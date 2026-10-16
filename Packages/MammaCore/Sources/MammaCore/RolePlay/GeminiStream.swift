import Foundation

/// What one server-sent event of :streamGenerateContent carries.
public enum GeminiStreamEvent: Hashable, Sendable {
    /// Answer text (thought summaries are left out).
    case text(String)
    /// Raw audio from the TTS model: 16-bit little-endian PCM, whatever "audio/l16" suggests.
    case audio(Data, mimeType: String?)
    /// The model stopped: "STOP" normally, "MAX_TOKENS", "SAFETY"…
    case finished(String)
    /// The prompt was refused before any answer ("SAFETY", "PROHIBITED_CONTENT"…).
    case blocked(String)
    case usage(prompt: Int, output: Int, thoughts: Int)
}

/// Reads the lines of a :streamGenerateContent?alt=sse response. Each event is a "data: {json}"
/// line; an event split over several data lines is put back together, and an error object in the
/// stream (rate limit hit mid-answer) is thrown as a `GeminiFailure`.
public struct GeminiStreamParser: Sendable {
    private var pending = ""

    public init() {}

    public mutating func feed(line: String) throws -> [GeminiStreamEvent] {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return try flush()
        }
        guard trimmed.hasPrefix("data:") else { return [] }
        let payload = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
        pending = pending.isEmpty ? payload : pending + "\n" + payload
        // Usually the whole JSON is on one line: parse it now rather than wait for the blank line.
        guard let data = pending.data(using: .utf8),
              let response = try? JSONDecoder().decode(GeminiResponse.self, from: data)
        else { return [] }
        pending = ""
        return try response.events()
    }

    /// Call at the end of the stream; an unfinished event there is a broken response.
    public mutating func finish() throws -> [GeminiStreamEvent] {
        try flush()
    }

    private mutating func flush() throws -> [GeminiStreamEvent] {
        guard !pending.isEmpty else { return [] }
        defer { pending = "" }
        guard let data = pending.data(using: .utf8),
              let response = try? JSONDecoder().decode(GeminiResponse.self, from: data)
        else {
            // Only the size: the event is the conversation, which stays out of the log.
            throw GeminiFailure.malformed("unreadable event of \(pending.count) characters")
        }
        return try response.events()
    }
}

/// The parts of a generateContent response the app uses.
public struct GeminiResponse: Decodable, Sendable {
    struct Candidate: Decodable, Sendable {
        let content: Content?
        let finishReason: String?
    }

    struct Content: Decodable, Sendable {
        let parts: [Part]?
    }

    struct Part: Decodable, Sendable {
        let text: String?
        let thought: Bool?
        let inlineData: InlineData?
    }

    struct InlineData: Decodable, Sendable {
        let mimeType: String?
        let data: String
    }

    struct PromptFeedback: Decodable, Sendable {
        let blockReason: String?
    }

    struct Usage: Decodable, Sendable {
        let promptTokenCount: Int?
        let candidatesTokenCount: Int?
        let thoughtsTokenCount: Int?
    }

    let candidates: [Candidate]?
    let promptFeedback: PromptFeedback?
    let usageMetadata: Usage?
    let error: GeminiErrorBody?

    public func events() throws -> [GeminiStreamEvent] {
        if let error {
            throw GeminiFailure(status: error.code ?? 0, error: error)
        }
        var events: [GeminiStreamEvent] = []
        if let reason = promptFeedback?.blockReason {
            events.append(.blocked(reason))
        }
        for candidate in candidates ?? [] {
            for part in candidate.content?.parts ?? [] where part.thought != true {
                if let inline = part.inlineData, let audio = Data(base64Encoded: inline.data) {
                    events.append(.audio(audio, mimeType: inline.mimeType))
                } else if let text = part.text, !text.isEmpty {
                    events.append(.text(text))
                }
            }
            if let reason = candidate.finishReason {
                events.append(.finished(reason))
            }
        }
        if let usage = usageMetadata, candidates?.contains(where: { $0.finishReason != nil }) == true {
            events.append(.usage(prompt: usage.promptTokenCount ?? 0, output: usage.candidatesTokenCount ?? 0,
                                 thoughts: usage.thoughtsTokenCount ?? 0))
        }
        return events
    }

    /// The answer text of a whole (non-streamed) response, without thought summaries.
    public var text: String {
        (candidates?.first?.content?.parts ?? [])
            .filter { $0.thought != true }
            .compactMap(\.text)
            .joined()
    }
}

/// Google's error object: {"error": {"code": 403, "message": "…", "status": "PERMISSION_DENIED",
/// "details": [{"reason": "SERVICE_DISABLED", …}]}}.
public struct GeminiErrorBody: Decodable, Hashable, Sendable {
    struct Detail: Decodable, Hashable, Sendable {
        let reason: String?
    }

    let code: Int?
    let message: String?
    let status: String?
    let details: [Detail]?

    var reasons: [String] { (details ?? []).compactMap(\.reason) }

    /// An error response body: an object, or for streamed requests an array of one.
    static func parse(_ body: Data) -> GeminiErrorBody? {
        struct Wrapper: Decodable {
            let error: GeminiErrorBody
        }
        if let wrapper = try? JSONDecoder().decode(Wrapper.self, from: body) {
            return wrapper.error
        }
        return (try? JSONDecoder().decode([Wrapper].self, from: body))?.first?.error
    }
}
