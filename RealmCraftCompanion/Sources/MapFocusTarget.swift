import Foundation

struct MapFocusTarget: Codable, Equatable {
    var id = UUID().uuidString
    let saveID: String
    let world: String
    let dimension: String
    let x: Int
    let y: Int
    let z: Int
    let blockID: Int
    var valid: Bool { ["o", "n"].contains(dimension) && (0...255).contains(y) && abs(Int64(x)) <= 30_000_000 && abs(Int64(z)) <= 30_000_000 && (0..<65535).contains(blockID) }
}
