import Foundation

/// Map selection applies a delta, preserving marks made in other views and dimensions.
enum ChestOwnership {
    static func validID(_ id: String) -> Bool {
        let parts = id.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, ["o", "n"].contains(parts[0]) else { return false }
        let coordinates = parts[1].split(separator: ",", omittingEmptySubsequences: false)
        guard coordinates.count == 3, let x = Int(coordinates[0]), let y = Int(coordinates[1]), let z = Int(coordinates[2]),
              abs(Double(x)) <= 30_000_000, (0...255).contains(y), abs(Double(z)) <= 30_000_000 else { return false }
        return id == "\(parts[0]):\(x),\(y),\(z)"
    }
    static func apply(_ body: [String: Any], world: String, existing: Set<String>) -> (ids: Set<String>, changed: Int)? {
        guard !world.isEmpty, body["world"] as? String == world,
              let action = body["action"] as? String, ["add", "remove"].contains(action),
              let raw = body["ids"] as? [String], !raw.isEmpty, raw.count <= 100_000, raw.allSatisfy(validID) else { return nil }
        let delta = Set(raw)
        let updated = action == "add" ? existing.union(delta) : existing.subtracting(delta)
        return (updated, existing.symmetricDifference(updated).count)
    }
}
