import SwiftUI
import AppKit

struct Savegame: Identifiable {
    let id = "synthetic-backup"
    let title = "Synthetic backup with a long display name"
    let world = "synthetic-world"
    let date = Date(timeIntervalSince1970: 1767268800)
    var gameDate: Date { date }
}
func displayDate(_ date: Date, language: String) -> String { "2026-01-01 12:00" }
private struct Frames: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
private final class Measurement { var frames: [String: CGRect] = [:] }
private final class FixtureState: ObservableObject { @Published var actions = 1 }
private extension View {
    func probe(_ key: String) -> some View {
        background(GeometryReader { geometry in
            Color.clear.preference(key: Frames.self, value: [key: geometry.frame(in: .global)])
        })
    }
}
private struct Fixture: View {
    let en: Bool
    let measurement: Measurement
    @ObservedObject var state: FixtureState
    @State private var selection = "a"
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CompanionPageHeader(title: en ? "Maps" : "Karten") {
                ForEach(0..<state.actions, id: \.self) { index in
                    Button(en ? "Generate map" : "Karte erzeugen") {}
                        .buttonStyle(CompanionButtonStyle(prominent: index == state.actions - 1))
                        .probe("action-\(index)")
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                SourceContextBar(saves: [Savegame()], selection: .constant("synthetic-backup"), language: en ? "en" : "de")
                CompanionPopup(title: en ? "Area" : "Bereich", selection: .constant("all"), options: [("all", "Synthetic area")])
                    .companionField(en ? "Area" : "Bereich").probe("field").companionActionAligned()
                CompanionEqualSegments(title: en ? "View" : "Ansicht", selection: $selection,
                    options: [("a", en ? "Stations & lines" : "Stationen & Linien"),
                              ("b", en ? "Map & network" : "Karte & Netz"),
                              ("c", en ? "Edit & travel" : "Bearbeiten & Reisen")])
                    .probe("segments").companionActionAligned()
            }.padding(.horizontal, CompanionLayout.pageInset)
            Spacer(minLength: 0)
        }.companionActionAlignmentScope()
            .onPreferenceChange(Frames.self) { measurement.frames = $0 }
            .environment(\.companionPageGuidance, CompanionPageGuidance(purpose: en ? "Explore a saved world." : "Eine gespeicherte Welt erkunden.", openHelp: {}))
            .padding(.leading, 96)
    }
}
private func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }
@main struct RenderActionAlignment {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let suite = "realmcraft.action-alignment-tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for en in [false, true] { for block in [false, true] {
            defaults.set(en ? "en" : "de", forKey: "appLanguage")
            defaults.set(block ? "block" : "classic", forKey: "companionSkin")
            let measurement = Measurement(), state = FixtureState()
            let host = NSHostingView(rootView: Fixture(en: en, measurement: measurement, state: state).companionAppearance().defaultAppStorage(defaults))
            host.sizingOptions = []
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1400, height: 520), styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = NSAppearance(named: block ? .darkAqua : .aqua)
            window.contentView = host
            for width in [1400.0, 796.0, 1096.0, 1400.0] {
                window.setContentSize(NSSize(width: width, height: 520))
                host.frame = NSRect(x: 0, y: 0, width: width, height: 520)
                for count in [3, 1, 0, 2] {
                    state.actions = count
                    host.layoutSubtreeIfNeeded()
                    RunLoop.current.run(until: Date().addingTimeInterval(0.3))
                    let frames = measurement.frames
                    guard let field = frames["field"], let segments = frames["segments"] else { fatalError("Missing geometry") }
                    let expected = count == 0 ? width - CompanionLayout.pageInset : min(width - CompanionLayout.pageInset, frames["action-\(count - 1)"]!.maxX)
                    precondition(abs(field.maxX - expected) < 1, "Field edge \(field.maxX) != \(expected)")
                    precondition(abs(segments.maxX - expected) < 1, "Segment edge")
                    precondition(abs(segments.height - 32) < 1)
                    let popups = descendants(host).compactMap { $0 as? NSPopUpButton }.filter {
                        !$0.isHiddenOrHasHiddenAncestor && $0.itemTitles.contains(where: { $0.hasPrefix("Synthetic") })
                    }
                    precondition(popups.count == 2, "Both synthetic field popups must be present")
                    for popup in popups {
                        let rect = popup.convert(popup.bounds, to: host)
                        precondition(abs(rect.maxX - expected) < 1, "Popup edge \(rect.maxX) != \(expected)")
                    }
                    for index in 0..<count {
                        let action = frames["action-\(index)"]!
                        precondition(abs(action.width - 180) < 1 && abs(action.height - 32) < 1)
                    }
                    let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    let name = "actions-\(count)-\(en ? "en" : "de")-\(block ? "block" : "classic")-\(Int(width)).png"
                    try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
                    print("PASS \(name)")
                }
            }
            window.contentView = nil
        }}
    }
}
