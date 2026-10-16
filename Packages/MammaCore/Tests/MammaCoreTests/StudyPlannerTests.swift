import Foundation
import Testing
@testable import MammaCore

struct StudyPlannerTests {
    let scheduler = ReviewScheduler()
    let epoch = Date(timeIntervalSince1970: 0)

    static func unit(_ id: String, _ kind: UnitKind) -> CourseUnit {
        CourseUnit(id: id, kind: kind, week: 1, title: id, focus: "—", frames: [], scene: "general", summary: "—")
    }

    func makePlanner() -> StudyPlanner {
        let course = Course(
            version: 1,
            frames: [],
            scenes: [SceneTag(id: "general", zh: "通用", neededAt: "first")],
            units: [
                Self.unit("L01", .lesson), Self.unit("L02", .lesson), Self.unit("C01", .challenge),
                Self.unit("L03", .lesson), Self.unit("C02", .challenge),
            ]
        )
        let lesson = LessonContent(unit: "L01", intro: nil, phrases: [
            Phrase(id: "L01-01", it: "Ciao", zh: "你好", frame: nil, scene: "general", status: .draft, note: nil),
        ])
        return StudyPlanner(content: ContentBundle(course: course, lessons: [lesson], audio: nil))
    }

    @Test func recommendsLessonsInOrderAndChallengesAfterTheirLessons() {
        let planner = makePlanner()
        var progress = Progress()
        #expect(planner.nextLesson(in: progress)?.id == "L01")
        #expect(planner.readyChallenges(in: progress).isEmpty)
        #expect(planner.lessons(before: "C02").map(\.id) == ["L03"])

        progress.completeLesson("L01", cards: planner.cards(for: "L01"), scheduler: scheduler, at: epoch)
        progress.completeLesson("L02", cards: planner.cards(for: "L02"), scheduler: scheduler, at: epoch)
        #expect(planner.nextLesson(in: progress)?.id == "L03")
        #expect(planner.readyChallenges(in: progress).map(\.id) == ["C01"])
        #expect(progress.cards.map(\.id.description) == ["L01-01#listen", "L01-01#recall"])

        progress.add(ChallengeRun(unit: "C01", finishedAt: epoch, passed: true, mistakes: 0, hintsUsed: 0,
                                  keyInfoCorrect: 0, keyInfoAsked: 0))
        #expect(planner.readyChallenges(in: progress).isEmpty)
    }
}
