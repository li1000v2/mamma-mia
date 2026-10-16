import Foundation
import MammaCore

/// Speaks one role-play reply sentence by sentence while it is still being written. Each sentence
/// goes to Gemini TTS as soon as the chunker hands it over (at most two requests in flight), and
/// its audio is played in order as it streams in, after the filler has finished. A sentence whose
/// speech fails is said with the phone's own Italian voice instead, so the reply is never lost.
@MainActor
final class ReplySpeaker {
    private struct Segment {
        let text: String
        let audio: AsyncThrowingStream<Data, Error>
    }

    private let client: GeminiClient
    private let voiceName: String?
    private let player: StreamingSpeechPlayer
    private let audio: AudioService
    private let segments: AsyncStream<Segment>
    private let segmentInput: AsyncStream<Segment>.Continuation
    private var requests: [Task<Void, Never>] = []
    private var playback: Task<Void, Never>?
    private var systemVoiceOnly: Bool

    /// When the first audio of the reply was scheduled, for the latency log.
    private(set) var firstAudio: Date?
    /// A refusal from the TTS model (the reply itself was fine); the rest of the session uses the phone's voice.
    private(set) var refusal: GeminiFailure?

    /// `voiceName` nil: Gemini speech is off for this session, use the phone's voice.
    init(client: GeminiClient, voiceName: String?, player: StreamingSpeechPlayer, audio: AudioService,
         rate: Float, after filler: Task<Void, Never>?) {
        self.client = client
        self.voiceName = voiceName
        self.player = player
        self.audio = audio
        systemVoiceOnly = voiceName == nil
        let (stream, input) = AsyncStream.makeStream(of: Segment.self)
        segments = stream
        segmentInput = input
        playback = Task { [weak self] in
            await filler?.value
            await self?.play(rate: rate)
        }
    }

    /// A finished sentence to speak.
    func say(_ sentence: String) {
        let (audioStream, audioInput) = AsyncThrowingStream.makeStream(of: Data.self)
        if systemVoiceOnly {
            audioInput.finish(throwing: CancellationError())
        } else if let voiceName {
            let previous = requests.count >= 2 ? requests[requests.count - 2] : nil
            let client = client
            requests.append(Task {
                await previous?.value // two requests in flight at most
                do {
                    let body = GeminiRequest.speech(sentence, voiceName: voiceName)
                    for try await event in client.stream(model: GeminiModels.speech, body: body) {
                        if case .audio(let data, _) = event {
                            audioInput.yield(data)
                        }
                    }
                    audioInput.finish()
                } catch {
                    audioInput.finish(throwing: error)
                }
            })
        }
        segmentInput.yield(Segment(text: sentence, audio: audioStream))
    }

    /// The reply is complete: returns when all of it has been heard.
    func finish() async {
        segmentInput.finish()
        await playback?.value
    }

    func cancel() {
        segmentInput.finish()
        for request in requests {
            request.cancel()
        }
        playback?.cancel()
        player.stop()
        audio.stop()
    }

    private func play(rate: Float) async {
        player.beginReply(rate: rate)
        for await segment in segments {
            if Task.isCancelled { return }
            var heard = false
            do {
                for try await chunk in segment.audio {
                    if Task.isCancelled { return }
                    firstAudio = firstAudio ?? .now
                    heard = true
                    player.append(chunk)
                }
            } catch is CancellationError {
                // Gemini speech is off: the phone's voice below.
            } catch let failure as GeminiFailure {
                AppLog.shared.write("RolePlay: speech failed, \(failure)")
                if failure.stopsSession {
                    refusal = failure
                    systemVoiceOnly = true
                }
            } catch {
                AppLog.shared.write("RolePlay: speech failed, \(error)")
            }
            if !heard, !Task.isCancelled {
                // Let what's already playing finish, then say this sentence with the phone's voice.
                player.endReply()
                await player.waitUntilDone()
                firstAudio = firstAudio ?? .now
                await audio.sayWithPhoneVoice(segment.text, speed: rate < 1 ? .slow : .normal)
                player.continueReply()
            }
        }
        player.endReply()
        await player.waitUntilDone()
    }
}
