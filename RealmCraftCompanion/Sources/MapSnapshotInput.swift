import Foundation

struct MapSnapshotInput {
    let directory: URL
    let manifest: [String: String]
    /// Caller owns and later removes only this new temporary directory.
    static func prepare(library: Library, save: Savegame, directory: URL) throws -> Self {
        try library.withExclusiveOperation {
            let manifest = try library.verify(save)
            guard !FileManager.default.fileExists(atPath: directory.path) else { throw LibraryError("Map input already exists / Karteneingabe existiert bereits.") }
            try FileManager.default.copyItem(at: library.worldFolder(save), to: directory)
            try library.assertSame(manifest, library.localManifest(directory))
            return Self(directory: directory, manifest: manifest)
        }
    }
}
