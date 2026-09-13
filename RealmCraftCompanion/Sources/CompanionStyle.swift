import SwiftUI
import AppKit

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
    static let librarySidebarWidth: CGFloat = 260
    static let sectionTitle: Font = .system(size: 20, weight: .semibold)
    static let detailTitle: Font = .system(size: 20, weight: .semibold)
    static let readingWidth: CGFloat = 760
    static let formLabelWidth: CGFloat = 140
}

/// Fixed label column across rows; compact panes stack labels above controls.
struct CompanionField<Control: View>: View {
    let title: String
    @ViewBuilder var control: () -> Control
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title).fixedSize(horizontal: false, vertical: true)
                    .frame(width: CompanionLayout.formLabelWidth, alignment: .leading)
                control().frame(minWidth: 0, maxWidth: .infinity)
            }.frame(minWidth: CompanionLayout.formLabelWidth + 132)
            VStack(alignment: .leading, spacing: 8) {
                Text(title).fixedSize(horizontal: false, vertical: true)
                control().frame(minWidth: 0, maxWidth: .infinity)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
extension View {
    func companionField(_ title: String) -> some View {
        CompanionField(title: title) { self.labelsHidden() }
    }
}

/// Native popup with an explicit flexible size; SwiftUI's menu Picker otherwise
/// keeps the width of its longest option even inside a wider field frame.
struct CompanionPopup<Value: Hashable>: NSViewRepresentable {
    let title: String
    @Binding var selection: Value
    let options: [(Value, String)]
    @Environment(\.isEnabled) private var enabled

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSPopUpButton {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.setContentHuggingPriority(.defaultLow, for: .horizontal)
        popup.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        popup.font = .systemFont(ofSize: 13)
        popup.cell?.lineBreakMode = .byTruncatingMiddle
        popup.target = context.coordinator
        popup.action = #selector(Coordinator.choose(_:))
        return popup
    }
    func updateNSView(_ popup: NSPopUpButton, context: Context) {
        context.coordinator.parent = self
        synchronize(popup)
    }
    func synchronize(_ popup: NSPopUpButton) {
        if popup.itemTitles != options.map(\.1) {
            popup.removeAllItems()
            // addItem(withTitle:) coalesces duplicate titles; distinct values must
            // remain independently selectable even when their display names match.
            for (index, option) in options.enumerated() {
                let item = NSMenuItem(title: option.1, action: nil, keyEquivalent: "")
                item.tag = index
                popup.menu?.addItem(item)
            }
        }
        popup.selectItem(at: options.firstIndex { $0.0 == selection } ?? -1)
        popup.isEnabled = enabled && !options.isEmpty
        popup.setAccessibilityLabel(title)
        popup.toolTip = options.first { $0.0 == selection }?.1
    }
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSPopUpButton, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 220, height: CompanionLayout.actionHeight)
    }
    final class Coordinator: NSObject {
        var parent: CompanionPopup
        init(_ parent: CompanionPopup) { self.parent = parent }
        @objc func choose(_ popup: NSPopUpButton) {
            let index = popup.indexOfSelectedItem
            guard popup.isEnabled, parent.options.indices.contains(index) else { return }
            parent.selection = parent.options[index].0
            // A guarded binding may reject the transition (e.g. Cancel in a
            // dirty-draft prompt). Restore the actual selection immediately.
            parent.synchronize(popup)
        }
    }
}

/// Secondary explanations remain available without dominating the task's entry point.
struct CompanionDetails<Content: View>: View {
    let title: String
    private let content: Content
    @State private var expanded: Bool
    init(_ title: String, initiallyExpanded: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
        _expanded = State(initialValue: initiallyExpanded)
    }
    var body: some View {
        DisclosureGroup(title, isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 12) { content }
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: CompanionLayout.readingWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
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
            .lineLimit(inHeader ? 2 : nil)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, inHeader || width != nil ? 0 : 7)
            .frame(width: width ?? (inHeader ? CompanionLayout.primaryActionWidth : nil), height: inHeader || width != nil ? CompanionLayout.actionHeight : nil)
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
    private let compact: Bool
    private let actions: Actions
    private let menuContent: AnyView?
    @AppStorage("appLanguage") private var language = "en"
    @AppStorage("companionSkin") private var skin = "block"
    @Environment(\.companionSettingsItems) private var settingsItems
    @Environment(\.companionPageGuidance) private var guidance
    private var english: Bool { language == "en" }

    init(title: String, compact: Bool = true, @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.compact = compact
        self.actions = actions()
        self.menuContent = nil
    }
    init<Items: View>(title: String, compact: Bool = true, @ViewBuilder actions: () -> Actions, @ViewBuilder menu: () -> Items) {
        self.title = title
        self.compact = compact
        self.actions = actions()
        self.menuContent = AnyView(menu())
    }
    private var heading: some View {
        Text(title).font(.system(size: 22, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
    }
    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: CompanionLayout.actionSpacing) {
                heading.fixedSize()
                Spacer(minLength: 24)
                alignedActions
                if compact { helpButton }
                overflow
            }
            VStack(alignment: .leading, spacing: 10) {
                ViewThatFits(in: .horizontal) {
                    HStack { heading; Spacer(minLength: 8); if compact { helpButton }; overflow }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack { heading; Spacer(minLength: 8); overflow }
                        if compact { helpButton }
                    }
                }
                ScrollView(.horizontal) {
                    HStack(spacing: CompanionLayout.actionSpacing) {
                        alignedActions
                    }.fixedSize()
                }
            }
        }
        if let guidance {
            HStack(alignment: .top, spacing: 12) {
                Text(guidance.purpose).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                if !compact { helpButton }
            }
        }
      }.padding(.horizontal, CompanionLayout.pageInset).padding(.vertical, compact ? 8 : 12)
            .frame(minHeight: CompanionLayout.headerHeight).frame(maxWidth: .infinity)
    }
    private var alignedActions: some View {
        HStack(spacing: CompanionLayout.actionSpacing) { actions }
            .environment(\.companionHeader, true).fixedSize()
            .background(GeometryReader { geometry in
                Color.clear.preference(key: CompanionHeaderActionBounds.self, value: geometry.frame(in: .global))
            })
    }
    @ViewBuilder private var helpButton: some View {
        if let guidance {
            Button(action: guidance.openHelp) { Label(english ? "Help" : "Hilfe", systemImage: "questionmark.circle") }
                .environment(\.companionHeader, true)
                .fixedSize().help(english ? "Help for this page" : "Hilfe zu dieser Seite")
                .accessibilityIdentifier("companion.page.help")
        }
    }
    private var overflow: some View {
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
    }
}

struct CompanionPageGuidance {
    let purpose: String
    let openHelp: () -> Void
}
private struct CompanionPageGuidanceKey: EnvironmentKey {
    static let defaultValue: CompanionPageGuidance? = nil
}
private struct CompanionSettingsItemsKey: EnvironmentKey {
    static let defaultValue: AnyView? = nil
}
extension EnvironmentValues {
    var companionPageGuidance: CompanionPageGuidance? {
        get { self[CompanionPageGuidanceKey.self] }
        set { self[CompanionPageGuidanceKey.self] = newValue }
    }
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

enum CompanionNoticeKind {
    case information, warning, error, success
    var symbol: String {
        switch self { case .information: return "info.circle"; case .warning: return "exclamationmark.triangle"; case .error: return "xmark.octagon"; case .success: return "checkmark.circle" }
    }
    var color: Color {
        switch self { case .information: return .secondary; case .warning: return .orange; case .error: return .red; case .success: return .green }
    }
}
struct CompanionNotice: View {
    let message: String
    let kind: CompanionNoticeKind
    var body: some View {
        Label(message, systemImage: kind.symbol).font(.caption).foregroundStyle(kind.color)
            .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
    }
}
