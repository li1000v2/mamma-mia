import SwiftUI
import UniformTypeIdentifiers
import MammaCore

struct DiagnosticsView: View {
    @Environment(AppModel.self) private var model
    @State private var log = ""
    @State private var exportURL: URL?
    @State private var importing = false
    @State private var pendingImport: URL?
    @State private var backupMessage: String?

    var body: some View {
        List {
            Section {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("导出进度", systemImage: "square.and.arrow.up")
                    }
                }
                Button {
                    importing = true
                } label: {
                    Label("从备份恢复…", systemImage: "square.and.arrow.down")
                }
                LabeledContent("卡片", value: "\(model.progress.cards.count)")
                LabeledContent("复习记录", value: "\(model.progress.reviews.count)")
                LabeledContent("行程", value: model.trip == nil ? "没有" : "已填写")
                LabeledContent("巡礼点记录", value: model.progress.spotLogs.isEmpty ? "没有" : "\(model.progress.spotLogs.count) 处")
                if let backupMessage {
                    Text(backupMessage)
                        .font(.footnote)
                }
            } header: {
                Text("学习进度备份")
            } footer: {
                Text(backupFooter)
            }
            speechSection
            Section("版本") {
                LabeledContent("版本", value: "\(BuildInfo.version) (\(BuildInfo.build))")
                LabeledContent("提交", value: BuildInfo.commit)
                LabeledContent("签名到期", value: model.checks.profile.map { AppModel.dateTimeText($0.expires) } ?? "读不到")
                LabeledContent("系统", value: ProcessInfo.processInfo.operatingSystemVersionString)
                LabeledContent("时区", value: TimeZone.current.identifier)
            }
            Section("日志") {
                if log.isEmpty {
                    Text("暂无日志")
                        .foregroundStyle(.secondary)
                } else {
                    Text(log)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("诊断、日志与备份")
        .toolbar {
            ShareLink(item: AppLog.shared.fileURL) {
                Label("分享日志", systemImage: "doc.text")
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                pendingImport = url
            case .failure(let error):
                backupMessage = "没能打开文件：\(error.localizedDescription)"
            }
        }
        .alert("用这个备份覆盖当前进度？", isPresented: Binding(
            get: { pendingImport != nil },
            set: { if !$0 { pendingImport = nil } }
        )) {
            Button("覆盖", role: .destructive) { restore() }
            Button("取消", role: .cancel) { pendingImport = nil }
        } message: {
            Text("当前进度会先存成备份副本。备份里没有行程、没有巡礼点记录的话，保留手机上现在的。巡礼点的照片不在备份里，不受影响。")
        }
        .onAppear {
            log = AppLog.shared.read()
            exportURL = try? model.exportFile()
            model.speech.refreshPermission()
        }
    }

    /// Offline recognition for 开口说: whether it works here, and the model download.
    private var speechSection: some View {
        let speech = model.speech
        return Section {
            LabeledContent("状态", value: speech.statusText)
            if let engine = speech.engine {
                LabeledContent("引擎", value: engine.rawValue)
            }
            if let locale = speech.locale {
                LabeledContent("语言", value: locale.identifier(.bcp47))
            }
            LabeledContent("权限", value: speech.permissionText)
            switch speech.status {
            case .needsDownload, .failed:
                Button {
                    Task { await speech.downloadModel() }
                } label: {
                    Label("下载意大利语识别模型", systemImage: "arrow.down.circle")
                }
            case .downloading(_, let fraction):
                ProgressView(value: fraction)
            default:
                EmptyView()
            }
            Button {
                Task { await speech.refresh() }
            } label: {
                Label("重新检查", systemImage: "arrow.clockwise")
            }
            .disabled(speech.status == .checking)
        } header: {
            Text("语音识别")
        } footer: {
            Text(speechFooter)
        }
    }

    /// What the backup carries that is personal, and that the spot photos stay behind.
    private var backupFooter: String {
        var parts: [String] = []
        if model.trip != nil {
            parts.append("备份文件里也有行程，包括酒店地址和忌口，只存到自己的地方。")
        }
        if !model.progress.spotLogs.isEmpty {
            parts.append("巡礼点的备注和打卡也在备份里。")
        }
        parts.append("巡礼点的照片只存在这台手机上，不进备份文件。")
        return parts.joined()
    }

    private var speechFooter: String {
        switch model.speech.status {
        case .unsupported:
            "这台手机不能离线识别意大利语。开口练习只保留录音对比和自评。"
        case .needsDownload:
            "模型由系统下载和管理，下载一次后离线可用，其他 app 也能共用。"
        default:
            "只用手机自带的离线识别，判断你说的意大利语对方能不能听懂，不打发音分。录音和识别结果都不离开这台手机。"
        }
    }

    private func restore() {
        guard let url = pendingImport else { return }
        pendingImport = nil
        do {
            let keptTrip = try model.importProgress(from: url)
            exportURL = try? model.exportFile()
            backupMessage = keptTrip ? "已从备份恢复。备份里没有行程，保留了手机上现在的行程。" : "已从备份恢复。"
        } catch {
            backupMessage = "恢复失败：\(error)"
        }
    }
}
