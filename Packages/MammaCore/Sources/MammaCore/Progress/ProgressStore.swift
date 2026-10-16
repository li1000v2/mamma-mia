import Foundation

public enum ProgressError: Error, Equatable, Sendable {
    /// The file was written by a newer build than this one.
    case newerVersion(Int)
}

/// Keeps `Progress` as JSON in one folder. Each save first copies the previous file to a backup,
/// and loading falls back to that backup when the main file can't be read.
public struct ProgressStore: Sendable {
    public let fileURL: URL
    public let backupURL: URL

    public init(directory: URL) {
        fileURL = directory.appendingPathComponent("progress.json")
        backupURL = directory.appendingPathComponent("progress.backup.json")
    }

    public func load() throws -> Progress {
        let manager = FileManager.default
        guard manager.fileExists(atPath: fileURL.path) else {
            if manager.fileExists(atPath: backupURL.path) {
                return try Self.decode(Data(contentsOf: backupURL))
            }
            return Progress()
        }
        do {
            return try Self.decode(Data(contentsOf: fileURL))
        } catch {
            guard manager.fileExists(atPath: backupURL.path) else { throw error }
            return try Self.decode(Data(contentsOf: backupURL))
        }
    }

    public func save(_ progress: Progress) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try Self.encode(progress)
        if manager.fileExists(atPath: fileURL.path) {
            if manager.fileExists(atPath: backupURL.path) {
                try manager.removeItem(at: backupURL)
            }
            try manager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
    }

    /// The same format is used for the file on disk and for exported backups.
    public static func encode(_ progress: Progress) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(progress)
    }

    public static func decode(_ data: Data) throws -> Progress {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let progress = try decoder.decode(Progress.self, from: data)
        guard progress.version <= Progress.currentVersion else {
            throw ProgressError.newerVersion(progress.version)
        }
        return progress
    }
}
