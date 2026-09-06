import Foundation
@main struct AIExportSharingTests {
    static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("RealmCraft-SharingTest-\(UUID())")
        defer { try? fm.removeItem(at: root) }
        let library = root.appendingPathComponent("saves")
        let exports = root.appendingPathComponent("exports")
        try fm.createDirectory(at: library, withIntermediateDirectories: true)
        try fm.createDirectory(at: exports, withIntermediateDirectories: true)
        let markdown = "# Welt 🌍\nInventar: Äpfel\n" + String(repeating: "Kiste: 12,64,-20\n", count: 50000)
        let first = try AIExportFiles.write(markdown: markdown, world: "../../world/ä", folder: exports, library: library)
        let second = try AIExportFiles.write(markdown: "new snapshot", world: "../../world/ä", folder: exports, library: library)
        precondition(first != second && first.deletingLastPathComponent().path == exports.resolvingSymlinksInPath().standardizedFileURL.path)
        let saved = try String(contentsOf: first, encoding: .utf8)
        precondition(saved == markdown)
        let exported = try fm.contentsOfDirectory(atPath: exports.path)
        precondition(exported.count == 2)
        let alias = root.appendingPathComponent("alias")
        try fm.createSymbolicLink(at: alias, withDestinationURL: library)
        for forbidden in [library, alias] {
            do {
                _ = try AIExportFiles.write(markdown: "bad", world: "1", folder: forbidden, library: library)
                fatalError("Managed library was writable")
            } catch { }
        }
        let untouched = try fm.contentsOfDirectory(atPath: library.path)
        precondition(untouched.isEmpty)
        let bookmark = try exports.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        var stale = false
        let resolved = try URL(resolvingBookmarkData: bookmark, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale)
        precondition(resolved.resolvingSymlinksInPath() == exports.resolvingSymlinksInPath())
        precondition(!AIExportFiles.isCloudFolder(exports))
        print("AI export sharing: full Unicode snapshot, distinct files, path safety, bookmark roundtrip passed")
    }
}
