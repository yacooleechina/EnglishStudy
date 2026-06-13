import SwiftUI

struct VocabularyBooksView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        AppScreen(title: "导入词书", subtitle: "按需加入本地生词本，导入后可直接浏览和练习。") {
            ForEach(BuiltinVocabularyBook.allCases) { book in
                GlassPanel {
                    HStack(spacing: 14) {
                        Image(systemName: book.systemImage)
                            .font(.title2)
                            .foregroundStyle(AppTheme.blue)
                            .frame(width: 42, height: 42)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)
                            Text("\(book.wordCount) 个单词")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.muted)
                        }

                        Spacer()

                        if appState.isVocabularyBookImported(book) {
                            Button {
                                appState.removeVocabularyBook(book)
                            } label: {
                                Image(systemName: "trash")
                                    .frame(width: 42, height: 42)
                            }
                            .buttonStyle(.bordered)
                            .tint(AppTheme.red)
                            .accessibilityLabel("移除\(book.title)")
                        } else {
                            Button {
                                appState.importVocabularyBook(book)
                            } label: {
                                Label("导入", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(PrimaryPillButtonStyle())
                            .frame(maxWidth: 120)
                        }
                    }
                }
            }

            Text("词表与中文释义来自 ECDICT（MIT License）。词书保存在本机，不会批量上传到欧路；学习归档仍会同步到欧路。")
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
