import Foundation

/// Gemini 4 Argon takes only these; MINIMAL and a thinking_budget are rejected with HTTP 400.
public enum ThinkingLevel: String, Codable, Sendable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

/// The model that answers in the role-play. Argon is the default; Flash answers sooner.
public enum ReplyModel: String, Codable, Sendable, CaseIterable {
    case argon = "gemini-4-argon"
    case flash = "gemini-3.8-flash"
}

public enum GeminiModels {
    /// Writes the feedback card, whichever model answers in the role-play.
    public static let feedback = ReplyModel.argon.rawValue
    /// The same TTS model the bundled recordings were made with (tools/tts_voices.json).
    public static let speech = "gemini-3.8-flash-tts"
}

/// Agent Platform's global endpoint for one Google Cloud project. The path must carry the
/// project: without it requests are routed to asia-southeast1, where Argon answers 404.
public struct GeminiEndpoint: Hashable, Sendable {
    public let project: String

    /// Nil unless `project` looks like a project number (digits) or a project id.
    public init?(project: String) {
        let trimmed = project.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidProject(trimmed) else { return nil }
        self.project = trimmed
    }

    /// A project number ("107211843390") or a project id ("my-project-1").
    public static func isValidProject(_ text: String) -> Bool {
        guard let first = text.first, first.isASCII, first.isLetter || first.isNumber,
              (1...63).contains(text.count)
        else { return false }
        return text.allSatisfy { $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "-") }
    }

    /// `:streamGenerateContent?alt=sse`: one JSON response per server-sent event.
    public func streamURL(model: String) -> URL {
        URL(string: "\(base(model)):streamGenerateContent?alt=sse")!
    }

    public func url(model: String) -> URL {
        URL(string: "\(base(model)):generateContent")!
    }

    private func base(_ model: String) -> String {
        "https://aiplatform.googleapis.com/v1/projects/\(project)/locations/global/publishers/google/models/\(model)"
    }
}

/// Request bodies for :generateContent and :streamGenerateContent.
public enum GeminiRequest {
    /// A reply in the role-play. Thinking is LOW: the reply is one short line and every second counts.
    public static func reply(system: String, contents: [JSONValue], thinking: ThinkingLevel = .low) -> JSONValue {
        [
            "systemInstruction": ["parts": [["text": .string(system)]]],
            "contents": .array(contents),
            "generationConfig": [
                "thinkingConfig": ["thinkingLevel": .string(thinking.rawValue)],
                // Thinking counts towards the limit; a reply is about 40 tokens.
                "maxOutputTokens": 1024,
            ],
        ]
    }

    /// The feedback card, as JSON in `schema`. It isn't in a hurry, so it thinks more.
    public static func structured(system: String, prompt: String, schema: JSONValue,
                                  thinking: ThinkingLevel = .medium) -> JSONValue {
        [
            "systemInstruction": ["parts": [["text": .string(system)]]],
            "contents": [["role": "user", "parts": [["text": .string(prompt)]]]],
            "generationConfig": [
                "thinkingConfig": ["thinkingLevel": .string(thinking.rawValue)],
                "responseMimeType": "application/json",
                "responseSchema": schema,
                "maxOutputTokens": 8192,
            ],
        ]
    }

    /// Speech for one sentence in a prebuilt voice. Only the text is sent: style instructions get
    /// read aloud, and the TTS model doesn't take a system instruction.
    public static func speech(_ text: String, voiceName: String) -> JSONValue {
        [
            "contents": [["role": "user", "parts": [["text": .string(text)]]]],
            "generationConfig": [
                "responseModalities": ["AUDIO"],
                "speechConfig": ["voiceConfig": ["prebuiltVoiceConfig": ["voiceName": .string(voiceName)]]],
            ],
        ]
    }

    /// One turn of the conversation history.
    public static func content(role: String, text: String) -> JSONValue {
        ["role": .string(role), "parts": [["text": .string(text)]]]
    }
}
