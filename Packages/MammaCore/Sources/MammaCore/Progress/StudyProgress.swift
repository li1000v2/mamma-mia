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
    /// Sentences from role-play feedback, reviewed like lesson phrases. Absent from files written
    /// before the online role-play existed.
    public var practicePhrases: [PracticePhrase] = []
    /// Notes and check-ins at the pilgrimage spots, by spot id. Personal like the trip. Absent from
    /// files written before the pilgrimage layer, and from any without one.
    public var spotLogs: [String: SpotLog] = [:]
    /// The file had a trip this build couldn't read, so it was left out. Not saved; it only lets
    /// the app note the loss in its log without writing anything about the trip itself.
    public private(set) var droppedUnreadableTrip = false

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case version, cards, reviews, completedUnits, challengeRuns, trip, practicePhrases, spotLogs
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
        do {
            trip = try container.decodeIfPresent(Trip.self, forKey: .trip)
        } catch {
            trip = nil
            droppedUnreadableTrip = true
        }
        // Like the trip: unreadable role-play phrases don't cost the rest of the record.
        practicePhrases = (try? container.decodeIfPresent([PracticePhrase].self, forKey: .practicePhrases)) ?? []
        // Like the trip: notes and check-ins that can't be read don't cost the learning record.
        spotLogs = (try? container.decodeIfPresent([String: SpotLog].self, forKey: .spotLogs)) ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(cards, forKey: .cards)
        try container.encode(reviews, forKey: .reviews)
        try container.encode(completedUnits, forKey: .completedUnits)
        try container.encode(challengeRuns, forKey: .challengeRuns)
        try container.encodeIfPresent(trip, forKey: .trip)
        // Left out until there is one, so the file reads the same to builds from before the role-play.
        if !practicePhrases.isEmpty {
            try container.encode(practicePhrases, forKey: .practicePhrases)
        }
        // Left out until there is one, so the file reads the same to builds from before the spots.
        if !spotLogs.isEmpty {
            try container.encode(spotLogs, forKey: .spotLogs)
        }
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

    /// Adds role-play phrases with new cards, like finishing a lesson. A phrase already here keeps
    /// its cards and their history. Returns the phrases that were new.
    @discardableResult
    public mutating func addPractice(_ phrases: [PracticePhrase], scheduler: ReviewScheduler, at now: Date) -> [PracticePhrase] {
        var added: [PracticePhrase] = []
        for phrase in phrases where !practicePhrases.contains(where: { $0.id == phrase.id }) {
            practicePhrases.append(phrase)
            let existing = Set(cards.map(\.id))
            for id in ContentBundle.cards(for: phrase.phrase) where !existing.contains(id) {
                cards.append(scheduler.makeCard(id, now: now))
            }
            added.append(phrase)
        }
        return added
    }

    /// Takes a role-play phrase back out of the reviews, cards included; the review log stays.
    public mutating func removePractice(_ id: String) {
        practicePhrases.removeAll { $0.id == id }
        cards.removeAll { $0.id.phraseID == id }
    }

    public func practicePhrase(_ id: String) -> PracticePhrase? {
        practicePhrases.first { $0.id == id }
    }

    /// What restoring `backup` over this progress leaves: the backup's learning records, and its
    /// trip if it has one. A backup without a trip (every backup made before the trip form, or one
    /// whose trip couldn't be read) keeps the trip already here; `keptTrip` says so. Spot notes and
    /// check-ins work the same way, so a backup from before the pilgrimage layer doesn't wipe them.
    public func restoring(_ backup: StudyProgress) -> (progress: StudyProgress, keptTrip: Bool) {
        var restored = backup
        if backup.spotLogs.isEmpty {
            restored.spotLogs = spotLogs
        }
        guard backup.trip == nil, let trip else { return (restored, false) }
        restored.trip = trip
        return (restored, true)
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
