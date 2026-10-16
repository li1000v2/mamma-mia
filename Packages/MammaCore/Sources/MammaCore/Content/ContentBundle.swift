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

    public init(course: Course, lessons: [LessonContent], dialogues: [DialogueScript] = [], audio: AudioManifest?) {
        self.course = course
        self.lessons = lessons.sorted { $0.unit < $1.unit }
        self.dialogues = dialogues.sorted { $0.unit < $1.unit }
        self.audio = audio
    }

    /// Loads course.json, every lessons/*.json and dialogues/*.json and, when present, the audio manifest.
    public static func load(contentDirectory: URL, audioDirectory: URL? = nil) throws -> ContentBundle {
        let course: Course = try decode(contentDirectory.appendingPathComponent("course.json"))
        let lessons: [LessonContent] = try decodeAll(in: contentDirectory.appendingPathComponent("lessons", isDirectory: true))
        let dialogues: [DialogueScript] = try decodeAll(in: contentDirectory.appendingPathComponent("dialogues", isDirectory: true))

        var audio: AudioManifest?
        if let audioDirectory {
            let manifest = audioDirectory.appendingPathComponent("manifest.json")
            if FileManager.default.fileExists(atPath: manifest.path) {
                audio = try decode(manifest)
            }
        }
        return ContentBundle(course: course, lessons: lessons, dialogues: dialogues, audio: audio)
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
