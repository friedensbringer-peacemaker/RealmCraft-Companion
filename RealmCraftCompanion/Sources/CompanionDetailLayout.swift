import SwiftUI

struct CompanionDetailFact: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(.secondary)
                .labelStyle(CompanionAlignedLabelStyle())
            Text(value).font(.system(size: 14, weight: .semibold)).monospacedDigit()
                .textSelection(.enabled).padding(.leading, 28)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A stable icon column keeps headings and supporting text on the same grid.
struct CompanionAlignedLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.icon.frame(width: 20)
            configuration.title
        }
    }
}

/// Preview and facts stay together; narrow detail panes stack without clipping.
struct CompanionDetailOverview<Preview: View, Facts: View>: View {
    var hasPreview = true
    @ViewBuilder let preview: Preview
    @ViewBuilder let facts: Facts
    var body: some View {
        if !hasPreview {
            facts.frame(maxWidth: .infinity, alignment: .leading)
        } else { ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: CompanionLayout.panelInset) {
                preview.frame(width: 256)
                facts.frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: CompanionLayout.panelInset) {
                preview.frame(maxWidth: 320, alignment: .leading)
                facts.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.frame(maxWidth: .infinity, alignment: .leading) }
    }
}
