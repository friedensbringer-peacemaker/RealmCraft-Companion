import AppKit
import SwiftUI

/// Production sidebar/header, isolated reference catalogs and temporary preferences.
/// This is a rendering check, not a keyboard or complete application acceptance test.
@main struct RenderUsability {
    @MainActor static func main() throws {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let resources = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let catalog = QuickFindCatalog.load(resources: resources)
        let suite = "UsabilityRender-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var checks = 0
        for english in [false, true] {
            for block in [false, true] {
                defaults.set(english ? "en" : "de", forKey: "appLanguage")
                defaults.set(block ? "block" : "classic", forKey: "companionSkin")
                for query in ["", "lever", "no-such-synthetic-query"] {
                    let theme = CompanionTheme(block: block)
                    let view = HStack(spacing: 0) {
                        CompanionSearchSidebar(english: english, focusRequest: .constant(UUID()), catalog: catalog, query: query, open: { _ in false }) {
                            VStack(alignment: .leading, spacing: 18) {
                                Label(english ? "Home" : "Start", systemImage: "square.grid.2x2")
                                Text(english ? "Navigation placeholder · render fixture" : "Navigation-Platzhalter · Renderprobe").font(.caption)
                                Spacer()
                            }.padding()
                        }.padding(.top, 14).frame(width: 250).background(theme.surface)
                        Divider()
                        VStack(spacing: 0) {
                            CompanionPageHeader(title: english ? "Worlds & backups" : "Welten & Sicherungen") {
                                Button(english ? "Import backup…" : "Sicherung importieren …") {}
                                Button(english ? "Backup from device" : "Vom Gerät sichern") {}.buttonStyle(CompanionButtonStyle(prominent: true))
                            }.environment(\.companionPageGuidance, CompanionPageGuidance(purpose: english ? "Back up, restore and organize your Quest worlds." : "Quest-Welten sichern, wiederherstellen und verwalten.", openHelp: {}))
                            Divider()
                            Text(english ? "Isolated UI component preview. No world data loaded." : "Isolierte UI-Komponentenprobe. Keine Weltdaten geladen.").padding()
                            Spacer()
                        }
                    }.frame(width: 1080, height: 700)
                        .environment(\.companionTheme, theme).environment(\.colorScheme, block ? .dark : .light)
                        .defaultAppStorage(defaults).buttonStyle(CompanionButtonStyle())
                        .background(theme.background)
                    // ImageRenderer cannot capture AppKit-backed TextField/List/Menu.
                    // A hidden native host renders those controls without opening the real app.
                    let host = NSHostingView(rootView: view)
                    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1080, height: 700), styleMask: [.borderless], backing: .buffered, defer: false)
                    window.appearance = NSAppearance(named: block ? .darkAqua : .aqua)
                    host.appearance = window.appearance
                    window.contentView = host; host.frame = NSRect(x: 0, y: 0, width: 1080, height: 700)
                    host.layoutSubtreeIfNeeded(); RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
                    guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("Render failed") }
                    host.cacheDisplay(in: host.bounds, to: rep)
                    guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("PNG failed") }
                    let name = "\(english ? "en" : "de")-\(block ? "block" : "classic")-\(query.isEmpty ? "navigation" : query == "lever" ? "results" : "empty").png"
                    try png.write(to: output.appendingPathComponent(name)); checks += 1
                    window.contentView = nil
                }
            }
        }
        print("Usability rendering: \(checks) production sidebar/header samples; navigation body is a labeled fixture")
    }
}
