import Foundation

@main struct OreClusterTests {
    static func main() throws {
        let b=[-3,3,8,14,-3,3]
        func sample(_ cells:[OreCluster.Cell:Int]) -> OreSpatial {
            var ids:[Int]=[]
            for y in 8...14 { for z in -3...3 { for x in -3...3 { ids.append(cells[.init(x:x,y:y,z:z)] ?? 0) } } }
            return OreSpatial(encoding:"u16le-yzx-v1",data:Data(ids.flatMap { [UInt8($0 & 255),UInt8($0 >> 8)] }))
        }
        let start=OreCluster.Cell(x:-1,y:10,z:-1)
        let positions: [OreCluster.Cell:Int]=[start:155,.init(x:-1,y:11,z:-1):156,.init(x:0,y:11,z:-1):155,
            .init(x:1,y:12,z:0):155,.init(x:-2,y:10,z:-1):31]
        let spatial=sample(positions), original=spatial.data
        let found=try OreCluster.find(spatial:spatial,bounds:b,start:start,blockIDs:[155,156])
        precondition(found.cells.count == 3 && found.minY == 10 && found.maxY == 11)
        precondition(!found.incomplete,"known air closes cluster; diagonal and gold do not connect")
        precondition(found.faces(in:[-3,3,10,10,-3,3]).count == 6,"highlight clips to slice without truncating count")
        precondition(found.faces(in:b).count == 14,"three adjacent cubes share interior faces")
        var missing=positions; missing[.init(x:-1,y:9,z:-1)]=65535
        precondition(tryFind(sample(missing),b,start).touchesMissing)
        var edge=positions; edge[.init(x:-2,y:10,z:-1)]=155; edge[.init(x:-3,y:10,z:-1)]=155
        precondition(tryFind(sample(edge),b,start).touchesBoundary)
        let limited=try OreCluster.find(spatial:spatial,bounds:b,start:start,blockIDs:[155,156],limit:2)
        precondition(limited.cells.count == 2 && limited.limited && limited.incomplete)
        let exactLimit=try OreCluster.find(spatial:spatial,bounds:b,start:start,blockIDs:[155,156],limit:3)
        precondition(!exactLimit.limited,"exact cap without omitted neighbor is complete")
        rejects { _ = try OreCluster.find(spatial:spatial,bounds:b,start:start,blockIDs:[0,155]) }
        rejects { _ = try OreCluster.find(spatial:spatial,bounds:[],start:start,blockIDs:[155]) }
        rejects { _ = try OreCluster.find(spatial:spatial,bounds:b,start:.init(x:100,y:10,z:0),blockIDs:[155]) }
        rejects { _ = try OreCluster.find(spatial:spatial,bounds:b,start:start,blockIDs:[155],limit:0) }
        rejects { _ = try OreCluster.find(spatial:spatial,bounds:b,start:start,blockIDs:[155]) { throw CancellationError() } }
        precondition(spatial.data == original)
        print("PASS: 3D six-face connectivity, variants, negative XYZ, diagonal/material isolation, clipping, unknown/boundary/cap evidence, cancellation and immutable input")
    }
    static func tryFind(_ s:OreSpatial,_ b:[Int],_ p:OreCluster.Cell) -> OreCluster { try! OreCluster.find(spatial:s,bounds:b,start:p,blockIDs:[155,156]) }
    static func rejects(_ action:() throws -> Void) { do { try action(); fatalError("Expected rejection") } catch {} }
}
