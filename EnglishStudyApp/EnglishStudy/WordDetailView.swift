import SwiftUI

struct WordDetailView: View {
    let item: StudyWord
    @StateObject private var speech = SpeechEvaluator()

    var body: some View {
        AppScreen(title: item.word, subtitle: item.displayExplanation != nil ? "单词详情和复习入口" : "这个单词还没有同步到中文释义。") {
            WordHero(word: item.word, caption: "生词本")

            HStack(spacing: 12) {
                Button {
                    speech.speakCorrection(for: item.word)
                } label: {
                    Label("播放发音", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(PrimaryPillButtonStyle())

                NavigationLink {
                    PronunciationQuizView(item: item)
                } label: {
                    Label("练发音", systemImage: "waveform")
                }
                .buttonStyle(SecondaryPillButtonStyle())
            }

            if let exp = item.displayExplanation {
                detailSection(title: "中文释义", icon: "character.book.closed", text: exp)
            }

            if let contextLine = item.contextLine, !contextLine.isEmpty {
                detailSection(title: "上下文", icon: "quote.opening", text: contextLine)
            }

            GlassPanel {
                VStack(spacing: 12) {
                    metadataRow(title: "加入时间", value: item.addTime ?? "无")
                    metadataRow(title: "星级", value: item.star.map(String.init) ?? "无")
                    metadataRow(title: "分组数", value: "\(item.categoryIds?.count ?? 0)")
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            speech.stopAll()
        }
    }

    private func detailSection(title: String, icon: String, text: String) -> some View {
        GlassPanel {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Text(text)
                .font(.body)
                .foregroundStyle(AppTheme.muted)
                .textSelection(.enabled)
        }
    }

    private func metadataRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.muted)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}
