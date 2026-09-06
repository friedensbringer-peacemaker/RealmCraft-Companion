import Foundation
import CryptoKit

extension Library {
    /// Verify the exact bytes used for the player view against the recorded manifest.
    /// Full-world verification remains mandatory in the backup/restore engine.
    func readPlayerData(_ save: Savegame) throws -> Data {
        try readVerifiedStateFile(save, filename: "player_data", limit: 4_000_000)
    }

    func readStatisticsData(_ save: Savegame) throws -> Data {
        try readVerifiedStateFile(save, filename: "world_data", limit: 1_000_000)
    }

    private func readVerifiedStateFile(_ save: Savegame, filename: String, limit: Int) throws -> Data {
        guard UUID(uuidString: save.id) != nil, validWorld(save.world) else {
            throw PlayerReadError("Invalid save identity / Ungültige Spielstand-ID.")
        }
        let entry = folder(save), world = worldFolder(save)
        let manifest = entry.appendingPathComponent("manifest.json")
        let player = world.appendingPathComponent(filename)
        for url in [entry, world, manifest, player] {
            guard try url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
                throw PlayerReadError("Savegame links are not supported / Verknüpfungen im Spielstand werden nicht unterstützt.")
            }
        }
        func boundedRead(_ url: URL, limit: Int) throws -> Data {
            let attributes = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard attributes.isRegularFile == true, let size = attributes.fileSize, size <= limit else {
                throw PlayerReadError("Unsupported file size or type / Nicht unterstützte Dateigröße oder Dateiart.")
            }
            let file = try FileHandle(forReadingFrom: url)
            defer { try? file.close() }
            let bytes = try file.read(upToCount: limit+1) ?? Data()
            guard bytes.count <= limit else { throw PlayerReadError("File changed during reading / Datei während des Lesens geändert.") }
            return bytes
        }
        let recordedBytes = try boundedRead(manifest, limit: 64_000_000)
        let recorded = try JSONDecoder().decode([String:String].self, from: recordedBytes)
        guard let expected = recorded[filename], expected.count == 64, expected.allSatisfy({ $0.isHexDigit }) else {
            throw PlayerReadError("State-file checksum missing / Prüfsumme der Zustandsdatei fehlt.")
        }
        let bytes = try boundedRead(player, limit: limit)
        let actual = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        guard actual == expected.lowercased(), try boundedRead(manifest, limit: 64_000_000) == recordedBytes else {
            throw PlayerReadError("State file does not match its backup checksum / Zustandsdatei stimmt nicht mit der Sicherungs-Prüfsumme überein.")
        }
        return bytes
    }
}
