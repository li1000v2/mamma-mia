import SwiftUI
import MammaCore

/// 随身, by date. Before the trip: the countdown, the check before leaving, the city packs ahead and
/// the trip form. During it: today's city, the sentences the day first needs, and a nudge when the
/// signature needs refreshing. After it: a short recap. Show cards, the emergency phrases and the
/// pilgrimage spots are one tap away throughout.
struct TravelView: View {
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var confirmingClear = false

    var body: some View {
        NavigationStack {
            List {
                if let trip = model.trip {
                    TripTodaySections(trip: trip, today: model.calendarToday, editing: $editing)
                } else {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("还没有行程")
                                .font(.headline)
                            Text("填好每座城市的到达和离开日期，复习会赶在用到之前，把要用的句子提前过一遍；酒店地址和忌口会做成出示卡。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        Button {
                            editing = true
                        } label: {
                            Label("填写行程", systemImage: "calendar.badge.plus")
                        }
                    }
                }
                Section("随时用") {
                    NavigationLink {
                        ShowCardsView()
                    } label: {
                        TravelEntry(title: "出示卡", detail: showCardsDetail, systemImage: "person.text.rectangle")
                    }
                    NavigationLink {
                        EmergencyPhrasesView()
                    } label: {
                        TravelEntry(title: "应急句", detail: "求助、药店，紧急电话 112", systemImage: "cross.case")
                    }
                }
                Section("巡礼") {
                    NavigationLink {
                        PilgrimageView()
                    } label: {
                        TravelEntry(title: "巡礼点", detail: model.pilgrimageSummary, systemImage: "mappin.and.ellipse")
                    }
                }
                if let trip = model.trip {
                    TripSummary(trip: trip)
                    Section {
                        // Before the trip the form opens from the countdown at the top.
                        if !isBeforeTrip(trip) {
                            Button {
                                editing = true
                            } label: {
                                Label("编辑行程", systemImage: "square.and.pencil")
                            }
                        }
                        Button(role: .destructive) {
                            confirmingClear = true
                        } label: {
                            Label("清除行程", systemImage: "trash")
                        }
                    }
                }
                Section {
                    Text("行程只存在这台手机上，并随学习进度写进「今日 → 诊断、日志与备份」导出的备份文件。酒店名、地址和忌口备注不做成示范音频，播放时用手机自带的意大利语语音朗读。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("随身")
            .sheet(isPresented: $editing) {
                TripEditorSheet()
                    .environment(model)
            }
            .confirmationDialog("清除行程？", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("清除行程", role: .destructive) {
                    model.saveTrip(nil)
                }
            } message: {
                Text("酒店和忌口也会一起删掉，学习记录不受影响。")
            }
        }
    }

    private func isBeforeTrip(_ trip: Trip) -> Bool {
        if case .before? = trip.phase(on: model.calendarToday) { return true }
        return false
    }

    private var showCardsDetail: String {
        var parts: [String] = []
        if let trip = model.trip, let content = model.content {
            if !content.hotelCards(for: trip).isEmpty { parts.append("酒店地址") }
            if content.dietCard(for: trip) != nil { parts.append("忌口") }
        }
        parts += ["请写下来", "说慢一点", "112"]
        return parts.joined(separator: "、")
    }
}

/// A row in 随身 that opens one of its tools.
private struct TravelEntry: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
    }
}

/// The top of 随身 for the trip's phase on `today`.
private struct TripTodaySections: View {
    @Environment(AppModel.self) private var model
    let trip: Trip
    let today: LocalDate
    @Binding var editing: Bool

    var body: some View {
        switch trip.phase(on: today) {
        case .before:
            Section("出发前") {
                TripStatus(trip: trip)
                NavigationLink {
                    DepartureCheckView()
                } label: {
                    DepartureCheckEntry(trip: trip, today: today)
                }
                Button {
                    editing = true
                } label: {
                    Label("编辑行程", systemImage: "square.and.pencil")
                }
                CityPackSchedule()
            }
        case .during:
            Section("今天") {
                TripStatus(trip: trip)
                SigningRefreshRow(today: today)
                if model.cityPacks.contains(where: { $0.arrival > today }) {
                    CityPackReminderRow()
                }
            }
            if let content = model.content {
                TripDayScenes(content: content, trip: trip, today: today)
            }
        case .after:
            Section("行程结束") {
                TripStatus(trip: trip)
                if let recap = model.progress.recap(of: trip, clock: model.clock) {
                    Text(recapText(recap))
                        .font(.subheadline)
                }
            }
        case nil:
            Section {
                TripStatus(trip: trip)
            }
        }
    }

    private func recapText(_ recap: TripRecap) -> String {
        let route = recap.cities.map { model.cityName($0) }.joined(separator: " → ")
        let reviews = recap.reviews > 0 ? "路上复习了 \(recap.reviews) 次，用到 \(recap.phrases) 个句子。" : "路上没有做复习。"
        return "\(recap.days) 天，\(route)。\(reviews)"
    }
}

/// When each city's pack opens, and whether its reminder can go off.
private struct CityPackSchedule: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ForEach(model.cityPacks, id: \.city) { pack in
            LabeledContent("\(pack.eve.zhShort)晚上 \(CityPack.eveningHour):00", value: "\(model.cityName(pack.city))城市包")
        }
        if !model.cityPacks.isEmpty {
            CityPackReminderRow()
        }
    }
}

/// The departure check in 随身 before the trip: what's left, and on its evening a nudge to do it.
private struct DepartureCheckEntry: View {
    @Environment(AppModel.self) private var model
    let trip: Trip
    let today: LocalDate

    var body: some View {
        let check = model.departureCheck
        let left = check?.todo.count ?? 0
        let ready = check?.isReady ?? false
        let tonight = trip.departureCheckTime?.day == today
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(tonight ? "今晚做一遍出发前自检" : "出发前自检")
                    .font(.headline)
                Text(left > 0 ? "还有 \(left) 项要处理" : ready ? "都准备好了" : "检查中……")
                    .font(.subheadline)
                    .foregroundStyle(tonight && left > 0 ? Color.orange : Color.secondary)
            }
        } icon: {
            Image(systemName: ready ? "checkmark.seal" : "checklist")
        }
        .task {
            await model.countAudio()
        }
    }
}

/// On the way, from the evening the reminder comes, or at once when the signature was meant to be
/// refreshed before leaving: refresh it before it runs out.
private struct SigningRefreshRow: View {
    @Environment(AppModel.self) private var model
    let today: LocalDate

    var body: some View {
        switch model.signingPlan {
        case .refreshOnTheWay(let expires, let day)? where today >= day:
            row("签名 \(model.tripTimeText(expires)) 到期：今晚连上酒店 Wi-Fi，打开 LocalDevVPN 和 SideStore 续签一次。")
        case .refreshBeforeLeaving(let expires)?:
            row("签名 \(model.tripTimeText(expires)) 就到期：尽快连上 Wi-Fi，打开 LocalDevVPN 和 SideStore 续签。")
        default:
            EmptyView()
        }
    }

    private func row(_ text: String) -> some View {
        Label(text, systemImage: "signature")
            .font(.subheadline)
            .foregroundStyle(.orange)
    }
}

/// Turns the trip's reminders on, or says why they won't come.
private struct CityPackReminderRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            switch model.notifier.permission {
            case .notAsked:
                Button {
                    Task { await model.enableReminders() }
                } label: {
                    Label("开启城市包提醒", systemImage: "bell")
                }
            case .allowed:
                Label("到每座城市的前一晚提醒你过一遍城市包", systemImage: "bell")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .denied:
                Label("通知已关闭，收不到城市包提醒：可以到 设置 → Mamma mia! → 通知 里打开。城市包照样会放进复习。", systemImage: "bell.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .unknown:
                EmptyView()
            }
        }
        .task {
            await model.notifier.refreshPermission()
        }
    }
}

/// During the trip: the scenes today first needs, then the ones of the city you're in.
private struct TripDayScenes: View {
    @Environment(AppModel.self) private var model
    let content: ContentBundle
    let trip: Trip
    let today: LocalDate

    var body: some View {
        let needed = content.scenes(firstNeededOn: today, trip: trip)
        // Today's own scenes are spelled out; on the first day the many general ones are links.
        let specific = needed.filter { $0.anchor != NeedAnchor.first }
        let general = needed.filter { $0.anchor == NeedAnchor.first }
        let city = content.cityScenes(on: today, trip: trip)
        ForEach(specific) { scene in
            Section {
                ForEach(content.phrases(inScene: scene.id)) { phrase in
                    TravelPhraseRow(phrase: phrase)
                }
            } header: {
                Text("今天要用 · \(scene.zh)")
            }
        }
        if !general.isEmpty {
            Section {
                ForEach(general) { scene in
                    SceneLink(content: content, scene: scene)
                }
            } header: {
                Text("从今天起处处要用")
            }
        }
        if let stop = trip.stop(on: today), !city.isEmpty {
            Section("在\(model.cityName(stop.city))") {
                ForEach(city) { scene in
                    SceneLink(content: content, scene: scene)
                }
            }
        }
    }
}

private struct SceneLink: View {
    let content: ContentBundle
    let scene: SceneTag

    var body: some View {
        NavigationLink {
            ScenePhrasesView(scene: scene)
        } label: {
            LabeledContent(scene.zh, value: "\(content.phrases(inScene: scene.id).count) 句")
        }
    }
}

/// One scene's sentences, each playable.
struct ScenePhrasesView: View {
    @Environment(AppModel.self) private var model
    let scene: SceneTag

    var body: some View {
        List {
            ForEach(model.content?.phrases(inScene: scene.id) ?? []) { phrase in
                TravelPhraseRow(phrase: phrase)
            }
        }
        .navigationTitle(scene.zh)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A sentence to use on the spot: the Italian large, its meaning, normal and slow audio.
struct TravelPhraseRow: View {
    let it: String
    let zh: String

    init(phrase: Phrase) {
        self.init(it: phrase.it, zh: phrase.zh)
    }

    init(it: String, zh: String) {
        self.it = it
        self.zh = zh
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(it)
                    .font(.title3.weight(.semibold))
                Text(zh)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(spacing: 14) {
                SpeakButton(text: it)
                SpeakButton(text: it, speed: .slow)
            }
        }
        .padding(.vertical, 4)
    }
}

/// The saved trip: stops with dates and hotels, the holidays it covers, and dietary needs.
struct TripSummary: View {
    @Environment(AppModel.self) private var model
    let trip: Trip

    var body: some View {
        Section("行程") {
            ForEach(Array(trip.stops.enumerated()), id: \.offset) { _, stop in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(model.cityName(stop.city))
                            .font(.headline)
                        Spacer()
                        Text(TripText.nights(stop))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(stop.from.zhText) – \(stop.to.zhText)")
                        .font(.subheadline)
                    if let name = stop.hotel?.name {
                        Text(name)
                            .font(.subheadline)
                    }
                    if let address = stop.hotel?.address {
                        Text(address)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        if !trip.events.isEmpty {
            Section("节日") {
                ForEach(trip.events, id: \.self) { event in
                    LabeledContent(model.eventName(event.id), value: event.date.zhText)
                }
            }
        }
        Section("忌口与过敏") {
            if let diet = trip.diet {
                ForEach(diet.allergens) { allergen in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(allergen.zh)
                        Text(allergen.italian)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let note = diet.note {
                    Text(note)
                }
            } else {
                Text("没有填写")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// The trip on 今日: a countdown before it, today's city during it.
struct TripStatus: View {
    @Environment(AppModel.self) private var model
    let trip: Trip

    var body: some View {
        let today = model.calendarToday
        VStack(alignment: .leading, spacing: 2) {
            switch trip.phase(on: today) {
            case .before(let daysLeft):
                Text(beforeTitle(daysLeft: daysLeft))
                    .font(.headline)
                if let first = trip.stops.first {
                    Text("\(first.from.zhText)抵达")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            case .during(let day, let length, let stop, let leaving):
                Text(duringTitle(day: day, length: length, stop: stop, leaving: leaving))
                    .font(.headline)
                Text("第 \(day) 天，共 \(length) 天")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(trip.events.filter { $0.date == today }, id: \.self) { event in
                    Text("今天是\(model.eventName(event.id))")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            case .after:
                Text("行程结束了")
                    .font(.headline)
                Text("欢迎回来。行程可以在「随身」里清除。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case nil:
                Text("行程里还没有城市")
                    .foregroundStyle(.secondary)
            }
            if let pack = model.openCityPack {
                Label("\(model.packTitle(pack))，要用的卡已经放进复习", systemImage: "shippingbox")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }

    private func beforeTitle(daysLeft: Int) -> String {
        let city = trip.stops.first.map { model.cityName($0.city) } ?? ""
        return daysLeft == 1 ? "明天到\(city)" : "还有 \(daysLeft) 天到\(city)"
    }

    private func duringTitle(day: Int, length: Int, stop: Trip.Stop?, leaving: Trip.Stop?) -> String {
        if let stop, let leaving {
            return "今天从\(model.cityName(leaving.city))去\(model.cityName(stop.city))"
        }
        if day == length {
            return stop.map { "最后一天：\(model.cityName($0.city))，今天回程" } ?? "最后一天，今天回程"
        }
        if let stop {
            return "今天在\(model.cityName(stop.city))"
        }
        return "今天在路上"
    }
}

/// The trip form in its own navigation stack, for presenting as a sheet.
struct TripEditorSheet: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            TripEditorView(trip: model.trip, cities: model.cities, today: TripDates.today)
        }
    }
}

/// Trip dates are Italian calendar days. Pickers work on noon in Rome, so no time zone can move
/// a date to the day before or after.
enum TripDates {
    static let zone = TimeZone(identifier: Trip.italyTimeZone) ?? .current

    static func date(_ day: LocalDate) -> Date {
        day.start(in: zone, hour: 12)
    }

    static func day(_ date: Date) -> LocalDate {
        LocalDate.of(date, in: zone)
    }

    static var today: LocalDate { day(.now) }
}

enum TripText {
    static func nights(_ stop: Trip.Stop) -> String {
        let nights = stop.from.days(until: stop.to)
        return nights > 0 ? "\(nights) 晚" : "当天离开"
    }
}

extension LocalDate {
    /// "12月8日（周二）".
    var zhText: String {
        "\(zhShort)（\(zhWeekday)）"
    }

    /// "12月8日".
    var zhShort: String {
        "\(month)月\(day)日"
    }

    private var zhWeekday: String {
        let weekday = Self.gregorianUTC.component(.weekday, from: start(in: Self.gregorianUTC.timeZone))
        let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return names[(weekday - 1) % 7]
    }

    private static let gregorianUTC: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()
}

extension Allergen {
    /// The Chinese name without its examples: "坚果" rather than "坚果（杏仁、榛子…）".
    var shortZh: String {
        zh.components(separatedBy: "（").first ?? zh
    }
}
