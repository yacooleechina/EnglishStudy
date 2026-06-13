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
                    Text("浏览欧路生词和已导入词书，并开始练习。")
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
                        Label("还没有可学习的单词", systemImage: "tray")
                            .font(.headline)
                        Text("可以同步欧路生词本，或从首页导入内置词书。")
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
                ForEach(appState.practiceCategories) { category in
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

struct ArchivedWordsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("已归档单词")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("累计正确 3 次的单词会保存在这里。")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }

                StatTile(
                    title: "已掌握",
                    value: "\(appState.archivedWords.count)",
                    icon: "archivebox.fill",
                    tint: AppTheme.green
                )

                if appState.archivedWords.isEmpty {
                    GlassPanel {
                        Label("还没有归档单词", systemImage: "archivebox")
                            .font(.headline)
                        Text("在中文或发音练习中累计正确 3 次后，单词会自动归档。")
                            .foregroundStyle(AppTheme.muted)
                    }
                } else {
                    ForEach(appState.archivedWords) { item in
                        NavigationLink {
                            WordDetailView(item: item, showsWordbooks: true)
                        } label: {
                            GlassPanel {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 7) {
                                        Text(item.word)
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(AppTheme.ink)
                                        if let explanation = item.displayExplanation {
                                            Text(explanation)
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.muted)
                                                .lineLimit(2)
                                        }
                                        let wordbookNames = appState.wordbookNames(for: item)
                                        Label(
                                            wordbookNames.isEmpty
                                                ? "未标记词书"
                                                : wordbookNames.joined(separator: " · "),
                                            systemImage: "books.vertical"
                                        )
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.blue)
                                        .lineLimit(2)
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
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
