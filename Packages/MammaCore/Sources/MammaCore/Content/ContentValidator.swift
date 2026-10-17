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
        for id in duplicates(course.cities.map(\.id)) { report("course.json", "duplicate city id \(id)") }
        for id in duplicates(course.events.map(\.id)) { report("course.json", "duplicate event id \(id)") }

        // 2000 is a leap year, so only dates that never exist fail.
        for event in course.events where event.date(in: 2000) == nil {
            report("course.json", "event \(event.id) has no valid date \(event.month)/\(event.day)")
        }
        for scene in course.scenes {
            switch scene.anchor {
            case nil:
                report("course.json", "scene \(scene.id) has malformed neededAt \"\(scene.neededAt)\"")
            case .city(let city)? where course.city(city) == nil:
                report("course.json", "scene \(scene.id) needs unknown city \(city)")
            case .event(let event)? where course.event(event) == nil:
                report("course.json", "scene \(scene.id) needs unknown event \(event)")
            default:
                break
            }
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

        func check(_ node: DialogueNode, in file: String) {
            if node.npc.isEmpty { report(file, "node \(node.id) has no lines") }
            if node.question != nil {
                for line in node.npc {
                    guard let answer = line.answer, let distractors = line.distractors, !distractors.isEmpty else {
                        report(file, "node \(node.id) asks a question but a line has no answer or distractors")
                        continue
                    }
                    if distractors.contains(answer) {
                        report(file, "node \(node.id) lists its answer \(answer) as a distractor")
                    }
                }
            }
            if let reply = node.reply {
                if !reply.choices.contains(where: \.correct) { report(file, "node \(node.id) has no correct choice") }
                if reply.choices.count < 2 { report(file, "node \(node.id) needs at least two choices") }
                if let frame = reply.frame, !frameIDs.contains(frame) {
                    report(file, "node \(node.id) uses unknown frame \(frame)")
                }
            }
        }

        let challengeIDs = Set(course.units.filter { $0.kind == .challenge }.map(\.id))
        for id in duplicates(bundle.dialogues.map(\.unit)) { report("dialogues/", "more than one file for unit \(id)") }
        for script in bundle.dialogues {
            let file = "dialogues/\(script.unit).json"
            let pool = script.followUps?.pool ?? []
            if !challengeIDs.contains(script.unit) { report(file, "\(script.unit) is not a challenge in course.json") }
            if script.nodes.isEmpty { report(file, "has no nodes") }
            for id in duplicates((script.nodes + pool).map(\.id)) { report(file, "duplicate node id \(id)") }
            for node in script.nodes + pool { check(node, in: file) }
            if let followUps = script.followUps {
                if !script.nodes.contains(where: { $0.id == followUps.after }) {
                    report(file, "followUps.after \(followUps.after) is not a node")
                }
                if followUps.min < 0 || followUps.min > followUps.max || followUps.max > pool.count {
                    report(file, "followUps needs 0 ≤ min ≤ max ≤ pool size")
                }
            }
        }

        if let cards = bundle.showCardContent {
            let file = "showcards.json"
            for id in duplicates(cards.phrases.map(\.id)) { report(file, "duplicate phrase id \(id)") }
            for phrase in cards.phrases where phraseIDs.contains(phrase.id) {
                report(file, "phrase id \(phrase.id) is also a lesson phrase")
            }
            for phrase in cards.phrases where phrase.it.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || phrase.zh.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                report(file, "phrase \(phrase.id) has empty text")
            }
            for id in ShowCard.Source.cardPhrases where cards.phrase(id) == nil {
                report(file, "the show cards need a phrase \(id)")
            }
            for id in ShowCard.Source.coursePhrases where !phraseIDs.contains(id) {
                report(file, "the show cards reuse lesson phrase \(id), which doesn't exist")
            }
            let names = Allergen.allCases.map { ShowCardContent.AllergenName(id: $0.rawValue, it: $0.italian) }
            if cards.allergens != names {
                report(file, "allergens must be the 14 of Allergen, in annex order, with the same Italian")
            }
        }

        if let rolePlay = bundle.rolePlay {
            let file = "roleplay.json"
            for id in duplicates(rolePlay.roles.map(\.unit)) { report(file, "more than one role for \(id)") }
            if rolePlay.fillers.isEmpty { report(file, "has no fillers") }
            for filler in rolePlay.fillers where filler.trimmingCharacters(in: .whitespaces).isEmpty {
                report(file, "has an empty filler")
            }
            for role in rolePlay.roles {
                if !challengeIDs.contains(role.unit) { report(file, "role for \(role.unit), which is not a challenge in course.json") }
                if !sceneIDs.contains(role.scene) { report(file, "role \(role.unit) uses unknown scene \(role.scene)") }
                if [role.name, role.zh, role.setting, role.task].contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                    report(file, "role \(role.unit) has empty text")
                }
                guard let audio = bundle.audio else { continue }
                if audio.profile(for: role.voice) == nil {
                    report(file, "role \(role.unit) uses voice \(role.voice), which the audio manifest doesn't have")
                } else if audio.voiceName(for: role.voice) == nil {
                    report(file, "role \(role.unit): the audio manifest has no Gemini voice name for \(role.voice)")
                }
            }
        }

        if let trip {
            for issue in trip.issues(knownCities: Set(course.cities.map(\.id))) {
                report("trip", "\(issue)")
            }
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
