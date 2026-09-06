import Foundation

@main struct StatisticsStorageTests {
    static func main() throws {
        let fm = FileManager.default, temp = FileManager.default.temporaryDirectory.appendingPathComponent("statistics-storage-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: temp) }
        let world = temp.appendingPathComponent("123")
        try fm.createDirectory(at: world, withIntermediateDirectories: true)
        let original = Data("verified world data".utf8)
        try original.write(to: world.appendingPathComponent("world_data"))
        try Data("player".utf8).write(to: world.appendingPathComponent("player_data"))
        let library = try Library(root: temp.appendingPathComponent("library"))
        let save = try library.importSave(world)
        func reject(_ action: () throws -> Void) { do { try action(); fatalError("Expected failure") } catch {} }
        let actual = try library.readStatisticsData(save); precondition(actual == original)
        let file = library.worldFolder(save).appendingPathComponent("world_data")
        let manifest = library.folder(save).appendingPathComponent("manifest.json"), recorded = try Data(contentsOf: manifest)
        try fm.removeItem(at: file)
        try Data("tampered".utf8).write(to: file); reject { _ = try library.readStatisticsData(save) }
        try fm.removeItem(at: file)
        try original.write(to: file); try Data("{}".utf8).write(to: manifest); reject { _ = try library.readStatisticsData(save) }
        try recorded.write(to: manifest)
        try fm.removeItem(at: file); try fm.createSymbolicLink(at: file, withDestinationURL: world.appendingPathComponent("world_data"))
        reject { _ = try library.readStatisticsData(save) }
        try fm.removeItem(at: file); try Data(repeating: 0, count: 1_000_001).write(to: file)
        reject { _ = try library.readStatisticsData(save) }
        print("PASS: statistics verified-read checksum, missing manifest, symlink and size protection")
    }
}
