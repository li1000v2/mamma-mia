import AVFoundation
import Foundation
import Observation
import MammaCore

@MainActor
@Observable
final class AppModel {
    private(set) var content: ContentBundle?
    private(set) var loadError: String?
    private(set) var progress = StudyProgress()
    private(set) var storageError: String?
    private(set) var phrasesByID: [String: Phrase] = [:]

    let scheduler = ReviewScheduler()
    let audio = AudioService()
    let recorder = Recorder()
    private let store: ProgressStore

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        store = ProgressStore(directory: support.appendingPathComponent("Progress", isDirectory: true))
        AppLog.shared.write("Launch \(BuildInfo.summary) on \(ProcessInfo.processInfo.operatingSystemVersionString)")
        configureAudioSession()
        loadContent()
        loadProgress()
    }

    /// Follows the device time zone, which changes when the phone lands in Italy.
    var clock: StudyClock { StudyClock(timeZone: .current) }

    var today: LocalDate { clock.day(of: .now) }

    var planner: StudyPlanner? { content.map { StudyPlanner(content: $0) } }

    // MARK: Content

    /// Content/ and Audio/ are copied into the app bundle as folders at build time.
    func loadContent() {
        guard let contentURL = Bundle.main.url(forResource: "Content", withExtension: nil) else {
            loadError = "安装包里找不到 Content 文件夹"
            AppLog.shared.write("Content folder missing from the app bundle")
            return
        }
        let audioURL = Bundle.main.url(forResource: "Audio", withExtension: nil)
        do {
            let bundle = try ContentBundle.load(contentDirectory: contentURL, audioDirectory: audioURL)
            content = bundle
            loadError = nil
            phrasesByID = Dictionary(bundle.phrases.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            audio.configure(manifest: bundle.audio, directory: audioURL)
            AppLog.shared.write("Loaded \(bundle.course.units.count) units, \(bundle.phrases.count) phrases, \(bundle.dialogues.count) dialogues, \(bundle.audio?.entries.count ?? 0) audio files")
        } catch {
            loadError = String(describing: error)
            AppLog.shared.write("Content failed to load: \(error)")
        }
    }

    func phrase(for card: ReviewCard) -> Phrase? {
        phrasesByID[card.id.phraseID]
    }

    // MARK: Reviews

    /// Cards whose phrase is still in the bundled content; a later build may drop or rename phrases.
    var activeCards: [ReviewCard] {
        progress.cards.filter { phrasesByID[$0.id.phraseID] != nil }
    }

    var newCardsStartedToday: Int {
        progress.newCardsStarted(on: today, clock: clock)
    }

    var todayPlan: DailyPlan {
        scheduler.plan(cards: activeCards, newIntroducedToday: newCardsStartedToday, now: .now, clock: clock)
    }

    var reviewsToday: Int {
        progress.reviewCount(on: today, clock: clock)
    }

    func nextReviewCard() -> ReviewCard? {
        let budget = max(0, scheduler.config.newCardsPerDay - newCardsStartedToday)
        return scheduler.nextCard(from: activeCards, newBudget: budget, now: .now, clock: clock)
    }

    func outcomes(for card: ReviewCard) -> [Grade: Date] {
        scheduler.outcomes(for: card, at: .now)
    }

    func grade(_ card: ReviewCard, _ grade: Grade) {
        do {
            let (updated, record) = try scheduler.review(card, grade: grade, at: .now)
            progress.apply(updated, record: record)
            save()
        } catch {
            AppLog.shared.write("Review of \(card.id) failed: \(error)")
        }
    }

    // MARK: Lessons and challenges

    func completeLesson(_ unit: CourseUnit) {
        guard let planner else { return }
        let cards = planner.cards(for: unit.id)
        progress.completeLesson(unit.id, cards: cards, scheduler: scheduler, at: .now)
        save()
        AppLog.shared.write("Finished \(unit.id), \(cards.count) cards")
    }

    func record(_ run: ChallengeRun) {
        progress.add(run)
        save()
        AppLog.shared.write("Challenge \(run.unit) \(run.passed ? "passed" : "not passed"), hints \(run.hintsUsed), mistakes \(run.mistakes)")
    }

    // MARK: Backup

    /// Writes the progress to a temporary file named for today, for sharing or saving to Files.
    func exportFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MammaMia-progress-\(today).json")
        try ProgressStore.encode(progress).write(to: url, options: .atomic)
        return url
    }

    /// Replaces the progress with an exported file; the current one is kept as the backup copy.
    func importProgress(from url: URL) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        let imported = try ProgressStore.decode(Data(contentsOf: url))
        try store.save(imported)
        progress = imported
        AppLog.shared.write("Imported progress: \(imported.cards.count) cards, \(imported.reviews.count) reviews")
    }

    // MARK: Private

    private func loadProgress() {
        do {
            progress = try store.load()
            AppLog.shared.write("Progress: \(progress.cards.count) cards, \(progress.reviews.count) reviews")
        } catch {
            storageError = "读取学习进度失败：\(error)"
            AppLog.shared.write("Progress failed to load: \(error)")
        }
    }

    private func save() {
        do {
            try store.save(progress)
            storageError = nil
        } catch {
            storageError = "保存学习进度失败：\(error)"
            AppLog.shared.write("Progress failed to save: \(error)")
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            AppLog.shared.write("Audio session setup failed: \(error)")
        }
    }
}
