import Foundation
import Testing
@testable import MammaCore

/// The trip as the form builds it. Made-up dates only: the real itinerary never enters the repository.
struct TripTests {
    let cities: Set<String> = ["venezia", "napoli", "roma"]
    let immacolata = CourseEvent(id: "immacolata", zh: "圣母无染原罪节（全国假日）", it: "Immacolata Concezione", month: 12, day: 8)

    func day(_ text: String) throws -> LocalDate {
        try #require(LocalDate(text))
    }

    func stop(_ city: String, _ from: String, _ to: String) throws -> Trip.Stop {
        Trip.Stop(city: city, from: try day(from), to: try day(to))
    }

    @Test func aTravelDayCanEndOneStopAndStartTheNext() throws {
        let trip = Trip(stops: [
            try stop("venezia", "2031-04-02", "2031-04-04"),
            try stop("napoli", "2031-04-04", "2031-04-06"),
            // A day somewhere else in between is fine too.
            try stop("roma", "2031-04-07", "2031-04-09"),
        ])
        #expect(trip.issues(knownCities: cities).isEmpty)
    }

    @Test func flagsOverlapsBackwardStaysAndCitiesTheCourseDoesntKnow() throws {
        let trip = Trip(timeZone: "Mars/Olympus", stops: [
            try stop("venezia", "2031-04-02", "2031-04-05"),
            try stop("napoli", "2031-04-04", "2031-04-06"),
            try stop("roma", "2031-04-09", "2031-04-07"),
            try stop("milano", "2031-04-10", "2031-04-11"),
            try stop("roma", "2031-04-12", "2031-04-13"),
        ])
        let issues = trip.issues(knownCities: cities)
        #expect(issues.contains(.overlaps(earlier: "venezia", later: "napoli")))
        #expect(issues.contains(.leavesBeforeArriving(city: "roma")))
        #expect(issues.contains(.unknownCity("milano")))
        #expect(issues.contains(.repeatedCity("roma")))
        #expect(issues.contains(.unknownTimeZone("Mars/Olympus")))
        #expect(issues.count == 5)
        #expect(Trip(stops: []).issues(knownCities: cities) == [.noStops])
    }

    @Test func fillsInTheFixedDateEventsTheTripCovers() throws {
        let december = Trip(stops: [
            try stop("napoli", "2031-12-06", "2031-12-10"),
            try stop("roma", "2031-12-10", "2031-12-11"),
        ])
        #expect(december.events(coveredFrom: [immacolata]) == [Trip.Event(id: "immacolata", date: try day("2031-12-08"))])

        let spring = Trip(stops: [try stop("roma", "2031-04-02", "2031-04-05")])
        #expect(spring.events(coveredFrom: [immacolata]).isEmpty)

        // The first and last days count, and a trip over New Year looks in both years.
        let newYear = CourseEvent(id: "capodanno", zh: "元旦", it: "Capodanno", month: 1, day: 1)
        let winter = Trip(stops: [try stop("roma", "2031-12-08", "2032-01-01")])
        #expect(winter.events(coveredFrom: [newYear, immacolata]).map(\.id) == ["immacolata", "capodanno"])
    }

    @Test func normalizingTrimsTextAndRecomputesEvents() throws {
        var venezia = try stop("venezia", "2031-12-01", "2031-12-03")
        venezia.hotel = Trip.Hotel(name: "  Albergo Esempio ", address: " \n")
        var napoli = try stop("napoli", "2031-12-03", "2031-12-10")
        napoli.hotel = Trip.Hotel(name: "", address: "")
        let draft = Trip(
            stops: [venezia, napoli],
            events: [Trip.Event(id: "stale", date: try day("2031-12-02"))],
            diet: Diet(allergens: [.sesame, .gluten], note: "  ")
        )
        let trip = draft.normalized(events: [immacolata])

        #expect(trip.timeZone == "Europe/Rome")
        #expect(trip.stops[0].hotel == Trip.Hotel(name: "Albergo Esempio", address: nil))
        #expect(trip.stops[1].hotel == nil)
        #expect(trip.diet == Diet(allergens: [.gluten, .sesame], note: nil))
        #expect(trip.events == [Trip.Event(id: "immacolata", date: try day("2031-12-08"))])
        #expect(Trip(stops: [venezia], diet: Diet()).normalized(events: []).diet == nil)
    }

    @Test func phaseCountsDownThenFollowsTheStops() throws {
        let venezia = try stop("venezia", "2031-04-02", "2031-04-04")
        let napoli = try stop("napoli", "2031-04-04", "2031-04-05")
        let roma = try stop("roma", "2031-04-07", "2031-04-09")
        let trip = Trip(stops: [venezia, napoli, roma])

        #expect(trip.phase(on: try day("2031-03-30")) == .before(daysLeft: 3))
        #expect(trip.phase(on: try day("2031-04-02")) == .during(day: 1, length: 8, stop: venezia, leaving: nil))
        #expect(trip.phase(on: try day("2031-04-04")) == .during(day: 3, length: 8, stop: napoli, leaving: venezia))
        #expect(trip.phase(on: try day("2031-04-06")) == .during(day: 5, length: 8, stop: nil, leaving: nil))
        #expect(trip.phase(on: try day("2031-04-09")) == .during(day: 8, length: 8, stop: roma, leaving: nil))
        #expect(trip.phase(on: try day("2031-04-10")) == .after)
        #expect(Trip(stops: []).phase(on: try day("2031-04-02")) == nil)
    }

    @Test func allergensFollowAnnexII() {
        #expect(Allergen.allCases.count == 14)
        #expect(Set(Allergen.allCases.map(\.italian)).count == 14)
        #expect(Allergen.allCases.first?.italian == "Cereali contenenti glutine")
        #expect(Allergen.fish.italian == "Pesce e prodotti della pesca")
        #expect(Allergen.allCases.last?.italian == "Molluschi e prodotti a base di molluschi")
    }

    @Test func allergensThisBuildDoesntKnowAreDropped() throws {
        let diet = try JSONDecoder().decode(Diet.self, from: Data(#"{"allergens": ["nuts", "kiwi", "milk"]}"#.utf8))
        #expect(diet == Diet(allergens: [.nuts, .milk]))
    }
}
