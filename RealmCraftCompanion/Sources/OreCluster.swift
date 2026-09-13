import Foundation

/// Six-face connectivity in measured data, never inferred from mesh visibility or aggregate counts.
struct OreCluster {
    struct Cell: Hashable { let x: Int, y: Int, z: Int }
    let cells: Set<Cell>
    let touchesBoundary: Bool
    let touchesMissing: Bool
    let limited: Bool
    var incomplete: Bool { touchesBoundary || touchesMissing || limited }
    var minY: Int { cells.map(\.y).min() ?? 0 }
    var maxY: Int { cells.map(\.y).max() ?? 0 }
    static let limit = 65_536

    static func find(spatial: OreSpatial, bounds b: [Int], start: Cell, blockIDs: Set<Int>,
                     limit: Int = Self.limit, checkCancellation: () throws -> Void = {}) throws -> Self {
        try OreLayerMesh.validate(spatial: spatial, bounds: b)
        guard limit > 0, limit <= Self.limit, !blockIDs.isEmpty,
              blockIDs.isDisjoint(with: [0,639,65535]),
              let id = spatial.cell(x:start.x,y:start.y,z:start.z,bounds:b), blockIDs.contains(id) else {
            throw OreError("No measured material at this point / Kein gemessenes Material an dieser Position")
        }
        var cells: Set<Cell> = [start], queue = [start], head = 0
        var boundary = false, missing = false, limited = false
        while head < queue.count {
            if head % 256 == 0 { try checkCancellation() }
            let cell = queue[head]; head += 1
            for n in OreLayerMesh.normals {
                let p = Cell(x:cell.x+n[0],y:cell.y+n[1],z:cell.z+n[2])
                guard (b[0]...b[1]).contains(p.x), (b[2]...b[3]).contains(p.y), (b[4]...b[5]).contains(p.z) else {
                    boundary = true; continue
                }
                if cells.contains(p) { continue }
                guard let id = spatial.cell(x:p.x,y:p.y,z:p.z,bounds:b) else { missing = true; continue }
                guard blockIDs.contains(id) else { continue }
                guard cells.count < limit else { limited = true; continue }
                cells.insert(p); queue.append(p)
            }
        }
        try checkCancellation()
        return Self(cells:cells,touchesBoundary:boundary,touchesMissing:missing,limited:limited)
    }

    /// Highlight only the current cutaway, including buried cells; never imply the entire cluster is visible.
    func faces(in b: [Int]) -> [OreLayerMesh.Face] {
        let shown = Set(cells.filter { (b[0]...b[1]).contains($0.x) && (b[2]...b[3]).contains($0.y) && (b[4]...b[5]).contains($0.z) })
        return shown.flatMap { p in
            OreLayerMesh.normals.enumerated().compactMap { side,n in
                shown.contains(Cell(x:p.x+n[0],y:p.y+n[1],z:p.z+n[2])) ? nil :
                    OreLayerMesh.Face(x:p.x,y:p.y,z:p.z,side:side)
            }
        }
    }
}
