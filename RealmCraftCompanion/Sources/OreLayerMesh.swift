import Foundation

/// Read-only, bounded geometry from the census payload; no second savegame decoder.
struct OreLayerMesh {
    struct Face: Equatable {
        let x: Int, y: Int, z: Int, side: Int
    }
    let id = UUID()
    let bounds: [Int]
    let faces: [Int: [Face]]
    let solid: Int, air: Int, missing: Int, hidden: Int
    var faceCount: Int { faces.values.reduce(0) { $0 + $1.count } }
    static let sideLimit = 64
    // +X, -X, +Y, -Y, +Z, -Z. Missing cells use a flat +Y marker, never an invented cube.
    static let normals = [[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]]
    static let corners = [
        [[1,0,0],[1,1,0],[1,1,1],[1,0,1]],
        [[0,0,1],[0,1,1],[0,1,0],[0,0,0]],
        [[0,1,1],[1,1,1],[1,1,0],[0,1,0]],
        [[0,0,0],[1,0,0],[1,0,1],[0,0,1]],
        [[1,0,1],[1,1,1],[0,1,1],[0,0,1]],
        [[0,0,0],[0,1,0],[1,1,0],[1,0,0]]
    ]
    static func window(bounds b: [Int], y: Int, depth: Int, centerX: Int, centerZ: Int) throws -> [Int] {
        guard b.count == 6, b.allSatisfy({ (-30_000_000...30_000_000).contains($0) }),
              b[0] <= b[1], b[4] <= b[5], b[2] >= 0, b[3] <= 255, b[2] <= b[3],
              (b[2]...b[3]).contains(y), [1,4,8].contains(depth) else { throw OreError("Invalid 3D region / Ungültiger 3D-Bereich") }
        func start(_ center: Int, _ low: Int, _ high: Int) -> Int {
            let count = min(sideLimit, high-low+1), bounded = min(high,max(low,center))
            return min(high-count+1,max(low,bounded-count/2))
        }
        let x = start(centerX,b[0],b[1]), z = start(centerZ,b[4],b[5])
        return [x,x+min(sideLimit,b[1]-b[0]+1)-1,max(b[2],y-depth+1),y,z,z+min(sideLimit,b[5]-b[4]+1)-1]
    }
    static func build(spatial: OreSpatial, bounds b: [Int], y: Int, depth: Int, centerX: Int, centerZ: Int,
                      selected: Set<Int>, onlySelected: Bool, checkCancellation: () throws -> Void = {}) throws -> Self {
        let w = try window(bounds:b,y:y,depth:depth,centerX:centerX,centerZ:centerZ)
        try validate(spatial:spatial,bounds:b)
        let nx=w[1]-w[0]+1, ny=w[3]-w[2]+1, nz=w[5]-w[4]+1
        var cells = [Int](repeating:65535,count:nx*ny*nz)
        var solid=0, air=0, missing=0, hidden=0
        func index(_ x:Int,_ y:Int,_ z:Int) -> Int { (y*nz+z)*nx+x }
        for ly in 0..<ny {
            try checkCancellation()
            for lz in 0..<nz { for lx in 0..<nx {
                let id = spatial.cell(x:lx+w[0],y:ly+w[2],z:lz+w[4],bounds:b)
                if let id {
                    if id == 0 || id == 639 { air += 1; cells[index(lx,ly,lz)] = 0 }
                    else if onlySelected && !selected.contains(id) { hidden += 1; cells[index(lx,ly,lz)] = 0 }
                    else { solid += 1; cells[index(lx,ly,lz)] = id }
                } else { missing += 1 }
            }}
        }
        var faces: [Int:[Face]] = [:]
        for ly in 0..<ny {
            try checkCancellation()
            for lz in 0..<nz { for lx in 0..<nx {
                let id=cells[index(lx,ly,lz)]
                guard id != 0 else { continue }
                if id == 65535 {
                    faces[id,default:[]].append(.init(x:lx+w[0],y:ly+w[2],z:lz+w[4],side:2)); continue
                }
                for (side,n) in normals.enumerated() {
                    let x=lx+n[0], y=ly+n[1], z=lz+n[2]
                    let neighbor = x>=0 && x<nx && y>=0 && y<ny && z>=0 && z<nz ? cells[index(x,y,z)] : 0
                    if neighbor == 0 || neighbor == 65535 {
                        faces[id,default:[]].append(.init(x:lx+w[0],y:ly+w[2],z:lz+w[4],side:side))
                    }
                }
            }}
        }
        return Self(bounds:w,faces:faces,solid:solid,air:air,missing:missing,hidden:hidden)
    }
    static func validate(spatial: OreSpatial, bounds b: [Int]) throws {
        guard b.count == 6 else { throw OreError("Invalid region / Ungültiger Bereich") }
        _ = try window(bounds:b,y:b[2],depth:1,centerX:b[0],centerZ:b[4])
        let size = Double(b[1]-b[0]+1)*Double(b[3]-b[2]+1)*Double(b[5]-b[4]+1)
        guard spatial.encoding == "u16le-yzx-v1", size <= 4_194_304, spatial.data.count == Int(size)*2 else {
            throw OreError("No valid spatial census data / Keine gültigen räumlichen Messdaten")
        }
    }
}
