import Foundation

/// A fixed sentence of the show cards that isn't a course phrase, from Content/showcards.json. It
/// goes through cross-checking like a lesson phrase (`status`, `checkedText`).
public struct ShowCardPhrase: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let it: String
    public let zh: String
    public let note: String?
    public let status: ReviewStatus
    public var checkedText: String? = nil
}

/// Content/showcards.json: the show cards' own sentences, and the allergen names the diet card
/// lists. Those are `Allergen.italian` again, here so the audio and review tools see them too.
public struct ShowCardContent: Codable, Sendable {
    public struct AllergenName: Codable, Hashable, Sendable {
        public let id: String
        public let it: String

        public init(id: String, it: String) {
            self.id = id
            self.it = it
        }
    }

    public let version: Int
    public let phrases: [ShowCardPhrase]
    public let allergens: [AllergenName]

    public func phrase(_ id: String) -> ShowCardPhrase? {
        phrases.first { $0.id == id }
    }
}

/// One show card (出示卡): big Italian to show someone and to play to them.
public struct ShowCard: Hashable, Sendable, Identifiable {
    public enum Kind: Hashable, Sendable {
        /// The hotel in a city, from the trip.
        case hotel(city: String)
        /// The trip's allergens and note.
        case diet
        case writeItDown
        case speakSlowly
        /// The EU emergency number.
        case emergency
    }

    public struct Line: Hashable, Sendable {
        public enum Style: Hashable, Sendable {
            /// A sentence to show and say.
            case sentence
            /// The learner's own text: a hotel's name or address, the diet note.
            case personal
            /// One entry of a list, such as an allergen.
            case item
            /// A phone number, shown huge.
            case number
        }

        public let style: Style
        public let text: String
        /// What it means, for the learner.
        public let zh: String?
        /// What playing the card says for this line; nil when it is only shown.
        public let speech: Speech?

        public init(style: Style, text: String, zh: String?, speech: Speech?) {
            self.style = style
            self.text = text
            self.zh = zh
            self.speech = speech
        }
    }

    public enum Speech: Hashable, Sendable {
        /// Fixed text, played from the bundled model audio when there is some.
        case model(String)
        /// The learner's own words: only ever read by the phone's voice, so they are never looked
        /// up in, generated for, or added to the bundled audio.
        case phoneVoice(String)
    }

    public let kind: Kind
    public let lines: [Line]

    public init(kind: Kind, lines: [Line]) {
        self.kind = kind
        self.lines = lines
    }

    public var id: String {
        switch kind {
        case .hotel(let city): "hotel-\(city)"
        case .diet: "diet"
        case .writeItDown: "write"
        case .speakSlowly: "slowly"
        case .emergency: "emergency"
        }
    }

    /// The EU-wide emergency number; free to call in Italy.
    public static let emergencyNumber = "112"

    /// The sentences the cards are made of: course phrases, reused with their audio, and the show
    /// cards' own lines in Content/showcards.json. `ContentValidator` checks that they exist.
    public enum Source {
        public static let writeItDown = "L03-05"
        public static let showOnMap = "L19-05"
        public static let help = "L26-01"
        public static let goToAddress = "go-to-address"
        public static let allergicTo = "allergic-to"
        public static let notEvenALittle = "not-even-a-little"
        public static let tellTheCook = "tell-the-cook"
        public static let speakSlowly = "speak-slowly"
        public static let call112 = "call-112"

        public static let coursePhrases = [writeItDown, showOnMap, help]
        public static let cardPhrases = [goToAddress, allergicTo, notEvenALittle, tellTheCook, speakSlowly, call112]
    }

    /// Whether the phone's Italian voice can read `text`: its letters are all Latin, accented or
    /// not. A note typed in Chinese is shown but not read out.
    public static func isLatinScript(_ text: String) -> Bool {
        text.unicodeScalars.allSatisfy { scalar in
            !scalar.properties.isAlphabetic || scalar.value < 0x0250 || (0x1E00...0x1EFF).contains(scalar.value)
        }
    }
}

extension ContentBundle {
    /// Every show card: the hotels in trip order and the diet card when the trip has them, then
    /// the cards any trip needs.
    public func showCards(for trip: Trip?) -> [ShowCard] {
        guard let trip else { return fixedShowCards }
        return hotelCards(for: trip) + [dietCard(for: trip)].compactMap { $0 } + fixedShowCards
    }

    /// A card for each stop with a hotel name or address: a sentence asking to go there, the name
    /// and address, and a request to show the way on a map.
    public func hotelCards(for trip: Trip) -> [ShowCard] {
        trip.stops.compactMap { stop in
            let name = Self.text(stop.hotel?.name)
            let address = Self.text(stop.hotel?.address)
            guard name != nil || address != nil else { return nil }
            var lines: [ShowCard.Line] = []
            lines += [showCardLine(ShowCard.Source.goToAddress)].compactMap { $0 }
            for text in [name, address].compactMap({ $0 }) {
                lines.append(ShowCard.Line(style: .personal, text: text, zh: nil, speech: .phoneVoice(text)))
            }
            lines += [showCardLine(ShowCard.Source.showOnMap)].compactMap { $0 }
            return ShowCard(kind: .hotel(city: stop.city), lines: lines)
        }
    }

    /// The allergens under a sentence saying you're allergic to them, in annex order with their
    /// legal Italian names, then the note as typed; nil when the trip has neither.
    public func dietCard(for trip: Trip) -> ShowCard? {
        let allergens = Allergen.allCases.filter { trip.diet?.allergens.contains($0) == true }
        let note = Self.text(trip.diet?.note)
        guard !allergens.isEmpty || note != nil else { return nil }
        var lines: [ShowCard.Line] = []
        if !allergens.isEmpty {
            lines += [showCardLine(ShowCard.Source.allergicTo)].compactMap { $0 }
            for allergen in allergens {
                lines.append(ShowCard.Line(style: .item, text: allergen.italian, zh: allergen.zh, speech: .model(allergen.italian)))
            }
            lines += [showCardLine(ShowCard.Source.notEvenALittle)].compactMap { $0 }
        }
        if let note {
            let speech: ShowCard.Speech? = ShowCard.isLatinScript(note) ? .phoneVoice(note) : nil
            lines.append(ShowCard.Line(style: .personal, text: note, zh: nil, speech: speech))
        }
        lines += [showCardLine(ShowCard.Source.tellTheCook)].compactMap { $0 }
        return ShowCard(kind: .diet, lines: lines)
    }

    /// The cards that don't depend on the trip: write it down, speak slowly, and 112.
    public var fixedShowCards: [ShowCard] {
        var cards: [ShowCard] = []
        if let line = showCardLine(ShowCard.Source.writeItDown) {
            cards.append(ShowCard(kind: .writeItDown, lines: [line]))
        }
        if let line = showCardLine(ShowCard.Source.speakSlowly) {
            cards.append(ShowCard(kind: .speakSlowly, lines: [line]))
        }
        let number = ShowCard.Line(style: .number, text: ShowCard.emergencyNumber, zh: "欧盟统一紧急电话", speech: nil)
        let sentences = [ShowCard.Source.help, ShowCard.Source.call112].compactMap { showCardLine($0) }
        cards.append(ShowCard(kind: .emergency, lines: [number] + sentences))
        return cards
    }

    /// A course phrase or a show-card sentence by id, as a line to show and play.
    func showCardLine(_ id: String) -> ShowCard.Line? {
        if let phrase = phrases.first(where: { $0.id == id }) {
            return ShowCard.Line(style: .sentence, text: phrase.it, zh: phrase.zh, speech: .model(phrase.it))
        }
        if let phrase = showCardContent?.phrase(id) {
            return ShowCard.Line(style: .sentence, text: phrase.it, zh: phrase.zh, speech: .model(phrase.it))
        }
        return nil
    }

    private static func text(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
