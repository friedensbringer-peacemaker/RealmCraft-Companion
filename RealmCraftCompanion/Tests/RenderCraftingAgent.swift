import AppKit
import SwiftUI

/// Native component captures with synthetic checkmarks, without a world or the real app profile.
@main struct RenderCraftingAgent {
    @MainActor static func main() throws {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let catalog = try CraftingCatalog.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
        let index = catalog.index(), output = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let library = CraftingAgentLibrary(url: output.appendingPathComponent("synthetic-agent-" + UUID().uuidString + ".json"))
        let lava = CraftingInstruction.all(index).first { $0.itemID == "lava_bucket" }!
        library.update { $0.verify(lava, index: index, enabled: true); $0.selectVerified(index) }
        precondition(library.failure.isEmpty && library.state.selectedIDs == [lava.id])
        let suite = "CraftingAgentQA-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for en in [false, true] {
            defaults.set(en ? "en" : "de", forKey: "appLanguage")
            defaults.set("block", forKey: "companionSkin")
            if CommandLine.arguments.contains("--installed-icons") {
                precondition(ItemIconStore.shared.installed.contains(.pixel), "Pixel pack must already be installed; this test never downloads it")
                defaults.set(true, forKey: "companionItemIcons")
                defaults.set("pixel", forKey: "companionIconPack")
                for id in ["diamond_pickaxe", "diamond", "stick", "crafting_table", "arrow", "flint", "feather"] {
                    precondition(ItemIconStore.shared.image(for: index.items[id]!.itemID!, pack: .pixel) != nil, "Missing mapped image: " + id)
                }
            }
            for item in ["lava_bucket", "bucket", "diamond_pickaxe"] {
                let view = CraftingView(language: en ? "en" : "de", catalog: catalog, initialItem: item, initialQuery: item == "lava_bucket" ? "lava" : item == "diamond_pickaxe" ? "pickaxe" : "bucket", planURL: output.appendingPathComponent("unused-plan.json"), agentLibrary: library)
                    .defaultAppStorage(defaults).companionAppearance().environment(\.colorScheme, .dark)
                try render(view, size: NSSize(width: 1080, height: 800), to: output.appendingPathComponent(item + (en ? "-en.png" : "-de.png")))
            }
            let recipe = index.recipes["diamond_pickaxe"]!.first!
            for step in 0..<5 {
                let walkthrough = CraftingWalkthroughView(item: index.items["diamond_pickaxe"]!, index: index, english: en, recipe: recipe, desired: 2, initialStep: step)
                    .padding(18).defaultAppStorage(defaults).companionAppearance().environment(\.colorScheme, .dark)
                try render(walkthrough, size: NSSize(width: 690, height: 660), to: output.appendingPathComponent("pickaxe-step-\(step + 1)-\(en ? "en" : "de").png"))
            }
            let view = CraftingAgentSelectionView(library: library, index: index, english: en)
                .defaultAppStorage(defaults).companionAppearance().environment(\.colorScheme, .dark)
            try render(view, size: NSSize(width: 720, height: 580), to: output.appendingPathComponent(en ? "selection-en.png" : "selection-de.png"))
        }
        print("PASS: 18 native recipe/obtaining/selection captures with synthetic confirmation")
    }
    @MainActor static func render<V: View>(_ view: V, size: NSSize, to url: URL) throws {
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = host; host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded(); RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("No bitmap") }
        host.cacheDisplay(in: host.bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("No PNG") }
        try data.write(to: url)
        window.contentView = nil
    }
}
