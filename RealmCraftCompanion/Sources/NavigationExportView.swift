import SwiftUI

struct NavigationExportOptions: View {
    let scope: String
    let english: Bool
    @Binding var enabled: Bool
    @Binding var includePOIs: Bool
    @Binding var pack: NavigationPack?
    @State private var busy = false
    @State private var status = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(english ? "Include English navigation · Beta" : "Englische Navigation beifügen · Beta", isOn: $enabled).toggleStyle(.checkbox)
            if enabled {
                HStack {
                    Button(english ? "Load route from Maps" : "Route aus Karten laden") { load() }
                    Toggle(english ? "Include nearby POIs · 250 blocks" : "Nahe POIs beifügen · 250 Blöcke", isOn: $includePOIs).toggleStyle(.checkbox)
                }.disabled(busy)
                if let pack {
                    Text("\(pack.steps.count) " + (english ? "steps" : "Schritte") + " · \(pack.distance) " + (english ? "blocks" : "Blöcke") + " · \(pack.pois.count) POIs · " + pack.dimension).font(.callout)
                    Button(english ? "Qwen: highlight useful navigation cues" : "Qwen: wichtige Navigationshinweise auswählen") { highlight() }.disabled(busy)
                    DisclosureGroup(english ? "Preview English directions" : "Englische Hinweise ansehen") { ScrollView { Text(pack.selectingPOIs(includePOIs).markdown).font(.system(.caption, design: .monospaced)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }.frame(maxHeight: 250) }
                    if includePOIs && !pack.includePOIs { Text(english ? "This route was saved without POIs. Enable POIs in Maps and plan it again." : "Diese Route wurde ohne POIs gespeichert. POIs in Karten aktivieren und neu planen.").font(.caption) }
                } else { Text(english ? "Maps → Measure → select A/B → Plan English navigation → Use in AI export." : "Karten → Messen → A/B wählen → Englische Navigation planen → Für KI-Export übernehmen.").font(.callout) }
                Text(english ? "Qwen selects supplied references locally via LM Studio (127.0.0.1:1234); route calculations work without AI. Saved map data, no live tracking. Unknown climbing routes and islands are never invented." : "Qwen wählt vorhandene Hinweise lokal über LM Studio (127.0.0.1:1234); die Routenberechnung funktioniert ohne KI. Gespeicherte Kartendaten, kein Live-Tracking. Unbekannte Kletterwege oder Inseln werden nicht erfunden.").font(.caption).foregroundStyle(.secondary)
                if busy { ProgressView().controlSize(.small) }
                if !status.isEmpty { Text(status).font(.callout).textSelection(.enabled) }
            }
        }.padding(16).companionPanel()
        .onAppear { load() }
        .onChange(of: scope) { _, _ in load() }
        .onChange(of: includePOIs) { _, _ in if var p = pack { p.localHighlights = nil; pack = p } }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("atlasNavigationChanged"))) { _ in load() }
    }
    private func load() { pack = NavigationPack.read(scope: scope); status = "" }
    private func highlight() {
        guard let source = pack?.selectingPOIs(includePOIs) else { return }; let originalScope = scope
        busy = true; status = ""
        Task { @MainActor in
            defer { busy = false }
            do { let highlighted = try await source.highlightedLocally(); guard scope == originalScope, pack?.generatedAt == source.generatedAt, pack?.steps.first?.at.x == source.steps.first?.at.x else { return }; var updated = pack; updated?.localHighlights = highlighted.localHighlights; pack = updated; status = english ? "Local Qwen highlights added. Generate context to include them." : "Lokale Qwen-Auswahl ergänzt. Zum Übernehmen Kontext erzeugen." }
            catch { status = (english ? "Local AI unavailable; complete route remains usable. Start LM Studio with Qwen3.5-4B. " : "Lokale KI nicht verfügbar; die vollständige Route bleibt nutzbar. LM Studio mit Qwen3.5-4B starten. ") + error.localizedDescription }
        }
    }
}
