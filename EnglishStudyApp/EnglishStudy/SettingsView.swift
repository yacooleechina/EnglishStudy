import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showsAuthorization = false

    var body: some View {
        AppScreen(title: "设置", subtitle: "连接欧路 OpenAPI，同步你的生词本。") {
            GlassPanel {
                Label("欧路账号", systemImage: "person.crop.circle")
                    .font(.headline)
                TextField("邮箱", text: $appState.username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(AppTheme.ink)
                    .tint(AppTheme.blue)
                    .padding(14)
                    .background(Color(red: 0.96, green: 0.97, blue: 0.99))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.18), lineWidth: 1.5)
                    }
            }

            GlassPanel {
                Label("OpenAPI 授权", systemImage: "key")
                    .font(.headline)

                HStack(spacing: 10) {
                    Group {
                        if showsAuthorization {
                            TextField("Authorization，例如 NIS xxxxx", text: $appState.authorization)
                        } else {
                            SecureField("Authorization，例如 NIS xxxxx", text: $appState.authorization)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(AppTheme.ink)
                    .tint(AppTheme.blue)

                    Button {
                        showsAuthorization.toggle()
                    } label: {
                        Image(systemName: showsAuthorization ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showsAuthorization ? "隐藏授权" : "显示授权")
                }
                .padding(10)
                .background(Color(red: 0.96, green: 0.97, blue: 0.99))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.18), lineWidth: 1.5)
                }

                Button {
                    appState.saveAuthorization()
                } label: {
                    Label("保存授权", systemImage: "key")
                }
                .buttonStyle(SecondaryPillButtonStyle())

                Button {
                    Task {
                        appState.saveAuthorization()
                        await appState.sync()
                    }
                } label: {
                    Label("保存并同步", systemImage: "arrow.clockwise")
                }
                .buttonStyle(PrimaryPillButtonStyle())

                Text("请从欧路 OpenAPI 授权页面获取 token。不要在这里填写欧路登录密码。")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
            }

            HStack(spacing: 12) {
                StatTile(title: "分组", value: "\(appState.categories.count)", icon: "folder", tint: AppTheme.green)
                StatTile(title: "单词", value: "\(appState.words.count)", icon: "textformat.abc", tint: AppTheme.blue)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
