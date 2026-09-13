import Foundation

struct BackupTransferReport: Codable {
    let version: Int
    let mode: String
    let baseSaveID: String?
    let downloadedFiles: Int
    let reusedFiles: Int
    let verification: String
}
extension Library {
    static func safeRelativeFile(_ path: String) -> Bool {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        return !parts.isEmpty && !path.contains("\\") && !path.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) &&
            parts.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }
    /// Retains full remote checksums before/after and final local verification; optimizes transfer, not trust.
    func transferBackup(_ serial: String, world: String, manifest: [String: String], staging: URL) throws -> BackupTransferReport {
        guard manifest.keys.allSatisfy(Self.safeRelativeFile) else { throw LibraryError("Invalid remote path / Ungültiger Gerätepfad.") }
        let previous = try entries().first { $0.world == world }
        var reusable: [String] = []
        if let previous {
            // A corrupt prior snapshot never weakens the verification of the new backup.
            if let verified = try? verify(previous) {
                reusable = manifest.keys.filter { verified[$0] == manifest[$0] }.sorted()
            } else { progress("Previous backup not reusable; downloading a full copy / Vorherige Sicherung nicht wiederverwendbar; vollständige Kopie …") }
        }
        let reused = Set(reusable), changed = manifest.keys.filter { !reused.contains($0) }.sorted()
        // ADB startup overhead makes one complete pull preferable when most files changed.
        guard let previous, !reusable.isEmpty, changed.count * 4 < manifest.count * 3 else {
            progress("Full transfer · \(manifest.count) files / Vollübertragung · \(manifest.count) Dateien …")
            _ = try command(serial, ["pull", "-a", remote + "/" + world, staging.path + "/"])
            return .init(version: 1, mode: "full", baseSaveID: nil, downloadedFiles: manifest.count, reusedFiles: 0, verification: "full SHA-256 before/after and local")
        }
        let target = staging.appendingPathComponent(world)
        try fm.createDirectory(at: target, withIntermediateDirectories: true)
        for (index, name) in reusable.enumerated() {
            let destination = target.appendingPathComponent(name)
            try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            // Copy, never modify a hardlinked source or expose it to a later pull overwrite.
            try fm.copyItem(at: worldFolder(previous).appendingPathComponent(name), to: destination)
            if index % 500 == 0 { progress("Reuse / Wiederverwenden · \(index + 1)/\(reusable.count)") }
        }
        for (index, name) in changed.enumerated() {
            let destination = target.appendingPathComponent(name)
            try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            progress("Transfer changed files / Geänderte Dateien übertragen · \(index + 1)/\(changed.count) · reused / wiederverwendet \(reusable.count)")
            _ = try command(serial, ["pull", "-a", remote + "/" + world + "/" + name, destination.path])
        }
        return .init(version: 1, mode: "incremental-transfer", baseSaveID: previous.id, downloadedFiles: changed.count,
                     reusedFiles: reusable.count, verification: "full SHA-256 before/after and local")
    }
}
