import SwiftUI
import Charts
import AppKit

struct SavedOreScan: Codable, Identifiable {
    var id = UUID().uuidString
    var date = Date()
    let saveID: String
    let beforeID: String?
    let sourceTitle: String
    let plan: OrePlan?
    let scan: OreScan
}

struct OreResearchView: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    let language: String
    let openMaps: () -> Void
    @Environment(\.companionTheme) private var theme
    @State private var draftID = UUID()
    @State private var draftBaseline = ""
    private var draftToken: String { DraftTransitions.fingerprint([DraftTransitions.fingerprint(plan), beforeID ?? "", DraftTransitions.fingerprint(counts), tested, String(accepted), editingID ?? "", method, trialEvidence?.id ?? "", chestID]) }
    private var dirty: Bool { !draftBaseline.isEmpty && draftBaseline != draftToken }
    private func markClean() { draftBaseline = draftToken; model.drafts.remove(draftID) }
    private func transition(_ action: () -> Void) { model.drafts.perform(action) }
    @State private var tab = "scan"
    @State private var catalog: OreReference?
    @State private var profile = "legacy"
    @State private var oreID = "gold"
    @State private var chartOreIDs: Set<String> = ["coal", "iron", "gold", "diamond"]
    @State private var showScanSetup = false
    @State private var mappingMode = "identity"
    @State private var offset = 0
    @State private var dimension = "o"
    @State private var bounds = ["-64","63","0","255","-64","63"]
    @State private var sampleSize = 256
    @State private var seed = 20260907
    @State private var histories: [SavedOreScan] = []
    @State private var selectedScan = ""
    @State private var failure = ""
    @State private var notice = ""
    @State private var nonAirOnly = false
    @State private var biomeID = "all"
    @State private var inspectedY = 16
    @State private var plan = OrePlan()
    @State private var beforeID: String?
    @State private var trials: [OreTrial] = []
    @State private var editingID: String?
    @State private var counts: [String:String] = [:]
    @State private var tested = ""
    @State private var accepted = false
    @State private var method = "manual-blocks"
    @State private var trialEvidence: SavedOreScan?
    @State private var chestID = ""
    @State private var journalFailed = false
    private var en: Bool { language == "en" }
    private var key: String { model.library.root.path+":"+(model.selection ?? "") }
    private var directory: URL? { model.selected.map { OreJournal.directory(root:model.library.root,world:$0.annotationScope) } }
    private var current: SavedOreScan? { histories.first{$0.id==selectedScan && $0.saveID==model.selection} }
    private var selectedOre: OreKind? { catalog?.entries.first{$0.id==oreID} }
    private var heightMapping: OreHeightMapping { .init(mode:mappingMode,offset:offset,legacy:profile=="legacy") }
    private var levels: [OreLevel] {
        guard let report=current?.scan else { return [] }
        return biomeID=="all" ? report.levels : report.biomes?.first{$0.id==biomeID}?.levels ?? []
    }
    private var biomeNames: [String:ItemName] {
        guard let url=Bundle.main.resourceURL?.appendingPathComponent("MapEngine/realmcraft_map/biomes.json"),let d=try? Data(contentsOf:url),let names=try? JSONDecoder().decode([String:ItemName].self,from:d) else {return [:]}
        return names
    }
    private func biomeName(_ id:String)->String { (en ? biomeNames[id]?.en : biomeNames[id]?.de) ?? (en ? "Unknown ID " : "Unbekannte ID ")+id }
    private func t(_ de: String,_ english: String)->String { en ? english : de }
    private func percent(_ x:Double)->String { (x*100).formatted(.number.precision(.fractionLength(0...4)).locale(Locale(identifier:language)))+" %" }
    private var canRead: Bool { model.selected != nil && !model.busy && !model.scanning && maps.ready }

    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: t("Erzhäufigkeit", "Ore frequency"), compact: true) {
                HStack(spacing: CompanionLayout.actionSpacing) {
                    if tab == "scan" || tab == "charts" {
                        Button(t("Bereich auf Karte wählen", "Select area on map"), action: openMaps)
                            .buttonStyle(CompanionButtonStyle())
                        Button(t("Blöcke zählen", "Count blocks")) { runScan(sample: false, compare: false) }
                            .buttonStyle(CompanionButtonStyle(prominent: true)).disabled(!canRead)
                    } else if tab == "trials" {
                        Button(t("Testlauf speichern", "Save trial"), action: { _ = saveTrial() })
                            .buttonStyle(CompanionButtonStyle(prominent: true))
                            .disabled(model.selected == nil || model.busy || journalFailed)
                    } else if tab == "results", let directory {
                        Button(t("Messdateien öffnen", "Open research files")) { NSWorkspace.shared.open(directory) }
                            .buttonStyle(CompanionButtonStyle())
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                SourceContextBar(saves: model.saves, selection: $model.selection, language: language, dimension: dimension, resultDate: current?.date, compact: true).disabled(model.busy)
                CompanionEqualSegments(title: t("Bereich", "Section"),
                    selection: Binding(get: { tab }, set: { value in transition { tab = value } }),
                    options: [("scan", t("Erkunden", "Explore")), ("charts", t("Verteilung", "Distribution")),
                              ("reference", t("Referenz", "Reference")), ("trials", t("Teststollen", "Mining trials"))])
                    .companionActionAligned()
                if !failure.isEmpty { CompanionNotice(message: failure, kind: .error) }
                if !notice.isEmpty { CompanionNotice(message: notice, kind: .information) }
                if dirty { Label(t("Ungespeicherter Testlauf", "Unsaved mining trial"), systemImage: "pencil.circle").font(.caption).foregroundStyle(.orange) }
                if model.busy { CompanionStatusLane { ProgressView().controlSize(.small); Text(model.status).font(.caption) } }
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 10)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if tab == "reference" { referencePanel }
                    else if tab == "trials" {
                        trialPanel
                        Divider()
                        CompanionDetails(t("Auswertung gespeicherter Testläufe", "Saved trial results")) { resultsPanel }
                    }
                    else if tab == "charts" { distributionPanel }
                    else { scanPanel }
                }.padding(CompanionLayout.pageInset).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .trackDraft(model.drafts, id: draftID, token: draftToken, dirty: { dirty }, title: t("Erz-Testlauf", "Mining trial"), save: saveTrial, discard: resetDraft)
        .onAppear { loadCatalog(); reload(); loadMapRegion(); maps.check(model); markClean() }
        .onChange(of: key) { _, _ in resetDraft(); reload(); loadMapRegion() }
        .onChange(of: profile) { _, _ in mappingMode = profile == "legacy" ? "identity" : "scaled"; loadCatalog() }
        .onChange(of: selectedScan) { _, _ in
            guard !selectedScan.isEmpty else { return }
            biomeID = "all"
            if let scan = current?.scan { inspectedY = min(scan.bounds[3], max(scan.bounds[2], inspectedY)) }
        }
    }

    private var toolsPanel: some View {
        Group {
            if !maps.ready {
                HStack {
                    Text(t("Für Chunk-Messungen werden die Kartenwerkzeuge benötigt.","Chunk measurements require the map tools."))
                    Button(t("Kartenwerkzeuge einrichten","Set up map tools")) { maps.install(model,english:en) }.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(model.busy || maps.checking)
                }.font(.callout)
            }
        }
    }
    private var scanPanel: some View {
        VStack(alignment:.leading,spacing:20) {
            OrePresetsView(model: model, english: en) { name in
                guard let save = model.selected else { return nil }
                let values = bounds.compactMap(Int.init)
                guard values.count == 6 else { return nil }
                return OrePreset(name: name, world: save.world, dimension: dimension, bounds: values,
                                 materials: chartOreIDs.sorted(), oreID: oreID, biomeID: biomeID, nonAirOnly: nonAirOnly, sampleSize: sampleSize, seed: seed)
            } apply: { preset in
                guard Set(preset.materials).isSubset(of: Set(OreMaterial.all.map(\.id))) else {
                    failure = t("Vorlage enthält unbekannte Materialien.", "Preset contains unknown materials."); return
                }
                dimension = preset.dimension; bounds = preset.bounds.map(String.init)
                chartOreIDs = Set(preset.materials); oreID = preset.oreID; biomeID = preset.biomeID
                nonAirOnly = preset.nonAirOnly; sampleSize = preset.sampleSize; seed = preset.seed
                selectedScan = ""; showScanSetup = true
                notice = t("Vorlage angewendet. Für diese Sicherung neu messen; gleicher Weltbezeichner belegt nicht denselben Spielverlauf.", "Preset applied. Scan this backup afresh; matching world IDs do not prove the same playthrough.")
            }
            if current == nil {
                Text(t("Wähle ein Gebiet und entdecke sein Inneres.", "Choose an area and explore beneath its surface.")).font(.title2.bold())
                Text(t("Auf der Karte Ressourcenanalyse anklicken und einen Bereich ziehen oder Grenzen unten eingeben. Für die interaktive Draufsicht empfehlen sich 64 × 64 Blöcke.", "Click Resource analysis on the map and drag an area, or enter bounds below. A 64 × 64 block area works well for the interactive layer view.")).foregroundStyle(.secondary)
            }
            DisclosureGroup(t("Messbereich & neue Stichprobe", "Measurement area & new sample"), isExpanded: Binding(get: { showScanSetup || current == nil }, set: { showScanSetup = $0 })) {
            toolsPanel
            CompanionPopup(title: t("Dimension","Dimension"), selection: $dimension,
                options: [("o", t("Oberwelt","Overworld")), ("n", "Nether")]).companionField(t("Dimension","Dimension")).padding(.vertical, 12)
            GroupBox(t("Begrenzten Bereich messen · inklusive Grenzen","Measure a bounded region · inclusive bounds")) {
                VStack(alignment:.leading,spacing:12) {
                    VStack(alignment: .leading, spacing: 16) {
                      HStack(spacing: 16) {
                        ForEach(0..<3,id:\.self) { axis in
                            VStack(alignment:.leading) {
                                Text(["X","Y","Z"][axis]).font(.caption.bold())
                                HStack { TextField("min",text:$bounds[axis*2]);Text("…");TextField("max",text:$bounds[axis*2+1]) }
                            }
                        }
                      }
                        Button(t("Bereich messen","Measure area")) { runScan(sample:false,compare:false) }.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(!canRead)
                    }.textFieldStyle(.roundedBorder)
                    Text(t("Ein Chunk umfasst 16 × 16 Spalten und Y 0–255. Negative X/Z werden abgerundet: X −1 gehört zum Chunk-Ursprung −16.","A chunk spans 16 × 16 columns and Y 0–255. Negative X/Z use floor division: X −1 belongs to chunk origin −16.")).font(.caption).foregroundStyle(.secondary)
                }.padding(8)
            }
            CompanionDetails(t("Zufällige räumliche Stichprobe","Random spatial sample")) {
                VStack(alignment:.leading,spacing:12) {
                    HStack {
                        number(t("Chunks (1–512)","Chunks (1–512)"),$sampleSize)
                        number("Seed",$seed)
                        Button(t("Stichprobe messen","Measure sample")) { runScan(sample:true,compare:false) }.buttonStyle(CompanionButtonStyle()).disabled(!canRead || !(1...512).contains(sampleSize))
                    }
                    Text(t("Gespeicherte Chunks werden über 256 × 256 große räumliche Sektoren verteilt zufällig gezogen, ohne Wiederholung. Seed und Dateiauswahl werden gespeichert. Die Messung ist räumlich geschichtet, kein flächengewichteter Weltdurchschnitt. Biome werden anschließend anhand ihrer gespeicherten 4×4-Spaltenzellen getrennt ausgewertet; keine Höhenbiome.","Saved chunks are randomly selected across 256 × 256 spatial sectors without replacement. Seed and selection are saved. This spatially stratified sample is not an area-weighted world average. Biomes are subsequently separated using their saved 4×4 column cells; these are not vertical biomes.")).font(.caption).foregroundStyle(.secondary)
                }.padding(8)
            }
            }
            if !histories.isEmpty {
                Picker(t("Gespeicherte Messung","Saved measurement"),selection:$selectedScan) {
                    ForEach(histories.filter{$0.saveID==model.selection}) { entry in Text(displayDate(entry.date,language:language)+" · \(entry.scan.scanned) Chunks · "+(entry.scan.sampling == nil ? t("Bereich","Region") : t("Zufall","Random"))).tag(entry.id) }
                }
            }
            if let current { censusResult(current) }
            else { Text(t("Noch keine Messung für diese Sicherung. Wähle einen Bereich oder eine Zufallsstichprobe.","No measurement for this backup yet. Choose a region or random sample.")).foregroundStyle(.secondary) }
        }
    }
    private func censusResult(_ value:SavedOreScan)->some View {
        let report=value.scan
        return VStack(alignment:.leading,spacing:16) {
            HStack {
                Text(t("Gemessene Verteilung","Measured distribution")).font(.title2.bold())
                Spacer()
                Button(t("JSON exportieren","Export JSON")) { exportScan(value) }.buttonStyle(CompanionButtonStyle())
            }
            Text("\(report.scanned) / \(report.expected) "+t("Chunks · ","chunks · ")+report.volume.formatted()+t(" untersuchte Blockpositionen"," examined block positions"))
            if !report.complete { Text(t("Unvollständige Abdeckung: \(report.missing.count) fehlen, \(report.errors.count) Lesefehler.","Incomplete coverage: \(report.missing.count) missing, \(report.errors.count) read errors.")).foregroundStyle(.orange) }
            if let sampling=report.sampling {
                Text("Seed \(sampling.seed) · \(sampling.eligible) "+t("gespeicherte Kandidaten · ","saved candidates · ")+"\(sampling.sectors) "+t("Sektoren","sectors")).font(.caption)
            }
            OreWorkspaceView(scan: report, y: $inspectedY, materials: $chartOreIDs, english: en, measuredAt:value.date) { x,y,z in
                guard model.drafts.authorize() else { return }
                resetDraft(); plan.x=x; plan.y=y; plan.z=z; plan.dimension=report.dimension
                tab="trials"
                notice=t("Fundstelle übernommen. Für unverzerrte Testläufe eine vorab gewählte, unabhängige Route verwenden.", "Deposit location applied. For unbiased trials use an independently preselected route.")
            } inspectArea: { area in
                dimension=report.dimension
                bounds=[String(area.x0),String(area.x1),String(report.bounds[2]),String(report.bounds[3]),String(area.z0),String(area.z1)]
                showScanSetup=true
                notice=t("Teilfläche übernommen – mit Blöcke zählen untersuchen.", "Area applied — use Count blocks to inspect.")
            } showOnMap: { x, y, z, blockID in
                guard let save = model.selected, save.id == value.saveID else { return }
                maps.focusTarget = MapFocusTarget(saveID: save.id, world: save.world, dimension: report.dimension, x: x, y: y, z: z, blockID: blockID)
                openMaps()
            }
            .id(value.id)
            HStack {
                Button(t("Verteilung & Top 3 öffnen", "Open distribution & Top 3")) { tab="charts" }.buttonStyle(CompanionButtonStyle(prominent:true))
                Spacer()
                Text(t("Blockzählung · aktueller Sicherungsstand", "Block census · saved snapshot")).font(.caption).foregroundStyle(.secondary)
            }
            DisclosureGroup(t("Lesefehler und Grenzen","Read errors and limitations")) {
                Text((report.errors+report.metadataErrors).joined(separator:"\n")).textSelection(.enabled)
                Text(t("Biom-IDs und Blocknamen stammen aus dem beobachteten RealmCraft-Katalog. Ein Name allein belegt keine Generierung. Erzadern erzeugen räumlich abhängige Funde; ein Peak oder Nullfund in einer Stichprobe belegt keine universelle Wahrscheinlichkeit. Biome, ältere Spielversionen und Spieleränderungen können die Verteilung beeinflussen.","Biome IDs and block names use the observed RealmCraft catalog. A name alone does not prove generation. Ore veins create spatially dependent observations; a peak or zero find in a sample does not establish a universal probability. Biomes, older game versions and player edits can affect distributions."))
            }.font(.caption)
        }
    }
    private var distributionPanel: some View {
        VStack(alignment:.leading,spacing:20) {
            if let current {
                Text(displayDate(current.date,language:language) + " · " + current.sourceTitle).font(.caption).foregroundStyle(.secondary)
                CompanionPopup(title: t("Biom", "Biome"), selection: $biomeID,
                    options: [("all", t("Gesamte Messung", "Entire census"))] + (current.scan.biomes ?? []).map { ($0.id, biomeName($0.id)) }).companionField(t("Biom", "Biome"))
                Toggle(t("Anteil an Nicht-Luft-Blöcken", "Fraction of non-air blocks"),isOn:$nonAirOnly)
                OreDistributionView(levels:levels,materials:$chartOreIDs,y:$inspectedY,nonAirOnly:nonAirOnly,english:en)
                OreTopThreeTable(levels:levels,ores:catalog?.entries ?? [],nonAirOnly:nonAirOnly,english:en)
            } else {
                ContentUnavailableView(t("Zuerst ein Gebiet messen", "Measure an area first"),systemImage:"chart.xyaxis.line",description:Text(t("Unter Erkunden einen Bereich oder eine Zufallsstichprobe einlesen.", "Under Explore, read an area or a random sample.")))
                Button(t("Zur Messung", "Go to census")) {tab="scan"}
            }
        }
    }
    private var orePicker:some View {
        CompanionPopup(title: t("Erz","Ore"), selection: $oreID,
            options: (catalog?.entries ?? []).map { ($0.id, $0.name(en)) }).companionField(t("Erz","Ore"))
    }
    private var referencePanel:some View {
        VStack(alignment:.leading,spacing:18) {
            Label(t("Minecraft-Vorkommen und Höhenvergleich","Minecraft occurrence and height comparison"), systemImage: "books.vertical").font(.title2.bold())
            Picker(t("Referenzversion","Reference version"),selection:$profile) { Text("Java 1.17.1 · Y 0–255").tag("legacy");Text("Java 1.21.1 · Y −64–319").tag("modern") }.pickerStyle(.segmented).companionField(t("Referenzversion","Reference version"))
            Text(t("Versionsgebundene Java-Generierungsdaten, geprüft am 07.09.2026. Keine Behauptung zur neuesten Minecraft-Version oder zum RealmCraft-Generator. Die Wiki-Artikel enthalten teils ältere bzw. widersprüchliche Werte; die verlinkten Konfigurationsdaten bestimmen die Tabelle.","Version-pinned Java generation data, reviewed 7 September 2026. No claim about the latest Minecraft version or the RealmCraft generator. Wiki pages contain some older or conflicting values; linked configuration data controls the table.")).font(.callout)
            orePicker
            CompanionPopup(title: t("Höhenanpassung · Hypothese","Height mapping · hypothesis"), selection: $mappingMode,
                options: [("identity", t("Gleiche Y-Werte","Same Y values")), ("scaled", t("Gesamte Höhenbereiche abbilden","Map full height ranges")), ("offset", t("Eigener Versatz","Custom offset"))]).companionField(t("Höhenanpassung · Hypothese","Height mapping · hypothesis"))
            if mappingMode=="offset" { number(t("Versatz zu Minecraft-Y","Offset added to Minecraft Y"),$offset) }
            Text(mappingExplanation).font(.callout).foregroundStyle(.orange)
            if let ore=selectedOre {
                Text(en ? ore.notesEN : ore.notesDE).fixedSize(horizontal:false,vertical:true)
                ForEach(ore.batches) { batch in
                    VStack(alignment:.leading,spacing:7) {
                        Text(batch.conditionName(en)).font(.headline)
                        Text("Minecraft Y \(batch.low)…\(batch.high) · "+(batch.shape=="uniform" ? t("gleichmäßig","uniform") : t("Dreiecksverteilung","triangular")))
                        Text(batch.attempts.formatted(.number.precision(.fractionLength(0...3)))+t(" Versuche/Chunk · Größenparameter "," attempts/chunk · size parameter ")+"\(batch.size) · "+t("Verwerfen bei Luftkontakt: ","Discard when air-exposed: ")+percent(batch.airSkip))
                        if let band=heightMapping.band(batch,dimension:ore.dimension) {
                            Text(t("RealmCraft-Vergleich: Y ","RealmCraft comparison: Y ")+"\(band.lowerBound)…\(band.upperBound) · "+t("unbestätigte Hypothese","unconfirmed hypothesis")).foregroundStyle(theme.accent)
                        } else { Text(t("Außerhalb des RealmCraft-Höhenbereichs mit dieser Anpassung.","Outside the RealmCraft height range with this mapping.")).foregroundStyle(.secondary) }
                        HStack { ForEach(batch.sources,id:\.self) { url in Link(url.path.contains("placed_feature") ? t("Platzierungsregel","Placement rule") : t("Generierungsdaten","Generation data"),destination:url) } }.font(.caption)
                    }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(theme.surface).clipShape(RoundedRectangle(cornerRadius:8))
                }
                Text(t("Versuche und Größenparameter ergeben keine garantierte Blockzahl oder Fundwahrscheinlichkeit. Adern können um ihren Ausgangspunkt hinausragen. Bereiche werden erst an Minecrafts Weltgrenzen und dann am RealmCraft-Anzeigebereich beschnitten.","Attempts and size parameters are not guaranteed block counts or encounter probabilities. Veins can extend around their origin. Ranges are clipped to Minecraft world bounds and then the RealmCraft display range.")).font(.caption)
                Link("Minecraft Wiki · "+ore.name(en),destination:ore.wiki)
            }
            DisclosureGroup(t("Bedrock, Quellen und Einordnung","Bedrock, sources and interpretation")) {
                Text(t("Bedrock ist keine Kopie dieser Java-Tabelle. Die Quellen nennen unter anderem abweichende Zusatzchargen bei Kohle in Bergen und bei antikem Schrott. Diese Zahlen sind hier nicht als versionsgeprüfter Bedrock-Datensatz hinterlegt. Für RealmCraft-VR konnte die Webrecherche keine belastbare vollständige Generierungsformel nachweisen. Messungen sind daher maßgeblich. Gleiche Namen und Höhen sind keine Gleichheit der Zufallsregeln.","Bedrock is not a copy of this Java table. Sources describe differing extra batches for mountain coal and ancient debris, among others. These are not included as a version-verified Bedrock dataset. Web research did not establish a reliable complete generation formula for RealmCraft VR. Measurements therefore take precedence. Matching names and heights do not establish identical random rules."))
                ForEach(catalog?.sources ?? [],id:\.self) { url in Link(url.host!+" · "+url.lastPathComponent,destination:url).font(.caption) }
            }
        }
    }
    private var mappingExplanation:String {
        if mappingMode=="offset" {return t("Hypothese: Y_RC = Y_MC + \(offset). Keine Änderung an Spielständen.","Hypothesis: Y_RC = Y_MC + \(offset). No savegame changes.")}
        if mappingMode=="identity" || profile=="legacy" {return t("Y_RC = Y_MC. Bei Java 1.17.1 passen die numerischen Höhenbereiche. Die Erzverteilung muss trotzdem mit RealmCraft-Chunks geprüft werden.","Y_RC = Y_MC. Java 1.17.1 has matching numerical height ranges. Ore distribution still requires verification against RealmCraft chunks.")}
        return t("Nur rechnerische Hypothese: Oberwelt Y_RC = (Y_MC + 64) × 255 / 383, auf ganze Blöcke gerundet. Nether bleibt Y_RC = Y_MC. Diese Skalierung ist keine belegte RealmCraft-Generierungsregel.","Arithmetic hypothesis only: Overworld Y_RC = (Y_MC + 64) × 255 / 383, rounded to whole blocks. Nether stays Y_RC = Y_MC. This scaling is not an established RealmCraft generation rule.")
    }

    private var trialPanel:some View {
        VStack(alignment:.leading,spacing:16) {
            Text(t("Geführter Probestollen","Guided mining trial")).font(.title2.bold())
            Text(t("Fester Stollenquerschnitt · Erzblöcke zählen · getrennte Ausbeutetruhe","Fixed tunnel cross-section · count ore blocks · separate yield chest")).foregroundStyle(.secondary)
            GroupBox(t("1 · Route & Versuchsaufbau", "1 · Route & setup")) {
            VStack(alignment:.leading,spacing:14) {
            HStack {
                Picker(t("Gespeicherter Lauf","Saved trial"),selection:Binding<String>(get:{editingID ?? ""},set:{id in transition { if let row=trials.first(where:{$0.id==id}) { edit(row) } else { resetDraft() } }})) {
                    Text(t("Neuer Lauf","New trial")).tag("")
                    ForEach(trials) {row in Text(row.plan.code+" · Y \(row.plan.y) · "+(row.accepted ? t("ausgewertet","accepted") : t("Entwurf","draft"))).tag(row.id)}
                }
                Button(t("Neuer Lauf","New trial")) { transition { resetDraft() } }.buttonStyle(CompanionButtonStyle())
            }
            TextField(t("Test-ID für das Schild","Trial ID for the sign"),text:$plan.code).textFieldStyle(.roundedBorder)
            HStack {
                Picker(t("Dimension","Dimension"),selection:$plan.dimension) {Text(t("Oberwelt","Overworld")).tag("o");Text("Nether").tag("n")}
                TextField(t("Biom / unbekannt","Biome / unknown"),text:$plan.biome)
                TextField(t("RealmCraft-Spielversion","RealmCraft game version"),text:$plan.gameVersion)
            }.textFieldStyle(.roundedBorder)
            HStack { number("X",$plan.x);number("Y",$plan.y);number("Z",$plan.z);Picker(t("Richtung","Direction"),selection:$plan.direction) {ForEach(["+x","-x","+z","-z"],id:\.self){Text($0.uppercased()).tag($0)}} }
            HStack {number(t("Länge","Length"),$plan.length);number(t("Breite","Width"),$plan.width);number(t("Höhe","Height"),$plan.height)}
            if (try? plan.validate()) != nil {
                HStack {
                    Label("\(plan.length) × \(plan.width) × \(plan.height)",systemImage:"cube.transparent")
                    Spacer()
                    Text(t("\(plan.volume) Blockpositionen · Y \(plan.y)…\(plan.y+plan.height-1)", "\(plan.volume) block positions · Y \(plan.y)…\(plan.y+plan.height-1)")).monospacedDigit()
                }.font(.headline).padding(12).companionPanel()
                CompanionDetails(t("Ablauf für diesen Testlauf","Procedure for this trial")) { Text(plan.instructions(en)).textSelection(.enabled).fixedSize(horizontal:false,vertical:true) }
                Button(t("Ablauf kopieren","Copy procedure")) { NSPasteboard.general.clearContents();NSPasteboard.general.setString(plan.instructions(en),forType:.string) }.buttonStyle(CompanionButtonStyle())
            } else {Text(t("Bitte gültige Stollenmaße eingeben.","Enter valid tunnel dimensions.")).foregroundStyle(.orange)}
            }
            }
            CompanionDetails(t("2 · Vorher / Nachher", "2 · Before / after")) {
            VStack(alignment:.leading,spacing:14) {
            toolsPanel
            CompanionPopup(title: t("Vorher-Sicherung derselben Welt","Before backup of the same world"), selection: $beforeID,
                options: [(nil, t("Vorher wählen","Choose before"))] + model.saves.filter { $0.world==model.selected?.world && $0.id != model.selection }.map { (Optional($0.id), $0.title + " · " + displayDate($0.date, language: language)) }).companionField(t("Vorher-Sicherung derselben Welt","Before backup of the same world"))
            Text(t("Die oben gewählte Sicherung ist NACHHER. Der Vergleich zählt ausschließlich Nicht-Luft → Luft im festgelegten Stollenvolumen.","The backup selected at the top is AFTER. Comparison counts only non-air → air inside the fixed tunnel volume.")).font(.caption)
            Button(t("Stollen vorher/nachher prüfen","Check tunnel before/after")) {runScan(sample:false,compare:true)}.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(!canRead || beforeID==nil || (try? plan.validate())==nil)
            if let evidence=trialEvidence,let p=evidence.scan.probe {
                Text(t("Verglichen: \(p.compared)/\(p.volume) · entfernt: \(p.removed) · vorher Luft: \(p.beforeAir) · verblieben: \(p.remaining) · andere Änderungen: \(p.otherChanges)","Compared: \(p.compared)/\(p.volume) · removed: \(p.removed) · previously air: \(p.beforeAir) · remaining: \(p.remaining) · other changes: \(p.otherChanges)"))
                Text(p.complete ? t("Volumen vollständig ausgehoben. Vor der Übernahme prüfen, ob die Route vorab gewählt wurde.","Volume fully excavated. Confirm the route was chosen in advance before accepting.") : t("Unvollständiger oder veränderter Testlauf: nur als Entwurf dokumentieren; keine automatische Wahrscheinlichkeit.","Incomplete or modified trial: document as draft; no automatic probability.")).foregroundStyle(p.complete ? theme.accent : .orange)
                Button(t("Gezählte Erzblöcke übernehmen","Use counted ore blocks")) {
                    tested=String(p.removed);counts=p.counts.mapValues(String.init);method="snapshot-diff";accepted=false
                }.buttonStyle(CompanionButtonStyle()).disabled(!p.complete || evidence.plan?.bounds != plan.bounds || evidence.plan?.dimension != plan.dimension || evidence.saveID != model.selection || evidence.beforeID != beforeID)
                chestPanel(evidence.scan)
            }
            }
            }
            CompanionDetails(t("3 · Funde & Messjournal", "3 · Finds & research journal")) {
            VStack(alignment:.leading,spacing:14) {
            numberText(t("Tatsächlich abgebaute Nicht-Luft-Blöcke im Testvolumen","Actually excavated non-air blocks inside test volume"),$tested)
            Text(t("Leer = nicht erfasst; 0 = geprüft, kein Fund. Nur Erzblöcke im Stollen zählen, keine Drops und keine außerhalb verfolgten Adern.","Blank = unrecorded; 0 = checked, no find. Count only ore blocks inside the tunnel, not drops or veins followed outside it.")).font(.caption)
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible())],alignment:.leading,spacing:10) {
                ForEach(catalog?.entries ?? []) {ore in numberText(ore.name(en),Binding(get:{counts[ore.id] ?? ""},set:{counts[ore.id]=$0;method="manual-blocks"}))}
            }
            TextField(t("Notizen: Werkzeug, Verzauberungen, Hindernisse, Quellen","Notes: tool, enchantments, obstacles, sources"),text:$plan.note,axis:.vertical).lineLimit(3...8).textFieldStyle(.roundedBorder)
            Toggle(t("Abgeschlossen: vorab gewählte Route, keine Zusatzfunde; in Höhenvergleich aufnehmen","Completed: preselected route, no extra finds; include in height comparison"),isOn:$accepted)
            Text(t("Überlappende ausgewertete Testvolumen werden abgewiesen. Änderungen werden als neue Version gespeichert; frühere Einträge bleiben erhalten.","Overlapping accepted test volumes are rejected. Edits create a new revision; prior records are retained.")).font(.caption).foregroundStyle(.secondary)
            Button(t("Testlauf lokal speichern","Save trial locally"),action:{ _ = saveTrial() }).buttonStyle(CompanionButtonStyle(prominent: true)).disabled(model.selected==nil || model.busy || journalFailed)
            }
            }
        }.frame(maxWidth: CompanionLayout.readingWidth, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
    }
    private func chestPanel(_ scan:OreScan)->some View {
        VStack(alignment:.leading,spacing:8) {
            Text(t("Truhe und Schild als Zusatzbeleg","Chest and sign as supporting evidence")).font(.headline)
            Picker(t("Testtruhe auswählen","Select trial chest"),selection:$chestID) {
                Text(t("Keine Zuordnung","No association")).tag("")
                ForEach(scan.chests.filter { chest in chest.readable && scan.beforeChests.contains(where:{$0.id==chest.id && $0.readable}) }) { chest in
                    Text((chest.signName ?? chest.nearbySign ?? chest.id)+" · "+chest.coordinates).tag(chest.id)
                }
            }
            if let after=scan.chests.first(where:{$0.id==chestID}),let before=scan.beforeChests.first(where:{$0.id==chestID}),let delta=try? OreJournal.delta(before:before,after:after) {
                Text(t("Schild: ","Sign: ")+(after.signName ?? after.nearbySign ?? t("nicht lesbar/zugeordnet","unreadable/unassigned")))
                Text(delta.keys.sorted().map {"ID \($0): \(delta[$0]! >= 0 ? "+" : "")\(delta[$0]!)"}.joined(separator:" · ")).font(.caption).textSelection(.enabled)
                Text(t("Dies sind Item-Differenzen, keine Erzblockzahlen. Negative Werte zeigen Entnahmen. Beschilderung und Nähe allein bestätigen keine Testzugehörigkeit; die Zuordnung wird von dir festgelegt.","These are item deltas, not ore block counts. Negative values indicate withdrawals. Sign text and proximity alone do not prove trial ownership; you choose the association.")).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    private var resultsPanel:some View {
        VStack(alignment:.leading,spacing:18) {
            Text(t("Empirische Fundraten aus Testläufen","Empirical rates from mining trials")).font(.title2.bold())
            orePicker
            Text(t("Schätzwert = Summe der Erzblöcke / Summe der tatsächlich abgebauten Nicht-Luft-Blöcke. Nur abgeschlossene, überlappungsfreie Testläufe derselben Welt, Dimension, Spielversion, Biomangabe und Höhenzone werden zusammengefasst. Zwei Blöcke hohe Stollen ergeben eine Höhenzone, keine Messung einer einzelnen Ebene.","Estimate = sum of ore blocks / sum of actually excavated non-air blocks. Only completed non-overlapping trials sharing world, dimension, game version, biome label and height band are pooled. Two-block-high tunnels describe a height band, not one individual layer."))
            let rows=OreTrialSummary.make(trials,ore:oreID)
            if rows.isEmpty {Text(t("Noch keine abgeschlossenen Testläufe für dieses Erz. Die direkten Chunk-Ergebnisse findest du unter Chunk-Messung.","No completed trials for this ore yet. Direct chunk results are available under Chunk census.")).foregroundStyle(.secondary)}
            ForEach(rows) {row in
                VStack(alignment:.leading,spacing:8) {
                    Text("Y \(row.plan.y)…\(row.plan.y+row.plan.height-1) · \(row.plan.biome) · \(row.plan.gameVersion) · \(row.plan.dimension=="o" ? t("Oberwelt","Overworld") : "Nether")").font(.headline)
                    Text(percent(row.probability)+" · \(row.hits) / \(row.tested) · \(row.runs) "+t("Testläufe","trials")).monospacedDigit()
                    Text(t("Fundraten einzelner Läufe: ","Individual trial rates: ")+percent(row.minimum)+"…"+percent(row.maximum)).font(.caption)
                }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(theme.surface).clipShape(RoundedRectangle(cornerRadius:8))
            }
            Text(t("Das ist eine empirische Wahrscheinlichkeit für die untersuchten Stollen, keine sichere Vorhersage für den nächsten Block. Adern erzeugen Abhängigkeiten; benachbarte Blöcke sind keine unabhängigen Versuche. Die Spannweite ist kein Konfidenzintervall. Nullfunde beweisen keine Unmöglichkeit. Mehrere vorab gewählte, getrennte Orte pro Höhe reduzieren Zufallsschwankungen und Auswahlverzerrung.","This is an empirical probability for the surveyed tunnels, not a reliable prediction for the next block. Veins create dependence; adjacent blocks are not independent trials. The displayed range is not a confidence interval. Zero finds do not prove impossibility. Multiple preselected separated locations per height reduce random variation and selection bias.")).font(.callout).foregroundStyle(.secondary)
            if let directory { Button(t("Lokale Messdateien im Finder","Show local research files")) {NSWorkspace.shared.open(directory) }.buttonStyle(CompanionButtonStyle()) }
        }
    }
    private func number(_ title:String,_ binding:Binding<Int>)->some View {
        VStack(alignment:.leading,spacing:4) {Text(title).font(.caption);TextField(title,value:binding,format:.number.grouping(.never)).textFieldStyle(.roundedBorder)}
    }
    private func numberText(_ title:String,_ binding:Binding<String>)->some View {
        VStack(alignment:.leading,spacing:4) {Text(title).font(.caption);TextField(title,text:binding).textFieldStyle(.roundedBorder)}
    }
    private func loadCatalog() {
        do {catalog=try OreReference.load(Bundle.main.url(forResource:profile=="legacy" ? "OreReferenceLegacy" : "OreReference",withExtension:"json"))}
        catch {failure=error.localizedDescription}
    }
    private func loadMapRegion() {
        guard let saveID=model.selection,
              let value=UserDefaults.standard.dictionary(forKey:"ore.region."+saveID),
              let dim=value["dimension"] as? String, ["o","n"].contains(dim),
              let x0=value["x0"] as? Int, let x1=value["x1"] as? Int,
              let z0=value["z0"] as? Int, let z1=value["z1"] as? Int,
              x0<=x1, z0<=z1 else { return }
        dimension=dim; bounds=[String(x0),String(x1),"0","255",String(z0),String(z1)]
        UserDefaults.standard.removeObject(forKey:"ore.region."+saveID)
        showScanSetup = current?.scan.bounds != bounds.compactMap(Int.init)
        notice=t("Kartenauswahl übernommen: X ","Map selection applied: X ")+"\(x0)…\(x1), Z \(z0)…\(z1)."
    }
    private func reload() {
        histories=[];trials=[];selectedScan="";failure="";notice="";journalFailed=false
        guard let directory else {return}
        do {
            trials=try OreJournal.load(directory)
            if FileManager.default.fileExists(atPath:directory.path) {
                let paths=try FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil).filter{$0.lastPathComponent.hasPrefix("scan-") && $0.pathExtension=="json"}
                histories=try paths.map{try JSONDecoder().decode(SavedOreScan.self,from:Data(contentsOf:$0))}.sorted{$0.date>$1.date}
                for entry in histories { try entry.scan.validateDisplay() }
                selectedScan=histories.first{$0.saveID==model.selection}?.id ?? ""
                if let scan=current?.scan { dimension=scan.dimension; bounds=scan.bounds.map(String.init) }
            }
        } catch {failure=t("Messjournal konnte nicht vollständig geladen werden: ","Research journal could not be fully loaded: ")+error.localizedDescription;journalFailed=true}
    }
    private func runScan(sample:Bool,compare:Bool) {
        guard canRead,let save=model.selected,let directory,let engine=Bundle.main.resourceURL?.appendingPathComponent("MapEngine") else {return}
        do {
            let prior=compare ? model.saves.first{$0.id==beforeID && $0.world==save.world && $0.id != save.id} : nil
            let selectedBounds:[Int]
            if compare {try plan.validate();guard prior != nil else {throw OreError("Select a before backup / Vorher-Sicherung wählen")};selectedBounds=plan.bounds}
            else {selectedBounds=try bounds.map{guard let x=Int($0) else {throw OreError("Integer bounds required / Ganzzahlige Grenzen erforderlich")};return x}}
            if !sample {
                guard selectedBounds.count == 6, selectedBounds[0] <= selectedBounds[1], selectedBounds[4] <= selectedBounds[5],
                      selectedBounds[2] >= 0, selectedBounds[2] <= selectedBounds[3], selectedBounds[3] <= 255 else { throw OreError(t("Bereich prüfen: min ≤ max, Y 0–255.", "Check bounds: min ≤ max, Y 0–255.")) }
            }
            let savedPlan=compare ? plan : nil, capturedKey=key, backend=model.library, interpreter=maps.python
            let dim=compare ? plan.dimension : dimension, limit=sampleSize, capturedSeed=seed, english=en
            failure="";notice=""
            if compare {trialEvidence=nil;accepted=false}
            model.work(t("Erzblöcke werden gelesen …","Reading ore blocks…")) {
                do {
                    _=try backend.verify(save);if let prior {_=try backend.verify(prior)}
                    var args=["-I","-B","-c","import sys; sys.path.insert(0, sys.argv.pop(1)); from realmcraft_map.ores import main; raise SystemExit(main())",engine.path,backend.worldFolder(save).path,"--dimension",dim]
                    if sample {args += ["--sample",String(limit),"--seed",String(capturedSeed)]}
                    else {args += ["--bounds"]+selectedBounds.map(String.init); if !compare {args += ["--spatial"]}}
                    if let prior {args += ["--before",backend.worldFolder(prior).path]}
                    let result=try backend.run(interpreter,args,timeout:1800)
                    guard result.code==0,let data=result.output.data(using:.utf8) else {throw OreError(String(result.output.suffix(3000)))}
                    let scan=try JSONDecoder().decode(OreScan.self,from:data)
                    try scan.validateDisplay()
                    _=try backend.verify(save);if let prior {_=try backend.verify(prior)}
                    let saved=SavedOreScan(saveID:save.id,beforeID:prior?.id,sourceTitle:save.title,plan:savedPlan,scan:scan)
                    try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
                    let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
                    try encoder.encode(saved).write(to:directory.appendingPathComponent("scan-"+saved.id+".json"),options:.atomic)
                    DispatchQueue.main.async {
                        guard key==capturedKey else {return}
                        histories.insert(saved,at:0);selectedScan=saved.id;biomeID="all"
                        if !compare { showScanSetup=false }
                        if compare {trialEvidence=saved;chestID=""}
                        notice=english ? "Measurement saved locally. Backup checksums unchanged." : "Messung lokal gespeichert. Prüfsummen der Sicherung unverändert."
                    }
                    return english ? "Ore measurement ready." : "Erzmessung bereit."
                } catch {
                    let message=error.localizedDescription
                    DispatchQueue.main.async {if key==capturedKey {failure=message}}
                    throw error
                }
            }
        } catch {failure=error.localizedDescription}
    }
    private func resetDraft() {
        plan=OrePlan();beforeID=nil;counts=[:];tested="";accepted=false;editingID=nil;method="manual-blocks";trialEvidence=nil;chestID="";markClean()
    }
    private func edit(_ row:OreTrial) {
        editingID=row.id;plan=row.plan;beforeID=row.beforeSaveID;counts=row.counts.mapValues(String.init);tested=row.tested.map(String.init) ?? "";accepted=row.accepted;method=row.method;chestID=row.chestID ?? ""
        trialEvidence=histories.first{"scan-"+$0.id+".json"==row.evidenceFile};markClean()
    }
    private func saveTrial() -> Bool {
        guard !journalFailed, !model.busy, let save=model.selected,let directory else { return false }
        do {
            var parsed:[String:Int]=[:]
            for (id,text) in counts where !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty {
                guard let n=Int(text) else{throw OreError(t("Ungültige Erzmenge","Invalid ore count"))};parsed[id]=n
            }
            let denominator=Int(tested)
            if !tested.isEmpty && denominator==nil {throw OreError(t("Ungültige Bezugsmenge","Invalid denominator"))}
            if accepted && parsed.isEmpty {throw OreError(t("Zuerst Erzblöcke erfassen, auch Nullfunde.","Record ore block counts, including zero finds, first."))}
            if method=="snapshot-diff" {
                guard let e=trialEvidence,e.plan?.bounds==plan.bounds,e.plan?.dimension==plan.dimension,e.saveID==save.id,e.beforeID==beforeID,e.scan.probe?.complete==true,e.scan.probe?.removed==denominator,e.scan.probe?.counts==parsed else {throw OreError(t("Testparameter oder Messwerte geändert: erneut vergleichen oder manuell erfassen.","Trial parameters or counts changed: compare again or enter manually."))}
            }
            var row=OreTrial(supersedes:editingID,world:save.annotationScope,saveID:save.id,beforeSaveID:beforeID,plan:plan,tested:denominator,counts:parsed,method:method,accepted:accepted,evidenceFile:trialEvidence.map{"scan-"+$0.id+".json"},chestID:chestID.isEmpty ? nil : chestID)
            if let e=trialEvidence,let a=e.scan.chests.first(where:{$0.id==chestID}),let b=e.scan.beforeChests.first(where:{$0.id==chestID}) {row.chestDelta=try OreJournal.delta(before:b,after:a)}
            try OreJournal.save(row,directory:directory);trials=try OreJournal.load(directory);editingID=row.id
            notice=t("Testlauf als neue Version gespeichert.","Trial saved as a new revision.");failure="";markClean();return true
        } catch {failure=error.localizedDescription;return false}
    }
    private func exportScan(_ scan:SavedOreScan) {
        let panel=NSSavePanel();panel.nameFieldStringValue="ore-measurement-"+scan.id+".json"
        if panel.runModal() == .OK,let url=panel.url {
            do {let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys];try encoder.encode(scan).write(to:url,options:.atomic)}
            catch {failure=error.localizedDescription}
        }
    }
}
