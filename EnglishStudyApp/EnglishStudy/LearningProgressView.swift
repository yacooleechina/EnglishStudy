import SwiftUI

struct LearningProgressView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("学习成果")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("按词书查看已经正确完成的中文意思和发音练习。")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }

                let sections = appState.learningProgressSections()
                if sections.isEmpty {
                    GlassPanel {
                        Label("还没有可展示的词书", systemImage: "chart.bar.doc.horizontal")
                            .font(.headline)
                        Text("请先同步欧路生词本或导入内置词书。")
                            .foregroundStyle(AppTheme.muted)
                    }
                } else {
                    ForEach(sections) { section in
                        NavigationLink {
                            LearningProgressDetailView(section: section)
                        } label: {
                            GlassPanel {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(section.title)
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.ink)
                                        HStack(spacing: 16) {
                                            Label(
                                                "中文 \(section.meaningWords.count)",
                                                systemImage: "character.book.closed"
                                            )
                                            Label(
                                                "发音 \(section.pronunciationWords.count)",
                                                systemImage: "waveform"
                                            )
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.muted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(AppTheme.muted)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LearningProgressDetailView: View {
    let section: LearningProgressSection
    @State private var mode = PracticeKind.meaning

    private var displayedWords: [StudyWord] {
        mode == .meaning ? section.meaningWords : section.pronunciationWords
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text(section.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Picker("成果类型", selection: $mode) {
                    Text("中文意思 \(section.meaningWords.count)")
                        .tag(PracticeKind.meaning)
                    Text("发音练习 \(section.pronunciationWords.count)")
                        .tag(PracticeKind.pronunciation)
                }
                .pickerStyle(.segmented)

                if displayedWords.isEmpty {
                    GlassPanel {
                        Label("还没有完成记录", systemImage: "checkmark.circle")
                            .font(.headline)
                    }
                } else {
                    ForEach(displayedWords) { item in
                        NavigationLink {
                            WordDetailView(item: item)
                        } label: {
                            GlassPanel {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.word)
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.ink)
                                        if let explanation = item.displayExplanation {
                                            Text(explanation)
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.muted)
                                                .lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
