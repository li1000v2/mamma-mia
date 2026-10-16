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
    public let audio: AudioManifest?

    public init(course: Course, lessons: [LessonContent], audio: AudioManifest?) {
        self.course = course
        self.lessons = lessons.sorted { $0.unit < $1.unit }
        self.audio = audio
    }

    /// Loads course.json, every lessons/*.json and, when present, the audio manifest.
    public static func load(contentDirectory: URL, audioDirectory: URL? = nil) throws -> ContentBundle {
        let course: Course = try decode(contentDirectory.appendingPathComponent("course.json"))

        let lessonsDirectory = contentDirectory.appendingPathComponent("lessons", isDirectory: true)
        let files = (try? FileManager.default.contentsOfDirectory(at: lessonsDirectory, includingPropertiesForKeys: nil)) ?? []
        let lessons: [LessonContent] = try files
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { try decode($0) }

        var audio: AudioManifest?
        if let audioDirectory {
            let manifest = audioDirectory.appendingPathComponent("manifest.json")
            if FileManager.default.fileExists(atPath: manifest.path) {
                audio = try decode(manifest)
            }
        }
        return ContentBundle(course: course, lessons: lessons, audio: audio)
    }

    public var phrases: [Phrase] { lessons.flatMap(\.phrases) }

    public func lesson(for unitID: String) -> LessonContent? {
        lessons.first { $0.unit == unitID }
    }

    public func scene(_ id: String) -> SceneTag? {
        course.scenes.first { $0.id == id }
    }

    /// The day `phrase` is first needed on the trip, or nil when the trip doesn't say.
    public func needBy(for phrase: Phrase, planner: NeedByPlanner) -> LocalDate? {
        guard let scene = scene(phrase.scene) else { return nil }
        return try? planner.resolve(scene.neededAt)
    }

    /// The cards every phrase gets by default: hear it and understand, see the intent and say it.
    public func defaultCards() -> [CardID] {
        phrases.flatMap { [CardID(phraseID: $0.id, kind: .listen), CardID(phraseID: $0.id, kind: .recall)] }
    }

    static func decode<T: Decodable>(_ url: URL) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
        } catch {
            throw ContentError(file: url.lastPathComponent, reason: String(describing: error))
        }
    }
}
