import AVFoundation
import Observation

/// Records the learner for 跟读. Recordings stay on the phone in Caches, one file per phrase,
/// replaced each time.
@MainActor
@Observable
final class Recorder {
    private(set) var recordingID: String?
    private(set) var recordedIDs: Set<String> = []
    @ObservationIgnored private var recorder: AVAudioRecorder?
    private let directory: URL

    init() {
        directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func url(for id: String) -> URL {
        directory.appendingPathComponent("\(id).m4a")
    }

    func hasRecording(_ id: String) -> Bool {
        recordedIDs.contains(id) || FileManager.default.fileExists(atPath: url(for: id).path)
    }

    /// Starts recording; false when microphone access is denied or recording can't start.
    func start(_ id: String) async -> Bool {
        stop()
        guard await AVAudioApplication.requestRecordPermission() else {
            AppLog.shared.write("Microphone access denied")
            return false
        }
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        do {
            let recorder = try AVAudioRecorder(url: url(for: id), settings: settings)
            guard recorder.record() else { return false }
            self.recorder = recorder
            recordingID = id
            return true
        } catch {
            AppLog.shared.write("Recording failed: \(error)")
            return false
        }
    }

    func stop() {
        guard let recorder, let recordingID else { return }
        recorder.stop()
        self.recorder = nil
        self.recordingID = nil
        recordedIDs.insert(recordingID)
    }
}
