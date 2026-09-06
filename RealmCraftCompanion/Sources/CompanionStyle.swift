import SwiftUI

enum CompanionLayout {
    static let pageInset: CGFloat = 28
    static let panelInset: CGFloat = 20
    static let headerHeight: CGFloat = 64
    static let actionHeight: CGFloat = 32
    static let primaryActionWidth: CGFloat = 180
    static let actionSpacing: CGFloat = 12
    static let sourceWidth: CGFloat = 440
    static let searchWidth: CGFloat = 260
    static let illustratedSidebarWidth: CGFloat = 280
    static let detailTitle: Font = .system(size: 24, weight: .semibold)
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
private struct CompanionHeaderKey: EnvironmentKey {
    static let defaultValue = false
}
private struct CompanionThemeKey: EnvironmentKey {
    static let defaultValue = CompanionTheme()
}
extension EnvironmentValues {
    var companionHeader: Bool {
        get { self[CompanionHeaderKey.self] }
        set { self[CompanionHeaderKey.self] = newValue }
    }
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
    var width: CGFloat? = nil
    @Environment(\.companionHeader) private var inHeader
    @Environment(\.companionTheme) private var theme
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .semibold))
            .lineLimit(inHeader ? 1 : nil)
            .padding(.horizontal, 12)
            .padding(.vertical, inHeader || width != nil ? 0 : 7)
            .frame(width: width ?? (inHeader && prominent ? CompanionLayout.primaryActionWidth : nil), height: inHeader || width != nil ? CompanionLayout.actionHeight : nil)
            .frame(minHeight: CompanionLayout.actionHeight)
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
    private let actions: Actions
    private let menuContent: AnyView?
    @AppStorage("appLanguage") private var language = "en"
    @AppStorage("companionSkin") private var skin = "block"
    @Environment(\.companionSettingsItems) private var settingsItems
    private var english: Bool { language == "en" }

    init(title: String, @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.actions = actions()
        self.menuContent = nil
    }
    init<Items: View>(title: String, @ViewBuilder actions: () -> Actions, @ViewBuilder menu: () -> Items) {
        self.title = title
        self.actions = actions()
        self.menuContent = AnyView(menu())
    }
    var body: some View {
        HStack(spacing: CompanionLayout.actionSpacing) {
            Text(title).font(.system(size: 22, weight: .semibold)).lineLimit(1).layoutPriority(1)
            Spacer(minLength: 24)
            actions.environment(\.companionHeader, true)
            Menu {
                if let menuContent { menuContent; Divider() }
                Text("Version \(AppInfo.version)")
                Link(destination: AppInfo.repositoryURL) { Label(english ? "Project on GitHub" : "Projekt auf GitHub", systemImage: "arrow.up.right.square") }
                Menu {
                    if let settingsItems { settingsItems }
                    else {
                        Picker(english ? "Appearance" : "Optik", selection: $skin) {
                            Text(english ? "Block world" : "Blockwelt").tag("block")
                            Text(english ? "Classic" : "Klassisch").tag("classic")
                        }
                        Picker("Language / Sprache", selection: $language) {
                            Text("Deutsch").tag("de"); Text("English").tag("en")
                        }
                    }
                } label: { Label(english ? "General settings" : "Allgemeine Einstellungen", systemImage: "gearshape") }
            } label: { Image(systemName: "ellipsis.circle") }
                .companionOverflow()
                .accessibilityLabel(english ? "Actions and settings" : "Aktionen und Einstellungen")
                .accessibilityIdentifier("companion.page.menu")
        }.padding(.horizontal, CompanionLayout.pageInset).frame(height: CompanionLayout.headerHeight)
            .frame(maxWidth: .infinity)
    }
}

private struct CompanionSettingsItemsKey: EnvironmentKey {
    static let defaultValue: AnyView? = nil
}
extension EnvironmentValues {
    var companionSettingsItems: AnyView? {
        get { self[CompanionSettingsItemsKey.self] }
        set { self[CompanionSettingsItemsKey.self] = newValue }
    }
}

// Keep menus the same size as adjacent toolbar controls, including their hit area.
extension View {
    func companionOverflow() -> some View {
        self.menuStyle(.borderlessButton).fixedSize()
            .frame(width: CompanionLayout.actionHeight, height: CompanionLayout.actionHeight)
            .contentShape(Rectangle())
    }
}

// Short activity messages keep their lane; longer errors can grow without clipping.
struct CompanionStatusLane<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(spacing: 8) { content(); Spacer(minLength: 0) }
            .font(.caption).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}
