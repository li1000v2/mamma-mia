import Foundation

/// Decides which study day a moment belongs to. The day starts at `dayStartHour` local time,
/// so a session at 01:00 still counts for the previous day. Uses the device time zone, which
/// changes when the phone lands in Italy; trip dates are resolved separately in the trip's zone.
public struct StudyClock: Sendable {
    public var timeZone: TimeZone
    public var dayStartHour: Int

    public init(timeZone: TimeZone = .current, dayStartHour: Int = 4) {
        self.timeZone = timeZone
        self.dayStartHour = dayStartHour
    }

    public func day(of date: Date) -> LocalDate {
        LocalDate.of(date, in: timeZone, dayStartHour: dayStartHour)
    }

    public func start(of day: LocalDate) -> Date {
        day.start(in: timeZone, hour: dayStartHour)
    }

    public func end(of day: LocalDate) -> Date {
        start(of: day.adding(days: 1))
    }
}
