import Foundation
import Testing
@testable import MammaCore

/// The pilgrimage layer: the spots in Content/spots.json, their order on the trip, their sentences,
/// the learner's check-ins and the badges. Made-up dates only, mostly Content/trip.example.json:
/// Venice 1–3 March 2030, Naples 3–5, Rome 5–8.
struct PilgrimageTests {
    func day(_ text: String) throws -> LocalDate {
        try #require(LocalDate(text))
    }

    /// Noon UTC on a made-up day, in whole seconds like the progress file.
    func moment(_ text: String, hour: Int = 12) throws -> Date {
        try day(text).start(in: LocalDate.utc, hour: hour)
    }

    @Test func theRepositoryHasTheCandidateSpotsInItaly() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let content = try #require(bundle.spotContent)
        #expect(content.spots.map(\.id) == ["santa-lucia", "san-giorgio", "capodichino", "posillipo", "pompei", "capri", "colosseo"])
        #expect(content.spots.filter(\.isDayTrip).map(\.id) == ["pompei", "capri"])
        for spot in content.spots {
            #expect((36.0...47.5).contains(spot.latitude) && (6.0...19.0).contains(spot.longitude), "\(spot.id) is off Italy")
            #expect(!bundle.lines(at: spot).isEmpty)
        }
        // The validator also runs in ContentTests.repositoryContentIsConsistent; spot ids are its subject here.
        #expect(ContentValidator.validate(bundle).filter { $0.location == "spots.json" }.isEmpty)
    }

    @Test func todaysCityComesFirstDuringTheTrip() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let trip = try ContentTests.loadExampleTrip()
        func order(_ date: String, trip: Trip? = nil) throws -> [String] {
            bundle.spotGroups(trip: trip, on: try day(date)).map(\.city)
        }

        #expect(try order("2030-02-20", trip: trip) == ["venezia", "napoli", "roma"])
        #expect(try order("2030-03-04", trip: trip) == ["napoli", "venezia", "roma"])
        // On the day you move from Naples to Rome, the city you arrive in.
        #expect(try order("2030-03-05", trip: trip) == ["roma", "venezia", "napoli"])
        #expect(try order("2030-03-20", trip: trip) == ["venezia", "napoli", "roma"])
        #expect(try order("2030-03-04") == ["venezia", "napoli", "roma"])

        // A trip without Rome still lists its spot, after the trip's cities.
        var shorter = trip
        shorter.stops.removeAll { $0.city == "roma" }
        #expect(try order("2030-03-02", trip: shorter) == ["venezia", "napoli", "roma"])

        let napoli = try #require(bundle.spotGroups(trip: trip, on: try day("2030-03-04")).first)
        #expect(napoli.spots.map(\.id) == ["capodichino", "posillipo"])
        #expect(napoli.dayTrips.map(\.id) == ["pompei", "capri"])
        #expect(napoli.all.count == 4)
    }

    @Test func aSpotsLinesComeFromTheCourseAndFromSpotsJson() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let content = try #require(bundle.spotContent)
        let capri = try #require(content.spot("capri"))
        let lines = bundle.lines(at: capri)
        #expect(lines.map(\.id) == ["last-boat-to-napoli", "L14-01"])
        #expect(lines[0].it == content.phrase("last-boat-to-napoli")?.it)
        #expect(lines[1].it == "Un biglietto per Napoli, per favore.")
        #expect(bundle.commonSpotLines.map(\.id) == ["L23-01", "L23-02", "L23-03", "L23-05"])
        #expect(bundle.commonSpotLines.first?.it == "Mi può fare una foto?")
    }

    @Test func checkInsAndNotesAreKeptPerSpot() throws {
        var progress = StudyProgress()
        let second = try moment("2030-03-02")
        let earlier = try moment("2030-03-01")
        progress.checkIn(atSpot: "colosseo", on: second.addingTimeInterval(0.75))
        progress.checkIn(atSpot: "colosseo", on: earlier)
        let log = try #require(progress.spotLogs["colosseo"])
        // Whole seconds, as the file keeps them, oldest first.
        #expect(log.checkIns == [earlier, second])
        #expect(log.firstCheckIn == earlier)
        // A double tap within the same second checks in once.
        progress.checkIn(atSpot: "colosseo", on: second.addingTimeInterval(0.2))
        #expect(progress.spotLogs["colosseo"]?.checkIns == [earlier, second])

        progress.setNote("  Il mio posto preferito \n", forSpot: "colosseo")
        #expect(progress.spotLogs["colosseo"]?.note == "Il mio posto preferito")
        progress.setNote("   ", forSpot: "colosseo")
        #expect(progress.spotLogs["colosseo"]?.note == nil)

        progress.removeCheckIn(atSpot: "colosseo", earlier)
        progress.removeCheckIn(atSpot: "colosseo", second)
        // Nothing left: the spot drops out of the file.
        #expect(progress.spotLogs["colosseo"] == nil)

        progress.setNote("示例", forSpot: "capri")
        #expect(progress.spotLogs["capri"] == SpotLog(note: "示例"))
        progress.removeCheckIn(atSpot: "capri", earlier)
        #expect(progress.spotLogs["capri"]?.note == "示例")
    }

    @Test func aCityBadgeNeedsItsOwnSpotsAndTheLastNeedsEveryOne() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let trip = try ContentTests.loadExampleTrip()
        let march1 = try moment("2030-03-01")
        let march2 = try moment("2030-03-02")
        let march3 = try moment("2030-03-03")
        let march4 = try moment("2030-03-04")
        let march4Morning = try moment("2030-03-04", hour: 9)
        let march6 = try moment("2030-03-06")
        let march7 = try moment("2030-03-07")
        var progress = StudyProgress()
        func badges() -> [String: SpotBadge] {
            Dictionary(uniqueKeysWithValues: bundle.spotBadges(trip: trip, logs: progress.spotLogs).map { ($0.id, $0) })
        }
        #expect(bundle.spotBadges(trip: trip, logs: [:]).map(\.id) == ["city-venezia", "city-napoli", "city-roma", "all"])
        #expect(badges()["all"]?.total == 7)
        #expect(badges().values.allSatisfy { !$0.isEarned && $0.visited == 0 })

        progress.checkIn(atSpot: "san-giorgio", on: march2)
        progress.checkIn(atSpot: "santa-lucia", on: march1)
        progress.checkIn(atSpot: "santa-lucia", on: march3)
        // Earned when the last of its spots was first checked in.
        #expect(badges()["city-venezia"]?.earnedAt == march2)

        // Naples needs its own two spots; the day trips count only toward the badge for every spot.
        progress.checkIn(atSpot: "pompei", on: march4)
        progress.checkIn(atSpot: "capodichino", on: march3)
        #expect(badges()["city-napoli"]?.visited == 1)
        #expect(badges()["city-napoli"]?.isEarned == false)
        progress.checkIn(atSpot: "posillipo", on: march4Morning)
        #expect(badges()["city-napoli"]?.earnedAt == march4Morning)

        progress.checkIn(atSpot: "colosseo", on: march6)
        #expect(badges()["city-roma"]?.isEarned == true)
        #expect(badges()["all"]?.visited == 6)
        #expect(badges()["all"]?.isEarned == false)
        progress.checkIn(atSpot: "capri", on: march7)
        #expect(badges()["all"]?.earnedAt == march7)
    }

    @Test func validatorChecksTheSpots() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let content = try #require(bundle.spotContent)
        let colosseo = try #require(content.spot("colosseo"))
        let broken = SpotContent(
            version: 1,
            commonPhrases: ["L23-01", "L99-01"],
            phrases: content.phrases + [
                SpotPhrase(id: "L03-05", it: "Me lo scrive?", zh: "写下来", note: nil, status: .draft),
                SpotPhrase(id: "spare", it: "Che bello!", zh: "真美！", note: nil, status: .draft),
            ],
            spots: content.spots + [
                Spot(id: "duomo", city: "milano", it: "Duomo di Milano", zh: "米兰大教堂", note: nil,
                     address: "Piazza del Duomo, 20122 Milano MI", latitude: 45.46, longitude: 9.19, pin: nil,
                     phrases: ["L23-01", "nowhere"], status: .draft),
                colosseo,
            ]
        )
        let messages = ContentValidator.validate(
            ContentBundle(course: bundle.course, lessons: bundle.lessons, audio: nil,
                          showCardContent: bundle.showCardContent, spotContent: broken)
        ).map(\.message)
        #expect(messages.contains("duplicate spot id colosseo"))
        #expect(messages.contains("phrase id L03-05 is also a lesson or show-card phrase"))
        #expect(messages.contains("common phrase L99-01 is not a lesson phrase"))
        #expect(messages.contains("spot duomo is in unknown city milano"))
        #expect(messages.contains("spot duomo uses phrase nowhere, which doesn't exist"))
        #expect(messages.contains("phrase spare is not used by any spot"))
    }

    @Test func everySpotLineHasModelAudioAtBothSpeeds() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let audio = try #require(bundle.audio)
        let content = try #require(bundle.spotContent)
        let texts = content.phrases.map(\.it) + content.spots.map(\.it)
        for text in texts {
            for speed in Speed.allCases {
                #expect(audio.file(for: text, speed: speed) != nil, "no \(speed) audio for \(text)")
            }
        }
    }
}
