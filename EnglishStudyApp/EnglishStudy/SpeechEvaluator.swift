import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechEvaluator: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var authorizationStatus = SFSpeechRecognizerAuthorizationStatus.notDetermined

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private let synthesizer = AVSpeechSynthesizer()
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var hasInputTap = false
    private var didRequestPermissions = false
    private var timeoutTask: Task<Void, Never>?
    private var silenceTask: Task<Void, Never>?
    private var completion: ((String) -> Void)?
    private var didComplete = false

    func requestPermissions() async {
        guard !didRequestPermissions else { return }
        didRequestPermissions = true

        authorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        if #available(iOS 17.0, *) {
            _ = await AVAudioApplication.requestRecordPermission()
        } else {
            _ = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        }
    }

    func start(onCompletion: @escaping (String) -> Void) throws {
        stop()
        transcript = ""
        completion = onCompletion
        didComplete = false

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw SpeechEvaluatorError.unavailableAudioInput
        }
        if hasInputTap {
            inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            guard buffer.frameLength > 0 else { return }
            request?.append(buffer)
        }
        hasInputTap = true

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        scheduleTimeout()

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                    if !result.bestTranscription.formattedString.isEmpty {
                        self?.scheduleSilenceFinish()
                    }
                }
                if error != nil || result?.isFinal == true {
                    self?.finishRecognition()
                }
            }
        }
    }

    func stop() {
        cleanupRecording()
        completion = nil
        didComplete = false
    }

    private func finishRecognition() {
        guard !didComplete else { return }
        didComplete = true
        let finalTranscript = transcript
        let completion = completion
        cleanupRecording()
        self.completion = nil
        completion?(finalTranscript)
    }

    private func cleanupRecording() {
        let wasUsingRecordingResources = audioEngine != nil || request != nil || task != nil || hasInputTap || isRecording

        timeoutTask?.cancel()
        timeoutTask = nil
        silenceTask?.cancel()
        silenceTask = nil

        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil

        if let audioEngine {
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            if hasInputTap {
                audioEngine.inputNode.removeTap(onBus: 0)
                hasInputTap = false
            }
        }
        audioEngine = nil

        if wasUsingRecordingResources {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        isRecording = false
    }

    private func scheduleTimeout() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            self?.finishRecognition()
        }
    }

    private func scheduleSilenceFinish() {
        silenceTask?.cancel()
        silenceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            self?.finishRecognition()
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func stopAll() {
        stop()
        stopSpeaking()
    }

    func speakCorrection(for word: String) {
        let normalizedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedWord.isEmpty else { return }

        if isRecording || audioEngine != nil || request != nil || task != nil {
            stop()
        }

        let utterance = AVSpeechUtterance(string: normalizedWord)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}

enum SpeechEvaluatorError: LocalizedError {
    case unavailableAudioInput

    var errorDescription: String? {
        "当前没有可用的麦克风输入。"
    }
}
