import Foundation
import Testing
@testable import MammaCore
import FSRS

struct QueueTests {
    let scheduler = ReviewScheduler(config: SchedulerConfig(enableFuzz: false))
    let clock = StudyClock(timeZone: LocalDate.utc, dayStartHour: 0)
    let now = Date(timeIntervalSince1970: 1_900_000_000) // 17:46 UTC

    func card(_ id: String, state: CardState, due: Date, stability: Double, lastReview: Date) -> ReviewCard {
        ReviewCard(
            id: CardID(phraseID: id, kind: .recall),
            memory: Card(due: due, stability: stability, difficulty: 5, state: state, lastReview: lastReview)
        )
    }

    @Test func learningStepsThenWeakestReviewsThenNewCards() {
        let learning = card("learn", state: .learning, due: now.addingTimeInterval(-60), stability: 1,
                            lastReview: now.addingTimeInterval(-600))
        let weak = card("weak", state: .review, due: now.addingTimeInterval(-86_400), stability: 2,
                        lastReview: now.addingTimeInterval(-6 * 86_400))
        // Due later today: still part of today's reviews.
        let strong = card("strong", state: .review, due: now.addingTimeInterval(3600), stability: 40,
                          lastReview: now.addingTimeInterval(-40 * 86_400 + 3600))
        let fresh = scheduler.makeCard(CardID(phraseID: "new", kind: .listen), now: now)

        func next(_ cards: [ReviewCard], budget: Int = 5) -> String? {
            scheduler.nextCard(from: cards, newBudget: budget, now: now, clock: clock)?.id.phraseID
        }
        #expect(next([fresh, strong, weak, learning]) == "learn")
        #expect(next([fresh, strong, weak]) == "weak")
        #expect(next([fresh, strong]) == "strong")
        #expect(next([fresh]) == "new")
        #expect(next([fresh], budget: 0) == nil)
    }

    @Test func learnsAheadWhenNothingElseIsLeft() {
        let soon = card("soon", state: .learning, due: now.addingTimeInterval(5 * 60), stability: 1, lastReview: now)
        let later = card("later", state: .learning, due: now.addingTimeInterval(45 * 60), stability: 1, lastReview: now)
        #expect(scheduler.nextCard(from: [later, soon], newBudget: 0, now: now, clock: clock)?.id.phraseID == "soon")
        #expect(scheduler.nextCard(from: [later], newBudget: 0, now: now, clock: clock) == nil)
    }

    @Test func betterGradesScheduleFurtherOut() throws {
        var card = scheduler.makeCard(CardID(phraseID: "x", kind: .recall), now: now)
        for _ in 0..<3 {
            (card, _) = try scheduler.review(card, grade: .good, at: card.due)
        }
        let outcomes = scheduler.outcomes(for: card, at: card.due)
        let again = try #require(outcomes[.again])
        let hard = try #require(outcomes[.hard])
        let good = try #require(outcomes[.good])
        let easy = try #require(outcomes[.easy])
        #expect(again < hard)
        #expect(hard <= good)
        #expect(good < easy)
    }

    @Test func intervalLabels() {
        #expect(IntervalText.short(30) == "<1 分钟")
        #expect(IntervalText.short(10 * 60) == "10 分钟")
        #expect(IntervalText.short(5 * 3600) == "5 小时")
        #expect(IntervalText.short(3 * 86_400) == "3 天")
        #expect(IntervalText.short(65 * 86_400) == "2 个月")
        #expect(IntervalText.short(400 * 86_400) == "1.1 年")
    }
}
