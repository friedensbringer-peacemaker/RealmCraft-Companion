import Foundation

struct SavegameWorldGroup: Identifiable {
    let id: String
    let saves: [Savegame]
    static func make(_ saves: [Savegame]) -> [Self] {
        Dictionary(grouping: saves, by: \.world).map { world, members in
            Self(id: world, saves: members.sorted { $0.date == $1.date ? $0.id < $1.id : $0.date > $1.date })
        }.sorted {
            let a = $0.saves[0].date, b = $1.saves[0].date
            return a == b ? $0.id < $1.id : a > b
        }
    }
}

struct SavegameDeletion: Identifiable {
    let save: Savegame
    let root: URL
    var id: String { save.id }
}

extension Library {
    /// Display metadata only. Unknown formats fall back to the world ID in the UI.
    func worldDisplayName(_ save: Savegame) -> String? {
        guard UUID(uuidString: save.id) != nil, validWorld(save.world) else { return nil }
        let file = worldFolder(save).appendingPathComponent("world_data")
        for url in [folder(save), worldFolder(save), file] {
            guard let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]), values.isSymbolicLink != true else { return nil }
        }
        guard let values = try? file.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]), values.isRegularFile == true,
              let size = values.fileSize, (18...1_000_000).contains(size),
              let handle = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 1041), data.count >= 18 else { return nil }
        let b = Array(data)
        func number(_ p: Int) -> UInt32 { b[p..<p+4].reduce(0) { ($0 << 8) | UInt32($1) } }
        guard b[0] == 9, let identity = UInt32(save.world), number(1) == identity else { return nil }
        let count = Int(number(13))
        guard count > 0, count <= 1024, 17+count <= b.count,
              let name = String(bytes: b[17..<17+count], encoding: .utf8) else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
        return trimmed
    }

    /// Called only after the UI confirms this exact save and library. Never permanently removes files.
    func trashSave(_ save: Savegame, expectedRoot: URL, trash: (URL) throws -> Void = { url in
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }) throws {
        guard root.standardizedFileURL == expectedRoot.standardizedFileURL, UUID(uuidString: save.id) != nil, validWorld(save.world) else {
            throw LibraryError("Library or save identity changed. Confirm deletion again / Bibliothek oder Spielstand geändert. Löschen erneut bestätigen.")
        }
        let entry = folder(save), metadata = entry.appendingPathComponent("savegame.json")
        for url in [entry, metadata] {
            guard try url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
                throw LibraryError("Linked save entries cannot be deleted here / Verknüpfte Spielstände können hier nicht gelöscht werden.")
            }
        }
        let current = try JSONDecoder().decode(Savegame.self, from: Data(contentsOf: metadata))
        guard current == save else {
            throw LibraryError("Savegame changed since confirmation. Refresh and try again / Spielstand seit der Bestätigung geändert. Aktualisieren und erneut versuchen.")
        }
        try trash(entry)
    }
}
