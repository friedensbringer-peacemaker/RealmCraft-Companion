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
private extension View {
    func probe(_ key: String) -> some View {
        background(GeometryReader { geometry in
            Color.clear.preference(key: Frames.self, value: [key: geometry.frame(in: .named("playerSourceLayout"))])
        })
    }
}
private struct Fixture: View {
    let en: Bool
    let quest: Bool
    let measurement: Measurement
    @State private var actionFrame = CGRect.zero
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CompanionPageHeader(title: en ? "Player" : "Spieler") {
                Button(en ? "Read player" : "Spieler auslesen") {}
                    .buttonStyle(CompanionButtonStyle(prominent: true)).probe("action")
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: PlayerActionBounds.self, value: geometry.frame(in: .named("playerSourceLayout")))
                    })
            }
            PlayerSourceLayout(title: en ? "Source" : "Quelle", actionFrame: actionFrame) {
                PlayerSourceToggle(quest: .constant(quest), deviceTitle: en ? "Device" : "Gerät", savegameTitle: en ? "Savegame" : "Spielstand").probe("source")
            } detail: {
                if quest {
                    CompanionPopup(title: en ? "World" : "Welt", selection: .constant("synthetic"), options: [("synthetic", "Synthetic world")])
                        .companionField(en ? "World" : "Welt").probe("detail")
                } else {
                    SourceContextBar(saves: [Savegame()], selection: .constant("synthetic-backup"), language: en ? "en" : "de").probe("detail")
                }
            }.padding(.horizontal, CompanionLayout.pageInset)
            Spacer(minLength: 0)
        }.coordinateSpace(name: "playerSourceLayout").companionActionAlignmentScope()
            .onPreferenceChange(PlayerActionBounds.self) { actionFrame = $0 }
            .onPreferenceChange(Frames.self) { measurement.frames = $0 }
            .environment(\.companionPageGuidance, CompanionPageGuidance(purpose: en ? "Read level, inventory and equipped armor." : "Level, Inventar und angelegte Rüstung lesen.", openHelp: {}))
    }
}
@main struct RenderPlayerSourceAlignment {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let suite = "realmcraft.player-alignment-tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for en in [false, true] { for block in [false, true] { for quest in [false, true] {
            defaults.set(en ? "en" : "de", forKey: "appLanguage")
            defaults.set(block ? "block" : "classic", forKey: "companionSkin")
            let measurement = Measurement()
            let host = NSHostingView(rootView: Fixture(en: en, quest: quest, measurement: measurement).companionAppearance().defaultAppStorage(defaults))
            host.sizingOptions = []
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 460), styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = NSAppearance(named: block ? .darkAqua : .aqua)
            window.contentView = host
            // Resize the same stateful hierarchy, including both header branches.
            for width in [900.0, 400.0, 600.0, 1300.0] {
                window.setContentSize(NSSize(width: width, height: 460))
                host.frame = NSRect(x: 0, y: 0, width: width, height: 460)
                host.layoutSubtreeIfNeeded()
                RunLoop.current.run(until: Date().addingTimeInterval(0.35))
                let frames = measurement.frames
                guard let action = frames["action"], let source = frames["source"], let detail = frames["detail"] else { fatalError("Missing geometry") }
                precondition(abs(source.minX - action.minX) < 1 && abs(source.maxX - action.maxX) < 1, "Source must share action edges")
                precondition(abs(detail.maxX - action.maxX) < 1, "Detail must end at action edge")
                precondition(abs(source.width - 180) < 1 && abs(source.height - 32) < 1)
                precondition(action.maxX <= width - CompanionLayout.pageInset + 1 && detail.minX >= CompanionLayout.pageInset - 1)
                let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                host.cacheDisplay(in: host.bounds, to: bitmap)
                let name = "player-\(en ? "en" : "de")-\(block ? "block" : "classic")-\(quest ? "device" : "backup")-\(Int(width)).png"
                try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
                print("PASS \(name): source/action edges and detail right edge aligned")
            }
            window.contentView = nil
        }}}
    }
}
