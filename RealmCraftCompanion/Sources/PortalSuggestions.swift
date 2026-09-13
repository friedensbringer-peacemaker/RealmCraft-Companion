import Foundation

struct PortalSuggestion: Identifiable {
    let start: String
    let destination: String
    let distance: Double
    let tied: Bool
    var id: String { start + "→" + destination }
}
enum PortalSuggestions {
    // Directional nearest candidates only. No Minecraft search radius is asserted.
    static func make(_ portals: [SavedPortal], recorded: [PortalPair]) -> [PortalSuggestion] {
        var result: [PortalSuggestion] = []
        for source in portals.sorted(by: { $0.id < $1.id }) {
            if recorded.contains(where: { $0.start == source.id }) { continue }
            let factor: Double = source.dimension == "o" ? 0.125 : 8.0
            let x = Double(source.anchor.x) * factor
            let z = Double(source.anchor.z) * factor
            var ranked: [(portal: SavedPortal, distance: Double)] = []
            for target in portals where target.dimension != source.dimension {
                let dx = Double(target.anchor.x) - x
                let dz = Double(target.anchor.z) - z
                ranked.append((target, hypot(dx, dz)))
            }
            ranked.sort { a, b in
                if a.distance == b.distance { return a.portal.id < b.portal.id }
                return a.distance < b.distance
            }
            guard let best = ranked.first else { continue }
            let nearest = ranked.filter { abs($0.distance - best.distance) < 0.000001 }
            for candidate in nearest {
                result.append(PortalSuggestion(start: source.id, destination: candidate.portal.id, distance: candidate.distance, tied: nearest.count > 1))
            }
        }
        return result
    }
}
struct PortalLabelStore {
    let url: URL
    struct Document: Codable { var version = 1; let fingerprint: String; var names: [String: String] }
    func load(fingerprint: String) throws -> [String: String] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [:] }
        let data = try Data(contentsOf: url)
        guard data.count <= 500_000 else { throw PortalPlanStore.StoreError.invalid }
        let d = try JSONDecoder().decode(Document.self, from: data)
        guard d.version == 1, d.fingerprint == fingerprint, d.names.count <= 1000,
              d.names.allSatisfy({ !$0.key.isEmpty && $0.key.count <= 160 && !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.value.count <= 100 }) else { throw PortalPlanStore.StoreError.invalid }
        return d.names
    }
    func save(id: String, name: String, fingerprint: String) throws -> [String: String] {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.count <= 100, !id.isEmpty, id.count <= 160 else { throw PortalPlanStore.StoreError.invalid }
        var names = try load(fingerprint: fingerprint); names[id] = clean
        guard names.count <= 1000 else { throw PortalPlanStore.StoreError.invalid }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(Document(fingerprint: fingerprint, names: names)).write(to: url, options: .atomic)
        return names
    }
}
struct PortalSignIndex: Decodable {
    let names: [String: [String]]
    let incomplete: Bool
}
