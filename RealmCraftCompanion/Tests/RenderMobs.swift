import SwiftUI
import AppKit

@main struct RenderMobs {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let catalog = try JSONDecoder().decode(MobCatalog.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let imageMode = CommandLine.arguments.contains("--images")
        let defaults = UserDefaults(suiteName: "MobRender-" + UUID().uuidString)!
        defaults.set(imageMode, forKey: "companionMobImages")
        for english in [false, true] {
            for id in ["zombie", "baby_cow", "horse"] {
                let entry = catalog.entries.first { $0.id == id }!
                try render(MobDetail(entry: entry, english: english, report: {}).defaultAppStorage(defaults).padding(24).frame(width: 580, height: imageMode ? 1510 : 1080).companionAppearance(),
                           width: 580, height: imageMode ? 1510 : 1080, path: output.appendingPathComponent("\(id)-\(english ? "en" : "de").png"))
            }
            try render(FeedbackView(context: FeedbackContext(area: "mobs", entryID: "bee", entryName: english ? "Bee" : "Biene"), english: english).companionAppearance(),
                       width: 808, height: 788, path: output.appendingPathComponent("feedback-\(english ? "en" : "de").png"))
        }
        print("Rendered DE/EN mob details and feedback sheets")
    }
    @MainActor static func render<V: View>(_ view: V, width: CGFloat, height: CGFloat, path: URL) throws {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: width, height: height)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("Render failed") }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try bitmap.representation(using: .png, properties: [:])!.write(to: path)
    }
}
