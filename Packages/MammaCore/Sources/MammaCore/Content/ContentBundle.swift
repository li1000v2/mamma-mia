import Foundation

public struct ContentError: Error, CustomStringConvertible, Sendable {
    public let file: String
    public let reason: String

    public var description: String { "\(file): \(reason)" }
}

/// Everything under Content/ plus the audio manifest, as bundled into the app.
public struct ContentBundle: Sendable {
    public let course: Course
    /// Lesson files sorted by unit id, which is course order (L01…L30).
    public let lessons: [LessonContent]
    /// Challenge scripts sorted by unit id (C01…C10).
    public let dialogues: [DialogueScript]
    public let audio: AudioManifest?
    /// The show cards' own sentences (showcards.json); nil when the content has none.
    public let showCardContent: ShowCardContent?
    /// The pilgrimage spots (spots.json); nil when the content has none.
    public let spotContent: SpotContent?

    public init(
        course: Course,
        lessons: [LessonContent],
        dialogues: [DialogueScript] = [],
        audio: AudioManifest?,
        showCardContent: ShowCardContent? = nil,
        spotContent: SpotContent? = nil
    ) {
        self.course = course
        self.lessons = lessons.sorted { $0.unit < $1.unit }
        self.dialogues = dialogues.sorted { $0.unit < $1.unit }
        self.audio = audio
        self.showCardContent = showCardContent
        self.spotContent = spotContent
    }

    /// Loads course.json, every lessons/*.json and dialogues/*.json and, when present,
    /// showcards.json, spots.json and the audio manifest.
    public static func load(contentDirectory: URL, audioDirectory: URL? = nil) throws -> ContentBundle {
        let course: Course = try decode(contentDirectory.appendingPathComponent("course.json"))
        let lessons: [LessonContent] = try decodeAll(in: contentDirectory.appendingPathComponent("lessons", isDirectory: true))
        let dialogues: [DialogueScript] = try decodeAll(in: contentDirectory.appendingPathComponent("dialogues", isDirectory: true))

        var showCardContent: ShowCardContent?
        let showCards = contentDirectory.appendingPathComponent("showcards.json")
        if FileManager.default.fileExists(atPath: showCards.path) {
            showCardContent = try decode(showCards)
        }

        var spotContent: SpotContent?
        let spots = contentDirectory.appendingPathComponent("spots.json")
        if FileManager.default.fileExists(atPath: spots.path) {
            spotContent = try decode(spots)
        }

        var audio: AudioManifest?
        if let audioDirectory {
            let manifest = audioDirectory.appendingPathComponent("manifest.json")
            if FileManager.default.fileExists(atPath: manifest.path) {
                audio = try decode(manifest)
            }
        }
        return ContentBundle(course: course, lessons: lessons, dialogues: dialogues, audio: audio,
                             showCardContent: showCardContent, spotContent: spotContent)
    }

    public var phrases: [Phrase] { lessons.flatMap(\.phrases) }

    public func lesson(for unitID: String) -> LessonContent? {
        lessons.first { $0.unit == unitID }
    }

    public func dialogue(for unitID: String) -> DialogueScript? {
        dialogues.first { $0.unit == unitID }
    }

    public func frame(_ id: String) -> Frame? {
        course.frames.first { $0.id == id }
    }

    public func scene(_ id: String) -> SceneTag? {
        course.scenes.first { $0.id == id }
    }

    /// The day `phrase` is first needed on the trip, or nil when the trip doesn't say.
    public func needBy(for phrase: Phrase, planner: NeedByPlanner) -> LocalDate? {
        guard let scene = scene(phrase.scene) else { return nil }
        return try? planner.resolve(scene.neededAt)
    }

    /// The day each phrase is first needed on `trip`, by phrase id. Phrases whose scene the trip
    /// doesn't place (a city it skips, an event it doesn't cover) are left out.
    public func needByDays(on trip: Trip) -> [String: LocalDate] {
        let planner = NeedByPlanner(trip: trip)
        var sceneDays: [String: LocalDate] = [:]
        for scene in course.scenes {
            if let day = try? planner.resolve(scene.neededAt) {
                sceneDays[scene.id] = day
            }
        }
        var days: [String: LocalDate] = [:]
        for phrase in phrases {
            if let day = sceneDays[phrase.scene] {
                days[phrase.id] = day
            }
        }
        return days
    }

    /// The cards a phrase gets: hear it and understand, see the intent and say it.
    public static func cards(for phrase: Phrase) -> [CardID] {
        [CardID(phraseID: phrase.id, kind: .listen), CardID(phraseID: phrase.id, kind: .recall)]
    }

    /// Every *.json file in `directory`, in file-name order; a missing directory means none.
    static func decodeAll<T: Decodable>(in directory: URL) throws -> [T] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return try files
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { try decode($0) }
    }

    static func decode<T: Decodable>(_ url: URL) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
        } catch {
            throw ContentError(file: url.lastPathComponent, reason: String(describing: error))
        }
    }
}
