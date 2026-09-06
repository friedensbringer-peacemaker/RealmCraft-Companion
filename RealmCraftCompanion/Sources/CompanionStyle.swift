import SwiftUI

enum CompanionLayout {
    static let pageInset: CGFloat = 28
    static let panelInset: CGFloat = 20
}

struct CompanionTheme {
    var block = true
    var accent: Color { block ? Color(red: 0.66, green: 0.81, blue: 0.43) : .teal }
    var background: Color { block ? Color(red: 0.075, green: 0.10, blue: 0.09) : Color(nsColor: .windowBackgroundColor) }
    var surface: Color { block ? Color(red: 0.12, green: 0.15, blue: 0.13) : Color(nsColor: .controlBackgroundColor) }
    var border: Color { block ? Color(red: 0.27, green: 0.32, blue: 0.25) : Color.primary.opacity(0.12) }
    var radius: CGFloat { block ? 3 : 12 }
    static let sidebarWidth: CGFloat = 220
}
private struct CompanionThemeKey: EnvironmentKey {
    static let defaultValue = CompanionTheme()
}
extension EnvironmentValues {
    var companionTheme: CompanionTheme {
        get { self[CompanionThemeKey.self] }
        set { self[CompanionThemeKey.self] = newValue }
    }
}
private struct CompanionAppearance: ViewModifier {
    @AppStorage("companionSkin") private var skin = "block"
    private var theme: CompanionTheme { CompanionTheme(block: skin != "classic") }
    func body(content: Content) -> some View {
        content
            .environment(\.companionTheme, theme)
            .tint(theme.accent)
            .accentColor(theme.accent)
            .buttonStyle(CompanionButtonStyle())
            .groupBoxStyle(CompanionGroupBoxStyle())
            .background(theme.background)
            .preferredColorScheme(theme.block ? .dark : nil)
    }
}
private struct CompanionPanel: ViewModifier {
    @Environment(\.companionTheme) private var theme
    func body(content: Content) -> some View {
        content.background(theme.surface, in: RoundedRectangle(cornerRadius: theme.radius))
            .overlay(RoundedRectangle(cornerRadius: theme.radius).strokeBorder(theme.border.opacity(0.3), lineWidth: 1))
    }
}
extension View {
    func companionAppearance() -> some View { modifier(CompanionAppearance()) }
    func companionPanel() -> some View { modifier(CompanionPanel()) }
}
struct CompanionButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.companionTheme) private var theme
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 12).padding(.vertical, 7).frame(minHeight: 30)
            .foregroundStyle(prominent ? Color.black : Color.primary)
            .background(prominent ? theme.accent : Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: theme.radius))
            .overlay(RoundedRectangle(cornerRadius: theme.radius).strokeBorder(prominent ? theme.accent.opacity(0.25) : Color.clear, lineWidth: 1))
            .brightness(configuration.isPressed ? -0.10 : 0)
            .opacity(enabled ? 1 : 0.45)
    }
}
struct CompanionGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            configuration.label
            configuration.content
        }.frame(maxWidth: .infinity, alignment: .leading).padding(CompanionLayout.panelInset).companionPanel()
    }
}
struct BlockEmblem: View {
    @Environment(\.companionTheme) private var theme
    var body: some View {
        Image(systemName: "cube.fill").font(.system(size: 24, weight: .bold))
            .foregroundStyle(theme.accent).frame(width: 44, height: 44)
            .background(theme.accent.opacity(0.12))
            .overlay(Rectangle().strokeBorder(theme.border, lineWidth: 2))
    }
}

struct CompanionPageHeader<Actions: View>: View {
    let title: String
    @ViewBuilder var actions: () -> Actions
    var body: some View {
        HStack(spacing: 16) {
            Text(title).font(.system(size: 22, weight: .semibold))
            Spacer(minLength: 24)
            actions()
        }.padding(.horizontal, CompanionLayout.pageInset).frame(height: 64)
    }
}
