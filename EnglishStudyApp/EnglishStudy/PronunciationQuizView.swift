import SwiftUI

struct PronunciationQuizView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var speech = SpeechEvaluator()
    let item: StudyWord?
    @State private var result: PronunciationResult?
    @State private var showsMeaning = false
    @State private var isPreparingRecording = false
    @State private var archiveMessage: String?

    init(item: StudyWord? = nil) {
        self.item = item
    }

    var body: some View {
        AppScreen(title: "发音练习", subtitle: "先听标准发音，再录音朗读，系统会识别并反馈。") {
            if let item = item ?? appState.currentWord {
                WordHero(word: item.word, caption: "听、读、校正")

                Text("已正确 \(appState.successfulChecks(for: item))/3 次")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)

                if let archiveMessage {
                    GlassPanel {
                        Label("已归档", systemImage: "archivebox.fill")
                            .font(.headline)
                            .foregroundStyle(AppTheme.green)
                        Text(archiveMessage)
                            .foregroundStyle(AppTheme.muted)
                    }
                }

                GlassPanel {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("识别结果")
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)
                            Text(speech.transcript.isEmpty ? "点击麦克风朗读这个单词" : speech.transcript)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(speech.transcript.isEmpty ? AppTheme.muted : AppTheme.ink)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Button {
                            speech.speakCorrection(for: item.word)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3)
                                .frame(width: 46, height: 46)
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(Circle())
                    }
                }

                Button {
                    withAnimation(.snappy) {
                        showsMeaning.toggle()
                    }
                } label: {
                    Label(showsMeaning ? "隐藏中文意思" : "显示中文意思", systemImage: showsMeaning ? "eye.slash" : "character.book.closed")
                }
                .buttonStyle(SecondaryPillButtonStyle())

                if showsMeaning {
                    GlassPanel {
                        Text("中文意思")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                        Text(item.displayExplanation ?? "暂无释义")
                            .foregroundStyle(AppTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button {
                    Task {
                        if speech.isRecording {
                            speech.stop()
                        } else {
                            guard !isPreparingRecording else { return }
                            isPreparingRecording = true
                            await speech.requestPermissions()
                            isPreparingRecording = false
                            result = nil
                            archiveMessage = nil
                            do {
                                try speech.start { transcript in
                                    evaluatePronunciation(item: item, transcript: transcript)
                                }
                            } catch {
                                appState.errorMessage = error.localizedDescription
                            }
                        }
                    }
                } label: {
                    Label(recordButtonTitle, systemImage: speech.isRecording ? "waveform" : "mic.fill")
                }
                .buttonStyle(PrimaryPillButtonStyle(tint: speech.isRecording ? AppTheme.red : AppTheme.blue))
                .disabled(isPreparingRecording)

                if self.item == nil {
                    Button {
                        speech.stop()
                        result = nil
                        showsMeaning = false
                        archiveMessage = nil
                        appState.nextWord()
                    } label: {
                        Label("下一个", systemImage: "arrow.right.circle")
                    }
                    .buttonStyle(SecondaryPillButtonStyle())
                }

                if let result {
                    GlassPanel {
                        Label(result.grade.rawValue, systemImage: result.grade.isPassing ? "checkmark.seal" : "xmark.seal")
                            .font(.headline)
                            .foregroundStyle(result.grade.isPassing ? AppTheme.green : AppTheme.red)
                        Text(result.explanation)
                            .foregroundStyle(AppTheme.muted)
                        Text("识别结果：\(result.transcript)")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.muted)
                        if !result.grade.isPassing {
                            Button {
                                speech.speakCorrection(for: item.word)
                            } label: {
                                Label("播放标准读音", systemImage: "speaker.wave.2")
                            }
                            .buttonStyle(SecondaryPillButtonStyle())
                        }
                    }
                }
            } else {
                GlassPanel {
                    Label("没有可朗读的单词", systemImage: "waveform.badge.magnifyingglass")
                        .font(.headline)
                    Text("请先同步欧路生词本。")
                        .foregroundStyle(AppTheme.muted)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            speech.stopAll()
        }
    }

    private var recordButtonTitle: String {
        if isPreparingRecording { return "准备录音" }
        return speech.isRecording ? "正在识别…" : "开始录音"
    }

    private func evaluatePronunciation(item: StudyWord, transcript: String) {
        let evaluation = QuizEngine.evaluatePronunciation(target: item.word, transcript: transcript)
        result = evaluation
        if evaluation.grade == .correct {
            Task {
                let archived = await appState.recordCorrectCheck(for: item, kind: .pronunciation)
                if archived {
                    result = nil
                    archiveMessage = "\(item.word) 已累计正确 3 次，并移出中文和发音练习。"
                }
            }
        } else if !evaluation.grade.isPassing {
            speech.speakCorrection(for: item.word)
        }
    }
}
