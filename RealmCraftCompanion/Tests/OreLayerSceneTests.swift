import SwiftUI
import SceneKit

/// Synthetic native-render smoke test. No application profile, library, network or device access.
@main struct OreLayerSceneTests {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let suite="realmcraft.ore-camera-test."+UUID().uuidString, defaults=UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        precondition(OreCameraPreset.load(defaults:defaults) == nil)
        var saved=BuildOrbitCamera.ore; saved.rotate(horizontal:0.8,vertical:0.3); saved.restoreZoom(0.15)
        OreCameraPreset.save(saved,defaults:defaults)
        let loaded=OreCameraPreset.load(defaults:defaults)!
        precondition(abs(loaded.yaw-saved.yaw)<1e-10 && abs(loaded.elevation-saved.elevation)<1e-10 && abs(loaded.zoom-saved.zoom)<1e-10)
        defaults.set([0,100,1.2],forKey:OreCameraPreset.key)
        precondition(OreCameraPreset.load(defaults:defaults) == nil,"malformed persisted camera rejected")
        let output=URL(fileURLWithPath:CommandLine.arguments[1],isDirectory:true)
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        let b=[-16,15,8,15,-16,15]
        var ids:[Int]=[]
        for y in 8...15 { for z in -16...15 { for x in -16...15 {
            var id=1
            if x < -12 && z > 10 { id=65535 }
            else if abs(z) < 2 && y >= 13 { id=0 }
            else if (x+8)*(x+8)+(z+7)*(z+7)<14 { id=155 }
            else if (x-6)*(x-6)+(z-8)*(z-8)<10 { id=31 }
            else if x > 8 && z < -8 { id=26 }
            ids.append(id)
        }}}
        let spatial=OreSpatial(encoding:"u16le-yzx-v1",data:Data(ids.flatMap { [UInt8($0 & 255),UInt8($0 >> 8)] }))
        for only in [false,true] {
            let mesh=try OreLayerMesh.build(spatial:spatial,bounds:b,y:15,depth:4,centerX:0,centerZ:0,selected:[31,155],onlySelected:only)
            let capture=OreSceneCapture()
            let cluster=try OreCluster.find(spatial:spatial,bounds:b,start:.init(x:-8,y:15,z:-7),blockIDs:[155,156])
            let root=OreLayerScene(mesh:mesh,materials:["gold","diamond"],orbit:.constant(.ore),select:{ _,_ in },capture:capture,cluster:cluster,clusterID:UUID())
            let host=NSHostingView(rootView:root); host.frame=NSRect(x:0,y:0,width:1000,height:650)
            let window=NSWindow(contentRect:host.frame,styleMask:[.borderless],backing:.buffered,defer:false)
            window.contentView=host
            host.layoutSubtreeIfNeeded()
            RunLoop.current.run(until:Date().addingTimeInterval(0.3))
            func find(_ view:NSView) -> BuildOrbitSceneView? {
                if let scene=view as? BuildOrbitSceneView { return scene }
                for child in view.subviews { if let result=find(child) { return result } }
                return nil
            }
            guard let scene=find(host), let data=scene.snapshot().tiffRepresentation,
                  let image=NSBitmapImageRep(data:data), let png=image.representation(using:.png,properties:[:]) else { fatalError("No rendered 3D scene") }
            precondition(scene.scene?.rootNode.childNode(withName:"ore",recursively:false) != nil)
            precondition(scene.scene?.rootNode.childNode(withName:"cluster",recursively:false) != nil)
            precondition(capture.view === scene && capture.meshID == mesh.id)
            precondition(scene.fitDimensions != nil)
            for _ in 0..<6 {
                let before=scene.pointOfView!.position
                scene.orbit.magnify(0.15); scene.updateCamera()
                let after=scene.pointOfView!.position
                precondition(before.x != after.x && before.y != after.y, "Repeated zoom updates the rendered camera")
            }
            scene.orbit.fit(); scene.updateCamera()
            let projected=scene.projectPoint(SCNVector3(8.5,4,9.5))
            let hits=scene.hitTest(NSPoint(x:CGFloat(projected.x),y:CGFloat(projected.y)),options:nil)
            guard let hit=hits.first(where: { $0.node.name == "155" }), let faces=mesh.faces[155] else { fatalError("Known diamond cannot be picked") }
            let cell=faces[hit.faceIndex/2]
            precondition(cell.x == -8 && cell.y == 15 && cell.z == -7,"Hit-test preserves exact negative world coordinates")
            try png.write(to:output.appendingPathComponent(only ? "ore-selected.png" : "ore-context.png"))
            let stamped=try OreImageExport.png(scene:scene.snapshot(),lines:["RealmCraft Companion · Synthetic 3D test", "X −16…15 · Y 12…15 · Z −16…15 · N = −Z", "Measured: 2026-01-01T12:00:00Z", "Missing data is not air. Orange: measured six-face connectivity; possibly incomplete at measurement boundaries."],legend:[.init(name:"Diamond",color:NSColor(OreMaterial.byBlock[155]!.color)),.init(name:"Gold",color:NSColor(OreMaterial.byBlock[31]!.color)),.init(name:"Missing / unknown",color:.systemPurple),.init(name:"3D connectivity",color:.systemOrange)])
            let exported=NSBitmapImageRep(data:stamped)!
            precondition(exported.pixelsHigh > image.pixelsHigh,"metadata and color legend are baked into image")
            try stamped.write(to:output.appendingPathComponent(only ? "ore-selected-export.png" : "ore-context-export.png"))
            // Orbit gestures use the shared bounded camera; no free pan is enabled.
            precondition(!scene.allowsCameraControl)
            window.contentView=nil
        }
        let scan=OreScan(schema:1,dimension:"o",bounds:b,expected:1,scanned:1,missing:[:],errors:[],metadataErrors:[],levels:[],hashes:[:],beforeHashes:[:],chests:[],beforeChests:[],probe:nil,biomes:nil,sampling:nil,spatial:spatial)
        for english in [false,true] {
            let root=ScrollView { OreLayer3DView(scan:scan,y:.constant(15),materials:["gold","diamond"],english:english,initialCenter:nil,planHere:{ _,_,_ in },showOnMap:nil,measuredAt:Date(timeIntervalSince1970:1767268800)).padding(20) }.background(Color(NSColor.windowBackgroundColor)).preferredColorScheme(.dark)
            let host=NSHostingView(rootView:root); host.frame=NSRect(x:0,y:0,width:1000,height:950)
            let window=NSWindow(contentRect:host.frame,styleMask:[.titled,.closable,.resizable],backing:.buffered,defer:false); window.contentView=host
            host.layoutSubtreeIfNeeded(); RunLoop.current.run(until:Date().addingTimeInterval(1))
            let bitmap=host.bitmapImageRepForCachingDisplay(in:host.bounds)!
            host.cacheDisplay(in:host.bounds,to:bitmap)
            try bitmap.representation(using:.png,properties:[:])!.write(to:output.appendingPathComponent(english ? "ore-ui-en.png" : "ore-ui-de.png"))
            if english && CommandLine.arguments.contains("--interactive") {
                window.title="Ore 3D QA · synthetic data only"
                NSApplication.shared.setActivationPolicy(.regular)
                window.center(); window.makeKeyAndOrderFront(nil); NSApplication.shared.activate(ignoringOtherApps:true)
                NSApplication.shared.run()
            }
            window.contentView=nil
        }
        print("PASS: native SceneKit context/selected-only render, exact XYZ picking and shared camera; synthetic PNGs written")
    }
}
