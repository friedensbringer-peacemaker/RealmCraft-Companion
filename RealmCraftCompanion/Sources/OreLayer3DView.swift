import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct OreLayer3DView: View {
    let scan: OreScan
    @Binding var y: Int
    let materials: Set<String>
    let english: Bool
    let initialCenter: CGPoint?
    let planHere: (Int,Int,Int) -> Void
    let showOnMap: ((Int,Int,Int,Int) -> Void)?
    var measuredAt: Date? = nil
    var availableLayers: [Int] = []
    var stepLayer: (Int) -> Void = { _ in }
    @State private var depth = 1
    @State private var onlySelected = false
    @State private var center: CGPoint?
    @State private var orbit = BuildOrbitCamera.ore
    @State private var mesh: OreLayerMesh?
    @State private var renderedRequest = ""
    @State private var failure = ""
    @State private var picked: OreLayerMesh.Face?
    @State private var pickedID = 0
    @State private var expanded = false
    @State private var capture = OreSceneCapture()
    @State private var presentationNotice = ""
    @State private var cluster: OreCluster?
    @State private var clusterID: UUID?
    @State private var clusterStatus = ""
    @State private var clusterResultKey = ""
    @State private var loadedCamera = false
    private var clusterRequest: String { request + (picked.map { ":\($0.x):\($0.y):\($0.z):\(pickedID)" } ?? ":none") }
    private var displayedCluster: OreCluster? { clusterResultKey == clusterRequest ? cluster : nil }
    private var displayedClusterStatus: String { clusterResultKey == clusterRequest ? clusterStatus : "" }
    @AppStorage("exploration.spoilerFree") private var spoilerFree = false
    private var cx: Int { Int((center ?? initialCenter)?.x ?? Double(scan.bounds[0]+scan.bounds[1])/2) }
    private var cz: Int { Int((center ?? initialCenter)?.y ?? Double(scan.bounds[4]+scan.bounds[5])/2) }
    private var request: String { "\(y):\(depth):\(cx):\(cz):\(onlySelected):\(spoilerFree):" + materials.sorted().joined(separator:",") }
    private var current: OreLayerMesh? { renderedRequest == request && !spoilerFree ? mesh : nil }
    private func t(_ de:String,_ en:String) -> String { english ? en : de }
    var body: some View {
        VStack(alignment:.leading) {
            if expanded { Text(t("Große 3D-Ansicht geöffnet", "Large 3D view open")).font(.caption) }
            else { content }
        }
        .sheet(isPresented:$expanded) {
            VStack(spacing:0) {
                HStack { Text(t("Erzhäufigkeit · 3D-Schnitt", "Ore frequency · 3D cutaway")).font(.headline); Spacer(); Button(t("Schließen", "Close")) { expanded=false }.keyboardShortcut(.cancelAction) }.padding()
                OreLayerControls(y: $y, bounds: scan.bounds[2]...scan.bounds[3], available: availableLayers, english: english, step: stepLayer)
                ScrollView { content.padding() }
            }.frame(minWidth:640,idealWidth:960,maxWidth:.infinity,minHeight:480,idealHeight:650,maxHeight:.infinity)
        }
        .task(id:request) { await rebuild() }
        .task(id:clusterRequest) { await inspectCluster() }
        .onAppear { if !loadedCamera { loadedCamera=true; if let saved=OreCameraPreset.load() { orbit=saved } } }
    }
    private var content: some View {
        VStack(alignment:.leading,spacing:10) {
            if spoilerFree {
                ContentUnavailableView(t("3D im Spoiler-light-Modus ausgeblendet", "3D hidden in spoiler-light mode"),systemImage:"eye.slash",
                    description:Text(t("Unter Einstellungen → Erkundung & Spoiler ändern.", "Change this under Settings → Exploration & spoilers."))).frame(height:360)
            } else if scan.spatial == nil {
                ContentUnavailableView(t("Räumliche Messdaten erforderlich", "Spatial census required"),systemImage:"cube.transparent",
                    description:Text(t("Einen begrenzten Bereich erneut mit Blöcke zählen messen. Zufallsstichproben und reine Summen enthalten keine 3D-Geometrie.", "Count blocks again for a bounded region. Random samples and aggregate-only reports contain no 3D geometry."))).frame(height:360)
            } else {
                if let current {
                    Text(t("Angezeigt: Y \(current.bounds[2])–\(current.bounds[3])", "Displayed: Y \(current.bounds[2])–\(current.bounds[3])"))
                        .font(.title3.bold()).monospacedDigit().accessibilityAddTraits(.updatesFrequently)
                } else {
                    Text(t("Gewählt: Y \(y) · noch nicht dargestellt", "Selected: Y \(y) · not yet displayed"))
                        .font(.headline).foregroundStyle(.secondary)
                }
                HStack {
                    Text(t("Schnittdicke", "Slice depth"))
                    Picker(t("Schnittdicke", "Slice depth"),selection:$depth) {
                        Text(t("Nur diese Ebene", "This layer only")).tag(1)
                        Text(t("4 Ebenen", "4 layers")).tag(4)
                        Text(t("8 Ebenen", "8 layers")).tag(8)
                    }.labelsHidden().frame(width:150)
                    .accessibilityLabel(t("Schnittdicke", "Slice depth"))
                    Toggle(t("Nur gewählte Materialien", "Selected materials only"),isOn:$onlySelected).font(.caption)
                }
                cameraControls
                HStack {
                    if !expanded { Button(t("Große Ansicht", "Large view")) { expanded=true } }
                    Button(t("Kamera merken", "Save camera")) { OreCameraPreset.save(orbit); presentationNotice=t("Kamera gespeichert; wird beim nächsten Öffnen wiederhergestellt.", "Camera saved; restored the next time this view opens.") }
                    Button(t("Kamera laden", "Restore camera")) { if let saved=OreCameraPreset.load() { orbit=saved; presentationNotice="" } else { presentationNotice=t("Keine gültige Kameraposition gespeichert.", "No valid saved camera.") } }
                    Spacer()
                    Button(t("Bild exportieren …", "Export image…")) { exportImage() }.disabled(current == nil)
                }.controlSize(.small)
                if !presentationNotice.isEmpty { Text(presentationNotice).font(.caption).textSelection(.enabled) }
                if let current {
                    OreLayerScene(mesh:current,materials:materials,orbit:$orbit,select:{ face,id in picked=face; pickedID=id },capture:capture,cluster:displayedCluster,clusterID:displayedCluster == nil ? nil : clusterID)
                        .frame(maxWidth:.infinity).frame(height:expanded ? 520 : 440).clipShape(RoundedRectangle(cornerRadius:8))
                        .accessibilityLabel(t("Drehbarer 3D-Schichtausschnitt; Details auch in der 2D-Ansicht verfügbar.", "Rotatable 3D layer section; details are also available in the 2D view."))
                    let b=current.bounds
                    Text("X \(b[0])…\(b[1]) · Y \(b[2])…\(b[3]) · Z \(b[4])…\(b[5])").font(.caption.monospaced())
                    Text(t("\(current.solid) sichtbare Blöcke · \(current.air) Luft · \(current.hidden) ausgefiltert · \(current.missing) fehlende Zellen", "\(current.solid) visible blocks · \(current.air) air · \(current.hidden) filtered · \(current.missing) missing cells")).font(.caption)
                    if scan.bounds[1]-scan.bounds[0]+1 > OreLayerMesh.sideLimit || scan.bounds[5]-scan.bounds[4]+1 > OreLayerMesh.sideLimit { regionControls(current) }
                } else if !failure.isEmpty { Text(failure).foregroundStyle(.orange).frame(height:360) }
                else { ProgressView(t("3D-Ausschnitt wird aufgebaut …", "Building 3D section…")).frame(maxWidth:.infinity).frame(height:360) }
                Text(t("Ziehen: drehen · Aufziehen / ±: zoomen · Klick: Blockdetails. Y ist die oberste Ebene; weitere Ebenen liegen darunter. N = −Z. Würfel sind schematisch, keine Original-Spielgrafik.", "Drag: rotate · pinch / ±: zoom · click: block details. Y is the top layer; extra layers lie below it. N = −Z. Cubes are schematic, not original game graphics.")).font(.caption).foregroundStyle(.secondary)
                Text(t("Violette Flächen: fehlende Daten, keine Luft. Violette Würfel: unbekannte Block-ID. Ausgefilterte Blöcke werden nur verborgen, nicht als abgebaut gewertet. Die Mengentabelle bezieht sich weiterhin auf die gewählte Ebene / das gesamte Messvolumen.", "Purple sheets: missing data, not air. Purple cubes: unknown block ID. Filtered blocks are hidden, not considered mined. The ledger still refers to the chosen layer / full measured volume.")).font(.caption).foregroundStyle(.secondary)
                if let picked, current != nil {
                    Text("X \(picked.x) · Y \(picked.y) · Z \(picked.z) · " + (pickedID == 65535 ? t("Daten fehlen", "Missing data") : "ID \(pickedID) · " + (OreMaterial.byBlock[pickedID]?.name(english) ?? t("Block", "Block")))).font(.caption.monospaced()).textSelection(.enabled)
                    if pickedID != 65535 {
                        HStack {
                            Button(t("Stollen planen", "Plan tunnel")) { planHere(picked.x,picked.y,picked.z) }
                            if let showOnMap { Button(t("Auf Karte zeigen", "Show on map")) { showOnMap(picked.x,picked.y,picked.z,pickedID) } }
                        }
                    }
                    if !displayedClusterStatus.isEmpty { Text(displayedClusterStatus).font(.caption).foregroundStyle(displayedCluster?.incomplete == true ? .orange : .secondary).textSelection(.enabled) }
                }
            }
        }
    }
    private func exportImage() {
        guard !spoilerFree, let current, capture.meshID == current.id, let view=capture.view else { return }
        do {
            let b=current.bounds
            let date=measuredAt.map { ISO8601DateFormatter().string(from:$0) } ?? t("nicht überliefert", "not recorded")
            let lines=[t("RealmCraft Companion · Erzhäufigkeit · schematische 3D-Ansicht", "RealmCraft Companion · Ore frequency · schematic 3D view"),
                       "\(scan.dimension == "o" ? t("Oberwelt", "Overworld") : "Nether") · X \(b[0])…\(b[1]) · Y \(b[2])…\(b[3]) · Z \(b[4])…\(b[5]) · N = −Z",
                       t("Messung: ", "Measured: ")+date,
                       t("\(current.solid) sichtbar · \(current.air) Luft · \(current.hidden) ausgefiltert · \(current.missing) fehlend. Nur dargestellter Ausschnitt.", "\(current.solid) visible · \(current.air) air · \(current.hidden) filtered · \(current.missing) missing. Displayed section only."),
                       displayedClusterStatus]
            var legend=OreMaterial.all.filter { materials.contains($0.id) }.map { OreImageExport.Legend(name:$0.name(english),color:NSColor($0.color)) }
            legend += [.init(name:t("Kontext", "Context"),color:.gray),.init(name:t("Fehlend / unbekannt", "Missing / unknown"),color:.systemPurple),.init(name:t("Wasser", "Water"),color:NSColor(calibratedRed:0.12,green:0.35,blue:0.55,alpha:1)),.init(name:t("Lava", "Lava"),color:NSColor(calibratedRed:0.85,green:0.3,blue:0.08,alpha:1))]
            if displayedCluster != nil { legend.append(.init(name:t("3D-Zusammenhang", "3D connectivity"),color:.systemOrange)) }
            let data=try OreImageExport.png(scene:view.snapshot(),lines:lines,legend:legend)
            let panel=NSSavePanel(); panel.allowedContentTypes=[.png]; panel.nameFieldStringValue="ore-layer-3d.png"
            panel.message=t("Das Bild enthält private Messdaten und Koordinaten. Es wird nur lokal gespeichert, nicht veröffentlicht.", "This image contains private measurement data and coordinates. It is saved locally, not published.")
            guard let window=view.window else { return }
            panel.beginSheetModal(for:window) { response in
                guard response == .OK, let url=panel.url, !UserDefaults.standard.bool(forKey:"exploration.spoilerFree") else { return }
                do { try data.write(to:url,options:.atomic); presentationNotice=t("Bild gespeichert.", "Image saved.") }
                catch { presentationNotice=error.localizedDescription }
            }
        } catch { presentationNotice=error.localizedDescription }
    }
    private func inspectCluster() async {
        cluster=nil; clusterID=nil; clusterStatus=""; clusterResultKey=clusterRequest
        guard !spoilerFree, let picked, let spatial=scan.spatial, let material=OreMaterial.byBlock[pickedID] else { return }
        let key=clusterRequest, bounds=scan.bounds, ids=Set(material.blocks)
        clusterStatus=t("3D-Zusammenhang wird geprüft …", "Checking 3D connectivity…")
        let worker=Task.detached(priority:.userInitiated) {
            try OreCluster.find(spatial:spatial,bounds:bounds,start:.init(x:picked.x,y:picked.y,z:picked.z),blockIDs:ids) { try Task.checkCancellation() }
        }
        do {
            let result=try await withTaskCancellationHandler(operation:{ try await worker.value },onCancel:{ worker.cancel() })
            guard !Task.isCancelled, key == clusterRequest else { return }
            cluster=result; clusterID=UUID()
            clusterStatus=t("\(result.cells.count) verbundene Blöcke · Y \(result.minY)…\(result.maxY) · \(material.name(false)). 6er-Nachbarschaft im gesamten Messvolumen; orange nur im sichtbaren Schnitt.", "\(result.cells.count) connected blocks · Y \(result.minY)…\(result.maxY) · \(material.name(true)). Six-face neighbors across the measured volume; orange only in the visible cutaway.")
            if result.incomplete { clusterStatus += t(" Möglicherweise unvollständig:", " Possibly incomplete:") }
            if result.touchesBoundary { clusterStatus += t(" Messgrenze erreicht.", " Measurement boundary reached.") }
            if result.touchesMissing { clusterStatus += t(" Fehlende Nachbardaten.", " Missing neighboring data.") }
            if result.limited { clusterStatus += t(" Sicherheitslimit 65.536 Blöcke erreicht; Anzahl ist eine Untergrenze.", " Safety limit of 65,536 blocks reached; count is a lower bound.") }
        } catch is CancellationError { }
        catch { if !Task.isCancelled, key == clusterRequest { clusterStatus=error.localizedDescription } }
    }
    private var cameraControls: some View {
        HStack {
            Button { orbit.rotate(horizontal:-.pi/8,vertical:0) } label: { Label(t("Links", "Left"),systemImage:"arrow.uturn.left") }
            Button { orbit.rotate(horizontal:.pi/8,vertical:0) } label: { Label(t("Rechts", "Right"),systemImage:"arrow.uturn.right") }
            Button { orbit.rotate(horizontal:0,vertical:0.2) } label: { Label(t("Von oben", "From above"),systemImage:"arrow.down.right") }
            Button { orbit.rotate(horizontal:0,vertical:-0.2) } label: { Label(t("Flacher", "Flatter"),systemImage:"arrow.right") }
            Spacer()
            Button(t("Einpassen", "Fit to view")) { orbit.fit() }.labelStyle(.titleOnly)
                .help(t("Den gesamten Ausschnitt einpassen; die Blickrichtung bleibt erhalten.", "Fit the whole section while keeping the viewing direction."))
            Button { orbit.magnify(-0.15) } label: { Label(t("Verkleinern", "Zoom out"),systemImage:"minus.magnifyingglass") }
                .disabled(!orbit.canZoomOut).help(t("Verkleinern", "Zoom out"))
            Button { orbit.magnify(0.15) } label: { Label(t("Vergrößern", "Zoom in"),systemImage:"plus.magnifyingglass") }
                .disabled(!orbit.canZoomIn).help(t("Vergrößern", "Zoom in"))
            Button { orbit = .ore } label: { Label(t("Ansicht zurücksetzen", "Reset view"),systemImage:"arrow.counterclockwise") }
                .help(t("Ansicht zurücksetzen", "Reset view"))
        }.labelStyle(.iconOnly).controlSize(.small)
    }
    private func regionControls(_ mesh:OreLayerMesh) -> some View {
        VStack(alignment:.leading,spacing:6) {
            Text(t("Begrenzter 64 × 64-Ausschnitt. In 2D einen Block fixieren oder den Ausschnitt verschieben.", "Bounded 64 × 64 section. Pin a block in 2D or move the section.")).font(.caption)
            HStack {
                Button("X −") { move(-32,0) }.disabled(mesh.bounds[0] == scan.bounds[0])
                Button("X +") { move(32,0) }.disabled(mesh.bounds[1] == scan.bounds[1])
                Button("N −Z") { move(0,-32) }.disabled(mesh.bounds[4] == scan.bounds[4])
                Button("S +Z") { move(0,32) }.disabled(mesh.bounds[5] == scan.bounds[5])
                Button(t("Mitte", "Center")) { center=CGPoint(x:Double(scan.bounds[0]+scan.bounds[1])/2,y:Double(scan.bounds[4]+scan.bounds[5])/2) }
            }.controlSize(.small)
        }
    }
    private func move(_ x:Int,_ z:Int) {
        guard let current else { return }
        let b=current.bounds
        center=CGPoint(x:min(scan.bounds[1],max(scan.bounds[0],(b[0]+b[1]+1)/2+x)),y:min(scan.bounds[5],max(scan.bounds[4],(b[4]+b[5]+1)/2+z)))
    }
    private func rebuild() async {
        mesh=nil; picked=nil; cluster=nil; clusterID=nil; clusterStatus=""; failure=""
        guard !spoilerFree, let spatial=scan.spatial else { return }
        let key=request, bounds=scan.bounds, height=y, depth=depth, x=cx, z=cz, only=onlySelected
        let selected=Set(OreMaterial.all.filter { materials.contains($0.id) }.flatMap(\.blocks))
        let worker=Task.detached(priority:.userInitiated) {
            try OreLayerMesh.build(spatial:spatial,bounds:bounds,y:height,depth:depth,centerX:x,centerZ:z,selected:selected,onlySelected:only) { try Task.checkCancellation() }
        }
        do {
            let built=try await withTaskCancellationHandler(operation:{ try await worker.value },onCancel:{ worker.cancel() })
            guard !Task.isCancelled else { return }
            mesh=built; renderedRequest=key
        } catch is CancellationError { }
        catch { if !Task.isCancelled { failure=error.localizedDescription } }
    }
}

struct OreLayerScene: NSViewRepresentable {
    let mesh: OreLayerMesh
    let materials: Set<String>
    @Binding var orbit: BuildOrbitCamera
    let select: (OreLayerMesh.Face,Int) -> Void
    var capture: OreSceneCapture? = nil
    var cluster: OreCluster? = nil
    var clusterID: UUID? = nil
    final class Coordinator {
        var meshID: UUID?
        var mesh: OreLayerMesh?
        var select: ((OreLayerMesh.Face,Int) -> Void)?
        var clusterID: UUID?
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context:Context) -> BuildOrbitSceneView {
        let view=BuildOrbitSceneView(); view.scene=SCNScene(); view.allowsCameraControl=false
        view.backgroundColor=NSColor(calibratedRed:0.07,green:0.10,blue:0.14,alpha:1); view.antialiasingMode = .multisampling4X
        let camera=SCNNode(); camera.name="camera"; camera.camera=SCNCamera(); camera.camera?.fieldOfView=60; camera.camera?.projectionDirection = .vertical
        camera.camera?.zNear=0.05; camera.camera?.zFar=10000; view.scene?.rootNode.addChildNode(camera); view.pointOfView=camera
        let ambient=SCNNode(); ambient.light=SCNLight(); ambient.light?.type = .ambient; ambient.light?.intensity=550; view.scene?.rootNode.addChildNode(ambient)
        let sun=SCNNode(); sun.light=SCNLight(); sun.light?.type = .omni; sun.light?.intensity=900; sun.position=SCNVector3(-40,100,-40); view.scene?.rootNode.addChildNode(sun)
        view.pick = { [weak view, weak coordinator=context.coordinator] point in
            guard let view, let coordinator, let mesh=coordinator.mesh else { return }
            for hit in view.hitTest(point,options:nil) {
                guard let name=hit.node.name, let id=Int(name), let faces=mesh.faces[id], hit.faceIndex/2 < faces.count else { continue }
                coordinator.select?(faces[hit.faceIndex/2],id); break
            }
        }
        return view
    }
    func updateNSView(_ view:BuildOrbitSceneView,context:Context) {
        capture?.view=view; capture?.meshID=mesh.id
        view.rotate = { x,y in orbit.rotate(horizontal:x,vertical:y) }; view.zoom = { orbit.magnify($0) }; view.orbit=orbit
        context.coordinator.select=select
        if context.coordinator.meshID != mesh.id {
            context.coordinator.clusterID=nil
            view.scene?.rootNode.childNode(withName:"cluster",recursively:false)?.removeFromParentNode()
            context.coordinator.meshID=mesh.id; context.coordinator.mesh=mesh
            view.scene?.rootNode.childNode(withName:"ore",recursively:false)?.removeFromParentNode()
            let group=SCNNode(); group.name="ore"
            for (id,faces) in mesh.faces {
                var vertices:[SCNVector3]=[], normals:[SCNVector3]=[], indices:[Int32]=[]
                vertices.reserveCapacity(faces.count*4); normals.reserveCapacity(faces.count*4); indices.reserveCapacity(faces.count*6)
                for face in faces {
                    let base=Int32(vertices.count), n=OreLayerMesh.normals[face.side]
                    for corner in OreLayerMesh.corners[face.side] {
                        vertices.append(SCNVector3(face.x-mesh.bounds[0]+corner[0],face.y-mesh.bounds[2]+corner[1],face.z-mesh.bounds[4]+corner[2]))
                        normals.append(SCNVector3(n[0],n[1],n[2]))
                    }
                    indices += [base,base+1,base+2,base,base+2,base+3]
                }
                let geometry=SCNGeometry(sources:[SCNGeometrySource(vertices:vertices),SCNGeometrySource(normals:normals)],elements:[SCNGeometryElement(indices:indices,primitiveType:.triangles)])
                let material=SCNMaterial(); material.diffuse.contents=color(id); material.lightingModel = .lambert; material.isDoubleSided=true
                geometry.materials=[material]
                let node=SCNNode(geometry:geometry); node.name=String(id); group.addChildNode(node)
            }
            let nx=mesh.bounds[1]-mesh.bounds[0]+1, ny=mesh.bounds[3]-mesh.bounds[2]+1, nz=mesh.bounds[5]-mesh.bounds[4]+1
            for (label,position) in [("N −Z",SCNVector3(0,ny+1,-3)),("+X",SCNVector3(nx+1,0,0)),("+Z",SCNVector3(0,0,nz+1))] {
                let text=SCNText(string:label,extrusionDepth:0.01); text.font=NSFont.monospacedSystemFont(ofSize:2,weight:.bold)
                let ink=SCNMaterial(); ink.diffuse.contents=NSColor.white; ink.lightingModel = .constant; ink.isDoubleSided=true; text.materials=[ink]
                let node=SCNNode(geometry:text); node.position=position; node.constraints=[SCNBillboardConstraint()]; group.addChildNode(node)
            }
            view.scene?.rootNode.addChildNode(group)
            view.target=SCNVector3(Double(nx)/2,Double(ny)/2,Double(nz)/2)
            view.radius=sqrt(Double(nx*nx+ny*ny+nz*nz))/2+5
            // Include a small margin for orientation labels, without a sphere's empty space.
            view.fitDimensions=(Double(nx)+4,Double(ny)+2,Double(nz)+4)
        }
        if context.coordinator.clusterID != clusterID {
            context.coordinator.clusterID=clusterID
            view.scene?.rootNode.childNode(withName:"cluster",recursively:false)?.removeFromParentNode()
            if let cluster {
                var vertices:[SCNVector3]=[], indices:[Int32]=[]
                for face in cluster.faces(in:mesh.bounds) {
                    let base=Int32(vertices.count)
                    for c in OreLayerMesh.corners[face.side] { vertices.append(SCNVector3(face.x-mesh.bounds[0]+c[0],face.y-mesh.bounds[2]+c[1],face.z-mesh.bounds[4]+c[2])) }
                    indices += [base,base+1,base+1,base+2,base+2,base+3,base+3,base]
                }
                let geometry=SCNGeometry(sources:[SCNGeometrySource(vertices:vertices)],elements:[SCNGeometryElement(indices:indices,primitiveType:.line)])
                let ink=SCNMaterial(); ink.diffuse.contents=NSColor.systemOrange; ink.lightingModel = .constant; ink.readsFromDepthBuffer=false; ink.writesToDepthBuffer=false
                geometry.materials=[ink]
                let node=SCNNode(geometry:geometry); node.name="cluster"; node.renderingOrder=10; view.scene?.rootNode.addChildNode(node)
            }
        }
        view.updateCamera()
    }
    private func color(_ id:Int) -> NSColor {
        if id == 65535 { return .systemPurple }
        if let material=OreMaterial.byBlock[id], materials.contains(material.id) { return NSColor(material.color) }
        if id == 26 { return NSColor(calibratedRed:0.12,green:0.35,blue:0.55,alpha:1) }
        if id == 27 { return NSColor(calibratedRed:0.85,green:0.3,blue:0.08,alpha:1) }
        if !knownBlocks.contains(String(id)) { return .systemPurple }
        return NSColor(white:0.28+Double(id%5)*0.025,alpha:1)
    }
    private var knownBlocks: Set<String> { Self.registry }
    private static let registry: Set<String> = {
        guard let url=Bundle.main.resourceURL?.appendingPathComponent("MapEngine/realmcraft_map/blocks.json"), let data=try? Data(contentsOf:url), let values=try? JSONDecoder().decode([String:String].self,from:data) else { return [] }
        return Set(values.keys)
    }()
}
