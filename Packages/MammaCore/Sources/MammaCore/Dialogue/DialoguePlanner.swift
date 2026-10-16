import Foundation

public struct KeyInfoQuestion: Hashable, Sendable {
    public let prompt: String
    public let options: [String]
    public let answer: String
}

/// One turn of a planned run: what the other person says, an optional key-information question
/// about it, and the learner's reply with its choices already shuffled.
public struct DialogueBeat: Hashable, Sendable, Identifiable {
    public let id: Int
    public let nodeID: String
    public let line: DialogueLine
    public let question: KeyInfoQuestion?
    public let reply: DialogueReply?
}

public enum DialoguePlanner {
    /// Lays out one run: the main nodes in order with `min…max` random follow-ups after
    /// `followUps.after`, a random variant of every line, and shuffled options and choices.
    public static func beats<G: RandomNumberGenerator>(for script: DialogueScript, using generator: inout G) -> [DialogueBeat] {
        var nodes: [DialogueNode] = []
        for node in script.nodes {
            nodes.append(node)
            if let followUps = script.followUps, followUps.after == node.id, !followUps.pool.isEmpty {
                let upper = Swift.max(0, Swift.min(followUps.max, followUps.pool.count))
                let lower = Swift.max(0, Swift.min(followUps.min, upper))
                let count = Int.random(in: lower...upper, using: &generator)
                nodes += followUps.pool.shuffled(using: &generator).prefix(count)
            }
        }

        var beats: [DialogueBeat] = []
        for node in nodes {
            guard let line = node.npc.randomElement(using: &generator) else { continue }
            var question: KeyInfoQuestion?
            if let prompt = node.question, let answer = line.answer {
                let options = ([answer] + (line.distractors ?? [])).shuffled(using: &generator)
                question = KeyInfoQuestion(prompt: prompt, options: options, answer: answer)
            }
            var reply: DialogueReply?
            if let original = node.reply {
                reply = DialogueReply(
                    intent: original.intent,
                    frame: original.frame,
                    choices: original.choices.shuffled(using: &generator)
                )
            }
            beats.append(DialogueBeat(id: beats.count, nodeID: node.id, line: line, question: question, reply: reply))
        }
        return beats
    }
}

/// How much help a reply hint gives; each step up counts as one more hint.
public enum ReplyHint: Int, CaseIterable, Comparable, Sendable {
    /// 中文意图: what you want to say, in Chinese.
    case intent = 1
    /// 句框: the sentence frame to use.
    case frame
    /// 整句: the right sentence is pointed out.
    case sentence

    public static func < (lhs: ReplyHint, rhs: ReplyHint) -> Bool { lhs.rawValue < rhs.rawValue }

    public var next: ReplyHint? { ReplyHint(rawValue: rawValue + 1) }
}

/// Scores a challenge run. 通关标准: every key-information question answered right, and at most
/// one hint (a translation of what they said, or any step of a reply hint). Wrong replies are
/// counted for feedback but don't fail the run; you try again, as you would in a shop.
public struct ChallengeTally: Hashable, Sendable {
    public private(set) var mistakes = 0
    public private(set) var hintsUsed = 0
    public private(set) var keyInfoAsked = 0
    public private(set) var keyInfoCorrect = 0

    public init() {}

    public var passed: Bool {
        keyInfoCorrect == keyInfoAsked && hintsUsed <= 1
    }

    @discardableResult
    public mutating func choose(_ choice: DialogueChoice) -> Bool {
        if !choice.correct { mistakes += 1 }
        return choice.correct
    }

    @discardableResult
    public mutating func answer(_ option: String, to question: KeyInfoQuestion) -> Bool {
        keyInfoAsked += 1
        let correct = option == question.answer
        if correct { keyInfoCorrect += 1 }
        return correct
    }

    public mutating func useHint() {
        hintsUsed += 1
    }

    public func run(unit: String, finishedAt: Date) -> ChallengeRun {
        ChallengeRun(
            unit: unit,
            finishedAt: finishedAt,
            passed: passed,
            mistakes: mistakes,
            hintsUsed: hintsUsed,
            keyInfoCorrect: keyInfoCorrect,
            keyInfoAsked: keyInfoAsked
        )
    }
}

/// SplitMix64: a small deterministic generator, so a run can be replayed exactly in tests.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
