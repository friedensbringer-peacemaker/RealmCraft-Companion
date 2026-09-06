import Foundation
import Darwin

struct SavegameStorageStatus {
    var files = 0
    var optimizedFiles = 0
    var sharedFiles = 0
    var related: [(save: Savegame, files: Int)] = []
    var originID: String?
}
struct SavegameCloudStatus {
    enum State { case unconfigured, found, notFound, unavailable }
    var state: State
    var archive: URL?
    var date: Date?
    var checked = 0
}

extension Library {
    /// Inspect actual hard links, not the optimization preference or matching world IDs.
    func storageStatus(_ save: Savegame) throws -> SavegameStorageStatus {
        guard UUID(uuidString: save.id) != nil, validWorld(save.world) else { throw LibraryError("Invalid save identity") }
        func regularIdentity(_ url: URL) throws -> String {
            let relative = String(url.path.dropFirst(root.path.count + 1))
            guard root.resolvingSymlinksInPath().appendingPathComponent(relative).standardizedFileURL == url.resolvingSymlinksInPath().standardizedFileURL else { throw LibraryError("Symbolic link in save path / Symbolische Verknüpfung im Savegame-Pfad") }
            var s = stat()
            guard lstat(url.path, &s) == 0, (s.st_mode & S_IFMT) == S_IFREG else {
                throw LibraryError("Missing file or unsupported link / Fehlende Datei oder nicht unterstützte Verknüpfung: \(url.lastPathComponent)")
            }
            return "\(s.st_dev):\(s.st_ino)"
        }
        func manifest(_ entry: Savegame) throws -> [String: String] {
            let data = try Data(contentsOf: folder(entry).appendingPathComponent("manifest.json"))
            let values = try JSONDecoder().decode([String:String].self, from: data)
            guard values["world_data"] != nil, values["player_data"] != nil,
                  values.keys.allSatisfy({ !$0.hasPrefix("/") && !$0.split(separator: "/").contains("..") }),
                  values.values.allSatisfy({ $0.count == 64 && $0.allSatisfy(\.isHexDigit) }) else { throw LibraryError("Invalid manifest / Ungültiges Manifest") }
            return values
        }
        for directory in [folder(save), worldFolder(save)] {
            guard try directory.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else { throw LibraryError("Linked save directory / Verknüpfter Savegame-Ordner") }
        }
        let expected = try manifest(save)
        var status = SavegameStorageStatus()
        var identities: [String: Int] = [:]
        for (name, hash) in expected {
            let file = worldFolder(save).appendingPathComponent(name)
            let identity = try regularIdentity(file)
            identities[identity, default: 0] += 1
            status.files += 1
            if (try? regularIdentity(objectURL(hash))) == identity { status.optimizedFiles += 1 }
        }
        var shared = Set<String>()
        for other in try entries() where other.id != save.id {
            guard (try? worldFolder(other).resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true,
                  let values = try? manifest(other) else { continue }
            var common = Set<String>()
            for name in values.keys {
                if let identity = try? regularIdentity(worldFolder(other).appendingPathComponent(name)), identities[identity] != nil { common.insert(identity) }
            }
            if !common.isEmpty {
                status.related.append((other, common.reduce(0) { $0 + (identities[$1] ?? 0) }))
                shared.formUnion(common)
            }
        }
        status.sharedFiles = shared.reduce(0) { $0 + (identities[$1] ?? 0) }
        if save.source.hasPrefix("Editor BETA"), let marker = save.source.range(of: "source ") {
            let token = String(save.source[marker.upperBound...].prefix(36))
            if UUID(uuidString: token) != nil { status.originID = token }
        }
        return status
    }

    /// A matching archive manifest establishes a local backup candidate, never provider upload status.
    func cloudStatus(_ save: Savegame, directory: String?) throws -> SavegameCloudStatus {
        guard let directory, !directory.isEmpty else { return .init(state: .unconfigured) }
        guard UUID(uuidString: save.id) != nil else { throw LibraryError("Invalid save identity") }
        let folder = URL(fileURLWithPath: directory, isDirectory: true)
        guard let children = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey]) else { return .init(state: .unavailable) }
        let expected = try Data(contentsOf: self.folder(save).appendingPathComponent("manifest.json"))
        let manifest = try JSONDecoder().decode([String:String].self, from: expected)
        let archives = children.filter { $0.lastPathComponent.hasPrefix("RealmCraft-Library-Backup-") && $0.pathExtension.lowercased() == "zip" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        var checked = 0, failed = false
        for archive in archives {
            if Task<Never,Never>.isCancelled { throw CancellationError() }
            do {
                let result = try run("/usr/bin/unzip", ["-p", archive.path, save.id + "/manifest.json"], timeout: 15)
                checked += 1
                if result.code == 11 { continue } // The requested member is absent.
                guard result.code == 0, let data = result.output.data(using: .utf8),
                      let archived = try? JSONDecoder().decode([String:String].self, from: data) else { failed = true; continue }
                if archived == manifest {
                    return .init(state: .found, archive: archive, date: (try? archive.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate, checked: checked)
                }
            } catch { failed = true }
        }
        return .init(state: failed ? .unavailable : .notFound, checked: checked)
    }
}
