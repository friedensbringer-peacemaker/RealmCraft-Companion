import AppKit

@main struct BuildGuideTextureTests {
    static func main() throws {
        let catalog = try JSONDecoder().decode(BuildCatalog.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("BuildGuides.json")))
        let source = NSImage(size: NSSize(width: 16, height: 32), flipped: false) { _ in
            NSColor.red.setFill(); NSRect(x: 0, y: 0, width: 16, height: 16).fill()
            NSColor.blue.setFill(); NSRect(x: 0, y: 16, width: 16, height: 16).fill()
            return true
        }
        for key in ["entry_door", "build_door", "entry_upper", "build_upper"] {
            let block = catalog.blocks[key]!
            let half = BuildGuideTexture.image(source, for: block)
            precondition(half.size == NSSize(width: 16, height: 16))
            let pixels = NSBitmapImageRep(data: half.tiffRepresentation!)!
            let color = pixels.colorAt(x: 8, y: 8)!.usingColorSpace(.deviceRGB)!
            if key.hasSuffix("upper") { precondition(color.blueComponent > 0.95 && color.redComponent < 0.05) }
            else { precondition(color.redComponent > 0.95 && color.blueComponent < 0.05) }
        }
        for key in ["ar_slab", "ar_oak_px", "build_fence", "build_gate"] {
            precondition(BuildGuideTexture.surfaceID(for: catalog.blocks[key]!) == 13)
        }
        precondition(BuildGuideTexture.surfaceID(for: catalog.blocks["ex_stair_nz"]!) == 236)
        precondition(BuildGuideTexture.image(source, for: catalog.blocks["#"]!) === source)
        print("PASS all door halves sample correct artwork; ordinary blocks unchanged")
    }
}
