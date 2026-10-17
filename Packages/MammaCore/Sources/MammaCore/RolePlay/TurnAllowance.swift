import Foundation

/// The daily cap on role-play turns, so a long evening of practice can't run up the bill or
/// hammer the project. A turn is one reply to something the learner said; the opening line and
/// the feedback card don't count. The count starts over each study day.
public struct TurnAllowance: Codable, Hashable, Sendable {
    /// Two sessions of `RolePlayConversation.turnsPerSession`.
    public static let defaultLimit = 2 * RolePlayConversation.turnsPerSession
    public static let limits = 10...200

    public private(set) var dailyLimit: Int
    /// The study day `used` counts for.
    public private(set) var day: LocalDate?
    public private(set) var used: Int

    public init(dailyLimit: Int = TurnAllowance.defaultLimit) {
        self.dailyLimit = Self.clamp(dailyLimit)
        day = nil
        used = 0
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dailyLimit = Self.clamp(try container.decodeIfPresent(Int.self, forKey: .dailyLimit) ?? Self.defaultLimit)
        day = try? container.decodeIfPresent(LocalDate.self, forKey: .day)
        used = max(0, try container.decodeIfPresent(Int.self, forKey: .used) ?? 0)
    }

    public func used(on today: LocalDate) -> Int {
        day == today ? used : 0
    }

    public func remaining(on today: LocalDate) -> Int {
        max(0, dailyLimit - used(on: today))
    }

    /// Counts one turn; false (and nothing counted) when today's turns are used up.
    @discardableResult
    public mutating func spend(on today: LocalDate) -> Bool {
        guard remaining(on: today) > 0 else { return false }
        used = used(on: today) + 1
        day = today
        return true
    }

    public mutating func setLimit(_ limit: Int) {
        dailyLimit = Self.clamp(limit)
    }

    private static func clamp(_ limit: Int) -> Int {
        min(max(limit, limits.lowerBound), limits.upperBound)
    }
}
