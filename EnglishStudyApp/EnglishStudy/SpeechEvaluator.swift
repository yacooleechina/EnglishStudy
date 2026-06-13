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
    private var activeSessionID: UUID?

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

    func start(expectedWord: String, onCompletion: @escaping (String) -> Void) throws {
        stop()
        transcript = ""
        completion = onCompletion
        didComplete = false
        let sessionID = UUID()
        activeSessionID = sessionID

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .confirmation
        let normalizedWord = expectedWord.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedWord.isEmpty {
            request.contextualStrings = [normalizedWord]
        }
        if recognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw SpeechEvaluatorError.unavailableAudioInput
        }
        if hasInputTap {
            inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format,
            block: Self.makeAudioTapHandler(request: request)
        )
        hasInputTap = true

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        scheduleTimeout()

        task = recognizer?.recognitionTask(
            with: request,
            resultHandler: Self.makeRecognitionHandler(owner: self, sessionID: sessionID)
        )
    }

    func stop() {
        cleanupRecording()
        completion = nil
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

        activeSessionID = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        silenceTask?.cancel()
        silenceTask = nil

        if let audioEngine {
            if hasInputTap {
                audioEngine.inputNode.removeTap(onBus: 0)
                hasInputTap = false
            }
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine.reset()
        }
        audioEngine = nil

        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil

        if wasUsingRecordingResources {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        isRecording = false
    }

    nonisolated private static func makeAudioTapHandler(
        request: SFSpeechAudioBufferRecognitionRequest
    ) -> AVAudioNodeTapBlock {
        { buffer, _ in
            guard buffer.frameLength > 0 else { return }
            let buffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
            guard buffers.contains(where: {
                $0.mData != nil && $0.mDataByteSize > 0
            }) else {
                return
            }
            request.append(buffer)
        }
    }

    nonisolated private static func makeRecognitionHandler(
        owner: SpeechEvaluator,
        sessionID: UUID
    ) -> (SFSpeechRecognitionResult?, Error?) -> Void {
        { [weak owner] result, error in
            let recognizedText = result?.bestTranscription.formattedString
            let shouldFinish = error != nil || result?.isFinal == true
            Task { @MainActor [weak owner] in
                owner?.receiveRecognitionUpdate(
                    recognizedText: recognizedText,
                    shouldFinish: shouldFinish,
                    sessionID: sessionID
                )
            }
        }
    }

    private func receiveRecognitionUpdate(
        recognizedText: String?,
        shouldFinish: Bool,
        sessionID: UUID
    ) {
        guard activeSessionID == sessionID else { return }
        if let recognizedText {
            transcript = recognizedText
            if !recognizedText.isEmpty {
                scheduleSilenceFinish()
            }
        }
        if shouldFinish {
            finishRecognition()
        }
    }

    func resetTranscript() {
        stop()
        transcript = ""
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
