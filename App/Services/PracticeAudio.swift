import Foundation
import MammaCore

/// Gemini recordings of the sentences role-play feedback added to reviews, so their cards play
/// the role's voice instead of the phone's. Kept in Application Support on this phone; a phrase
/// without one (restored from a backup elsewhere) falls back to the phone's Italian voice.
enum PracticeAudio {
    static let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("PracticeAudio", isDirectory: true)

    /// Named after the phrase id, so the same words find the same file.
    static func url(for text: String) -> URL {
        directory.appendingPathComponent("\(PracticePhrase.id(for: text)).wav")
    }

    static func recording(for text: String) -> URL? {
        let url = url(for: text)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Saves streamed TTS (24 kHz mono 16-bit little-endian PCM) as a WAV file.
    static func save(pcm: Data, for text: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var wav = Data()
        let rate = UInt32(StreamingSpeechPlayer.sampleRate)
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { wav.append(contentsOf: $0) }
        }
        wav.append(contentsOf: Array("RIFF".utf8))
        append(UInt32(36 + pcm.count))
        wav.append(contentsOf: Array("WAVEfmt ".utf8))
        append(UInt32(16))      // fmt chunk size
        append(UInt16(1))       // PCM
        append(UInt16(1))       // mono
        append(rate)
        append(rate * 2)        // bytes per second
        append(UInt16(2))       // bytes per frame
        append(UInt16(16))      // bits per sample
        wav.append(contentsOf: Array("data".utf8))
        append(UInt32(pcm.count))
        wav.append(pcm)
        try wav.write(to: url(for: text), options: .atomic)
    }

    static func delete(for text: String) {
        try? FileManager.default.removeItem(at: url(for: text))
    }
}
