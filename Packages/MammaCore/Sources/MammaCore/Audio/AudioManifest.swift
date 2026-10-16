import Foundation

public enum Speed: String, Codable, Sendable, CaseIterable {
    case normal = "n"
    case slow = "s"
}

/// Audio/manifest.json, written by the TTS tool. Files are named by a hash of the entry key, so
/// editing a sentence or bumping a voice's revision regenerates only the audio that changed.
public struct AudioManifest: Codable, Sendable {
    public let version: Int
    /// Current voice profiles as "<voice>@<revision>", e.g. "f1@1".
    public let voices: [String]
    /// Entry key → file name inside Audio/.
    public let entries: [String: String]

    /// Must stay identical to the key the audio tool computes: "<voice>|<speed>|<text>".
    public static func key(text: String, voice: String, speed: Speed) -> String {
        "\(voice)|\(speed.rawValue)|\(text)"
    }

    public func file(text: String, voice: String, speed: Speed) -> String? {
        entries[Self.key(text: text, voice: voice, speed: speed)]
    }
}
