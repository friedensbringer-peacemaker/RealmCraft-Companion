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
    var guidance = false
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
                .environment(\.companionPageGuidance, guidance ? CompanionPageGuidance(purpose: "Gespeicherte Welt erkunden, Quellen prüfen und Ergebnisse mit dem richtigen Sicherungsstand vergleichen. Saved data, not live gameplay.", openHelp: {}) : nil)
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
        for width in [620.0, 740, 868, 1068, 1228, 1588] {
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
                            precondition(header.height >= 64 && header.height < 140, "Bounded header height \(header)")
                            precondition(primary.minX >= 28 - 0.1 && primary.maxX <= width - 28 + 0.1, "Visible primary action \(primary) at \(width)")
                            if search, let searchFrame = result.frames["search"] {
                                precondition(abs(searchFrame.midY - primary.midY) < 0.1, "Search and action share one horizontal row")
                            }
                            if width >= 868 {
                                precondition(abs(header.height - 64) < 0.1, "Wide header height \(header)")
                                precondition(abs(primary.maxX - (width - 28 - 32 - 12)) < 0.1, "Wide action edge \(primary) at \(width)")
                            }
                            if width == 620 && search {
                                precondition(header.height > 64, "Compact search/actions must wrap")
                            }
                            count += 1
                            window.contentView = nil
                        }
                    }
                }
            }
        }
        }
        for width in [620.0, 740, 829, 1068] {
            for block in [true, false] {
                let result = Measurement()
                let host = NSHostingView(rootView: Probe(title: "Assistenten-Anweisungen", label: "Vom Gerät sichern", search: true, overflow: true, disabled: false, block: block, result: result, guidance: true))
                let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 700), styleMask: [.borderless], backing: .buffered, defer: false)
                window.contentView = host; host.frame = NSRect(x: 0, y: 0, width: width, height: 700)
                host.layoutSubtreeIfNeeded(); RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
                guard let header = result.frames["header"], let primary = result.frames["primary"] else { fatalError("Guided header geometry missing") }
                precondition(header.height > 64 && header.height < 210, "Guidance wraps within a bounded header")
                precondition(primary.minX >= 28 && primary.maxX <= width - 28 + 0.1, "Guidance must not push actions off screen")
                count += 1; window.contentView = nil
            }
        }
        print("PASS: \(count) header layouts across widths, languages, themes, enabled states, guidance and overflow roles")
    }
}
