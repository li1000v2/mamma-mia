import Foundation
import Observation
import MammaCore

/// What the departure check keeps about this phone, in UserDefaults rather than the progress file:
/// the learner's ticks, which show cards went into Photos as they were then, and SideStore's signing
/// profile.
@MainActor
@Observable
final class DepartureCheckStore {
    private let defaults: UserDefaults
    /// When each manual item was ticked.
    private(set) var done: [DepartureCheck.Manual: Date] = [:]
    /// Card id → fingerprint of the card as it was saved to Photos.
    private(set) var savedCards: [String: String]
    /// Manifest files missing from the app, and how many it lists; nil until counted.
    private(set) var missingAudio: Int?
    private(set) var audioFiles = 0
    /// The signing profile SideStore put in the app; nil in a simulator build or one installed otherwise.
    let profile: ProvisioningProfile?

    private static let savedCardsKey = "departureCheck.savedShowCards"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        profile = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap(ProvisioningProfile.init(data:))
        savedCards = defaults.dictionary(forKey: Self.savedCardsKey) as? [String: String] ?? [:]
        var done: [DepartureCheck.Manual: Date] = [:]
        for item in DepartureCheck.Manual.allCases {
            if let date = defaults.object(forKey: Self.doneKey(item)) as? Date {
                done[item] = date
            }
        }
        self.done = done
        if let profile {
            AppLog.shared.write("Signing profile expires \(profile.expires.ISO8601Format())")
        } else {
            AppLog.shared.write("No signing profile in the app")
        }
    }

    func setDone(_ item: DepartureCheck.Manual, _ isDone: Bool) {
        done[item] = isDone ? .now : nil
        defaults.set(done[item], forKey: Self.doneKey(item))
    }

    /// Notes `cards` as saved to Photos the way they are now.
    func recordSaved(_ cards: [ShowCard]) {
        for card in cards {
            savedCards[card.id] = card.fingerprint
        }
        defaults.set(savedCards, forKey: Self.savedCardsKey)
    }

    /// Counts the manifest's files that the app is missing, off the main thread; once per launch, as
    /// the app's files don't change while it runs.
    func countAudio(manifest: AudioManifest?, directory: URL?) async {
        guard missingAudio == nil, let manifest else { return }
        audioFiles = Set(manifest.entries.values).count
        guard let directory else {
            missingAudio = audioFiles
            return
        }
        let missing = await Task.detached(priority: .utility) { manifest.missingFiles(in: directory).count }.value
        missingAudio = missing
        if missing > 0 {
            AppLog.shared.write("Audio: \(missing) of \(audioFiles) files missing from the app")
        }
    }

    private static func doneKey(_ item: DepartureCheck.Manual) -> String {
        "departureCheck.done.\(item.rawValue)"
    }
}
