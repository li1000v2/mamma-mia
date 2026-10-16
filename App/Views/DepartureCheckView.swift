import SwiftUI
import MammaCore

/// 出发前自检, meant for the evening before the first city: what the app checks itself, with a way to
/// fix each, and what only the learner can tick off.
struct DepartureCheckView: View {
    @Environment(AppModel.self) private var model
    @State private var editingTrip = false
    @State private var exporting = false
    @State private var exportMessage: String?

    var body: some View {
        List {
            if let check = model.departureCheck {
                Section {
                    summary(check)
                }
                Section {
                    ForEach(check.items.filter(\.isAutomatic), id: \.self) { item in
                        automaticRow(item)
                    }
                } header: {
                    Text("app 自己查")
                }
                Section {
                    ForEach(DepartureCheck.Manual.allCases, id: \.self) { item in
                        ManualCheckRow(item: item)
                    }
                } header: {
                    Text("要你确认")
                } footer: {
                    Text(remindersFooter)
                }
            } else {
                Section {
                    Text("先填写行程：酒店地址、出示卡和签名都要对着行程查。")
                        .foregroundStyle(.secondary)
                    Button {
                        editingTrip = true
                    } label: {
                        Label("填写行程", systemImage: "calendar.badge.plus")
                    }
                }
            }
        }
        .navigationTitle("出发前自检")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.speech.refreshPermission()
            await model.notifier.refreshPermission()
            await model.countAudio()
        }
        .sheet(isPresented: $editingTrip) {
            TripEditorSheet()
                .environment(model)
        }
    }

    @ViewBuilder
    private func summary(_ check: DepartureCheck) -> some View {
        if check.isReady {
            Label("都准备好了，一路顺风！", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Label("还有 \(check.todo.count) 项要处理", systemImage: "checklist")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("最好在出发前一晚连着 Wi-Fi 做完：下载和刷新都要网络。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var remindersFooter: String {
        var text = "出发前一晚 \(Trip.departureCheckHour):00 会提醒你做一遍自检"
        if case .refreshOnTheWay(_, let day)? = model.signingPlan {
            text += "，\(day.zhShort)晚上 \(Trip.signingRefreshHour):00 提醒你在路上续签"
        }
        return text + "；提醒要开着通知。"
    }

    @ViewBuilder
    private func automaticRow(_ item: DepartureCheck.Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title(of: item))
                        .font(.headline)
                    Text(detail(of: item))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                StateIcon(state: item.state)
            }
            action(for: item)
        }
        .padding(.vertical, 2)
    }

    private func title(of item: DepartureCheck.Item) -> String {
        switch item {
        case .speechModel: "意大利语离线识别模型"
        case .audio: "示范音频"
        case .hotels: "每站的酒店地址"
        case .showCards: "出示卡存进相册"
        case .reminders: "提醒"
        case .signing: "app 签名"
        case .manual(let manual, _): ManualCheckRow.title(of: manual)
        }
    }

    private func detail(of item: DepartureCheck.Item) -> String {
        switch item {
        case .speechModel(let state):
            switch state {
            case .installed: return "已经装好，开口说离线也能识别。"
            case .missing: return "还没下载。连着 Wi-Fi 下载一次，之后离线可用。"
            case .downloading: return "正在下载……"
            case .unsupported: return "这台手机不能离线识别意大利语；开口说照样能录音对比、自己打分。"
            case .checking: return "检查中……"
            case .failed: return "检查或下载出错了，再试一次。"
            }
        case .audio(let missing):
            guard let missing else { return "清点中……" }
            if missing == 0 { return "安装包里 \(model.checks.audioFiles) 段音频都在。" }
            return "安装包里缺 \(missing) 段音频：重新装一次最新的安装包。"
        case .hotels(let cities):
            if cities.isEmpty { return "每一站都填了酒店地址，酒店出示卡上有。" }
            return "\(cities.map { model.cityName($0) }.joined(separator: "、"))还没填酒店地址。"
        case .showCards(let unsaved):
            if unsaved.isEmpty { return "出示卡都存进了相册，和现在的行程一致。app 签名过期打不开时，从「照片」里拿出来给人看。" }
            return "\(unsaved.count) 张出示卡还没存，或者改过行程之后没有重新存。"
        case .reminders(let permission):
            switch permission {
            case .allowed: return "已开启：出发前一晚提醒自检，到每座城市的前一晚提醒城市包，路上提醒续签。"
            case .notAsked: return "城市包、出发前自检和路上续签都靠本地通知提醒。"
            case .denied: return "通知已关闭，收不到提醒：到 设置 → Mamma mia! → 通知 里打开。"
            case .unknown: return "检查中……"
            }
        case .signing(let plan):
            switch plan {
            case .coversTrip(let expires)?:
                return "签名\(AppModel.expiryText(expires))到期，整个行程都够用。"
            case .refreshOnTheWay(let expires, let day)?:
                let last = model.lastTripDayText.map { "（\($0)）" } ?? ""
                return "签名\(AppModel.expiryText(expires))到期，比行程最后一天\(last)早：\(day.zhShort)晚上会提醒你连上酒店 Wi-Fi，打开 LocalDevVPN 和 SideStore 再续一次。"
            case .refreshBeforeLeaving(let expires)?:
                return "签名\(AppModel.expiryText(expires))就到期了：出发前打开 LocalDevVPN 和 SideStore 刷新一次，再回来看。"
            case nil:
                return "读不到签名信息：这个安装包不是 SideStore 装的（比如模拟器），没法检查。"
            }
        case .manual(let manual, _):
            return ManualCheckRow.detail(of: manual)
        }
    }

    @ViewBuilder
    private func action(for item: DepartureCheck.Item) -> some View {
        switch item {
        case .speechModel(.missing), .speechModel(.failed):
            Button {
                Task { await model.speech.downloadModel() }
            } label: {
                Label("下载意大利语识别模型", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.bordered)
        case .speechModel(.downloading):
            if case .downloading(_, let fraction) = model.speech.status {
                ProgressView(value: fraction)
            }
        case .hotels(let cities) where !cities.isEmpty:
            Button {
                editingTrip = true
            } label: {
                Label("编辑行程", systemImage: "square.and.pencil")
            }
            .buttonStyle(.bordered)
        case .showCards(let unsaved) where !unsaved.isEmpty:
            VStack(alignment: .leading, spacing: 4) {
                Button {
                    exportCards()
                } label: {
                    Label(exporting ? "正在保存…" : "全部存到相册", systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(.bordered)
                .disabled(exporting)
                if let exportMessage {
                    Text(exportMessage)
                        .font(.footnote)
                }
            }
        case .reminders(.notAsked):
            Button {
                Task { await model.enableReminders() }
            } label: {
                Label("开启提醒", systemImage: "bell")
            }
            .buttonStyle(.bordered)
        default:
            EmptyView()
        }
    }

    private func exportCards() {
        exporting = true
        exportMessage = nil
        Task {
            exportMessage = await model.exportToPhotos(model.showCards)
            exporting = false
        }
    }
}

/// One thing only the learner can check, ticked with the time it was done.
private struct ManualCheckRow: View {
    @Environment(AppModel.self) private var model
    let item: DepartureCheck.Manual

    var body: some View {
        let doneAt = model.checks.done[item]
        Toggle(isOn: Binding(
            get: { doneAt != nil },
            set: { model.checks.setDone(item, $0) }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.title(of: item))
                    .font(.headline)
                Text(Self.detail(of: item))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let doneAt {
                    Text("已确认 · \(AppModel.expiryText(doneAt))")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 2)
    }

    static func title(of item: DepartureCheck.Manual) -> String {
        switch item {
        case .sideStore: "SideStore 刚刷新过，LocalDevVPN 能连上"
        case .translate: "「翻译」App 下载了意大利语"
        case .offlineMaps: "「地图」App 下载了离线地图"
        }
    }

    static func detail(of item: DepartureCheck.Manual) -> String {
        switch item {
        case .sideStore:
            "出发前一晚在手机上刷新一次。免费签名只有 7 天，路上还要在酒店 Wi-Fi 下再续一次。"
        case .translate:
            "在「翻译」App 里把意大利语下载到手机上，没网也能翻译；出示卡上的中文忌口备注要靠它。"
        case .offlineMaps:
            "在「地图」App 的离线地图里下载威尼斯、那不勒斯（连同庞贝和卡普里）和罗马；没网时巡礼点用它导航。"
        }
    }
}

/// Done, fine with a note, unknown yet, or to do.
private struct StateIcon: View {
    let state: CheckState

    var body: some View {
        switch state {
        case .ok:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .note:
            Image(systemName: "info.circle.fill").foregroundStyle(.blue)
        case .unknown:
            Image(systemName: "questionmark.circle").foregroundStyle(.secondary)
        case .todo:
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
        }
    }
}

extension DepartureCheck.Item {
    /// The app checks these itself; the rest the learner ticks.
    var isAutomatic: Bool {
        if case .manual = self { return false }
        return true
    }
}
