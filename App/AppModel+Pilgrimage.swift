import Foundation
import MammaCore

/// 巡礼点 on the model: the spots by city, the learner's check-ins and notes, and the badges. The
/// notes and check-ins are personal like the trip and never logged; photos live in `spotPhotos`.
extension AppModel {
    /// During the trip the city you're in comes first.
    var spotGroups: [SpotGroup] {
        content?.spotGroups(trip: trip, on: calendarToday) ?? []
    }

    var spotBadges: [SpotBadge] {
        content?.spotBadges(trip: trip, logs: progress.spotLogs) ?? []
    }

    func spotLog(_ spot: Spot) -> SpotLog {
        progress.spotLogs[spot.id] ?? SpotLog()
    }

    /// Checks in now; returns the badges this check-in earned, if any.
    @discardableResult
    func checkIn(at spot: Spot) -> [SpotBadge] {
        let before = Set(spotBadges.filter(\.isEarned).map(\.id))
        updateSpotLogs { $0.checkIn(atSpot: spot.id, on: .now) }
        return spotBadges.filter { $0.isEarned && !before.contains($0.id) }
    }

    func removeCheckIn(_ date: Date, at spot: Spot) {
        updateSpotLogs { $0.removeCheckIn(atSpot: spot.id, date) }
    }

    /// Saves the note when it changed; blank text clears it.
    func setNote(_ note: String, for spot: Spot) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != (spotLog(spot).note ?? "") else { return }
        updateSpotLogs { $0.setNote(note, forSpot: spot.id) }
    }

    /// "7 处 · 打卡 2 处 · 徽章 1 枚" for the entry in 随身.
    var pilgrimageSummary: String {
        let spots = content?.spots ?? []
        let visited = spots.filter { progress.spotLogs[$0.id]?.firstCheckIn != nil }.count
        let badges = spotBadges.filter(\.isEarned).count
        var parts = ["\(spots.count) 处"]
        if visited > 0 { parts.append("打卡 \(visited) 处") }
        if badges > 0 { parts.append("徽章 \(badges) 枚") }
        return parts.joined(separator: " · ")
    }

    func badgeTitle(_ badge: SpotBadge) -> String {
        switch badge.scope {
        case .city(let city): cityName(city)
        case .all: "全部巡礼点"
        }
    }

    /// An SF Symbol for each badge: the lagoon's boats, Vesuvius, the columns of Rome.
    func badgeSymbol(_ badge: SpotBadge) -> String {
        switch badge.scope {
        case .city("venezia"): "ferry.fill"
        case .city("napoli"): "mountain.2.fill"
        case .city("roma"): "building.columns.fill"
        case .city: "mappin.circle.fill"
        case .all: "star.fill"
        }
    }
}
