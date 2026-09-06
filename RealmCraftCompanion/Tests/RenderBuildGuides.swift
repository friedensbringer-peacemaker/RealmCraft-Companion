import SwiftUI
import AppKit

// Render the production SwiftUI views for layout review without opening a live savegame session.
@main struct RenderBuildGuides {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let catalog = try JSONDecoder().decode(BuildCatalog.self, from: data)
        try catalog.validate()
        let directory = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for english in [false, true] {
            let renderWidth: CGFloat = english ? 900 : 584
            for guide in catalog.guides {
                let content = BuildGuideDetail(guide: guide, blocks: catalog.blocks, english: english)
                    .frame(width: renderWidth, height: 1050).companionAppearance()
                let host = NSHostingView(rootView: content)
                host.frame = NSRect(x: 0, y: 0, width: renderWidth, height: 1050)
                let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
                window.appearance = NSAppearance(named: .darkAqua)
                window.contentView = host
                host.layoutSubtreeIfNeeded()
                RunLoop.current.run(until: Date().addingTimeInterval(0.15))
                guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("Render failed") }
                host.cacheDisplay(in: host.bounds, to: bitmap)
                let png = bitmap.representation(using: .png, properties: [:])!
                try png.write(to: directory.appendingPathComponent("\(guide.id)-\(english ? "en" : "de").png"))
            }
        }
        for guide in catalog.guides {
            for plane in guide.planes {
                let grid = BuildPaperGrid(plane: plane, blocks: catalog.blocks, english: false, cellSize: 56) { _, _ in }
                let renderer = ImageRenderer(content: grid)
                renderer.scale = 1
                guard let image = renderer.cgImage else { fatalError("Grid render failed") }
                try NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
                    .write(to: directory.appendingPathComponent("grid-\(guide.id)-\(plane.id).png"))
            }
        }
        print("Rendered all production guide details in DE/EN and every block plane")
    }
}
