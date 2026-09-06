import Foundation

@main struct SavegameStatusTests {
    static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("save-status-tests-" + UUID().uuidString)
        defer { try? fm.removeItem(at: root) }
        let library = try Library(root: root.appendingPathComponent("library"))
        func make(_ title: String) throws -> Savegame {
            let stage = library.root.appendingPathComponent(".stage-" + UUID().uuidString)
            let world = stage.appendingPathComponent("123")
            try fm.createDirectory(at: world, withIntermediateDirectories: true)
            try Data("world".utf8).write(to: world.appendingPathComponent("world_data"))
            try Data("player".utf8).write(to: world.appendingPathComponent("player_data"))
            return try library.finish(stage, world: "123", title: title, source: "Test", manifest: library.localManifest(world))
        }
        let a = try make("First"), b = try make("Second")
        let shared = try library.storageStatus(a)
        precondition(shared.files == 2 && shared.optimizedFiles == 2 && shared.sharedFiles == 2)
        precondition(shared.related.map(\.save.id) == [b.id])
        try fm.removeItem(at: library.folder(b))
        do { let result = try library.verify(a).count == 2; precondition(result) }
        let independent = try library.storageStatus(a)
        precondition(independent.related.isEmpty && independent.optimizedFiles == 2)
        try library.materializeWorld(library.worldFolder(a))
        do { let result = try library.storageStatus(a).optimizedFiles == 0; precondition(result) }
        let cloudFolder = root.appendingPathComponent("cloud")
        try fm.createDirectory(at: cloudFolder, withIntermediateDirectories: true)
        do { let result = try library.cloudStatus(a, directory: nil).state == .unconfigured; precondition(result) }
        do { let result = try library.cloudStatus(a, directory: cloudFolder.path).state == .notFound; precondition(result) }
        let archive = cloudFolder.appendingPathComponent("RealmCraft-Library-Backup-test.zip")
        try library.exportLibraryArchive(to: archive)
        do { let result = try library.cloudStatus(a, directory: cloudFolder.path).state == .found; precondition(result) }
        var manifest = try library.verify(a)
        manifest["player_data"] = String(repeating: "0", count: 64)
        try library.write(manifest, to: library.folder(a).appendingPathComponent("manifest.json"))
        do { let result = try library.cloudStatus(a, directory: cloudFolder.path).state == .notFound; precondition(result) }
        try fm.removeItem(at: archive)
        try Data("bad zip".utf8).write(to: archive)
        do { let result = try library.cloudStatus(a, directory: cloudFolder.path).state == .unavailable; precondition(result) }
        let player = library.worldFolder(a).appendingPathComponent("player_data")
        try fm.removeItem(at: player)
        try fm.createSymbolicLink(at: player, withDestinationURL: root.appendingPathComponent("missing"))
        do { _ = try library.storageStatus(a); fatalError("Invalid linked save reported independent") } catch {}
        print("PASS: actual hard links, shared snapshots, deletion independence, materialization, absent/matching/stale/corrupt cloud archives and symlink rejection")
    }
}
