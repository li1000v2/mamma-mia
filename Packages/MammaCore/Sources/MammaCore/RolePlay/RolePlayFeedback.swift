import Foundation

/// The card after a role-play: a short summary, at most three corrections and one new expression.
/// The corrected sentences and the expression become practice phrases with review cards.
public struct RolePlayFeedback: Codable, Hashable, Sendable {
    public struct Correction: Codable, Hashable, Sendable {
        /// What the learner said (as recognized).
        public let said: String
        /// A natural, correct sentence for what they meant.
        public let better: String
        public let zh: String
        /// Why, in Chinese.
        public let why: String
    }

    public struct Expression: Codable, Hashable, Sendable {
        public let it: String
        public let zh: String
        /// When to use it, in Chinese.
        public let note: String
    }

    public static let maxCorrections = 3

    public let summary: String
    public let corrections: [Correction]
    public let expression: Expression?

    /// Reads the model's JSON, keeping only what the card can show: corrections that change
    /// something (not just accents or punctuation), at most three, and an expression with text.
    public static func parse(_ text: String) throws -> RolePlayFeedback {
        var body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.hasPrefix("```") {
            body = body.split(separator: "\n", omittingEmptySubsequences: false).dropFirst()
                .joined(separator: "\n")
            if let fence = body.range(of: "```", options: .backwards) {
                body = String(body[..<fence.lowerBound])
            }
        }
        let raw: Raw
        do {
            raw = try JSONDecoder().decode(Raw.self, from: Data(body.utf8))
        } catch {
            throw GeminiFailure.malformed("feedback isn't JSON: \(error)")
        }

        let corrections = (raw.corrections ?? []).compactMap { item -> Correction? in
            let said = Self.trimmed(item.said)
            let better = SpokenText.clean(Self.trimmed(item.better))
            guard !better.isEmpty, Self.fold(better) != Self.fold(said) else { return nil }
            return Correction(said: said, better: better, zh: Self.trimmed(item.zh), why: Self.trimmed(item.why))
        }
        var expression: Expression?
        if let item = raw.expression {
            let it = SpokenText.clean(Self.trimmed(item.it))
            if !it.isEmpty {
                expression = Expression(it: it, zh: Self.trimmed(item.zh), note: Self.trimmed(item.note))
            }
        }
        return RolePlayFeedback(
            summary: Self.trimmed(raw.summary),
            corrections: Array(corrections.prefix(maxCorrections)),
            expression: expression
        )
    }

    /// The sentences to review: each correction's better sentence and the expression, skipping
    /// any the course already teaches (`taught` holds `PracticePhrase.key` of every lesson phrase).
    public func practicePhrases(role: RolePlayRole, addedAt: Date, taught: Set<String>) -> [PracticePhrase] {
        var phrases: [PracticePhrase] = []
        var seen = taught
        func add(_ it: String, zh: String, note: String?, source: PracticePhrase.Source) {
            guard seen.insert(PracticePhrase.key(it)).inserted else { return }
            phrases.append(PracticePhrase(it: it, zh: zh, note: note, scene: role.scene, unit: role.unit,
                                          source: source, addedAt: addedAt))
        }
        for correction in corrections {
            let note = correction.why.isEmpty ? "你说的是：\(correction.said)" : "\(correction.why)（你说的是：\(correction.said)）"
            add(correction.better, zh: correction.zh, note: note, source: .correction)
        }
        if let expression {
            add(expression.it, zh: expression.zh, note: expression.note.isEmpty ? nil : expression.note, source: .expression)
        }
        return phrases
    }

    private struct Raw: Decodable {
        struct Item: Decodable {
            let said: String?
            let better: String?
            let zh: String?
            let why: String?
        }

        struct NewExpression: Decodable {
            let it: String?
            let zh: String?
            let note: String?
        }

        let summary: String?
        let corrections: [Item]?
        let expression: NewExpression?
    }

    private static func trimmed(_ text: String?) -> String {
        (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func fold(_ text: String) -> String {
        PracticePhrase.key(text)
    }
}

/// An Italian sentence learned outside the lessons — a correction or a new expression from a
/// role-play — reviewed with the same two cards as a lesson phrase. Kept in the progress file,
/// so backups have it.
public struct PracticePhrase: Codable, Hashable, Sendable, Identifiable {
    public enum Source: String, Codable, Sendable {
        case correction, expression
    }

    /// "RP-" and a hash of the words, so the same sentence from two sessions is one phrase.
    public let id: String
    public let it: String
    public let zh: String
    public let note: String?
    public let scene: String
    /// The challenge whose role-play it came from.
    public let unit: String
    public let source: Source
    public let addedAt: Date

    public init(it: String, zh: String, note: String?, scene: String, unit: String, source: Source, addedAt: Date) {
        id = Self.id(for: it)
        self.it = it
        self.zh = zh
        self.note = note
        self.scene = scene
        self.unit = unit
        self.source = source
        self.addedAt = addedAt
    }

    public static let idPrefix = "RP-"

    public static func id(for text: String) -> String {
        let hash = AudioManifest.stableHash(key(text))
        let hex = String(hash, radix: 16)
        return idPrefix + String(repeating: "0", count: 16 - hex.count) + hex
    }

    /// The words without case, accents or punctuation: two sentences with the same key are the same phrase.
    public static func key(_ text: String) -> String {
        SpokenSentence(text).words.map(\.key).joined(separator: " ")
    }

    /// As a phrase for the review screen. Not cross-checked, so it stays a draft.
    public var phrase: Phrase {
        Phrase(id: id, it: it, zh: zh, frame: nil, scene: scene, status: .draft, note: note)
    }
}
