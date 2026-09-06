import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AIContextExportView: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @ObservedObject var chests: ChestController
    let language: String
    @Binding var generateRequest: UUID?
    @Binding var openLatest: Bool
    var openSkills: () -> Void = {}
    @ObservedObject private var skills = AgentSkillLibrary.shared
    @AppStorage("agentSkill.selectedID") private var selectedSkillID = "realmcraft-world-context"
    @AppStorage("agentSkill.includeInExport") private var includeSkill = true
    @AppStorage("agentSkill.includeProfile") private var includeProfile = false
    @State private var documentDate: Date?
    @StateObject private var sharing = AIExportSharing()
    @State private var includeNavigation = false
    @State private var includeNavigationPOIs = true
    @State private var navigationPack: NavigationPack?
    @State private var includeChests = true
    @AppStorage(VideoKnowledgeExport.selectionKey) private var videoSelection = ""
    @AppStorage("videoExport.include") private var includeVideos = true
    @AppStorage("videoExport.separate") private var separateVideos = false
    private let videoTips = VideoTip.bundled ?? []
    @State private var document: AIContextDocument?
    @State private var documentTitle = ""
    @State private var documentWorld = ""
    @State private var generating = false
    @State private var notice = ""
    @State private var failure = ""
    @State private var request = UUID()
    @Environment(\.companionTheme) private var theme
    private var en: Bool { language == "en" }
    private var chosenSkill: AgentSkill? { skills.state.skills.first { $0.id == selectedSkillID && !$0.archived }.map { $0.localized(en ? "en" : "de") } }
    private var canGenerate: Bool { model.selected != nil && !model.busy && !generating && (!includeChests || (maps.ready && !maps.checking)) && (!includeSkill || chosenSkill != nil) }


    var body: some View {
        exportSelectionEvents
        .onChange(of: videoSelection) { _, _ in clear() }
        .onChange(of: includeVideos) { _, _ in clear() }
        .onChange(of: separateVideos) { _, _ in clear() }
        .onChange(of: includeNavigation) { _, _ in clear() }
        .onChange(of: includeNavigationPOIs) { _, _ in clear() }
        .onChange(of: includeChests) { _, _ in clear() }
        .onChange(of: language) { _, _ in clear() }
    }
    private var page: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: en ? "AI export" : "KI-Export") {
                Button(en ? "Generate context" : "Kontext erzeugen", action: generate)
                    .buttonStyle(CompanionButtonStyle(prominent: true))
                    .disabled(!canGenerate)
            }
            HStack {
                    Picker(en ? "Savegame" : "Spielstand", selection: $model.selection) {
                        Text(en ? "Select a savegame" : "Spielstand auswählen").tag(nil as String?)
                        ForEach(model.saves) { save in Text(save.title + " · " + displayDate(save.date, language: language)).tag(Optional(save.id)) }
                    }.frame(maxWidth: CompanionLayout.sourceWidth).disabled(model.busy || generating)
                Spacer(minLength: 0)
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(en ? "Your world as a document for GPT, Claude and other agents." : "Deine Welt als Dokument für GPT, Claude und andere Agenten.").font(.title2.bold())
                    Text(en ? "Choose a backup and generate a self-contained snapshot. Save Markdown to discuss it with an agent, or JSON for structured processing. Creation is local; you choose where to upload the file."
                         : "Wähle eine Sicherung und erzeuge ein eigenständig verständliches Abbild. Speichere Markdown für das Gespräch mit einem Agenten oder JSON zur strukturierten Verarbeitung. Die Erstellung erfolgt lokal; du entscheidest, wo du die Datei hochlädst.")
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle(en ? "Include an agent skill" : "Agenten-Skill beifügen", isOn: $includeSkill).toggleStyle(.checkbox)
                            Spacer()
                            Button(en ? "Manage skills…" : "Skills verwalten …", action: openSkills)
                        }
                        if includeSkill {
                            Picker(en ? "Skill" : "Skill", selection: $selectedSkillID) {
                                Text(en ? "Choose a skill" : "Skill auswählen").tag("")
                                ForEach(skills.state.skills.filter { !$0.archived }) { Text($0.localized(en ? "en" : "de").title).tag($0.id) }
                            }.frame(maxWidth: 600)
                            if let skill = chosenSkill { Text(skill.summary).font(.callout).foregroundStyle(.secondary) }
                            else { Text(en ? "Choose an active skill or turn off skill inclusion." : "Wähle einen aktiven Skill oder deaktiviere die Beigabe.").font(.callout).foregroundStyle(.orange) }
                        }
                        Toggle(en ? "Include my personal context" : "Meine persönlichen Angaben beifügen", isOn: $includeProfile).toggleStyle(.checkbox)
                        if includeProfile {
                            Text(skills.state.profile.isEmpty ? (en ? "No personal context saved yet. Add it in Skills." : "Noch keine persönlichen Angaben gespeichert. Ergänze sie unter Skills.") : skills.state.profile)
                                .font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                        }
                        Text(en ? "The selected instructions and additions are copied into both formats. Files stay local until you save or share them with an agent." : "Die gewählten Anweisungen und Ergänzungen werden in beide Formate kopiert. Dateien bleiben lokal, bis du sie einem Agenten übergibst.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(20).companionPanel().disabled(model.busy || generating)
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
                    NavigationExportOptions(scope: model.selected?.annotationScope ?? "", english: en, enabled: $includeNavigation, includePOIs: $includeNavigationPOIs, pack: $navigationPack).disabled(generating || model.busy)
                    videoOptions
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
                        if let documentDate {
                            Text((en ? "Export created: " : "Export erstellt: ") + documentDate.formatted(date: .abbreviated, time: .shortened)).font(.callout).foregroundStyle(.secondary)
                        }
                        Text(en ? "This is the saved export. Generate a new one to apply changed skills or personal context." : "Dies ist der gespeicherte Export. Erzeuge ihn neu, um geänderte Skills oder persönliche Angaben anzuwenden.").font(.caption).foregroundStyle(.secondary)
                        if document.videoMarkdown != nil {
                            Text(en ? "Two Markdown files will be saved or shared together. Attach BOTH files to your agent. JSON includes all selected video notes in one file." : "Zwei Markdown-Dateien werden gemeinsam gespeichert oder geteilt. BEIDE Dateien beim Agenten anhängen. JSON enthält alle ausgewählten Videonotizen in einer Datei.").font(.callout).foregroundStyle(theme.accent)
                        }
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
                                    sharing.saveToCloud(markdown: document.markdown, videoMarkdown: document.videoMarkdown, world: documentWorld, library: model.library.root, english: en)
                                }
                                Button(en ? "Send via AirDrop…" : "Per AirDrop senden …") {
                                    sharing.airDrop(markdown: document.markdown, videoMarkdown: document.videoMarkdown, world: documentWorld, library: model.library.root, english: en)
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
    }
    private var lifecycleEvents: some View {
        page
         .onAppear {
            try? skills.reload()
            maps.check(model)
            if generateRequest == nil { restoreLast(force: openLatest) }
            openLatest = false
            consumeGenerateRequest()
        }
        .onChange(of: generateRequest) { _, _ in consumeGenerateRequest() }
        .onChange(of: maps.checking) { _, _ in consumeGenerateRequest() }
        .onChange(of: model.busy) { _, busy in if !busy { consumeGenerateRequest() } }
    }
    private var exportSelectionEvents: some View {
        lifecycleEvents
        .onChange(of: selectedSkillID) { _, _ in clear() }
        .onChange(of: includeSkill) { _, _ in clear() }
        .onChange(of: includeProfile) { _, _ in clear() }
        .onChange(of: model.selection) { _, _ in clear() }
        .onChange(of: model.library.root) { _, _ in clear() }
    }
    private var videoOptions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(en ? "Include selected video knowledge" : "Ausgewähltes Videowissen einbeziehen", isOn: $includeVideos).toggleStyle(.checkbox)
            let selected = VideoKnowledgeExport.selected(videoTips, value: videoSelection)
            Text(en ? "\(selected.count) videos selected. Summaries, authored steps, sources and timestamps; no full transcripts." : "\(selected.count) Videos ausgewählt. Kurzfassungen, aufbereitete Schritte, Quellen und Sprungmarken; keine Volltranskripte.").font(.caption).foregroundStyle(.secondary)
            DisclosureGroup(en ? "Choose reviewed videos" : "Aufbereitete Videos auswählen") {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(videoTips.filter { tip in tip.isCurated || selected.contains(where: { v in v.videoID == tip.videoID }) }) { tip in
                            Toggle(tip.title.value(en), isOn: Binding(
                                get: { VideoKnowledgeExport.selectedIDs(videoSelection).contains(tip.videoID) },
                                set: { videoSelection = VideoKnowledgeExport.selecting(tip.videoID, in: videoSelection, enabled: $0) }
                            )).toggleStyle(.checkbox)
                        }
                    }
                }.frame(maxHeight: 220)
            }
            Toggle(en ? "Always save video knowledge as a second Markdown file" : "Videowissen immer als zweite Markdown-Datei speichern", isOn: $separateVideos).toggleStyle(.checkbox).disabled(!includeVideos)
            Text(en ? "Otherwise it is included in the main document. Above 100 KB combined size, video notes move to a second file automatically. Nothing is truncated." : "Sonst steht es im Hauptdokument. Ab 100 KB Gesamtgröße werden die Videonotizen automatisch in eine zweite Datei ausgelagert. Nichts wird gekürzt.").font(.caption).foregroundStyle(.secondary)
        }.disabled(generating || model.busy)
    }
    private func clear() { request = UUID(); document = nil; documentDate = nil; notice = ""; failure = ""; generating = false }
    private func consumeGenerateRequest() {
        guard generateRequest != nil, !maps.checking, !model.busy else { return }
        generateRequest = nil
        guard canGenerate else {
            failure = en ? "Check the savegame, selected skill and map tools above, then generate the export." : "Prüfe oben Spielstand, gewählten Skill und Kartenwerkzeuge und erzeuge dann den Export."
            return
        }
        generate()
    }
    private func restoreLast(force: Bool) {
        guard let record = CompanionActivity.shared.latest("export", root: model.library.root),
              force || record.saveID == model.selection else { return }
        do {
            document = try CompanionExportArchive.read(record, root: model.library.root)
            documentTitle = record.title
            documentWorld = model.saves.first { $0.id == record.saveID }?.world ?? "world"
            documentDate = record.date
        } catch { failure = en ? "The last local export is no longer available. Generate a new one." : "Der letzte lokale Export ist nicht mehr verfügbar. Erzeuge einen neuen." }
    }
    private func sizeDescription(_ document: AIContextDocument) -> String {
        let bytes = document.markdown.utf8.count + (document.videoMarkdown?.utf8.count ?? 0)
        let size = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
        let inventory = (document.payload["player"] as? [String: Any])?["inventory"] as? [[String: Any]] ?? []
        let storage = (document.payload["storage"] as? [String: Any])?["chests"] as? [[String: Any]] ?? []
        return en ? "Markdown: \(size) · \(inventory.count) occupied inventory slots · \(storage.count) chests · no record truncation"
                  : "Markdown: \(size) · \(inventory.count) belegte Inventarslots · \(storage.count) Kisten · keine gekürzten Datensätze"
    }
    private func generate() {
        guard canGenerate, let selected = model.selected else { return }
        let backend = model.library, root = backend.root, english = en
        let python = includeChests ? maps.python : nil
        let engine = includeChests ? Bundle.main.resourceURL?.appendingPathComponent("MapEngine") : nil
        let names = chests.names
        let skill = includeSkill ? chosenSkill : nil
        let profile = includeProfile ? skills.state.profile : nil
        let videos = includeVideos ? VideoKnowledgeExport.selected(videoTips, value: videoSelection) : []
        let splitVideos = separateVideos
        let navigation = includeNavigation ? navigationPack?.selectingPOIs(includeNavigationPOIs) : nil
        if includeNavigation && navigation == nil { failure = english ? "Load a route from Maps first." : "Zuerst eine Route aus Karten laden."; return }
        let supplement = AIContextSupplement.capture(save: selected, resources: Bundle.main.resourceURL)
        let owned = Set(UserDefaults.standard.stringArray(forKey: "conversation.ownedChests." + selected.annotationScope) ?? [])
        let places = CompanionPlace.named(UserDefaults.standard.dictionary(forKey: "atlasPOI." + selected.annotationScope) as? [String: String] ?? [:])
        clear(); generating = true
        let token = UUID(); request = token
        model.work(english ? "Generating AI context…" : "KI-Kontext wird erzeugt …") {
            let result = Result {
                let rawBase = try backend.makeAIContext(selected, python: python, engine: engine, names: names, ownedIDs: owned, places: places, english: english, supplement: supplement)
                let base = navigation?.attach(to: rawBase) ?? rawBase
                let value = AgentSkillExport.attach(skill, profile: profile, to: base, english: english).addingVideos(videos, english: english, separate: splitVideos)
                let file = try CompanionExportArchive.write(markdown: value.markdown, json: value.json, root: root, videoMarkdown: value.videoMarkdown)
                return (value, file, Date())
            }
            DispatchQueue.main.async {
                if case .success(let value) = result { CompanionActivity.shared.record(CompanionActivityRecord(date: value.2, saveID: selected.id, title: selected.title, path: value.1.path), kind: "export", root: root) }
                guard request == token, model.selection == selected.id, model.library.root == root else { return }
                generating = false
                switch result {
                case .success(let value):
                    document = value.0; documentTitle = selected.title; documentWorld = selected.world; documentDate = value.2
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
            let destination = target.deletingLastPathComponent().resolvingSymlinksInPath().appendingPathComponent(target.lastPathComponent).resolvingSymlinksInPath().standardizedFileURL.path
            let root = model.library.root.resolvingSymlinksInPath().standardizedFileURL.path
            guard destination != root, !destination.hasPrefix(root + "/") else {
                throw LibraryError(en ? "Save the document outside the savegame library." : "Speichere das Dokument außerhalb der Spielstand-Bibliothek.")
            }
            let files: [URL]
            if json {
                try value.json.write(to: target, options: .atomic)
                files = [target]
            } else {
                files = try MarkdownExportPackage.write(markdown: value.markdown, videoMarkdown: value.videoMarkdown, to: target, library: model.library.root)
            }
            notice = (en ? "Saved: " : "Gespeichert: ") + files.map(\.path).joined(separator: "\n")
            failure = ""
        } catch { failure = error.localizedDescription }
    }
}
