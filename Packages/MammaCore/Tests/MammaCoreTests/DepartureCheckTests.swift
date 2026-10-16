import Foundation
import Testing
@testable import MammaCore

/// 出发前自检: the signature's dates, the plan for refreshing it on the way, and what the check lists.
/// Made-up dates only: Content/trip.example.json runs from 1 to 8 March 2030 in Italian time.
struct DepartureCheckTests {
    let rome = TimeZone(identifier: "Europe/Rome")!

    func day(_ text: String) throws -> LocalDate {
        try #require(LocalDate(text))
    }

    func italianTime(_ text: String, hour: Int) throws -> Date {
        try day(text).start(in: rome, hour: hour)
    }

    /// What embedded.mobileprovision looks like: a signed message around an XML property list.
    func profileData(_ plist: String) -> Data {
        Data([0x30, 0x82, 0x2A, 0x10, 0x06, 0x09]) + Data(plist.utf8) + Data([0xA0, 0x82, 0x00, 0x00, 0x31])
    }

    @Test func readsOnlyTheDatesOutOfTheProfile() throws {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>AppIDName</key><string>Mamma mia!</string>
            <key>CreationDate</key><date>2030-02-28T09:00:00Z</date>
            <key>ExpirationDate</key><date>2030-03-07T09:00:00Z</date>
            <key>TeamName</key><string>Esempio Esempio</string>
            <key>TimeToLive</key><integer>7</integer>
        </dict>
        </plist>
        """
        let profile = try #require(ProvisioningProfile(data: profileData(plist)))
        #expect(profile.created == Date(timeIntervalSince1970: 1_898_499_600))
        #expect(profile.expires == Date(timeIntervalSince1970: 1_899_104_400))

        #expect(ProvisioningProfile(data: Data("not a profile".utf8)) == nil)
        let noExpiry = plist.replacingOccurrences(of: "<key>ExpirationDate</key><date>2030-03-07T09:00:00Z</date>", with: "")
        #expect(ProvisioningProfile(data: profileData(noExpiry)) == nil)
    }

    @Test func aSevenDaySignatureNeedsOneRefreshOnTheWay() throws {
        let trip = try ContentTests.loadExampleTrip()
        func plan(_ date: String, hour: Int = 10) throws -> SigningPlan? {
            SigningPlan(expires: try italianTime(date, hour: hour), trip: trip)
        }

        #expect(try plan("2030-03-09") == .coversTrip(expires: try italianTime("2030-03-09", hour: 10)))
        // Refreshed at home the evening before the first city: it runs out on the trip's seventh day,
        // and the reminder comes two evenings before.
        #expect(try plan("2030-03-07") == .refreshOnTheWay(expires: try italianTime("2030-03-07", hour: 10), remindOn: try day("2030-03-05")))
        // Running out on the last day still needs a refresh: that day needs the taxi to the airport.
        #expect(try plan("2030-03-08", hour: 23) == .refreshOnTheWay(expires: try italianTime("2030-03-08", hour: 23), remindOn: try day("2030-03-06")))
        // Never before the first day.
        #expect(try plan("2030-03-02") == .refreshOnTheWay(expires: try italianTime("2030-03-02", hour: 10), remindOn: try day("2030-03-01")))
        #expect(try plan("2030-03-01") == .refreshBeforeLeaving(expires: try italianTime("2030-03-01", hour: 10)))
        #expect(try plan("2030-02-20") == .refreshBeforeLeaving(expires: try italianTime("2030-02-20", hour: 10)))

        // Days are the trip's: half past midnight in Rome is already the next day.
        let afterMidnight = try italianTime("2030-03-09", hour: 0).addingTimeInterval(1800)
        #expect(SigningPlan(expires: afterMidnight, trip: trip) == .coversTrip(expires: afterMidnight))
        #expect(SigningPlan(expires: afterMidnight, trip: Trip(stops: [])) == nil)
    }

    @Test func remindersComeOnTheirEvenings() throws {
        let trip = try ContentTests.loadExampleTrip()
        #expect(trip.departureCheckTime == TripReminderTime(day: try day("2030-02-28"), hour: Trip.departureCheckHour))
        #expect(Trip(stops: []).departureCheckTime == nil)

        let expires = try italianTime("2030-03-07", hour: 10)
        let onTheWay = SigningPlan(expires: expires, trip: trip)
        #expect(trip.signingRefreshTime(onTheWay) == TripReminderTime(day: try day("2030-03-05"), hour: Trip.signingRefreshHour))
        #expect(trip.signingRefreshTime(.coversTrip(expires: expires)) == nil)
        #expect(trip.signingRefreshTime(.refreshBeforeLeaving(expires: expires)) == nil)
        #expect(trip.signingRefreshTime(nil) == nil)

        let time = TripReminderTime(day: try day("2030-03-05"), hour: 20)
        #expect(time.date(in: rome) == (try italianTime("2030-03-05", hour: 20)))
    }

    @Test func theCheckListsWhatIsLeftToDo() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        var trip = try ContentTests.loadExampleTrip()
        for index in trip.stops.indices {
            trip.stops[index].hotel = Trip.Hotel(name: "Albergo Esempio", address: "Via Finta \(index + 1)")
        }
        let cards = bundle.showCards(for: trip)
        let saved = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0.fingerprint) })
        let profile = ProvisioningProfile(created: nil, expires: try italianTime("2030-03-07", hour: 10))
        let ticked = Dictionary(uniqueKeysWithValues: DepartureCheck.Manual.allCases.map { ($0, Date(timeIntervalSince1970: 0)) })
        func check(
            trip: Trip, speech: DepartureCheck.SpeechModel = .installed, missingAudio: Int? = 0,
            saved: [String: String], reminders: DepartureCheck.Permission = .allowed,
            profile: ProvisioningProfile?, done: [DepartureCheck.Manual: Date]
        ) -> DepartureCheck {
            DepartureCheck(trip: trip, speechModel: speech, missingAudio: missingAudio, showCards: bundle.showCards(for: trip),
                           savedCards: saved, reminders: reminders, profile: profile, done: done)
        }

        // Everything done; the signature runs out on the way, which is the plan, not a problem.
        let ready = check(trip: trip, saved: saved, profile: profile, done: ticked)
        #expect(ready.isReady)
        #expect(ready.items.count == 9)
        #expect(ready.items.filter { $0.state == .note } == [.signing(SigningPlan(expires: profile.expires, trip: trip))])
        // A phone that can't recognize Italian, or a build without a profile, can't be fixed: not to do.
        #expect(check(trip: trip, speech: .unsupported, saved: saved, profile: nil, done: ticked).isReady)

        var moved = trip
        moved.stops[2].hotel = Trip.Hotel(name: "Albergo Esempio", address: "  ")
        let left = check(trip: moved, speech: .missing, missingAudio: 3, saved: saved, reminders: .notAsked,
                         profile: ProvisioningProfile(created: nil, expires: try italianTime("2030-02-27", hour: 10)),
                         done: [.translate: Date(timeIntervalSince1970: 0)])
        #expect(!left.isReady)
        #expect(left.todo == [
            .speechModel(.missing),
            .audio(missing: 3),
            .hotels(missingAddress: ["roma"]),
            // Rome's card lost its address, so the image in Photos is out of date.
            .showCards(unsaved: ["hotel-roma"]),
            .reminders(.notAsked),
            .signing(.refreshBeforeLeaving(expires: try italianTime("2030-02-27", hour: 10))),
            .manual(.sideStore, doneAt: nil),
            .manual(.offlineMaps, doneAt: nil),
        ])
        #expect(check(trip: trip, speech: .checking, missingAudio: nil, saved: saved, reminders: .unknown, profile: profile, done: ticked)
            .items.filter { $0.state == .unknown }.count == 3)
    }

    @Test func aCardsFingerprintFollowsWhatIsPrintedOnIt() {
        let line = ShowCard.Line(style: .personal, text: "Via Finta 1", zh: nil, speech: .phoneVoice("Via Finta 1"))
        let card = ShowCard(kind: .hotel(city: "roma"), lines: [line])
        #expect(card.fingerprint == ShowCard(kind: .hotel(city: "roma"), lines: [line]).fingerprint)
        #expect(card.fingerprint != ShowCard(kind: .hotel(city: "napoli"), lines: [line]).fingerprint)
        let moved = ShowCard.Line(style: .personal, text: "Via Finta 2", zh: nil, speech: .phoneVoice("Via Finta 2"))
        #expect(card.fingerprint != ShowCard(kind: .hotel(city: "roma"), lines: [moved]).fingerprint)
        let glossed = ShowCard.Line(style: .personal, text: "Via Finta 1", zh: "地址", speech: .phoneVoice("Via Finta 1"))
        #expect(card.fingerprint != ShowCard(kind: .hotel(city: "roma"), lines: [glossed]).fingerprint)
        // How it is read out isn't printed.
        let silent = ShowCard.Line(style: .personal, text: "Via Finta 1", zh: nil, speech: nil)
        #expect(card.fingerprint == ShowCard(kind: .hotel(city: "roma"), lines: [silent]).fingerprint)
    }

    @Test func missingAudioFilesAreFound() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("mammamia-audio-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data().write(to: directory.appendingPathComponent("aaaaaaaaaaaaaaaa.m4a"))
        let manifest = AudioManifest(version: 1, voices: ["f1@1"], entries: [
            "f1@1|n|Ciao!": "aaaaaaaaaaaaaaaa.m4a",
            "f1@1|s|Ciao!": "bbbbbbbbbbbbbbbb.m4a",
        ])
        #expect(manifest.missingFiles(in: directory) == ["bbbbbbbbbbbbbbbb.m4a"])
    }
}
