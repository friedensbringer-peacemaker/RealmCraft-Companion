import AppKit
import SwiftUI

struct Frames: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) { value.merge(nextValue(), uniquingKeysWith: { _, new in new }) }
}
extension View {
    func measure(_ key: String) -> some View {
        background(GeometryReader { proxy in Color.clear.preference(key: Frames.self, value: [key: proxy.frame(in: .named("page"))]) })
    }
}
final class Measurement { var frames: [String: CGRect] = [:] }
struct Probe: View {
    let title: String
    let label: String
    let search: Bool
    let overflow: Bool
    let disabled: Bool
    let block: Bool
    let result: Measurement
    @ViewBuilder private var actions: some View {
        if search { TextField("Search skills", text: .constant("")).frame(width: CompanionLayout.searchWidth).measure("search") }
        Button(label) {}.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(disabled).measure("primary")
    }
    @ViewBuilder private var header: some View {
        if overflow {
            CompanionPageHeader(title: title) { actions } menu: {
                Button("Contextual action") {}.disabled(disabled)
            }
        } else {
            CompanionPageHeader(title: title) { actions }
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            header.measure("header")
            Spacer(minLength: 0)
        }.coordinateSpace(name: "page").environment(\.companionTheme, CompanionTheme(block: block))
            .onPreferenceChange(Frames.self) { result.frames = $0 }
    }
}
@main struct CompanionLayoutTests {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        var count = 0
        for width in [868.0, 1068, 1228, 1588] {
            for block in [true, false] {
                for search in [true, false] {
                for disabled in [true, false] {
                    for overflow in [true, false] {
                        for label in ["Read player", "Refresh", "Spieler auslesen", "Aktualisieren", "Vom Gerät sichern", "Generate context", "Statistik auslesen"] {
                            let result = Measurement()
                            let host = NSHostingView(rootView: Probe(title: "Statistiken · Beta", label: label, search: search, overflow: overflow, disabled: disabled, block: block, result: result))
                            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 700), styleMask: [.borderless], backing: .buffered, defer: false)
                            window.contentView = host
                            host.frame = NSRect(x: 0, y: 0, width: width, height: 700)
                            host.layoutSubtreeIfNeeded()
                            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.015))
                            guard let primary = result.frames["primary"], let header = result.frames["header"] else { fatalError("Missing geometry") }
                            precondition(abs(primary.width - 180) < 0.1, "Button width \(primary)")
                            precondition(abs(primary.height - 32) < 0.1, "Button height \(primary)")
                            precondition(abs(header.height - 64) < 0.1, "Header height")
                            precondition(abs(primary.maxX - (width - 28 - 32 - 12)) < 0.1, "Action edge \(primary) at \(width)")
                            count += 1
                            window.contentView = nil
                        }
                    }
                }
            }
        }
        }
        print("PASS: \(count) header layouts across widths, languages, themes, enabled states and overflow roles")
    }
}
