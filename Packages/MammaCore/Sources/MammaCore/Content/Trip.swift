import Foundation

/// The itinerary. The real one is personal: it is entered in the app's trip form and kept on the
/// phone with the study progress (and in its backups). The repository only ships
/// Content/trip.example.json with made-up dates.
public struct Trip: Codable, Hashable, Sendable {
    /// Where you sleep at a stop. Only stored for now; the show cards will use it.
    public struct Hotel: Codable, Hashable, Sendable {
        public var name: String?
        public var address: String?

        public init(name: String? = nil, address: String? = nil) {
            self.name = name
            self.address = address
        }
    }

    public struct Stop: Codable, Hashable, Sendable {
        public var city: String
        /// Arrival day.
        public var from: LocalDate
        /// Departure day; equals the next stop's `from` on travel days.
        public var to: LocalDate
        public var hotel: Hotel?

        public init(city: String, from: LocalDate, to: LocalDate, hotel: Hotel? = nil) {
            self.city = city
            self.from = from
            self.to = to
            self.hotel = hotel
        }
    }

    public struct Event: Codable, Hashable, Sendable {
        public let id: String
        public let date: LocalDate

        public init(id: String, date: LocalDate) {
            self.id = id
            self.date = date
        }
    }

    /// The zone the trip form writes dates in.
    public static let italyTimeZone = "Europe/Rome"

    /// IANA zone the dates are written in, e.g. "Europe/Rome".
    public var timeZone: String
    public var stops: [Stop]
    public var events: [Event]
    /// Allergies and other things you don't eat. Only stored for now; the show cards will use it.
    public var diet: Diet?

    public init(timeZone: String = Trip.italyTimeZone, stops: [Stop], events: [Event] = [], diet: Diet? = nil) {
        self.timeZone = timeZone
        self.stops = stops
        self.events = events
        self.diet = diet
    }

    public var zone: TimeZone? { TimeZone(identifier: timeZone) }

    /// The city you are in on `day`. On a travel day this is the city you arrive in.
    public func stop(on day: LocalDate) -> Stop? {
        stops.last { $0.from <= day && day <= $0.to }
    }

    /// From the first arrival to the last departure; nil without stops or with dates that end
    /// before they start.
    public var span: ClosedRange<LocalDate>? {
        guard let start = stops.map(\.from).min(), let end = stops.map(\.to).max(), start <= end else {
            return nil
        }
        return start...end
    }
}

/// Allergies and other dietary needs.
public struct Diet: Codable, Hashable, Sendable {
    /// In the order of Annex II.
    public var allergens: [Allergen]
    /// Anything else, in the learner's own words.
    public var note: String?

    public init(allergens: [Allergen] = [], note: String? = nil) {
        self.allergens = allergens
        self.note = note
    }

    private enum CodingKeys: String, CodingKey {
        case allergens, note
    }

    /// Ids this build doesn't know are dropped rather than failing the whole progress file.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ids = try container.decodeIfPresent([String].self, forKey: .allergens) ?? []
        allergens = ids.compactMap(Allergen.init(rawValue:))
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }
}

/// The 14 substances EU food businesses must declare, from Annex II of Regulation (EU)
/// No 1169/2011. Cases are in the annex's order.
public enum Allergen: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case gluten
    case crustaceans
    case eggs
    case fish
    case peanuts
    case soybeans
    case milk
    case nuts
    case celery
    case mustard
    case sesame
    case sulphites
    case lupin
    case molluscs

    public var id: String { rawValue }

    /// The entry as worded in the Italian text of Annex II (consolidated version, with the 2017
    /// corrigendum to entry 4), up to its list of examples or exceptions.
    public var italian: String {
        switch self {
        case .gluten: "Cereali contenenti glutine"
        case .crustaceans: "Crostacei e prodotti a base di crostacei"
        case .eggs: "Uova e prodotti a base di uova"
        case .fish: "Pesce e prodotti della pesca"
        case .peanuts: "Arachidi e prodotti a base di arachidi"
        case .soybeans: "Soia e prodotti a base di soia"
        case .milk: "Latte e prodotti a base di latte (incluso lattosio)"
        case .nuts: "Frutta a guscio"
        case .celery: "Sedano e prodotti a base di sedano"
        case .mustard: "Senape e prodotti a base di senape"
        case .sesame: "Semi di sesamo e prodotti a base di semi di sesamo"
        case .sulphites: "Anidride solforosa e solfiti"
        case .lupin: "Lupini e prodotti a base di lupini"
        case .molluscs: "Molluschi e prodotti a base di molluschi"
        }
    }

    public var zh: String {
        switch self {
        case .gluten: "含麸质的谷物（小麦、黑麦、大麦、燕麦等）"
        case .crustaceans: "甲壳类（虾、蟹等）"
        case .eggs: "蛋"
        case .fish: "鱼"
        case .peanuts: "花生"
        case .soybeans: "大豆"
        case .milk: "奶（含乳糖）"
        case .nuts: "坚果（杏仁、榛子、核桃、腰果、开心果等）"
        case .celery: "芹菜"
        case .mustard: "芥末（芥菜籽）"
        case .sesame: "芝麻"
        case .sulphites: "二氧化硫和亚硫酸盐"
        case .lupin: "羽扇豆"
        case .molluscs: "软体动物（贝类、鱿鱼、章鱼等）"
        }
    }
}

/// Something that stops a trip from being saved.
public enum TripIssue: Hashable, Sendable {
    case noStops
    case unknownTimeZone(String)
    case unknownCity(String)
    case repeatedCity(String)
    /// The stop's departure day is before its arrival day.
    case leavesBeforeArriving(city: String)
    /// `later` starts before `earlier` ends. A travel day may end one stop and start the next.
    case overlaps(earlier: String, later: String)
}

extension Trip {
    /// What has to be fixed before the trip can be used; empty when it's fine. Stops must be in
    /// order; `knownCities` are the course's city ids.
    public func issues(knownCities: Set<String>) -> [TripIssue] {
        var issues: [TripIssue] = []
        if stops.isEmpty { issues.append(.noStops) }
        if zone == nil { issues.append(.unknownTimeZone(timeZone)) }
        var seen = Set<String>()
        for stop in stops {
            if !knownCities.contains(stop.city) {
                issues.append(.unknownCity(stop.city))
            }
            if !seen.insert(stop.city).inserted, !issues.contains(.repeatedCity(stop.city)) {
                issues.append(.repeatedCity(stop.city))
            }
            if stop.to < stop.from {
                issues.append(.leavesBeforeArriving(city: stop.city))
            }
        }
        for (earlier, later) in zip(stops, stops.dropFirst()) where later.from < earlier.to {
            issues.append(.overlaps(earlier: earlier.city, later: later.city))
        }
        return issues
    }

    /// `catalog`'s events that fall within the trip, by date.
    public func events(coveredFrom catalog: [CourseEvent]) -> [Event] {
        guard let span else { return [] }
        var events: [Event] = []
        for year in span.lowerBound.year...span.upperBound.year {
            for event in catalog {
                if let date = event.date(in: year), span.contains(date) {
                    events.append(Event(id: event.id, date: date))
                }
            }
        }
        return events.sorted { ($0.date, $0.id) < ($1.date, $1.id) }
    }

    /// The trip as the form saves it: text trimmed, blank text and empty hotels or diet dropped,
    /// allergens in annex order, and the events taken from `catalog` for the dates it covers.
    public func normalized(events catalog: [CourseEvent]) -> Trip {
        var trip = self
        trip.stops = stops.map { stop in
            var stop = stop
            let hotel = Hotel(name: Self.cleaned(stop.hotel?.name), address: Self.cleaned(stop.hotel?.address))
            stop.hotel = hotel.name == nil && hotel.address == nil ? nil : hotel
            return stop
        }
        if let diet {
            let allergens = Allergen.allCases.filter { diet.allergens.contains($0) }
            let note = Self.cleaned(diet.note)
            trip.diet = allergens.isEmpty && note == nil ? nil : Diet(allergens: allergens, note: note)
        }
        trip.events = events(coveredFrom: catalog)
        return trip
    }

    private static func cleaned(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

/// Where `day` falls relative to a trip.
public enum TripPhase: Hashable, Sendable {
    /// Before the first arrival; `daysLeft` is at least 1.
    case before(daysLeft: Int)
    /// Day `day` (1-based) of `length`. `stop` is where you are, which on a travel day is the city
    /// you arrive in, and `leaving` the stop you leave that day. `stop` is nil between stops.
    case during(day: Int, length: Int, stop: Trip.Stop?, leaving: Trip.Stop?)
    case after
}

extension Trip {
    public func phase(on day: LocalDate) -> TripPhase? {
        guard let span else { return nil }
        if day < span.lowerBound { return .before(daysLeft: day.days(until: span.lowerBound)) }
        if day > span.upperBound { return .after }
        let current = stop(on: day)
        let leaving = stops.first { $0.to == day && $0.from < day && $0 != current }
        return .during(
            day: span.lowerBound.days(until: day) + 1,
            length: span.lowerBound.days(until: span.upperBound) + 1,
            stop: current,
            leaving: leaving
        )
    }
}
