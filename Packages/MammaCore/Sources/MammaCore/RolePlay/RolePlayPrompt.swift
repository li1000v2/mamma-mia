import Foundation

/// What the model is told in the online role-play and when it writes the feedback card. Both
/// follow the course: Lei towards strangers, masculine forms for the learner, A1–A2 Italian.
public enum RolePlayPrompt {
    /// The longest reply, in words; the system prompt asks for it and the chunker doesn't enforce it.
    public static let maxWords = 15

    /// Sent as the first user turn when the role speaks first: the history has to start with the
    /// user, and this tells the model it's its turn to open.
    public static let openingCue = "[The learner walks up to you. Open the conversation the way you would.]"

    public static func system(for role: RolePlayRole) -> String {
        """
        You are role-playing with a beginner learner of Italian (A1–A2) who is practising for a trip to Italy. \
        Each learner line is what speech recognition heard on their phone, so it may have recognition mistakes, \
        no accents and no punctuation. Understand it generously, as a patient person would; if you really can't \
        understand, say so briefly in Italian and ask them to repeat.

        Your role: \(role.setting)

        Rules:
        - Stay in character and keep the situation realistic.
        - Speak only simple Italian (A1–A2): common words, short sentences.
        - At most \(maxWords) words per turn.
        - Address the learner formally with Lei (Scusi, Mi dica, Può…), never with tu. The learner is a man: \
        use masculine forms for him (benvenuto, signore).
        - Now and then end with one simple question that moves the situation on; never more than one question per turn.
        - No English, unless the learner asks "Parla inglese?": then say "Un po'." and at most one short English \
        sentence, and go back to Italian.
        - Write only words you say out loud: no emoji, asterisks, markdown, lists or stage directions.
        - Write prices, times and other numbers in words, as you say them (tre euro e cinquanta, alle nove e mezza).
        - A user line in square brackets is a note from the app, not something the learner said.
        - When the learner says goodbye or the task is done, close politely in one short line.

        Reply in exactly two lines:
        what you say, in Italian
        the same in Simplified Chinese
        """
    }

    // MARK: Feedback

    public static let feedbackSystem = """
        You are a patient Italian teacher. A Chinese-speaking beginner (A1–A2) just did a spoken role-play to \
        practise for a trip to Italy. Course conventions: strangers are addressed with Lei; the learner uses \
        masculine forms for himself (sono arrivato, sono stanco).

        The learner's lines are what speech recognition heard, so they may contain recognition errors. Don't correct \
        capitalization, punctuation, missing accents, or words that only look wrong because of recognition. Correct \
        real mistakes a listener would notice: wrong words or forms, tu instead of Lei, a sentence that would be \
        misunderstood or sounds rude.

        Return JSON with:
        - summary: one or two sentences in Simplified Chinese: what went well, and the one thing to work on.
        - corrections: at most 3, most useful first. said = the learner's words as in the transcript; better = a \
        short, natural, correct Italian sentence for what they meant (A1–A2, Lei); zh = its meaning in Simplified \
        Chinese; why = one short Simplified Chinese sentence on what changed and why. Leave the list empty when \
        nothing is worth correcting.
        - expression: one useful Italian expression for this situation that the learner didn't use, with zh (its \
        meaning in Simplified Chinese) and note (one short Simplified Chinese sentence on when to use it).
        """

    public static func feedbackPrompt(role: RolePlayRole, lines: [RolePlayLine]) -> String {
        var text = """
            Situation: \(role.setting)
            The learner's task (in Chinese): \(role.task)

            Conversation (ROLE is the other person, LEARNER is the learner):

            """
        for line in lines {
            switch line.speaker {
            case .role: text += "ROLE: \(line.text)\n"
            case .learner: text += "LEARNER: \(line.text)\n"
            }
        }
        return text
    }

    public static let feedbackSchema: JSONValue = [
        "type": "object",
        "properties": [
            "summary": ["type": "string"],
            "corrections": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "said": ["type": "string"],
                        "better": ["type": "string"],
                        "zh": ["type": "string"],
                        "why": ["type": "string"],
                    ],
                    "required": ["said", "better", "zh", "why"],
                ],
            ],
            "expression": [
                "type": "object",
                "properties": [
                    "it": ["type": "string"],
                    "zh": ["type": "string"],
                    "note": ["type": "string"],
                ],
                "required": ["it", "zh", "note"],
            ],
        ],
        "required": ["summary", "corrections", "expression"],
    ]
}
