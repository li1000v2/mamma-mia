import Foundation

/// Version details CI writes into Info.plist, so you can tell which build is on the phone.
enum BuildInfo {
    static var version: String { info("CFBundleShortVersionString") ?? "?" }
    static var build: String { info("CFBundleVersion") ?? "?" }
    static var commit: String { info("MMGitCommit") ?? "local" }

    static var summary: String { "\(version) (\(build), \(commit))" }

    private static func info(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else { return nil }
        return value
    }
}
