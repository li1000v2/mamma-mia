import Foundation

/// One word of a sentence, as written and in the form used to compare it with what a recognizer
/// heard. Case, punctuation and accents don't count: "È" and "e" are the same word here, because
/// the question is whether the listener understood, not how it was spelled.
public struct SpokenWord: Hashable, Sendable {
    /// As written, including an elision apostrophe: "Quant'", "è", "€".
    public let text: String
    /// What follows the word up to the next one: spaces and punctuation.
    public let trailing: String
    /// Lowercased, without accents or apostrophes: "quant", "e", "euro".
    public let key: String
    /// Written with an elision apostrophe ("l'", "dov'", "po'"), so it stands for any word that
    /// starts the same way: "dov'" matches "dove", "l'" matches "la".
    public let elided: Bool
    /// The value of a numeral or an Italian number word: "12", "dodici", "un".
    public let number: Int?

    init(text: String, trailing: String, elided: Bool = false) {
        self.text = text
        self.trailing = trailing
        self.elided = elided
        let key = text == "€" ? "euro" : SpokenWord.fold(text)
        self.key = key
        number = SpokenWord.value(of: key)
    }

    /// Whether a listener would take the two as the same word.
    public func matches(_ other: SpokenWord) -> Bool {
        if key == other.key { return true }
        if let number, number == other.number { return true }
        if elided, !key.isEmpty, other.key.hasPrefix(key) { return true }
        if other.elided, !other.key.isEmpty, key.hasPrefix(other.key) { return true }
        return false
    }

    /// 0…1 by spelling, for telling a near miss ("scusa" for "scusi") from an unrelated word.
    func similarity(to other: SpokenWord) -> Double {
        let a = Array(key), b = Array(other.key)
        let longest = max(a.count, b.count)
        guard longest > 0 else { return 1 }
        return 1 - Double(Self.editDistance(a, b)) / Double(longest)
    }

    // MARK: Normalization

    private static let accents: [Character: Character] = [
        "à": "a", "á": "a", "â": "a", "ä": "a", "ã": "a",
        "è": "e", "é": "e", "ê": "e", "ë": "e",
        "ì": "i", "í": "i", "î": "i", "ï": "i",
        "ò": "o", "ó": "o", "ô": "o", "ö": "o", "õ": "o",
        "ù": "u", "ú": "u", "û": "u", "ü": "u",
        "ç": "c", "ñ": "n",
    ]

    /// Lowercases and drops accents and apostrophes. Precomposed accented letters are mapped by
    /// table and combining marks are dropped, so the result is the same on every platform.
    static func fold(_ text: String) -> String {
        var result = ""
        for character in text.lowercased() {
            if let plain = accents[character] {
                result.append(plain)
                continue
            }
            for scalar in character.unicodeScalars {
                if (0x300...0x36F).contains(scalar.value) || SpokenSentence.apostrophes.contains(Character(scalar)) {
                    continue
                }
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    private static let numberWords: [String: Int] = {
        var words: [String: Int] = [
            "zero": 0, "un": 1, "uno": 1, "una": 1, "due": 2, "tre": 3, "quattro": 4, "cinque": 5,
            "sei": 6, "sette": 7, "otto": 8, "nove": 9, "dieci": 10, "undici": 11, "dodici": 12,
            "tredici": 13, "quattordici": 14, "quindici": 15, "sedici": 16, "diciassette": 17,
            "diciotto": 18, "diciannove": 19, "cento": 100, "mille": 1000,
        ]
        let tens = ["venti": 20, "trenta": 30, "quaranta": 40, "cinquanta": 50,
                    "sessanta": 60, "settanta": 70, "ottanta": 80, "novanta": 90]
        let units = ["uno": 1, "due": 2, "tre": 3, "quattro": 4, "cinque": 5,
                     "sei": 6, "sette": 7, "otto": 8, "nove": 9]
        for (ten, tenValue) in tens {
            words[ten] = tenValue
            for (unit, unitValue) in units {
                // venti + uno → ventuno, venti + otto → ventotto; ventitré is already unaccented.
                let stem = unit == "uno" || unit == "otto" ? String(ten.dropLast()) : ten
                words[stem + unit] = tenValue + unitValue
            }
        }
        return words
    }()

    /// Recognizers write numbers as digits ("12 €") while lessons spell them out ("dodici euro").
    static func value(of key: String) -> Int? {
        if !key.isEmpty, key.count <= 6, key.allSatisfy({ $0.isASCII && $0.isNumber }) {
            return Int(key)
        }
        return numberWords[key]
    }

    static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var previous = Array(0...b.count)
        var current = previous
        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)
                current[j] = min(substitution, previous[j] + 1, current[j - 1] + 1)
            }
            swap(&previous, &current)
        }
        return previous[b.count]
    }
}

/// A sentence split into words, keeping the text between them so it can be shown as written.
public struct SpokenSentence: Hashable, Sendable {
    /// Text before the first word, e.g. "¿" or a quote.
    public let leading: String
    public let words: [SpokenWord]

    static let apostrophes: Set<Character> = ["'", "’", "ʼ"]

    public init(_ text: String) {
        var leading = ""
        var words: [(text: String, elided: Bool)] = []
        var trailings: [String] = []
        var current = ""
        var gap = ""

        func closeWord(elided: Bool) {
            guard !current.isEmpty else { return }
            if words.isEmpty {
                leading = gap
            } else {
                trailings.append(gap)
            }
            words.append((current, elided))
            current = ""
            gap = ""
        }

        for character in text {
            if character == "€" {
                closeWord(elided: false)
                current = "€"
                closeWord(elided: false)
            } else if character.isLetter || character.isNumber {
                current.append(character)
            } else if Self.apostrophes.contains(character), !current.isEmpty, current.last?.isLetter == true {
                // "l'acqua", "dov'è", "un po'": the apostrophe belongs to the elided word.
                current.append(character)
                closeWord(elided: true)
            } else {
                closeWord(elided: false)
                gap.append(character)
            }
        }
        closeWord(elided: false)
        if words.isEmpty {
            leading = gap
        } else {
            trailings.append(gap)
        }

        self.leading = leading
        self.words = zip(words, trailings).map { word, trailing in
            SpokenWord(text: word.text, trailing: trailing, elided: word.elided)
        }
    }

    /// The words of recognizer output with prices read the way they are said: "3,50 €" and
    /// "€ 3,50" become "3 euro e 50", "€ 12" becomes "12 euro".
    var wordsWithAmountsSpelledOut: [SpokenWord] {
        var result: [SpokenWord] = []
        var index = 0
        func isDigits(_ word: SpokenWord) -> Bool {
            word.text.allSatisfy { $0.isASCII && $0.isNumber }
        }
        func isEuro(_ i: Int) -> Bool { words.indices.contains(i) && words[i].key == "euro" }
        /// Whole units at `i`, cents (two digits after "," or ".") at `i + 1` when present.
        func amount(at i: Int) -> (units: SpokenWord, cents: SpokenWord?, next: Int)? {
            guard words.indices.contains(i), isDigits(words[i]) else { return nil }
            let decimalMark = words[i].trailing == "," || words[i].trailing == "."
            if decimalMark, words.indices.contains(i + 1), isDigits(words[i + 1]), words[i + 1].text.count == 2 {
                return (words[i], words[i + 1], i + 2)
            }
            return (words[i], nil, i + 1)
        }
        func spell(_ amount: (units: SpokenWord, cents: SpokenWord?, next: Int), trailing: String) {
            let units = amount.units
            if let cents = amount.cents {
                result.append(SpokenWord(text: units.text, trailing: " "))
                result.append(SpokenWord(text: "euro", trailing: " "))
                result.append(SpokenWord(text: "e", trailing: " "))
                result.append(SpokenWord(text: cents.text, trailing: trailing))
            } else {
                result.append(SpokenWord(text: units.text, trailing: " "))
                result.append(SpokenWord(text: "euro", trailing: trailing))
            }
        }

        while index < words.count {
            if let found = amount(at: index), found.cents != nil, isEuro(found.next) {
                spell(found, trailing: words[found.next].trailing)
                index = found.next + 1
            } else if words[index].text == "€", let found = amount(at: index + 1) {
                spell(found, trailing: words[found.next - 1].trailing)
                index = found.next
            } else {
                result.append(words[index])
                index += 1
            }
        }
        return result
    }
}
