import SwiftUI
import MammaCore

/// The online role-play for one challenge: free conversation with the role, by voice. Needs the
/// network and the key from 在线对话设置; extra practice that never counts towards passing.
struct RolePlayView: View {
    @Environment(AppModel.self) private var model
    let unit: CourseUnit
    let role: RolePlayRole
    @State private var session: RolePlaySession?
    @State private var typing = false
    @State private var typed = ""

    var body: some View {
        Group {
            if let session {
                content(session)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(role.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if session == nil {
                session = RolePlaySession(model: model, unit: unit, role: role)
                typing = !model.speech.isUsable
            }
            session?.start()
        }
        .onDisappear {
            session?.leave()
        }
    }

    // MARK: Layout

    private func content(_ session: RolePlaySession) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        header(session)
                        ForEach(session.conversation.lines) { line in
                            bubble(line, in: session)
                                .id(line.id)
                        }
                        if session.phase == .waiting || session.phase == .opening {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("\(role.name) 正在想…")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.callout)
                            .id("waiting")
                        }
                        if session.phase == .finished {
                            RolePlayFeedbackCard(session: session)
                                .id("feedback")
                        }
                    }
                    .padding()
                }
                .onChange(of: session.conversation.lines.count) {
                    if let last = session.conversation.lines.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
                .onChange(of: session.phase) {
                    if session.phase == .finished {
                        withAnimation { proxy.scrollTo("feedback", anchor: .top) }
                    }
                }
            }
            Divider()
            panel(session)
                .padding()
        }
    }

    private func header(_ session: RolePlaySession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(role.name) · \(role.zh)")
                .font(.headline)
            Text(role.task)
                .font(.callout)
            Text("在线加练：需要联网，不计入通关。今天还能说 \(session.remainingTurns) 个回合。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func bubble(_ line: RolePlayLine, in session: RolePlaySession) -> some View {
        if line.speaker == .learner {
            HStack {
                Spacer(minLength: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("你（识别到）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(line.text)
                }
                .padding(10)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            }
        } else {
            let hidden = line.id == session.latestRoleLineID && !session.showLatestItalian
                && session.phase != .finished
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(role.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(hidden ? "（先听，不看字）" : line.text)
                        .foregroundStyle(hidden ? Color.secondary : Color.primary)
                    if session.shownTranslations.contains(line.id), let translation = line.translation {
                        Text(translation)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 14) {
                        if hidden {
                            Button("原文") { session.showLatestItalian = true }
                        }
                        if line.translation != nil, !session.shownTranslations.contains(line.id) {
                            Button("中文") { session.shownTranslations.insert(line.id) }
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
                .padding(10)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: Bottom panel

    @ViewBuilder
    private func panel(_ session: RolePlaySession) -> some View {
        VStack(spacing: 10) {
            if let refusal = session.service.refusal {
                Label(refusal, systemImage: "exclamationmark.octagon.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("改好「对话 → 在线对话设置」并通过测试后再来。离线挑战照常能练。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if !session.service.isConfigured {
                Text("先到「对话 → 在线对话设置」粘贴 Google API key、填项目编号。")
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let notice = session.notice {
                Text(notice)
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            switch session.phase {
            case .listening:
                listeningControls(session)
            case .recording:
                Button {
                    session.stopRecording()
                } label: {
                    Label("说完了", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.red)
            case .transcribing:
                ProgressView("识别中…")
            case .opening, .waiting, .speaking:
                HStack {
                    Text(session.phase == .speaking ? "\(role.name) 在说…" : "等 \(role.name) 回答…")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("结束对话", role: .destructive) { session.end() }
                }
                .font(.callout)
            case .finished:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func listeningControls(_ session: RolePlaySession) -> some View {
        if session.canRetry {
            Button {
                session.retry()
            } label: {
                Label(session.conversation.needsOpening ? "让对方开口" : "重试这一句", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        if typing {
            HStack {
                TextField("用意大利语打字", text: $typed)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit { sendTyped(session) }
                Button("发送") { sendTyped(session) }
                    .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty || !session.canSend)
            }
        } else {
            Button {
                session.startRecording()
            } label: {
                Label("开口说", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!session.canSend || session.conversation.needsOpening)
        }
        if !model.speech.isUsable {
            SpeechStatusNote()
        }
        HStack(spacing: 16) {
            Button {
                session.replay()
            } label: {
                Label("再听", systemImage: "speaker.wave.2.fill")
            }
            .disabled(session.latestRoleLineID == nil)
            Toggle(isOn: Binding(get: { session.slow }, set: { session.slow = $0 })) {
                Label("慢速", systemImage: "tortoise.fill")
            }
            .toggleStyle(.button)
            Button {
                typing.toggle()
            } label: {
                Label(typing ? "说" : "打字", systemImage: typing ? "mic" : "keyboard")
            }
            Spacer()
            Button("结束", role: .destructive) { session.end() }
                .disabled(session.conversation.lines.isEmpty)
        }
        .font(.callout)
        .buttonStyle(.borderless)
    }

    private func sendTyped(_ session: RolePlaySession) {
        let text = typed
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        typed = ""
        session.send(typed: text)
    }
}

/// After the conversation: what went well, at most three corrections and one new expression.
/// Their sentences go into reviews as new cards; each can be taken back out.
struct RolePlayFeedbackCard: View {
    let session: RolePlaySession

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("反馈", systemImage: "text.badge.checkmark")
                .font(.title3.bold())
            switch session.feedback {
            case .notRequested:
                Text(session.conversation.hasLearnerLines ? "还没有反馈。" : "你还没说话，这次没有反馈。")
                    .foregroundStyle(.secondary)
            case .loading:
                ProgressView("老师在看这段对话…")
            case .failed(let message):
                Text(message)
                    .foregroundStyle(.orange)
                Button("重试") { session.requestFeedback() }
                    .buttonStyle(.bordered)
            case .ready(let card):
                if !card.summary.isEmpty {
                    Text(card.summary)
                }
                if card.corrections.isEmpty {
                    Text("没有需要纠正的地方。")
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(card.corrections.enumerated()), id: \.offset) { _, correction in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("你说：\(correction.said)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        sentence(correction.better, zh: correction.zh)
                        if !correction.why.isEmpty {
                            Text(correction.why)
                                .font(.footnote)
                        }
                        reviewStatus(correction.better)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
                if let expression = card.expression {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("新表达")
                            .font(.footnote.bold())
                            .foregroundStyle(.orange)
                        sentence(expression.it, zh: expression.zh)
                        if !expression.note.isEmpty {
                            Text(expression.note)
                                .font(.footnote)
                        }
                        reviewStatus(expression.it)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
                Text("加进复习的句子和课程的句子一样，从明天起按记忆曲线出现；只有复习时的自评会改变卡片。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sentence(_ text: String, zh: String) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.headline)
                if !zh.isEmpty {
                    Text(zh)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            SpeakButton(text: text)
        }
    }

    @ViewBuilder
    private func reviewStatus(_ text: String) -> some View {
        if let id = session.coursePhraseID(for: text) {
            Label("课程里有这句（\(id)）", systemImage: "book")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if session.isInReviews(text) {
            HStack {
                Label("已加入复习", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
                Button("移出复习") { session.toggleReview(text) }
                    .buttonStyle(.borderless)
            }
            .font(.caption)
        } else {
            HStack {
                Label("没加入复习", systemImage: "circle")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("加入复习") { session.toggleReview(text) }
                    .buttonStyle(.borderless)
            }
            .font(.caption)
        }
    }
}
