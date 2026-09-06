import SwiftUI
import AppKit

@main struct ItemIconTests {
    @MainActor static func main() async throws {
        _ = NSApplication.shared
        let resources = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("Resources")
        let output = URL(fileURLWithPath: CommandLine.arguments[4])
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "RealmCraft-IconTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { try? fm.removeItem(at: temp); defaults.removePersistentDomain(forName: suite) }
        try fm.createDirectory(at: output, withIntermediateDirectories: true)
        let store = ItemIconStore(root: temp, resources: resources, defaults: defaults)
        precondition(store.installed.isEmpty && !defaults.bool(forKey: "companionItemIcons"))
        let names = try JSONSerialization.jsonObject(with: Data(contentsOf: resources.appendingPathComponent("MapEngine/realmcraft_map/item_names.json"))) as! [String: Any]
        for (index, pack) in IconPack.allCases.enumerated() {
            let mapping = pack.mapping(at: resources.appendingPathComponent(pack.manifest + ".json"))
            precondition(mapping.count == (pack == .kenney ? 49 : 686))
            precondition(mapping.keys.allSatisfy { names[$0] != nil })
            let archive = URL(fileURLWithPath: CommandLine.arguments[index + 2])
            let destination = store.directory(pack)
            try pack.install(archive: archive, destination: destination, mapping: mapping)
            precondition(pack.validInstallation(at: destination, mapping: mapping))
            let bad = temp.appendingPathComponent("bad.zip")
            try Data("invalid".utf8).write(to: bad)
            do { try pack.install(archive: bad, destination: destination, mapping: mapping); fatalError("Corruption accepted") } catch {}
            precondition(pack.validInstallation(at: destination, mapping: mapping))
            try pack.install(archive: archive, destination: destination, mapping: mapping)
            precondition(fm.fileExists(atPath: destination.appendingPathComponent("Companion-LICENSE.md").path))
        }
        store.refresh()
        precondition(store.installed.count == 2)
        precondition(store.image(for: -1, pack: .pixel) == nil)
        precondition(store.image(for: 3018, pack: .pixel) != nil && store.image(for: 3018, pack: .kenney) == nil)
        for pack in IconPack.allCases {
            store.activate(pack)
            precondition(store.activePack == pack && defaults.bool(forKey: "companionItemIcons"))
            let reloaded = ItemIconStore(root: temp, resources: resources, defaults: defaults)
            precondition(reloaded.activePack == pack && reloaded.installed.count == 2)
            for english in [false, true] {
                for skin in ["block", "classic"] {
                    defaults.set(skin, forKey: "companionSkin")
                    try render(ItemIconSettings(english: english, store: store).companionAppearance().defaultAppStorage(defaults), path: output.appendingPathComponent("\(pack.rawValue)-\(english)-\(skin).png"))
                }
            }
        }
        store.activate(.pixel)
        store.remove(.kenney)
        precondition(store.activePack == .pixel && defaults.bool(forKey: "companionItemIcons") && store.installed == [.pixel])
        store.remove(.pixel)
        precondition(store.installed.isEmpty && !defaults.bool(forKey: "companionItemIcons"))
        try render(ItemIconSettings(english: false, store: store).companionAppearance().defaultAppStorage(defaults), path: output.appendingPathComponent("download-de.png"))
        if CommandLine.arguments.contains("--download") {
            for pack in IconPack.allCases {
                store.download(pack)
                while store.busy { try await Task.sleep(nanoseconds: 100_000_000) }
                precondition(store.error == nil && store.installed.contains(pack) && store.activePack == pack, store.error ?? "Download failed")
            }
            precondition(store.installed.count == 2)
            print("PASS: both native downloads, verification and activation")
        }
        print("PASS: 49/686 mappings, install/reinstall, corrupt ZIP preservation, independent removal, persistent switching, fallback, DE/EN and both skins")
    }
    @MainActor static func render<V: View>(_ view: V, path: URL) throws {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 610, height: 690)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("Render failed") }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try bitmap.representation(using: .png, properties: [:])!.write(to: path)
    }
}
