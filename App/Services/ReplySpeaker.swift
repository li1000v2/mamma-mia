import Foundation
import MammaCore

/// Speaks one role-play reply sentence by sentence while it is still being written. Each sentence
/// goes to Gemini TTS as soon as the chunker hands it over (at most two requests in flight), and
/// its audio is played in order as it streams in, after the filler has finished. A sentence whose
/// speech fails is said with the phone's own Italian voice instead, so the reply is never lost.
/// A refusal (401/403/404) stops every further speech request at once.
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
    private var cancelled = false

    /// When the first audio of the reply was scheduled, for the latency log.
    private(set) var firstAudio: Date?
    /// The TTS model refused (the reply itself was fine): no more speech requests; the rest of the
    /// reply is said with the phone's voice.
    private(set) var refusal: GeminiFailure?
    /// Some sentence was said with the phone's voice, so the stored audio isn't the whole reply.
    private(set) var usedPhoneVoice = false

    /// `voiceName` nil: no Gemini speech for this reply, the phone's voice says it.
    init(client: GeminiClient, voiceName: String?, player: StreamingSpeechPlayer, audio: AudioService,
         rate: Float, after filler: Task<Void, Never>?) {
        self.client = client
        self.voiceName = voiceName
        self.player = player
        self.audio = audio
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
        guard !cancelled else { return }
        let (audioStream, audioInput) = AsyncThrowingStream.makeStream(of: Data.self)
        if let voiceName, refusal == nil {
            let previous = requests.count >= 2 ? requests[requests.count - 2] : nil
            let client = client
            requests.append(Task { [weak self] in
                await previous?.value // two requests in flight at most
                guard let self, !self.cancelled, self.refusal == nil, !Task.isCancelled else {
                    audioInput.finish(throwing: CancellationError())
                    return
                }
                do {
                    let body = GeminiRequest.speech(sentence, voiceName: voiceName)
                    for try await event in client.stream(model: GeminiModels.speech, body: body) {
                        if case .audio(let data, _) = event {
                            audioInput.yield(data)
                        }
                    }
                    audioInput.finish()
                } catch let failure as GeminiFailure where failure.stopsSession {
                    self.refuse(failure)
                    audioInput.finish(throwing: failure)
                } catch {
                    audioInput.finish(throwing: error)
                }
            })
        } else {
            // No Gemini speech: the playback loop says it with the phone's voice.
            audioInput.finish(throwing: CancellationError())
        }
        segmentInput.yield(Segment(text: sentence, audio: audioStream))
    }

    /// The reply is complete: returns when all of it has been heard.
    func finish() async {
        segmentInput.finish()
        await playback?.value
    }

    func cancel() {
        cancelled = true
        segmentInput.finish()
        for request in requests {
            request.cancel()
        }
        playback?.cancel()
        player.stop()
        audio.stop()
    }

    /// The first refusal cancels the other request in flight; later sentences don't ask at all.
    private func refuse(_ failure: GeminiFailure) {
        guard refusal == nil else { return }
        refusal = failure
        AppLog.shared.write("RolePlay: speech refused, \(failure)")
        for request in requests {
            request.cancel()
        }
    }

    private func play(rate: Float) async {
        player.beginReply(rate: rate)
        for await segment in segments {
            if Task.isCancelled { return }
            var heard = false
            do {
                for try await chunk in segment.audio {
                    if Task.isCancelled { return }
                    guard player.append(chunk) else {
                        // The audio engine won't start: the phone's voice says the sentence instead.
                        heard = false
                        break
                    }
                    firstAudio = firstAudio ?? .now
                    heard = true
                }
            } catch is CancellationError {
                // No Gemini speech for this sentence: the phone's voice below.
            } catch let failure as GeminiFailure {
                if !failure.stopsSession { // a refusal was logged when it happened
                    AppLog.shared.write("RolePlay: speech failed, \(failure)")
                }
            } catch {
                AppLog.shared.write("RolePlay: speech failed, \(error)")
            }
            if !heard, !Task.isCancelled {
                // Let what's already playing finish, then say this sentence with the phone's voice.
                player.endReply()
                await player.waitUntilDone()
                firstAudio = firstAudio ?? .now
                usedPhoneVoice = true
                await audio.sayWithPhoneVoice(segment.text, speed: rate < 1 ? .slow : .normal)
                player.continueReply()
            }
        }
        player.endReply()
        await player.waitUntilDone()
    }
}
