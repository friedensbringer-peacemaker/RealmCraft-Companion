import SwiftUI
import AppKit

struct WindowFramePersistence: NSViewRepresentable {
    let name: String
    var title: String? = nil
    func makeNSView(context: Context) -> FrameView { FrameView(name: name) }
    func updateNSView(_ view: FrameView, context: Context) {
        if let title { view.window?.title = title }
    }
    final class FrameView: NSView {
        let frameName: String
        init(name: String) { frameName = name; super.init(frame: .zero) }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.setFrameAutosaveName(frameName)
            // NSWindow constrains a restored frame to the current screen configuration.
            _ = window.setFrameUsingName(frameName)
        }
    }
}
