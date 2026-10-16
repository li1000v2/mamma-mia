import Foundation

/// Lines up what the phone's offline recognizer heard with the sentence the learner meant to say,
/// word by word. It answers "would the other person understand?", not "how good was the accent?":
/// a target word the recognizer didn't pick up is one the listener may not catch either.
public struct SpeechCheck: Hashable, Sendable {
    public struct Word: Hashable, Sendable {
        /// As written in the target sentence.
        public let text: String
        /// Spaces and punctuation after it in the target sentence.
        public let trailing: String
        public let heard: Bool
        /// A similar word the recognizer heard in its place ("scusa" for "scusi"), if any.
        public let heardAs: String?
    }

    public enum Verdict: Sendable {
        /// Every word was recognized.
        case clear
        /// At least 60% of the words were recognized.
        case mostly
        case unclear
        /// Nothing was recognized at all.
        case silent
    }

    /// Text before the first word of the target.
    public let leading: String
    public let words: [Word]
    public let transcript: String
    /// Words in the transcript, whether or not they belong to the target.
    public let heardWordCount: Int

    public init(target: String, transcript: String) {
        let sentence = SpokenSentence(target)
        let heard = SpokenSentence(transcript).wordsWithAmountsSpelledOut
        self.init(leading: sentence.leading, target: sentence.words, heard: heard, transcript: transcript)
    }

    init(leading: String, target: [SpokenWord], heard: [SpokenWord], transcript: String) {
        self.leading = leading
        self.transcript = transcript
        heardWordCount = heard.count
        let alignment = Self.align(target, heard)
        words = zip(target, alignment).map { word, link in
            switch link {
            case .matched:
                Word(text: word.text, trailing: word.trailing, heard: true, heardAs: nil)
            case .substituted(let index):
                Word(text: word.text, trailing: word.trailing, heard: false, heardAs: heard[index].text)
            case .missing:
                Word(text: word.text, trailing: word.trailing, heard: false, heardAs: nil)
            }
        }
    }

    public var missed: [Word] { words.filter { !$0.heard } }

    /// Share of the target's words that were recognized.
    public var coverage: Double {
        words.isEmpty ? 0 : Double(words.count - missed.count) / Double(words.count)
    }

    public var verdict: Verdict {
        if heardWordCount == 0 { return .silent }
        if missed.isEmpty { return .clear }
        return coverage >= 0.6 ? .mostly : .unclear
    }

    // MARK: Alignment

    enum Link: Equatable {
        case matched(Int)
        /// Lined up with a different but similar heard word.
        case substituted(Int)
        case missing
    }

    /// Word-level edit distance between target and heard. A substitution costs less the more alike
    /// the two words are spelled, so a near miss is paired up (and reported as "heard as …") while
    /// an unrelated word is treated as missing. Recognizers sometimes reorder words ("1,20 €" for
    /// "un euro e venti"), so target words still missing afterwards are matched to any unused
    /// heard word that is the same.
    static func align(_ target: [SpokenWord], _ heard: [SpokenWord]) -> [Link] {
        let n = target.count, m = heard.count
        guard n > 0 else { return [] }
        let gap = 10
        func substitution(_ i: Int, _ j: Int) -> Int {
            // 11 for an almost identical spelling up to 15 for half the letters; below that the
            // words aren't alike, and pairing them costs the same as two gaps.
            let similarity = target[i].similarity(to: heard[j])
            guard similarity >= 0.5 else { return 2 * gap }
            return 2 * gap - min(9, Int((similarity * 10).rounded()))
        }

        var cost = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { cost[i][0] = i * gap }
        for j in 0...m { cost[0][j] = j * gap }
        if m > 0 {
            for i in 1...n {
                for j in 1...m {
                    let diagonal = target[i - 1].matches(heard[j - 1]) ? 0 : substitution(i - 1, j - 1)
                    cost[i][j] = min(cost[i - 1][j - 1] + diagonal, cost[i - 1][j] + gap, cost[i][j - 1] + gap)
                }
            }
        }

        var links = Array(repeating: Link.missing, count: n)
        var i = n, j = m
        while i > 0, j > 0 {
            if target[i - 1].matches(heard[j - 1]), cost[i][j] == cost[i - 1][j - 1] {
                links[i - 1] = .matched(j - 1)
                i -= 1
                j -= 1
            } else if !target[i - 1].matches(heard[j - 1]), substitution(i - 1, j - 1) < 2 * gap,
                      cost[i][j] == cost[i - 1][j - 1] + substitution(i - 1, j - 1) {
                links[i - 1] = .substituted(j - 1)
                i -= 1
                j -= 1
            } else if cost[i][j] == cost[i - 1][j] + gap {
                i -= 1
            } else {
                j -= 1
            }
        }

        var used = Set(links.compactMap { link -> Int? in
            if case .matched(let index) = link { index } else { nil }
        })
        for index in links.indices {
            if case .matched = links[index] { continue }
            if let other = heard.indices.first(where: { !used.contains($0) && target[index].matches(heard[$0]) }) {
                links[index] = .matched(other)
                used.insert(other)
            }
        }
        for index in links.indices {
            if case .substituted(let other) = links[index], used.contains(other) {
                links[index] = .missing
            }
        }
        return links
    }
}

/// Picks the scripted reply a spoken answer corresponds to, by each option's words.
public enum ReplyMatcher {
    /// The index of the choice that `transcript` says, or nil when no single choice fits; the
    /// learner then taps one instead.
    ///
    /// A choice fits when at least half of its words were heard and the transcript has none of the
    /// words that only other choices use: "Non ho capito" rules out "Non capito", because "ho" is
    /// a keyword of the other option. When several fit (one choice's words are a subset of
    /// another's), the one heard in full wins: "Non capito" is "Non capito", not a cut-short
    /// "Scusi, non ho capito".
    public static func match(_ transcript: String, choices: [String]) -> Int? {
        let heard = SpokenSentence(transcript).wordsWithAmountsSpelledOut
        guard !heard.isEmpty else { return nil }
        let options = choices.map { SpokenSentence($0).words }

        var fitting: [(index: Int, complete: Bool)] = []
        for (index, words) in options.enumerated() where !words.isEmpty {
            let check = SpeechCheck(leading: "", target: words, heard: heard, transcript: transcript)
            guard check.coverage >= 0.5 else { continue }
            let others = options.enumerated().filter { $0.offset != index }.flatMap(\.element)
            let saysAnotherOption = heard.contains { word in
                !words.contains { $0.matches(word) } && others.contains { $0.matches(word) }
            }
            if !saysAnotherOption {
                fitting.append((index, check.missed.isEmpty))
            }
        }

        if fitting.count == 1 { return fitting[0].index }
        let complete = fitting.filter(\.complete)
        return complete.count == 1 ? complete[0].index : nil
    }
}
