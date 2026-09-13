import SwiftUI
import AppKit

// Synthetic presentation-only fixtures. No Model, Library or device is created.
@main struct RenderDetailAlignment {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let suite = "realmcraft.detail-layout-tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for en in [false, true] { for block in [false, true] { for width in [420.0, 1000.0] {
            defaults.set(en ? "en" : "de", forKey: "appLanguage")
            defaults.set(block ? "block" : "classic", forKey: "companionSkin")
            for hasPreview in [false, true] {
                let root = VStack(alignment: .leading, spacing: 0) {
                    CompanionPageHeader(title: en ? "Worlds & backups" : "Welten & Sicherungen") {
                        Button(en ? "Import backup…" : "Sicherung importieren …") {}
                        Button(en ? "Backup from device" : "Vom Gerät sichern") {}
                            .buttonStyle(CompanionButtonStyle(prominent: true)).disabled(true)
                    }.environment(\.companionPageGuidance, CompanionPageGuidance(
                        purpose: en ? "Back up, restore and organize your Quest worlds." : "Quest-Welten sichern, wiederherstellen und organisieren.", openHelp: {}))
                    Divider()
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            Text(en ? "Synthetic backup with a deliberately long title" : "Synthetische Sicherung mit einem bewusst langen Titel")
                                .font(CompanionLayout.sectionTitle).fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Button {} label: { Image(systemName: "trash") }
                                .buttonStyle(CompanionButtonStyle(width: CompanionLayout.actionHeight))
                        }
                        Text("2026-01-01 12:00").font(.callout).foregroundStyle(.secondary)
                        CompanionDetailOverview(hasPreview: hasPreview) {
                            Rectangle().fill(Color.teal.opacity(0.4)).aspectRatio(4 / 3, contentMode: .fit)
                                .overlay(Image(systemName: "cube").font(.system(size: 48)))
                        } facts: {
                            VStack(alignment: .leading, spacing: 12) {
                                CompanionDetailFact(title: en ? "World" : "Welt", value: "synthetic-world", icon: "globe.europe.africa")
                                CompanionDetailFact(title: en ? "Files" : "Dateien", value: "1,024", icon: "doc.on.doc")
                                CompanionDetailFact(title: en ? "Size" : "Größe", value: "12 MB", icon: "externaldrive")
                            }
                        }
                    }.padding(CompanionLayout.pageInset)
                    Spacer(minLength: 0)
                }.frame(width: width, height: 800, alignment: .topLeading)
                    .companionAppearance().defaultAppStorage(defaults)
                let host = NSHostingView(rootView: root)
                host.frame = NSRect(x: 0, y: 0, width: width, height: 800)
                let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
                window.contentView = host
                host.layoutSubtreeIfNeeded()
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
                precondition(host.fittingSize.width <= width + 1, "Detail must fit the offered width")
                let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                host.cacheDisplay(in: host.bounds, to: bitmap)
                let name = "detail-\(en ? "en" : "de")-\(block ? "block" : "classic")-\(Int(width))-\(hasPreview ? "preview" : "no-preview").png"
                try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
                print("PASS \(name)")
                window.contentView = nil
            }
        }}}
    }
}
