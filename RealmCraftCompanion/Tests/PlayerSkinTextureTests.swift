import AppKit
import SceneKit

@main struct PlayerSkinTextureTests {
    static func main() {
        _ = NSApplication.shared
        for gender in ["Boy", "Girl"] {
            var profile = PlayerSkinProfile(); profile.gender = gender
            let preview = PlayerSkinScene(profile: profile, armor: [])
            guard let image = preview.composite(profile),
                  let output = image.tiffRepresentation.flatMap({ NSBitmapImageRep(data: $0) }),
                  let shirtURL = SkinAssets.texture(profile, "shirt"),
                  let shirt = NSBitmapImageRep(data: try! Data(contentsOf: shirtURL)),
                  let bodyURL = SkinAssets.texture(profile, "body"),
                  let body = NSBitmapImageRep(data: try! Data(contentsOf: bodyURL)) else { fatalError("Missing skin assets") }
            func pixel(_ bitmap: NSBitmapImageRep, _ x: CGFloat, _ y: CGFloat) -> NSColor {
                bitmap.colorAt(x: Int(x * CGFloat(bitmap.pixelsWide)), y: Int(y * CGFloat(bitmap.pixelsHigh)))!.usingColorSpace(.deviceRGB)!
            }
            func distance(_ a: NSColor, _ b: NSColor) -> CGFloat {
                abs(a.redComponent - b.redComponent) + abs(a.greenComponent - b.greenComponent) + abs(a.blueComponent - b.blueComponent)
            }
            // Front torso UV island: originally this rendered bare skin for both models.
            let x: CGFloat = 0.40, y: CGFloat = 0.08
            let expected = pixel(shirt, x * (gender == "Girl" ? 1.358 : 1.416), y * 1.868)
            let actual = pixel(output, x, y)
            assert(expected.alphaComponent > 0.95)
            // AppKit color management can shift RGB values; the bare-skin check below
            // is the regression guard, while this tolerance checks the garment color.
            assert(distance(actual, expected) < 0.40, "Shirt missing from \(gender) torso")
            assert(distance(actual, pixel(body, x, y)) > 0.25, "Torso still shows body texture")
            // Face remains outside clothing's atlas region.
            assert(distance(pixel(output, 0.85, 0.58), pixel(body, 0.85, 0.58)) < 0.08)
        }
        print("Player skin texture regressions passed for both character models")
    }
}
