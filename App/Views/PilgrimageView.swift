import MapKit
import PhotosUI
import SwiftUI
import MammaCore

/// 巡礼点: the spots by city, today's city first on the trip, each with the learner's check-ins, note
/// and photos; a badge per city and one for every spot. Maps need the network; offline the list shows
/// addresses and opens Apple Maps, which has its own offline maps.
struct PilgrimageView: View {
    @Environment(AppModel.self) private var model
    private let network = NetworkMonitor.shared

    var body: some View {
        List {
            Section {
                BadgeShelf(badges: model.spotBadges)
            } footer: {
                Text("一座城市的巡礼点都打过卡，就点亮这座城市的徽章；连一日游在内全部打卡，再点亮最后一枚。")
            }
            ForEach(model.spotGroups) { group in
                SpotGroupSections(group: group, online: network.isOnline)
            }
            if let lines = model.content?.commonSpotLines, !lines.isEmpty {
                Section("在哪儿都用得上") {
                    ForEach(lines) { line in
                        TravelPhraseRow(it: line.it, zh: line.zh)
                    }
                }
            }
            Section {
                Text("巡礼点只有地名和地址；这里是哪一幕，写在你自己的备注里。备注和打卡只存在这台手机上，也会写进「今日 → 诊断、日志与备份」导出的备份文件。照片存在 app 自己的文件夹里，不进备份文件。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("巡礼点")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            model.audio.stop()
        }
    }
}

/// A city's spots, with their map when online, then the day trips made from it.
private struct SpotGroupSections: View {
    @Environment(AppModel.self) private var model
    let group: SpotGroup
    let online: Bool

    var body: some View {
        Section {
            if online {
                SpotMap(spots: group.all)
                    .frame(height: 180)
                    .listRowInsets(EdgeInsets())
            }
            ForEach(group.spots) { spot in
                SpotRows(spot: spot, online: online)
            }
        } header: {
            Text(header)
        } footer: {
            if !online {
                Text("现在没有网络，地图出不来。地址在列表里；「地图」App 下载过离线地图的话，点“用「地图」打开”就能导航。")
            }
        }
        if !group.dayTrips.isEmpty {
            Section("从\(model.cityName(group.city))出发的一日游") {
                ForEach(group.dayTrips) { spot in
                    SpotRows(spot: spot, online: online)
                }
            }
        }
    }

    private var header: String {
        let name = model.cityName(group.city)
        if case .during(_, _, let stop?, _)? = model.trip?.phase(on: model.calendarToday), stop.city == group.city {
            return "\(name) · 今天在这里"
        }
        return name
    }
}

/// A spot in the list; offline, its address and a button for Apple Maps on a row of its own.
private struct SpotRows: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    let spot: Spot
    let online: Bool

    var body: some View {
        let log = model.spotLog(spot)
        let photos = model.spotPhotos.photos(at: spot.id).count
        NavigationLink {
            SpotDetailView(spot: spot)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: log.firstCheckIn == nil ? "seal" : "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(log.firstCheckIn == nil ? Color.secondary : Color.green)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.zh)
                        .font(.headline)
                    Text(spot.it)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !online {
                        Text(spot.address)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let first = log.firstCheckIn {
                        Text(photos > 0 ? "\(AppModel.dateTimeText(first)) 打卡 · 照片 \(photos) 张" : "\(AppModel.dateTimeText(first)) 打卡")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.vertical, 2)
        }
        if !online, let url = spot.mapsURL {
            Button {
                openURL(url)
            } label: {
                Label("用「地图」打开\(spot.zh)", systemImage: "map")
                    .font(.subheadline)
            }
        }
    }
}

/// Where the spots are; for looking only, so it doesn't fight the list for scrolling.
private struct SpotMap: View {
    let spots: [Spot]

    var body: some View {
        Map(initialPosition: .automatic, interactionModes: []) {
            ForEach(spots) { spot in
                Marker(spot.zh, systemImage: spot.isDayTrip ? "figure.walk" : "star.fill", coordinate: spot.coordinate)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
    }
}

/// One spot: its name to say, where it is, the learner's check-ins, note and photos, and what to say there.
struct SpotDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    let spot: Spot
    private let network = NetworkMonitor.shared
    @State private var note = ""
    @State private var noteLoaded = false
    @FocusState private var editingNote: Bool
    @State private var picked: [PhotosPickerItem] = []
    @State private var importing = false
    @State private var photoMessage: String?
    @State private var shownPhoto: ShownPhoto?
    @State private var earned: [SpotBadge] = []
    @State private var checkIns = 0

    var body: some View {
        let log = model.spotLog(spot)
        List {
            Section {
                nameHeader
            }
            Section {
                if network.isOnline {
                    // For looking only, like the city maps; Apple Maps is a tap away for getting there.
                    Map(initialPosition: .region(MKCoordinateRegion(center: spot.coordinate, latitudinalMeters: 1500, longitudinalMeters: 1500)),
                        interactionModes: []) {
                        Marker(spot.zh, systemImage: "star.fill", coordinate: spot.coordinate)
                    }
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets())
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.address)
                        .textSelection(.enabled)
                    if let pin = spot.pin {
                        Text(pin)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if let url = spot.mapsURL {
                    Button {
                        openURL(url)
                    } label: {
                        Label("用「地图」App 打开", systemImage: "map")
                    }
                }
            } header: {
                Text("在哪儿")
            } footer: {
                if !network.isOnline {
                    Text("现在没有网络，地图出不来。「地图」App 里下载过离线地图的话，可以在那里导航。")
                }
            }
            Section {
                Button {
                    checkIn()
                } label: {
                    Label(log.checkIns.isEmpty ? "打卡" : "再打一次卡", systemImage: "checkmark.seal")
                }
                ForEach(log.checkIns.reversed(), id: \.self) { date in
                    Label(AppModel.dateTimeText(date), systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .swipeActions {
                            Button("删除", role: .destructive) {
                                model.removeCheckIn(date, at: spot)
                            }
                        }
                }
            } header: {
                Text("打卡")
            } footer: {
                Text("打卡记下现在的日期和时间。点错了，左滑删掉。")
            }
            Section {
                TextField("这里是哪一幕、和谁一起来、想记住什么……", text: $note, axis: .vertical)
                    .lineLimit(3...10)
                    .focused($editingNote)
            } header: {
                Text("我的备注")
            } footer: {
                Text("只存在这台手机上，也会写进导出的备份文件；不写进日志。")
            }
            photoSection
            Section("在这里用得上") {
                ForEach(model.content?.lines(at: spot) ?? []) { line in
                    TravelPhraseRow(it: line.it, zh: line.zh)
                }
            }
        }
        .navigationTitle(spot.zh)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !noteLoaded {
                note = log.note ?? ""
                noteLoaded = true
            }
        }
        .onChange(of: editingNote) { _, editing in
            if !editing {
                model.setNote(note, for: spot)
            }
        }
        .onChange(of: picked) { _, items in
            importPhotos(items)
        }
        .onDisappear {
            model.setNote(note, for: spot)
            model.audio.stop()
        }
        .sheet(item: $shownPhoto) { photo in
            PhotoViewer(url: photo.url) {
                model.spotPhotos.delete(photo.url)
            }
        }
        .alert("点亮徽章", isPresented: Binding(
            get: { !earned.isEmpty },
            set: { if !$0 { earned = [] } }
        )) {
            Button("好") { earned = [] }
        } message: {
            Text(model.earnedText(earned))
        }
        .sensoryFeedback(.success, trigger: checkIns)
    }

    private var nameHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.it)
                    .font(.title2.weight(.semibold))
                Text(spot.zh)
                    .foregroundStyle(.secondary)
                if let note = spot.note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            VStack(spacing: 14) {
                SpeakButton(text: spot.it)
                SpeakButton(text: spot.it, speed: .slow)
            }
        }
        .padding(.vertical, 4)
    }

    private var photoSection: some View {
        let photos = model.spotPhotos.photos(at: spot.id)
        return Section {
            if !photos.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                    ForEach(photos, id: \.self) { url in
                        Button {
                            shownPhoto = ShownPhoto(url: url)
                        } label: {
                            PhotoThumbnail(url: url)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 4)
            }
            PhotosPicker(selection: $picked, maxSelectionCount: 10, matching: .images) {
                Label(importing ? "正在加进来…" : "从相册添加照片", systemImage: "photo.badge.plus")
            }
            .disabled(importing)
            if let photoMessage {
                Text(photoMessage)
                    .font(.footnote)
            }
        } header: {
            Text("照片")
        } footer: {
            Text("选你自己拍的照片。app 在自己的文件夹里存一份缩小的副本，去掉了位置信息；照片不进导出的备份文件，删掉 app 会一起删掉，相册里的原图不受影响。")
        }
    }

    private func checkIn() {
        earned = model.checkIn(at: spot)
        checkIns += 1
    }

    private func importPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        picked = []
        importing = true
        photoMessage = nil
        Task {
            var failed = 0
            for item in items {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        failed += 1
                        continue
                    }
                    try await model.spotPhotos.add(data, at: spot.id)
                } catch {
                    failed += 1
                }
            }
            if failed > 0 {
                photoMessage = "有 \(failed) 张没能加进来，再试一次。"
                AppLog.shared.write("Spot photos: \(failed) of \(items.count) couldn't be added")
            }
            importing = false
        }
    }
}

/// The badges in a row: a city's lights up when its spots are all checked in.
private struct BadgeShelf: View {
    @Environment(AppModel.self) private var model
    let badges: [SpotBadge]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(badges) { badge in
                    BadgeView(badge: badge, title: model.badgeTitle(badge), symbol: model.badgeSymbol(badge))
                }
            }
            .padding(.vertical, 6)
        }
    }
}

/// A round badge: gold with its symbol once earned, a dashed outline with the count until then.
private struct BadgeView: View {
    let badge: SpotBadge
    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badge.isEarned
                          ? AnyShapeStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                          : AnyShapeStyle(Color.secondary.opacity(0.12)))
                Circle()
                    .strokeBorder(badge.isEarned ? Color.orange : Color.secondary.opacity(0.5),
                                  style: StrokeStyle(lineWidth: 3, dash: badge.isEarned ? [] : [4, 4]))
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(badge.isEarned ? Color.white : Color.secondary)
            }
            .frame(width: 64, height: 64)
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(badge.earnedAt.map { $0.formatted(.dateTime.month().day()) } ?? "\(badge.visited)/\(badge.total)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 78)
        .accessibilityElement(children: .combine)
    }
}

/// A square of the photo, loaded small off the main thread.
private struct PhotoThumbnail: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .task(id: url) {
                image = await Task.detached(priority: .utility) { PhotoResizer.thumbnail(of: url, pixels: 300) }.value
            }
    }
}

private struct ShownPhoto: Identifiable {
    let url: URL
    var id: URL { url }
}

/// One photo full screen, to look at or delete.
private struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    let delete: () -> Void
    @State private var confirming = false

    var body: some View {
        NavigationStack {
            Group {
                if let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    ContentUnavailableView("照片打不开", systemImage: "photo")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("删除", role: .destructive) { confirming = true }
                }
            }
            .confirmationDialog("删除这张照片？", isPresented: $confirming, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    delete()
                    dismiss()
                }
            } message: {
                Text("只删 app 里的副本，相册里的原图不受影响。")
            }
        }
    }
}

extension Spot {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Opens the place in Apple Maps, which works offline with its own downloaded maps.
    var mapsURL: URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "q", value: it),
        ]
        return components?.url
    }
}
