import SwiftUI
import MammaCore

/// The daily lesson flow from the plan: micro-lesson, listen (full speed, then slow, subtitles
/// last), shadow against your own recording, say it from the Chinese intent, then finish.
enum LessonStep: Int, CaseIterable, Identifiable {
    case intro
    case listen
    case shadow
    case speak
    case finish

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .intro: "微课"
        case .listen: "听"
        case .shadow: "跟读"
        case .speak: "说"
        case .finish: "完成"
        }
    }
}

struct LessonPlayerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let unit: CourseUnit
    let lesson: LessonContent
    @State private var step = LessonStep.intro

    var body: some View {
        VStack(spacing: 0) {
            Picker("步骤", selection: $step) {
                ForEach(LessonStep.allCases) { step in
                    Text(step.title).tag(step)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            Group {
                switch step {
                case .intro:
                    LessonIntroStep(unit: unit, lesson: lesson)
                case .listen:
                    ListenStep(phrases: lesson.phrases)
                case .shadow:
                    ShadowStep(phrases: lesson.phrases)
                case .speak:
                    SpeakStep(phrases: lesson.phrases)
                case .finish:
                    FinishStep(cardCount: lesson.phrases.count * 2) {
                        model.completeLesson(unit)
                        dismiss()
                    }
                }
            }
            .frame(maxHeight: .infinity)

            if step != .finish {
                Button {
                    step = LessonStep(rawValue: step.rawValue + 1) ?? .finish
                } label: {
                    Text("下一步")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
            }
        }
        .navigationTitle(unit.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: step) {
            model.audio.stop()
            model.recorder.stop()
        }
        .onDisappear {
            model.audio.stop()
            model.recorder.stop()
        }
    }
}

private struct LessonIntroStep: View {
    @Environment(AppModel.self) private var model
    let unit: CourseUnit
    let lesson: LessonContent

    var body: some View {
        List {
            Section(unit.focus) {
                Text(lesson.intro ?? unit.summary)
            }
            ForEach(unit.frames, id: \.self) { id in
                if let frame = model.content?.frame(id) {
                    Section("句框：\(frame.pattern)") {
                        Text(frame.use)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text(frame.example)
                                .font(.headline)
                            Spacer()
                            SpeakButton(text: frame.example)
                        }
                    }
                }
            }
        }
    }
}

private struct ListenStep: View {
    let phrases: [Phrase]
    @State private var revealed: Set<String> = []

    var body: some View {
        List {
            Section {
                Text("先听原速，再听慢速，听懂了再看字幕。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(phrases.enumerated()), id: \.element.id) { offset, phrase in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 18) {
                        Text("\(offset + 1)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        SpeakButton(text: phrase.it)
                        SpeakButton(text: phrase.it, speed: .slow)
                        Spacer()
                        Button {
                            toggle(phrase.id)
                        } label: {
                            Text(revealed.contains(phrase.id) ? "隐藏字幕" : "显示字幕")
                        }
                        .buttonStyle(.borderless)
                        .font(.callout)
                    }
                    if revealed.contains(phrase.id) {
                        Text(phrase.it)
                            .font(.headline)
                        Text(phrase.zh)
                            .foregroundStyle(.secondary)
                        if let note = phrase.note {
                            Text(note)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func toggle(_ id: String) {
        if revealed.contains(id) {
            revealed.remove(id)
        } else {
            revealed.insert(id)
        }
    }
}

private struct ShadowStep: View {
    let phrases: [Phrase]

    var body: some View {
        List {
            Section {
                Text("先听原声，再录下自己跟读，然后交替播放对比。录音只存在这台手机上。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ForEach(phrases) { phrase in
                ShadowRow(phrase: phrase)
            }
        }
    }
}

private struct ShadowRow: View {
    @Environment(AppModel.self) private var model
    let phrase: Phrase
    @State private var micDenied = false

    var body: some View {
        let isRecording = model.recorder.recordingID == phrase.id
        let hasRecording = model.recorder.hasRecording(phrase.id)
        VStack(alignment: .leading, spacing: 8) {
            Text(phrase.it)
                .font(.headline)
            Text(phrase.zh)
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack(spacing: 20) {
                SpeakButton(text: phrase.it)
                Button {
                    toggleRecording(isRecording: isRecording)
                } label: {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundStyle(isRecording ? Color.red : Color.accentColor)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(isRecording ? "停止录音" : "录音")
                Button {
                    Task { await model.audio.play(url: model.recorder.url(for: phrase.id)) }
                } label: {
                    Image(systemName: "person.wave.2.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .disabled(!hasRecording || isRecording)
                .accessibilityLabel("听自己的录音")
                Button {
                    Task { await alternate() }
                } label: {
                    Label("交替播放", systemImage: "arrow.left.arrow.right")
                        .font(.callout)
                }
                .buttonStyle(.borderless)
                .disabled(!hasRecording || isRecording)
            }
            if micDenied {
                Text("没有麦克风权限：请到 设置 → Mamma mia! 里打开麦克风。")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleRecording(isRecording: Bool) {
        if isRecording {
            model.recorder.stop()
        } else {
            model.audio.stop()
            Task { micDenied = !(await model.recorder.start(phrase.id)) }
        }
    }

    /// Model, then your own recording, so the difference is easy to hear.
    private func alternate() async {
        await model.audio.say(phrase.it)
        await model.audio.play(url: model.recorder.url(for: phrase.id))
    }
}

/// Say it from the Chinese first; then the answer, lined up with what offline recognition heard.
private struct SpeakStep: View {
    @Environment(AppModel.self) private var model
    let phrases: [Phrase]
    @State private var index = 0
    @State private var revealed = false
    @State private var attempt: SpokenAttempt?

    var body: some View {
        if phrases.isEmpty {
            ContentUnavailableView("这一课还没有句子", systemImage: "text.bubble")
        } else {
            let phrase = phrases[min(index, phrases.count - 1)]
            VStack(spacing: 16) {
                Text("\(index + 1) / \(phrases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ScrollView {
                    VStack(spacing: 20) {
                        Text(phrase.zh)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                        if revealed {
                            SpokenAnswer(text: phrase.it, attempt: attempt)
                        } else {
                            Text("先用意大利语说出来，再看答案和识别结果")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .defaultScrollAnchor(.center)
                if revealed {
                    Button {
                        revealed = false
                        attempt = nil
                        index = (index + 1) % phrases.count
                    } label: {
                        Text(index + 1 < phrases.count ? "下一句" : "再来一轮")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    SayItButton(recordingID: "say-\(phrase.id)") { result in
                        // A late result after skipping ahead belongs to a sentence no longer shown.
                        guard !revealed, phrases[min(index, phrases.count - 1)].id == phrase.id else { return }
                        attempt = result
                        reveal(phrase)
                    }
                    Button("不说了，直接看答案") {
                        reveal(phrase)
                    }
                    .font(.callout)
                }
            }
            .padding()
        }
    }

    private func reveal(_ phrase: Phrase) {
        model.recorder.stop()
        revealed = true
        Task { await model.audio.say(phrase.it) }
    }
}

private struct FinishStep: View {
    let cardCount: Int
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("这一课学完了")
                .font(.title2.bold())
            Text("会加入 \(cardCount) 张复习卡（每句听辨和回忆各一张），今天的复习里就会出现。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(action: onFinish) {
                Text("完成本课")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
