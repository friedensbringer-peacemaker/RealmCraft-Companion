import AppKit
import SceneKit

@main struct PlayerSkinCameraTests {
    static func main() {
        _ = NSApplication.shared
        let view = SkinPreviewView(frame: NSRect(x: 0, y: 0, width: 235, height: 300), options: nil)
        view.scene = SCNScene()
        let camera = SCNNode(); camera.name = "camera"; camera.camera = SCNCamera()
        view.scene!.rootNode.addChildNode(camera)
        view.modelRadius = 1.3
        view.resetView()
        let initial = camera.position
        for _ in 0..<200 { view.orbit(horizontal: 15, vertical: 15); view.changeZoom(-100) }
        assert(view.pitch <= 0.65 && view.zoom == 1)
        let position = camera.position
        let distance = sqrt(position.x * position.x + (position.y - 1) * (position.y - 1) + position.z * position.z)
        let angle = atan(tan(CGFloat.pi / 8) * (235.0 / 300.0))
        assert(distance * sin(angle) > view.modelRadius, "Entire model must fit the viewport")
        for _ in 0..<200 { view.orbit(horizontal: -15, vertical: -15); view.changeZoom(100) }
        assert(view.pitch >= -0.65 && view.zoom == 2.5)
        view.orbit(horizontal: .infinity, vertical: .nan); view.changeZoom(.nan)
        assert(view.yaw.isFinite && view.pitch.isFinite && view.zoom.isFinite)
        view.resetView()
        assert(view.yaw == 0 && view.pitch == 0 && view.zoom == 1)
        assert(abs(camera.position.z - initial.z) < 0.0001 && camera.position.x == initial.x && camera.position.y == initial.y)
        assert(abs(camera.eulerAngles.z) < 0.0001, "Reset must remove camera roll")
        assert(view.pointOfView === camera && !view.allowsCameraControl)
        print("Camera bounds, fixed orbit, invalid input and reset checks passed")
    }
}
