import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AIContextExportView: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @ObservedObject var chests: ChestController
    let language: String
    @StateObject private var sharing = AIExportSharing()
    @State private var includeChests = true
    @State private var document: AIContextDocument?
    @State private var documentTitle = ""
    @State private var documentWorld = ""
    @State private var generating = false
    @State private var notice = ""
    @State private var failure = ""
    @State private var request = UUID()
    @Environment(\.companionTheme) private var theme
    private var en: Bool { language == "en" }

    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: en ? "AI export" : "KI-Export") {
                Button(en ? "Generate context" : "Kontext erzeugen", action: generate)
                    .buttonStyle(CompanionButtonStyle(prominent: true))
                    .disabled(model.busy || generating || model.selected == nil || (includeChests && (!maps.ready || maps.checking)))
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(en ? "Your world as a document for GPT, Claude and other agents." : "Deine Welt als Dokument für GPT, Claude und andere Agenten.").font(.title2.bold())
                    Text(en ? "Choose a backup and generate a self-contained snapshot. Save Markdown to discuss it with an agent, or JSON for structured processing. Creation is local; you choose where to upload the file."
                         : "Wähle eine Sicherung und erzeuge ein eigenständig verständliches Abbild. Speichere Markdown für das Gespräch mit einem Agenten oder JSON zur strukturierten Verarbeitung. Die Erstellung erfolgt lokal; du entscheidest, wo du die Datei hochlädst.")
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Picker(en ? "Savegame" : "Spielstand", selection: $model.selection) {
                        Text(en ? "Select a savegame" : "Spielstand auswählen").tag(nil as String?)
                        ForEach(model.saves) { save in Text(save.title + " · " + displayDate(save.date, language: language)).tag(Optional(save.id)) }
                    }.frame(maxWidth: 680).disabled(model.busy || generating)
                    Toggle(en ? "Include all saved chests and their contents" : "Alle gespeicherten Kisten mit Inhalten einbeziehen", isOn: $includeChests)
                        .toggleStyle(.checkbox).disabled(model.busy || generating)
                    Text(en ? "The export freshly scans this backup, including chests hidden by UI filters. Chests marked in Maps or under Conversation → My chests count as owned resources. Unmarked containers remain visible with unknown ownership."
                         : "Der Export liest diese Sicherung frisch ein, einschließlich durch Oberflächenfilter ausgeblendeter Kisten. In Karten oder unter Gespräch → Eigene Kisten markierte Kisten zählen zu deinen Lagerressourcen. Unmarkierte Behälter bleiben mit unbekanntem Besitz sichtbar.")
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    if includeChests && !maps.ready {
                        Text(en ? "Chest reading needs the map tools. Set them up here, or disable chest inclusion to export player data and named places."
                             : "Zum Lesen der Kisten werden die Kartenwerkzeuge benötigt. Richte sie hier ein oder deaktiviere die Kisten, um Spielerdaten und benannte Orte zu exportieren.").font(.callout)
                        MapToolsSetup(model: model, maps: maps, english: en)
                    }
                    if generating {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { ProgressView().controlSize(.small); Text(en ? "Verifying backup and reading records… Large worlds can take several minutes." : "Sicherung prüfen und Daten lesen … Bei großen Welten kann das mehrere Minuten dauern.") }
                            Text(tr(model.status)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if !failure.isEmpty { Text(failure).foregroundStyle(.red).textSelection(.enabled) }
                    if let document {
                        Divider()
                        Text(documentTitle).font(.headline)
                        Text(sizeDescription(document)).font(.callout).foregroundStyle(.secondary)
                        HStack {
                            Button(en ? "Save Markdown…" : "Markdown speichern …") { save(document, json: false) }
                                .buttonStyle(CompanionButtonStyle(prominent: true))
                            Button(en ? "Save JSON…" : "JSON speichern …") { save(document, json: true) }
                        }.disabled(generating)
                        VStack(alignment: .leading, spacing: 12) {
                            Label(en ? "Send to iPhone" : "An iPhone übergeben", systemImage: "iphone").font(.headline)
                            HStack {
                                Button(en ? "Save to iCloud…" : "In iCloud speichern …") {
                                    sharing.saveToCloud(markdown: document.markdown, world: documentWorld, library: model.library.root, english: en)
                                }
                                Button(en ? "Send via AirDrop…" : "Per AirDrop senden …") {
                                    sharing.airDrop(markdown: document.markdown, world: documentWorld, library: model.library.root, english: en)
                                }.disabled(sharing.sharing)
                            }.buttonStyle(CompanionButtonStyle())
                            HStack {
                                Button(en ? "Choose iCloud folder…" : "iCloud-Ordner auswählen …") { sharing.chooseFolder(english: en) }
                                if sharing.folder != nil {
                                    Button(en ? "Forget folder" : "Ordner vergessen") { sharing.forgetFolder() }
                                }
                            }
                            if let folder = sharing.folder { Text(folder.path).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                            Text(en ? "Both options transfer the complete Markdown snapshot. Each export gets a new file. The chosen iCloud folder is remembered on this Mac."
                                 : "Beide Optionen übertragen das vollständige Markdown-Abbild. Jeder Export erhält eine neue Datei. Der gewählte iCloud-Ordner wird auf diesem Mac gespeichert.")
                                .font(.caption).foregroundStyle(.secondary)
                            if !sharing.status.isEmpty { Text(sharing.status).font(.callout).textSelection(.enabled) }
                            if !sharing.failure.isEmpty { Text(sharing.failure).foregroundStyle(.red).textSelection(.enabled) }
                            if let file = sharing.lastSaved {
                                Button(en ? "Show saved file in Finder" : "Gespeicherte Datei im Finder zeigen") { NSWorkspace.shared.activateFileViewerSelecting([file]) }
                            }
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(theme.surface)
                        if !notice.isEmpty { Text(notice).font(.callout).textSelection(.enabled) }
                        Text(en ? "Upload one format to your agent. Markdown includes all exported records; JSON represents the same snapshot. This is a record of the backup, not the running game."
                             : "Lade eines der Formate bei deinem Agenten hoch. Markdown enthält alle exportierten Datensätze; JSON bildet denselben Datenstand ab. Es handelt sich um die Sicherung, nicht um das laufende Spiel.")
                            .font(.callout).foregroundStyle(.secondary)
                        let issues = document.payload["issues"] as? [String] ?? []
                        if !issues.isEmpty {
                            Label(en ? "\(issues.count) data gap(s) — included in the document" : "\(issues.count) Datenlücke(n) — im Dokument ausgewiesen", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            ForEach(Array(issues.prefix(8).enumerated()), id: \.offset) { _, issue in Text(issue).font(.caption).textSelection(.enabled) }
                            if issues.count > 8 { Text(en ? "All issues are listed in the export." : "Alle Hinweise stehen im Export.").font(.caption) }
                        }
                        DisclosureGroup(en ? "Document preview (first 12,000 characters)" : "Dokumentvorschau (erste 12.000 Zeichen)") {
                            Text(String(document.markdown.prefix(12_000))).font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(12).background(theme.surface)
                        }
                    } else if !generating {
                        Divider()
                        Text(en ? "Included" : "Enthalten").font(.headline)
                        Text(en ? "• Backup identity, dates and saved world bounds\n• Player level, inventory, armor, durability and enchantments\n• Saved respawn point and named places\n• Chest coordinates, ownership marks, items and resource summaries\n• World name and seed (supported format), free map markers and chest names\n• Storage groups, repair forecasts and recipe material checks\n• Build plans, checklists, test notes and mob reference knowledge\n• Explicit data gaps and guidance for the agent"
                             : "• Sicherungs-ID, Zeitangaben und gespeicherte Weltgrenzen\n• Spielerlevel, Inventar, Rüstung, Haltbarkeit und Verzauberungen\n• Gespeicherter Respawnpunkt und benannte Orte\n• Kistenkoordinaten, Besitzmarkierungen, Inhalte und Ressourcenübersicht\n• Weltname und Seed (unterstütztes Format), freie Kartenmarker und Kistennamen\n• Lagergruppen, Reparaturprognosen und Rezept-Materialchecks\n• Baupläne, Checklisten, Testnotizen und Mob-Referenzwissen\n• Ausdrückliche Datenlücken und Hinweise für den Agenten")
                            .lineSpacing(7).fixedSize(horizontal: false, vertical: true)
                        Text(en ? "Player position, health, hunger, terrain resources and live mobs are currently unavailable. The document labels these as unknown."
                             : "Spielerposition, Gesundheit, Hunger, Rohstoffe im Gelände und lebende Mobs sind derzeit nicht verfügbar. Das Dokument kennzeichnet diese als unbekannt.").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(CompanionLayout.pageInset).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear { maps.check(model) }
        .onChange(of: model.selection) { _, _ in clear() }
        .onChange(of: model.library.root) { _, _ in clear() }
        .onChange(of: includeChests) { _, _ in clear() }
        .onChange(of: language) { _, _ in clear() }
    }
    private func clear() { request = UUID(); document = nil; notice = ""; failure = ""; generating = false }
    private func sizeDescription(_ document: AIContextDocument) -> String {
        let bytes = document.markdown.utf8.count
        let size = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
        let inventory = (document.payload["player"] as? [String: Any])?["inventory"] as? [[String: Any]] ?? []
        let storage = (document.payload["storage"] as? [String: Any])?["chests"] as? [[String: Any]] ?? []
        return en ? "Markdown: \(size) · \(inventory.count) occupied inventory slots · \(storage.count) chests · no record truncation"
                  : "Markdown: \(size) · \(inventory.count) belegte Inventarslots · \(storage.count) Kisten · keine gekürzten Datensätze"
    }
    private func generate() {
        guard let selected = model.selected, !model.busy else { return }
        let backend = model.library, root = backend.root, english = en
        let python = includeChests ? maps.python : nil
        let engine = includeChests ? Bundle.main.resourceURL?.appendingPathComponent("MapEngine") : nil
        let names = chests.names
        let supplement = AIContextSupplement.capture(save: selected, resources: Bundle.main.resourceURL)
        let owned = Set(UserDefaults.standard.stringArray(forKey: "conversation.ownedChests." + selected.annotationScope) ?? [])
        let places = CompanionPlace.named(UserDefaults.standard.dictionary(forKey: "atlasPOI." + selected.annotationScope) as? [String: String] ?? [:])
        clear(); generating = true
        let token = UUID(); request = token
        model.work(english ? "Generating AI context…" : "KI-Kontext wird erzeugt …") {
            let result = Result { try backend.makeAIContext(selected, python: python, engine: engine, names: names, ownedIDs: owned, places: places, english: english, supplement: supplement) }
            DispatchQueue.main.async {
                guard request == token, model.selection == selected.id, model.library.root == root else { return }
                generating = false
                switch result {
                case .success(let value): document = value; documentTitle = selected.title; documentWorld = selected.world
                case .failure(let error): failure = error.localizedDescription
                }
            }
            _ = try result.get()
            return english ? "AI context ready. Choose Markdown or JSON to save." : "KI-Kontext bereit. Zum Speichern Markdown oder JSON wählen."
        }
    }
    private func save(_ value: AIContextDocument, json: Bool) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = json ? [.json] : [UTType(filenameExtension: "md") ?? .plainText]
        panel.nameFieldStringValue = "RealmCraft-\(documentWorld)-AI-Context." + (json ? "json" : "md")
        guard panel.runModal() == .OK, let target = panel.url else { return }
        do {
            // Export output must never overwrite a file inside the managed save library.
            let destination = target.resolvingSymlinksInPath().standardizedFileURL.path
            let root = model.library.root.resolvingSymlinksInPath().standardizedFileURL.path
            guard destination != root, !destination.hasPrefix(root + "/") else {
                throw LibraryError(en ? "Save the document outside the savegame library." : "Speichere das Dokument außerhalb der Spielstand-Bibliothek.")
            }
            let data = json ? try value.json : Data(value.markdown.utf8)
            try data.write(to: target, options: .atomic)
            notice = (en ? "Saved: " : "Gespeichert: ") + target.path
            failure = ""
        } catch { failure = error.localizedDescription }
    }
}
