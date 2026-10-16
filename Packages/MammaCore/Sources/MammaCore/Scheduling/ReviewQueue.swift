import Foundation
import FSRS

public enum CardPhase: Sendable {
    case new
    /// In a learning or relearning step, scheduled minutes ahead.
    case learning
    /// Graduated; scheduled whole days ahead.
    case review
}

extension ReviewCard {
    public var phase: CardPhase {
        switch memory.state {
        case .new: .new
        case .learning, .relearning: .learning
        case .review: .review
        }
    }
}

extension ReviewScheduler {
    /// The card to show next in a review session:
    /// 1. learning-step cards whose step is up, earliest first;
    /// 2. review cards due any time today, lowest predicted recall first;
    /// 3. new cards in course order while today's new-card budget lasts;
    /// 4. otherwise a learning-step card due within `learnAhead`, so the session doesn't stall on a 10-minute step.
    ///
    /// A card of `avoidingPhrase` (the phrase just shown) is skipped while anything else is available:
    /// answering the recall card right after hearing the same sentence only tests short-term memory.
    public func nextCard(
        from cards: [ReviewCard],
        newBudget: Int,
        now: Date,
        clock: StudyClock,
        learnAhead: TimeInterval = 20 * 60,
        avoidingPhrase avoided: String? = nil
    ) -> ReviewCard? {
        let endOfToday = clock.end(of: clock.day(of: now))
        let learning = cards.filter { $0.phase == .learning }
        let dueLearning = learning.filter { $0.due <= now }.sorted { $0.due < $1.due }
        let dueReviews = cards
            .filter { $0.phase == .review && $0.due <= endOfToday }
            .map { (card: $0, recall: retrievability(of: $0, at: now)) }
            .sorted { $0.recall < $1.recall }
            .map(\.card)
        let newCards = newBudget > 0 ? Array(cards.filter(\.isNew).prefix(newBudget)) : []
        let ahead = learning
            .filter { $0.due > now && $0.due <= now.addingTimeInterval(learnAhead) }
            .sorted { $0.due < $1.due }
        let ordered = dueLearning + dueReviews + newCards + ahead
        return ordered.first { $0.id.phraseID != avoided } ?? ordered.first
    }

    /// When each grade would schedule the card next, for the labels on the answer buttons.
    public func outcomes(for card: ReviewCard, at now: Date) -> [Grade: Date] {
        var result: [Grade: Date] = [:]
        for grade in Grade.allCases {
            if let next = try? review(card, grade: grade, at: now) {
                result[grade] = next.card.due
            }
        }
        return result
    }
}

/// Short Chinese labels for intervals: "<1 分钟", "10 分钟", "3 天", "2 个月".
public enum IntervalText {
    public static func short(_ interval: TimeInterval) -> String {
        let minutes = interval / 60
        if minutes < 1 { return "<1 分钟" }
        if minutes < 60 { return "\(Int(minutes.rounded())) 分钟" }
        let hours = minutes / 60
        if hours < 24 { return "\(Int(hours.rounded())) 小时" }
        let days = hours / 24
        if days < 30 { return "\(Int(days.rounded())) 天" }
        let months = days / 30
        if months < 12 { return "\(Int(months.rounded())) 个月" }
        return "\((days / 365 * 10).rounded() / 10) 年"
    }
}
