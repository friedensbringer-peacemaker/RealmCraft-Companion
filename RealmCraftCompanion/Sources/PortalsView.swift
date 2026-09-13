import SwiftUI

struct PortalsView: View {
    @ObservedObject var model: Model
    let language: String
    @State private var draftID = UUID()
    private var draftToken: String { DraftTransitions.fingerprint([start, destination, name, note]) }
    private var dirty: Bool { !name.isEmpty || !note.isEmpty || !start.isEmpty || !destination.isEmpty }
    private func guardedRead() { model.drafts.perform { read() } }
    @State private var plans: [PortalPlan] = []
    @State private var planError: String?
    @State private var portals: [SavedPortal] = []
    @State private var pairs: [PortalPair] = []
    @State private var fingerprint = ""
    @State private var pairStorageData: Data?
    @State private var error: String?
    @State private var start = ""
    @State private var destination = ""
    @State private var name = ""
    @State private var note = ""
    private var english: Bool { language == "en" }
    private var selectionKey: String { model.library.root.path + (model.selection ?? "") }
    private var storageURL: URL? {
        guard let save = model.selected else { return nil }
        return model.library.root.appendingPathComponent(".portal-pairs").appendingPathComponent(save.id + ".json")
    }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Nether travel planner · Portal pairs" : "Nether-Reiseplaner · Portalpaare") {
                Button(english ? "Reload" : "Neu einlesen", action: guardedRead).disabled(model.selected == nil)
            }
            SourceContextBar(saves: model.saves, selection: $model.selection, language: language)
                .padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 12).disabled(model.busy)
            if dirty { Label(english ? "Unsaved portal connection" : "Ungespeicherte Portalverbindung", systemImage: "pencil.circle").font(.caption).foregroundStyle(.orange).padding(8) }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(english ? "Saved portal positions and recorded travel connections. Coordinates are X / Y / Z of a bottom portal block, not an exact arrival position. Connections are recorded observations; the POI data does not store destination links." : "Gespeicherte Portalpositionen und vermerkte Reiseverbindungen. Koordinaten sind X / Y / Z eines unteren Portalblocks, keine exakte Ankunftsposition. Verbindungen sind dokumentierte Beobachtungen; die POI-Daten speichern keine Zielverknüpfung.").foregroundStyle(.secondary)
                    if let error { CompanionNotice(message: error, kind: .error) }
                    if let save = model.selected {
                        Text((english ? "Snapshot: " : "Spielstand: ") + displayDate(save.gameDate, language: language)).font(.caption)
                    }
                    if let planError { CompanionNotice(message: planError, kind: .error) }
                    if !plans.isEmpty {
                        Text(english ? "Planned portals · assumed scale 8:1" : "Geplante Portale · angenommener Maßstab 1:8").font(.title3.bold())
                        ForEach(plans) { plan in
                            GroupBox {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(plan.name).font(.headline)
                                    Text(dimensionName(plan.dimension) + " · X \(plan.x) / Z \(plan.z)")
                                    Text((english ? "Calculated counterpart: " : "Berechnete Gegenposition: ") + dimensionName(plan.targetDimension) + " · X " + coordinate(plan.targetX) + " / Z " + coordinate(plan.targetZ))
                                    Text((english ? "Nearest block (ties away from zero): " : "Nächster Block (halbe Werte von null weg): ") + "X \(plan.targetBlockX) / Z \(plan.targetBlockZ)").font(.caption)
                                    if let y = plan.referenceY { Text((english ? "Source map reference height: Y " : "Referenzhöhe der Ausgangskarte: Y ") + String(y)).font(.caption) }
                                    Text(english ? "Target Y and actual exit are unknown. Verify terrain and existing portal links before building." : "Zielhöhe Y und tatsächlicher Ausgang sind unbekannt. Gelände und vorhandene Portalverbindungen vor dem Bau prüfen.").font(.caption).foregroundStyle(.secondary)
                                }.frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled).padding(6)
                            }
                        }
                    }
                    ForEach(pairs) { pair in
                        GroupBox {
                            VStack(alignment: .leading, spacing: 9) {
                                Text(pair.name).font(.headline)
                                Text(label(pair.start) + "  →  " + label(pair.destination)).font(.body.monospaced())
                                Text(pair.note).foregroundStyle(.secondary)
                                Text(english ? "Recorded connection · reverse direction not automatically confirmed" : "Vermerkte Verbindung · Rückrichtung nicht automatisch bestätigt").font(.caption)
                            }.frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled).padding(6)
                        }
                    }
                    Text(english ? "Portals in this snapshot" : "Portale in dieser Sicherung").font(.title3.bold())
                    ForEach(portals) { portal in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(label(portal.id)).font(.headline)
                            Text(portal.bounds + " · \(portal.blocks.count) " + (english ? "saved POI blocks" : "gespeicherte POI-Blöcke")).font(.caption)
                        }.textSelection(.enabled)
                    }
                    if !portals.isEmpty {
                        Divider()
                        Text(english ? "Record a portal connection" : "Portalverbindung vermerken").font(.title3.bold())
                        TextField(english ? "Name" : "Bezeichnung", text: $name)
                        Picker(english ? "Start" : "Anfang", selection: $start) {
                            Text("—").tag("")
                            ForEach(portals) { Text(label($0.id)).tag($0.id) }
                        }
                        Picker(english ? "Destination" : "Ziel", selection: $destination) {
                            Text("—").tag("")
                            ForEach(portals.filter { $0.dimension != portals.first(where: { $0.id == start })?.dimension }) { Text(label($0.id)).tag($0.id) }
                        }
                        TextField(english ? "Evidence / travel observation" : "Nachweis / Reisebeobachtung", text: $note)
                        Button(english ? "Save connection" : "Verbindung speichern", action: { _ = savePair() })
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || note.trimmingCharacters(in: .whitespaces).isEmpty || !validPair || fingerprint.isEmpty)
                    }
                    Divider()
                    Text(english ? "In Maps, select a point and choose Plan portal here. Planned counterparts use an assumed 8:1 scale, not a verified RealmCraft linking rule." : "Unter Karten einen Punkt auswählen und Hier Portal planen wählen. Geplante Gegenpositionen verwenden den angenommenen Maßstab 1:8, keine bestätigte RealmCraft-Verknüpfungsregel.").font(.caption).foregroundStyle(.secondary)
                }.lineSpacing(3).padding(CompanionLayout.pageInset).frame(maxWidth: 900, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
            }
        }.trackDraft(model.drafts, id: draftID, token: draftToken, dirty: { dirty }, title: english ? "Portal connection" : "Portalverbindung", save: savePair, discard: read)
        .onAppear(perform: read).onChange(of: selectionKey) { _, _ in read() }
    }
    private func dimensionName(_ value: String) -> String { value == "o" ? (english ? "Overworld" : "Oberwelt") : "Nether" }
    private func coordinate(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...3)).locale(Locale(identifier: language))) }
    private var validPair: Bool {
        guard let a = portals.first(where: { $0.id == start }), let b = portals.first(where: { $0.id == destination }) else { return false }
        return a.dimension != b.dimension
    }
    private func label(_ id: String) -> String {
        guard let p = portals.first(where: { $0.id == id }) else { return id }
        return (p.dimension == "o" ? (english ? "Overworld" : "Oberwelt") : "Nether") + " · " + p.anchor.text
    }
    private func read() {
        portals = []; pairs = []; error = nil; fingerprint = ""; start = ""; destination = ""; name = ""; note = ""
        plans = []; planError = nil; pairStorageData = nil
        guard let save = model.selected else { return }
        do { plans = try PortalPlanStore(url: model.library.root.appendingPathComponent(".portal-plans").appendingPathComponent(save.id + ".json")).load() }
        catch { planError = error.localizedDescription }
        do {
            let result = try PortalReader.read(model.library.worldFolder(save))
            portals = result.portals; fingerprint = result.fingerprint
            if let url = storageURL, FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                let document = try JSONDecoder().decode(PortalPairDocument.self, from: data)
                guard document.fingerprint == fingerprint,
                      document.pairs.allSatisfy({ p in portals.contains(where: { $0.id == p.start }) && portals.contains(where: { $0.id == p.destination }) }) else {
                    error = english ? "Saved connections belong to different portal data. The original file is preserved; review it before recording changes." : "Gespeicherte Verbindungen gehören zu anderen Portaldaten. Die ursprüngliche Datei bleibt erhalten; vor Änderungen prüfen."
                    fingerprint = ""; return
                }
                pairs = document.pairs; pairStorageData = data
            }
        } catch { self.error = error.localizedDescription; fingerprint = "" }
    }
    private func savePair() -> Bool {
        guard validPair, !fingerprint.isEmpty, !name.trimmingCharacters(in: .whitespaces).isEmpty, !note.trimmingCharacters(in: .whitespaces).isEmpty, let url = storageURL else { error = english ? "Complete name, evidence and both portals before saving." : "Vor dem Speichern Name, Nachweis und beide Portale ergänzen."; return false }
        var updated = pairs
        updated.append(PortalPair(id: UUID().uuidString, name: name, start: start, destination: destination, note: note))
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(PortalPairDocument(fingerprint: fingerprint, pairs: updated))
            try model.library.withExclusiveOperation {
                let current = FileManager.default.fileExists(atPath: url.path) ? try Data(contentsOf: url) : nil
                guard current == pairStorageData else { throw PlanningError.changed }
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
            }
            pairStorageData = data
            pairs = updated; name = ""; note = ""; start = ""; destination = ""; error = nil; model.drafts.remove(draftID); return true
        } catch { self.error = error.localizedDescription; return false }
    }
}
