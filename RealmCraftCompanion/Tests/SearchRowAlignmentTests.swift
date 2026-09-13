import AppKit
import SwiftUI

private struct SearchAlignmentScene: View {
    let english: Bool
    let block: Bool
    let accessory: Bool
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Color.clear.frame(height: CompanionLayout.brandHeaderHeight)
                CompanionSearchRow(horizontalInset: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass").frame(width: 24, height: 28)
                        TextField("global-search", text: .constant("")).textFieldStyle(.roundedBorder)
                        Image(systemName: "line.3.horizontal.decrease.circle").frame(width: 28, height: 28)
                    }
                }
                Spacer()
            }.frame(width: 250)
            Divider()
            VStack(spacing: 0) {
                CompanionPageHeader(title: english ? "Worlds & backups" : "Welten & Sicherungen") {
                    Button(english ? "Import backup…" : "Sicherung importieren …") {}
                    Button(english ? "Backup from device" : "Vom Gerät sichern") {}.buttonStyle(CompanionButtonStyle(prominent: true))
                }
                .environment(\.companionPageGuidance, CompanionPageGuidance(purpose: english ? "Organize your saved worlds." : "Organisiere deine gesicherten Welten.", openHelp: {}))
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        CompanionSearchRow {
                            HStack(spacing: 6) {
                                TextField("local-search", text: .constant("")).textFieldStyle(.roundedBorder)
                                if accessory { Image(systemName: "line.3.horizontal.decrease.circle").frame(width: 28, height: 28) }
                            }
                        }
                        Spacer()
                    }.frame(width: CompanionLayout.librarySidebarWidth)
                    Spacer()
                }
            }
        }.environment(\.companionTheme, CompanionTheme(block: block))
            .buttonStyle(CompanionButtonStyle())
    }
}
private func fields(_ view: NSView) -> [NSTextField] {
    (view as? NSTextField).map { [$0] } ?? view.subviews.flatMap(fields)
}
@main struct SearchRowAlignmentTests {
    static func main() {
        NSApplication.shared.setActivationPolicy(.prohibited)
        var count = 0
        for english in [true, false] {
            for block in [true, false] {
              for accessory in [false, true] {
                let host = NSHostingView(rootView: SearchAlignmentScene(english: english, block: block, accessory: accessory))
                let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1440, height: 900), styleMask: [.borderless], backing: .buffered, defer: false)
                window.contentView = host
                for width in [1440.0, 1080, 1280, 1800, 1080, 1280] {
                    window.setContentSize(NSSize(width: width, height: 900))
                    host.frame = NSRect(x: 0, y: 0, width: width, height: 900)
                    host.layoutSubtreeIfNeeded()
                    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.04))
                    let native = fields(host)
                    guard let global = native.first(where: { $0.placeholderString == "global-search" }),
                          let local = native.first(where: { $0.placeholderString == "local-search" }) else { fatalError("Missing native search controls") }
                    let a = global.convert(global.bounds, to: nil), b = local.convert(local.bounds, to: nil)
                    if width >= 1280 {
                        precondition(abs(a.minY - b.minY) < 1 && abs(a.maxY - b.maxY) < 1, "Misaligned fields: \(a), \(b), width \(width)")
                    } else {
                        precondition(b.maxY <= a.maxY + 1 && b.minY > 0, "Compact header must keep local search visible below its content")
                    }
                    precondition(a.width > 100 && b.width > 150, "Search fields must remain usable")
                    count += 1
                }
                window.contentView = nil
              }
            }
        }
        print("PASS: \(count) native search-field edge checks, DE/EN, both themes and repeated resizing")
    }
}
