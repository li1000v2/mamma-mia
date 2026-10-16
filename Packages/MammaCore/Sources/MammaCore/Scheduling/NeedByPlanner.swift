import Foundation

public enum NeedByError: Error, Equatable, Sendable {
    case malformed(String)
    case unknownCity(String)
    case unknownEvent(String)
    case emptyTrip
}

/// Turns a scene's `neededAt` ("first", "last", "city:<id>", "event:<id>") into the trip day
/// on which that content is first used.
public struct NeedByPlanner: Sendable {
    public let trip: Trip

    public init(trip: Trip) {
        self.trip = trip
    }

    public func resolve(_ neededAt: String) throws -> LocalDate {
        switch neededAt {
        case "first":
            guard let stop = trip.stops.first else { throw NeedByError.emptyTrip }
            return stop.from
        case "last":
            guard let stop = trip.stops.last else { throw NeedByError.emptyTrip }
            return stop.to
        default:
            let parts = neededAt.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2, !parts[1].isEmpty else { throw NeedByError.malformed(neededAt) }
            switch parts[0] {
            case "city":
                guard let stop = trip.stops.first(where: { $0.city == parts[1] }) else {
                    throw NeedByError.unknownCity(parts[1])
                }
                return stop.from
            case "event":
                guard let event = trip.events.first(where: { $0.id == parts[1] }) else {
                    throw NeedByError.unknownEvent(parts[1])
                }
                return event.date
            default:
                throw NeedByError.malformed(neededAt)
            }
        }
    }

    /// Syntax check that needs no trip, for validating course.json on its own.
    public static func isWellFormed(_ neededAt: String) -> Bool {
        if neededAt == "first" || neededAt == "last" { return true }
        let parts = neededAt.split(separator: ":", maxSplits: 1)
        return parts.count == 2 && ["city", "event"].contains(String(parts[0])) && !parts[1].isEmpty
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
            guard !card.isNew, let day = needBy(card) else { return nil }
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
