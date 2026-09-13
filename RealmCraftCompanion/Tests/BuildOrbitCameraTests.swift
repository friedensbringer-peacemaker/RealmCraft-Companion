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
        var ore = BuildOrbitCamera.ore
        for _ in 0..<12 {
            let before = ore.zoom
            ore.magnify(0.15)
            precondition(ore.zoom < before, "Every zoom-in click must change the ore camera")
        }
        ore.magnify(100)
        precondition(ore.zoom == 0.15 && !ore.canZoomIn)
        ore.restoreZoom(2.8)
        precondition(!ore.canZoomOut)
        ore.fit()
        precondition(ore.zoom == 1)
        for aspect in [0.5,1,1.5,2.5,4] {
            for elevation in [0.15,0.55,1.4] {
                for yaw in [-2.0,-0.68,0,1.5] {
                    var fit = BuildOrbitCamera.ore
                    fit.rotate(horizontal:yaw-fit.yaw,vertical:elevation-fit.elevation)
                    let distance = fit.distance(width:68,height:10,depth:68,aspect:aspect)
                    for x in [-34.0,34] { for y in [-5.0,5] { for z in [-34.0,34] {
                        let toward=x*cos(elevation)*sin(yaw)+y*sin(elevation)-z*cos(elevation)*cos(yaw)
                        let horizontal=x*cos(yaw)+z*sin(yaw)
                        let vertical = -x*sin(elevation)*sin(yaw)+y*cos(elevation)+z*sin(elevation)*cos(yaw)
                        precondition(abs(horizontal)/(distance-toward) < tan(.pi/6)*aspect)
                        precondition(abs(vertical)/(distance-toward) < tan(.pi/6))
                    }}}
                }
            }
        }
        print("PASS bounded rotation/zoom, invalid input and full-model framing at six viewport ratios")
    }
}
