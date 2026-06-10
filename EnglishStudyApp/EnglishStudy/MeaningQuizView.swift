import SwiftUI

struct MeaningQuizView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var speech = SpeechEvaluator()
    @State private var answer = ""
    @State private var result: MeaningResult?
    @FocusState private var isAnswerFocused: Bool

    var body: some View {
        AppScreen(title: "中文意思", subtitle: "输入中文释义，系统会和欧路释义做匹配。") {
            if let item = appState.currentWord {
                WordHero(word: item.word, caption: "写出中文意思")

                Button {
                    speech.speakCorrection(for: item.word)
                } label: {
                    Label("播放发音", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(SecondaryPillButtonStyle())

                GlassPanel {
                    Text("你的答案")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    TextField("例如：放弃、坚持、扩大", text: $answer, axis: .vertical)
                        .textFieldStyle(.plain)
                        .focused($isAnswerFocused)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                        .tint(AppTheme.blue)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isAnswerFocused ? AppTheme.blue : Color.black.opacity(0.24), lineWidth: 2)
                        }
                        .shadow(color: isAnswerFocused ? AppTheme.blue.opacity(0.16) : .clear, radius: 8)
                }

                HStack {
                    Button {
                        result = QuizEngine.evaluateMeaning(answer: answer, expected: item.exp)
                    } label: {
                        Label("检查", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(PrimaryPillButtonStyle(tint: AppTheme.green))

                    Button {
                        answer = ""
                        result = nil
                        appState.nextWord()
                        isAnswerFocused = true
                    } label: {
                        Label("下一个", systemImage: "arrow.right.circle")
                    }
                    .buttonStyle(SecondaryPillButtonStyle())
                }

                if let result {
                    ResultPanel(
                        title: result.grade.rawValue,
                        detail: result.explanation,
                        systemImage: result.grade.isPassing ? "checkmark.seal" : "xmark.seal",
                        tint: result.grade.isPassing ? AppTheme.green : AppTheme.red
                    )
                    GlassPanel {
                        DisclosureGroup("标准释义") {
                            Text(item.displayExplanation ?? "暂无释义")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            } else {
                GlassPanel {
                    Label("没有可练习的单词", systemImage: "text.badge.plus")
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
}

private struct ResultPanel: View {
    let title: String
    let detail: String
    let systemImage: String
    var tint: Color = AppTheme.blue

    var body: some View {
        GlassPanel {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(detail).font(.subheadline).foregroundStyle(AppTheme.muted)
                }
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
            }
        }
    }
}
