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
                                UnitLink(unit: unit)
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

struct ChallengesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                if let content = model.content {
                    Section {
                        Text("通关标准：任务完成，关键信息题全对，提示不超过 1 次。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(content.course.units.filter { $0.kind == .challenge }) { unit in
                        UnitLink(unit: unit)
                    }
                    if content.rolePlay != nil {
                        Section {
                            NavigationLink {
                                RolePlaySettingsView()
                            } label: {
                                Label("在线对话设置", systemImage: "key")
                            }
                        } header: {
                            Text("在线 AI 角色扮演")
                        } footer: {
                            Text("每个挑战都可以和 AI 扮演的角色自由对话（在挑战页里）。需要联网和你自己的 Google key，只作加练，不计入通关；离线挑战不受影响。")
                        }
                    }
                }
            }
            .navigationTitle("情境挑战")
        }
    }
}

struct UnitDetailView: View {
    @Environment(AppModel.self) private var model
    let unit: CourseUnit

    var body: some View {
        List {
            Section(unit.kind == .lesson ? "关键表达" : "挑战任务") {
                Text(script?.goal ?? unit.summary)
            }
            if !frames.isEmpty {
                Section("句框") {
                    ForEach(frames) { frame in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(frame.pattern)
                                .font(.headline)
                            Text(frame.use)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if let lesson {
                Section {
                    NavigationLink {
                        LessonPlayerView(unit: unit, lesson: lesson)
                    } label: {
                        Label(model.progress.isCompleted(unit.id) ? "再学一遍" : "开始学习", systemImage: "play.fill")
                            .font(.headline)
                    }
                }
                Section("句子") {
                    ForEach(lesson.phrases) { phrase in
                        PhraseRow(phrase: phrase)
                    }
                }
            } else if let script {
                Section {
                    NavigationLink {
                        ChallengePlayerView(unit: unit, script: script)
                    } label: {
                        Label("开始挑战", systemImage: "bubble.left.and.bubble.right.fill")
                            .font(.headline)
                    }
                }
                if let role = model.content?.rolePlay?.role(for: unit.id) {
                    Section {
                        NavigationLink {
                            RolePlayView(unit: unit, role: role)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("AI 角色扮演：\(role.name)", systemImage: "waveform.and.mic")
                                Text(role.zh)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("在线加练")
                    } footer: {
                        Text("需要联网，不计入通关。key 和每日上限在「对话 → 在线对话设置」。")
                    }
                }
                if !runs.isEmpty {
                    Section("挑战记录") {
                        ForEach(Array(runs.enumerated()), id: \.offset) { _, run in
                            LabeledContent(run.finishedAt.formatted(date: .abbreviated, time: .shortened),
                                           value: run.passed ? "通关" : "未通关")
                        }
                    }
                }
            } else {
                Section {
                    Text("这一单元的内容还在编写。")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(unit.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var lesson: LessonContent? {
        unit.kind == .lesson ? model.content?.lesson(for: unit.id) : nil
    }

    private var script: DialogueScript? {
        unit.kind == .challenge ? model.content?.dialogue(for: unit.id) : nil
    }

    private var frames: [Frame] {
        unit.frames.compactMap { model.content?.frame($0) }
    }

    private var runs: [ChallengeRun] {
        Array(model.progress.runs(of: unit.id).reversed())
    }
}

struct PhraseRow: View {
    let phrase: Phrase

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(phrase.it)
                        .font(.headline)
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
            Spacer()
            SpeakButton(text: phrase.it)
        }
        .padding(.vertical, 2)
    }
}
