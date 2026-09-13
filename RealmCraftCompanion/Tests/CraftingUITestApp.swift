import SwiftUI
import AppKit

/// Standalone synthetic QA shell; no library, device, notification or microphone services.
@main struct CraftingUITestApp {
    @MainActor static func main() throws {
        let application = NSApplication.shared
        application.setActivationPolicy(.regular)
        let catalog = try CraftingCatalog.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
        let plan = URL(fileURLWithPath: CommandLine.arguments[2])
        let english = CommandLine.arguments.contains("--en")
        let defaults = UserDefaults(suiteName: "CraftingQA-" + UUID().uuidString)!
        let view = CraftingView(language: english ? "en" : "de", catalog: catalog, planURL: plan, agentLibrary: CraftingAgentLibrary(url: plan.deletingLastPathComponent().appendingPathComponent("qa-agent.json")))
            .defaultAppStorage(defaults).companionAppearance()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1180, height: 820), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "RealmCraft · Synthetic Crafting QA"
        window.contentView = NSHostingView(rootView: view)
        window.center(); window.makeKeyAndOrderFront(nil)
        application.activate(ignoringOtherApps: true)
        application.run()
    }
}
