import Foundation
import Testing
@testable import MammaCore

/// Runs the same cross-file checks against the repository's real Content/ folder,
/// so a broken id in course.json or a lesson file fails CI.
struct ContentTests {
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // MammaCoreTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // MammaCore
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent()

    static func loadRepositoryContent() throws -> ContentBundle {
        try ContentBundle.load(
            contentDirectory: repoRoot.appendingPathComponent("Content"),
            audioDirectory: repoRoot.appendingPathComponent("Audio")
        )
    }

    @Test func repositoryContentIsConsistent() throws {
        let bundle = try Self.loadRepositoryContent()
        let tripData = try Data(contentsOf: Self.repoRoot.appendingPathComponent("Content/trip.example.json"))
        let trip = try JSONDecoder().decode(Trip.self, from: tripData)

        let issues = ContentValidator.validate(bundle, trip: trip)
        #expect(issues.isEmpty, "\(issues.map(\.description).joined(separator: "\n"))")
    }

    @Test func courseHasThirtyLessonsAndTenChallenges() throws {
        let units = try Self.loadRepositoryContent().course.units
        #expect(units.filter { $0.kind == .lesson }.count == 30)
        #expect(units.filter { $0.kind == .challenge }.count == 10)
        #expect(Set(units.map(\.week)) == Set(1...5))
    }

    @Test func validatorCatchesBrokenReferences() {
        let course = Course(
            version: 1,
            frames: [Frame(id: "prendo", pattern: "Prendo…", use: "点单", example: "Prendo un caffè.")],
            scenes: [SceneTag(id: "bar", zh: "咖啡吧", neededAt: "somewhere")],
            units: [CourseUnit(id: "L01", kind: .lesson, week: 1, title: "t", focus: "f", frames: ["vorrei"], scene: "bar", summary: "s")]
        )
        let lesson = LessonContent(unit: "L02", phrases: [
            Phrase(id: "L01-01", it: "Ciao", zh: "你好", frame: nil, scene: "boat", status: .draft, note: nil),
        ])
        let messages = ContentValidator.validate(ContentBundle(course: course, lessons: [lesson], audio: nil))
            .map(\.message)

        #expect(messages.contains("scene bar has malformed neededAt \"somewhere\""))
        #expect(messages.contains("unit L01 uses unknown frame vorrei"))
        #expect(messages.contains("unit L02 is not in course.json"))
        #expect(messages.contains("phrase L01-01 should start with L02-"))
        #expect(messages.contains("phrase L01-01 uses unknown scene boat"))
    }

    @Test func audioManifestKeyFormat() {
        #expect(AudioManifest.key(text: "Al banco.", voice: "f1@1", speed: .slow) == "f1@1|s|Al banco.")
        let manifest = AudioManifest(version: 1, voices: ["f1@1"], entries: ["f1@1|n|Ciao!": "0123456789abcdef.m4a"])
        #expect(manifest.file(text: "Ciao!", voice: "f1@1", speed: .normal) == "0123456789abcdef.m4a")
        #expect(manifest.file(text: "Ciao!", voice: "f1@1", speed: .slow) == nil)
    }
}
