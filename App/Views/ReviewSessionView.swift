import SwiftUI
import MammaCore

/// One review session: cards come from the FSRS queue one at a time until nothing is due.
struct ReviewSessionView: View {
    @Environment(AppModel.self) private var model
    @State private var card: ReviewCard?
    @State private var revealed = false
    @State private var reviewed = 0
    @State private var started = false

    var body: some View {
        Group {
            if let card, let phrase = model.phrase(for: card) {
                ReviewCardView(card: card, phrase: phrase, revealed: $revealed) { grade in
                    model.grade(card, grade)
                    reviewed += 1
                    advance(after: card)
                }
                // A fresh view per card, so a spoken try doesn't carry over to the next one.
                .id(card.id)
            } else if started {
                ContentUnavailableView(
                    "今天的复习完成了",
                    systemImage: "checkmark.seal",
                    description: Text("这次复习了 \(reviewed) 张。还在学习步骤里的卡，过几分钟会再出现。")
                )
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !started {
                advance()
                started = true
            }
        }
        .onDisappear {
            model.audio.stop()
            model.recorder.stop()
        }
    }

    private var title: String {
        reviewed > 0 ? "复习 · 已做 \(reviewed) 张" : "复习"
    }

    private func advance(after previous: ReviewCard? = nil) {
        revealed = false
        card = model.nextReviewCard(after: previous)
    }
}

private struct ReviewCardView: View {
    @Environment(AppModel.self) private var model
    let card: ReviewCard
    let phrase: Phrase
    @Binding var revealed: Bool
    let onGrade: (Grade) -> Void
    /// A recall card can be said aloud before showing the answer. It's only a hint: the grade
    /// is still the learner's own, and only that grade updates the card.
    @State private var attempt: SpokenAttempt?

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(card.id.kind == .listen ? "听：这句是什么意思？" : "说：用意大利语怎么说？")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                // In a city pack, or not due yet but needed on the trip soon; graded like any other review.
                if let tag = model.travelTag(for: card) {
                    Label(tag, systemImage: "airplane")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            ScrollView {
                VStack(spacing: 20) {
                    prompt
                    if revealed {
                        answer
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            // Centered like before while it fits; scrolls when a spoken check makes it taller.
            .defaultScrollAnchor(.center)
            if revealed {
                gradeButtons
            } else {
                if card.id.kind == .recall {
                    SayItButton(recordingID: "say-\(phrase.id)", title: "先说一遍（可选）", prominent: false) { result in
                        guard !revealed else { return }
                        attempt = result
                        reveal()
                    }
                }
                Button {
                    reveal()
                } label: {
                    Text("显示答案")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .task(id: card.id) {
            if card.id.kind == .listen {
                await model.audio.say(phrase.it)
            }
        }
    }

    @ViewBuilder
    private var prompt: some View {
        if card.id.kind == .listen {
            HStack(spacing: 40) {
                SpeakButton(text: phrase.it)
                SpeakButton(text: phrase.it, speed: .slow)
            }
            .font(.largeTitle)
        } else {
            Text(phrase.zh)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
        }
    }

    private var answer: some View {
        VStack(spacing: 8) {
            if let attempt {
                SpokenAnswer(text: phrase.it, attempt: attempt)
            } else {
                Text(phrase.it)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            Text(phrase.zh)
                .foregroundStyle(.secondary)
            if let note = phrase.note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if card.id.kind != .listen, attempt == nil {
                HStack(spacing: 28) {
                    SpeakButton(text: phrase.it)
                    SpeakButton(text: phrase.it, speed: .slow)
                }
            }
        }
    }

    private var gradeButtons: some View {
        let outcomes = model.outcomes(for: card)
        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Grade.allCases, id: \.self) { grade in
                    Button {
                        onGrade(grade)
                    } label: {
                        VStack(spacing: 2) {
                            Text(grade.label)
                                .font(.headline)
                            if let due = outcomes[grade] {
                                Text(IntervalText.short(due.timeIntervalSinceNow))
                                    .font(.caption2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(grade.tint)
                }
            }
            Text("重来：没想出来 · 困难：想了很久才对 · 记得：想得出来 · 轻松：脱口而出")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func reveal() {
        model.recorder.stop()
        revealed = true
        if card.id.kind != .listen {
            Task { await model.audio.say(phrase.it) }
        }
    }
}
