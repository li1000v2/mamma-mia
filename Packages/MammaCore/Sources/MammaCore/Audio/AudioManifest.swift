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

    /// The file to play for `text`: in the `preferred` voice ("f1" matches "f1@2") when given,
    /// otherwise in a voice picked from the text itself, so a sentence always sounds the same.
    /// Falls back to any voice that has the line.
    public func file(for text: String, speed: Speed, preferring preferred: String? = nil) -> String? {
        guard !voices.isEmpty else { return nil }
        let chosen = preferred.flatMap { id in voices.first { $0 == id || $0.hasPrefix(id + "@") } }
            ?? voices[Int(Self.stableHash(text) % UInt64(voices.count))]
        return file(text: text, voice: chosen, speed: speed)
            ?? voices.lazy.compactMap { file(text: text, voice: $0, speed: speed) }.first
    }

    /// FNV-1a over UTF-8: unlike `hashValue`, the same on every launch and platform.
    static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}
