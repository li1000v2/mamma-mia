import Foundation
import Observation
import MammaCore

/// One online role-play. The learner speaks; a filler in the role's voice plays at once while the
/// phone transcribes offline; the transcript goes to the reply model, whose answer is cut into
/// sentences and spoken through Gemini TTS while it streams. After the session a feedback card
/// adds its corrections to reviews as new cards. Extra practice only: nothing here touches
/// challenge results or card states.
@MainActor
@Observable
final class RolePlaySession {
    enum Phase: Equatable {
        /// The role is opening the conversation.
        case opening
        /// The learner's turn.
        case listening
        case recording
        case transcribing
        /// The reply was asked for and isn't playing yet.
        case waiting
        case speaking
        /// Over: the feedback card.
        case finished
    }

    enum Feedback: Equatable {
        case notRequested
        case loading
        case ready(RolePlayFeedback)
        case failed(String)
    }

    static let recordingID = "roleplay"

    let unit: CourseUnit
    let role: RolePlayRole
    private(set) var conversation: RolePlayConversation
    private(set) var phase = Phase.listening
    /// What went wrong with the last step, shown above the controls.
    private(set) var notice: String?
    private(set) var feedback = Feedback.notRequested
    /// The latest reply can be played again from memory, without a request.
    private(set) var canReplay = false
    /// The latest role line's Italian stays hidden until 原文: listen first.
    var showLatestItalian = false
    /// Role lines whose Chinese is shown, by line id.
    var shownTranslations: Set<Int> = []
    var slow = false
    /// Feedback sentences now in reviews, by `PracticePhrase.key` → phrase id.
    private(set) var inReviews: [String: String] = [:]

    @ObservationIgnored private let model: AppModel
    @ObservationIgnored private let player = StreamingSpeechPlayer()
    @ObservationIgnored private var work: Task<Void, Never>?
    @ObservationIgnored private var speaker: ReplySpeaker?
    @ObservationIgnored private var fillerIndex = Int.random(in: 0..<12)
    /// Gemini speech was refused once: the rest of the session uses the phone's voice.
    @ObservationIgnored private var systemVoiceOnly = false
    /// Every lesson phrase by `PracticePhrase.key` → id: feedback sentences the course already teaches.
    @ObservationIgnored private let coursePhraseIDs: [String: String]
    /// What the lessons before this challenge taught, for the feedback request.
    @ObservationIgnored private let coursePhrases: [String]

    init(model: AppModel, unit: CourseUnit, role: RolePlayRole) {
        self.model = model
        self.unit = unit
        self.role = role
        conversation = RolePlayConversation(role: role)
        var ids: [String: String] = [:]
        for phrase in model.content?.phrases ?? [] {
            ids[PracticePhrase.key(phrase.it)] = ids[PracticePhrase.key(phrase.it)] ?? phrase.id
        }
        coursePhraseIDs = ids
        coursePhrases = (model.planner?.lessons(before: unit.id) ?? []).flatMap { lesson in
            model.content?.lesson(for: lesson.id)?.phrases.map(\.it) ?? []
        }
    }

    var service: RolePlayService { model.rolePlay }

    var remainingTurns: Int {
        service.remaining(on: model.today)
    }

    /// Requests can go out: settings filled in and nothing refused.
    var canSend: Bool {
        service.isConfigured && service.refusal == nil
    }

    var latestRoleLineID: Int? {
        conversation.lines.last { $0.speaker == .role }?.id
    }

    /// The learner line, or the opening, that failed and can be asked for again.
    var canRetry: Bool {
        phase == .listening && canSend && (conversation.awaitsReply || conversation.needsOpening)
    }

    // MARK: Flow

    /// On appear: the role opens if it's its turn. Does nothing while something is going on.
    func start() {
        guard phase == .listening, work == nil, canSend, conversation.needsOpening else { return }
        guard remainingTurns > 0 else {
            notice = usedUpNotice
            return
        }
        notice = nil
        phase = .opening
        let started = Date.now
        work = Task { await reply(filler: nil, since: started, learnerTurn: false) }
    }

    func startRecording() {
        guard phase == .listening, canSend else { return }
        stopAudio()
        notice = nil
        phase = .recording
        Task {
            await model.speech.requestPermissionIfNeeded()
            let started = await model.recorder.start(Self.recordingID)
            if !started, phase == .recording {
                phase = .listening
                notice = "没有麦克风权限：请到 设置 → Mamma mia! 里打开麦克风。"
            }
        }
    }

    /// The learner is done: the filler starts at once, recognition runs meanwhile.
    func stopRecording() {
        guard phase == .recording else { return }
        let recorded = model.recorder.recordingID == Self.recordingID
        model.recorder.stop()
        guard recorded else {
            phase = .listening
            return
        }
        let stoppedAt = Date.now
        phase = .transcribing
        let filler = playFiller()
        work = Task {
            let result = await model.speech.recognize(model.recorder.url(for: Self.recordingID), logText: false)
            guard !Task.isCancelled else { return }
            let transcript = result.transcript?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            AppLog.shared.write("RolePlay \(role.unit): recognized in \(RolePlayService.seconds(since: stoppedAt))")
            guard !transcript.isEmpty else {
                await filler?.value
                work = nil
                phase = .listening
                notice = result.transcript == nil
                    ? (result.note ?? "这次没能识别，再说一次。")
                    : "没听清你说的，再说一次（不算回合）。"
                return
            }
            await sendLearnerLine(transcript, filler: filler, since: stoppedAt)
        }
    }

    /// Typed instead of spoken, when recognition can't run or keeps mishearing.
    func send(typed text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, phase == .listening, canSend else { return }
        stopAudio()
        notice = nil
        let sentAt = Date.now
        let filler = playFiller()
        work = Task { await sendLearnerLine(text, filler: filler, since: sentAt) }
    }

    /// Asks again for the reply (or the opening) that failed.
    func retry() {
        guard canRetry else { return }
        notice = nil
        if conversation.needsOpening {
            start()
            return
        }
        guard remainingTurns > 0 else {
            notice = usedUpNotice
            return
        }
        phase = .waiting
        let started = Date.now
        work = Task { await reply(filler: nil, since: started, learnerTurn: true) }
    }

    /// The latest reply again, from memory.
    func replay() {
        guard phase == .listening || phase == .finished else { return }
        model.audio.stop()
        if canReplay {
            let rate: Float = slow ? 0.75 : 1
            Task { await player.replay(rate: rate) }
        } else if let line = conversation.lines.last(where: { $0.speaker == .role }) {
            Task { await model.audio.sayWithSystemVoice(line.text, speed: slow ? .slow : .normal) }
        }
    }

    /// Ends the conversation and asks for the feedback card.
    func end() {
        cancelWork()
        model.recorder.stop()
        phase = .finished
        if conversation.hasLearnerLines, case .notRequested = feedback {
            requestFeedback()
        }
    }

    /// Leaving the screen: the conversation stops where it was. A finished one keeps going in the
    /// background until its feedback and recordings are in, so its sentences still reach reviews.
    func leave() {
        model.recorder.stop()
        if phase == .finished {
            stopAudio()
            return
        }
        cancelWork()
        switch phase {
        case .opening, .recording, .transcribing, .waiting, .speaking:
            phase = .listening
        case .listening, .finished:
            break
        }
    }

    // MARK: Turn

    private func sendLearnerLine(_ text: String, filler: Task<Void, Never>?, since start: Date) async {
        guard remainingTurns > 0 else {
            await filler?.value
            work = nil
            notice = usedUpNotice
            end()
            return
        }
        conversation.addLearner(text)
        await reply(filler: filler, since: start, learnerTurn: true)
    }

    /// Streams the role's next line and speaks it sentence by sentence as it arrives.
    private func reply(filler: Task<Void, Never>?, since start: Date, learnerTurn: Bool) async {
        guard let client = service.client() else {
            phase = .listening
            work = nil
            notice = "先在「在线对话设置」里填好 key 和项目编号。"
            return
        }
        phase = learnerTurn ? .waiting : .opening
        showLatestItalian = false
        canReplay = false
        let voiceName = systemVoiceOnly ? nil : model.content?.audio?.voiceName(for: role.voice)
        let speaker = ReplySpeaker(client: client, voiceName: voiceName, player: player, audio: model.audio,
                                   rate: slow ? 0.75 : 1, after: filler)
        self.speaker = speaker
        var chunker = SentenceChunker()
        var raw = ""
        var firstText: Date?
        var stopReason: String?
        do {
            let body = conversation.replyRequest()
            for try await event in client.stream(model: service.replyModel.rawValue, body: body) {
                switch event {
                case .text(let delta):
                    firstText = firstText ?? .now
                    raw += delta
                    for sentence in chunker.append(delta) {
                        speaker.say(sentence)
                    }
                case .blocked(let reason), .finished(let reason):
                    stopReason = reason
                case .audio, .usage:
                    break
                }
            }
            for sentence in chunker.finish() {
                speaker.say(sentence)
            }
        } catch is CancellationError {
            speaker.cancel()
            return
        } catch {
            speaker.cancel()
            fail(error)
            return
        }
        guard !Task.isCancelled else {
            speaker.cancel()
            return
        }
        guard conversation.addRole(raw: raw) != nil else {
            speaker.cancel()
            phase = .listening
            work = nil
            notice = stopReason.map { "对方没有回答（\($0)）。换个说法再试。" } ?? "对方没有回答，再试一次。"
            AppLog.shared.write("RolePlay \(role.unit): empty reply (\(stopReason ?? "no reason"))")
            return
        }
        if learnerTurn {
            service.spendTurn(on: model.today)
        }
        phase = .speaking
        await speaker.finish()
        guard !Task.isCancelled else { return }
        canReplay = player.hasReply
        if let refusal = speaker.refusal, !systemVoiceOnly {
            systemVoiceOnly = true
            notice = "语音合成被拒绝（\(refusal.status)），这次对话改用手机自带的意大利语声音。"
        }
        let turn = learnerTurn ? "turn \(conversation.learnerTurns)" : "opening"
        AppLog.shared.write("RolePlay \(role.unit) \(turn): first text \(Self.offset(firstText, from: start)), first audio \(Self.offset(speaker.firstAudio, from: start)), \(service.replyModel.rawValue)")
        self.speaker = nil
        work = nil
        if conversation.isFull {
            notice = "这次对话满 \(RolePlayConversation.turnsPerSession) 个回合了。"
            end()
        } else {
            phase = .listening
        }
    }

    private func fail(_ error: Error) {
        let failure = error as? GeminiFailure ?? GeminiFailure.network(error.localizedDescription)
        if failure.stopsSession {
            service.noteRefusal(failure)
        }
        AppLog.shared.write("RolePlay \(role.unit): reply failed, \(failure)")
        notice = failure.message
        phase = .listening
        work = nil
    }

    // MARK: Feedback

    func requestFeedback() {
        guard conversation.hasLearnerLines else { return }
        guard canSend, let client = service.client() else {
            feedback = .failed(service.refusal ?? "先在「在线对话设置」里填好 key 和项目编号。")
            return
        }
        feedback = .loading
        let body = conversation.feedbackRequest(coursePhrases: coursePhrases)
        let started = Date.now
        work = Task {
            do {
                let response = try await client.generate(model: GeminiModels.feedback, body: body)
                let card = try RolePlayFeedback.parse(response.text)
                guard !Task.isCancelled else { return }
                feedback = .ready(card)
                addToReviews(card)
                AppLog.shared.write("RolePlay \(role.unit): feedback in \(RolePlayService.seconds(since: started)), \(card.corrections.count) corrections, \(inReviews.count) phrases in reviews")
                await recordPracticeAudio(client: client)
            } catch is CancellationError {
                return
            } catch {
                let failure = error as? GeminiFailure ?? GeminiFailure.malformed("\(error)")
                if failure.stopsSession {
                    service.noteRefusal(failure)
                }
                AppLog.shared.write("RolePlay \(role.unit): feedback failed, \(failure)")
                feedback = .failed(failure.message)
            }
            work = nil
        }
    }

    /// Where a feedback sentence stands: the lesson phrase that teaches it, if any.
    func coursePhraseID(for text: String) -> String? {
        coursePhraseIDs[PracticePhrase.key(text)]
    }

    func isInReviews(_ text: String) -> Bool {
        inReviews[PracticePhrase.key(text)] != nil
    }

    /// Takes a feedback sentence out of reviews, or puts it back.
    func toggleReview(_ text: String) {
        guard case .ready(let card) = feedback else { return }
        let key = PracticePhrase.key(text)
        if let id = inReviews[key] {
            model.removePracticePhrase(id)
            inReviews[key] = nil
        } else if let phrase = card.practicePhrases(role: role, addedAt: .now, taught: Set(coursePhraseIDs.keys))
            .first(where: { PracticePhrase.key($0.it) == key }) {
            model.addPracticePhrases([phrase])
            inReviews[key] = phrase.id
            if let client = service.client(), canSend {
                Task { await recordPracticeAudio(client: client) }
            }
        }
    }

    private func addToReviews(_ card: RolePlayFeedback) {
        let phrases = card.practicePhrases(role: role, addedAt: .now, taught: Set(coursePhraseIDs.keys))
        model.addPracticePhrases(phrases)
        for phrase in phrases {
            inReviews[PracticePhrase.key(phrase.it)] = phrase.id
        }
    }

    /// The new review sentences in the role's voice, so their cards don't fall back to the phone's.
    private func recordPracticeAudio(client: GeminiClient) async {
        guard !systemVoiceOnly, let voiceName = model.content?.audio?.voiceName(for: role.voice) else { return }
        guard case .ready(let card) = feedback else { return }
        let texts = card.corrections.map(\.better) + [card.expression?.it].compactMap { $0 }
        for text in texts where isInReviews(text) && PracticeAudio.recording(for: text) == nil {
            var pcm = Data()
            do {
                for try await event in client.stream(model: GeminiModels.speech, body: GeminiRequest.speech(text, voiceName: voiceName)) {
                    if case .audio(let data, _) = event {
                        pcm.append(data)
                    }
                }
                if !pcm.isEmpty {
                    try PracticeAudio.save(pcm: pcm, for: text)
                }
            } catch is CancellationError {
                return
            } catch {
                AppLog.shared.write("RolePlay: couldn't record a review sentence: \(error)")
                return
            }
        }
    }

    // MARK: Helpers

    private var usedUpNotice: String {
        "今天的 \(service.allowance.dailyLimit) 个回合用完了，明天再练；上限可以在「在线对话设置」里调。"
    }

    /// The next filler ("Allora…") in the role's voice, playing right away; nil when there's none.
    private func playFiller() -> Task<Void, Never>? {
        guard let fillers = model.content?.rolePlay?.fillers, !fillers.isEmpty else { return nil }
        let filler = fillers[fillerIndex % fillers.count]
        fillerIndex += 1
        let audio = model.audio
        let voice = role.voice
        let speed: Speed = slow ? .slow : .normal
        return Task { _ = await audio.playRecording(filler, voice: voice, speed: speed) }
    }

    private func stopAudio() {
        player.stop()
        model.audio.stop()
    }

    private func cancelWork() {
        work?.cancel()
        work = nil
        speaker?.cancel()
        speaker = nil
        stopAudio()
    }

    private static func offset(_ date: Date?, from start: Date) -> String {
        guard let date else { return "-" }
        return String(format: "%.1fs", date.timeIntervalSince(start))
    }
}
