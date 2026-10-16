import Foundation

public struct ContentIssue: Hashable, Sendable, CustomStringConvertible {
    public let location: String
    public let message: String

    public var description: String { "\(location): \(message)" }
}

/// Cross-file checks the JSON Schemas can't express: ids that must exist, be unique, or line up.
public enum ContentValidator {
    public static func validate(_ bundle: ContentBundle, trip: Trip? = nil) -> [ContentIssue] {
        var issues: [ContentIssue] = []
        func report(_ location: String, _ message: String) {
            issues.append(ContentIssue(location: location, message: message))
        }

        let course = bundle.course
        let frameIDs = Set(course.frames.map(\.id))
        let sceneIDs = Set(course.scenes.map(\.id))
        let unitIDs = Set(course.units.map(\.id))

        for id in duplicates(course.frames.map(\.id)) { report("course.json", "duplicate frame id \(id)") }
        for id in duplicates(course.scenes.map(\.id)) { report("course.json", "duplicate scene id \(id)") }
        for id in duplicates(course.units.map(\.id)) { report("course.json", "duplicate unit id \(id)") }

        for scene in course.scenes where !NeedByPlanner.isWellFormed(scene.neededAt) {
            report("course.json", "scene \(scene.id) has malformed neededAt \"\(scene.neededAt)\"")
        }
        for unit in course.units {
            let prefix = unit.kind == .lesson ? "L" : "C"
            if !unit.id.hasPrefix(prefix) {
                report("course.json", "\(unit.kind.rawValue) \(unit.id) should start with \(prefix)")
            }
            if !sceneIDs.contains(unit.scene) {
                report("course.json", "unit \(unit.id) uses unknown scene \(unit.scene)")
            }
            for frame in unit.frames where !frameIDs.contains(frame) {
                report("course.json", "unit \(unit.id) uses unknown frame \(frame)")
            }
        }

        var phraseIDs = Set<String>()
        for id in duplicates(bundle.lessons.map(\.unit)) { report("lessons/", "more than one file for unit \(id)") }
        for lesson in bundle.lessons {
            let file = "lessons/\(lesson.unit).json"
            if !unitIDs.contains(lesson.unit) { report(file, "unit \(lesson.unit) is not in course.json") }
            for phrase in lesson.phrases {
                if !phraseIDs.insert(phrase.id).inserted { report(file, "duplicate phrase id \(phrase.id)") }
                if !phrase.id.hasPrefix(lesson.unit + "-") {
                    report(file, "phrase \(phrase.id) should start with \(lesson.unit)-")
                }
                if let frame = phrase.frame, !frameIDs.contains(frame) {
                    report(file, "phrase \(phrase.id) uses unknown frame \(frame)")
                }
                if !sceneIDs.contains(phrase.scene) {
                    report(file, "phrase \(phrase.id) uses unknown scene \(phrase.scene)")
                }
                if phrase.it.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || phrase.zh.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    report(file, "phrase \(phrase.id) has empty text")
                }
            }
        }

        if let trip {
            let planner = NeedByPlanner(trip: trip)
            for scene in course.scenes where NeedByPlanner.isWellFormed(scene.neededAt) {
                do {
                    _ = try planner.resolve(scene.neededAt)
                } catch {
                    report("trip", "scene \(scene.id) can't be placed on the trip: \(error)")
                }
            }
        }
        return issues
    }

    static func duplicates(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        var repeated = Set<String>()
        for id in ids where !seen.insert(id).inserted { repeated.insert(id) }
        return repeated.sorted()
    }
}
