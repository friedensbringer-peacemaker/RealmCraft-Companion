import Foundation

struct OrePreset: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    let name: String
    let world: String
    let dimension: String
    let bounds: [Int] // inclusive x0,x1,y0,y1,z0,z1; same contract as OreScan
    let materials: [String]
    let oreID: String
    let biomeID: String
    let nonAirOnly: Bool
    let sampleSize: Int
    let seed: Int
    var valid: Bool {
        guard UUID(uuidString: id) != nil, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name.count <= 80,
              !world.isEmpty, ["o", "n"].contains(dimension), bounds.count == 6,
              bounds.allSatisfy({ (-30_000_000...30_000_000).contains($0) }),
              bounds[0] <= bounds[1], bounds[4] <= bounds[5], (0...255).contains(bounds[2]), (bounds[2]...255).contains(bounds[3]),
              (1...512).contains(sampleSize), !materials.isEmpty, materials.count <= 32,
              materials.allSatisfy({ !$0.isEmpty && $0.count <= 60 }), Set(materials).count == materials.count,
              !oreID.isEmpty, oreID.count <= 60, biomeID.count <= 40 else { return false }
        return true
    }
}
struct OrePresetCollection: Codable, Equatable {
    var version = 1
    var presets: [OrePreset] = []
    var valid: Bool { version == 1 && presets.count <= 100 && presets.allSatisfy(\.valid) && Set(presets.map(\.id)).count == presets.count }
}
