import Foundation
import MammaCore

/// 随身 on the model: show cards, city packs and their reminders. Hotel names, addresses and the
/// diet note stay on this phone; none of it is logged.
extension AppModel {
    /// Every show card: the trip's hotels and diet when it has them, then the cards any trip needs.
    var showCards: [ShowCard] {
        content?.showCards(for: trip) ?? []
    }

    /// The name of a card in lists, in the exported image's footer and on the card's screen.
    func title(of card: ShowCard) -> String {
        switch card.kind {
        case .hotel(let city): "酒店 · \(cityName(city))"
        case .diet: "忌口与过敏"
        case .writeItDown: "请对方写下来"
        case .speakSlowly: "请对方说慢一点"
        case .emergency: "紧急电话 112"
        }
    }

    // MARK: City packs

    /// The pack open now: from the evening before an arrival to the end of that day.
    var openCityPack: CityPack? {
        cityPacks.first { $0.isOpen(at: .now, clock: clock) }
    }

    /// "城市包：明天到那不勒斯" on the eve, "城市包：今天到那不勒斯" on the arrival day.
    func packTitle(_ pack: CityPack) -> String {
        let when = today < pack.arrival ? "明天" : "今天"
        return "城市包：\(when)到\(cityName(pack.city))"
    }

    /// Why a card is in today's reviews beyond plain FSRS: an open city pack, or a trip boost.
    func travelTag(for card: ReviewCard) -> String? {
        if let pack = openCityPack, pack.phraseIDs.contains(card.id.phraseID) {
            return packTitle(pack)
        }
        if let day = boostDay(for: card) {
            return "行程加练 · \(day.zhShort)要用"
        }
        return nil
    }

    /// The scenes a pack covers, for its reminder: the city's own by name, the first day's in a word.
    func packScenesText(_ pack: CityPack) -> String {
        let named = pack.scenes.filter { $0.anchor != NeedAnchor.first }.map(\.zh)
        let general = pack.scenes.contains { $0.anchor == NeedAnchor.first }
        switch (named.isEmpty, general) {
        case (false, true): return "\(named.joined(separator: "、"))，以及第一天起就要用的句子"
        case (true, true): return "第一天起就要用的句子"
        default: return named.joined(separator: "、")
        }
    }

    /// Asks for notification permission, then schedules the trip's reminders.
    func enableReminders() async {
        if await notifier.requestPermission() {
            await notifier.reschedule(cityPackReminders, prefix: CityPackNotifier.idPrefix)
            await notifier.reschedule(departureReminders, prefix: CityPackNotifier.departurePrefix)
        }
    }

    /// Brings the scheduled reminders in line with the trip, e.g. after it was edited: the city
    /// packs, the check before leaving and the signature refresh on the way.
    func rescheduleTripReminders() {
        let packs = cityPackReminders
        let departure = departureReminders
        Task {
            await notifier.reschedule(packs, prefix: CityPackNotifier.idPrefix)
            await notifier.reschedule(departure, prefix: CityPackNotifier.departurePrefix)
        }
    }

    private var cityPackReminders: [CityPackNotifier.Reminder] {
        cityPacks.map { pack in
            CityPackNotifier.Reminder(
                id: CityPackNotifier.idPrefix + pack.city,
                fireDate: pack.opens(clock),
                title: "明天到\(cityName(pack.city))",
                body: "城市包已经放进今天的复习：\(packScenesText(pack))。最多 \(CityPack.size) 张，睡前过一遍。"
            )
        }
    }
}
