import Foundation
import Testing
@testable import MammaCore
import FSRS

/// 随身 on the trip: the scenes each day needs, the show cards and the city packs. Made-up dates
/// only, mostly Content/trip.example.json: Venice 1–3 March 2030, Naples 3–5 with the holiday on the
/// 4th, Rome 5–8.
struct TravelTests {
    let scheduler = ReviewScheduler(config: SchedulerConfig(enableFuzz: false))
    let clock = StudyClock(timeZone: LocalDate.utc, dayStartHour: 4)

    func day(_ text: String) throws -> LocalDate {
        try #require(LocalDate(text))
    }

    // MARK: The day's scenes

    @Test func anchorsParseEveryKindOfNeededAt() {
        #expect(NeedAnchor("first") == .first)
        #expect(NeedAnchor("last") == .last)
        #expect(NeedAnchor("city:napoli") == .city("napoli"))
        #expect(NeedAnchor("event:immacolata") == .event("immacolata"))
        #expect(NeedAnchor("city:") == nil)
        #expect(NeedAnchor("napoli") == nil)
        #expect(NeedAnchor("planet:mars") == nil)
    }

    @Test func eachDayListsTheScenesItFirstNeedsMostSpecificFirst() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let trip = try ContentTests.loadExampleTrip()
        func needed(_ date: String) throws -> [String] {
            bundle.scenes(firstNeededOn: try day(date), trip: trip).map(\.id)
        }
        func city(_ date: String) throws -> [String] {
            bundle.cityScenes(on: try day(date), trip: trip).map(\.id)
        }

        // Arriving in Venice on the first day: its boats, then everything general in course order.
        let firstDay = try needed("2030-03-01")
        #expect(firstDay.first == "boat")
        #expect(firstDay.dropFirst().first == "general")
        #expect(firstDay.contains("hotel") && firstDay.contains("emergency"))
        #expect(!firstDay.contains("train") && !firstDay.contains("taxi"))

        // A second day in Venice needs nothing new; the city's scenes are still there.
        #expect(try needed("2030-03-02").isEmpty)
        #expect(try city("2030-03-02") == ["boat"])

        #expect(try needed("2030-03-03") == ["train", "pizzeria"])
        #expect(try city("2030-03-03").isEmpty)

        // The holiday in Naples: is it open today?
        #expect(try needed("2030-03-04") == ["holiday"])
        #expect(try city("2030-03-04") == ["train", "pizzeria"])

        #expect(try needed("2030-03-08") == ["taxi"])
        #expect(try city("2030-03-08") == ["metro"])

        #expect(bundle.phrases(inScene: "holiday").map(\.id) == ["L18-01", "L18-02", "L18-03", "L18-04", "L18-05"])
    }

    @Test func recapCountsTheReviewsOnTheTripsDays() throws {
        let trip = try ContentTests.loadExampleTrip()
        func record(_ phraseID: String, _ date: String) throws -> ReviewRecord {
            ReviewRecord(
                card: CardID(phraseID: phraseID, kind: .listen),
                grade: .good,
                reviewedAt: clock.start(of: try day(date)).addingTimeInterval(3600),
                elapsedDays: 1,
                scheduledDays: 3,
                stability: 3,
                difficulty: 5
            )
        }
        var progress = StudyProgress()
        progress.reviews = [
            try record("L05-01", "2030-02-27"),
            try record("L18-02", "2030-03-04"),
            try record("L18-02", "2030-03-04"),
            try record("L27-02", "2030-03-08"),
            try record("L27-02", "2030-03-09"),
        ]
        let recap = try #require(progress.recap(of: trip, clock: clock))
        #expect(recap == TripRecap(days: 8, cities: ["venezia", "napoli", "roma"], reviews: 3, phrases: 2))
        #expect(StudyProgress().recap(of: Trip(stops: []), clock: clock) == nil)
    }

    // MARK: Show cards

    @Test func hotelCardsShowTheTripsHotelsForThePhoneToRead() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let trip = try ContentTests.loadExampleTrip()
        let cards = bundle.hotelCards(for: trip)
        // Only Venice has a hotel in the example.
        #expect(cards.map(\.id) == ["hotel-venezia"])
        let lines = try #require(cards.first).lines
        #expect(lines.map(\.style) == [.sentence, .personal, .personal, .sentence])
        #expect(lines[0].text == bundle.showCardContent?.phrase(ShowCard.Source.goToAddress)?.it)
        #expect(lines[1].speech == .phoneVoice("Albergo Esempio"))
        #expect(lines[2].speech == .phoneVoice("Calle Finta 1, Venezia"))
        #expect(lines[3].text == "Me lo può indicare sulla mappa?")

        var nameOnly = trip
        nameOnly.stops[0].hotel = Trip.Hotel(name: "Albergo Esempio", address: "  ")
        let nameCard = try #require(bundle.hotelCards(for: nameOnly).first)
        #expect(nameCard.lines.filter { $0.style == .personal }.map(\.text) == ["Albergo Esempio"])
        nameOnly.stops[0].hotel = Trip.Hotel()
        #expect(bundle.hotelCards(for: nameOnly).isEmpty)
    }

    @Test func dietCardListsTheAllergensByTheirLegalNames() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        var trip = try ContentTests.loadExampleTrip()
        trip.diet = Diet(allergens: [.nuts, .milk], note: "Niente maiale, per favore")
        let card = try #require(bundle.dietCard(for: trip))
        let items = card.lines.filter { $0.style == .item }
        // Annex order, whatever order they were picked in.
        #expect(items.map(\.text) == [Allergen.milk.italian, Allergen.nuts.italian])
        #expect(items.first?.speech == .model(Allergen.milk.italian))
        #expect(card.lines.first?.text == bundle.showCardContent?.phrase(ShowCard.Source.allergicTo)?.it)
        #expect(card.lines.last?.text == bundle.showCardContent?.phrase(ShowCard.Source.tellTheCook)?.it)
        #expect(card.lines.contains { $0.style == .personal && $0.speech == .phoneVoice("Niente maiale, per favore") })

        // A note in Chinese is shown but not read by the Italian voice.
        trip.diet = Diet(allergens: [], note: "不吃生的海鲜")
        let noteOnly = try #require(bundle.dietCard(for: trip))
        #expect(!noteOnly.lines.contains { $0.style == .item })
        #expect(noteOnly.lines.contains { $0.text == "不吃生的海鲜" && $0.speech == nil })

        trip.diet = nil
        #expect(bundle.dietCard(for: trip) == nil)
    }

    @Test func everyTripGetsTheFixedCardsAndPersonalTextNeverUsesModelAudio() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        #expect(bundle.showCards(for: nil).map(\.id) == ["write", "slowly", "emergency"])
        let emergency = try #require(bundle.fixedShowCards.last)
        #expect(emergency.lines.first?.text == "112")
        #expect(emergency.lines.first?.style == .number)
        #expect(emergency.lines.contains { $0.text == "Aiuto!" })
        let write = try #require(bundle.fixedShowCards.first)
        #expect(write.lines.map(\.text) == ["Me lo può scrivere?"])

        let trip = try ContentTests.loadExampleTrip()
        let cards = bundle.showCards(for: trip)
        #expect(cards.map(\.id) == ["hotel-venezia", "diet", "write", "slowly", "emergency"])
        for line in cards.flatMap(\.lines) where line.style == .personal {
            if case .model? = line.speech {
                Issue.record("personal text would be looked up in the model audio: \(line.text)")
            }
        }
    }

    @Test func everyFixedLineHasModelAudioAtBothSpeeds() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let audio = try #require(bundle.audio)
        var trip = try ContentTests.loadExampleTrip()
        trip.diet = Diet(allergens: Allergen.allCases)
        let texts = bundle.showCards(for: trip).flatMap(\.lines).compactMap { line -> String? in
            guard case .model(let text)? = line.speech else { return nil }
            return text
        }
        // Hotel 2, diet 1 + 14 allergens + 2, write 1, slowly 1, 112 card 2.
        #expect(texts.count == 2 + 17 + 1 + 1 + 2)
        for text in texts {
            for speed in Speed.allCases {
                #expect(audio.file(for: text, speed: speed, preferring: "f1") != nil, "no \(speed) audio for \(text)")
            }
        }
    }

    @Test func onlyLatinTextIsReadByTheItalianVoice() {
        #expect(ShowCard.isLatinScript("Niente maiale, perché…"))
        #expect(ShowCard.isLatinScript("Calle Finta 1, 30121 Venezia"))
        #expect(!ShowCard.isLatinScript("不吃猪肉"))
        #expect(!ShowCard.isLatinScript("No pork 不吃猪肉"))
        #expect(!ShowCard.isLatinScript("豚肉なし"))
    }

    @Test func validatorChecksTheShowCardSentences() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let content = try #require(bundle.showCardContent)
        let broken = ShowCardContent(
            version: 1,
            phrases: content.phrases.filter { $0.id != ShowCard.Source.call112 }
                + [ShowCardPhrase(id: "L03-05", it: "Me lo scrive?", zh: "写下来", note: nil, status: .draft)],
            allergens: Array(content.allergens.dropLast())
        )
        let messages = ContentValidator.validate(
            ContentBundle(course: bundle.course, lessons: bundle.lessons, audio: nil, showCardContent: broken)
        ).map(\.message)
        #expect(messages.contains("the show cards need a phrase call-112"))
        #expect(messages.contains("phrase id L03-05 is also a lesson phrase"))
        #expect(messages.contains("allergens must be the 14 of Allergen, in annex order, with the same Italian"))
    }

    // MARK: City packs

    @Test func packsHoldWhatEachArrivalFirstNeeds() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let trip = try ContentTests.loadExampleTrip()
        let packs = bundle.cityPacks(on: trip)
        #expect(packs.map(\.city) == ["venezia", "napoli", "roma"])
        #expect(packs.map(\.eve) == [try day("2030-02-28"), try day("2030-03-02"), try day("2030-03-04")])

        // Before the first city also everything needed from the first day: the need-by days decide.
        let firstDay = try day("2030-03-01")
        let neededFirst = Set(bundle.needByDays(on: trip).filter { $0.value == firstDay }.map(\.key))
        #expect(packs[0].phraseIDs == neededFirst)
        #expect(packs[0].scenes.first?.id == "boat")
        #expect(packs[1].scenes.map(\.id) == ["train", "pizzeria"])
        #expect(packs[1].phraseIDs == Set(bundle.phrases.filter { ["train", "pizzeria"].contains($0.scene) }.map(\.id)))
        #expect(packs[2].scenes.map(\.id) == ["metro"])
    }

    @Test func aPackOpensTheEveningBeforeAndClosesWithTheArrivalDay() throws {
        let pack = CityPack(city: "napoli", arrival: try day("2030-03-03"), scenes: [], phraseIDs: ["L14-01"])
        let eve = try day("2030-03-02")
        let zone = clock.timeZone
        #expect(pack.opens(clock) == eve.start(in: zone, hour: CityPack.eveningHour))
        #expect(!pack.isOpen(at: eve.start(in: zone, hour: 18), clock: clock))
        #expect(pack.isOpen(at: eve.start(in: zone, hour: 19), clock: clock))
        #expect(pack.isOpen(at: try day("2030-03-03").start(in: zone, hour: 23), clock: clock))
        // The arrival's study day ends at four the next morning.
        #expect(pack.isOpen(at: try day("2030-03-04").start(in: zone, hour: 3), clock: clock))
        #expect(!pack.isOpen(at: try day("2030-03-04").start(in: zone, hour: 4), clock: clock))
    }

    @Test func aPackTakesTheWeakestCardsAndKeepsThemWhileYouReview() throws {
        let arrival = try day("2030-03-03")
        let ids = (1...40).map { "L14-\($0 < 10 ? "0" : "")\($0)" }
        let pack = CityPack(city: "napoli", arrival: arrival, scenes: [], phraseIDs: Set(ids))
        let opens = pack.opens(clock)
        let deadline = clock.start(of: arrival)
        // All seen ten days before arrival; the lower the stability, the lower the recall then.
        var cards = ids.enumerated().map { index, id in
            reviewedCard(id, stability: Double(index + 1) * 3, lastReviewDaysAgo: 10, now: deadline)
        }
        // A new card and another city's card stay out.
        cards.append(scheduler.makeCard(CardID(phraseID: "L14-01", kind: .listen), now: opens))
        cards.append(reviewedCard("L21-01", stability: 1, lastReviewDaysAgo: 10, now: deadline))

        #expect(scheduler.packCards(cards: cards, packs: [pack], now: opens.addingTimeInterval(-60), clock: clock).isEmpty)

        let now = opens.addingTimeInterval(3600)
        let pending = scheduler.packCards(cards: cards, packs: [pack], now: now, clock: clock)
        #expect(pending.count == CityPack.size)
        #expect(pending.map(\.id.phraseID) == Array(ids.prefix(CityPack.size)))

        // Reviewing some of them leaves the rest of the same set, whichever were done.
        var reviewed = cards
        for card in pending.prefix(4) + pending.suffix(1) {
            let index = try #require(reviewed.firstIndex { $0.id == card.id })
            reviewed[index] = try scheduler.review(card, grade: .good, at: now).card
        }
        let rest = scheduler.packCards(cards: reviewed, packs: [pack], now: now.addingTimeInterval(60), clock: clock)
        #expect(rest.map(\.id) == pending.dropFirst(4).dropLast().map(\.id))

        #expect(scheduler.packCards(cards: cards, packs: [pack], now: pack.closes(clock), clock: clock).isEmpty)
    }

    @Test func packCardsJoinTheReviewsWhileThePackIsOpen() throws {
        let arrival = try day("2030-03-03")
        let pack = CityPack(city: "napoli", arrival: arrival, scenes: [], phraseIDs: ["L14-01", "L14-02"])
        let deadline = clock.start(of: arrival)
        // Remembered well enough that neither FSRS nor the trip boost would show it before arrival.
        let strong = reviewedCard("L14-01", stability: 200, lastReviewDaysAgo: 2, now: deadline)
        // Due anyway.
        let due = reviewedCard("L14-02", stability: 5, lastReviewDaysAgo: 8, now: deadline)
        let needBy: (ReviewCard) -> LocalDate? = { _ in arrival }
        let evening = pack.opens(clock).addingTimeInterval(600)

        let plan = scheduler.plan(cards: [strong, due], newIntroducedToday: 0, now: evening, clock: clock,
                                  needBy: needBy, packs: [pack])
        #expect(plan.due.map(\.id.phraseID) == ["L14-02"])
        #expect(plan.boosted.isEmpty)
        #expect(plan.packed.map(\.id.phraseID) == ["L14-01"])

        var left = [strong, due]
        var order: [String] = []
        while let next = scheduler.nextCard(from: left, newBudget: 0, now: evening, clock: clock, needBy: needBy, packs: [pack]) {
            order.append(next.id.phraseID)
            left.removeAll { $0.id == next.id }
        }
        #expect(order == ["L14-02", "L14-01"])

        // That morning the pack isn't open yet: FSRS alone.
        let morning = pack.opens(clock).addingTimeInterval(-8 * 3600)
        #expect(scheduler.plan(cards: [strong, due], newIntroducedToday: 0, now: morning, clock: clock,
                               needBy: needBy, packs: [pack]).packed.isEmpty)
        #expect(scheduler.nextCard(from: [strong], newBudget: 0, now: morning, clock: clock, needBy: needBy, packs: [pack]) == nil)
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
