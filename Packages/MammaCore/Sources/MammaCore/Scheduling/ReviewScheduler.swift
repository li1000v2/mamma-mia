import Foundation
import FSRS

public enum CardKind: String, Codable, Sendable, CaseIterable {
    /// 听辨: hear it at full speed, say or pick the meaning.
    case listen
    /// 回忆: see the Chinese intent, say it, compare with the model audio.
    case recall
    /// 换词: say the whole sentence with a new word in the frame.
    case swap
    /// 最小对立: hear one of two near-identical words, pick which.
    case minimalPair
}

public struct CardID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let phraseID: String
    public let kind: CardKind

    public init(phraseID: String, kind: CardKind) {
        self.phraseID = phraseID
        self.kind = kind
    }

    public var description: String { "\(phraseID)#\(kind.rawValue)" }
}

/// Self-graded answer quality, mapped onto FSRS ratings.
public enum Grade: Int, Codable, Sendable, CaseIterable {
    case again = 1
    case hard
    case good
    case easy

    var rating: Rating {
        switch self {
        case .again: .again
        case .hard: .hard
        case .good: .good
        case .easy: .easy
        }
    }
}

/// A card and its FSRS memory state. The FSRS types stay internal so the app only needs MammaCore.
public struct ReviewCard: Codable, Hashable, Sendable, Identifiable {
    public let id: CardID
    var memory: Card

    public var due: Date { memory.due }
    public var isNew: Bool { memory.state == .new }
    public var reps: Int { memory.reps }
    public var lapses: Int { memory.lapses }
    public var lastReview: Date? { memory.lastReview }
    public var stability: Double { memory.stability }
}

/// One answered card, kept for the review log and progress export.
public struct ReviewRecord: Codable, Hashable, Sendable {
    public let card: CardID
    public let grade: Grade
    public let reviewedAt: Date
    public let elapsedDays: Double
    public let scheduledDays: Double
    public let stability: Double
    public let difficulty: Double
}

public struct SchedulerConfig: Codable, Hashable, Sendable {
    public var desiredRetention: Double
    public var newCardsPerDay: Int
    public var learningSteps: [String]
    public var relearningSteps: [String]
    public var enableFuzz: Bool

    public init(
        desiredRetention: Double = 0.9,
        newCardsPerDay: Int = 20,
        learningSteps: [String] = ["1m", "10m"],
        relearningSteps: [String] = ["10m"],
        enableFuzz: Bool = true
    ) {
        self.desiredRetention = desiredRetention
        self.newCardsPerDay = newCardsPerDay
        self.learningSteps = learningSteps
        self.relearningSteps = relearningSteps
        self.enableFuzz = enableFuzz
    }
}

/// Today's queue: reviews due before the study day ends, extra reviews for the trip, then the new
/// cards the daily cap allows.
public struct DailyPlan: Sendable {
    public let due: [ReviewCard]
    /// Cards FSRS would next show only after the trip day that needs them (see `boostCandidates`).
    /// They are ordinary reviews: the grade updates them like any other.
    public let boosted: [ReviewCard]
    public let new: [ReviewCard]
}

/// FSRS-6 scheduling with the default parameters until there is enough review history to fit our own.
public struct ReviewScheduler: Sendable {
    public let config: SchedulerConfig
    private let fsrs: FSRS

    public init(config: SchedulerConfig = SchedulerConfig()) {
        self.config = config
        fsrs = FSRS(parameters: FSRSParameters(
            requestRetention: config.desiredRetention,
            w: FSRSDefaults.defaultWv6,
            enableFuzz: config.enableFuzz,
            enableShortTerm: true,
            learningSteps: config.learningSteps,
            relearningSteps: config.relearningSteps
        ))
    }

    public var usesFSRS6: Bool { fsrs.version == .v6 }

    public func makeCard(_ id: CardID, now: Date) -> ReviewCard {
        ReviewCard(id: id, memory: Card(due: now))
    }

    public func review(_ card: ReviewCard, grade: Grade, at now: Date) throws -> (card: ReviewCard, record: ReviewRecord) {
        let result = try fsrs.next(card: card.memory, now: now, grade: grade.rating)
        var updated = card
        updated.memory = result.card
        let record = ReviewRecord(
            card: card.id,
            grade: grade,
            reviewedAt: now,
            elapsedDays: result.log.elapsedDays,
            scheduledDays: result.log.scheduledDays,
            stability: result.card.stability,
            difficulty: result.card.difficulty
        )
        return (updated, record)
    }

    /// Predicted probability of recalling `card` at `date` (0 for cards never reviewed).
    public func retrievability(of card: ReviewCard, at date: Date) -> Double {
        fsrs.getRetrievability(card: card.memory, now: date).number
    }

    /// `cards` must be in course order; new cards are introduced in that order. `needBy` gives the
    /// trip day a card is first needed on; without a trip it returns nil and nothing is boosted.
    public func plan(
        cards: [ReviewCard],
        newIntroducedToday: Int,
        now: Date,
        clock: StudyClock,
        needBy: (ReviewCard) -> LocalDate? = { _ in nil },
        boostPolicy: BoostPolicy = BoostPolicy()
    ) -> DailyPlan {
        let endOfToday = clock.end(of: clock.day(of: now))
        let due = cards.filter { !$0.isNew && $0.due <= endOfToday }
        let boosted = boostCandidates(cards: cards, needBy: needBy, now: now, clock: clock, policy: boostPolicy).map(\.card)
        let budget = max(0, config.newCardsPerDay - newIntroducedToday)
        return DailyPlan(
            due: neededSoonestFirst(due, now: now, clock: clock, needBy: needBy, policy: boostPolicy),
            boosted: neededSoonestFirst(boosted, now: now, clock: clock, needBy: needBy, policy: boostPolicy),
            new: Array(cards.filter(\.isNew).prefix(budget))
        )
    }

    /// Review order: cards needed on the trip within the boost window come first, the soonest
    /// need-by day first; then the rest. Lowest predicted recall first within each.
    func neededSoonestFirst(
        _ cards: [ReviewCard],
        now: Date,
        clock: StudyClock,
        needBy: (ReviewCard) -> LocalDate?,
        policy: BoostPolicy
    ) -> [ReviewCard] {
        let today = clock.day(of: now)
        return cards
            .map { card -> (card: ReviewCard, daysLeft: Int, recall: Double) in
                var daysLeft = Int.max
                if let day = needBy(card) {
                    let left = today.days(until: day)
                    if left >= 0 && left <= policy.windowDays {
                        daysLeft = left
                    }
                }
                return (card, daysLeft, retrievability(of: card, at: now))
            }
            .sorted { ($0.daysLeft, $0.recall) < ($1.daysLeft, $1.recall) }
            .map(\.card)
    }
}
