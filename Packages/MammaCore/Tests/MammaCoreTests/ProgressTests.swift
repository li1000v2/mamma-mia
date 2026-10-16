import Foundation
import Testing
@testable import MammaCore

struct ProgressTests {
    let scheduler = ReviewScheduler(config: SchedulerConfig(enableFuzz: false))
    // Whole seconds: the file stores ISO 8601 dates without fractions.
    let start = Date(timeIntervalSince1970: 1_900_000_000)

    func sampleProgress() throws -> StudyProgress {
        var progress = StudyProgress()
        let ids = [CardID(phraseID: "L05-01", kind: .listen), CardID(phraseID: "L05-01", kind: .recall)]
        progress.completeLesson("L05", cards: ids, scheduler: scheduler, at: start)
        let (card, record) = try scheduler.review(progress.cards[0], grade: .good, at: start.addingTimeInterval(60))
        progress.apply(card, record: record)
        progress.add(ChallengeRun(unit: "C02", finishedAt: start.addingTimeInterval(600), passed: true,
                                  mistakes: 1, hintsUsed: 0, keyInfoCorrect: 1, keyInfoAsked: 1))
        return progress
    }

    /// Made-up, like everything trip-shaped in the repository.
    func sampleTrip() throws -> Trip {
        Trip(
            stops: [
                Trip.Stop(city: "venezia", from: try #require(LocalDate("2030-03-01")), to: try #require(LocalDate("2030-03-03")),
                          hotel: Trip.Hotel(name: "Albergo Esempio", address: "Calle Finta 1, Venezia")),
                Trip.Stop(city: "roma", from: try #require(LocalDate("2030-03-03")), to: try #require(LocalDate("2030-03-06"))),
            ],
            diet: Diet(allergens: [.nuts, .milk], note: "示例")
        )
    }

    @Test func roundTripsThroughJSON() throws {
        let progress = try sampleProgress()
        #expect(try ProgressStore.decode(ProgressStore.encode(progress)) == progress)
    }

    @Test func backupRoundTripsWithATrip() throws {
        var progress = try sampleProgress()
        progress.trip = try sampleTrip()
        let restored = try ProgressStore.decode(ProgressStore.encode(progress))
        #expect(restored == progress)
        #expect(restored.trip?.stops.first?.hotel?.address == "Calle Finta 1, Venezia")
        #expect(restored.trip?.diet?.allergens == [.nuts, .milk])
        #expect(restored.cards == progress.cards)
    }

    @Test func backupsWithoutATripStillImport() throws {
        let progress = try sampleProgress()
        let data = try ProgressStore.encode(progress)
        // No trip, no key: the file reads like one written before the trip form existed.
        #expect(!String(decoding: data, as: UTF8.self).contains("\"trip\""))
        let restored = try ProgressStore.decode(data)
        #expect(restored == progress)
        #expect(restored.trip == nil)

        let old = #"{"version": 1, "cards": [], "reviews": [], "completedUnits": {"L01": "2030-03-01T08:00:00Z"}, "challengeRuns": []}"#
        let fromOldBuild = try ProgressStore.decode(Data(old.utf8))
        #expect(fromOldBuild.trip == nil)
        #expect(fromOldBuild.isCompleted("L01"))
    }

    @Test func aDamagedTripDoesNotCostTheLearningRecord() throws {
        let json = #"""
        {"version": 1, "completedUnits": {"L01": "2030-03-01T08:00:00Z"},
         "trip": {"timeZone": "Europe/Rome", "stops": [{"city": "roma", "from": "2030-02-30", "to": "2030-03-02"}], "events": []}}
        """#
        let progress = try ProgressStore.decode(Data(json.utf8))
        #expect(progress.isCompleted("L01"))
        #expect(progress.trip == nil)
        #expect(progress.droppedUnreadableTrip)
        let intact = try ProgressStore.decode(ProgressStore.encode(sampleProgress()))
        #expect(!intact.droppedUnreadableTrip)
    }

    @Test func restoringKeepsThePhonesTripOnlyWhenTheBackupHasNone() throws {
        var phone = StudyProgress()
        phone.trip = try sampleTrip()

        let oldBackup = try sampleProgress()
        let (restored, kept) = phone.restoring(oldBackup)
        #expect(kept)
        #expect(restored.trip == phone.trip)
        #expect(restored.cards == oldBackup.cards)
        #expect(restored.reviews == oldBackup.reviews)

        var newBackup = try sampleProgress()
        var otherTrip = try sampleTrip()
        otherTrip.stops.removeLast()
        newBackup.trip = otherTrip
        let (replaced, keptAgain) = phone.restoring(newBackup)
        #expect(!keptAgain)
        #expect(replaced == newBackup)

        let (plain, keptNothing) = StudyProgress().restoring(oldBackup)
        #expect(!keptNothing)
        #expect(plain == oldBackup)
    }

    @Test func storeKeepsTheTripUntilItIsCleared() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ProgressStore(directory: directory)
        var progress = try sampleProgress()
        progress.trip = try sampleTrip()
        try store.save(progress)
        #expect(try ProgressStore(directory: directory).load() == progress)

        progress.trip = nil
        try store.save(progress)
        #expect(try store.load().trip == nil)
        #expect(try store.load().cards == progress.cards)
    }

    @Test func missingFieldsDecodeAsEmpty() throws {
        let progress = try ProgressStore.decode(Data(#"{"version": 1, "completedUnits": {"L01": "2030-03-01T08:00:00Z"}}"#.utf8))
        #expect(progress.cards.isEmpty)
        #expect(progress.isCompleted("L01"))
        #expect(!progress.isCompleted("L02"))
    }

    @Test func refusesFilesFromNewerBuilds() {
        #expect(throws: ProgressError.newerVersion(99)) {
            try ProgressStore.decode(Data(#"{"version": 99}"#.utf8))
        }
    }

    @Test func storeKeepsABackupAndFallsBackToIt() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ProgressStore(directory: directory)
        #expect(try store.load() == StudyProgress())

        let first = try sampleProgress()
        try store.save(first)
        var second = first
        second.add(ChallengeRun(unit: "C02", finishedAt: start.addingTimeInterval(1200), passed: false,
                                mistakes: 0, hintsUsed: 2, keyInfoCorrect: 1, keyInfoAsked: 1))
        try store.save(second)
        #expect(try store.load() == second)

        try Data("not json".utf8).write(to: store.fileURL)
        #expect(try store.load() == first)
    }

    @Test func redoingALessonKeepsCardHistory() throws {
        var progress = try sampleProgress()
        let reviewed = progress.cards[0]
        progress.completeLesson("L05", cards: [reviewed.id, CardID(phraseID: "L05-02", kind: .listen)],
                                scheduler: scheduler, at: start.addingTimeInterval(3600))
        #expect(progress.cards.count == 3)
        #expect(progress.card(reviewed.id) == reviewed)
        #expect(progress.completedUnits["L05"] == start)
    }

    @Test func countsNewCardsByTheirFirstReview() throws {
        let clock = StudyClock(timeZone: LocalDate.utc, dayStartHour: 0)
        var progress = StudyProgress()
        let ids = (1...3).map { CardID(phraseID: "L05-0\($0)", kind: .recall) }
        progress.completeLesson("L05", cards: ids, scheduler: scheduler, at: start)
        for card in progress.cards {
            let (updated, record) = try scheduler.review(card, grade: .good, at: start)
            progress.apply(updated, record: record)
        }
        // A second review of the same card that day is not another new card.
        let first = try #require(progress.card(ids[0]))
        let (again, record) = try scheduler.review(first, grade: .good, at: first.due)
        progress.apply(again, record: record)

        let today = clock.day(of: start)
        #expect(progress.newCardsStarted(on: today, clock: clock) == 3)
        #expect(progress.reviewCount(on: today, clock: clock) == 4)
        #expect(progress.newCardsStarted(on: today.adding(days: 1), clock: clock) == 0)
    }
}
