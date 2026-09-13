import Foundation

/// Guide previews retain full-build framing; ore previews opt into close inspection.
struct BuildOrbitCamera: Equatable {
    private(set) var yaw = -0.68
    private(set) var elevation = 0.55
    private(set) var zoom = 1.15
    private var minimumZoom = 1.0
    static var ore: BuildOrbitCamera {
        var camera = BuildOrbitCamera()
        camera.minimumZoom = 0.15
        camera.zoom = 1
        return camera
    }
    var canZoomIn: Bool { zoom > minimumZoom }
    var canZoomOut: Bool { zoom < 2.8 }
    mutating func fit() { zoom = 1 }
    mutating func restoreZoom(_ value: Double) {
        guard value.isFinite else { return }
        zoom = min(2.8, max(minimumZoom, value))
    }
    mutating func rotate(horizontal: Double, vertical: Double) {
        guard horizontal.isFinite, vertical.isFinite else { return }
        yaw = (yaw + horizontal).truncatingRemainder(dividingBy: .pi * 2)
        elevation = min(1.4, max(0.15, elevation + vertical))
    }
    mutating func magnify(_ amount: Double) {
        guard amount.isFinite else { return }
        restoreZoom(zoom * exp(min(1, max(-1, -amount))))
    }
    /// Fit all eight box corners to both viewport axes before applying relative zoom.
    /// Unlike a bounding sphere this uses the shallow ore slice's actual silhouette.
    func distance(width: Double, height: Double, depth: Double, aspect: Double) -> Double {
        let tanV = tan(Double.pi / 6), tanH = tanV * max(0.05, aspect)
        let sy = sin(yaw), cy = cos(yaw), se = sin(elevation), ce = cos(elevation)
        var fitted = 1.0
        for x in [-width / 2, width / 2] {
            for y in [-height / 2, height / 2] {
                for z in [-depth / 2, depth / 2] {
                    let toward = x * ce * sy + y * se - z * ce * cy
                    let horizontal = x * cy + z * sy
                    let vertical = -x * se * sy + y * ce + z * se * cy
                    fitted = max(fitted, toward + abs(horizontal) / tanH,
                                 toward + abs(vertical) / tanV)
                }
            }
        }
        return fitted * 1.1 * zoom
    }
    func distance(radius: Double, aspect: Double) -> Double {
        let verticalHalfAngle = Double.pi / 6 // Camera uses a 60-degree vertical field of view.
        let horizontalHalfAngle = atan(tan(verticalHalfAngle) * max(0.05, aspect))
        return max(1, radius) / sin(min(verticalHalfAngle, horizontalHalfAngle)) * 1.1 * zoom
    }
}
