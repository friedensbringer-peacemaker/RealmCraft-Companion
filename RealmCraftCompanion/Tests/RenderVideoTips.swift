import SwiftUI
import AppKit

@main struct RenderVideoTips {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let tips = try VideoTip.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
        let directory = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for english in [false, true] {
            for tip in tips {
                let width: CGFloat = english ? 900 : 650
                let content = VideoTipDetail(tip: tip, english: english).frame(width: width, height: 1150).companionAppearance()
                let host = NSHostingView(rootView: content)
                host.frame = NSRect(x: 0, y: 0, width: width, height: 1150)
                let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
                window.appearance = NSAppearance(named: .darkAqua); window.contentView = host
                host.layoutSubtreeIfNeeded()
                RunLoop.current.run(until: Date().addingTimeInterval(0.2))
                let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("\(tip.id)-\(english ? "en" : "de").png"))
            }
        }
        print("Rendered all three production video-guide views in DE/EN")
    }
}
