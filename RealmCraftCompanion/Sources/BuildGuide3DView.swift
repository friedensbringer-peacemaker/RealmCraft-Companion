import SwiftUI
import SceneKit

struct BuildGuide3DView: View {
    let guide: BuildGuide
    let blocks: [String: BuildBlock]
    let step: Int
    let english: Bool
    let select: (String, String) -> Void
    @State private var level: Double? = nil
    @State private var orbit = BuildOrbitCamera()
    @AppStorage("buildGuideIconDisplay") private var useIcons = false
    @AppStorage("companionIconPack") private var pack = "kenney"
    @ObservedObject private var store = ItemIconStore.shared
    var body: some View {
        if let model = BuildVoxelCatalog.guides[guide.id] {
            let all = model.stages.flatMap { $0 }.filter { blocks[$0.block]?.color != "air" }
            let low = all.map(\.y).min() ?? 0
            let high = all.map(\.y).max() ?? 0
            let ceiling = Int(level ?? Double(high))
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(model.complete ? (english ? "3D build model" : "3D-Baumodell") : (english ? "3D slice model · partial" : "3D-Schnittmodell · unvollständig")).font(.headline)

                }
                HStack(spacing: 8) {
                    Button { orbit.rotate(horizontal: -.pi / 8, vertical: 0) } label: { Label(english ? "Left" : "Links", systemImage: "arrow.uturn.left") }
                    Button { orbit.rotate(horizontal: .pi / 8, vertical: 0) } label: { Label(english ? "Right" : "Rechts", systemImage: "arrow.uturn.right") }
                    Button { orbit.rotate(horizontal: 0, vertical: 0.2) } label: { Label(english ? "From above" : "Von oben", systemImage: "arrow.down.right") }
                    Button { orbit.rotate(horizontal: 0, vertical: -0.2) } label: { Label(english ? "Flatter" : "Flacher", systemImage: "arrow.right") }
                    Spacer()
                    Button { orbit = BuildOrbitCamera() } label: { Label(english ? "Reset view" : "Ansicht zurücksetzen", systemImage: "arrow.counterclockwise") }
                        .help(english ? "Reset view" : "Ansicht zurücksetzen")
                    Button { orbit.magnify(-0.15) } label: { Image(systemName: "minus.magnifyingglass") }
                        .help(english ? "Zoom out" : "Verkleinern").accessibilityLabel(english ? "Zoom out" : "Verkleinern").disabled(orbit.zoom >= 2.8)
                    Button { orbit.magnify(0.15) } label: { Image(systemName: "plus.magnifyingglass") }
                        .help(english ? "Zoom in" : "Vergrößern").accessibilityLabel(english ? "Zoom in" : "Vergrößern").disabled(orbit.zoom <= 1)
                }.labelStyle(.iconOnly).controlSize(.small)
                BuildGuideScene(guideID: guide.id, model: model, blocks: blocks, step: step, ceiling: ceiling,
                    icons: useIcons, pack: IconPack(rawValue: pack) ?? .kenney, installed: store.installed,
                    orbit: $orbit, select: select)
                    .frame(height: 420).clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel(english ? "Interactive 3D build preview" : "Interaktive 3D-Bauvorschau")
                HStack {
                    Text(english ? "Show through y=\(ceiling)" : "Anzeigen bis y=\(ceiling)").font(.caption.monospaced())
                    if high > low {
                        Slider(value: Binding(get: { level ?? Double(high) }, set: { level = $0 }), in: Double(low)...Double(high), step: 1)
                            .accessibilityLabel(english ? "Cutaway height" : "Höhe des Schnitts")
                    }
                    Button(english ? "All layers" : "Alle Ebenen") { level = nil }
                }
                Text(english ? "Drag to rotate · pinch or ± to zoom · click a block for details" : "Ziehen zum Drehen · Aufziehen oder ± zum Zoomen · Block anklicken für Details")
                    .font(.caption).foregroundStyle(.secondary)
                if !model.complete {
                    Text(english ? "Partial model: only documented slices are shown." : "Teilmodell: Nur dokumentierte Schnitte werden gezeigt.").font(.caption).foregroundStyle(.orange)
                }
                DisclosureGroup(english ? "About this preview" : "Hinweise zur Vorschau") {
                Text(model.complete
                     ? (english ? "Schematic geometry from the build data, not a game simulation. Glass is transparent; stairs and slabs use simplified shapes. No water, growth or machine animation is claimed." : "Schematische Geometrie aus den Baudaten, keine Spielsimulation. Glas ist transparent; Treppen und Stufen sind vereinfacht geformt. Wasser, Wachstum und Maschinen werden nicht simuliert.")
                     : (english ? "This older guide only documents individual slices. The model shows those known cells; unseen walls, depth and attachments are not reconstructed. Use the step text and 2D diagrams for placement." : "Diese ältere Anleitung dokumentiert nur einzelne Schnitte. Das Modell zeigt diese bekannten Zellen; verdeckte Wände, Tiefe und Anbauteile werden nicht ergänzt. Zum Platzieren Schritttext und 2D-Raster beachten."))
                    .font(.caption).foregroundStyle(.secondary)
                }
            }
        } else {
            Text(english ? "No validated 3D data available for this guide. Use the 2D grids." : "Für diese Anleitung liegen keine geprüften 3D-Daten vor. Bitte die 2D-Raster verwenden.")
        }
    }
}

struct BuildGuideScene: NSViewRepresentable {
    let guideID: String
    let model: BuildVoxelGuide
    let blocks: [String: BuildBlock]
    let step: Int
    let ceiling: Int
    let icons: Bool
    let pack: IconPack
    let installed: Set<IconPack>
    @Binding var orbit: BuildOrbitCamera
    let select: (String, String) -> Void
    final class Coordinator: NSObject {
        var key = ""
        var selected: ((String, String) -> Void)?
        func clicked(_ point: NSPoint, in view: SCNView) {
            for hit in view.hitTest(point, options: nil) {
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name, name.hasPrefix("block|") {
                        let parts = name.split(separator: "|").map(String.init)
                        if parts.count == 5 { selected?(parts[1], "x=\(parts[2]), y=\(parts[3]), z=\(parts[4])") }
                        return
                    }
                    node = current.parent
                }
            }
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> BuildOrbitSceneView {
        let view = BuildOrbitSceneView()
        view.scene = SCNScene(); view.backgroundColor = NSColor(calibratedRed: 0.10, green: 0.13, blue: 0.17, alpha: 1)
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = false
        let camera = SCNNode(); camera.name = "camera"; camera.camera = SCNCamera()
        camera.camera?.zNear = 0.05; camera.camera?.zFar = 10000
        camera.camera?.fieldOfView = 60; camera.camera?.projectionDirection = .vertical
        view.scene?.rootNode.addChildNode(camera); view.pointOfView = camera
        let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light?.type = .ambient; ambient.light?.intensity = 650
        view.scene?.rootNode.addChildNode(ambient)
        let sun = SCNNode(); sun.light = SCNLight(); sun.light?.type = .omni; sun.light?.intensity = 1100
        sun.position = SCNVector3(-20, 40, -30); view.scene?.rootNode.addChildNode(sun)
        view.pick = { [weak view, weak coordinator = context.coordinator] point in
            guard let view else { return }; coordinator?.clicked(point, in: view)
        }
        return view
    }
    func updateNSView(_ view: BuildOrbitSceneView, context: Context) {
        view.rotate = { x, y in orbit.rotate(horizontal: x, vertical: y) }
        view.zoom = { amount in orbit.magnify(amount) }
        view.orbit = orbit
        context.coordinator.selected = select
        let key = "\(guideID)|\(step)|\(ceiling)|\(icons)|\(pack.rawValue)|\(installed.contains(pack))"
        let all = model.stages.flatMap { $0 }.filter { blocks[$0.block]?.color != "air" }
        guard let minX = all.map(\.x).min(), let maxX = all.map(\.x).max(),
              let minY = all.map(\.y).min(), let maxY = all.map(\.y).max(),
              let minZ = all.map(\.z).min(), let maxZ = all.map(\.z).max() else { return }
        if context.coordinator.key != key {
            context.coordinator.key = key
            view.scene?.rootNode.childNode(withName: "build", recursively: false)?.removeFromParentNode()
            let group = SCNNode(); group.name = "build"
            let previous = step > 0 ? Set(model.stages[step - 1]) : []
            let current = model.stages[step].filter { $0.y <= ceiling && blocks[$0.block]?.color != "air" }
            var materials: [String: SCNMaterial] = [:]
            let occupied = Set(current.map(\.coordinate))
            for voxel in current {
                guard let block = blocks[voxel.block] else { continue }
                let isNew = !previous.contains(voxel)
                let materialKey = "\(voxel.block)|\(isNew)"
                let material: SCNMaterial
                if let cached = materials[materialKey] { material = cached }
                else {
                    material = SCNMaterial(); material.lightingModel = .lambert
                    let glass = [72, 217].contains(block.itemID ?? -1)
                    if icons, let id = BuildGuideTexture.surfaceID(for: block), let image = ItemIconStore.shared.image(for: id, pack: pack) {
                        material.diffuse.contents = BuildGuideTexture.image(image, for: block)
                    } else { material.diffuse.contents = color(block.color) }
                    material.diffuse.magnificationFilter = .nearest; material.diffuse.minificationFilter = .nearest
                    material.emission.contents = isNew ? NSColor(calibratedRed: 0.04, green: 0.20, blue: 0.09, alpha: 1) : NSColor.black
                    if glass { material.transparency = 0.28; material.isDoubleSided = true; material.writesToDepthBuffer = false }
                    materials[materialKey] = material
                }
                let node = geometry(voxel, block: block, occupied: occupied, material: material)
                node.name = "block|\(voxel.block)|\(voxel.x)|\(voxel.y)|\(voxel.z)"
                node.position = SCNVector3(voxel.x, voxel.y, voxel.z)
                group.addChildNode(node)
            }
            // Local coordinate floor, visible even when the selected stage is still empty.
            let gridMaterial = SCNMaterial(); gridMaterial.diffuse.contents = NSColor.gray.withAlphaComponent(0.45)
            for x in minX...maxX + 1 {
                let line = SCNNode(geometry: SCNBox(width: 0.015, height: 0.015, length: CGFloat(maxZ-minZ+1), chamferRadius: 0))
                line.geometry?.materials = [gridMaterial]; line.position = SCNVector3(Double(x)-0.5, Double(minY)-0.53, Double(minZ+maxZ)/2)
                group.addChildNode(line)
            }
            for z in minZ...maxZ + 1 {
                let line = SCNNode(geometry: SCNBox(width: CGFloat(maxX-minX+1), height: 0.015, length: 0.015, chamferRadius: 0))
                line.geometry?.materials = [gridMaterial]; line.position = SCNVector3(Double(minX+maxX)/2, Double(minY)-0.53, Double(z)-0.5)
                group.addChildNode(line)
            }
            for (text,position) in [("+X",SCNVector3(maxX+2,minY,minZ)),("+Z",SCNVector3(minX,minY,maxZ+2)),("+Y",SCNVector3(minX,maxY+2,minZ))] {
                let shape = SCNText(string: text, extrusionDepth: 0.01); shape.font = NSFont.monospacedSystemFont(ofSize: 1, weight: .bold)
                shape.firstMaterial?.diffuse.contents = NSColor.white
                let label = SCNNode(geometry: shape); label.position = position; label.scale = SCNVector3(0.7,0.7,0.7)
                label.constraints = [SCNBillboardConstraint()]; group.addChildNode(label)
            }
            view.scene?.rootNode.addChildNode(group)
        }
        view.target = SCNVector3(Double(minX+maxX)/2,Double(minY+maxY)/2,Double(minZ+maxZ)/2)
        let dx = Double(maxX-minX+1), dy = Double(maxY-minY+1), dz = Double(maxZ-minZ+1)
        view.radius = sqrt(dx*dx+dy*dy+dz*dz)/2 + 1
        view.updateCamera()
    }
    private func color(_ key: String) -> NSColor {
        switch key {
        case "wood": return NSColor(calibratedRed: 0.61, green: 0.40, blue: 0.22, alpha: 1)
        case "plant": return .systemGreen
        case "water": return .systemCyan
        case "soil": return .brown
        case "signal": return .systemRed
        case "light": return .systemYellow
        case "machine", "metal": return .lightGray
        default: return NSColor(calibratedWhite: 0.58, alpha: 1)
        }
    }
    private func geometry(_ voxel: BuildVoxel, block: BuildBlock, occupied: Set<String>, material: SCNMaterial) -> SCNNode {
        let node = SCNNode(); let key = voxel.block; let id = block.itemID ?? -1
        func box(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ x: CGFloat = 0, _ y: CGFloat = 0, _ z: CGFloat = 0) {
            let shape = SCNBox(width: w, height: h, length: d, chamferRadius: 0)
            if [152, 261, 466, 199, 259].contains(id) {
                // Tile scale follows each face's physical size, including half-height sides.
                shape.materials = [(w,h),(d,h),(w,h),(d,h),(w,d),(w,d)].map { width, height in
                    let face = material.copy() as! SCNMaterial
                    face.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1)
                    return face
                }
            } else { shape.materials = [material] }
            let part = SCNNode(geometry: shape); part.position = SCNVector3(x,y,z); node.addChildNode(part)
        }
        if [152,261].contains(id) || key == "stairs" {
            box(0.98,0.5,0.98,0,-0.25,0)
            let px = key.hasSuffix("_px") || key == "stairs", nx = key.hasSuffix("_nx"), nz = key.hasSuffix("_nz")
            if px || nx { box(0.5,0.5,0.98,px ? 0.25 : -0.25,0.25,0) }
            else { box(0.98,0.5,0.5,0,0.25,nz ? -0.25 : 0.25) }
        } else if id == 466 { box(0.98,0.5,0.98,0,-0.25,0)
        } else if id == 412 { box(0.98,0.06,0.98,0,-0.47,0)
        } else if [170,97,98,179].contains(id) || key == "R" { box(0.94,0.07,0.94,0,-0.465,0)
        } else if id == 168 { box(0.98,1.0,0.14)
        } else if id == 259 {
            box(0.12,0.98,0.16,-0.43,0,0); box(0.12,0.98,0.16,0.43,0,0)
            box(0.76,0.14,0.14,0,0.25,0); box(0.76,0.14,0.14,0,-0.15,0)
        } else if [230,393].contains(id) { box(0.98,0.14,0.98,0,0.43,0)
        } else if id == 169 {
            let back = key == "uw_ladder_back"
            if key == "ladder" { box(0.12,0.98,0.75,0.43,0,0) }
            else { box(0.75,0.98,0.12,0,0,back ? 0.43 : -0.43) }
        } else if id == 199 {
            box(0.22,0.98,0.22)
            for (dx,dz) in [(1,0),(-1,0),(0,1),(0,-1)] where occupied.contains("\(voxel.x+dx),\(voxel.y),\(voxel.z+dz)") {
                for y in [CGFloat(-0.15),CGFloat(0.25)] { box(dx == 0 ? 0.12 : 0.5,0.12,dz == 0 ? 0.12 : 0.5,CGFloat(dx)*0.25,y,CGFloat(dz)*0.25) }
            }
        } else if id == 95 {
            // Two occupied cells form one bed; never repeat the whole inventory bed image.
            func bedPart(_ width: CGFloat, _ height: CGFloat, _ length: CGFloat, _ y: CGFloat, _ z: CGFloat, _ color: NSColor) {
                let shape = SCNBox(width: width, height: height, length: length, chamferRadius: 0)
                let surface = SCNMaterial(); surface.diffuse.contents = color
                surface.emission.contents = material.emission.contents
                shape.materials = [surface]
                let part = SCNNode(geometry: shape); part.position = SCNVector3(0,y,z); node.addChildNode(part)
            }
            bedPart(0.95,0.18,1,-0.36,0,.brown)
            bedPart(0.95,0.30,1,-0.12,0,.systemRed)
            if key == "pr_head" { bedPart(0.85,0.05,0.40,0.055,0.25,.white) }
        } else if id == 692 { box(0.38,0.55,0.38,0,key == "ar_hang" ? 0.2 : -0.225,0)
        } else if block.color == "plant" && key != "tree_existing" {
            box(0.08,0.8,0.75,0,-0.1,0);box(0.75,0.8,0.08,0,-0.1,0)
        } else if [178,191,147].contains(id) { box(0.2,0.5,0.2,0,-0.25,0)
        } else { box(0.98,0.98,0.98) }
        return node
    }
}

/// Own mouse handling replaces SceneKit's free pan / fly camera, including modifier gestures.
final class BuildOrbitSceneView: SCNView {
    var orbit = BuildOrbitCamera()
    var target = SCNVector3Zero
    var radius = 1.0
    var rotate: ((Double, Double) -> Void)?
    var zoom: ((Double) -> Void)?
    var pick: ((NSPoint) -> Void)?
    private var start: NSPoint?
    private var last: NSPoint?
    private var dragged = false
    override var acceptsFirstResponder: Bool { true }
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        start = convert(event.locationInWindow, from: nil); last = start; dragged = false
    }
    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let start, let last else { return }
        if hypot(point.x-start.x,point.y-start.y) > 3 { dragged = true }
        if dragged { rotate?(Double(point.x-last.x)*0.008,Double(point.y-last.y)*0.008) }
        self.last = point
    }
    override func mouseUp(with event: NSEvent) {
        if start != nil && !dragged { pick?(convert(event.locationInWindow, from: nil)) }
        start = nil; last = nil; dragged = false
    }
    override func rightMouseDown(with event: NSEvent) {}
    override func rightMouseDragged(with event: NSEvent) {}
    override func rightMouseUp(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) {}
    override func otherMouseDragged(with event: NSEvent) {}
    override func otherMouseUp(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) {
        // Page scrolling must never change the build camera, including momentum events.
        enclosingScrollView?.scrollWheel(with: event)
    }
    override func magnify(with event: NSEvent) { zoom?(Double(event.magnification)) }
    override func layout() { super.layout(); updateCamera() }
    func updateCamera() {
        guard bounds.width > 0, bounds.height > 0,
              let camera = scene?.rootNode.childNode(withName: "camera", recursively: false) else { return }
        let distance = orbit.distance(radius: radius, aspect: Double(bounds.width / bounds.height))
        let horizontal = distance * cos(orbit.elevation)
        camera.position = SCNVector3(Double(target.x)+horizontal*sin(orbit.yaw),
                                     Double(target.y)+distance*sin(orbit.elevation),
                                     Double(target.z)-horizontal*cos(orbit.yaw))
        camera.look(at: target); pointOfView = camera
    }
}
