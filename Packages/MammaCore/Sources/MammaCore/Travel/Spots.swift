import Foundation

/// A sentence for the pilgrimage spots that isn't a course phrase, from Content/spots.json. It goes
/// through cross-checking like a lesson phrase (`status`, `checkedText`).
public struct SpotPhrase: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let it: String
    public let zh: String
    public let note: String?
    public let status: ReviewStatus
    public var checkedText: String? = nil
}

/// A pilgrimage spot (巡礼点): a public place, by its name, address and coordinates. Which scene it
/// is stays the learner's own note on the phone; nothing about the story is in the repository.
public struct Spot: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    /// The course city it belongs to; for a day trip, the city it is made from.
    public let city: String
    /// Reached on a day trip from `city` rather than in it. Such spots count toward the badge for
    /// every spot, not toward the city's.
    public var dayTrip: Bool? = nil
    /// The name in Italian, as signposted and said. Checked like a phrase (`status`, `checkedText`).
    public let it: String
    public let zh: String
    /// Help with saying the name, in Chinese.
    public let note: String?
    public let address: String
    public let latitude: Double
    public let longitude: Double
    /// For a place larger than a point, such as a hill or an island: what the pin marks, in Chinese.
    public let pin: String?
    /// Course phrase ids or ids of `SpotContent.phrases`, in the order shown.
    public let phrases: [String]
    public let status: ReviewStatus
    public var checkedText: String? = nil

    public var isDayTrip: Bool { dayTrip == true }
}

/// Content/spots.json: the pilgrimage layer's places and what to say there.
public struct SpotContent: Codable, Sendable {
    public let version: Int
    /// Course phrases for any spot, such as asking someone to take a photo.
    public let commonPhrases: [String]
    public let phrases: [SpotPhrase]
    public let spots: [Spot]

    public func spot(_ id: String) -> Spot? {
        spots.first { $0.id == id }
    }

    public func phrase(_ id: String) -> SpotPhrase? {
        phrases.first { $0.id == id }
    }
}

/// A sentence to say at a spot, from the course or from spots.json.
public struct SpotLine: Hashable, Sendable, Identifiable {
    public let id: String
    public let it: String
    public let zh: String
}

/// The spots of one city: its own, then those reached on day trips from it.
public struct SpotGroup: Hashable, Sendable, Identifiable {
    public let city: String
    public let spots: [Spot]
    public let dayTrips: [Spot]

    public var id: String { city }
    public var all: [Spot] { spots + dayTrips }
}

/// What the learner recorded at a spot. Personal, like the trip: kept with the progress on the
/// phone and in its backups, never in the log. Photos aren't in it: they stay in the app's own
/// folder on the phone.
public struct SpotLog: Codable, Hashable, Sendable {
    /// Their own words, such as which scene the place is.
    public var note: String?
    /// When they checked in, oldest first, in whole seconds as the file stores them.
    public var checkIns: [Date]

    public init(note: String? = nil, checkIns: [Date] = []) {
        self.note = note
        self.checkIns = checkIns
    }

    private enum CodingKeys: String, CodingKey {
        case note, checkIns
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        checkIns = try container.decodeIfPresent([Date].self, forKey: .checkIns) ?? []
    }

    public var isEmpty: Bool { note == nil && checkIns.isEmpty }
    public var firstCheckIn: Date? { checkIns.min() }
}

/// A badge of the pilgrimage layer: one per city for its own spots, and one for every spot.
public struct SpotBadge: Hashable, Sendable, Identifiable {
    public enum Scope: Hashable, Sendable {
        case city(String)
        case all
    }

    public let scope: Scope
    public let total: Int
    public let visited: Int
    /// When the last of its spots was first checked in; nil until every one has been.
    public let earnedAt: Date?

    public var id: String {
        switch scope {
        case .city(let city): "city-\(city)"
        case .all: "all"
        }
    }

    public var isEarned: Bool { earnedAt != nil }
}

extension ContentBundle {
    public var spots: [Spot] { spotContent?.spots ?? [] }

    /// A spot's sentences in order. An id that names nothing is left out; the validator reports it.
    public func lines(at spot: Spot) -> [SpotLine] {
        spot.phrases.compactMap(spotLine)
    }

    /// The course sentences for any spot, such as asking someone to take a photo.
    public var commonSpotLines: [SpotLine] {
        (spotContent?.commonPhrases ?? []).compactMap(spotLine)
    }

    /// The spots by city. During the trip the city you're in comes first; then the trip's cities in
    /// its order, then the rest in course order. Spots keep the file's order within a city.
    public func spotGroups(trip: Trip?, on day: LocalDate) -> [SpotGroup] {
        var first: [String] = []
        if case .during(_, _, let stop?, _)? = trip?.phase(on: day) {
            first.append(stop.city)
        }
        return Self.unique(first + spotCityOrder(trip: trip)).compactMap { city -> SpotGroup? in
            let mine = spots.filter { $0.city == city }
            guard !mine.isEmpty else { return nil }
            return SpotGroup(city: city, spots: mine.filter { !$0.isDayTrip }, dayTrips: mine.filter(\.isDayTrip))
        }
    }

    /// A badge for each city with spots of its own, in the trip's order, then one for every spot.
    public func spotBadges(trip: Trip?, logs: [String: SpotLog]) -> [SpotBadge] {
        let cities = spotCityOrder(trip: trip).compactMap { city -> SpotBadge? in
            let own = spots.filter { $0.city == city && !$0.isDayTrip }
            guard !own.isEmpty else { return nil }
            return Self.badge(.city(city), spots: own, logs: logs)
        }
        return cities + [Self.badge(.all, spots: spots, logs: logs)]
    }

    /// The trip's cities in its order, then the course's, then any other a spot names.
    private func spotCityOrder(trip: Trip?) -> [String] {
        Self.unique((trip?.stops.map(\.city) ?? []) + course.cities.map(\.id) + spots.map(\.city))
    }

    private static func badge(_ scope: SpotBadge.Scope, spots: [Spot], logs: [String: SpotLog]) -> SpotBadge {
        let firsts = spots.compactMap { logs[$0.id]?.firstCheckIn }
        let earned = !spots.isEmpty && firsts.count == spots.count ? firsts.max() : nil
        return SpotBadge(scope: scope, total: spots.count, visited: firsts.count, earnedAt: earned)
    }

    func spotLine(_ id: String) -> SpotLine? {
        if let phrase = phrases.first(where: { $0.id == id }) {
            return SpotLine(id: id, it: phrase.it, zh: phrase.zh)
        }
        if let phrase = spotContent?.phrase(id) {
            return SpotLine(id: id, it: phrase.it, zh: phrase.zh)
        }
        return nil
    }

    private static func unique(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }
}

extension StudyProgress {
    /// Adds a check-in at `date`, kept to the whole second the file stores.
    public mutating func checkIn(atSpot id: String, on date: Date) {
        let second = Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded(.down))
        var log = spotLogs[id] ?? SpotLog()
        log.checkIns.append(second)
        log.checkIns.sort()
        spotLogs[id] = log
    }

    /// Takes back one check-in, e.g. a tap by mistake.
    public mutating func removeCheckIn(atSpot id: String, _ date: Date) {
        guard var log = spotLogs[id], let index = log.checkIns.firstIndex(of: date) else { return }
        log.checkIns.remove(at: index)
        spotLogs[id] = log.isEmpty ? nil : log
    }

    /// Sets the learner's note; blank text clears it.
    public mutating func setNote(_ note: String?, forSpot id: String) {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        var log = spotLogs[id] ?? SpotLog()
        log.note = trimmed?.isEmpty == false ? trimmed : nil
        spotLogs[id] = log.isEmpty ? nil : log
    }
}
