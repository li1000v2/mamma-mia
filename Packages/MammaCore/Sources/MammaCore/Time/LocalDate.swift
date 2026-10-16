import Foundation

/// A calendar date with no time or time zone, written "YYYY-MM-DD" in content and trip files.
public struct LocalDate: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init?(year: Int, month: Int, day: Int) {
        guard (1...12).contains(month), day >= 1, day <= LocalDate.daysInMonth(year: year, month: month) else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    public init?(_ string: String) {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    public var description: String {
        "\(Self.pad(year, 4))-\(Self.pad(month, 2))-\(Self.pad(day, 2))"
    }

    public static func < (lhs: LocalDate, rhs: LocalDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// The moment this date starts in `timeZone`, at `hour` o'clock local time.
    public func start(in timeZone: TimeZone, hour: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) else {
            preconditionFailure("valid Gregorian date \(self) has no start in \(timeZone.identifier)")
        }
        return date
    }

    /// The date `date` falls on in `timeZone`, treating times before `dayStartHour` as the previous day.
    public static func of(_ date: Date, in timeZone: TimeZone, dayStartHour: Int = 0) -> LocalDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let shifted = date.addingTimeInterval(TimeInterval(-dayStartHour * 3600))
        let parts = calendar.dateComponents([.year, .month, .day], from: shifted)
        guard let year = parts.year, let month = parts.month, let day = parts.day,
              let result = LocalDate(year: year, month: month, day: day)
        else { preconditionFailure("calendar returned an invalid date for \(date)") }
        return result
    }

    public func adding(days: Int) -> LocalDate {
        let shifted = start(in: Self.utc).addingTimeInterval(TimeInterval(days) * 86_400)
        return LocalDate.of(shifted, in: Self.utc)
    }

    /// Whole days from this date to `other` (negative when `other` is earlier).
    public func days(until other: LocalDate) -> Int {
        Int((other.start(in: Self.utc).timeIntervalSince(start(in: Self.utc)) / 86_400).rounded())
    }

    static let utc = TimeZone(secondsFromGMT: 0)!

    static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 2: (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }

    private static func pad(_ value: Int, _ width: Int) -> String {
        let digits = String(value)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }
}

extension LocalDate: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let date = LocalDate(string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "expected YYYY-MM-DD, got \(string)")
        }
        self = date
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
