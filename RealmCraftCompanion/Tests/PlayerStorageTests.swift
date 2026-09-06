import Foundation

@main struct PlayerStorageTests {
    static func main() throws {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("player-storage-tests-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: temp) }
        let world = temp.appendingPathComponent("1234567890")
        try fm.createDirectory(at: world, withIntermediateDirectories: true)
        let bytes = Data("verified player".utf8)
        try bytes.write(to: world.appendingPathComponent("player_data"))
        try Data("world".utf8).write(to: world.appendingPathComponent("world_data"))
        try Data("chunk".utf8).write(to: world.appendingPathComponent("o.0,0"))
        let library = try Library(root: temp.appendingPathComponent("library"))
        let save = try library.importSave(world)
        func expect(_ value: Bool) { precondition(value) }
        func rejects(_ action: () throws -> Void) {
            do { try action(); fatalError("Expected rejection") } catch {}
        }
        let player = library.worldFolder(save).appendingPathComponent("player_data")
        let manifest = library.folder(save).appendingPathComponent("manifest.json")
        let originalManifest = try Data(contentsOf: manifest)
        expect(try library.readPlayerData(save) == bytes)
        // Unrelated chunk corruption does not change player bytes, but full verification still fails.
        try fm.removeItem(at: library.worldFolder(save).appendingPathComponent("o.0,0"))
        try Data("changed chunk".utf8).write(to: library.worldFolder(save).appendingPathComponent("o.0,0"))
        expect(try library.readPlayerData(save) == bytes)
        rejects { _ = try library.verify(save) }
        try fm.removeItem(at: player)
        try Data("bad player".utf8).write(to: player)
        rejects { _ = try library.readPlayerData(save) }
        try fm.removeItem(at: player)
        try bytes.write(to: player)
        try Data("{}".utf8).write(to: manifest)
        rejects { _ = try library.readPlayerData(save) }
        try originalManifest.write(to: manifest)
        try fm.removeItem(at: player)
        try fm.createSymbolicLink(at: player, withDestinationURL: world.appendingPathComponent("player_data"))
        rejects { _ = try library.readPlayerData(save) }
        try fm.removeItem(at: player)
        try Data(repeating: 0, count: 4_000_001).write(to: player)
        rejects { _ = try library.readPlayerData(save) }
        try fm.removeItem(at: player)
        try bytes.write(to: player)
        var invalid = save; invalid.id = "../escape"
        rejects { _ = try library.readPlayerData(invalid) }
        expect(try library.readPlayerData(save) == bytes)
        print("PASS: focused player checksum, corruption, missing manifest entry, symlink, size and identity guards; full-world verification still detects unrelated corruption")
    }
}
