import SwiftUI
import SceneKit

struct PlayerSkinScene: NSViewRepresentable {
    let profile: PlayerSkinProfile
    let armor: [PlayerItem]
    var hands = false
    var resetToken = 0

    final class Coordinator {
        var key = ""
        var geometry: [String: SCNGeometry] = [:]
        var previousHands: Bool?
        var previousReset: Int?
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> SkinPreviewView {
        let view = SkinPreviewView(frame: .zero, options: nil)
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.scene = SCNScene()
        let camera = SCNNode(); camera.name = "camera"; camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 45; camera.camera?.projectionDirection = .vertical
        camera.camera?.zNear = 0.01; camera.camera?.zFar = 100
        view.scene?.rootNode.addChildNode(camera); view.pointOfView = camera
        let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light?.type = .ambient
        ambient.light?.intensity = 650; view.scene?.rootNode.addChildNode(ambient)
        let light = SCNNode(); light.light = SCNLight(); light.light?.type = .omni
        light.light?.intensity = 850; light.position = SCNVector3(-3, 5, 4)
        view.scene?.rootNode.addChildNode(light)
        view.defaultCameraController.target = SCNVector3(0, 1, 0)
        return view
    }
    func updateNSView(_ view: SkinPreviewView, context: Context) {
        if context.coordinator.previousReset != resetToken || context.coordinator.previousHands != hands {
            view.resetView()
            context.coordinator.previousReset = resetToken
        }
        let key = profile.encoded + "\(hands)" + armor.map { "\($0.slot):\($0.itemID)" }.joined(separator: ",")
        guard key != context.coordinator.key, let root = SkinAssets.root else { return }
        context.coordinator.key = key
        view.scene?.rootNode.childNode(withName: "model", recursively: false)?.removeFromParentNode()
        guard let data = try? Data(contentsOf: root.appendingPathComponent("models.json")),
              let manifest = try? JSONDecoder().decode([String: [Part]].self, from: data) else { return }
        let group = SCNNode(); group.name = "model"
        let skin = composite(profile)
        let parts = manifest[hands ? "Hand\(profile.hand)" : profile.gender] ?? []
        for part in parts {
            let armorPart = part.name.lowercased().contains("armor")
            let slot = part.name.contains("Helmet") ? 4 : part.name.contains("Boots") ? 1 : part.name.contains("Pants") ? 2 : 3
            let equipped = armor.first { $0.slot == slot }
            if armorPart && equipped == nil { continue }
            let source: SCNGeometry?
            if let cached = context.coordinator.geometry[part.mesh] { source = cached }
            else {
                source = loadOBJ(root.appendingPathComponent(part.mesh + ".obj"))
                context.coordinator.geometry[part.mesh] = source
            }
            guard let geometry = source?.copy() as? SCNGeometry else { continue }
            let material = SCNMaterial(); material.lightingModel = .lambert
            material.diffuse.magnificationFilter = .nearest
            material.diffuse.minificationFilter = .linear
            material.isDoubleSided = true
            if hands {
                material.diffuse.contents = NSImage(contentsOf: root.appendingPathComponent("Hands/Type_\(profile.hand)/\(profile.parts.body).png"))
            } else if armorPart {
                material.diffuse.contents = part.texture.flatMap { NSImage(contentsOf: root.appendingPathComponent($0)) }
                material.multiply.contents = armorColor(equipped!.itemID)
            } else { material.diffuse.contents = skin }
            geometry.materials = [material]; group.addChildNode(SCNNode(geometry: geometry))
        }
        let (low, high) = group.boundingBox
        let height = hands ? max(high.x - low.x, high.y - low.y, high.z - low.z) : high.y - low.y
        if height > 0 {
            let scale: CGFloat = 2 / height
            group.scale = SCNVector3(scale, scale, scale)
            group.position = SCNVector3(-(low.x + high.x) * 0.5 * scale, (hands ? 1 - (low.y + high.y) * 0.5 * scale : -low.y * scale), -(low.z + high.z) * 0.5 * scale)
        }
        view.scene?.rootNode.addChildNode(group)
        // A bounding sphere keeps the whole model visible at every allowed rotation.
        if height > 0 {
            let halfX = (high.x - low.x) / height
            let halfY = (high.y - low.y) / height
            let halfZ = (high.z - low.z) / height
            view.modelRadius = sqrt(halfX * halfX + halfY * halfY + halfZ * halfZ)
        }
        view.applyCamera()
        context.coordinator.previousHands = hands
    }
    private struct Part: Decodable {
        let mesh: String
        let name: String
        let texture: String?
    }
    func composite(_ profile: PlayerSkinProfile) -> NSImage? {
        guard let baseURL = SkinAssets.texture(profile, "body"), let base = NSImage(contentsOf: baseURL) else { return nil }
        let image = NSImage(size: base.size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        let rect = NSRect(origin: .zero, size: base.size)
        base.draw(in: rect)
        for part in ["shirt", "pants"] {
            if let url = SkinAssets.texture(profile, part), let layer = NSImage(contentsOf: url) {
                // Original material UV scale and offset; clothing occupies only its atlas region.
                let female = profile.gender == "Girl"
                let sx: CGFloat = part == "shirt" ? (female ? 1.358 : 1.416) : (female ? 1.358 : 1.365)
                let sy: CGFloat = part == "shirt" ? 1.868 : (female ? 2.151 : 2.133)
                // Shirt torso UV islands occupy the top of the body atlas. Anchor the
                // complete shirt there; the prefab's static offset leaves those islands bare.
                let y: CGFloat = part == "shirt" ? base.size.height - base.size.height / sy : 0
                let region = NSRect(x: 0, y: y, width: base.size.width / sx, height: base.size.height / sy)
                layer.draw(in: region, from: .zero, operation: .sourceOver, fraction: 1)
            }
        }
        image.unlockFocus(); return image
    }
    private func armorColor(_ id: Int) -> NSColor {
        switch id {
        case 3047...3050: return NSColor(red: 0.22, green: 0.86, blue: 0.95, alpha: 1)
        case 3043...3046: return NSColor(red: 1, green: 0.80, blue: 0.22, alpha: 1)
        case 3031...3034: return NSColor(red: 0.64, green: 0.38, blue: 0.20, alpha: 1)
        case 3051...3054: return NSColor(white: 0.32, alpha: 1)
        case 3055: return NSColor(red: 0.25, green: 0.58, blue: 0.30, alpha: 1)
        default: return NSColor(white: 0.85, alpha: 1)
        }
    }
    private func loadOBJ(_ url: URL) -> SCNGeometry? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        var positions: [SCNVector3] = [], normals: [SCNVector3] = [], uvs: [CGPoint] = []
        var vertices: [SCNVector3] = [], vertexNormals: [SCNVector3] = [], vertexUVs: [CGPoint] = []
        for line in text.split(separator: "\n") {
            let p = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard let kind = p.first else { continue }
            if kind == "v" || kind == "vn", p.count >= 4,
               let x = Float(p[1]), let y = Float(p[2]), let z = Float(p[3]) {
                if kind == "v" { positions.append(SCNVector3(x, y, z)) } else { normals.append(SCNVector3(x, y, z)) }
            } else if kind == "vt", p.count >= 3, let u = Double(p[1]), let v = Double(p[2]) {
                uvs.append(CGPoint(x: u, y: 1 - v))
            } else if kind == "f", p.count >= 4 {
                for k in 2..<(p.count - 1) {
                    for token in [p[1], p[k], p[k + 1]] {
                        let indices = token.split(separator: "/", omittingEmptySubsequences: false)
                        guard indices.count >= 3, let a = Int(indices[0]), let b = Int(indices[1]), let c = Int(indices[2]),
                              positions.indices.contains(a - 1), uvs.indices.contains(b - 1), normals.indices.contains(c - 1) else { return nil }
                        vertices.append(positions[a - 1]); vertexUVs.append(uvs[b - 1]); vertexNormals.append(normals[c - 1])
                    }
                }
            }
        }
        guard !vertices.isEmpty else { return nil }
        let indices = Array(0..<Int32(vertices.count))
        return SCNGeometry(sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: vertexNormals), SCNGeometrySource(textureCoordinates: vertexUVs)], elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
    }
}


/// Fixed-target orbit controls. SceneKit's free pan/dolly controls stay disabled.
final class SkinPreviewView: SCNView {
    private(set) var yaw: CGFloat = 0
    private(set) var pitch: CGFloat = 0
    private(set) var zoom: CGFloat = 1
    var modelRadius: CGFloat = 1.2
    private var lastDragPoint: NSPoint?

    func resetView() {
        yaw = 0; pitch = 0; zoom = 1; lastDragPoint = nil
        applyCamera()
    }
    func orbit(horizontal: CGFloat, vertical: CGFloat) {
        guard horizontal.isFinite, vertical.isFinite else { return }
        yaw = (yaw + horizontal).truncatingRemainder(dividingBy: 2 * .pi)
        pitch = min(0.65, max(-0.65, pitch + vertical))
        applyCamera()
    }
    func changeZoom(_ amount: CGFloat) {
        guard amount.isFinite else { return }
        zoom = min(2.5, max(1, zoom * exp(min(2, max(-2, amount)))))
        applyCamera()
    }
    func applyCamera() {
        guard let camera = scene?.rootNode.childNode(withName: "camera", recursively: false) else { return }
        let aspect = max(0.1, bounds.width / max(1, bounds.height))
        let halfAngle = atan(tan(CGFloat.pi / 8) * min(1, aspect))
        let distance = max(0.1, modelRadius) / sin(halfAngle) * 1.08 * zoom
        SCNTransaction.begin(); SCNTransaction.disableActions = true
        camera.position = SCNVector3(sin(yaw) * cos(pitch) * distance,
                                    1 + sin(pitch) * distance,
                                    cos(yaw) * cos(pitch) * distance)
        camera.look(at: SCNVector3(0, 1, 0), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        pointOfView = camera
        SCNTransaction.commit()
    }
    override func layout() { super.layout(); applyCamera() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { lastDragPoint = event.locationInWindow }
    override func mouseUp(with event: NSEvent) { lastDragPoint = nil }
    override func mouseDragged(with event: NSEvent) {
        let point = event.locationInWindow
        if let previous = lastDragPoint {
            orbit(horizontal: -(point.x - previous.x) * 0.012, vertical: -(point.y - previous.y) * 0.012)
        }
        lastDragPoint = point
    }
    override func scrollWheel(with event: NSEvent) { changeZoom(event.scrollingDeltaY * 0.01) }
    override func magnify(with event: NSEvent) { changeZoom(-event.magnification) }
    override func rotate(with event: NSEvent) { orbit(horizontal: CGFloat(event.rotation) * .pi / 180, vertical: 0) }
    override func rightMouseDragged(with event: NSEvent) {}
    override func otherMouseDragged(with event: NSEvent) {}
    override func swipe(with event: NSEvent) {}
}
