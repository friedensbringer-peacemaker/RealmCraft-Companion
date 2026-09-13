import AppKit
import SceneKit

/// Only relative camera parameters are stored, not world coordinates or measurement identifiers.
enum OreCameraPreset {
    static let key = "ore3d.camera.v1"
    static func save(_ camera: BuildOrbitCamera, defaults: UserDefaults = .standard) {
        defaults.set([camera.yaw,camera.elevation,camera.zoom],forKey:key)
    }
    static func load(defaults: UserDefaults = .standard) -> BuildOrbitCamera? {
        guard let values = defaults.array(forKey:key) as? [Double], values.count == 3,
              values.allSatisfy(\.isFinite), (-2 * Double.pi...2 * Double.pi).contains(values[0]),
              (0.15...1.4).contains(values[1]), (0.15...2.8).contains(values[2]) else { return nil }
        var camera = BuildOrbitCamera.ore
        camera.rotate(horizontal:values[0]-camera.yaw,vertical:values[1]-camera.elevation)
        camera.restoreZoom(values[2])
        return camera
    }
}

final class OreSceneCapture {
    weak var view: BuildOrbitSceneView?
    var meshID: UUID?
}

enum OreImageExport {
    struct Legend { let name: String; let color: NSColor }
    /// Bake provenance and a color legend into the image, not into easily lost sidecar metadata.
    @MainActor static func png(scene: NSImage, lines: [String], legend: [Legend]) throws -> Data {
        let width = max(1000, min(2000, scene.size.width))
        let imageHeight = width * scene.size.height / max(1,scene.size.width)
        let attributes: [NSAttributedString.Key:Any] = [.font:NSFont.systemFont(ofSize:16),.foregroundColor:NSColor.white]
        let text = NSAttributedString(string:lines.joined(separator:"\n"),attributes:attributes)
        let textHeight = ceil(text.boundingRect(with:NSSize(width:width-40,height:10000),options:[.usesLineFragmentOrigin,.usesFontLeading]).height)
        let footer = textHeight + CGFloat((legend.count+3)/4)*28 + 40
        let canvas = NSImage(size:NSSize(width:width,height:imageHeight+footer))
        canvas.lockFocus()
        NSColor(calibratedRed:0.07,green:0.10,blue:0.14,alpha:1).setFill()
        NSRect(origin:.zero,size:canvas.size).fill()
        scene.draw(in:NSRect(x:0,y:footer,width:width,height:imageHeight))
        text.draw(with:NSRect(x:20,y:footer-20-textHeight,width:width-40,height:textHeight),options:[.usesLineFragmentOrigin,.usesFontLeading])
        for (i,item) in legend.enumerated() {
            let x = 20 + CGFloat(i%4)*(width-40)/4, y = footer-20-textHeight-28-CGFloat(i/4)*28
            item.color.setFill(); NSRect(x:x,y:y+2,width:14,height:14).fill()
            NSAttributedString(string:item.name,attributes:attributes).draw(in:NSRect(x:x+21,y:y,width:(width-40)/4-25,height:24))
        }
        canvas.unlockFocus()
        guard let tiff=canvas.tiffRepresentation, let bitmap=NSBitmapImageRep(data:tiff),
              let data=bitmap.representation(using:.png,properties:[:]) else { throw OreError("PNG export failed / PNG-Export fehlgeschlagen") }
        return data
    }
}
