import Foundation

// What 随身 shows on a day of the trip: the scenes the day needs, and those of the city you're in.
extension ContentBundle {
    /// Scenes whose phrases are first needed on `day`, most specific first: the day's holidays,
    /// the city you arrive in, the trip's last day, then what's needed from the first day on.
    /// Scenes with the same kind of anchor keep course order.
    public func scenes(firstNeededOn day: LocalDate, trip: Trip) -> [SceneTag] {
        let planner = NeedByPlanner(trip: trip)
        return course.scenes.enumerated()
            .filter { (try? planner.resolve($0.element.neededAt)) == day }
            .sorted { lhs, rhs in
                let left = lhs.element.anchor?.specificity ?? Int.max
                let right = rhs.element.anchor?.specificity ?? Int.max
                return (left, lhs.offset) < (right, rhs.offset)
            }
            .map(\.element)
    }

    /// The scenes of the city you're in on `day` that were first needed on an earlier day, such
    /// as the vaporetto on a second day in Venice.
    public func cityScenes(on day: LocalDate, trip: Trip) -> [SceneTag] {
        guard let stop = trip.stop(on: day) else { return [] }
        let neededToday = Set(scenes(firstNeededOn: day, trip: trip).map(\.id))
        return course.scenes.filter { $0.anchor == NeedAnchor.city(stop.city) && !neededToday.contains($0.id) }
    }

    /// The lesson phrases of a scene, in course order.
    public func phrases(inScene id: String) -> [Phrase] {
        phrases.filter { $0.scene == id }
    }
}

/// The trip in a few numbers, for 随身 once it is over.
public struct TripRecap: Hashable, Sendable {
    /// From the first arrival to the last departure, both counted.
    public let days: Int
    /// City ids in the order visited.
    public let cities: [String]
    /// Answers given in reviews on the trip's days.
    public let reviews: Int
    /// Different phrases among them.
    public let phrases: Int
}

extension StudyProgress {
    /// Nil for a trip without a valid span.
    public func recap(of trip: Trip, clock: StudyClock) -> TripRecap? {
        guard let span = trip.span else { return nil }
        let during = reviews.filter { span.contains(clock.day(of: $0.reviewedAt)) }
        return TripRecap(
            days: span.lowerBound.days(until: span.upperBound) + 1,
            cities: trip.stops.map(\.city),
            reviews: during.count,
            phrases: Set(during.map(\.card.phraseID)).count
        )
    }
}
