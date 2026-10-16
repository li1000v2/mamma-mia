import SwiftUI
import MammaCore

/// One spoken try: always a recording, plus what offline recognition heard when it could run.
struct SpokenAttempt: Equatable {
    let recordingID: String
    /// Nil when recognition isn't available or failed; "" when it heard nothing.
    let transcript: String?
    /// Why there's no transcript.
    let note: String?
}

/// 开口说: tap to record, tap again when done. The recording is then transcribed on the phone
/// when the Italian model is there; without it the attempt is still recorded for comparing by ear.
struct SayItButton: View {
    @Environment(AppModel.self) private var model
    let recordingID: String
    var title = "开口说"
    var prominent = true
    let onFinish: (SpokenAttempt) -> Void
    @State private var recognizing = false
    @State private var micDenied = false

    var body: some View {
        let isRecording = model.recorder.recordingID == recordingID
        VStack(spacing: 6) {
            styled(
                Button {
                    toggle(isRecording: isRecording)
                } label: {
                    Label(isRecording ? "说完了" : title, systemImage: isRecording ? "stop.circle.fill" : "mic.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(isRecording ? Color.red : Color.accentColor)
                .disabled(recognizing)
            )
            if recognizing {
                ProgressView("识别中…")
                    .font(.footnote)
            } else if isRecording {
                Text("正在录音，说完点一下")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if micDenied {
                Text("没有麦克风权限：请到 设置 → Mamma mia! 里打开麦克风。")
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else {
                SpeechStatusNote()
            }
        }
    }

    @ViewBuilder
    private func styled(_ button: some View) -> some View {
        if prominent {
            button.buttonStyle(.borderedProminent).controlSize(.large)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    private func toggle(isRecording: Bool) {
        if isRecording {
            model.recorder.stop()
            Task { await finish() }
        } else {
            model.audio.stop()
            Task {
                await model.speech.requestPermissionIfNeeded()
                micDenied = !(await model.recorder.start(recordingID))
            }
        }
    }

    private func finish() async {
        recognizing = true
        let result = await model.speech.recognize(model.recorder.url(for: recordingID))
        recognizing = false
        onFinish(SpokenAttempt(recordingID: recordingID, transcript: result.transcript, note: result.note))
    }
}

/// A one-line note under the speak button while recognition isn't ready, with the model download.
struct SpeechStatusNote: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        switch model.speech.status {
        case .needsDownload:
            HStack(spacing: 8) {
                Text("下载意大利语识别模型后，能看出对方听不听得懂。")
                Button("下载") {
                    Task { await model.speech.downloadModel() }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        case .downloading(_, let fraction):
            ProgressView("正在下载识别模型", value: fraction)
                .font(.footnote)
        case .unsupported:
            Text("这台手机不能离线识别意大利语：录下来自己对比。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .ready where model.speech.permission == .denied:
            Text("没有语音识别权限：到 设置 → Mamma mia! 打开，就能看出对方听不听得懂。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        default:
            EmptyView()
        }
    }
}

/// The target sentence with the words recognition missed in red, and what was heard.
struct SpeechCheckView: View {
    let check: SpeechCheck

    var body: some View {
        VStack(spacing: 10) {
            Label(verdictTitle, systemImage: verdictIcon)
                .font(.headline)
                .foregroundStyle(verdictColor)
            sentence
                .font(.title3)
                .multilineTextAlignment(.center)
            if check.verdict != .silent {
                ForEach(Array(check.missed.enumerated()), id: \.offset) { _, word in
                    Text(missedLine(word))
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            Text(check.transcript.isEmpty ? "识别到：（什么也没听到）" : "识别到：\(check.transcript)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var sentence: Text {
        check.words.reduce(Text(check.leading)) { (partial: Text, word: SpeechCheck.Word) -> Text in
            let piece = word.heard ? Text(word.text) : Text(word.text).foregroundStyle(.red).underline()
            return Text("\(partial)\(piece)\(word.trailing)")
        }
    }

    private func missedLine(_ word: SpeechCheck.Word) -> String {
        let text = "「\(word.text)」这个词对方可能听不清"
        guard let heardAs = word.heardAs else { return text }
        return text + "（听成了 \(heardAs)）"
    }

    private var verdictTitle: String {
        switch check.verdict {
        case .clear: "对方应该能听懂"
        case .mostly: "大部分能听懂"
        case .unclear: "对方可能听不懂"
        case .silent: "没听到意大利语，靠近一点再说一次"
        }
    }

    private var verdictIcon: String {
        switch check.verdict {
        case .clear: "checkmark.circle.fill"
        case .mostly: "exclamationmark.circle.fill"
        case .unclear: "xmark.circle.fill"
        case .silent: "mic.slash"
        }
    }

    private var verdictColor: Color {
        switch check.verdict {
        case .clear: .green
        case .mostly: .orange
        case .unclear: .red
        case .silent: .secondary
        }
    }
}

/// The answer after a spoken try: the alignment when recognition ran, otherwise the plain sentence
/// and why, then the model audio and 录音对比 (your take alone, or model and yours back to back).
struct SpokenAnswer: View {
    @Environment(AppModel.self) private var model
    let text: String
    let attempt: SpokenAttempt?

    var body: some View {
        VStack(spacing: 12) {
            if let transcript = attempt?.transcript {
                SpeechCheckView(check: SpeechCheck(target: text, transcript: transcript))
            } else {
                Text(text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                if let note = attempt?.note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            HStack(spacing: 28) {
                SpeakButton(text: text)
                SpeakButton(text: text, speed: .slow)
            }
            if let attempt {
                HStack(spacing: 12) {
                    Button {
                        Task { await model.audio.play(url: model.recorder.url(for: attempt.recordingID)) }
                    } label: {
                        Label("听自己的", systemImage: "person.wave.2.fill")
                    }
                    Button {
                        Task {
                            await model.audio.say(text)
                            await model.audio.play(url: model.recorder.url(for: attempt.recordingID))
                        }
                    } label: {
                        Label("交替播放", systemImage: "arrow.left.arrow.right")
                    }
                }
                .buttonStyle(.bordered)
                .font(.callout)
            }
        }
    }
}
