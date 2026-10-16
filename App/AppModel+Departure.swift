import Foundation
import MammaCore

/// 出发前自检 on the model: what the app checks itself, the learner's ticks, the show cards saved to
/// Photos, and the reminders for the check and for refreshing the signature on the way.
extension AppModel {
    /// Nil without a trip: the check is about its stops, cards and dates.
    var departureCheck: DepartureCheck? {
        guard let trip else { return nil }
        return DepartureCheck(
            trip: trip,
            speechModel: speechModelState,
            missingAudio: checks.missingAudio,
            showCards: showCards,
            savedCards: checks.savedCards,
            reminders: reminderPermission,
            profile: checks.profile,
            done: checks.done
        )
    }

    /// Whether the signature lasts the trip; nil without a trip or without a profile to read.
    var signingPlan: SigningPlan? {
        guard let trip, let profile = checks.profile else { return nil }
        return SigningPlan(expires: profile.expires, trip: trip)
    }

    /// The trip's last day, in Chinese.
    var lastTripDayText: String? {
        trip?.span.map { $0.upperBound.zhShort }
    }

    /// Counts the audio files the app is missing, for the check.
    func countAudio() async {
        await checks.countAudio(manifest: content?.audio, directory: Bundle.main.url(forResource: "Audio", withExtension: nil))
    }

    /// Saves show cards to Photos as images and notes them as saved; the message to show either way.
    func exportToPhotos(_ cards: [ShowCard]) async -> String {
        let result = await PhotoExport.export(cards) { title(of: $0) }
        if result.saved {
            checks.recordSaved(cards)
        }
        return result.message
    }

    /// The evening before the first city, and the evening to refresh the signature on the way.
    var departureReminders: [CityPackNotifier.Reminder] {
        guard let trip, let first = trip.stops.first else { return [] }
        var reminders: [CityPackNotifier.Reminder] = []
        if let time = trip.departureCheckTime {
            reminders.append(CityPackNotifier.Reminder(
                id: CityPackNotifier.departurePrefix + "check",
                fireDate: time.date(in: .current),
                title: "明天到\(cityName(first.city))：做一遍出发前自检",
                body: "在「随身 → 出发前自检」里看一遍：识别模型、音频、酒店地址、出示卡和签名 app 自己查；SideStore、离线翻译和离线地图要你确认。"
            ))
        }
        if let plan = signingPlan, let time = trip.signingRefreshTime(plan) {
            reminders.append(CityPackNotifier.Reminder(
                id: CityPackNotifier.departurePrefix + "signing",
                fireDate: time.date(in: .current),
                title: "今晚续签 Mamma mia!",
                body: "app 的签名 \(Self.dateTimeText(plan.expires)) 到期。连上酒店 Wi-Fi，打开 LocalDevVPN 和 SideStore 刷新一次；没成功明晚再试。"
            ))
        }
        return reminders
    }

    /// "12月11日 18:00", in the phone's time zone.
    static func dateTimeText(_ date: Date) -> String {
        date.formatted(.dateTime.month().day().hour().minute())
    }

    private var speechModelState: DepartureCheck.SpeechModel {
        switch speech.status {
        case .ready: .installed
        case .needsDownload: .missing
        case .downloading: .downloading
        case .unsupported: .unsupported
        case .checking: .checking
        case .failed: .failed
        }
    }

    private var reminderPermission: DepartureCheck.Permission {
        switch notifier.permission {
        case .allowed: .allowed
        case .notAsked: .notAsked
        case .denied: .denied
        case .unknown: .unknown
        }
    }
}
