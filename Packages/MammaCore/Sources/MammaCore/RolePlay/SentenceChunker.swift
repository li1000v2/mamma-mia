import Foundation

/// Cuts a streamed role-play reply into sentences for speech while it arrives, so the first
/// sentence can go to TTS before the rest is written.
///
/// A reply is the Italian line, then a line break and its Chinese translation (see
/// `RolePlayPrompt`). Only the Italian is spoken: it ends at the first line break, or at the first
/// Chinese character if the model puts the translation on the same line, and what is left of it
/// goes to speech right then rather than when the translation has finished.
///
/// A sentence ends at . ! ? or … followed by a space and something that isn't a lowercase letter
/// ("Allora… vediamo" is one sentence), so the chunker waits for the next word before cutting.
/// Abbreviations ("Sig.") and decimals ("3.50") don't end sentences, and a piece shorter than
/// `minimumLength` characters ("Sì.") is kept with the next one: TTS reads a lone word oddly.
public struct SentenceChunker: Sendable {
    public let minimumLength: Int
    private var pending = ""
    private var started = false
    private var ended = false

    public init(minimumLength: Int = 12) {
        self.minimumLength = minimumLength
    }

    /// Adds streamed text; returns the sentences it completed, ready for speech.
    public mutating func append(_ delta: String) -> [String] {
        guard !ended else { return [] }
        var reachedEnd = false
        for character in delta {
            if !started {
                if character.isWhitespace { continue }
                started = true
            }
            if character.isNewline || SpokenText.isCJK(character) {
                reachedEnd = true
                break
            }
            pending.append(character)
        }
        var sentences = completeSentences()
        if reachedEnd {
            sentences += finish()
        }
        return sentences
    }

    /// The end of the reply (or of its Italian part): whatever is left is the last sentence.
    public mutating func finish() -> [String] {
        ended = true
        let rest = SpokenText.clean(pending)
        pending = ""
        return rest.isEmpty ? [] : [rest]
    }

    /// Whether the Italian part is over: everything still to come is translation.
    public var isFinished: Bool { ended }

    private mutating func completeSentences() -> [String] {
        var sentences: [String] = []
        while let cut = nextCut() {
            let sentence = SpokenText.clean(String(pending[..<cut]))
            pending = String(pending[cut...])
            if !sentence.isEmpty { sentences.append(sentence) }
        }
        return sentences
    }

    /// The end of the first complete sentence in `pending` that is long enough, if any.
    private func nextCut() -> String.Index? {
        let text = pending
        var index = text.startIndex
        while index < text.endIndex {
            guard Self.terminators.contains(text[index]) else {
                index = text.index(after: index)
                continue
            }
            // A run of terminators and closing quotes ends together: "?!", "...", "!»".
            var end = text.index(after: index)
            while end < text.endIndex, Self.terminators.contains(text[end]) || Self.closers.contains(text[end]) {
                end = text.index(after: end)
            }
            guard end < text.endIndex else { return nil }
            // "3.50", "www.": not followed by a space, so not the end of a sentence.
            guard text[end].isWhitespace else {
                index = end
                continue
            }
            var next = end
            while next < text.endIndex, text[next].isWhitespace {
                next = text.index(after: next)
            }
            guard next < text.endIndex else { return nil } // wait for the next word
            let long = SpokenText.clean(String(text[..<end])).count >= minimumLength
            if long, !text[next].isLowercase, !endsWithAbbreviation(text[..<index]) {
                return end
            }
            index = next
        }
        return nil
    }

    private func endsWithAbbreviation(_ text: Substring) -> Bool {
        let word = String(text.reversed().prefix { $0.isLetter }.reversed())
        return Self.abbreviations.contains(word.lowercased())
    }

    private static let terminators: Set<Character> = [".", "!", "?", "…"]
    private static let closers: Set<Character> = ["\"", "'", "»", "”", "’", ")"]
    private static let abbreviations: Set<String> = [
        "sig", "sigg", "dott", "prof", "ecc", "es", "tel", "n", "nr", "pag", "ca", "avv", "ing", "dr",
    ]
}

/// The two lines of a role-play reply: what the role says, and its Chinese translation.
public struct RolePlayReply: Hashable, Sendable {
    /// Exactly the text that is spoken: what the chunker hands to speech, joined up.
    public let italian: String
    public let chinese: String?

    public init(raw: String) {
        var chunker = SentenceChunker(minimumLength: 0)
        italian = (chunker.append(raw) + chunker.finish()).joined(separator: " ")
        chinese = Self.translation(in: raw)
    }

    /// The translation: from the first Chinese character when the first line has one, otherwise
    /// the lines after it, starting with the first that has Chinese in it.
    static func translation(in raw: String) -> String? {
        let lines = raw.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard let first = lines.first else { return nil }
        var parts: [String]
        if let start = first.firstIndex(where: SpokenText.isCJK) {
            parts = [String(first[start...])] + lines.dropFirst()
        } else {
            parts = Array(lines.dropFirst().drop { !$0.contains(where: SpokenText.isCJK) })
        }
        guard !parts.isEmpty else { return nil }
        var text = parts.joined(separator: " ")
        for label in ["中文：", "中文:", "ZH:", "ZH："] where text.hasPrefix(label) {
            text = String(text.dropFirst(label.count))
        }
        text = text.trimmingCharacters(in: CharacterSet(charactersIn: "()（） ").union(.whitespaces))
        return text.isEmpty ? nil : text
    }
}

/// Clean-up shared by the chunker and the transcript.
enum SpokenText {
    /// Han, kana and full-width punctuation: the translation has started.
    static func isCJK(_ character: Character) -> Bool {
        character.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3000...0x30FF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF, 0xFF00...0xFFEF: true
            default: false
            }
        }
    }

    /// Drops what speech shouldn't read: markdown marks, emoji, an "IT:" label, the bracket that
    /// opened a same-line translation; collapses spaces.
    static func clean(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            if markup.contains(scalar) || isEmoji(scalar) { continue }
            result.unicodeScalars.append(scalar)
        }
        var words = result.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        for label in ["IT:", "Italiano:", "Italian:"] where words.hasPrefix(label) {
            words = words.dropFirst(label.count).trimmingCharacters(in: .whitespaces)
        }
        while let last = words.last, "([-–—/|:".contains(last) {
            words = words.dropLast().trimmingCharacters(in: .whitespaces)
        }
        return words
    }

    private static let markup: Set<Unicode.Scalar> = ["*", "_", "#", "`", "~"]

    private static func isEmoji(_ scalar: Unicode.Scalar) -> Bool {
        if scalar.value == 0x200D || scalar.value == 0xFE0F { return true } // joiner, emoji style
        if scalar.value >= 0x1F000 { return true }
        return scalar.properties.isEmojiPresentation
    }
}
