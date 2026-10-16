import SwiftUI
import MammaCore

/// Plays one offline scripted challenge. Replies can be said aloud and are matched to a choice by
/// its words; when recognition can't run or nothing matches, you tap the choice instead. Each run
/// reshuffles the follow-up questions, line variants and choices.
struct ChallengePlayerView: View {
    @Environment(AppModel.self) private var model
    let unit: CourseUnit
    let script: DialogueScript

    private enum Stage {
        case listening, question, reply, finished
    }

    @State private var beats: [DialogueBeat] = []
    @State private var index = 0
    @State private var stage = Stage.listening
    @State private var tally = ChallengeTally()
    @State private var showItalian = false
    @State private var showChinese = false
    @State private var hint: ReplyHint?
    @State private var feedback: String?
    @State private var answered: String?
    @State private var said: [Int: String] = [:]
    /// What recognition heard for replies that were spoken, by beat.
    @State private var heard: [Int: String] = [:]
    @State private var spokenNote: String?
    @State private var result: ChallengeRun?

    private var beat: DialogueBeat? {
        beats.indices.contains(index) ? beats[index] : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(script.goal)
                        .font(.callout)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    ForEach(beats.prefix(index)) { past in
                        pastExchange(past)
                    }
                    if let beat, stage != .finished {
                        currentLine(beat)
                    }
                }
                .padding()
            }
            Divider()
            panel
                .padding()
        }
        .navigationTitle(script.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if beats.isEmpty { restart() }
        }
        .onDisappear {
            model.audio.stop()
            model.recorder.stop()
        }
    }

    // MARK: Transcript

    private func pastExchange(_ beat: DialogueBeat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            bubble(speaker: script.speaker, text: beat.line.it, detail: beat.line.zh, mine: false)
            if let reply = said[beat.id] {
                bubble(speaker: "你", text: reply, detail: heard[beat.id].map { "识别到：\($0)" }, mine: true)
            }
        }
    }

    private func bubble(speaker: String, text: String, detail: String?, mine: Bool) -> some View {
        HStack {
            if mine { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                Text(speaker)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(text)
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .background(mine ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 12))
            if !mine { Spacer(minLength: 40) }
        }
    }

    private func currentLine(_ beat: DialogueBeat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(script.speaker)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(showItalian ? beat.line.it : "（先听，不看字）")
                .font(.title3)
                .foregroundStyle(showItalian ? Color.primary : Color.secondary)
            if showChinese {
                Text(beat.line.zh)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Button("再听") { Task { await model.audio.say(beat.line.it, voice: script.voice) } }
                Button("慢速") { Task { await model.audio.say(beat.line.it, speed: .slow, voice: script.voice) } }
                Button("原文") { showItalian = true }
                    .disabled(showItalian)
                Button("中文（算提示）") {
                    showChinese = true
                    tally.useHint()
                }
                .disabled(showChinese)
            }
            .buttonStyle(.bordered)
            .font(.callout)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Bottom panel

    @ViewBuilder
    private var panel: some View {
        switch stage {
        case .listening:
            Button {
                afterListening()
            } label: {
                Text("听完了")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        case .question:
            if let question = beat?.question {
                questionPanel(question)
            }
        case .reply:
            if let reply = beat?.reply {
                replyPanel(reply)
            }
        case .finished:
            if let result {
                resultPanel(result)
            }
        }
    }

    private func questionPanel(_ question: KeyInfoQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.prompt)
                .font(.headline)
            ForEach(question.options, id: \.self) { option in
                Button {
                    guard answered == nil else { return }
                    answered = option
                    tally.answer(option, to: question)
                } label: {
                    HStack {
                        Text(option)
                        Spacer()
                        if answered != nil, option == question.answer {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        } else if option == answered {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
            if answered != nil {
                Button {
                    answered = nil
                    if beat?.reply != nil {
                        stage = .reply
                    } else {
                        advance()
                    }
                } label: {
                    Text("继续")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func replyPanel(_ reply: DialogueReply) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("你要说：")
                    .font(.headline)
                Spacer()
                Button(hintButtonTitle) { escalateHint() }
                    .disabled(hint == .sentence)
                    .font(.callout)
            }
            if let hint {
                Text("意图：\(reply.intent)")
                    .font(.callout)
                if hint >= .frame {
                    Text("句框：\(framePattern(reply))")
                        .font(.callout)
                }
            }
            if model.speech.isUsable {
                SayItButton(recordingID: "reply", title: "直接说出来", prominent: false, requiresRecognition: true) { attempt in
                    hear(attempt, for: reply)
                }
            } else {
                // Without recognition there's nothing to match a spoken reply against: tap only.
                SpeechStatusNote()
            }
            if let spokenNote {
                Text(spokenNote)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ForEach(reply.choices, id: \.it) { choice in
                Button {
                    pick(choice)
                } label: {
                    Text(choice.it)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(hint == .sentence && choice.correct ? Color.green : nil)
            }
            if let feedback {
                Text(feedback)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
    }

    private func resultPanel(_ run: ChallengeRun) -> some View {
        VStack(spacing: 10) {
            Label(run.passed ? "通关！" : "这次没通关", systemImage: run.passed ? "star.fill" : "arrow.counterclockwise")
                .font(.title2.bold())
                .foregroundStyle(run.passed ? Color.orange : Color.primary)
            Text("关键信息 \(run.keyInfoCorrect)/\(run.keyInfoAsked) · 提示 \(run.hintsUsed) 次 · 说错 \(run.mistakes) 次")
                .font(.callout)
                .foregroundStyle(.secondary)
            if !run.passed {
                Text("通关要求：关键信息题全对，提示不超过 1 次。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Button {
                restart()
            } label: {
                Text("再来一次")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: Flow

    private var hintButtonTitle: String {
        switch hint {
        case nil: "提示：中文意图"
        case .intent?: "提示：句框"
        case .frame?: "提示：整句"
        case .sentence?: "已给出整句"
        }
    }

    private func framePattern(_ reply: DialogueReply) -> String {
        reply.frame.flatMap { model.content?.frame($0)?.pattern } ?? "这句不用固定句框"
    }

    private func escalateHint() {
        let next: ReplyHint? = hint == nil ? .intent : hint?.next
        guard let next else { return }
        hint = next
        tally.useHint()
    }

    private func afterListening() {
        guard let beat else { return }
        if beat.question != nil {
            stage = .question
        } else if beat.reply != nil {
            stage = .reply
        } else {
            advance()
        }
    }

    /// Treats a spoken reply like tapping the choice it matches; otherwise the choices stay to tap.
    private func hear(_ attempt: SpokenAttempt, for reply: DialogueReply) {
        guard let beat, stage == .reply, beat.reply == reply else { return }
        guard let transcript = attempt.transcript else {
            spokenNote = "这次没能识别，点选你想说的那句。"
            return
        }
        guard let index = ReplyMatcher.match(transcript, choices: reply.choices.map(\.it)) else {
            let what = transcript.isEmpty ? "（什么也没听到）" : "「\(transcript)」"
            spokenNote = "识别到\(what)，没对上任何一句。点选你想说的那句。"
            return
        }
        let choice = reply.choices[index]
        spokenNote = "识别到「\(transcript)」→ \(choice.it)"
        if choice.correct {
            heard[beat.id] = transcript
        }
        pick(choice)
    }

    private func pick(_ choice: DialogueChoice) {
        guard let beat else { return }
        if tally.choose(choice) {
            said[beat.id] = choice.it
            advance()
        } else {
            feedback = choice.feedback ?? "对方好像没听懂，换一句试试。"
        }
    }

    private func advance() {
        index += 1
        stage = .listening
        showItalian = false
        showChinese = false
        hint = nil
        feedback = nil
        spokenNote = nil
        answered = nil
        if let beat {
            Task { await model.audio.say(beat.line.it, voice: script.voice) }
        } else {
            finish()
        }
    }

    private func finish() {
        let run = tally.run(unit: unit.id, finishedAt: .now)
        result = run
        stage = .finished
        model.record(run)
    }

    private func restart() {
        var generator = SystemRandomNumberGenerator()
        beats = DialoguePlanner.beats(for: script, using: &generator)
        index = 0
        stage = .listening
        tally = ChallengeTally()
        showItalian = false
        showChinese = false
        hint = nil
        feedback = nil
        spokenNote = nil
        answered = nil
        said = [:]
        heard = [:]
        result = nil
        if let first = beats.first {
            Task { await model.audio.say(first.line.it, voice: script.voice) }
        }
    }
}
