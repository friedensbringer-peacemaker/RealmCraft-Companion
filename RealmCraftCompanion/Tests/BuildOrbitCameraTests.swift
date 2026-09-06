import Foundation
@main struct BuildOrbitCameraTests {
    static func main() {
        var camera = BuildOrbitCamera()
        for _ in 0..<1000 { camera.rotate(horizontal: 100, vertical: 100); camera.magnify(100) }
        precondition(camera.zoom == 1 && camera.elevation == 1.4 && abs(camera.yaw) < .pi * 2)
        for _ in 0..<1000 { camera.rotate(horizontal: -100, vertical: -100); camera.magnify(-100) }
        precondition(camera.zoom == 2.8 && camera.elevation == 0.15)
        // The angular silhouette of the bounding sphere must fit BOTH viewport axes.
        for aspect in [0.2,0.5,1,1.5,2.5,4] {
            for radius in [1.0,5,20,100] {
                var close = BuildOrbitCamera(); close.magnify(100)
                let angle = asin(radius / close.distance(radius: radius, aspect: aspect))
                precondition(angle < .pi/6 && angle < atan(tan(.pi/6)*aspect))
            }
        }
        let original = camera
        camera.rotate(horizontal: .infinity, vertical: 0); camera.magnify(.nan)
        precondition(camera == original)
        print("PASS bounded rotation/zoom, invalid input and full-model framing at six viewport ratios")
    }
}
