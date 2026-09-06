import AppKit
import SceneKit

private final class PageScrollView: NSScrollView {
    var scrollEvents = 0
    override func scrollWheel(with event: NSEvent) { scrollEvents += 1 }
}
@main struct BuildGuideScrollTests {
    static func main() {
        let page = PageScrollView(frame: NSRect(x: 0, y: 0, width: 600, height: 600))
        let document = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 1200))
        page.documentView = document
        let viewer = BuildOrbitSceneView(frame: NSRect(x: 0, y: 0, width: 500, height: 420))
        document.addSubview(viewer)
        var zoomCalls = 0
        viewer.zoom = { _ in zoomCalls += 1 }
        let before = viewer.orbit
        for units in [CGScrollEventUnit.pixel, .line] {
            let event = NSEvent(cgEvent: CGEvent(scrollWheelEvent2Source: nil, units: units, wheelCount: 1, wheel1: -5, wheel2: 0, wheel3: 0)!)!
            viewer.scrollWheel(with: event)
        }
        precondition(page.scrollEvents == 2)
        precondition(zoomCalls == 0 && before == viewer.orbit)
        print("PASS pixel and wheel scrolling reach page without zoom or camera changes")
    }
}
