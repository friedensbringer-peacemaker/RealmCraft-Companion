import AppKit
import SwiftUI

@main struct RenderCraftingBrowse {
    @MainActor static func main() throws {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let catalog = try CraftingCatalog.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let suite = "CraftingBrowseQA-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for en in [false, true] {
            for block in [false, true] {
                defaults.set(en ? "en" : "de", forKey: "appLanguage")
                defaults.set(block ? "block" : "classic", forKey: "companionSkin")
                let view = CraftingView(language: en ? "en" : "de", catalog: catalog, initialItem: "oak_boat", initialQuery: "boat", planURL: output.appendingPathComponent("unused-plan.json"), agentLibrary: CraftingAgentLibrary(url: output.appendingPathComponent("qa-agent.json")))
                    .companionAppearance().defaultAppStorage(defaults).environment(\.colorScheme, block ? .dark : .light)
                let host = NSHostingView(rootView: view)
                let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1080, height: 700), styleMask: [.borderless], backing: .buffered, defer: false)
                window.appearance = NSAppearance(named: block ? .darkAqua : .aqua)
                window.contentView = host; host.frame = NSRect(x: 0, y: 0, width: 1080, height: 700)
                host.layoutSubtreeIfNeeded(); RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
                guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("No bitmap") }
                host.cacheDisplay(in: host.bounds, to: rep)
                guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("No PNG") }
                try data.write(to: output.appendingPathComponent("boats-\(en ? "en" : "de")-\(block ? "block" : "classic").png"))
                window.contentView = nil
            }
        }
        print("Rendered 4 production Crafting views with boat filter, both languages/themes; no library or device")
    }
}
