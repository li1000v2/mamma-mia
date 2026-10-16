import Foundation

/// The other person in the online role-play of one challenge: who they are, for the model, and
/// what the learner tries to get done, for the learner.
public struct RolePlayRole: Codable, Hashable, Sendable, Identifiable {
    /// The challenge this role belongs to (C01…C10).
    public let unit: String
    /// The role's name as shown, in Italian: "Pizzaiolo".
    public let name: String
    /// Who it is, in Chinese: "那不勒斯披萨店的师傅".
    public let zh: String
    /// Voice id from the audio manifest ("f1", "m1"): the live voice and the fillers use it.
    public let voice: String
    /// The scene the phrases from this role-play's feedback are filed under.
    public let scene: String
    /// Whether the role speaks first (a shop counter) or waits for the learner (a passer-by).
    public let opens: Bool
    /// Who the role is and what happens, in English, for the model.
    public let setting: String
    /// What the learner tries to do, in Chinese.
    public let task: String

    public var id: String { unit }
}

/// Content/roleplay.json: one role per challenge for the online role-play, and the fillers played
/// the moment the learner stops speaking, while the reply is on its way.
public struct RolePlayContent: Codable, Sendable {
    public let version: Int
    /// Hesitation words ("Allora…") with pre-generated audio in every voice, so the wait for the
    /// reply starts with the role's own voice instead of silence.
    public let fillers: [String]
    public let roles: [RolePlayRole]

    public func role(for unit: String) -> RolePlayRole? {
        roles.first { $0.unit == unit }
    }
}
