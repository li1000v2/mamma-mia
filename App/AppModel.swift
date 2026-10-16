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
    /// The trip day each phrase is first needed on, by phrase id; empty without a trip.
    private(set) var needByDays: [String: LocalDate] = [:]
    /// One per stop: the arrival's cards join the reviews the evening before. Empty without a trip.
    private(set) var cityPacks: [CityPack] = []

    let scheduler = ReviewScheduler()
    let audio = AudioService()
    let recorder = Recorder()
    let speech = SpeechService()
    let notifier = CityPackNotifier()
    let spotPhotos = SpotPhotoStore()
    let checks = DepartureCheckStore()
    private let store: ProgressStore

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        store = ProgressStore(directory: support.appendingPathComponent("Progress", isDirectory: true))
        AppLog.shared.write("Launch \(BuildInfo.summary) on \(ProcessInfo.processInfo.operatingSystemVersionString)")
        configureAudioSession()
        loadContent()
        loadProgress()
        refreshNeedBy()
        Task { await speech.refresh() }
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
        scheduler.plan(cards: activeCards, newIntroducedToday: newCardsStartedToday, now: .now, clock: clock,
                       needBy: needBy, packs: cityPacks)
    }

    var reviewsToday: Int {
        progress.reviewCount(on: today, clock: clock)
    }

    func nextReviewCard(after previous: ReviewCard? = nil) -> ReviewCard? {
        let budget = max(0, scheduler.config.newCardsPerDay - newCardsStartedToday)
        return scheduler.nextCard(from: activeCards, newBudget: budget, now: .now, clock: clock,
                                  needBy: needBy, packs: cityPacks, avoidingPhrase: previous?.id.phraseID)
    }

    /// The trip day a card is first needed on, for the review queue.
    private var needBy: (ReviewCard) -> LocalDate? {
        let days = needByDays
        return { days[$0.id.phraseID] }
    }

    /// For a card shown although FSRS doesn't have it due today: the day the trip needs it.
    func boostDay(for card: ReviewCard) -> LocalDate? {
        guard card.phase == .review, card.due > clock.end(of: today) else { return nil }
        return needByDays[card.id.phraseID]
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

    // MARK: Trip

    /// Personal data: kept in the progress file on this phone and in its backups, never in the log.
    /// Read through `normalized`, so the stops are in order and the holidays are this build's
    /// even for a trip saved by an earlier one.
    var trip: Trip? {
        guard let saved = progress.trip else { return nil }
        guard let content else { return saved }
        return saved.normalized(events: content.course.events)
    }

    /// Today's calendar date where the phone is; the phone switches to Italian time on landing.
    var calendarToday: LocalDate { LocalDate.of(.now, in: .current) }

    var cities: [CourseCity] { content?.course.cities ?? [] }

    func cityName(_ id: String) -> String {
        content?.course.city(id)?.zh ?? id
    }

    func eventName(_ id: String) -> String {
        content?.course.event(id)?.zh ?? id
    }

    /// Saves the trip from the form, or clears it with nil. Learning records are untouched.
    func saveTrip(_ trip: Trip?) {
        progress.trip = trip
        save()
        refreshNeedBy()
        AppLog.shared.write(trip == nil ? "Trip cleared" : "Trip saved")
    }

    /// Changes the notes and check-ins at the pilgrimage spots and saves them. Personal like the
    /// trip: kept with the progress and in its backups, never in the log.
    func updateSpotLogs(_ change: (inout StudyProgress) -> Void) {
        change(&progress)
        save()
    }

    // MARK: Backup

    /// Writes the progress to a temporary file named for today, for sharing or saving to Files.
    func exportFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MammaMia-progress-\(today).json")
        try ProgressStore.encode(progress).write(to: url, options: .atomic)
        return url
    }

    /// Replaces the progress with an exported file; the current one is kept as the backup copy.
    /// A backup without a trip (older ones have none) keeps the trip already on the phone; the
    /// result says whether that happened.
    @discardableResult
    func importProgress(from url: URL) throws -> Bool {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        let backup = try ProgressStore.decode(Data(contentsOf: url))
        let (restored, keptTrip) = progress.restoring(backup)
        try store.save(restored)
        progress = restored
        refreshNeedBy()
        AppLog.shared.write("Imported progress: \(restored.cards.count) cards, \(restored.reviews.count) reviews")
        if backup.droppedUnreadableTrip {
            AppLog.shared.write(Self.unreadableTripNote)
        }
        return keptTrip
    }

    /// Logged instead of anything about the trip itself.
    private static let unreadableTripNote = "A trip in the file couldn't be read and was left out"

    // MARK: Private

    private func refreshNeedBy() {
        if let content, let trip {
            needByDays = content.needByDays(on: trip)
            cityPacks = content.cityPacks(on: trip)
        } else {
            needByDays = [:]
            cityPacks = []
        }
        rescheduleTripReminders()
    }

    private func loadProgress() {
        do {
            progress = try store.load()
            AppLog.shared.write("Progress: \(progress.cards.count) cards, \(progress.reviews.count) reviews")
            if progress.droppedUnreadableTrip {
                AppLog.shared.write(Self.unreadableTripNote)
            }
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
