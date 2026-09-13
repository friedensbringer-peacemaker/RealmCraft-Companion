import Foundation

@main struct OreLayerMeshTests {
    static func check(_ condition:Bool,_ message:String) { precondition(condition,message) }
    static func rejects(_ action:() throws -> Void) { do { try action(); fatalError("Expected rejection") } catch {} }
    static func data(_ ids:[Int]) -> OreSpatial {
        OreSpatial(encoding:"u16le-yzx-v1",data:Data(ids.flatMap { [UInt8($0 & 255),UInt8($0 >> 8)] }))
    }
    static func main() throws {
        let b=[-2,-1,10,11,-3,-2]
        // Y/Z/X ordering: bottom and top layers deliberately differ.
        let spatial=data([155,1,0,65535,31,639,65000,1])
        let original=spatial.data
        let top=try OreLayerMesh.build(spatial:spatial,bounds:b,y:11,depth:1,centerX:-2,centerZ:-3,selected:[31],onlySelected:false)
        check(top.bounds == [-2,-1,11,11,-3,-2],"exact single-layer coordinates")
        check(top.solid == 3 && top.air == 1 && top.missing == 0,"known air and unknown block remain distinct")
        check(top.faces[155] == nil && top.faces[31]?.allSatisfy { $0.x == -2 && $0.z == -3 && $0.y == 11 } == true,"no other layer or axis swap")
        check(top.faces[65000]?.isEmpty == false,"unknown IDs stay visible")
        let both=try OreLayerMesh.build(spatial:spatial,bounds:b,y:11,depth:8,centerX:0,centerZ:0,selected:[155,31],onlySelected:false)
        check(both.bounds == b && both.solid == 5 && both.air == 2 && both.missing == 1,"depth clips to measured range")
        check(both.faces[65535] == [.init(x:-1,y:10,z:-2,side:2)],"missing marked by one sheet, not invented solid")
        let filtered=try OreLayerMesh.build(spatial:spatial,bounds:b,y:11,depth:8,centerX:0,centerZ:0,selected:[155,31],onlySelected:true)
        check(filtered.solid == 2 && filtered.hidden == 3 && filtered.air == 2 && filtered.missing == 1,"hidden is not air; missing survives filter")
        check(filtered.faceCount == 11,"two adjacent cubes have ten exposed faces plus missing sheet")
        let empty=try OreLayerMesh.build(spatial:spatial,bounds:b,y:11,depth:1,centerX:0,centerZ:0,selected:[],onlySelected:true)
        check(empty.faceCount == 0 && empty.hidden == 3,"empty material selection has no invented geometry")
        let solid=try OreLayerMesh.build(spatial:data([1,1,1,1]),bounds:[0,1,0,0,0,1],y:0,depth:1,centerX:0,centerZ:0,selected:[],onlySelected:false)
        check(solid.faceCount == 16,"internal horizontal cube faces culled")
        for side in 0..<6 {
            let c=OreLayerMesh.corners[side], n=OreLayerMesh.normals[side]
            let a=zip(c[1],c[0]).map(-), d=zip(c[2],c[0]).map(-)
            let cross=[a[1]*d[2]-a[2]*d[1],a[2]*d[0]-a[0]*d[2],a[0]*d[1]-a[1]*d[0]]
            check(cross == n,"outward face winding")
        }
        let wide=[-200,200,0,255,-200,200]
        check(tryWindow(wide,-500,-500) == [-200,-137,0,0,-200,-137],"negative edge window")
        check(tryWindow(wide,500,500) == [137,200,0,0,137,200],"positive edge window")
        rejects { _ = try OreLayerMesh.window(bounds:b,y:9,depth:1,centerX:0,centerZ:0) }
        rejects { _ = try OreLayerMesh.window(bounds:b,y:10,depth:256,centerX:0,centerZ:0) }
        rejects { _ = try OreLayerMesh.build(spatial:data([1]),bounds:b,y:10,depth:1,centerX:0,centerZ:0,selected:[],onlySelected:false) }
        rejects { _ = try OreLayerMesh.build(spatial:spatial,bounds:b,y:10,depth:1,centerX:0,centerZ:0,selected:[],onlySelected:false) { throw CancellationError() } }
        check(spatial.data == original,"source census unchanged")
        print("PASS: 3D slice axes, negative windows, height clipping, filtering, coverage, exposed faces, winding, malformed data, cancellation and immutable input")
    }
    static func tryWindow(_ b:[Int],_ x:Int,_ z:Int) -> [Int] { try! OreLayerMesh.window(bounds:b,y:0,depth:8,centerX:x,centerZ:z) }
}
