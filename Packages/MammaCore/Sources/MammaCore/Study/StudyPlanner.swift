import Foundation

/// Recommends what to study next. Nothing is locked: lessons can be done in any order and
/// challenges retried at will; this only points at the next lesson and says when a challenge's
/// lessons are done.
public struct StudyPlanner: Sendable {
    public let content: ContentBundle

    public init(content: ContentBundle) {
        self.content = content
    }

    /// The first lesson in course order that hasn't been finished.
    public func nextLesson(in progress: StudyProgress) -> CourseUnit? {
        content.course.units.first { $0.kind == .lesson && !progress.isCompleted($0.id) }
    }

    /// The lessons a challenge follows: those since the previous challenge.
    public func lessons(before challengeID: String) -> [CourseUnit] {
        var block: [CourseUnit] = []
        for unit in content.course.units {
            if unit.id == challengeID { return block }
            if unit.kind == .challenge {
                block = []
            } else {
                block.append(unit)
            }
        }
        return []
    }

    /// Challenges whose lessons are all finished but which haven't been passed yet, in course order.
    public func readyChallenges(in progress: StudyProgress) -> [CourseUnit] {
        content.course.units.filter { unit in
            unit.kind == .challenge
                && !progress.hasPassed(unit.id)
                && lessons(before: unit.id).allSatisfy { progress.isCompleted($0.id) }
        }
    }

    /// The cards finishing a lesson adds.
    public func cards(for unitID: String) -> [CardID] {
        content.lesson(for: unitID)?.phrases.flatMap(ContentBundle.cards(for:)) ?? []
    }
}
