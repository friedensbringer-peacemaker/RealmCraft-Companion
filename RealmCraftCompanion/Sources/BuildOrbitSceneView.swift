import SceneKit
import AppKit

/// Shared fixed-target interaction for guide and ore previews; page scrolling never rotates the model.
final class BuildOrbitSceneView: SCNView {
    var orbit = BuildOrbitCamera()
    var target = SCNVector3Zero
    var radius = 1.0
    var fitDimensions: (width: Double, height: Double, depth: Double)?
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
        let aspect = Double(bounds.width / bounds.height)
        let distance = fitDimensions.map {
            orbit.distance(width: $0.width, height: $0.height, depth: $0.depth, aspect: aspect)
        } ?? orbit.distance(radius: radius, aspect: aspect)
        let horizontal = distance * cos(orbit.elevation)
        camera.position = SCNVector3(Double(target.x)+horizontal*sin(orbit.yaw),
                                     Double(target.y)+distance*sin(orbit.elevation),
                                     Double(target.z)-horizontal*cos(orbit.yaw))
        camera.look(at: target); pointOfView = camera
    }
}
