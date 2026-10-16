import Foundation

/// One finished run of a situational challenge.
public struct ChallengeRun: Codable, Hashable, Sendable {
    public let unit: String
    public let finishedAt: Date
    public let passed: Bool
    public let mistakes: Int
    public let hintsUsed: Int
    public let keyInfoCorrect: Int
    public let keyInfoAsked: Int

    public init(unit: String, finishedAt: Date, passed: Bool, mistakes: Int, hintsUsed: Int, keyInfoCorrect: Int, keyInfoAsked: Int) {
        self.unit = unit
        self.finishedAt = finishedAt
        self.passed = passed
        self.mistakes = mistakes
        self.hintsUsed = hintsUsed
        self.keyInfoCorrect = keyInfoCorrect
        self.keyInfoAsked = keyInfoAsked
    }
}

/// Everything the learner has done: card states, the full review history, finished lessons and
/// challenge runs, plus the trip they entered. Saved as one JSON file, which is also the backup
/// format. Every field decodes with a default, so files written by older builds keep loading after
/// fields are added — the app is reinstalled every week.
public struct StudyProgress: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version = StudyProgress.currentVersion
    public var cards: [ReviewCard] = []
    public var reviews: [ReviewRecord] = []
    public var completedUnits: [String: Date] = [:]
    public var challengeRuns: [ChallengeRun] = []
    /// Personal: stays on the phone and in its backups. Absent from files written before the trip
    /// form existed.
    public var trip: Trip?

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case version, cards, reviews, completedUnits, challengeRuns, trip
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? StudyProgress.currentVersion
        cards = try container.decodeIfPresent([ReviewCard].self, forKey: .cards) ?? []
        reviews = try container.decodeIfPresent([ReviewRecord].self, forKey: .reviews) ?? []
        completedUnits = try container.decodeIfPresent([String: Date].self, forKey: .completedUnits) ?? [:]
        challengeRuns = try container.decodeIfPresent([ChallengeRun].self, forKey: .challengeRuns) ?? []
        // A trip that can't be read is dropped rather than costing the learning record; it can be
        // entered again in a minute.
        trip = try? container.decodeIfPresent(Trip.self, forKey: .trip)
    }
}

extension StudyProgress {
    public func card(_ id: CardID) -> ReviewCard? {
        cards.first { $0.id == id }
    }

    public func isCompleted(_ unitID: String) -> Bool {
        completedUnits[unitID] != nil
    }

    public func hasPassed(_ unitID: String) -> Bool {
        challengeRuns.contains { $0.unit == unitID && $0.passed }
    }

    public func runs(of unitID: String) -> [ChallengeRun] {
        challengeRuns.filter { $0.unit == unitID }
    }

    /// Marks a lesson done and adds its cards as new cards. Cards that already exist keep their
    /// history, so redoing a lesson never resets reviews.
    public mutating func completeLesson(_ unitID: String, cards ids: [CardID], scheduler: ReviewScheduler, at now: Date) {
        if completedUnits[unitID] == nil {
            completedUnits[unitID] = now
        }
        let existing = Set(cards.map(\.id))
        for id in ids where !existing.contains(id) {
            cards.append(scheduler.makeCard(id, now: now))
        }
    }

    public mutating func apply(_ card: ReviewCard, record: ReviewRecord) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        } else {
            cards.append(card)
        }
        reviews.append(record)
    }

    public mutating func add(_ run: ChallengeRun) {
        challengeRuns.append(run)
    }

    /// How many cards had their first-ever review on `day`; the daily new-card cap counts these.
    public func newCardsStarted(on day: LocalDate, clock: StudyClock) -> Int {
        var seen = Set<CardID>()
        var count = 0
        for record in reviews where seen.insert(record.card).inserted {
            if clock.day(of: record.reviewedAt) == day {
                count += 1
            }
        }
        return count
    }

    public func reviewCount(on day: LocalDate, clock: StudyClock) -> Int {
        reviews.filter { clock.day(of: $0.reviewedAt) == day }.count
    }
}
