import SwiftUI

struct OrePresetsView: View {
    @ObservedObject var model: Model
    let english: Bool
    let capture: (String) -> OrePreset?
    let apply: (OrePreset) -> Void
    @State private var collection = OrePresetCollection()
    @State private var selected = ""
    @State private var name = ""
    @State private var error: String?
    @State private var failed = false
    @State private var confirmRemoval = false
    private var key: String { model.library.root.path + ":" + (model.selected?.world ?? "") }
    private var store: PlanningStore<OrePresetCollection>? {
        model.selected.map { PlanningStore(url: model.library.root.appendingPathComponent(".ore-presets").appendingPathComponent($0.world + ".json"), empty: OrePresetCollection()) }
    }
    private func t(_ de: String, _ en: String) -> String { english ? en : de }
    var body: some View {
        DisclosureGroup(t("Analyse-Vorlagen", "Analysis presets")) {
            VStack(alignment: .leading, spacing: 10) {
                Text(t("Gebiet, Dimension, Höhen, Materialauswahl, Biomfilter und Stichprobenparameter dieser Welt wiederverwenden. Anwenden startet keine Messung und übernimmt keine Ergebnisse.", "Reuse this world's region, dimension, heights, materials, biome filter and sampling parameters. Applying a preset does not start a scan or copy results.")).font(.caption)
                Picker(t("Vorlage", "Preset"), selection: $selected) {
                    Text("—").tag("")
                    ForEach(collection.presets) { Text($0.name).tag($0.id) }
                }
                HStack {
                    Button(t("Anwenden", "Apply")) {
                        guard let row = collection.presets.first(where: { $0.id == selected }), row.valid, row.world == model.selected?.world else { return }
                        apply(row)
                    }.disabled(selected.isEmpty || model.busy || failed)
                    Button(t("Entfernen…", "Remove…")) { confirmRemoval = true }.disabled(selected.isEmpty || model.busy || failed)
                    Button(t("Neu laden", "Reload"), action: load).disabled(model.busy)
                }
                HStack {
                    TextField(t("Name der neuen Vorlage", "New preset name"), text: $name).textFieldStyle(.roundedBorder)
                    Button(t("Aktuelle Auswahl speichern", "Save current selection")) {
                        guard let row = capture(name.trimmingCharacters(in: .whitespacesAndNewlines)), row.valid, row.world == model.selected?.world else {
                            error = t("Namen, ganzzahlige Grenzen und Materialauswahl prüfen.", "Check name, integer bounds and material selection."); return
                        }
                        var copy = collection; copy.presets.append(row)
                        if save(copy) { selected = row.id; name = "" }
                    }.disabled(model.selected == nil || model.busy || failed || collection.presets.count >= 100)
                }
                if let error { Text(error).foregroundStyle(.orange).textSelection(.enabled) }
            }.padding(.top, 8)
        }
        .onAppear(perform: load)
        .onChange(of: key) { _, _ in load() }
        .confirmationDialog(t("Vorlage entfernen?", "Remove preset?"), isPresented: $confirmRemoval, titleVisibility: .visible) {
            Button(t("Vorlage entfernen", "Remove preset"), role: .destructive) {
                var copy = collection; copy.presets.removeAll { $0.id == selected }
                if save(copy) { selected = "" }
            }
        } message: { Text(t("Messungen und Spielstände bleiben erhalten.", "Measurements and savegames are retained.")) }
    }
    private func load() {
        collection = OrePresetCollection(); selected = ""; name = ""; error = nil; failed = false
        do {
            if let value = try store?.load() {
                guard value.valid, value.presets.allSatisfy({ $0.world == model.selected?.world }) else { throw PlanningError.invalid }
                collection = value
            }
        } catch { self.error = error.localizedDescription; failed = true }
    }
    private func save(_ proposal: OrePresetCollection) -> Bool {
        guard proposal.valid, proposal.presets.allSatisfy({ $0.world == model.selected?.world }), let store, !model.busy, !failed else { return false }
        do { try model.library.withExclusiveOperation { try store.save(proposal, replacing: collection) }; collection = proposal; error = nil; return true }
        catch { self.error = error.localizedDescription; return false }
    }
}
