import SwiftUI
import AppKit

struct WindowFramePersistence: NSViewRepresentable {
    let name: String
    var title: String? = nil
    var canClose: (() -> Bool)? = nil
    func makeNSView(context: Context) -> FrameView { FrameView(name: name, canClose: canClose) }
    func updateNSView(_ view: FrameView, context: Context) {
        if let title { view.window?.title = title }
        view.closeGuard.canClose = canClose
    }
    final class FrameView: NSView {
        let frameName: String
        let closeGuard = CloseGuard()
        init(name: String, canClose: (() -> Bool)?) { frameName = name; closeGuard.canClose = canClose; super.init(frame: .zero) }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            if closeGuard.canClose != nil, window.delegate !== closeGuard {
                closeGuard.next = window.delegate; window.delegate = closeGuard
            }
            window.setFrameAutosaveName(frameName)
            // NSWindow constrains a restored frame to the current screen configuration.
            _ = window.setFrameUsingName(frameName)
        }
    }
    final class CloseGuard: NSObject, NSWindowDelegate {
        weak var next: NSWindowDelegate?
        var canClose: (() -> Bool)?
        func windowShouldClose(_ sender: NSWindow) -> Bool {
            guard canClose?() != false else { return false }
            return next?.windowShouldClose?(sender) ?? true
        }
        override func responds(to selector: Selector!) -> Bool { super.responds(to: selector) || next?.responds(to: selector) == true }
        override func forwardingTarget(for selector: Selector!) -> Any? { next?.responds(to: selector) == true ? next : super.forwardingTarget(for: selector) }
    }
}
