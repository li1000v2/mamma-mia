import Foundation
import Observation
import MammaCore

@MainActor
@Observable
final class AppModel {
    private(set) var content: ContentBundle?
    private(set) var loadError: String?

    init() {
        AppLog.shared.write("Launch \(BuildInfo.summary) on \(ProcessInfo.processInfo.operatingSystemVersionString)")
        loadContent()
    }

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
            AppLog.shared.write("Loaded \(bundle.course.units.count) units, \(bundle.phrases.count) phrases, \(bundle.audio?.entries.count ?? 0) audio files")
        } catch {
            loadError = String(describing: error)
            AppLog.shared.write("Content failed to load: \(error)")
        }
    }
}
