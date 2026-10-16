import Foundation
import ImageIO
import Observation
import UIKit

/// The learner's own photos at the pilgrimage spots: copies in the app's folder, one folder per spot.
/// They stay on this phone. The progress backup doesn't carry them and nothing about them is logged;
/// the originals stay in Photos.
@MainActor
@Observable
final class SpotPhotoStore {
    private let root: URL
    /// Files by spot id, oldest first.
    private(set) var photos: [String: [URL]] = [:]

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        root = support.appendingPathComponent("SpotPhotos", isDirectory: true)
        reload()
    }

    func photos(at spot: String) -> [URL] {
        photos[spot] ?? []
    }

    var count: Int {
        photos.values.reduce(0) { $0 + $1.count }
    }

    /// Saves a smaller JPEG copy of `data` (HEIC and anything else ImageIO reads). The copy carries no
    /// metadata, so no location either.
    func add(_ data: Data, at spot: String) async throws {
        let folder = root.appendingPathComponent(spot, isDirectory: true)
        let file = folder.appendingPathComponent("\(Self.stamp.string(from: .now))-\(UUID().uuidString.prefix(8)).jpg")
        try await Task.detached(priority: .userInitiated) {
            guard let jpeg = PhotoResizer.jpeg(from: data) else { throw CocoaError(.fileReadCorruptFile) }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try jpeg.write(to: file, options: .atomic)
        }.value
        reload()
    }

    func delete(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            // The code only: the message would name the file, which says when it was added.
            AppLog.shared.write("A spot photo couldn't be deleted (error \((error as NSError).code))")
        }
        reload()
    }

    func reload() {
        let manager = FileManager.default
        var found: [String: [URL]] = [:]
        for folder in (try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [] {
            let files = ((try? manager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
                .filter { $0.pathExtension == "jpg" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            if !files.isEmpty {
                found[folder.lastPathComponent] = files
            }
        }
        photos = found
    }

    /// Names files by when they were added, in UTC so a folder lists oldest first across time zones.
    private static let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}

/// Downscaling with ImageIO, which decodes only as much of a large photo as the size needs.
enum PhotoResizer {
    /// Longest side of a saved copy, in pixels: plenty for a phone screen.
    static let savedPixels = 2048

    static func jpeg(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = image(from: source, maxPixels: savedPixels)
        else { return nil }
        return UIImage(cgImage: image).jpegData(compressionQuality: 0.85)
    }

    static func thumbnail(of url: URL, pixels: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = image(from: source, maxPixels: pixels)
        else { return nil }
        return UIImage(cgImage: image)
    }

    private static func image(from source: CGImageSource, maxPixels: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // Applies the photo's orientation, so the copy needs none.
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
