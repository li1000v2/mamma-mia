import Foundation
import Testing
@testable import MammaCore

struct SpeechCheckTests {
    func missed(_ target: String, heard transcript: String) -> [String] {
        SpeechCheck(target: target, transcript: transcript).missed.map(\.text)
    }

    // MARK: Normalization

    @Test func splitsWordsAndKeepsTheTextBetweenThem() {
        let sentence = SpokenSentence("Scusi, non ho capito. Più piano, per favore.")
        #expect(sentence.words.map(\.text) == ["Scusi", "non", "ho", "capito", "Più", "piano", "per", "favore"])
        #expect(sentence.words.map(\.key) == ["scusi", "non", "ho", "capito", "piu", "piano", "per", "favore"])
        #expect(sentence.words.first?.trailing == ", ")
        #expect(sentence.words.last?.trailing == ".")
    }

    @Test func rebuildsTheTargetAsWritten() {
        for target in ["Quant'è?", "«Ciao!»", "Un cappuccino e una brioche, per favore.", "Dov'è l'uscita?", "..."] {
            let check = SpeechCheck(target: target, transcript: "ciao")
            #expect(check.leading + check.words.map { $0.text + $0.trailing }.joined() == target)
        }
    }

    @Test func elisionKeepsTheApostropheOnTheElidedWord() {
        let sentence = SpokenSentence("Dov'è l’uscita? Un po'.")
        #expect(sentence.words.map(\.text) == ["Dov'", "è", "l’", "uscita", "Un", "po'"])
        #expect(sentence.words.map(\.elided) == [true, false, true, false, false, true])
        #expect(sentence.words.map(\.key) == ["dov", "e", "l", "uscita", "un", "po"])
    }

    @Test func numbersMatchDigitsAndWords() {
        let words = SpokenSentence("12 dodici ventuno 21 ventotto 28 trentatré 33 un 1 una cento 100").words
        #expect(words.map(\.number) == [12, 12, 21, 21, 28, 28, 33, 33, 1, 1, 1, 100, 100])
        #expect(SpokenSentence("sono").words[0].number == nil)
    }

    // MARK: Alignment

    @Test func ignoresCaseAccentsAndPunctuation() {
        #expect(missed("Più piano, per favore.", heard: "piu piano per favore") == [])
        #expect(missed("Può ripetere, per favore?", heard: "PUO RIPETERE PER FAVORE") == [])
        #expect(missed("caffè", heard: "Caffe.") == [])
        #expect(missed("È tutto.", heard: "e tutto") == [])
        // Decomposed accents, as some text sources produce them.
        #expect(missed("caffè", heard: "caffe\u{300}") == [])
        #expect(SpeechCheck(target: "Grazie mille!", transcript: "Grazie mille.").verdict == .clear)
    }

    @Test func marksTheWordsTheRecognizerMissed() {
        let check = SpeechCheck(target: "Scusi, non ho capito.", transcript: "Scusi non capito")
        #expect(check.words.map(\.heard) == [true, true, false, true])
        #expect(check.missed.map(\.text) == ["ho"])
        #expect(check.verdict == .mostly)
        #expect(missed("Me lo può scrivere?", heard: "Me può scrivere") == ["lo"])
        #expect(missed("Vorrei un caffè, per favore.", heard: "Vorrei un caffè") == ["per", "favore"])
    }

    @Test func reportsANearMissAsWhatWasHeard() {
        let check = SpeechCheck(target: "Scusi, non ho capito.", transcript: "Scusa, non ho capito.")
        #expect(check.missed.map(\.text) == ["Scusi"])
        #expect(check.missed.first?.heardAs == "Scusa")

        // An unrelated word in its place is just missing, not "heard as".
        let unrelated = SpeechCheck(target: "Prendo un cappuccino.", transcript: "Prendo un tavolo")
        #expect(unrelated.missed.map(\.text) == ["cappuccino"])
        #expect(unrelated.missed.first?.heardAs == nil)
    }

    @Test func extraWordsDontCountAgainstTheSentence() {
        #expect(missed("Al banco.", heard: "Buongiorno, al banco, grazie") == [])
        #expect(missed("Prendo un cappuccino.", heard: "Allora prendo un cappuccino per favore") == [])
    }

    @Test func elidedWordsMatchTheirFullForm() {
        #expect(missed("Quant'è?", heard: "Quanto è") == [])
        #expect(missed("Quant'è?", heard: "Quant'è") == [])
        #expect(missed("Dov'è l'uscita?", heard: "Dove è la uscita") == [])
        #expect(missed("Dov'è l'uscita?", heard: "Dove la uscita") == ["è"])
    }

    @Test func pricesWrittenAsDigitsMatchTheSpokenForm() {
        #expect(missed("Sono dodici euro.", heard: "Sono 12 €.") == [])
        #expect(missed("Sono dodici euro.", heard: "Sono 12 euro") == [])
        #expect(missed("Tre euro e cinquanta.", heard: "3,50 €") == [])
        #expect(missed("Tre euro e cinquanta.", heard: "€ 3.50") == [])
        #expect(missed("Un euro e venti.", heard: "1,20 €") == [])
        #expect(missed("Prendo un cappuccino.", heard: "Prendo 1 cappuccino") == [])
        #expect(missed("Due biglietti.", heard: "3 biglietti") == ["Due"])
    }

    @Test func toleratesReorderedWords() {
        // Some recognizers put the currency first.
        #expect(missed("Dodici euro.", heard: "euro 12") == [])
    }

    @Test func verdicts() {
        #expect(SpeechCheck(target: "Non ho capito.", transcript: "").verdict == .silent)
        #expect(SpeechCheck(target: "Non ho capito.", transcript: "  ...  ").verdict == .silent)
        #expect(SpeechCheck(target: "Non ho capito.", transcript: "non ho capito").verdict == .clear)
        #expect(SpeechCheck(target: "Non ho capito.", transcript: "non capito").verdict == .mostly)
        #expect(SpeechCheck(target: "Posso pagare con la carta?", transcript: "posso andare").verdict == .unclear)
    }

    @Test func repeatedWordsEachNeedTheirOwnMatch() {
        #expect(missed("Al banco o al tavolo?", heard: "al banco o tavolo") == ["al"])
        #expect(missed("Al banco o al tavolo?", heard: "al banco o al tavolo") == [])
    }

    // MARK: Replies

    static let notUnderstood = [
        "Scusi, non ho capito. Più piano, per favore.",
        "Sì, grazie.",
        "Non capito.",
    ]
    static let croissant = [
        "Un cornetto al cioccolato, per favore.",
        "Una cioccolata, per favore.",
        "Ho un cornetto al cioccolato.",
    ]
    static let enough = [
        "No, grazie. Basta così.",
        "Sì, grazie. Basta così.",
        "No, prego.",
    ]

    @Test func eachChoiceSaidInFullMatchesItself() {
        for choices in [Self.notUnderstood, Self.croissant, Self.enough] {
            for (index, choice) in choices.enumerated() {
                #expect(ReplyMatcher.match(choice, choices: choices) == index, "\(choice)")
                #expect(ReplyMatcher.match(choice.lowercased().filter { $0.isLetter || $0 == " " }, choices: choices) == index)
            }
        }
    }

    @Test func matchesAReplyWithMostOfAChoicesWords() {
        #expect(ReplyMatcher.match("scusi non ho capito più piano", choices: Self.notUnderstood) == 0)
        #expect(ReplyMatcher.match("Buongiorno, un cornetto al cioccolato per favore", choices: Self.croissant) == 0)
        #expect(ReplyMatcher.match("No grazie", choices: Self.enough) == 0)
        #expect(ReplyMatcher.match("Sì grazie basta così", choices: Self.enough) == 1)
        #expect(ReplyMatcher.match("Me lo può scrivere", choices: ["Me lo può scrivere?", "Lo scrivo io.", "Può pagare?"]) == 0)
    }

    @Test func wordsOfAnotherChoiceRuleAChoiceOut() {
        // "ho" belongs to the first choice, so this isn't "Non capito"; and it's too little of the first.
        #expect(ReplyMatcher.match("Non ho capito", choices: Self.notUnderstood) == nil)
        // Says neither "per favore" nor "ho": could be either.
        #expect(ReplyMatcher.match("un cornetto al cioccolato", choices: Self.croissant) == nil)
        // "Sì" and "No" are the keywords here.
        #expect(ReplyMatcher.match("grazie basta così", choices: Self.enough) == nil)
    }

    @Test func noMatchForSilenceOrSomethingElse() {
        #expect(ReplyMatcher.match("", choices: Self.enough) == nil)
        #expect(ReplyMatcher.match("Dov'è la stazione?", choices: Self.enough) == nil)
        #expect(ReplyMatcher.match("ciao", choices: []) == nil)
    }

    @Test func numbersInChoicesMatchDigits() {
        let choices = ["Due biglietti, per favore.", "Tre biglietti, per favore."]
        #expect(ReplyMatcher.match("2 biglietti per favore", choices: choices) == 0)
        #expect(ReplyMatcher.match("3 biglietti", choices: choices) == 1)
    }
}
