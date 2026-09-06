import Foundation

/// A fixed target and bounded distance keep the entire build inside the viewport.
struct BuildOrbitCamera: Equatable {
    private(set) var yaw = -0.68
    private(set) var elevation = 0.55
    private(set) var zoom = 1.15
    mutating func rotate(horizontal: Double, vertical: Double) {
        guard horizontal.isFinite, vertical.isFinite else { return }
        yaw = (yaw + horizontal).truncatingRemainder(dividingBy: .pi * 2)
        elevation = min(1.4, max(0.15, elevation + vertical))
    }
    mutating func magnify(_ amount: Double) {
        guard amount.isFinite else { return }
        zoom = min(2.8, max(1, zoom * exp(min(1, max(-1, -amount)))))
    }
    func distance(radius: Double, aspect: Double) -> Double {
        let verticalHalfAngle = Double.pi / 6 // Camera uses a 60-degree vertical field of view.
        let horizontalHalfAngle = atan(tan(verticalHalfAngle) * max(0.05, aspect))
        return max(1, radius) / sin(min(verticalHalfAngle, horizontalHalfAngle)) * 1.1 * zoom
    }
}
