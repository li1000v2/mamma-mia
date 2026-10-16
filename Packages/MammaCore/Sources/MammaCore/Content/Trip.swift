import Foundation

/// The itinerary. The real one is personal and imported on the phone; the repository only ships
/// Content/trip.example.json with made-up dates.
public struct Trip: Codable, Sendable {
    public struct Stop: Codable, Hashable, Sendable {
        public let city: String
        /// Arrival day.
        public let from: LocalDate
        /// Departure day; equals the next stop's `from` on travel days.
        public let to: LocalDate
    }

    public struct Event: Codable, Hashable, Sendable {
        public let id: String
        public let date: LocalDate
    }

    /// IANA zone the dates are written in, e.g. "Europe/Rome".
    public let timeZone: String
    public let stops: [Stop]
    public let events: [Event]

    public var zone: TimeZone? { TimeZone(identifier: timeZone) }

    /// The city you are in on `day`. On a travel day this is the city you arrive in.
    public func stop(on day: LocalDate) -> Stop? {
        stops.last { $0.from <= day && day <= $0.to }
    }
}
