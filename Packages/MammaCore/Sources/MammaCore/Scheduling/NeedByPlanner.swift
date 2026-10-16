import Foundation

public enum NeedByError: Error, Equatable, Sendable {
    case malformed(String)
    case unknownCity(String)
    case unknownEvent(String)
    case emptyTrip
}

/// A scene's `neededAt`, parsed: the trip's first or last day, the arrival in a city, or a
/// fixed-date event.
public enum NeedAnchor: Hashable, Sendable {
    case first
    case last
    case city(String)
    case event(String)

    /// Nil when `neededAt` isn't one of "first", "last", "city:<id>" or "event:<id>".
    public init?(_ neededAt: String) {
        switch neededAt {
        case "first":
            self = .first
        case "last":
            self = .last
        default:
            let parts = neededAt.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2, !parts[1].isEmpty else { return nil }
            switch parts[0] {
            case "city": self = .city(parts[1])
            case "event": self = .event(parts[1])
            default: return nil
            }
        }
    }

    /// How narrowly the anchor picks its day, lowest first: a holiday, a city's arrival, the
    /// last day, then the first day, from which everything general is needed.
    var specificity: Int {
        switch self {
        case .event: 0
        case .city: 1
        case .last: 2
        case .first: 3
        }
    }
}

extension SceneTag {
    public var anchor: NeedAnchor? { NeedAnchor(neededAt) }
}

/// Turns a scene's `neededAt` ("first", "last", "city:<id>", "event:<id>") into the trip day
/// on which that content is first used.
public struct NeedByPlanner: Sendable {
    public let trip: Trip

    public init(trip: Trip) {
        self.trip = trip
    }

    public func resolve(_ neededAt: String) throws -> LocalDate {
        guard let anchor = NeedAnchor(neededAt) else { throw NeedByError.malformed(neededAt) }
        switch anchor {
        case .first:
            guard let stop = trip.stops.first else { throw NeedByError.emptyTrip }
            return stop.from
        case .last:
            guard let stop = trip.stops.last else { throw NeedByError.emptyTrip }
            return stop.to
        case .city(let city):
            guard let stop = trip.stops.first(where: { $0.city == city }) else {
                throw NeedByError.unknownCity(city)
            }
            return stop.from
        case .event(let id):
            guard let event = trip.events.first(where: { $0.id == id }) else {
                throw NeedByError.unknownEvent(id)
            }
            return event.date
        }
    }

    /// Syntax check that needs no trip, for validating course.json on its own.
    public static func isWellFormed(_ neededAt: String) -> Bool {
        NeedAnchor(neededAt) != nil
    }
}

/// How the trip-aware extra reviews work. FSRS alone keeps recall around its target retention;
/// before a card's need-by day we want it fresher than that, but only for cards that need it.
public struct BoostPolicy: Sendable {
    /// Cards whose predicted recall at the start of their need-by day is below this get an extra review.
    public var threshold: Double
    /// How many days before the need-by day extra reviews may start.
    public var windowDays: Int

    public init(threshold: Double = 0.95, windowDays: Int = 5) {
        self.threshold = threshold
        self.windowDays = windowDays
    }
}

public struct BoostCandidate: Sendable {
    public let card: ReviewCard
    public let needBy: LocalDate
    public let predictedRecall: Double
}

extension ReviewScheduler {
    /// Cards FSRS would not show before their need-by day whose predicted recall on that day is
    /// below the policy threshold, most at-risk first. Cards already reviewed today are skipped.
    public func boostCandidates(
        cards: [ReviewCard],
        needBy: (ReviewCard) -> LocalDate?,
        now: Date,
        clock: StudyClock,
        policy: BoostPolicy = BoostPolicy()
    ) -> [BoostCandidate] {
        let today = clock.day(of: now)
        return cards.compactMap { card -> BoostCandidate? in
            // New and learning-step cards have their own schedule within the day.
            guard card.phase == .review, let day = needBy(card) else { return nil }
            let daysLeft = today.days(until: day)
            guard daysLeft > 0, daysLeft <= policy.windowDays else { return nil }
            let deadline = clock.start(of: day)
            guard card.due > deadline else { return nil }
            if let last = card.lastReview, clock.day(of: last) == today { return nil }
            let recall = retrievability(of: card, at: deadline)
            guard recall < policy.threshold else { return nil }
            return BoostCandidate(card: card, needBy: day, predictedRecall: recall)
        }
        .sorted { ($0.predictedRecall, $0.needBy) < ($1.predictedRecall, $1.needBy) }
    }
}
