import SwiftUI

struct DiagnosticsView: View {
    @State private var log = ""

    var body: some View {
        List {
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
        .navigationTitle("诊断与日志")
        .toolbar {
            ShareLink(item: AppLog.shared.fileURL) {
                Label("分享日志", systemImage: "square.and.arrow.up")
            }
        }
        .onAppear { log = AppLog.shared.read() }
    }
}
