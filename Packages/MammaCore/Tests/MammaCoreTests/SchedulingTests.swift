import Foundation
import Testing
@testable import MammaCore
import FSRS

struct SchedulingTests {
    static let exampleTripJSON = """
    {
      "timeZone": "Europe/Rome",
      "stops": [
        {"city": "venezia", "from": "2030-03-01", "to": "2030-03-03"},
        {"city": "napoli", "from": "2030-03-03", "to": "2030-03-05"},
        {"city": "roma", "from": "2030-03-05", "to": "2030-03-08"}
      ],
      "events": [{"id": "festa", "date": "2030-03-04"}]
    }
    """

    let scheduler = ReviewScheduler(config: SchedulerConfig(enableFuzz: false))
    let start = Date(timeIntervalSince1970: 1_900_000_000)
    let cardID = CardID(phraseID: "L05-01", kind: .recall)

    @Test func usesFSRS6Parameters() {
        #expect(scheduler.usesFSRS6)
    }

    @Test func goodAnswersPushTheNextReviewOut() throws {
        var card = scheduler.makeCard(cardID, now: start)
        #expect(card.isNew)
        for _ in 0..<4 {
            (card, _) = try scheduler.review(card, grade: .good, at: card.due)
        }
        #expect(!card.isNew)
        #expect(card.reps == 4)
        #expect(card.due.timeIntervalSince(start) > 3 * 86_400)
    }

    @Test func againBringsTheCardBackWithinTheSession() throws {
        let (card, record) = try scheduler.review(scheduler.makeCard(cardID, now: start), grade: .again, at: start)
        #expect(card.due.timeIntervalSince(start) < 3600)
        #expect(record.grade == .again)
        #expect(record.card == cardID)
    }

    @Test func recallFadesOverTime() throws {
        var card = scheduler.makeCard(cardID, now: start)
        for _ in 0..<3 {
            (card, _) = try scheduler.review(card, grade: .good, at: card.due)
        }
        let atDue = scheduler.retrievability(of: card, at: card.due)
        let monthLater = scheduler.retrievability(of: card, at: card.due.addingTimeInterval(30 * 86_400))
        #expect(monthLater < atDue)
    }

    @Test func dailyPlanCapsNewCardsAndPutsWeakestReviewsFirst() throws {
        let clock = StudyClock(timeZone: LocalDate.utc, dayStartHour: 0)
        let now = start
        // Both overdue; the low-stability one has the lower predicted recall, so it comes first.
        let weak = reviewedCard("L01-01", stability: 2, lastReviewDaysAgo: 6, now: now)
        let strong = reviewedCard("L01-02", stability: 50, lastReviewDaysAgo: 51, now: now)
        let notDue = reviewedCard("L01-03", stability: 50, lastReviewDaysAgo: 1, now: now)
        let newCards = (1...30).map { scheduler.makeCard(CardID(phraseID: "L02-\($0)", kind: .listen), now: now) }

        let plan = scheduler.plan(cards: [strong, notDue, weak] + newCards, newIntroducedToday: 15, now: now, clock: clock)

        #expect(plan.due.map(\.id.phraseID) == ["L01-01", "L01-02"])
        #expect(plan.new.count == 5)
        #expect(plan.new.first?.id.phraseID == "L02-1")
    }

    @Test func needByResolvesEveryAnchor() throws {
        let planner = NeedByPlanner(trip: try Self.exampleTrip())
        #expect(try planner.resolve("first") == LocalDate("2030-03-01"))
        #expect(try planner.resolve("last") == LocalDate("2030-03-08"))
        #expect(try planner.resolve("city:napoli") == LocalDate("2030-03-03"))
        #expect(try planner.resolve("event:festa") == LocalDate("2030-03-04"))
        #expect(throws: NeedByError.unknownCity("milano")) { try planner.resolve("city:milano") }
        #expect(throws: NeedByError.malformed("napoli")) { try planner.resolve("napoli") }
        #expect(!NeedByPlanner.isWellFormed("city:"))
    }

    @Test func boostPicksOnlyAtRiskCardsInsideTheWindow() throws {
        let clock = StudyClock(timeZone: LocalDate.utc, dayStartHour: 0)
        let needBy = try #require(LocalDate("2030-03-05"))
        let deadline = clock.start(of: needBy)
        let now = deadline.addingTimeInterval(-3 * 86_400 + 10 * 3600) // three days before, mid-morning

        // Seen 20 days before the deadline with a 30-day stability: about 0.93 recall on the day.
        let atRisk = reviewedCard("L08-01", stability: 30, lastReviewDaysAgo: 20, now: deadline)
        // Seen 5 days before: about 0.98 recall, fresh enough.
        let fresh = reviewedCard("L08-02", stability: 30, lastReviewDaysAgo: 5, now: deadline)
        // Due before the deadline anyway, so the normal queue handles it.
        let dueAnyway = reviewedCard("L08-03", stability: 20, lastReviewDaysAgo: 25, now: deadline)
        // Needed ten days later: outside the window.
        let later = reviewedCard("L21-01", stability: 30, lastReviewDaysAgo: 20, now: deadline)

        let candidates = scheduler.boostCandidates(
            cards: [fresh, later, dueAnyway, atRisk],
            needBy: { $0.id.phraseID.hasPrefix("L21") ? needBy.adding(days: 10) : needBy },
            now: now,
            clock: clock
        )

        #expect(candidates.map(\.card.id.phraseID) == ["L08-01"])
        let recall = try #require(candidates.first?.predictedRecall)
        #expect(recall > 0.9 && recall < 0.95)
    }

    @Test func reviewsNeededSoonestComeFirstAndBoostsJoinTheQueue() throws {
        let clock = StudyClock(timeZone: LocalDate.utc, dayStartHour: 0)
        let today = try #require(LocalDate("2030-03-02"))
        let now = clock.start(of: today).addingTimeInterval(10 * 3600)
        let deadline = clock.start(of: today.adding(days: 3))

        // Not due until after the day it's needed, and below 0.95 recall by then: a boost.
        let boost = reviewedCard("L08-01", stability: 30, lastReviewDaysAgo: 20, now: deadline)
        // Due today anyway: needed tomorrow, in five days, and not tied to the trip.
        let tomorrow = reviewedCard("L09-01", stability: 10, lastReviewDaysAgo: 11, now: now)
        let inFiveDays = reviewedCard("L21-01", stability: 10, lastReviewDaysAgo: 11, now: now)
        let offTrip = reviewedCard("L01-01", stability: 2, lastReviewDaysAgo: 8, now: now)
        let days: [String: LocalDate] = [
            "L08-01": today.adding(days: 3),
            "L09-01": today.adding(days: 1),
            "L21-01": today.adding(days: 5),
        ]
        let needBy: (ReviewCard) -> LocalDate? = { days[$0.id.phraseID] }
        let all = [offTrip, inFiveDays, boost, tomorrow]

        var left = all
        var order: [String] = []
        while let next = scheduler.nextCard(from: left, newBudget: 0, now: now, clock: clock, needBy: needBy) {
            order.append(next.id.phraseID)
            left.removeAll { $0.id == next.id }
        }
        #expect(order == ["L09-01", "L08-01", "L21-01", "L01-01"])

        let plan = scheduler.plan(cards: all, newIntroducedToday: 0, now: now, clock: clock, needBy: needBy)
        #expect(plan.boosted.map(\.id.phraseID) == ["L08-01"])
        #expect(plan.due.map(\.id.phraseID) == ["L09-01", "L21-01", "L01-01"])

        // Without a trip it's plain FSRS: the boost isn't due and the weakest review goes first.
        let plain = scheduler.plan(cards: all, newIntroducedToday: 0, now: now, clock: clock)
        #expect(plain.boosted.isEmpty)
        #expect(plain.due.first?.id.phraseID == "L01-01")
        #expect(scheduler.nextCard(from: [boost], newBudget: 0, now: now, clock: clock) == nil)
    }

    @Test func aBoostedCardIsAnOrdinaryReview() throws {
        let clock = StudyClock(timeZone: LocalDate.utc, dayStartHour: 0)
        let needByDay = try #require(LocalDate("2030-03-05"))
        let deadline = clock.start(of: needByDay)
        let now = deadline.addingTimeInterval(-2 * 86_400 + 9 * 3600)
        let boost = reviewedCard("L08-01", stability: 30, lastReviewDaysAgo: 20, now: deadline)
        let needBy: (ReviewCard) -> LocalDate? = { _ in needByDay }

        #expect(scheduler.nextCard(from: [boost], newBudget: 0, now: now, clock: clock, needBy: needBy)?.id == boost.id)
        let (graded, record) = try scheduler.review(boost, grade: .good, at: now)
        #expect(record.grade == .good)
        #expect(graded.reps == boost.reps + 1)
        // Reviewed today, so it isn't boosted again today.
        #expect(scheduler.nextCard(from: [graded], newBudget: 0, now: now.addingTimeInterval(60), clock: clock, needBy: needBy) == nil)
    }

    static func exampleTrip() throws -> Trip {
        try JSONDecoder().decode(Trip.self, from: Data(exampleTripJSON.utf8))
    }

    /// A card in review state whose last review was a whole number of days before `now`.
    func reviewedCard(_ phraseID: String, stability: Double, lastReviewDaysAgo days: Double, now: Date) -> ReviewCard {
        let lastReview = now.addingTimeInterval(-days * 86_400)
        let memory = Card(
            due: lastReview.addingTimeInterval(stability * 86_400),
            stability: stability,
            difficulty: 5,
            scheduledDays: stability,
            reps: 3,
            state: .review,
            lastReview: lastReview
        )
        return ReviewCard(id: CardID(phraseID: phraseID, kind: .recall), memory: memory)
    }
}
