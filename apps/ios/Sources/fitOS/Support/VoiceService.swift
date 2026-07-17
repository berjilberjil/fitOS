import Foundation
import Speech
import AVFoundation

/// On-device speech transcription via the Speech framework — the native
/// equivalent of the web app's browser SpeechRecognition.
@MainActor
final class VoiceService: ObservableObject {
    enum Status: Equatable { case idle, listening, denied, unavailable }

    @Published var transcript = ""
    @Published var status: Status = .idle

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN")) ?? SFSpeechRecognizer()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()
    /// Prevents double `removeTap` crashes (stop is called from recognition final + UI Done).
    private var hasTap = false

    /// Ask for speech + microphone permission.
    func requestAuth() async -> Bool {
        let speechOK: Bool = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        guard speechOK else { return false }
        return await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { cont.resume(returning: $0) }
        }
    }

    func start() {
        // Always tear down first so re-start / redo never double-installs a tap.
        stop()
        guard let recognizer, recognizer.isAvailable else { status = .unavailable; return }
        transcript = ""
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                req.append(buffer)
            }
            hasTap = true
            engine.prepare()
            try engine.start()
            status = .listening

            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    Task { @MainActor in self.transcript = text }
                }
                if error != nil || (result?.isFinal ?? false) {
                    Task { @MainActor in self.stop() }
                }
            }
        } catch {
            stop()
            status = .unavailable
        }
    }

    /// Idempotent — safe to call multiple times.
    func stop() {
        if engine.isRunning {
            engine.stop()
        }
        if hasTap {
            engine.inputNode.removeTap(onBus: 0)
            hasTap = false
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        if status == .listening { status = .idle }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
