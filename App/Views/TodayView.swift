import SwiftUI
import MammaCore

struct TodayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Buongiorno!")
                            .font(.largeTitle.bold())
                        Text("每天 15 分钟：先复习，再学新课。")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if let content = model.content {
                    Section("内容") {
                        LabeledContent("课程单元", value: "\(content.course.units.count)")
                        LabeledContent("已写好的句子", value: "\(content.phrases.count)")
                        LabeledContent("示范音频", value: "\(content.audio?.entries.count ?? 0)")
                    }
                } else if let error = model.loadError {
                    Section("内容加载失败") {
                        Text(error)
                            .font(.footnote.monospaced())
                    }
                }

                Section {
                    NavigationLink("诊断与日志") { DiagnosticsView() }
                }
            }
            .navigationTitle("今日")
        }
    }
}
