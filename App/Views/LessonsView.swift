import SwiftUI
import MammaCore

struct LessonsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                if let content = model.content {
                    ForEach(weeks(of: content.course), id: \.self) { week in
                        Section("第 \(week) 周") {
                            ForEach(content.course.units.filter { $0.week == week }) { unit in
                                NavigationLink {
                                    UnitDetailView(unit: unit, lesson: content.lesson(for: unit.id))
                                } label: {
                                    UnitRow(unit: unit)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("课程")
        }
    }

    private func weeks(of course: Course) -> [Int] {
        Array(Set(course.units.map(\.week))).sorted()
    }
}

private struct UnitRow: View {
    let unit: CourseUnit

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(unit.id)
                .font(.caption.monospaced())
                .foregroundStyle(unit.kind == .challenge ? Color.orange : Color.secondary)
                .frame(width: 32, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(unit.title)
                Text(unit.focus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct UnitDetailView: View {
    let unit: CourseUnit
    let lesson: LessonContent?

    var body: some View {
        List {
            Section(unit.kind == .lesson ? "关键表达" : "挑战任务") {
                Text(unit.summary)
            }
            if let lesson {
                Section("句子") {
                    ForEach(lesson.phrases) { phrase in
                        PhraseRow(phrase: phrase)
                    }
                }
            } else if unit.kind == .lesson {
                Section {
                    Text("这一课的内容还在编写。")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(unit.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PhraseRow: View {
    let phrase: Phrase

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(phrase.it)
                    .font(.headline)
                Spacer()
                if phrase.status == .draft {
                    Text("草稿")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.25), in: Capsule())
                }
            }
            Text(phrase.zh)
                .foregroundStyle(.secondary)
            if let note = phrase.note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
