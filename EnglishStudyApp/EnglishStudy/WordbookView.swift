import SwiftUI

struct WordbookView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("生词本")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("从欧路同步后，在这里浏览和开始练习。")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }

                HStack(spacing: 12) {
                    StatTile(title: "分组", value: "\(appState.categories.count)", icon: "folder", tint: AppTheme.green)
                    StatTile(title: "单词", value: "\(appState.words.count)", icon: "textformat.abc", tint: AppTheme.blue)
                }

                toolbar

                if appState.words.isEmpty {
                    GlassPanel {
                        Label("还没有同步单词", systemImage: "tray")
                            .font(.headline)
                        Text("在设置中填写欧路 Authorization 后同步生词本。")
                            .foregroundStyle(AppTheme.muted)
                    }
                } else {
                    ForEach(appState.words) { item in
                        NavigationLink {
                            WordDetailView(item: item)
                        } label: {
                            GlassPanel {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 7) {
                                        Text(item.word)
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(AppTheme.ink)
                                        if let exp = item.displayExplanation {
                                            Text(exp)
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.muted)
                                                .lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
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
        .scrollIndicators(.visible)
        .scrollBounceBehavior(.basedOnSize)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if appState.words.isEmpty, !appState.authorization.isEmpty {
                await appState.sync()
            }
        }
    }

    private var toolbar: some View {
        GlassPanel {
            HStack(spacing: 12) {
            Picker("分组", selection: $appState.selectedCategoryId) {
                Text("全部").tag(String?.none)
                ForEach(appState.categories) { category in
                    Text(category.name).tag(Optional(category.id))
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.ink)
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task { await appState.sync() }
            } label: {
                if appState.isLoading {
                    ProgressView()
                } else {
                    Label("同步", systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .frame(maxWidth: 150)
            .disabled(appState.isLoading)
            }
        }
        .onChange(of: appState.selectedCategoryId) { _, _ in
            Task { await appState.sync(refreshCategories: false) }
        }
    }
}
