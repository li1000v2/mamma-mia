import SwiftUI
import MammaCore

/// The trip form: the course's cities with arrival and departure days, a hotel per stop, and what
/// you can't eat. Only the stops are required. Everything stays on this phone and in its backups.
struct TripEditorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    /// Edited in place; blank hotel text is dropped and the stops sorted when the trip is built.
    @State private var stops: [Trip.Stop]
    @State private var allergens: Set<Allergen>
    @State private var dietNote: String
    private let isNew: Bool
    private let today: LocalDate

    init(trip: Trip?, cities: [CourseCity], today: LocalDate) {
        self.today = today
        isNew = trip == nil
        if let trip {
            _stops = State(initialValue: trip.stops)
            _allergens = State(initialValue: Set(trip.diet?.allergens ?? []))
            _dietNote = State(initialValue: trip.diet?.note ?? "")
        } else {
            // The course's cities back to back from today: usually only the dates need changing.
            var stops: [Trip.Stop] = []
            var day = today
            for city in cities {
                stops.append(Trip.Stop(city: city.id, from: day, to: day.adding(days: 2)))
                day = day.adding(days: 2)
            }
            _stops = State(initialValue: stops)
            _allergens = State(initialValue: [])
            _dietNote = State(initialValue: "")
        }
    }

    var body: some View {
        Form {
            Section {
                Text("填每座城市的到达日和离开日，用意大利当地日期。换城市那天既是上一站的离开日，也是下一站的到达日。保存时按到达日期排序。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(stops, id: \.city) { stop in
                stopSection(stop.city)
            }
            if !remainingCities.isEmpty {
                Section {
                    Menu {
                        ForEach(remainingCities) { city in
                            Button("\(city.zh) \(city.it)") {
                                add(city)
                            }
                        }
                    } label: {
                        Label("添加城市", systemImage: "plus.circle")
                    }
                }
            }
            if !draft.events.isEmpty {
                Section {
                    ForEach(draft.events, id: \.self) { event in
                        LabeledContent(model.eventName(event.id), value: event.date.zhText)
                    }
                } header: {
                    Text("行程里的节日")
                } footer: {
                    Text("按日期自动加上，相关的句子会赶在这天之前复习。")
                }
            }
            dietSection
            if !issues.isEmpty {
                Section {
                    ForEach(issues, id: \.self) { issue in
                        Label(describe(issue), systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .environment(\.timeZone, TripDates.zone)
        .scrollDismissesKeyboard(.interactively)
        // Typed addresses shouldn't vanish with a stray swipe: leave through 取消 or 保存.
        .interactiveDismissDisabled()
        .navigationTitle(isNew ? "填写行程" : "编辑行程")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .disabled(!issues.isEmpty)
            }
        }
    }

    private func stopSection(_ city: String) -> some View {
        let stop = binding(for: city)
        return Section {
            DatePicker("到达", selection: arrival(of: stop), displayedComponents: .date)
            DatePicker("离开", selection: departure(of: stop), in: TripDates.date(stop.wrappedValue.from)...,
                       displayedComponents: .date)
            TextField("酒店名称（可不填）", text: hotelText(of: stop, \.name))
                .autocorrectionDisabled()
            TextField("酒店地址（可不填）", text: hotelText(of: stop, \.address), axis: .vertical)
                .lineLimit(1...4)
                .textContentType(.fullStreetAddress)
                .autocorrectionDisabled()
            Button("删除这一站", role: .destructive) {
                stops.removeAll { $0.city == city }
            }
        } header: {
            Text("\(model.cityName(city)) · \(nightsText(stop.wrappedValue))")
        }
    }

    private var dietSection: some View {
        Section {
            NavigationLink {
                AllergenPicker(selection: $allergens)
            } label: {
                LabeledContent("过敏原", value: allergenSummary)
            }
            TextField("其他忌口（可不填），比如不吃猪肉、吃素", text: $dietNote, axis: .vertical)
                .lineLimit(1...4)
        } header: {
            Text("忌口与过敏")
        } footer: {
            Text("会做成「随身 → 出示卡」里给店员看的忌口卡：过敏原用欧盟法规里的意大利文名称列出，备注照原样显示。")
        }
    }

    // MARK: Draft

    /// What saving would store. `Trip.normalized` puts the stops in arrival order, drops blank
    /// text and adds the course's fixed-date events the dates cover.
    private var draft: Trip {
        let diet = Diet(allergens: Array(allergens), note: dietNote)
        return Trip(stops: stops, diet: diet).normalized(events: model.content?.course.events ?? [])
    }

    private var issues: [TripIssue] {
        draft.issues(knownCities: Set(model.cities.map(\.id)))
    }

    private var remainingCities: [CourseCity] {
        model.cities.filter { city in !stops.contains { $0.city == city.id } }
    }

    private var allergenSummary: String {
        let names = Allergen.allCases.filter { allergens.contains($0) }.map(\.shortZh)
        return names.isEmpty ? "无" : names.joined(separator: "、")
    }

    private func nightsText(_ stop: Trip.Stop) -> String {
        let nights = stop.from.days(until: stop.to)
        if nights < 0 { return "日期有误" }
        return nights == 0 ? "当天离开" : "\(nights) 晚"
    }

    private func describe(_ issue: TripIssue) -> String {
        switch issue {
        case .noStops:
            "至少要有一站。"
        case .unknownTimeZone(let id):
            "无法识别时区 \(id)。"
        case .unknownCity(let id):
            "课程里没有城市 \(id)。"
        case .repeatedCity(let id):
            "\(model.cityName(id))出现了两次。"
        case .leavesBeforeArriving(let city):
            "\(model.cityName(city))的离开日早于到达日。"
        case .overlaps(let earlier, let later):
            "\(model.cityName(later))的到达日早于\(model.cityName(earlier))的离开日。换城市那天可以是同一天，但不能重叠。"
        }
    }

    // MARK: Editing

    /// A new stop starts on the day the trip so far ends: a travel day.
    private func add(_ city: CourseCity) {
        let start = stops.map(\.to).max() ?? today
        stops.append(Trip.Stop(city: city.id, from: start, to: start.adding(days: 2)))
    }

    private func save() {
        guard issues.isEmpty else { return }
        model.saveTrip(draft)
        dismiss()
    }

    /// Looked up by city on every access, so a removed stop can't leave a dangling index behind.
    private func binding(for city: String) -> Binding<Trip.Stop> {
        Binding(
            get: { stops.first { $0.city == city } ?? Trip.Stop(city: city, from: today, to: today) },
            set: { newValue in
                if let index = stops.firstIndex(where: { $0.city == city }) {
                    stops[index] = newValue
                }
            }
        )
    }

    /// See `Trip.Stop.moveArrival`: the departure only moves when it would fall before the arrival.
    private func arrival(of stop: Binding<Trip.Stop>) -> Binding<Date> {
        Binding(
            get: { TripDates.date(stop.wrappedValue.from) },
            set: { newValue in
                var updated = stop.wrappedValue
                updated.moveArrival(to: TripDates.day(newValue))
                stop.wrappedValue = updated
            }
        )
    }

    private func departure(of stop: Binding<Trip.Stop>) -> Binding<Date> {
        Binding(
            get: { TripDates.date(stop.wrappedValue.to) },
            set: { stop.wrappedValue.to = TripDates.day($0) }
        )
    }

    /// The hotel's name or address as plain text, blank meaning not given.
    private func hotelText(of stop: Binding<Trip.Stop>, _ field: WritableKeyPath<Trip.Hotel, String?>) -> Binding<String> {
        Binding(
            get: { stop.wrappedValue.hotel?[keyPath: field] ?? "" },
            set: { newValue in
                var hotel = stop.wrappedValue.hotel ?? Trip.Hotel()
                hotel[keyPath: field] = newValue
                stop.wrappedValue.hotel = hotel
            }
        )
    }
}

/// The 14 allergens of EU food labelling, each with its Italian name from the regulation.
private struct AllergenPicker: View {
    @Binding var selection: Set<Allergen>

    var body: some View {
        List {
            Section {
                ForEach(Allergen.allCases) { allergen in
                    Button {
                        toggle(allergen)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(allergen.zh)
                                    .foregroundStyle(.primary)
                                Text(allergen.italian)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selection.contains(allergen) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityAddTraits(selection.contains(allergen) ? .isSelected : [])
                }
            } footer: {
                Text("欧盟食品标签法规 (EU) No 1169/2011 附件二规定必须标明的 14 类过敏原，意大利文取自法规原文。")
            }
        }
        .navigationTitle("过敏原")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ allergen: Allergen) {
        if selection.contains(allergen) {
            selection.remove(allergen)
        } else {
            selection.insert(allergen)
        }
    }
}
