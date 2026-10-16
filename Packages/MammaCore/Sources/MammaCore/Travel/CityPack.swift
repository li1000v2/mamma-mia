import Foundation

/// 城市包: the evening before you arrive in a city, up to `size` of the cards that arrival needs go
/// into reviews — the city's own scenes and, before the first city, everything needed from the first
/// day. It only puts cards in the queue: as with every review, only the grade changes a card.
public struct CityPack: Hashable, Sendable {
    public let city: String
    public let arrival: LocalDate
    /// Scenes first needed on the arrival day, most specific first.
    public let scenes: [SceneTag]
    /// The phrases of those scenes.
    public let phraseIDs: Set<String>

    /// Most cards one pack puts into reviews.
    public static let size = 30
    /// Local hour on the eve when the pack opens and its reminder goes off.
    public static let eveningHour = 19

    public init(city: String, arrival: LocalDate, scenes: [SceneTag], phraseIDs: Set<String>) {
        self.city = city
        self.arrival = arrival
        self.scenes = scenes
        self.phraseIDs = phraseIDs
    }

    public var eve: LocalDate { arrival.adding(days: -1) }

    /// The evening before the arrival, in the clock's time zone: where the phone is then.
    public func opens(_ clock: StudyClock) -> Date {
        eve.start(in: clock.timeZone, hour: Self.eveningHour)
    }

    /// The end of the arrival's study day, so a pack skipped on the eve can still be done on arrival.
    public func closes(_ clock: StudyClock) -> Date {
        clock.end(of: arrival)
    }

    public func isOpen(at date: Date, clock: StudyClock) -> Bool {
        opens(clock) <= date && date < closes(clock)
    }
}

extension ContentBundle {
    /// One pack per stop whose arrival needs phrases, in trip order. A pack holds the scenes the
    /// need-by days put on the arrival, except those of another city arriving the same day.
    public func cityPacks(on trip: Trip) -> [CityPack] {
        trip.stops.compactMap { stop in
            let needed = scenes(firstNeededOn: stop.from, trip: trip).filter { scene in
                if case .city(let city)? = scene.anchor { return city == stop.city }
                return true
            }
            let sceneIDs = Set(needed.map(\.id))
            let phraseIDs = Set(phrases.filter { sceneIDs.contains($0.scene) }.map(\.id))
            guard !phraseIDs.isEmpty else { return nil }
            return CityPack(city: stop.city, arrival: stop.from, scenes: needed, phraseIDs: phraseIDs)
        }
    }
}

extension ReviewScheduler {
    /// The cards the packs open at `now` still put into reviews. A pack takes its arrival's cards in
    /// review state, the lowest predicted recall at the start of the arrival day first, up to
    /// `CityPack.size` less its cards already reviewed since it opened. Reviewing a card only shortens
    /// the rest, so the set doesn't change while you work through it.
    public func packCards(cards: [ReviewCard], packs: [CityPack], now: Date, clock: StudyClock) -> [ReviewCard] {
        var chosen: [ReviewCard] = []
        var seen = Set<CardID>()
        for pack in packs where pack.isOpen(at: now, clock: clock) {
            let opened = pack.opens(clock)
            let mine = cards.filter { pack.phraseIDs.contains($0.id.phraseID) }
            let done = mine.filter { ($0.lastReview ?? .distantPast) >= opened }.count
            let deadline = clock.start(of: pack.arrival)
            let ranked = mine
                .filter { $0.phase == .review && ($0.lastReview ?? .distantPast) < opened }
                .map { (card: $0, recall: retrievability(of: $0, at: deadline)) }
                .sorted { ($0.recall, $0.card.id.description) < ($1.recall, $1.card.id.description) }
            for entry in ranked.prefix(max(0, CityPack.size - done)) where seen.insert(entry.card.id).inserted {
                chosen.append(entry.card)
            }
        }
        return chosen
    }
}
