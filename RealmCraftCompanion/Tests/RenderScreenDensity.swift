import SwiftUI
import AppKit

// Synthetic metadata only. No application Model, Library, device or media URLs.
struct Savegame: Identifiable {
    let id = "synthetic-backup"
    let title = "Synthetic backup with a deliberately long descriptive title"
    let world = "synthetic-world"
    let date = Date(timeIntervalSince1970: 1767268800)
    var gameDate: Date { date }
}
func displayDate(_ date: Date, language: String) -> String { "2026-01-01 12:00" }

@main struct RenderScreenDensity {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let suite = "realmcraft.density-tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for en in [false, true] { for block in [false, true] {
                for width in [600.0, 1000.0] { for expanded in [false, true] {
                defaults.set(en ? "en" : "de", forKey: "appLanguage")
                defaults.set(block ? "block" : "classic", forKey: "companionSkin")
                let root = VStack(alignment: .leading, spacing: 0) {
                    CompanionPageHeader(title: en ? "Ore frequency" : "Erzhäufigkeit") {
                        Button(en ? "Select area on map" : "Bereich auf Karte wählen") {}
                        Button(en ? "Count blocks" : "Blöcke zählen") {}
                            .buttonStyle(CompanionButtonStyle(prominent: true))
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        SourceContextBar(saves: [Savegame()], selection: .constant("synthetic-backup"), language: en ? "en" : "de")
                        Divider()
                        Text(en ? "Measure a bounded region" : "Begrenzten Bereich messen").font(CompanionLayout.detailTitle)
                        Text(en ? "Saved data, not live. Missing values are not zero." : "Gespeicherte Daten, nicht live. Fehlende Werte sind nicht null.")
                            .font(.callout).foregroundStyle(.orange)
                        CompanionDetails(en ? "Additional measurement options" : "Zusätzliche Messoptionen", initiallyExpanded: expanded) {
                            Text(en ? "These synthetic controls verify wrapping and spacing. Expanding the section starts no measurement and changes no files." : "Diese synthetischen Bedienelemente prüfen Umbruch und Abstände. Aufklappen startet keine Messung und verändert keine Dateien.")
                            HStack(spacing: 16) {
                                ForEach(["X", "Y", "Z"], id: \.self) { axis in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(axis).font(.caption)
                                        TextField(axis, text: .constant("16")).textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            Button(en ? "Measure sample" : "Stichprobe messen") {}.disabled(true)
                        }
                    }.padding(CompanionLayout.pageInset)
                    Spacer(minLength: 0)
                }.frame(width: width, height: 600, alignment: .topLeading)
                    .environment(\.companionPageGuidance, CompanionPageGuidance(purpose: en ? "Explore saved data." : "Gespeicherte Daten erkunden.", openHelp: {}))
                    .companionAppearance().defaultAppStorage(defaults)
                let host = NSHostingView(rootView: root)
                host.frame = NSRect(x: 0, y: 0, width: width, height: 600)
                let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
                window.contentView = host
                host.layoutSubtreeIfNeeded()
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
                precondition(host.fittingSize.width <= width + 1 && host.fittingSize.height <= 601)
                let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                host.cacheDisplay(in: host.bounds, to: bitmap)
                let name = "density-\(en ? "en" : "de")-\(block ? "block" : "classic")-\(Int(width))-\(expanded ? "expanded" : "collapsed").png"
                try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
                print("PASS \(name)")
                window.contentView = nil
            }}
        }}
    }
}
