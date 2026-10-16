import Foundation
import Observation
import UserNotifications

/// The evening reminders for the city packs: local notifications, scheduled on this phone only (a
/// free Apple ID has no push). Nothing about the trip is written to the log.
@MainActor
@Observable
final class CityPackNotifier {
    enum Permission {
        case unknown, notAsked, allowed, denied
    }

    struct Reminder: Equatable {
        let id: String
        /// The evening before an arrival; it goes off at that hour wherever the phone is then.
        let fireDate: Date
        let title: String
        let body: String
    }

    static let idPrefix = "citypack-"

    private(set) var permission = Permission.unknown
    private let presenter = ForegroundPresenter()

    init() {
        UNUserNotificationCenter.current().delegate = presenter
    }

    func refreshPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permission = Self.permission(from: settings.authorizationStatus)
    }

    /// Asks for permission (iOS only shows the question once); true when reminders may be shown.
    func requestPermission() async -> Bool {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            AppLog.shared.write("Notification permission request failed: \(error.localizedDescription)")
        }
        await refreshPermission()
        return permission == .allowed
    }

    /// Replaces the scheduled city-pack reminders with those of `reminders` still ahead. Without
    /// permission it only clears the old ones.
    func reschedule(_ reminders: [Reminder]) async {
        let center = UNUserNotificationCenter.current()
        let old = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: old)
        await refreshPermission()
        guard permission == .allowed else { return }
        for reminder in reminders where reminder.fireDate > .now {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            // No time zone in the components: the reminder follows the phone, which changes zone on landing.
            let when = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
            do {
                try await center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
            } catch {
                AppLog.shared.write("A city-pack reminder couldn't be scheduled: \(error.localizedDescription)")
            }
        }
    }

    private static func permission(from status: UNAuthorizationStatus) -> Permission {
        switch status {
        case .notDetermined: .notAsked
        case .denied: .denied
        case .authorized, .provisional, .ephemeral: .allowed
        @unknown default: .denied
        }
    }
}

/// Shows a reminder that arrives while the app is open, which iOS would otherwise keep quiet.
private final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
