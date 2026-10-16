import Foundation

/// Plain-text log in Application Support. A sideloaded build has no Xcode console, so the
/// 诊断 screen shows this file and can share it for debugging.
final class AppLog: @unchecked Sendable {
    static let shared = AppLog()

    let fileURL: URL
    private let lock = NSLock()
    private let maxBytes = 512 * 1024

    private init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("mammamia.log")
    }

    func write(_ message: String) {
        let line = Data("\(Date().ISO8601Format()) \(message)\n".utf8)
        lock.lock()
        defer { lock.unlock() }
        // Start over rather than grow without bound; the log is only for recent problems.
        if let size = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int, size > maxBytes {
            try? FileManager.default.removeItem(at: fileURL)
        }
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: line)
        } else {
            try? line.write(to: fileURL)
        }
    }

    func read() -> String {
        lock.lock()
        defer { lock.unlock() }
        return (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    }
}
