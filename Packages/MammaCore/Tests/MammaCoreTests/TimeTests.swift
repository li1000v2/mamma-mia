import Foundation
import Testing
@testable import MammaCore

struct TimeTests {
    @Test func parsesAndFormatsDates() {
        #expect(LocalDate("2030-03-04")?.description == "2030-03-04")
        #expect(LocalDate("2030-02-29") == nil)
        #expect(LocalDate("2032-02-29") != nil)
        #expect(LocalDate("2030-3-4") == nil)
        #expect(LocalDate(year: 2030, month: 13, day: 1) == nil)
    }

    @Test func dayArithmetic() throws {
        let start = try #require(LocalDate("2030-02-26"))
        #expect(start.adding(days: 5) == LocalDate("2030-03-03"))
        #expect(start.days(until: try #require(LocalDate("2030-03-08"))) == 10)
        #expect(start.days(until: try #require(LocalDate("2030-02-20"))) == -6)
    }

    @Test func studyDayRollsOverAtFourInTheMorning() throws {
        let rome = try #require(TimeZone(identifier: "Europe/Rome"))
        let clock = StudyClock(timeZone: rome, dayStartHour: 4)
        let day = try #require(LocalDate("2030-03-04"))
        let halfPastTwo = day.start(in: rome).addingTimeInterval(2.5 * 3600)
        let nineAM = day.start(in: rome).addingTimeInterval(9 * 3600)

        #expect(clock.day(of: halfPastTwo) == LocalDate("2030-03-03"))
        #expect(clock.day(of: nineAM) == day)
        #expect(clock.end(of: day).timeIntervalSince(clock.start(of: day)) == 24 * 3600)
    }

    @Test func sameMomentIsADifferentStudyDayInSingaporeAndRome() throws {
        let singapore = try #require(TimeZone(identifier: "Asia/Singapore"))
        let rome = try #require(TimeZone(identifier: "Europe/Rome"))
        let day = try #require(LocalDate("2030-03-05"))
        // 06:00 in Singapore is 23:00 the previous evening in Rome.
        let moment = day.start(in: singapore).addingTimeInterval(6 * 3600)

        #expect(StudyClock(timeZone: singapore).day(of: moment) == day)
        #expect(StudyClock(timeZone: rome).day(of: moment) == LocalDate("2030-03-04"))
    }

    @Test func tripKnowsWhichCityYouAreIn() throws {
        let trip = try JSONDecoder().decode(Trip.self, from: Data(SchedulingTests.exampleTripJSON.utf8))
        #expect(trip.stop(on: try #require(LocalDate("2030-03-02")))?.city == "venezia")
        #expect(trip.stop(on: try #require(LocalDate("2030-03-03")))?.city == "napoli")
        #expect(trip.stop(on: try #require(LocalDate("2030-03-20"))) == nil)
    }
}
