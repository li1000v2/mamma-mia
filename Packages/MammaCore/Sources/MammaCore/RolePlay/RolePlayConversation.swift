import Foundation

/// One line of a role-play, as shown and as sent back to the model.
public struct RolePlayLine: Hashable, Sendable, Identifiable {
    public enum Speaker: String, Hashable, Sendable {
        case learner, role
    }

    public let id: Int
    public let speaker: Speaker
    /// What was said in Italian: the recognized words for the learner, the spoken line for the role.
    public let text: String
    /// The role's line in Chinese, when the model gave one.
    public let translation: String?
    /// The role's reply as the model wrote it, both lines; sent back as history so the model
    /// keeps answering in that shape.
    let raw: String?
}

/// A role-play session: the lines so far and what to send for the next reply or the feedback.
/// A session ends after `turnsPerSession` learner turns, or earlier when the learner ends it.
public struct RolePlayConversation: Hashable, Sendable {
    public static let turnsPerSession = 20

    public let role: RolePlayRole
    public private(set) var lines: [RolePlayLine] = []

    public init(role: RolePlayRole) {
        self.role = role
    }

    public var learnerTurns: Int {
        lines.filter { $0.speaker == .learner }.count
    }

    /// No more learner turns in this session.
    public var isFull: Bool {
        learnerTurns >= Self.turnsPerSession
    }

    /// The role opens and hasn't yet.
    public var needsOpening: Bool {
        role.opens && lines.isEmpty
    }

    /// The last learner line still waits for a reply (the request failed or was cut off).
    public var awaitsReply: Bool {
        lines.last?.speaker == .learner
    }

    /// Whether there's anything for the feedback card to look at.
    public var hasLearnerLines: Bool {
        learnerTurns > 0
    }

    public mutating func addLearner(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        lines.append(RolePlayLine(id: lines.count, speaker: .learner, text: text, translation: nil, raw: nil))
    }

    /// Adds the role's reply from the model's raw text; nil when it had nothing to say out loud.
    @discardableResult
    public mutating func addRole(raw: String) -> RolePlayLine? {
        let reply = RolePlayReply(raw: raw)
        guard !reply.italian.isEmpty else { return nil }
        let line = RolePlayLine(id: lines.count, speaker: .role, text: reply.italian, translation: reply.chinese,
                                raw: raw.trimmingCharacters(in: .whitespacesAndNewlines))
        lines.append(line)
        return line
    }

    /// The history for the next reply. It starts with the user (an opening cue when the role
    /// speaks first) and alternates: learner lines in a row, left by a failed request, are sent
    /// as one turn.
    public func contents() -> [JSONValue] {
        var turns: [(role: String, text: String)] = []
        if role.opens {
            turns.append(("user", RolePlayPrompt.openingCue))
        }
        for line in lines {
            let speaker = line.speaker == .learner ? "user" : "model"
            let text = line.raw ?? line.text
            if let last = turns.last, last.role == speaker {
                turns[turns.count - 1].text += "\n" + text
            } else {
                turns.append((speaker, text))
            }
        }
        return turns.map { GeminiRequest.content(role: $0.role, text: $0.text) }
    }

    /// The request for the role's next line: the opening, or the answer to the learner.
    public func replyRequest(thinking: ThinkingLevel = .low) -> JSONValue {
        GeminiRequest.reply(system: RolePlayPrompt.system(for: role), contents: contents(), thinking: thinking)
    }

    /// The request for the feedback card, once the session is over.
    public func feedbackRequest(thinking: ThinkingLevel = .medium) -> JSONValue {
        GeminiRequest.structured(
            system: RolePlayPrompt.feedbackSystem,
            prompt: RolePlayPrompt.feedbackPrompt(role: role, lines: lines),
            schema: RolePlayPrompt.feedbackSchema,
            thinking: thinking
        )
    }
}
