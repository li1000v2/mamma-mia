import SwiftUI
import MammaCore

/// 随身. For now it holds the trip: entered here, kept on this phone. Show cards, emergency phrases
/// and the pilgrimage spots come in a later version and will build on it.
struct TravelView: View {
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var confirmingClear = false

    var body: some View {
        NavigationStack {
            List {
                if let trip = model.trip {
                    TripSummary(trip: trip)
                    Section {
                        Button {
                            editing = true
                        } label: {
                            Label("编辑行程", systemImage: "square.and.pencil")
                        }
                        Button(role: .destructive) {
                            confirmingClear = true
                        } label: {
                            Label("清除行程", systemImage: "trash")
                        }
                    }
                } else {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("还没有行程")
                                .font(.headline)
                            Text("填好每座城市的到达和离开日期，复习会赶在用到之前，把要用的句子提前过一遍。")
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
                Section {
                    Text("行程只存在这台手机上，并随学习进度写进「今日 → 诊断、日志与备份」导出的备份文件。酒店和忌口先存着；出示卡、应急句和巡礼点会在后面的版本加进来。")
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
