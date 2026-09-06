import AppKit

/// Door inventory artwork represents the whole two-cell object. Split it once per
/// half for both grid and SceneKit, retaining independent picking and cutaways.
enum BuildGuideTexture {
    static func surfaceID(for block: BuildBlock) -> Int? {
        switch block.itemID {
        case 152, 466, 199, 259: return 13 // Oak parts use plank surfaces, not an inventory object on every face.
        case 261: return 236
        default: return block.itemID
        }
    }
    static func image(_ source: NSImage, for block: BuildBlock) -> NSImage {
        guard block.itemID == 168 else { return source }
        let half = source.size.height / 2
        guard source.size.width > 0, half > 0 else { return source }
        let rect = NSRect(x: 0, y: block.symbol.contains("↑") ? half : 0,
                          width: source.size.width, height: half)
        return NSImage(size: rect.size, flipped: false) { target in
            NSGraphicsContext.current?.imageInterpolation = .none
            source.draw(in: target, from: rect, operation: .copy, fraction: 1,
                        respectFlipped: false, hints: nil)
            return true
        }
    }
}
