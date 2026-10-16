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
            Section("学习进度备份") {
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
                if let backupMessage {
                    Text(backupMessage)
                        .font(.footnote)
                }
            }
            Section("版本") {
                LabeledContent("版本", value: "\(BuildInfo.version) (\(BuildInfo.build))")
                LabeledContent("提交", value: BuildInfo.commit)
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
            Text("当前进度会先存成备份副本。")
        }
        .onAppear {
            log = AppLog.shared.read()
            exportURL = try? model.exportFile()
        }
    }

    private func restore() {
        guard let url = pendingImport else { return }
        pendingImport = nil
        do {
            try model.importProgress(from: url)
            exportURL = try? model.exportFile()
            backupMessage = "已从备份恢复。"
        } catch {
            backupMessage = "恢复失败：\(error)"
        }
    }
}
