import SwiftUI
import AppKit

private struct GridFrames: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
private extension View {
    func gridProbe(_ id: String) -> some View {
        background(GeometryReader { geometry in
            Color.clear.preference(key: GridFrames.self, value: [id: geometry.frame(in: .named("grid"))])
        })
    }
}
private final class Measurements { var frames: [String: CGRect] = [:] }
private final class SelectionState {
    var selected: String?
    var accepted = true
    var writes = 0
}

// Production field/header components; only synthetic constant selection bindings.
@main struct RenderFormGrid {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        checkSelectionBindings()
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let suite = "realmcraft.form-grid-tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for en in [false, true] { for block in [false, true] { for width in [300.0, 600.0, 1000.0] {
            defaults.set(en ? "en" : "de", forKey: "appLanguage")
            defaults.set(block ? "block" : "classic", forKey: "companionSkin")
            let measurements = Measurements()
            let labels = en ? ["From", "To", "Line", "Mode", "Evidence"] : ["Von", "Nach", "Linie", "Art", "Nachweis"]
            let root = VStack(alignment: .leading, spacing: 0) {
                CompanionPageHeader(title: "Nether Metro") {
                    Button(en ? "Plan journey" : "Reise planen") {}.disabled(true).gridProbe("secondary")
                    Button(en ? "Add station" : "Station hinzufügen") {}
                        .buttonStyle(CompanionButtonStyle(prominent: true)).gridProbe("primary")
                }
                VStack(alignment: .leading, spacing: 14) {
                    Text(en ? "Directed connection" : "Gerichtete Strecke").font(CompanionLayout.detailTitle)
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        CompanionPopup(title: label, selection: .constant(index < 3 ? "empty" : "value"), options: [
                            ("empty", "—"),
                            ("value", index == 3 ? (en ? "Rail" : "Schiene") : (en ? "Planned" : "Geplant")),
                            ("long", en ? "A longer synthetic station name" : "Ein längerer synthetischer Stationsname")
                        ]).gridProbe("field-\(index)").companionField(label)
                    }
                    CompanionPopup(title: en ? "Height mapping · hypothesis" : "Höhenanpassung · Hypothese", selection: .constant("full"),
                        options: [("full", en ? "Map full height ranges" : "Gesamte Höhenbereiche abbilden")])
                        .gridProbe("field-long").companionField(en ? "Height mapping · hypothesis" : "Höhenanpassung · Hypothese")
                }.padding(CompanionLayout.pageInset)
                Spacer(minLength: 0)
            }.frame(width: width, height: 900, alignment: .topLeading)
                .coordinateSpace(name: "grid")
                .onPreferenceChange(GridFrames.self) { measurements.frames = $0 }
                .environment(\.companionPageGuidance, CompanionPageGuidance(purpose: en ? "Synthetic layout test" : "Synthetischer Layout-Test", openHelp: {}))
                .companionAppearance().defaultAppStorage(defaults)
            let host = NSHostingView(rootView: root)
            host.frame = NSRect(x: 0, y: 0, width: width, height: 900)
            let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = NSAppearance(named: block ? .darkAqua : .aqua)
            window.contentView = host
            host.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            let frames = measurements.frames
            let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
            host.cacheDisplay(in: host.bounds, to: bitmap)
            let name = "form-\(en ? "en" : "de")-\(block ? "block" : "classic")-\(Int(width)).png"
            try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
            let fields = frames.filter { $0.key.hasPrefix("field-") }.map(\.value)
            precondition(fields.count == 6, "All field probes must be present")
            let left = fields[0].minX, right = fields[0].maxX
            precondition(fields.allSatisfy { abs($0.minX - left) < 1 && abs($0.maxX - right) < 1 }, "Fields must share both edges")
            precondition(abs(right - (width - CompanionLayout.pageInset)) < 1, "Fields must fill the content row")
            for id in ["primary", "secondary"] {
                guard let frame = frames[id] else { fatalError("Missing header action") }
                precondition(abs(frame.width - 180) < 1 && abs(frame.height - 32) < 1, "Header action dimensions differ")
            }
            precondition(host.fittingSize.width <= width + 1 && host.fittingSize.height <= 901)
            print("PASS \(name): 6 equal field edges; 2 equal 180x32 actions")
            window.contentView = nil
        }}}
    }
    @MainActor private static func checkSelectionBindings() {
        let state = SelectionState()
        let binding = Binding<String?>(get: { state.selected }, set: { if state.accepted { state.selected = $0; state.writes += 1 } })
        let model = CompanionPopup(title: "Synthetic choice", selection: binding,
            options: [(nil, "—"), ("a", "Same title"), ("b", "Same title")])
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        model.synchronize(popup)
        precondition(popup.numberOfItems == 3 && popup.indexOfSelectedItem == 0 && state.writes == 0)
        let coordinator = model.makeCoordinator()
        popup.selectItem(at: 2); coordinator.choose(popup)
        precondition(state.selected == "b" && popup.indexOfSelectedItem == 2 && state.writes == 1)
        state.accepted = false
        popup.selectItem(at: 1); coordinator.choose(popup)
        precondition(state.selected == "b" && popup.indexOfSelectedItem == 2 && state.writes == 1)
        state.accepted = true; popup.isEnabled = false
        popup.selectItem(at: 1); coordinator.choose(popup)
        precondition(state.selected == "b" && state.writes == 1)
        model.synchronize(popup)
        popup.selectItem(at: 0); coordinator.choose(popup)
        precondition(state.selected == nil && state.writes == 2)
        state.selected = "b"
        let reordered = CompanionPopup(title: "Synthetic choice", selection: binding,
            options: [("b", "Renamed"), (nil, "—"), ("a", "Same title")])
        reordered.synchronize(popup)
        precondition(popup.indexOfSelectedItem == 0 && popup.titleOfSelectedItem == "Renamed" && state.writes == 2)
        let empty = CompanionPopup<String?>(title: "Synthetic choice", selection: binding, options: [])
        empty.synchronize(popup)
        precondition(!popup.isEnabled && popup.numberOfItems == 0 && state.selected == "b" && state.writes == 2)
        print("PASS native popup: duplicate titles, nil, rejected/disabled changes, reordered options, empty state; synchronization never writes")
    }
}
