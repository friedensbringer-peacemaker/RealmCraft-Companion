import Foundation

@main struct SavegameOrganizationTests {
    static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("organization-tests-" + UUID().uuidString)
        defer { try? fm.removeItem(at: root) }
        let library = try Library(root: root.appendingPathComponent("library"))
        func save(_ world: String, _ time: Double) throws -> Savegame {
            let value = Savegame(id: UUID().uuidString, title: "Backup", date: Date(timeIntervalSince1970: time), gameDate: Date(), world: world, count: 1, bytes: 1, source: "Test")
            try fm.createDirectory(at: library.folder(value), withIntermediateDirectories: true)
            try JSONEncoder().encode(value).write(to: library.folder(value).appendingPathComponent("savegame.json"))
            return value
        }
        let older = try save("123", 1), newer = try save("123", 3), other = try save("456", 2)
        let groups = SavegameWorldGroup.make([other, older, newer])
        precondition(groups.map(\.id) == ["123", "456"])
        precondition(groups[0].saves == [newer, older])
        precondition(SavegameWorldGroup.make([]).isEmpty)
        var calls = 0
        func rejected(_ value: Savegame, expected: URL) {
            do {
                try library.trashSave(value, expectedRoot: expected) { _ in calls += 1 }
                fatalError("Unsafe deletion accepted")
            } catch {}
        }
        rejected(newer, expected: root)
        var changed = newer; changed.title = "Changed since confirmation"
        rejected(changed, expected: library.root)
        var invalid = newer; invalid.id = "../outside"
        rejected(invalid, expected: library.root)
        let metadata = library.folder(other).appendingPathComponent("savegame.json")
        let outside = root.appendingPathComponent("outside.json")
        try fm.moveItem(at: metadata, to: outside)
        try fm.createSymbolicLink(at: metadata, withDestinationURL: outside)
        rejected(other, expected: library.root)
        precondition(calls == 0)
        let trash = root.appendingPathComponent("test-trash")
        try library.trashSave(newer, expectedRoot: library.root) { entry in
            calls += 1
            try fm.moveItem(at: entry, to: trash)
        }
        precondition(calls == 1 && fm.fileExists(atPath: trash.path))
        precondition(!fm.fileExists(atPath: library.folder(newer).path))
        precondition(fm.fileExists(atPath: library.folder(older).path))
        precondition(fm.fileExists(atPath: library.folder(other).path))
        precondition(fm.fileExists(atPath: outside.path))
        rejected(newer, expected: library.root)
        precondition(calls == 1)
        print("PASS: world grouping, ordering, confirmation identity, changed metadata, symlink rejection, isolated reversible deletion")
    }
}
