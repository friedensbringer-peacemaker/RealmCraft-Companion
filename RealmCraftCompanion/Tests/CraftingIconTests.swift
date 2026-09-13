import SwiftUI
import AppKit

@main struct CraftingIconTests {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let fm = FileManager.default
        let temporary = fm.temporaryDirectory.appendingPathComponent("CraftingIcons-" + UUID().uuidString)
        let resources = temporary.appendingPathComponent("Resources")
        let assets = temporary.appendingPathComponent("Assets")
        let suite = "CraftingIcons-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { try? fm.removeItem(at: temporary); defaults.removePersistentDomain(forName: suite) }
        try fm.createDirectory(at: resources, withIntermediateDirectories: true)
        let catalog = try CraftingCatalog.load(from: root.appendingPathComponent("Resources/CraftingCatalog.json")).index()
        let torchID = catalog.items["torch"]!.itemID!
        // Synthetic, single-color fixture, not redistributed game or icon-pack artwork.
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 8, pixelsHigh: 8, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        for y in 0..<8 { for x in 0..<8 { bitmap.setColor(NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1), atX: x, y: y) } }
        for pack in IconPack.allCases {
            let folder = assets.appendingPathComponent(pack.folder)
            try fm.createDirectory(at: folder.appendingPathComponent("PNG"), withIntermediateDirectories: true)
            try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("PNG/synthetic.png"))
            try JSONEncoder().encode([String(torchID): "PNG/synthetic.png"]).write(to: resources.appendingPathComponent(pack.manifest + ".json"))
            try pack.digest.write(to: folder.appendingPathComponent("verified.sha256"), atomically: true, encoding: .utf8)
            try "Synthetic test fixture only".write(to: folder.appendingPathComponent(pack.creditFile), atomically: true, encoding: .utf8)
        }
        let store = ItemIconStore(root: assets, resources: resources, defaults: defaults)
        precondition(store.installed.count == 2)
        var checks = 0
        for english in [false, true] {
            for pack in IconPack.allCases {
                defaults.set(pack.rawValue, forKey: "companionIconPack")
                defaults.set(true, forKey: "companionItemIcons")
                let mapped = render(itemID: torchID, english: english, store: store, defaults: defaults)
                let missing = render(itemID: -1, english: english, store: store, defaults: defaults)
                let unmapped = render(itemID: nil, english: english, store: store, defaults: defaults)
                precondition(mapped != missing && missing == unmapped, "Explicit item ID vs neutral fallback")
                defaults.set(false, forKey: "companionItemIcons")
                let textOnly = render(itemID: torchID, english: english, store: store, defaults: defaults)
                precondition(textOnly != mapped && textOnly != missing, "Text-only hides image and fallback")
                checks += 2
            }
        }
        defaults.set(true, forKey: "companionItemIcons")
        let before = render(itemID: torchID, english: true, store: store, defaults: defaults)
        store.remove(.pixel)
        defaults.set(true, forKey: "companionItemIcons")
        let after = render(itemID: torchID, english: true, store: store, defaults: defaults)
        precondition(before != after, "Removing a pack clears cached artwork")
        checks += 1
        print("PASS: \(checks) native crafting-icon render checks; DE/EN, both packs, unmapped IDs, text-only and removal; no downloads")
    }

    @MainActor static func render(itemID: Int?, english: Bool, store: ItemIconStore, defaults: UserDefaults) -> Data {
        let view = CraftingItemIcon(itemID: itemID, english: english, store: store)
            .frame(width: 40, height: 40).background(Color.white).foregroundStyle(Color.black)
            .environment(\.colorScheme, .light).defaultAppStorage(defaults)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        guard let image = renderer.cgImage else { fatalError("Native icon rendering failed") }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    }
}
