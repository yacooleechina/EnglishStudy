import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            AppScreen(title: "English Study", subtitle: "\(appState.words.count) 个单词待练习") {
                GlassPanel {
                    HomeLink(title: "生词本", systemImage: "books.vertical", destination: WordbookView())
                    Divider()
                    HomeLink(title: "导入词书", systemImage: "square.and.arrow.down", destination: VocabularyBooksView())
                    Divider()
                    HomeLink(title: "中文意思", systemImage: "character.book.closed", destination: MeaningQuizView())
                    Divider()
                    HomeLink(title: "发音练习", systemImage: "waveform", destination: PronunciationQuizView())
                    Divider()
                    HomeLink(title: "已归档单词", systemImage: "archivebox", destination: ArchivedWordsView())
                    Divider()
                    HomeLink(title: "设置", systemImage: "gearshape", destination: SettingsView())
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .alert("需要处理", isPresented: Binding(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("好") { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
        .task {
            await appState.syncOnLaunch()
        }
    }
}

private struct HomeLink<Destination: View>: View {
    let title: String
    let systemImage: String
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 34, height: 34)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(AppTheme.muted.opacity(0.5))
            }
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
    }
}
