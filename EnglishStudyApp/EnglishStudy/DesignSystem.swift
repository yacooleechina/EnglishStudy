import SwiftUI

enum AppTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.96, green: 0.97, blue: 0.99),
            Color(red: 0.90, green: 0.94, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ink = Color(red: 0.08, green: 0.10, blue: 0.15)
    static let muted = Color(red: 0.30, green: 0.34, blue: 0.42)
    static let blue = Color(red: 0.08, green: 0.29, blue: 0.88)
    static let green = Color(red: 0.05, green: 0.62, blue: 0.45)
    static let red = Color(red: 0.86, green: 0.22, blue: 0.24)
}

struct AppScreen<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                content
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct GlassPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.07), radius: 12, y: 5)
    }
}

struct PrimaryPillButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.blue
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(minHeight: 48)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .background(isEnabled ? tint.opacity(configuration.isPressed ? 0.80 : 1) : AppTheme.muted)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(1)
    }
}

struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.ink)
            .frame(minHeight: 48)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .background(configuration.isPressed ? Color(red: 0.88, green: 0.90, blue: 0.94) : .white)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
            }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = AppTheme.blue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(tint)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
    }
}

struct WordHero: View {
    let word: String
    let caption: String

    var body: some View {
        VStack(spacing: 10) {
            Text(word)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .minimumScaleFactor(0.55)
                .lineLimit(1)
                .foregroundStyle(.white)
            Text(caption)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 18)
        .background {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.14, blue: 0.24), AppTheme.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: AppTheme.blue.opacity(0.24), radius: 22, y: 12)
    }
}
