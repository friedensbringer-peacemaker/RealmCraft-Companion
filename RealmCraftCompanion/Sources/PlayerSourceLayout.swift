import SwiftUI

/// The action's actual bounds also follow the shared header's compact fallback.
struct PlayerActionBounds: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if !next.isEmpty { value = next }
    }
}

struct PlayerSourceLayout<Source: View, Detail: View>: View {
    let title: String
    let actionFrame: CGRect
    @ViewBuilder var source: () -> Source
    @ViewBuilder var detail: () -> Detail

    private var end: CGFloat {
        max(CompanionLayout.primaryActionWidth, actionFrame.maxX - CompanionLayout.pageInset)
    }
    var body: some View {
        ViewThatFits(in: .horizontal) {
            rows(width: end)
            rows(width: CompanionLayout.primaryActionWidth)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func rows(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if width >= CompanionLayout.formLabelWidth + 24 + CompanionLayout.primaryActionWidth {
                HStack(spacing: 12) {
                    Text(title).frame(width: CompanionLayout.formLabelWidth, alignment: .leading)
                    Spacer(minLength: 0)
                    source().frame(width: CompanionLayout.primaryActionWidth)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                    source().frame(width: CompanionLayout.primaryActionWidth)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            detail()
        }.frame(width: width, alignment: .leading)
    }
}

/// Two equal hit areas; intrinsic label widths never change the split.
struct PlayerSourceToggle: View {
    @Binding var quest: Bool
    let deviceTitle: String
    let savegameTitle: String
    @Environment(\.companionTheme) private var theme
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        HStack(spacing: 0) {
            choice(true, title: deviceTitle)
            choice(false, title: savegameTitle)
        }.background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: theme.radius))
            .opacity(enabled ? 1 : 0.45)
    }
    private func choice(_ value: Bool, title: String) -> some View {
        Button { quest = value } label: {
            Text(title).font(.system(size: 13)).lineLimit(1)
                .frame(width: CompanionLayout.primaryActionWidth / 2, height: CompanionLayout.actionHeight)
                .foregroundStyle(quest == value ? Color.black : Color.primary)
                .background(quest == value ? theme.accent : Color.clear, in: RoundedRectangle(cornerRadius: theme.radius))
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityAddTraits(quest == value ? [.isSelected] : [])
    }
}
