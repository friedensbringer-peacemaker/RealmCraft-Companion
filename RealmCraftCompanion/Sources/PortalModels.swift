import Foundation
import CryptoKit

struct PortalPosition: Codable, Hashable {
    let x: Int, y: Int, z: Int
    var text: String { "\(x) / \(y) / \(z)" }
}
struct SavedPortal: Identifiable {
    let dimension: String
    let blocks: [PortalPosition]
    var anchor: PortalPosition { blocks[0] }
    var id: String { dimension + ":" + anchor.text }
    var bounds: String {
        func range(_ values: [Int]) -> String { let a = values.min()!, b = values.max()!; return a == b ? "\(a)" : "\(a)…\(b)" }
        return "X \(range(blocks.map(\.x))) · Y \(range(blocks.map(\.y))) · Z \(range(blocks.map(\.z)))"
    }
}
struct PortalPair: Codable, Identifiable {
    var id: String
    var name: String
    var start: String
    var destination: String
    var note: String
    // Records the reported direction only; a reverse connection is not implied.
}
struct PortalPairDocument: Codable {
    var fingerprint: String
    var pairs: [PortalPair]
}
enum PortalReader {
    enum ReadError: LocalizedError {
        case invalid
        var errorDescription: String? { "Unsupported or incomplete portal data / Nicht unterstützte oder unvollständige Portaldaten." }
    }
    static func parse(_ data: Data, dimension: String) throws -> [SavedPortal] {
        let b = Array(data)
        guard b.count >= 4, b.count <= 20_000_000, ["o", "n"].contains(dimension) else { throw ReadError.invalid }
        func int(_ at: Int) -> Int { Int(Int32(bitPattern: b[at..<at+4].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) })) }
        let count = int(0)
        guard count >= 0, count <= (b.count - 4) / 18, b.count == 4 + count * 18 else { throw ReadError.invalid }
        var remaining = Set<PortalPosition>()
        for i in 0..<count {
            let at = 4 + i * 18
            guard b[at] == 0 && b[at+1] == 0 else { continue }
            let point = PortalPosition(x: int(at+2), y: int(at+6), z: int(at+10))
            guard (0..<256).contains(point.y), remaining.insert(point).inserted else { throw ReadError.invalid }
        }
        var result: [SavedPortal] = []
        while let first = remaining.first {
            remaining.remove(first)
            var group = [first], next = 0
            while next < group.count {
                let p = group[next]; next += 1
                for d in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)] {
                    let q = PortalPosition(x: p.x+d.0, y: p.y+d.1, z: p.z+d.2)
                    if remaining.remove(q) != nil { group.append(q) }
                }
            }
            group.sort { ($0.y, $0.x, $0.z) < ($1.y, $1.x, $1.z) }
            result.append(SavedPortal(dimension: dimension, blocks: group))
        }
        return result.sorted { $0.id < $1.id }
    }
    static func read(_ world: URL) throws -> (portals: [SavedPortal], fingerprint: String) {
        var portals: [SavedPortal] = [], hash = SHA256()
        for (dimension, name) in [("o", "poiOverworld"), ("n", "poiTheNether")] {
            let data = try Data(contentsOf: world.appendingPathComponent(name))
            portals += try parse(data, dimension: dimension)
            hash.update(data: data)
        }
        return (portals, hash.finalize().map { String(format: "%02x", $0) }.joined())
    }
}
