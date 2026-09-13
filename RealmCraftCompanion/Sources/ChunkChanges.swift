import Foundation

struct ChunkChange: Codable, Equatable, Identifiable {
    enum Status: String, Codable, CaseIterable { case added, changed, missing, unchanged }
    let dimension: String; let x: Int; let z: Int; let status: Status
    var id: String { "\(dimension).\(x),\(z)" }
    static func position(_ path: String) -> (String, Int, Int)? {
        let parts = path.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2, ["o", "n"].contains(String(parts[0])) else { return nil }
        let numbers = parts[1].split(separator: ",", omittingEmptySubsequences: false)
        guard numbers.count == 2, let x = Int(numbers[0]), let z = Int(numbers[1]),
              (-30_000_000...30_000_000).contains(x), (-30_000_000...30_000_000).contains(z), x % 16 == 0, z % 16 == 0,
              path == "\(parts[0]).\(x),\(z)" else { return nil }
        return (String(parts[0]), x, z)
    }
    static func compare(before: [String: String], after: [String: String]) -> [Self] {
        Set(before.keys).union(after.keys).compactMap { key in
            guard let (dimension, x, z) = position(key) else { return nil }
            let status: Status = before[key] == nil ? .added : after[key] == nil ? .missing : before[key] == after[key] ? .unchanged : .changed
            return Self(dimension: dimension, x: x, z: z, status: status)
        }.sorted { ($0.dimension, $0.z, $0.x) < ($1.dimension, $1.z, $1.x) }
    }
}
struct ChunkChangeReport: Codable {
    let schemaVersion: Int
    let world: String
    let beforeID: String; let afterID: String
    let beforeDate: Date; let afterDate: Date
    let changes: [ChunkChange]
    let method: String
}
