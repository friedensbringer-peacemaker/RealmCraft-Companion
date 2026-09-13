import SwiftUI
import AppKit

struct ChunkChangesView: View {
    @ObservedObject var model: Model
    let english: Bool
    @State private var beforeID = ""
    @State private var report: ChunkChangeReport?
    @State private var reportKey = ""
    @State private var dimension = "o"
    @State private var filter = "all"
    @State private var selected: String?
    @State private var error: String?
    @State private var zoom: Double = 1
    @State private var visibleCount = 100
    private var key: String { model.library.root.path + ":" + (model.selection ?? "") + ":" + beforeID }
    private var current: ChunkChangeReport? { reportKey == key ? report : nil }
    private var rows: [ChunkChange] { current?.changes.filter { $0.dimension == dimension } ?? [] }
    private var filtered: [ChunkChange] { rows.filter { filter == "all" || $0.status.rawValue == filter } }
    private func t(_ de: String, _ en: String) -> String { english ? en : de }
    private func label(_ status: ChunkChange.Status) -> String {
        switch status { case .added: return t("Neu", "New"); case .changed: return t("Datei geändert", "File changed"); case .missing: return t("Im Ziel fehlend", "Missing in target"); case .unchanged: return t("Identisch", "Identical") }
    }
    private func color(_ status: ChunkChange.Status) -> Color {
        switch status { case .added: return .green; case .changed: return .orange; case .missing: return .red; case .unchanged: return .gray }
    }
    var body: some View {
        GroupBox(t("Änderungskarte zwischen Sicherungen", "Backup change map")) {
            VStack(alignment: .leading, spacing: 12) {
                Picker(t("Ältere Sicherung", "Older backup"), selection: $beforeID) {
                    Text("—").tag("")
                    ForEach(model.saves.filter { $0.world == model.selected?.world && $0.id != model.selection && $0.date < (model.selected?.date ?? .distantPast) }) {
                        Text($0.title + " · " + $0.date.formatted()).tag($0.id)
                    }
                }.disabled(model.busy)
                Text(t("Vergleicht verifizierte Datei-Prüfsummen. Geänderte Chunk-Dateien sind kein Beleg für geänderte Blöcke. Fehlend bedeutet nicht leer oder gelöscht. Gleiche Welt-ID allein belegt nicht denselben Spielverlauf.", "Compares verified file checksums. A changed chunk file does not prove block changes. Missing does not mean empty or deleted. Matching world IDs alone do not prove the same playthrough.")).font(.caption)
                Button(t("Sicherungen vergleichen", "Compare backups"), action: compare).disabled(beforeID.isEmpty || model.selected == nil || model.busy)
                if let error { Text(error).foregroundStyle(.orange).textSelection(.enabled) }
                if let current {
                    Text(current.beforeDate.formatted() + " → " + current.afterDate.formatted()).font(.caption)
                    HStack {
                        Picker(t("Dimension", "Dimension"), selection: $dimension) { Text(t("Oberwelt", "Overworld")).tag("o"); Text("Nether").tag("n") }.frame(width: 200)
                        Picker(t("Filter", "Filter"), selection: $filter) {
                            Text(t("Alle", "All")).tag("all")
                            ForEach(ChunkChange.Status.allCases, id: \.rawValue) { Text(label($0)).tag($0.rawValue) }
                        }.frame(width: 230)
                        Spacer()
                        Button("−") { zoom = max(1, zoom / 2) }.disabled(zoom <= 1)
                        Button("+") { zoom = min(256, zoom * 2) }.disabled(zoom >= 256)
                        Button(t("Gesamt", "Fit")) { selected = nil; zoom = 1 }
                    }
                    HStack {
                        ForEach(ChunkChange.Status.allCases, id: \.rawValue) { status in
                            Label("\(label(status)): \(rows.filter { $0.status == status }.count)", systemImage: "square.fill").foregroundStyle(color(status))
                        }
                    }.font(.caption)
                    if rows.isEmpty { Text(t("Keine Chunk-Dateien dieser Dimension in den beiden Sicherungen.", "No chunk files for this dimension in either backup.")) }
                    else { changeCanvas.frame(height: 300).accessibilityLabel(t("Nordorientierte Chunk-Änderungskarte. Dieselben Einträge stehen in der Liste darunter.", "North-up chunk change map. The same entries are listed below.")) }
                    Text(t("Norden = −Z · ein Feld = 16 × 16 Blöcke. Leere Kartenfläche: in keiner Sicherung als Chunk-Datei vorhanden. Zum Zentrieren einen Listeneintrag wählen.", "North = −Z · one cell = 16 × 16 blocks. Blank area: no chunk file in either snapshot. Select a list entry to center it.")).font(.caption)
                    ForEach(Array(filtered.prefix(visibleCount))) { item in
                        Button { selected = item.id; zoom = max(zoom, 2) } label: {
                            HStack { Image(systemName: selected == item.id ? "scope" : "square.fill").foregroundStyle(color(item.status)); Text("\(item.id) · " + label(item.status)); Spacer() }
                        }.buttonStyle(.plain)
                    }
                    if filtered.count > visibleCount { Button(t("Weitere 100 anzeigen", "Show 100 more")) { visibleCount += 100 } }
                    Button(t("Vergleich als JSON exportieren…", "Export comparison JSON…")) {
                        let panel = NSSavePanel(); panel.nameFieldStringValue = "Chunk-changes.json"
                        if panel.runModal() == .OK, let url = panel.url {
                            do { let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]; e.dateEncodingStrategy = .iso8601; try e.encode(current).write(to: url, options: .atomic) }
                            catch { self.error = error.localizedDescription }
                        }
                    }
                }
            }.padding(10)
        }
        .onChange(of: key) { _, _ in error = nil; selected = nil; zoom = 1; visibleCount = 100 }
        .onChange(of: dimension) { _, _ in selected = nil; zoom = 1; visibleCount = 100 }
        .onChange(of: filter) { _, _ in visibleCount = 100 }
    }
    private var changeCanvas: some View {
        Canvas { context, size in
            let minX = rows.map(\.x).min() ?? 0, maxX = rows.map(\.x).max() ?? 0
            let minZ = rows.map(\.z).min() ?? 0, maxZ = rows.map(\.z).max() ?? 0
            let focus = rows.first { $0.id == selected }
            let cx = focus.map { Double($0.x + 8) } ?? Double(minX + maxX + 16) / 2
            let cz = focus.map { Double($0.z + 8) } ?? Double(minZ + maxZ + 16) / 2
            let scale = min(size.width / Double(maxX - minX + 48), size.height / Double(maxZ - minZ + 48)) * zoom
            for row in filtered {
                let rect = CGRect(x: size.width / 2 + (Double(row.x) - cx) * scale, y: size.height / 2 + (Double(row.z) - cz) * scale, width: max(1, 16 * scale), height: max(1, 16 * scale))
                guard rect.intersects(CGRect(origin: .zero, size: size)) else { continue }
                context.fill(Path(rect), with: .color(color(row.status).opacity(0.75)))
                if row.id == selected { context.stroke(Path(rect), with: .color(.primary), lineWidth: 2) }
            }
        }.background(.quaternary.opacity(0.3)).clipped()
    }
    private func compare() {
        guard let after = model.selected, let before = model.saves.first(where: { $0.id == beforeID }), before.world == after.world, before.date < after.date, !model.busy else { return }
        let capturedKey = key, library = model.library
        report = nil; error = nil
        model.work(t("Sicherungen werden verifiziert …", "Verifying backups…")) {
            do {
                let old = try library.verify(before), new = try library.verify(after)
                let result = ChunkChangeReport(schemaVersion: 1, world: after.world, beforeID: before.id, afterID: after.id, beforeDate: before.date, afterDate: after.date,
                                               changes: ChunkChange.compare(before: old, after: new), method: "Verified SHA-256 file comparison; no block-level interpretation. Missing is not empty.")
                DispatchQueue.main.async { report = result; reportKey = capturedKey }
                return t("Chunk-Dateien verglichen. Spielstände unverändert.", "Chunk files compared. Savegames unchanged.")
            } catch { DispatchQueue.main.async { self.error = error.localizedDescription }; throw error }
        }
    }
}
