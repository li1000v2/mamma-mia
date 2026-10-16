import SwiftUI
import Translation
import MammaCore

/// 出示卡: big Italian to show across a counter or play to someone. Every card can go into Photos
/// as an image, so it still works if the app's signature runs out on the trip.
struct ShowCardsView: View {
    @Environment(AppModel.self) private var model
    @State private var exporting = false
    @State private var exportMessage: String?

    var body: some View {
        let cards = model.showCards
        let todaysHotel = todaysHotelID
        List {
            if let card = cards.first(where: { $0.id == todaysHotel }) {
                Section("今天") {
                    ShowCardRow(card: card)
                }
            }
            Section {
                ForEach(cards.filter { Self.isHotel($0) && $0.id != todaysHotel }) { card in
                    ShowCardRow(card: card)
                }
                if !cards.contains(where: Self.isHotel) {
                    Text("在行程里填了酒店名称或地址，这里就有每座城市的酒店卡，给司机或路人看。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("酒店")
            }
            Section("忌口") {
                if let card = cards.first(where: { $0.kind == .diet }) {
                    ShowCardRow(card: card)
                } else {
                    Text("在行程里选了过敏原或写了忌口，这里就有给店员看的忌口卡。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Section("沟通与求助") {
                ForEach(cards.filter { [ShowCard.Kind.writeItDown, .speakSlowly, .emergency].contains($0.kind) }) { card in
                    ShowCardRow(card: card)
                }
            }
            Section {
                Button {
                    exportAll(cards)
                } label: {
                    Label(exporting ? "正在保存…" : "全部存到相册", systemImage: "photo.on.rectangle.angled")
                }
                .disabled(exporting || cards.isEmpty)
                if let exportMessage {
                    Text(exportMessage)
                        .font(.footnote)
                }
            } footer: {
                Text("每张卡存成一张图片放进「照片」。app 签名过期打不开时，也能从相册里拿出来给人看。改了行程要再存一次。")
            }
        }
        .navigationTitle("出示卡")
    }

    private static func isHotel(_ card: ShowCard) -> Bool {
        if case .hotel = card.kind { return true }
        return false
    }

    /// During the trip, the card of the hotel you sleep in tonight.
    private var todaysHotelID: String? {
        guard let city = model.trip?.stop(on: model.calendarToday)?.city else { return nil }
        return ShowCard(kind: .hotel(city: city), lines: []).id
    }

    private func exportAll(_ cards: [ShowCard]) {
        exporting = true
        exportMessage = nil
        Task {
            exportMessage = await PhotoExport.export(cards) { model.title(of: $0) }
            exporting = false
        }
    }
}

private struct ShowCardRow: View {
    @Environment(AppModel.self) private var model
    let card: ShowCard

    var body: some View {
        NavigationLink {
            ShowCardDetailView(card: card)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title(of: card))
                    .font(.headline)
                if let first = card.lines.first(where: { $0.style != .number }) ?? card.lines.first {
                    Text(first.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

/// One card full screen: the text as large as it goes, playback, and saving it to Photos.
struct ShowCardDetailView: View {
    @Environment(AppModel.self) private var model
    let card: ShowCard
    /// Identifies the playback in progress, so a finished one doesn't clear a newer one.
    @State private var playback: UUID?
    @State private var playTask: Task<Void, Never>?
    @State private var saving = false
    @State private var saveMessage: String?
    @State private var translatingNote = false

    var body: some View {
        ScrollView {
            ShowCardFace(card: card)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) {
            controls
        }
        .navigationTitle(model.title(of: card))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stop()
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if card.kind == .emergency, let url = EmergencyPhrasesView.call112 {
                Link(destination: url) {
                    Label("拨打 \(ShowCard.emergencyNumber)", systemImage: "phone.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
            }
            if let note = untranslatedNote {
                Button {
                    translatingNote = true
                } label: {
                    Label("用 iPhone 翻译忌口备注", systemImage: "translate")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .translationPresentation(isPresented: $translatingNote, text: note)
            }
            HStack(spacing: 10) {
                Button {
                    toggle(.normal)
                } label: {
                    Label(playback == nil ? "播放" : "停止", systemImage: playback == nil ? "speaker.wave.2.fill" : "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    toggle(.slow)
                } label: {
                    Label("慢速", systemImage: "tortoise.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(playback != nil)
                Button {
                    save()
                } label: {
                    Label("存到相册", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(saving)
            }
            .controlSize(.large)
            if let saveMessage {
                Text(saveMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.bar)
    }

    /// The diet note when the phone's Italian voice can't read it (it's in Chinese, say).
    private var untranslatedNote: String? {
        guard card.kind == .diet else { return nil }
        return card.lines.first { $0.style == .personal && $0.speech == nil }?.text
    }

    private func toggle(_ speed: Speed) {
        if playback != nil {
            stop()
            return
        }
        let token = UUID()
        playback = token
        playTask = Task {
            await model.audio.say(card, speed: speed)
            if playback == token {
                playback = nil
            }
        }
    }

    private func stop() {
        playTask?.cancel()
        playTask = nil
        playback = nil
        model.audio.stop()
    }

    private func save() {
        saving = true
        saveMessage = nil
        Task {
            saveMessage = await PhotoExport.export([card]) { model.title(of: $0) }
            saving = false
        }
    }
}

/// A card's lines, large enough to read across a counter. With `forImage` the colors are fixed
/// black on white, whatever the phone's appearance.
struct ShowCardFace: View {
    let card: ShowCard
    var forImage = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(card.lines.enumerated()), id: \.offset) { _, line in
                lineView(line)
            }
        }
    }

    private var primary: Color { forImage ? .black : .primary }
    private var secondary: Color { forImage ? Color(white: 0.4) : .secondary }

    @ViewBuilder
    private func lineView(_ line: ShowCard.Line) -> some View {
        switch line.style {
        case .number:
            VStack(alignment: .leading, spacing: 4) {
                Text(line.text)
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(.red)
                gloss(line)
            }
        case .sentence:
            VStack(alignment: .leading, spacing: 6) {
                Text(line.text)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(primary)
                    .fixedSize(horizontal: false, vertical: true)
                gloss(line)
            }
        case .personal:
            Text(line.text)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
        case .item:
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("•")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(line.text)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(primary)
                        .fixedSize(horizontal: false, vertical: true)
                    gloss(line)
                }
            }
        }
    }

    @ViewBuilder
    private func gloss(_ line: ShowCard.Line) -> some View {
        if let zh = line.zh {
            Text(zh)
                .font(.body)
                .foregroundStyle(secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The exported image: the card on white, with a footer naming it for finding it in Photos.
struct ShowCardPoster: View {
    let card: ShowCard
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            ShowCardFace(card: card, forImage: true)
            Text("Mamma mia! 出示卡 · \(title)")
                .font(.footnote)
                .foregroundStyle(Color(white: 0.5))
        }
        .padding(36)
        .frame(width: 430, alignment: .leading)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }
}
