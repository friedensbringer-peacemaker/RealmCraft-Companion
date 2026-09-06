import AppKit
let destination = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        let context = NSGraphicsContext.current!.cgContext
        context.scaleBy(x: CGFloat(pixels)/1024, y: CGFloat(pixels)/1024)
        let outer = NSBezierPath(roundedRect: NSRect(x: 45, y: 45, width: 934, height: 934), xRadius: 215, yRadius: 215)
        NSGradient(starting: NSColor(calibratedRed: 0.07, green: 0.18, blue: 0.24, alpha: 1), ending: NSColor(calibratedRed: 0.03, green: 0.07, blue: 0.13, alpha: 1))!.draw(in: outer, angle: -60)
        func face(_ points: [NSPoint], _ color: NSColor) {
            let p = NSBezierPath(); p.move(to: points[0]); points.dropFirst().forEach { p.line(to: $0) }; p.close(); color.setFill(); p.fill()
        }
        face([NSPoint(x:512,y:820),NSPoint(x:800,y:665),NSPoint(x:512,y:510),NSPoint(x:224,y:665)], NSColor(calibratedRed:0.27,green:0.88,blue:0.70,alpha:1))
        face([NSPoint(x:224,y:665),NSPoint(x:512,y:510),NSPoint(x:512,y:190),NSPoint(x:224,y:345)], NSColor(calibratedRed:0.08,green:0.55,blue:0.60,alpha:1))
        face([NSPoint(x:512,y:510),NSPoint(x:800,y:665),NSPoint(x:800,y:345),NSPoint(x:512,y:190)], NSColor(calibratedRed:0.08,green:0.36,blue:0.55,alpha:1))
        let arrow=NSBezierPath(); arrow.move(to:NSPoint(x:640,y:545)); arrow.line(to:NSPoint(x:640,y:370)); arrow.move(to:NSPoint(x:580,y:425)); arrow.line(to:NSPoint(x:640,y:365)); arrow.line(to:NSPoint(x:700,y:425)); arrow.lineWidth=28; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round; NSColor.white.setStroke(); arrow.stroke()
        image.unlockFocus()
        let data = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try data.write(to: destination.appendingPathComponent(name))
    }
}
