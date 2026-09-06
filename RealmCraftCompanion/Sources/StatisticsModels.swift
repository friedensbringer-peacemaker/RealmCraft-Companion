import Foundation

struct WorldStatistics: Equatable {
    let worldID: UInt32
    let worldName: String
    let buildDigActions: Int64
}

struct StatisticsReadError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum StatisticsReader {
    /// Observed world_data v9. Lengths are decoded; no world-specific byte offsets.
    static func parse(_ data: Data, expectedWorld: String) throws -> WorldStatistics {
        func reject() -> StatisticsReadError {
            StatisticsReadError(message: "Unsupported or damaged statistics data / Statistikdaten nicht unterstützt oder beschädigt.")
        }
        let bytes = [UInt8](data)
        guard bytes.count >= 17, bytes.count <= 1_000_000, bytes[0] == 9 else { throw reject() }
        func uint(_ offset: Int, _ count: Int) throws -> UInt64 {
            guard offset >= 0, offset <= bytes.count, count <= bytes.count - offset else { throw reject() }
            return bytes[offset..<offset+count].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        }
        let world = UInt32(try uint(1, 4))
        guard String(world) == expectedWorld else {
            throw StatisticsReadError(message: "World identity mismatch / Welt-ID stimmt nicht mit der Sicherung überein.")
        }
        let nameLength = Int(try uint(13, 4))
        guard (1...4096).contains(nameLength), 17 + nameLength <= bytes.count,
              let name = String(bytes: bytes[17..<17+nameLength], encoding: .utf8), !name.contains("\0") else { throw reject() }
        let suffix = 17 + nameLength
        // Time, last-played ticks, four setting bytes, 13-byte spawn position, hash length.
        let hashLength = Int(try uint(suffix + 33, 4))
        guard hashLength <= 128 else { throw reject() }
        // Screenshot hash, then 15 bytes of weather state before the Int64 counter.
        let counterOffset = suffix + 37 + hashLength + 15
        // v9 also has settings and sharing data after this field (at least 25 bytes).
        guard counterOffset + 8 + 25 <= bytes.count else { throw reject() }
        let raw = try uint(counterOffset, 8)
        guard raw <= UInt64(Int64.max) else { throw reject() }
        return WorldStatistics(worldID: world, worldName: name, buildDigActions: Int64(raw))
    }
}
