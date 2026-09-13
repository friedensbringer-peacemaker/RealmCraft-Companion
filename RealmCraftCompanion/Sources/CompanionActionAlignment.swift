import SwiftUI

struct CompanionHeaderActionBounds: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if !next.isEmpty { value = next }
    }
}
private struct CompanionHeaderActionFrameKey: EnvironmentKey {
    static var defaultValue: CGRect = .zero
}
extension EnvironmentValues {
    var companionHeaderActionFrame: CGRect {
        get { self[CompanionHeaderActionFrameKey.self] }
        set { self[CompanionHeaderActionFrameKey.self] = newValue }
    }
}
private struct CompanionActionAlignmentScope: ViewModifier {
    @State private var actionFrame = CGRect.zero
    func body(content: Content) -> some View {
        content.environment(\.companionHeaderActionFrame, actionFrame)
            .onPreferenceChange(CompanionHeaderActionBounds.self) { actionFrame = $0 }
    }
}
private struct CompanionActionAligned: ViewModifier {
    @Environment(\.companionHeaderActionFrame) private var actionFrame
    @State private var bounds = CGRect.zero
    private var width: CGFloat? {
        guard !actionFrame.isEmpty, !bounds.isEmpty else { return nil }
        return min(bounds.width, max(CompanionLayout.primaryActionWidth, actionFrame.maxX - bounds.minX))
    }
    func body(content: Content) -> some View {
        content.frame(width: width, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GeometryReader { geometry in
                Color.clear.onChange(of: geometry.frame(in: .global), initial: true) { _, value in bounds = value }
            })
    }
}
extension View {
    func companionActionAlignmentScope() -> some View { modifier(CompanionActionAlignmentScope()) }
    func companionActionAligned() -> some View { modifier(CompanionActionAligned()) }
}

/// Equal-width segments preserve the caller's binding, including draft guards.
struct CompanionEqualSegments<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [(Value, String)]
    @Environment(\.companionTheme) private var theme
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { value, label in
                Button { selection = value } label: {
                    Text(label).font(.system(size: 13)).lineLimit(2).multilineTextAlignment(.center)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: CompanionLayout.actionHeight)
                        .foregroundStyle(selection == value ? Color.black : Color.primary)
                        .background(selection == value ? theme.accent : Color.clear, in: RoundedRectangle(cornerRadius: theme.radius))
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).help(label)
                    .accessibilityAddTraits(selection == value ? [.isSelected] : [])
            }
        }.background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: theme.radius))
            .opacity(enabled ? 1 : 0.45)
            .accessibilityElement(children: .contain).accessibilityLabel(title)
    }
}
