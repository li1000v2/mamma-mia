import Foundation
import Testing
@testable import MammaCore

struct DialogueTests {
    static func cafe() throws -> DialogueScript {
        let bundle = try ContentTests.loadRepositoryContent()
        return try #require(bundle.dialogue(for: "C02"))
    }

    static func beats(_ script: DialogueScript, seed: UInt64) -> [DialogueBeat] {
        var generator = SeededGenerator(seed: seed)
        return DialoguePlanner.beats(for: script, using: &generator)
    }

    @Test func keepsTheMainLineAndAddsOneOrTwoFollowUps() throws {
        let script = try Self.cafe()
        for seed in UInt64(1)...20 {
            let beats = Self.beats(script, seed: seed)
            let ids = beats.map(\.nodeID)
            #expect(ids.first == "order")
            #expect(Array(ids.suffix(2)) == ["price", "receipt"])
            #expect((4...5).contains(beats.count))
            #expect(beats.last?.reply == nil)

            let price = try #require(beats.first { $0.nodeID == "price" })
            let question = try #require(price.question)
            #expect(question.answer == price.line.answer)
            #expect(question.options.contains(question.answer))
            #expect(question.options.count == 3)
        }
    }

    @Test func sameSeedReplaysTheSameRun() throws {
        let script = try Self.cafe()
        #expect(Self.beats(script, seed: 42) == Self.beats(script, seed: 42))
    }

    @Test func runsVary() throws {
        let script = try Self.cafe()
        let runs = Set((UInt64(1)...30).map { seed in
            Self.beats(script, seed: seed).map { "\($0.nodeID)|\($0.line.it)" }
        })
        #expect(runs.count > 3)
    }

    @Test func passingNeedsKeyInfoRightAndAtMostOneHint() {
        let question = KeyInfoQuestion(prompt: "要付多少钱？", options: ["3.50 €", "3.15 €"], answer: "3.50 €")
        var tally = ChallengeTally()
        tally.choose(DialogueChoice(it: "Ho un cappuccino.", correct: false, feedback: nil))
        tally.answer("3.50 €", to: question)
        tally.useHint()
        #expect(tally.passed)
        #expect(tally.mistakes == 1)

        tally.useHint()
        #expect(!tally.passed)

        var missed = ChallengeTally()
        missed.answer("3.15 €", to: question)
        let run = missed.run(unit: "C02", finishedAt: Date(timeIntervalSince1970: 0))
        #expect(!run.passed)
        #expect(run.keyInfoAsked == 1 && run.keyInfoCorrect == 0)
    }

    @Test func hintsEscalate() {
        #expect(ReplyHint.intent.next == .frame)
        #expect(ReplyHint.frame.next == .sentence)
        #expect(ReplyHint.sentence.next == nil)
    }

    @Test func validatorFlagsBrokenScripts() {
        let course = Course(
            version: 1,
            frames: [],
            scenes: [SceneTag(id: "bar", zh: "咖啡吧", neededAt: "first")],
            units: [CourseUnit(id: "C01", kind: .challenge, week: 1, title: "t", focus: "—", frames: [], scene: "bar", summary: "s")]
        )
        let broken = DialogueScript(
            unit: "L09",
            title: "t",
            goal: "g",
            speaker: "s",
            voice: nil,
            status: .draft,
            nodes: [DialogueNode(
                id: "a",
                npc: [DialogueLine(it: "Quanto?", zh: "多少？", answer: nil, distractors: nil)],
                question: "多少钱？",
                reply: DialogueReply(intent: "x", frame: "nope", choices: [DialogueChoice(it: "a", correct: false, feedback: nil)])
            )],
            followUps: DialogueFollowUps(after: "zzz", min: 2, max: 1, pool: [])
        )
        let messages = ContentValidator.validate(ContentBundle(course: course, lessons: [], dialogues: [broken], audio: nil))
            .map(\.message)

        #expect(messages.contains("L09 is not a challenge in course.json"))
        #expect(messages.contains("node a asks a question but a line has no answer or distractors"))
        #expect(messages.contains("node a has no correct choice"))
        #expect(messages.contains("node a needs at least two choices"))
        #expect(messages.contains("node a uses unknown frame nope"))
        #expect(messages.contains("followUps.after zzz is not a node"))
        #expect(messages.contains("followUps needs 0 ≤ min ≤ max ≤ pool size"))
    }
}
