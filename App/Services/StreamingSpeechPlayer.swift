import AVFoundation

/// Plays Gemini TTS while it streams in: 24 kHz mono 16-bit little-endian PCM (the stream calls it
/// "audio/l16", but the bytes are little-endian), converted to float buffers for an
/// AVAudioPlayerNode. Playback starts once a quarter second is buffered; the TTS stream runs about
/// twice as fast as real time, so it doesn't run dry after that. The last reply is kept, so it can be
/// played again at normal speed or slowed (pitch kept) without another request.
@MainActor
final class StreamingSpeechPlayer {
    nonisolated static let sampleRate = 24_000.0

    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    private let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: StreamingSpeechPlayer.sampleRate,
                                       channels: 1, interleaved: false)!
    private var isSetUp = false
    /// Bumped on every stop, so completion callbacks from earlier buffers are ignored.
    private var generation = 0
    private var pending = 0
    private var bufferedFrames: AVAudioFramePosition = 0
    private var inputEnded = true
    private var started = false
    /// A byte left over when a chunk ended in the middle of a sample.
    private var leftover: UInt8?
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var lastReply: [AVAudioPCMBuffer] = []
    /// The engine wouldn't start for this reply: further audio is refused until the next one.
    private var broken = false
    nonisolated(unsafe) private var configurationObserver: NSObjectProtocol?

    deinit {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
        }
    }

    var hasReply: Bool { !lastReply.isEmpty }

    /// Starts a new reply; whatever was playing stops. `rate` 0.75 is the course's slow speed.
    func beginReply(rate: Float) {
        reset()
        broken = false
        lastReply = []
        timePitch.rate = rate
    }

    /// Adds PCM from the stream and plays it as soon as enough is buffered. False when the audio
    /// engine can't play: the caller says the sentence another way.
    @discardableResult
    func append(_ data: Data) -> Bool {
        guard !broken else { return false }
        guard let buffer = makeBuffer(data) else { return true }
        lastReply.append(buffer)
        schedule(buffer)
        if !started, Double(bufferedFrames) / Self.sampleRate >= 0.25 {
            play()
        }
        return !broken
    }

    /// More audio for the same reply after `endReply` and a pause (a sentence said by the phone's voice).
    func continueReply() {
        inputEnded = false
        bufferedFrames = 0
    }

    /// No more audio for this reply.
    func endReply() {
        inputEnded = true
        if !started, pending > 0 {
            play()
        }
        finishIfDone()
    }

    /// Returns when everything scheduled has been heard, or playback was stopped.
    func waitUntilDone() async {
        guard !(inputEnded && pending == 0) else { return }
        // An interruption (a call, a route change) stops the engine without the buffers'
        // callbacks: give up a little after the audio should have ended rather than wait forever.
        let seconds = Double(bufferedFrames) / Self.sampleRate / Double(max(timePitch.rate, 0.25)) + 3
        let current = generation
        let watchdog = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled, self.generation == current, !self.waiters.isEmpty else { return }
            AppLog.shared.write("RolePlay: playback never reported its end; stopped it")
            self.stop()
        }
        await withCheckedContinuation { waiters.append($0) }
        watchdog.cancel()
    }

    /// Plays the last reply again.
    func replay(rate: Float) async {
        let buffers = lastReply
        guard !buffers.isEmpty else { return }
        reset()
        broken = false
        timePitch.rate = rate
        for buffer in buffers {
            schedule(buffer)
        }
        endReply()
        await waitUntilDone()
    }

    func stop() {
        generation += 1
        if isSetUp {
            node.stop()
        }
        pending = 0
        inputEnded = true
        started = false
        resumeWaiters()
        if engine.isRunning {
            engine.pause()
        }
    }

    // MARK: Private

    private func reset() {
        stop()
        inputEnded = false
        bufferedFrames = 0
        leftover = nil
    }

    private func setUpIfNeeded() {
        guard !isSetUp else { return }
        engine.attach(node)
        engine.attach(timePitch)
        engine.connect(node, to: timePitch, format: format)
        engine.connect(timePitch, to: engine.mainMixerNode, format: format)
        engine.prepare()
        isSetUp = true
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.engineStopped() }
        }
    }

    /// A route change (headphones, a call) stopped the engine and dropped what was scheduled. End
    /// this playback now rather than wait for the watchdog; 再听 plays the reply again, and the
    /// next play restarts the engine.
    private func engineStopped() {
        guard pending > 0 || !waiters.isEmpty else { return }
        AppLog.shared.write("RolePlay: the audio route changed during playback; stopped it")
        stop()
    }

    private func schedule(_ buffer: AVAudioPCMBuffer) {
        setUpIfNeeded()
        let current = generation
        pending += 1
        bufferedFrames += AVAudioFramePosition(buffer.frameLength)
        node.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in self?.played(generation: current) }
        }
    }

    private func played(generation finished: Int) {
        guard finished == generation else { return }
        pending = max(0, pending - 1)
        finishIfDone()
    }

    private func finishIfDone() {
        guard inputEnded, pending == 0 else { return }
        started = false
        resumeWaiters()
        if engine.isRunning {
            engine.pause()
        }
    }

    private func resumeWaiters() {
        let waiting = waiters
        waiters = []
        for waiter in waiting {
            waiter.resume()
        }
    }

    private func play() {
        do {
            if !engine.isRunning {
                // A call or another app may have deactivated the session since launch.
                try AVAudioSession.sharedInstance().setActive(true)
                try engine.start()
            }
            node.play()
            started = true
        } catch {
            AppLog.shared.write("RolePlay: audio engine didn't start: \(error)")
            broken = true
            stop()
        }
    }

    private func makeBuffer(_ data: Data) -> AVAudioPCMBuffer? {
        var bytes = [UInt8]()
        bytes.reserveCapacity(data.count + 1)
        if let leftover {
            bytes.append(leftover)
            self.leftover = nil
        }
        bytes.append(contentsOf: data)
        if bytes.count % 2 == 1 {
            leftover = bytes.removeLast()
        }
        let frames = bytes.count / 2
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
              let channel = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(frames)
        for index in 0..<frames {
            let sample = Int16(bitPattern: UInt16(bytes[2 * index]) | UInt16(bytes[2 * index + 1]) << 8)
            channel[index] = Float(sample) / 32_768
        }
        return buffer
    }
}
