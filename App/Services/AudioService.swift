import AVFoundation
import MammaCore

/// Plays model audio: the bundled TTS file when the manifest has one, otherwise iOS's own Italian
/// voice, so lessons work before the audio is generated. Each call returns when playback ends or
/// is interrupted by the next one.
@MainActor
final class AudioService: NSObject {
    private var manifest: AudioManifest?
    private var audioDirectory: URL?
    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private var playbackID: ObjectIdentifier?
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func configure(manifest: AudioManifest?, directory: URL?) {
        self.manifest = manifest
        audioDirectory = directory
    }

    /// Whether `text` has a generated recording rather than the built-in voice.
    func hasRecording(for text: String) -> Bool {
        bundledFile(for: text, speed: .normal, voice: nil) != nil
    }

    /// `voice` is a manifest voice id ("f1") to keep one person's lines in one voice.
    func say(_ text: String, speed: Speed = .normal, voice: String? = nil) async {
        if let url = bundledFile(for: text, speed: speed, voice: voice) {
            await play(url: url)
            return
        }
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        utterance.rate = speed == .slow ? AVSpeechUtteranceDefaultSpeechRate * 0.75 : AVSpeechUtteranceDefaultSpeechRate
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.continuation = continuation
            playbackID = ObjectIdentifier(utterance)
            synthesizer.speak(utterance)
        }
    }

    func play(url: URL, rate: Float = 1) async {
        stop()
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            AppLog.shared.write("Can't play \(url.lastPathComponent)")
            return
        }
        player.delegate = self
        player.enableRate = true
        player.rate = rate
        self.player = player
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.continuation = continuation
            playbackID = ObjectIdentifier(player)
            if !player.play() {
                finish(ObjectIdentifier(player))
            }
        }
    }

    func stop() {
        player?.stop()
        player = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let playbackID {
            finish(playbackID)
        }
    }

    private func finish(_ id: ObjectIdentifier) {
        guard id == playbackID else { return }
        playbackID = nil
        continuation?.resume()
        continuation = nil
    }

    private func bundledFile(for text: String, speed: Speed, voice: String?) -> URL? {
        guard let manifest, let audioDirectory,
              let name = manifest.file(for: text, speed: speed, preferring: voice)
        else { return nil }
        return audioDirectory.appendingPathComponent(name)
    }
}

extension AudioService: AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor in self.finish(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finish(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finish(id) }
    }
}
