import AVFoundation
import CoreMedia
import Foundation
import Observation
import Speech

/// Offline Italian recognition for 开口说, used only to judge whether the words came across, never
/// to score pronunciation. Prefers SpeechAnalyzer with SpeechTranscriber; devices without that
/// model fall back to DictationTranscriber. When neither handles Italian, the app keeps recording
/// comparison and self-assessment.
@MainActor
@Observable
final class SpeechService {
    enum Engine: String {
        case transcriber = "SpeechTranscriber"
        case dictation = "DictationTranscriber"
    }

    enum Status: Equatable {
        case checking
        case ready(Engine)
        /// Italian is supported but its model isn't on the phone yet.
        case needsDownload(Engine)
        case downloading(Engine, fraction: Double)
        /// Neither transcriber handles Italian on this device.
        case unsupported
        case failed(String)
    }

    enum Permission {
        case notAsked, allowed, denied
    }

    static let italian = Locale(identifier: "it_IT")

    private(set) var status = Status.checking
    private(set) var permission = Permission.notAsked
    private(set) var engine: Engine?
    /// The supported locale closest to it_IT, as the transcriber names it.
    private(set) var locale: Locale?

    init() {
        permission = Self.currentPermission()
    }

    /// Whether a recording can be transcribed right now.
    var isUsable: Bool {
        unavailableReason == nil
    }

    var statusText: String {
        switch status {
        case .checking: "检查中…"
        case .ready: permission == .denied ? "不可用：没有语音识别权限" : "可用"
        case .needsDownload: "需要下载意大利语模型"
        case .downloading(_, let fraction): "正在下载 \(Int((fraction * 100).rounded()))%"
        case .unsupported: "不支持"
        case .failed(let message): "出错：\(message)"
        }
    }

    var permissionText: String {
        switch permission {
        case .notAsked: "还没问过（第一次开口说时会问）"
        case .allowed: "已允许"
        case .denied: "已拒绝（设置 → Mamma mia! → 语音识别）"
        }
    }

    /// Why a recording won't be transcribed, shown next to the attempt; nil when it will be.
    var unavailableReason: String? {
        if case .ready = status, permission == .denied {
            return "没有语音识别权限（设置 → Mamma mia! → 语音识别），这次听录音自己对比。"
        }
        switch status {
        case .ready: return nil
        case .checking: return "离线识别还没准备好，这次听录音自己对比。"
        case .needsDownload: return "还没下载意大利语识别模型，这次听录音自己对比。可以在「今日 → 诊断、日志与备份」里下载。"
        case .downloading: return "识别模型还在下载，这次听录音自己对比。"
        case .unsupported: return "这台手机不能离线识别意大利语，听录音和示范对比，自己判断。"
        case .failed(let message): return "离线识别出错（\(message)），这次听录音自己对比。"
        }
    }

    // MARK: Availability

    /// Picks the transcriber and checks whether its Italian model is installed.
    func refresh() async {
        if case .downloading = status { return }
        permission = Self.currentPermission()
        status = .checking
        for candidate in [Engine.transcriber, .dictation] {
            if candidate == .transcriber, !SpeechTranscriber.isAvailable {
                AppLog.shared.write("Speech: SpeechTranscriber isn't available on this device")
                continue
            }
            let supported = await Self.supportedLocales(for: candidate)
            guard let match = Self.closestItalian(in: supported) else {
                AppLog.shared.write("Speech: \(candidate.rawValue) supports \(supported.count) locales, no Italian")
                continue
            }
            let module = Self.makeModule(candidate, locale: match)
            let assets = await AssetInventory.status(forModules: [module])
            if assets == .unsupported {
                AppLog.shared.write("Speech: \(candidate.rawValue) assets for \(Self.tag(match)) are unsupported")
                continue
            }
            let installed = await Self.installedLocales(for: candidate).contains { Self.tag($0) == Self.tag(match) }
            engine = candidate
            locale = match
            let ready = installed || assets == .installed
            if ready {
                // A model another app downloaded still needs this app's reservation; a download
                // request reserves on its own.
                do {
                    try await AssetInventory.reserve(locale: match)
                } catch {
                    AppLog.shared.write("Speech: couldn't reserve \(Self.tag(match)): \(error)")
                }
            }
            status = ready ? .ready(candidate) : .needsDownload(candidate)
            AppLog.shared.write("Speech: \(candidate.rawValue) \(Self.tag(match)), installed \(installed), assets \(assets), permission \(permission)")
            return
        }
        engine = nil
        locale = nil
        status = .unsupported
        AppLog.shared.write("Speech: no offline Italian recognition on this device")
    }

    /// Asks AssetInventory for the Italian model of the chosen transcriber and waits for it.
    func downloadModel() async {
        guard let engine, let locale else { return }
        switch status {
        case .needsDownload, .failed: break
        default: return
        }
        var watcher: Task<Void, Never>?
        do {
            let module = Self.makeModule(engine, locale: locale)
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
                AppLog.shared.write("Speech: downloading the \(Self.tag(locale)) model for \(engine.rawValue)")
                status = .downloading(engine, fraction: 0)
                let progress = request.progress
                watcher = Task { [weak self] in
                    while !Task.isCancelled {
                        self?.status = .downloading(engine, fraction: progress.fractionCompleted)
                        try? await Task.sleep(for: .milliseconds(300))
                    }
                }
                try await request.downloadAndInstall()
                watcher?.cancel()
                AppLog.shared.write("Speech: model download finished")
            }
            status = .checking
            await refresh()
        } catch {
            watcher?.cancel()
            AppLog.shared.write("Speech: model download failed: \(error)")
            status = .failed("下载失败：\(error.localizedDescription)")
        }
    }

    // MARK: Permission

    /// Picks up a change made in Settings since the last check.
    func refreshPermission() {
        permission = Self.currentPermission()
    }

    /// Shows the speech-recognition prompt the first time, and only when recognition could run.
    func requestPermissionIfNeeded() async {
        refreshPermission()
        guard permission == .notAsked else { return }
        switch status {
        case .ready, .needsDownload, .downloading: break
        default: return
        }
        let answer = await Self.askForAuthorization()
        permission = Self.permission(from: answer)
        AppLog.shared.write("Speech: recognition permission \(permission)")
    }

    // MARK: Transcription

    /// What the recognizer heard in a recording; nil with the reason when it can't run.
    func recognize(_ url: URL) async -> (transcript: String?, note: String?) {
        if let reason = unavailableReason {
            return (nil, reason)
        }
        do {
            let started = Date.now
            let transcript = try await transcribe(url)
            AppLog.shared.write("Speech: heard \"\(transcript)\" in \(String(format: "%.1f", Date.now.timeIntervalSince(started)))s")
            return (transcript, nil)
        } catch {
            AppLog.shared.write("Speech: transcription failed: \(error)")
            return (nil, "这次没能识别（\(error.localizedDescription)），听录音自己对比。")
        }
    }

    /// Lets the analyzer read the recording file itself first. Buffers must already be in a format
    /// the analyzer supports, and the docs don't say whether the file path converts, so when that
    /// fails or hears nothing the audio is converted to the analyzer's format and fed as a buffer.
    private func transcribe(_ url: URL) async throws -> String {
        guard let engine, let locale else { throw CocoaError(.featureUnsupported) }
        var heardNothing = false
        do {
            let text = try await Self.transcribe(url, engine: engine, locale: locale, converting: false)
            if !text.isEmpty { return text }
            heardNothing = true
            AppLog.shared.write("Speech: nothing heard reading the file directly; retrying with converted audio")
        } catch {
            AppLog.shared.write("Speech: reading the file directly failed (\(error)); retrying with converted audio")
        }
        do {
            return try await Self.transcribe(url, engine: engine, locale: locale, converting: true)
        } catch let error where heardNothing {
            // The first pass worked and the recording really was silent (or too short to convert).
            AppLog.shared.write("Speech: converted retry failed too (\(error)); treating it as silence")
            return ""
        }
    }

    private static func transcribe(_ url: URL, engine: Engine, locale: Locale, converting: Bool) async throws -> String {
        let file = try AVAudioFile(forReading: url)
        switch engine {
        case .transcriber:
            let module = SpeechTranscriber(locale: locale, preset: .transcription)
            return try await analyze(file, converting: converting, with: module, results: module.results) {
                String($0.text.characters)
            }
        case .dictation:
            let module = DictationTranscriber(locale: locale, preset: .shortDictation)
            return try await analyze(file, converting: converting, with: module, results: module.results) {
                String($0.text.characters)
            }
        }
    }

    /// Runs the whole recording through a fresh analyzer and joins the finalized results.
    private static func analyze<Results: AsyncSequence>(
        _ file: AVAudioFile,
        converting: Bool,
        with module: any SpeechModule,
        results: Results,
        text: @escaping (Results.Element) -> String
    ) async throws -> String {
        // Collect results while the analyzer runs; the sequence ends when analysis finishes.
        let collector = Task {
            var parts: [String] = []
            for try await result in results {
                parts.append(text(result))
            }
            return parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let analyzer = SpeechAnalyzer(modules: [module])
        do {
            let lastSample: CMTime?
            if converting {
                guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [module]) else {
                    throw CocoaError(.featureUnsupported)
                }
                let buffer = try convert(file, to: format)
                let (inputs, builder) = AsyncStream.makeStream(of: AnalyzerInput.self)
                builder.yield(AnalyzerInput(buffer: buffer))
                builder.finish()
                lastSample = try await analyzer.analyzeSequence(inputs)
            } else {
                lastSample = try await analyzer.analyzeSequence(from: file)
            }
            if let lastSample {
                try await analyzer.finalizeAndFinish(through: lastSample)
            } else {
                await analyzer.cancelAndFinishNow()
            }
        } catch {
            await analyzer.cancelAndFinishNow()
            collector.cancel()
            throw error
        }
        return try await collector.value
    }

    /// Decodes the whole recording into one buffer in `format`, the one the analyzer asked for.
    nonisolated private static func convert(_ file: AVAudioFile, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let source = file.processingFormat
        guard file.length > 0,
              let input = AVAudioPCMBuffer(pcmFormat: source, frameCapacity: AVAudioFrameCount(file.length))
        else { throw CocoaError(.fileReadCorruptFile) }
        try file.read(into: input)
        guard let converter = AVAudioConverter(from: source, to: format) else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        let frames = (Double(input.frameLength) * format.sampleRate / source.sampleRate).rounded(.up)
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames) + 4096) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let supplied = ConverterInput(input)
        var conversionError: NSError?
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            if supplied.done {
                inputStatus.pointee = .endOfStream
                return nil
            }
            supplied.done = true
            inputStatus.pointee = .haveData
            return supplied.buffer
        }
        if status == .error {
            throw conversionError ?? CocoaError(.fileReadCorruptFile)
        }
        return output
    }

    // MARK: Helpers

    private static func makeModule(_ engine: Engine, locale: Locale) -> any SpeechModule {
        switch engine {
        case .transcriber: SpeechTranscriber(locale: locale, preset: .transcription)
        case .dictation: DictationTranscriber(locale: locale, preset: .shortDictation)
        }
    }

    private static func supportedLocales(for engine: Engine) async -> [Locale] {
        switch engine {
        case .transcriber: await SpeechTranscriber.supportedLocales
        case .dictation: await DictationTranscriber.supportedLocales
        }
    }

    private static func installedLocales(for engine: Engine) async -> [Locale] {
        switch engine {
        case .transcriber: await SpeechTranscriber.installedLocales
        case .dictation: await DictationTranscriber.installedLocales
        }
    }

    /// it-IT when supported, otherwise another Italian variant (it-CH).
    private static func closestItalian(in locales: [Locale]) -> Locale? {
        locales.first { tag($0) == tag(italian) }
            ?? locales.first { $0.language.languageCode?.identifier == "it" }
    }

    private static func tag(_ locale: Locale) -> String {
        locale.identifier(.bcp47)
    }

    private static func currentPermission() -> Permission {
        permission(from: SFSpeechRecognizer.authorizationStatus())
    }

    private static func permission(from status: SFSpeechRecognizerAuthorizationStatus) -> Permission {
        switch status {
        case .authorized: .allowed
        case .denied, .restricted: .denied
        case .notDetermined: .notAsked
        @unknown default: .notAsked
        }
    }

    /// Nonisolated so the callback, which arrives on a background queue, isn't treated as main-actor code.
    nonisolated private static func askForAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { @Sendable status in
                continuation.resume(returning: status)
            }
        }
    }
}

/// The one input buffer of a conversion and whether the converter has had it yet. The converter
/// calls its input block synchronously inside convert(to:error:withInputFrom:), so the block's
/// @Sendable requirement doesn't mean the buffer is shared across threads.
private final class ConverterInput: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
    var done = false

    init(_ buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }
}
