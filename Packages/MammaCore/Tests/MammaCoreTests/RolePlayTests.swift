import Foundation
import Testing
@testable import MammaCore

struct RolePlayTests {
    static func pizzaiolo(opens: Bool = true) -> RolePlayRole {
        RolePlayRole(unit: "C06", name: "Pizzaiolo", zh: "披萨店师傅", voice: "m1", scene: "pizzeria", opens: opens,
                     setting: "You are a pizzaiolo in Naples.", task: "外带一个披萨。")
    }

    static func chunks(_ deltas: [String], minimumLength: Int = 12) -> [String] {
        var chunker = SentenceChunker(minimumLength: minimumLength)
        return deltas.flatMap { chunker.append($0) } + chunker.finish()
    }

    // MARK: Sentence chunking

    @Test func cutsSentencesAsTheyComplete() {
        var chunker = SentenceChunker()
        #expect(chunker.append("Sì, siamo aperti fino alle dieci.") == [])
        // The sentence goes out as soon as the next one starts.
        #expect(chunker.append(" Cosa") == ["Sì, siamo aperti fino alle dieci."])
        #expect(chunker.append(" desidera?") == [])
        #expect(chunker.finish() == ["Cosa desidera?"])
    }

    @Test func stopsAtTheTranslationAndSendsTheRestRightAway() {
        var chunker = SentenceChunker()
        #expect(chunker.append("Perfetto, una margherita. Vuole qualcosa da bere?") == ["Perfetto, una margherita."])
        // The line break ends the Italian: the last sentence goes out without waiting for the end.
        #expect(chunker.append("\n好的，一个玛格丽特。") == ["Vuole qualcosa da bere?"])
        #expect(chunker.isFinished)
        #expect(chunker.append(" 您要喝点什么吗？") == [])
        #expect(chunker.finish() == [])
    }

    @Test func aTranslationOnTheSameLineIsNotSpoken() {
        #expect(Self.chunks(["Buonasera! Dica pure. (晚上好！请说。)"]) == ["Buonasera! Dica pure."])
        #expect(Self.chunks(["Ecco a lei 给您"]) == ["Ecco a lei"])
    }

    @Test func survivesAnyStreamBoundaries() {
        let reply = "Allora… vediamo. Oggi chiudiamo alle nove e mezza, Sig. Rossi! Va bene?\n可以吗？"
        let whole = Self.chunks([reply])
        #expect(whole == ["Allora… vediamo.", "Oggi chiudiamo alle nove e mezza, Sig. Rossi!", "Va bene?"])
        let characterByCharacter = Self.chunks(reply.map { String($0) })
        #expect(characterByCharacter == whole)
    }

    @Test func shortPiecesWaitForTheNextSentence() {
        #expect(Self.chunks(["Sì. Siamo aperti oggi. Prego!"]) == ["Sì. Siamo aperti oggi.", "Prego!"])
        #expect(Self.chunks(["Sì. Siamo aperti oggi."], minimumLength: 0) == ["Sì.", "Siamo aperti oggi."])
    }

    @Test func decimalsAndLowercaseContinuationsDontEndSentences() {
        #expect(Self.chunks(["Sono 3.50 euro, grazie mille. Altro?"]) == ["Sono 3.50 euro, grazie mille.", "Altro?"])
        #expect(Self.chunks(["Allora... vediamo un attimo. Ecco!"], minimumLength: 0)
            == ["Allora... vediamo un attimo.", "Ecco!"])
    }

    @Test func cleansWhatShouldntBeRead() {
        #expect(Self.chunks(["  **Buonasera!** 😊 Prego, si accomodi."]) == ["Buonasera! Prego, si accomodi."])
        #expect(Self.chunks(["IT: Ecco il menù."]) == ["Ecco il menù."])
        #expect(Self.chunks(["\n\n"]) == [])
    }

    @Test func replySplitsItalianAndChinese() {
        let reply = RolePlayReply(raw: "Sì, siamo aperti. Cosa desidera?\n是的，我们开着。您要什么？")
        #expect(reply.italian == "Sì, siamo aperti. Cosa desidera?")
        #expect(reply.chinese == "是的，我们开着。您要什么？")

        let sameLine = RolePlayReply(raw: "Prego! （请进！）")
        #expect(sameLine.italian == "Prego!")
        #expect(sameLine.chinese == "请进！")

        let labelled = RolePlayReply(raw: "Margherita da asporto?\n\nZH: Margherita 外带？")
        #expect(labelled.chinese == "Margherita 外带？")

        let italianOnly = RolePlayReply(raw: "Arrivederci!")
        #expect(italianOnly.italian == "Arrivederci!")
        #expect(italianOnly.chinese == nil)
    }

    // MARK: Conversation and requests

    @Test func historyStartsWithTheOpeningCueAndAlternates() throws {
        var conversation = RolePlayConversation(role: Self.pizzaiolo())
        #expect(conversation.needsOpening)
        let opening = try #require(conversation.addRole(raw: "Buonasera! Dica.\n晚上好！请说。"))
        #expect(opening.text == "Buonasera! Dica.")
        #expect(opening.translation == "晚上好！请说。")
        conversation.addLearner("  siete aperti oggi ")
        #expect(conversation.awaitsReply)
        // A failed request left the first line without a reply; the next one is sent with it.
        conversation.addLearner("Siete aperti?")

        let contents = conversation.contents()
        #expect(contents.count == 3)
        #expect(contents[0]["role"]?.stringValue == "user")
        #expect(contents[0]["parts"]?[0]?["text"]?.stringValue == RolePlayPrompt.openingCue)
        #expect(contents[1]["role"]?.stringValue == "model")
        // The model's own two lines go back as history, so it keeps the format.
        #expect(contents[1]["parts"]?[0]?["text"]?.stringValue == "Buonasera! Dica.\n晚上好！请说。")
        #expect(contents[2]["role"]?.stringValue == "user")
        #expect(contents[2]["parts"]?[0]?["text"]?.stringValue == "siete aperti oggi\nSiete aperti?")
        #expect(conversation.learnerTurns == 2)
    }

    @Test func aPasserByWaitsForTheLearner() {
        var conversation = RolePlayConversation(role: Self.pizzaiolo(opens: false))
        #expect(!conversation.needsOpening)
        #expect(conversation.contents().isEmpty)
        conversation.addLearner("Scusi, dov'è il Colosseo?")
        #expect(conversation.contents().count == 1)
        #expect(conversation.addRole(raw: "\n") == nil)
        #expect(conversation.lines.count == 1)
    }

    @Test func sessionsEndAfterTwentyTurns() {
        var conversation = RolePlayConversation(role: Self.pizzaiolo(opens: false))
        for turn in 1...RolePlayConversation.turnsPerSession {
            #expect(!conversation.isFull)
            conversation.addLearner("Frase \(turn)")
            conversation.addRole(raw: "Va bene.\n好的。")
        }
        #expect(conversation.isFull)
    }

    @Test func replyRequestUsesLowThinkingAndNoBudget() throws {
        var conversation = RolePlayConversation(role: Self.pizzaiolo())
        conversation.addRole(raw: "Buonasera!\n晚上好！")
        conversation.addLearner("Una margherita, per favore.")
        let body = conversation.replyRequest()
        let config = try #require(body["generationConfig"])
        #expect(config["thinkingConfig"]?["thinkingLevel"]?.stringValue == "LOW")
        #expect(config["thinkingConfig"]?["thinkingBudget"] == nil)
        let system = try #require(body["systemInstruction"]?["parts"]?[0]?["text"]?.stringValue)
        #expect(system.contains("You are a pizzaiolo in Naples."))
        #expect(system.contains("At most 15 words"))
        #expect(system.contains("Lei"))
        #expect(system.contains("Parla inglese?"))
        #expect(system.contains("Simplified Chinese"))

        let json = String(decoding: try body.encoded(), as: UTF8.self)
        #expect(!json.contains("thinking_budget"))
        #expect(json.contains("\"maxOutputTokens\":1024"))
    }

    @Test func feedbackAsksForJSONWithMediumThinking() throws {
        var conversation = RolePlayConversation(role: Self.pizzaiolo())
        conversation.addRole(raw: "Buonasera!\n晚上好！")
        conversation.addLearner("Io volere pizza")
        let body = conversation.feedbackRequest()
        #expect(body["generationConfig"]?["thinkingConfig"]?["thinkingLevel"]?.stringValue == "MEDIUM")
        #expect(body["generationConfig"]?["responseMimeType"]?.stringValue == "application/json")
        let required: JSONValue = ["summary", "corrections", "expression"]
        #expect(body["generationConfig"]?["responseSchema"]?["required"] == required)
        let prompt = try #require(body["contents"]?[0]?["parts"]?[0]?["text"]?.stringValue)
        #expect(prompt.contains("ROLE: Buonasera!\n"))
        #expect(prompt.contains("LEARNER: Io volere pizza\n"))
        #expect(prompt.contains("外带一个披萨。"))
        #expect(!prompt.contains("晚上好"))
    }

    @Test func speechRequestSendsOnlyTheTextAndVoice() {
        let expected: JSONValue = [
            "contents": [["role": "user", "parts": [["text": "Buonasera!"]]]],
            "generationConfig": [
                "responseModalities": ["AUDIO"],
                "speechConfig": ["voiceConfig": ["prebuiltVoiceConfig": ["voiceName": "Charon"]]],
            ],
        ]
        #expect(GeminiRequest.speech("Buonasera!", voiceName: "Charon") == expected)
    }

    @Test func endpointUsesTheGlobalProjectPath() throws {
        let endpoint = try #require(GeminiEndpoint(project: " 107211843390\n"))
        #expect(endpoint.streamURL(model: "gemini-4-argon").absoluteString
            == "https://aiplatform.googleapis.com/v1/projects/107211843390/locations/global/publishers/google/models/gemini-4-argon:streamGenerateContent?alt=sse")
        #expect(endpoint.url(model: "gemini-4-argon").absoluteString.hasSuffix("/models/gemini-4-argon:generateContent"))
        #expect(GeminiEndpoint(project: "my-project-1") != nil)
        #expect(GeminiEndpoint(project: "") == nil)
        #expect(GeminiEndpoint(project: "12 34") == nil)
        #expect(GeminiEndpoint(project: "projects/123") == nil)
    }

    // MARK: Streaming responses

    @Test func parsesStreamedTextAndSkipsThoughts() throws {
        var parser = GeminiStreamParser()
        #expect(try parser.feed(line: ": keep-alive").isEmpty)
        let first = try parser.feed(line: #"data: {"candidates": [{"content": {"role": "model", "parts": [{"text": "Planning", "thought": true}, {"text": "Buonasera!"}]}}]}"#)
        #expect(first == [.text("Buonasera!")])
        #expect(try parser.feed(line: "").isEmpty)
        let last = try parser.feed(line: #"data: {"candidates": [{"content": {"parts": [{"text": ""}]}, "finishReason": "STOP"}], "usageMetadata": {"promptTokenCount": 117, "candidatesTokenCount": 30}}"#)
        #expect(last == [.finished("STOP"), .usage(prompt: 117, output: 30, thoughts: 0)])
        #expect(try parser.finish().isEmpty)
    }

    @Test func parsesStreamedAudio() throws {
        var parser = GeminiStreamParser()
        let pcm = Data([0x01, 0x00, 0xFF, 0x7F])
        let line = #"data: {"candidates": [{"content": {"parts": [{"inlineData": {"mimeType": "audio/l16; rate=24000; channels=1", "data": ""# + pcm.base64EncodedString() + #""}}]}}]}"#
        #expect(try parser.feed(line: line) == [.audio(pcm, mimeType: "audio/l16; rate=24000; channels=1")])
    }

    @Test func putsAnEventSplitOverLinesBackTogether() throws {
        var parser = GeminiStreamParser()
        #expect(try parser.feed(line: #"data: {"candidates": [{"content": {"parts":"#).isEmpty)
        #expect(try parser.feed(line: #"data: [{"text": "Ciao"}]}}]}"#) == [.text("Ciao")])

        var broken = GeminiStreamParser()
        _ = try broken.feed(line: "data: {\"candidates\": [")
        #expect(throws: GeminiFailure.self) { try broken.finish() }
    }

    @Test func anErrorInTheStreamIsThrown() {
        var parser = GeminiStreamParser()
        let failure = #expect(throws: GeminiFailure.self) {
            try parser.feed(line: #"data: {"error": {"code": 429, "message": "Resource exhausted", "status": "RESOURCE_EXHAUSTED"}}"#)
        }
        #expect(failure?.kind == .rateLimited)
    }

    @Test func aBlockedPromptSaysSo() throws {
        var parser = GeminiStreamParser()
        let events = try parser.feed(line: #"data: {"promptFeedback": {"blockReason": "SAFETY"}}"#)
        #expect(events == [.blocked("SAFETY")])
    }

    // MARK: Failures

    static func failure(_ status: Int, _ json: String, key: String? = nil) -> GeminiFailure {
        GeminiFailure(status: status, body: Data(json.utf8), redacting: key)
    }

    @Test func refusedRequestsStopTheSession() {
        let unauthorized = Self.failure(401, #"{"error": {"code": 401, "message": "Request had invalid authentication credentials.", "status": "UNAUTHENTICATED"}}"#)
        #expect(unauthorized.stopsSession)
        #expect(unauthorized.message.contains("401"))

        let disabled = Self.failure(403, #"[{"error": {"code": 403, "message": "Agent Platform API has not been used in project 1 before or it is disabled.", "status": "PERMISSION_DENIED", "details": [{"@type": "type.googleapis.com/google.rpc.ErrorInfo", "reason": "SERVICE_DISABLED"}]}}]"#)
        #expect(disabled.stopsSession)
        #expect(disabled.reason == "SERVICE_DISABLED")
        #expect(disabled.message.contains("启用"))

        let missing = Self.failure(404, #"{"error": {"code": 404, "message": "Publisher Model was not found", "status": "NOT_FOUND"}}"#)
        #expect(missing.stopsSession)
        #expect(missing.message.contains("项目编号"))

        let suspended = Self.failure(403, #"{"error": {"code": 403, "message": "Consumer 'projects/1' has been suspended.", "status": "PERMISSION_DENIED"}}"#)
        #expect(suspended.stopsSession)
        #expect(suspended.message.contains("停用"))

        // Google answers an invalid key with 400, but it's still the key.
        let badKey = Self.failure(400, #"{"error": {"code": 400, "message": "API key not valid. Please pass a valid API key.", "status": "INVALID_ARGUMENT", "details": [{"reason": "API_KEY_INVALID"}]}}"#)
        #expect(badKey.stopsSession)
        #expect(badKey.message.contains("key 无效"))
    }

    @Test func otherFailuresLetTheLearnerTryAgain() {
        #expect(!Self.failure(429, #"{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED"}}"#).stopsSession)
        #expect(Self.failure(429, "{}").kind == .rateLimited)
        #expect(Self.failure(503, "<html>Service Unavailable</html>").kind == .server)
        #expect(Self.failure(400, #"{"error": {"code": 400, "message": "Invalid value at 'contents'", "status": "INVALID_ARGUMENT"}}"#).kind == .badRequest)
        #expect(!GeminiFailure.network("offline").stopsSession)
    }

    @Test func theKeyNeverEndsUpInAFailure() {
        let key = "AIzaSyExampleExampleExampleExample123"
        let echoed = Self.failure(400, #"{"error": {"code": 400, "message": "Key AIzaSyExampleExampleExampleExample123 is bad", "status": "INVALID_ARGUMENT"}}"#, key: key)
        #expect(!echoed.detail.contains(key))
        #expect(!echoed.description.contains(key))
        let plain = Self.failure(500, "oops \(key)", key: key)
        #expect(!plain.detail.contains(key))
    }

    // MARK: Daily cap

    @Test func dailyCapCountsTurnsAndStartsOverEachDay() throws {
        let monday = try #require(LocalDate("2030-03-04"))
        let tuesday = monday.adding(days: 1)
        var allowance = TurnAllowance(dailyLimit: 10)
        #expect(TurnAllowance.defaultLimit == 40)
        for _ in 1...10 {
            #expect(allowance.spend(on: monday))
        }
        #expect(!allowance.spend(on: monday))
        #expect(allowance.remaining(on: monday) == 0)
        #expect(allowance.used(on: monday) == 10)
        #expect(allowance.remaining(on: tuesday) == 10)
        #expect(allowance.spend(on: tuesday))
        #expect(allowance.used(on: tuesday) == 1)
        #expect(allowance.used(on: monday) == 0)
    }

    @Test func dailyCapStaysInRangeAndSurvivesOldFiles() throws {
        var allowance = TurnAllowance()
        allowance.setLimit(5000)
        #expect(allowance.dailyLimit == TurnAllowance.limits.upperBound)
        allowance.setLimit(0)
        #expect(allowance.dailyLimit == TurnAllowance.limits.lowerBound)

        let today = try #require(LocalDate("2030-03-04"))
        allowance.setLimit(20)
        allowance.spend(on: today)
        let decoded = try JSONDecoder().decode(TurnAllowance.self, from: JSONEncoder().encode(allowance))
        #expect(decoded == allowance)
        let empty = try JSONDecoder().decode(TurnAllowance.self, from: Data("{}".utf8))
        #expect(empty.dailyLimit == TurnAllowance.defaultLimit)
        #expect(empty.remaining(on: today) == TurnAllowance.defaultLimit)
    }

    // MARK: Feedback

    static let feedbackJSON = """
        {
          "summary": "点单很清楚，记得用 Lei。",
          "corrections": [
            {"said": "io volere pizza", "better": "Vorrei una pizza, per favore.", "zh": "我想要一个披萨。", "why": "volere 要变位，点单用 Vorrei。"},
            {"said": "quanto costa", "better": "Quanto costa?", "zh": "多少钱？", "why": "只差标点。"},
            {"said": "puoi ripetere", "better": "Può ripetere?", "zh": "您能再说一遍吗？", "why": "对陌生人用 Lei。"},
            {"said": "grazie mille", "better": "**Grazie mille!**", "zh": "非常感谢！", "why": "加个感叹号更热情。"},
            {"said": "ciao", "better": "Buonasera!", "zh": "晚上好！", "why": "对店员不说 ciao。"}
          ],
          "expression": {"it": "Da portare via, per favore.", "zh": "请打包带走。", "note": "外带时说。"}
        }
        """

    @Test func feedbackKeepsAtMostThreeRealCorrections() throws {
        let feedback = try RolePlayFeedback.parse(Self.feedbackJSON)
        #expect(feedback.summary == "点单很清楚，记得用 Lei。")
        // "Quanto costa?" and "Grazie mille!" only add punctuation or markdown: not corrections.
        #expect(feedback.corrections.map(\.better) == ["Vorrei una pizza, per favore.", "Può ripetere?", "Buonasera!"])
        #expect(feedback.expression?.it == "Da portare via, per favore.")
    }

    @Test func feedbackToleratesFencesAndGaps() throws {
        let fenced = "```json\n{\"summary\": \"不错\", \"corrections\": [{\"said\": \"x\", \"better\": \"\"}], \"expression\": {\"it\": \" \"}}\n```"
        let feedback = try RolePlayFeedback.parse(fenced)
        #expect(feedback.summary == "不错")
        #expect(feedback.corrections.isEmpty)
        #expect(feedback.expression == nil)
        #expect(throws: GeminiFailure.self) { try RolePlayFeedback.parse("Non è JSON") }
    }

    @Test func feedbackBecomesPracticePhrasesWithStableIDs() throws {
        let feedback = try RolePlayFeedback.parse(Self.feedbackJSON)
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        // The course already teaches "Può ripetere?".
        let taught: Set<String> = [PracticePhrase.key("Può ripetere?")]
        let phrases = feedback.practicePhrases(role: Self.pizzaiolo(), addedAt: now, taught: taught)
        #expect(phrases.map(\.it) == ["Vorrei una pizza, per favore.", "Buonasera!", "Da portare via, per favore."])
        #expect(phrases.map(\.source) == [.correction, .correction, .expression])
        #expect(phrases.allSatisfy { $0.scene == "pizzeria" && $0.unit == "C06" && $0.id.hasPrefix("RP-") })
        #expect(phrases[0].note == "volere 要变位，点单用 Vorrei。（你说的是：io volere pizza）")
        #expect(phrases[0].phrase.status == .draft)
        #expect(phrases[0].phrase.zh == "我想要一个披萨。")

        // Same words, different case and punctuation: the same phrase.
        #expect(PracticePhrase.id(for: "vorrei una pizza per favore") == phrases[0].id)
        #expect(PracticePhrase.id(for: "Vorrei due pizze.") != phrases[0].id)
        #expect(phrases[0].id.count == 3 + 16)
    }

    @Test func practicePhrasesBecomeNewCardsOnce() throws {
        let scheduler = ReviewScheduler(config: SchedulerConfig(enableFuzz: false))
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        var progress = StudyProgress()
        progress.completeLesson("L05", cards: [CardID(phraseID: "L05-01", kind: .listen)], scheduler: scheduler, at: now)
        let (reviewed, record) = try scheduler.review(progress.cards[0], grade: .good, at: now.addingTimeInterval(60))
        progress.apply(reviewed, record: record)

        let feedback = try RolePlayFeedback.parse(Self.feedbackJSON)
        let phrases = feedback.practicePhrases(role: Self.pizzaiolo(), addedAt: now, taught: [])
        let added = progress.addPractice(phrases, scheduler: scheduler, at: now)
        #expect(added.count == 4)
        #expect(progress.cards.count == 1 + 8)
        #expect(progress.cards.filter { $0.id.phraseID.hasPrefix("RP-") }.allSatisfy(\.isNew))
        // Adding cards doesn't touch the reviewed one or the log.
        #expect(progress.cards[0] == reviewed)
        #expect(progress.reviews.count == 1)

        // The same sentence from another session keeps its cards.
        #expect(progress.addPractice(phrases, scheduler: scheduler, at: now.addingTimeInterval(3600)).isEmpty)
        #expect(progress.cards.count == 9)
        #expect(progress.practicePhrase(phrases[0].id)?.it == "Vorrei una pizza, per favore.")

        progress.removePractice(phrases[0].id)
        #expect(progress.practicePhrase(phrases[0].id) == nil)
        #expect(progress.cards.count == 7)
        #expect(progress.reviews.count == 1)
    }

    @Test func practicePhrasesRoundTripAndOldFilesStillLoad() throws {
        let scheduler = ReviewScheduler(config: SchedulerConfig(enableFuzz: false))
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        var progress = StudyProgress()
        // Without practice phrases the file has no key for them, as before the role-play.
        #expect(!String(decoding: try ProgressStore.encode(progress), as: UTF8.self).contains("practicePhrases"))

        let phrase = PracticePhrase(it: "Vorrei una pizza.", zh: "我想要一个披萨。", note: nil, scene: "pizzeria",
                                    unit: "C06", source: .correction, addedAt: now)
        progress.addPractice([phrase], scheduler: scheduler, at: now)
        let restored = try ProgressStore.decode(ProgressStore.encode(progress))
        #expect(restored == progress)
        #expect(restored.practicePhrases == [phrase])

        let old = #"{"version": 1, "cards": [], "reviews": [], "completedUnits": {}, "challengeRuns": []}"#
        #expect(try ProgressStore.decode(Data(old.utf8)).practicePhrases.isEmpty)
        // Unreadable phrases are dropped rather than costing the rest of the record.
        let odd = #"{"version": 1, "cards": [], "reviews": [], "completedUnits": {"L01": "2030-03-01T08:00:00Z"}, "challengeRuns": [], "practicePhrases": [{"id": 5}]}"#
        let fromOdd = try ProgressStore.decode(Data(odd.utf8))
        #expect(fromOdd.practicePhrases.isEmpty)
        #expect(fromOdd.isCompleted("L01"))
    }

    // MARK: Content

    @Test func everyChallengeHasARoleWithAVoice() throws {
        let bundle = try ContentTests.loadRepositoryContent()
        let rolePlay = try #require(bundle.rolePlay)
        let challenges = bundle.course.units.filter { $0.kind == .challenge }.map(\.id)
        #expect(rolePlay.roles.map(\.unit) == challenges)
        #expect(!rolePlay.fillers.isEmpty)
        let audio = try #require(bundle.audio)
        for role in rolePlay.roles {
            #expect(audio.voiceName(for: role.voice) != nil, "\(role.unit)")
            for filler in rolePlay.fillers {
                #expect(audio.file(for: filler, speed: .normal, onlyIn: role.voice) != nil, "\(role.unit) \(filler)")
            }
        }
        #expect(audio.voiceName(for: "f1@1") == "Kore")
    }

    @Test func validatorChecksRoles() {
        let course = Course(
            version: 1,
            frames: [],
            scenes: [SceneTag(id: "bar", zh: "咖啡吧", neededAt: "first")],
            units: [CourseUnit(id: "C01", kind: .challenge, week: 1, title: "t", focus: "—", frames: [], scene: "bar", summary: "s")]
        )
        let role = RolePlayRole(unit: "C09", name: "Barista", zh: "", voice: "x9", scene: "boat", opens: true,
                                setting: "You run a bar.", task: "点咖啡。")
        let rolePlay = RolePlayContent(version: 1, fillers: [], roles: [role, role])
        let audio = AudioManifest(version: 1, voices: ["f1@1"], entries: [:], voiceNames: ["f1": "Kore"])
        let messages = ContentValidator.validate(ContentBundle(course: course, lessons: [], audio: audio, rolePlay: rolePlay))
            .map(\.message)
        #expect(messages.contains("more than one role for C09"))
        #expect(messages.contains("has no fillers"))
        #expect(messages.contains("role for C09, which is not a challenge in course.json"))
        #expect(messages.contains("role C09 uses unknown scene boat"))
        #expect(messages.contains("role C09 has empty text"))
        #expect(messages.contains("role C09 uses voice x9, which the audio manifest doesn't have"))
    }

    @Test func manifestVoiceNamesAreOptional() throws {
        let old = #"{"version": 1, "voices": ["f1@1"], "entries": {}}"#
        let manifest = try JSONDecoder().decode(AudioManifest.self, from: Data(old.utf8))
        #expect(manifest.voiceNames == nil)
        #expect(manifest.voiceName(for: "f1") == nil)
        #expect(manifest.profile(for: "f1") == "f1@1")
        #expect(manifest.profile(for: "f") == nil)
    }
}
