import Foundation

/// Something the other person says. A node lists several variants and each run picks one, so the
/// learner has to listen instead of remembering the script. When the node asks a key-information
/// question (price, time, platform), each variant carries its own answer and distractors.
public struct DialogueLine: Codable, Hashable, Sendable {
    public let it: String
    public let zh: String
    public let answer: String?
    public let distractors: [String]?
}

public struct DialogueChoice: Codable, Hashable, Sendable {
    public let it: String
    public let correct: Bool
    /// Why a wrong choice is wrong, in Chinese.
    public let feedback: String?
}

/// The learner's turn. Hints escalate from the Chinese intent to the frame to the whole sentence.
public struct DialogueReply: Codable, Hashable, Sendable {
    public let intent: String
    public let frame: String?
    public let choices: [DialogueChoice]
}

public struct DialogueNode: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let npc: [DialogueLine]
    /// Key-information question asked about the line, e.g. "要付多少钱？".
    public let question: String?
    /// Nil when the node only closes the conversation.
    public let reply: DialogueReply?
}

/// Random follow-up questions ("Al banco o al tavolo?") inserted after one node, so no two runs
/// are the same.
public struct DialogueFollowUps: Codable, Hashable, Sendable {
    public let after: String
    public let min: Int
    public let max: Int
    public let pool: [DialogueNode]
}

/// Content/dialogues/<challenge>.json: an offline scripted conversation for one challenge.
public struct DialogueScript: Codable, Sendable, Identifiable {
    public let unit: String
    public let title: String
    /// What the learner has to get done, in Chinese.
    public let goal: String
    /// Role name of the other person, e.g. "Cassiere".
    public let speaker: String
    /// Voice id from the audio manifest ("f1", "m1") so the role keeps one voice throughout.
    public let voice: String?
    public let status: ReviewStatus
    /// The main conversation in order.
    public let nodes: [DialogueNode]
    public let followUps: DialogueFollowUps?

    public var id: String { unit }
}
