import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

private func buildCategory(_ id: String, _ english: Bool) -> String {
    switch id {
    case "basics": return english ? "Basic circuits" : "Grundschaltungen"
    case "security": return english ? "HQ protection & entrances" : "HQ-Schutz & Zugänge"
    case "architecture": return english ? "Architecture & buildings" : "Architektur & Gebäude"
    case "interiors": return english ? "Interiors & furniture" : "Innenräume & Möbel"
    case "decoration": return english ? "Decoration & planting" : "Dekoration & Pflanzen"
    case "treehouse": return english ? "Treehouses & tree villages" : "Baumhäuser & Baumdörfer"
    case "underwater": return english ? "Underwater & biospheres" : "Unterwasser & Biosphären"
    case "processing": return english ? "Processing & storage" : "Verarbeitung & Lager"
    case "transport": return english ? "Transport networks" : "Transportnetze"
    case "farms": return english ? "Farms" : "Farmen"
    case "building": return english ? "Building & landscaping" : "Bauen & Landschaft"
    case "equipment": return english ? "Equipment & enchanting" : "Ausrüstung & Verzaubern"
    case "exploration": return english ? "Exploration & mining" : "Erkundung & Bergbau"
    case "survival": return english ? "Survival & creatures" : "Überleben & Kreaturen"
    case "other": return english ? "Other topics" : "Weitere Themen"
    default: return english ? "All topics" : "Alle Themen"
    }
}

struct OfflineBuildGuidesView: View {
    let language: String
    @Environment(\.companionTheme) private var theme
    @State private var query = ""
    @State private var category = "all"
    @State private var selected = "lamp"
    private let catalog = try? BuildCatalog.load()
    private var english: Bool { language == "en" }
    private var filtered: [BuildGuide] {
        catalog?.guides.filter { (category == "all" || $0.category == category) && $0.matches(query) } ?? []
    }
    private var visibleGuide: BuildGuide? { filtered.first { $0.id == selected } ?? filtered.first }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Build guides" : "Bauanleitungen") {
                TextField(english ? "Find build or material" : "Aufbau oder Material suchen", text: $query)
                    .textFieldStyle(.roundedBorder).frame(width: CompanionLayout.searchWidth)
            }
            Divider()
            HStack(spacing: 0) {
                sidebar.frame(width: CompanionTheme.sidebarWidth)
                Divider()
                if let catalog, let guide = visibleGuide {
                    BuildGuideDetail(guide: guide, blocks: catalog.blocks, english: english).id(guide.id)
                } else {
                    ContentUnavailableView(english ? "No build guides" : "Keine Bauanleitungen", systemImage: "square.grid.3x3",
                        description: Text(catalog == nil
                            ? (english ? "The offline catalog could not be loaded. Rebuild the app with its resources." : "Der Offline-Katalog konnte nicht geladen werden. App mit ihren Ressourcen neu bauen.")
                            : (english ? "Try another search or select all topics." : "Suche ändern oder alle Themen wählen.")))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(english ? "Topic" : "Thema", selection: $category) {
                ForEach(["all"] + BuildGuideTopic.ids, id: \.self) { Text(buildCategory($0, english)).tag($0) }
            }.labelsHidden().padding(.horizontal, 16).padding(.top, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(BuildGuideTopic.ids, id: \.self) { topic in
                        let items = filtered.filter { $0.category == topic }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(buildCategory(topic, english).uppercased()).font(.system(size: 10, weight: .bold)).tracking(1).foregroundStyle(.secondary)
                                ForEach(items) { guide in
                                    Button { selected = guide.id } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(guide.title.value(english)).font(.headline)
                                            if visibleGuide?.id == guide.id {
                                                Text(guide.summary.value(english)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                            }
                                        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                            .background(visibleGuide?.id == guide.id ? theme.accent.opacity(0.13) : theme.surface)
                                            .overlay(alignment: .leading) { Rectangle().fill(visibleGuide?.id == guide.id ? theme.accent : .clear).frame(width: 3) }
                                    }.buttonStyle(.plain).accessibilityAddTraits(visibleGuide?.id == guide.id ? .isSelected : [])
                                }
                            }
                        }
                    }
                }.padding(.horizontal, 16).padding(.bottom, 16)
            }
            Text(english ? "\(catalog?.guides.count ?? 0) offline test builds\nUntested · AI-generated" : "\(catalog?.guides.count ?? 0) Offline-Testaufbauten\nUngetestet · KI-generiert")
                .font(.caption).foregroundStyle(.secondary).padding(16)
        }.frame(maxHeight: .infinity).background(theme.surface.opacity(0.4))
    }
}

struct BuildGuideDetail: View {
    let guide: BuildGuide
    let blocks: [String: BuildBlock]
    let english: Bool
    @Environment(\.companionTheme) private var theme
    @AppStorage("buildGuideIconDisplay") private var showBlockIcons = false
    @AppStorage("companionIconPack") private var selectedIconPack = "kenney"
    @ObservedObject private var iconStore = ItemIconStore.shared
    @State private var showIconSettings = false
    @State private var planeID = ""
    @AppStorage("buildGuide3DDisplay") private var show3D = false
    @State private var stepIndex = 0
    @State private var collected: Set<Int> = []
    @State private var zoom: Double = 56
    @State private var audioFeedback = ""
    @State private var selectedCell: String? = nil
    @State private var selectedCoordinate = ""
    @State private var testResult: String
    @State private var testNotes: String
    private var plane: BuildPlane { guide.planes.first { $0.id == planeID } ?? guide.planes[0] }
    init(guide: BuildGuide, blocks: [String: BuildBlock], english: Bool) {
        self.guide = guide; self.blocks = blocks; self.english = english
        _collected = State(initialValue: Set(UserDefaults.standard.array(forKey: "buildMaterials.\(guide.id)") as? [Int] ?? []))
        _planeID = State(initialValue: guide.id == "flush" ? "crop" : guide.planes[0].id)
        _testResult = State(initialValue: UserDefaults.standard.string(forKey: "buildTest.\(guide.id)") ?? "untested")
        _testNotes = State(initialValue: UserDefaults.standard.string(forKey: "buildNotes.\(guide.id)") ?? "")
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(buildCategory(guide.category, english).uppercased()).font(.caption.bold()).tracking(1.5).foregroundStyle(theme.accent)
                    Text(guide.title.value(english)).font(CompanionLayout.detailTitle)
                    Text(guide.summary.value(english)).font(.title3).foregroundStyle(.secondary)
                    Label(guide.footprint.value(english), systemImage: "ruler").font(.callout.monospaced())
                    Label(english ? "Untested · AI-generated" : "Ungetestet · KI-generiert", systemImage: "testtube.2").font(.caption.bold()).foregroundStyle(.orange)
                }
                DisclosureGroup(english ? "Materials · \(collected.count)/\(guide.materials.count) ready" : "Materialien · \(collected.count)/\(guide.materials.count) bereit") { materials.padding(.top, 12) }
                instructionBook
                DisclosureGroup(english ? "Display & icon packs" : "Darstellung & Iconpacks") { iconDisplay.padding(.top, 12) }
                DisclosureGroup(english ? "Audio guide for a voice agent" : "Audioguide für einen Sprachagenten") { audioGuide.padding(.top, 12) }
                DisclosureGroup(english ? "Complete plans & all layers" : "Gesamtpläne & alle Ebenen") { blueprint.padding(.top, 12) }
                DisclosureGroup(english ? "Function, testing & troubleshooting" : "Funktion, Test & Fehlerhilfe") {
                section(english ? "How it works" : "So funktioniert der Aufbau", guide.mechanism.value(english))
                section(english ? "A successful test" : "Daran erkennst du den Erfolg", guide.success.value(english))
                section(english ? "If it does not work" : "Wenn es nicht funktioniert", guide.troubleshooting.value(english))
                testLog
                }
                DisclosureGroup(english ? "Evidence & sources" : "Belege & Quellen") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(english ? "Evidence & sources · 5 September 2026" : "Belege & Quellen · 5. September 2026").font(.headline)
                    Text(guide.evidence.value(english)).foregroundStyle(.secondary)
                    Text(english ? "AI-generated layouts based on Minecraft principles, not tested in RealmCraft VR. Catalog IDs establish names, not working VR mechanics. Sources open externally; diagrams work offline." : "KI-generierte Pläne nach Minecraft-Prinzipien, nicht in RealmCraft VR getestet. Katalog-IDs belegen Namen, keine funktionierende VR-Mechanik. Quellen öffnen extern; die Pläne funktionieren offline.").font(.caption).foregroundStyle(.secondary)
                    ForEach(guide.sources.indices, id: \.self) { index in
                        Link(guide.sources[index].title, destination: guide.sources[index].url)
                    }
                }.padding(20).companionPanel()
                }
            }.padding(CompanionLayout.pageInset).frame(maxWidth: 1100, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
        }.onChange(of: planeID) { _, _ in selectedCell = nil; selectedCoordinate = "" }
    }
    private var iconDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker(english ? "Plan display" : "Plananzeige", selection: $showBlockIcons) {
                    Text(english ? "Symbols" : "Symbole").tag(false)
                    Text(english ? "Block icons" : "Block-Icons").tag(true)
                }.pickerStyle(.segmented).frame(maxWidth: 340)
                Button(english ? "Icon packs…" : "Iconpacks…") { showIconSettings = true }
            }
            if showBlockIcons {
                let pack = IconPack(rawValue: selectedIconPack) ?? .kenney
                Text(iconStore.installed.contains(pack)
                     ? (english ? "Pack: " : "Pack: ") + pack.title
                     : (english ? "Selected pack is not installed. Install it via Icon packs; symbols remain visible." : "Das ausgewählte Pack ist nicht installiert. Über Iconpacks installieren; bis dahin bleiben Symbole sichtbar."))
                    .font(.caption).foregroundStyle(.secondary)
                Text(english ? "2D pack textures, not original RealmCraft graphics. Symbols preserve orientation and placement details. Unmapped blocks and empty spaces keep the schematic display." : "2D-Texturen aus dem Pack, keine RealmCraft-Originalgrafiken. Kürzel erhalten Ausrichtung und Platzierungsdetails. Blöcke ohne Zuordnung und freie Felder behalten die schematische Darstellung.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.sheet(isPresented: $showIconSettings) { ItemIconSettings(english: english) }
    }
    private var audioGuide: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(english ? "Audio guide with a voice agent" : "Audioguide mit Sprachagent", systemImage: "headphones").font(.headline)
            Text(english ? "Build with your headset on: one small instruction, then say done, repeat or pause." : "Mit aufgesetzter Brille bauen: eine kleine Aufgabe, dann fertig, wiederholen oder Pause sagen.").font(.callout)
            HStack {
                Button(english ? "Copy audio guide prompt" : "Audioguide-Auftrag kopieren") {
                    NSPasteboard.general.clearContents()
                    let ok = NSPasteboard.general.setString(guide.audioAgentPrompt(blocks: blocks, english: english), forType: .string)
                    audioFeedback = ok ? (english ? "Copied — paste into your voice agent's conversation." : "Kopiert – in die Unterhaltung deines Sprachagenten einfügen.") : (english ? "Copy failed. Try saving a file." : "Kopieren fehlgeschlagen. Als Datei speichern versuchen.")
                }
                Button(english ? "Save as text…" : "Als Text speichern …") {
                    let panel = NSSavePanel()
                    panel.nameFieldStringValue = "RealmCraft-Audioguide-\(guide.id).txt"
                    if panel.runModal() == .OK, let url = panel.url {
                        do {
                            try guide.audioAgentPrompt(blocks: blocks, english: english).write(to: url, atomically: true, encoding: .utf8)
                            audioFeedback = english ? "Audio guide prompt saved." : "Audioguide-Auftrag gespeichert."
                        } catch { audioFeedback = error.localizedDescription }
                    }
                }
            }
            if !audioFeedback.isEmpty { Text(audioFeedback).font(.caption).foregroundStyle(theme.accent) }
            DisclosureGroup(english ? "Use with ChatGPT or another voice agent" : "Mit ChatGPT oder einem anderen Sprachagenten nutzen") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(english ? "1. Copy the prompt or save the text file. It contains this guide's materials, steps and grids.\n2. Paste it into a conversation with your chosen agent (or attach the text file where supported), then start that app's voice conversation. Confirm that it has received the whole plan.\n3. Before putting on your headset, test microphone and sound. Say: Start the audio guide and wait after each small action.\n4. Agree on a fixed building direction. Say done only after placement; ask for a checkpoint before stopping." : "1. Auftrag kopieren oder Textdatei speichern. Er enthält Materialien, Schritte und Raster dieser Anleitung.\n2. In eine Unterhaltung beim gewünschten Agenten einfügen (oder dort die Textdatei anhängen, falls unterstützt), dann dessen Sprachmodus starten. Bestätigen lassen, dass der ganze Plan vorliegt.\n3. Vor dem Aufsetzen der Brille Mikrofon und Ton testen. Sagen: Starte den Audioguide und warte nach jeder kleinen Aufgabe.\n4. Eine feste Baurichtung vereinbaren. Erst nach dem Setzen fertig sagen; vor dem Beenden einen Zwischenstand anfordern.")
                    Text(english ? "The agent speaks the guide; Companion exports text, not an audio recording. Nothing is sent automatically. Voice availability depends on your chosen app/account. There is no headset view or progress sync; material checkmarks and personal test notes are not exported." : "Der Agent spricht die Anleitung; der Companion exportiert Text, keine Tonaufnahme. Es wird nichts automatisch gesendet. Sprachfunktionen hängen von App und Konto ab. Es gibt keine Brillensicht oder Fortschrittssynchronisierung; Materialhäkchen und persönliche Testnotizen werden nicht exportiert.").font(.caption).foregroundStyle(.secondary)
                    Link(english ? "ChatGPT voice instructions" : "ChatGPT-Sprachmodus: Anleitung", destination: URL(string: "https://learn.chatgpt.com/docs/features/voice")!)
                }.padding(.top, 8)
            }
        }.padding(CompanionLayout.panelInset).companionPanel()
    }
    private var blueprint: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(english ? "Block plan" : "Blockplan").font(.title2.bold())
                Spacer()
                Text(english ? "1 large square = 1 block" : "1 großes Kästchen = 1 Block").font(.caption).foregroundStyle(.secondary)
            }
            Picker(english ? "View / layer" : "Ansicht / Ebene", selection: Binding(get: { plane.id }, set: { planeID = $0 })) {
                ForEach(guide.planes) { Text($0.title.value(english)).tag($0.id) }
            }.frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Text(english ? "Grid size" : "Rastergröße").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "minus.magnifyingglass")
                Slider(value: $zoom, in: 44...76, step: 4).frame(width: 130).accessibilityLabel(english ? "Grid size" : "Rastergröße")
                Image(systemName: "plus.magnifyingglass")
            }
            Text(plane.note.value(english)).font(.callout).fixedSize(horizontal: false, vertical: true)
            ScrollView(.horizontal) {
                BuildPaperGrid(plane: plane, blocks: blocks, english: english, cellSize: zoom) { key, coordinate in
                    selectedCell = key; selectedCoordinate = coordinate
                }.padding(1)
            }
            Text(english ? "Coordinates are local to this build. Top views: x left → right, z back → front. Side views: height y. Small subdivisions are drawing guides, not partial blocks. Click a cell for placement details." : "Koordinaten gelten relativ zum Aufbau. Draufsicht: x links → rechts, z hinten → vorne. Seitenansicht: Höhe y. Feine Unterteilungen dienen als Zeichenhilfe, nicht als Teilblöcke. Ein Feld anklicken zeigt Platzierungsdetails.")
                .font(.caption).foregroundStyle(.secondary)
            if let key = selectedCell, let block = blocks[key] {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(selectedCoordinate) · \(block.name.value(english))").font(.headline)
                    Text(block.detail.value(english)).font(.callout)
                }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(theme.accent.opacity(0.10))
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), alignment: .leading)], alignment: .leading, spacing: 10) {
                ForEach(Array(Set(plane.cells.flatMap { $0 })).sorted(), id: \.self) { key in
                    if let block = blocks[key] {
                        HStack(spacing: 8) {
                            BuildBlockGlyph(block: block, size: 34).frame(width: 34, height: 34)
                            Text(block.name.value(english)).font(.caption)
                        }
                    }
                }
            }
        }.padding(CompanionLayout.panelInset).companionPanel()
    }
    private var materials: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(english ? "1 · Gather materials" : "1 · Materialien bereitstellen").font(.title2.bold())
                Spacer()
                Text("\(collected.intersection(Set(guide.materials.indices)).count) / \(guide.materials.count)").font(.callout.monospaced()).foregroundStyle(.secondary)
                Menu {
                    Button(english ? "Copy shopping list" : "Einkaufsliste kopieren") {
                        let lines = orderedMaterials.map { i in
                            "[\(collected.contains(i) ? "x" : " ")] \(guide.materials[i].count.value(english)) × \(guide.materials[i].name.value(english)) — \(english ? "from step" : "ab Schritt") \(guide.materialFirstSteps[i])"
                        }
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(([guide.title.value(english)] + lines).joined(separator: "\n"), forType: .string)
                    }
                    Button(english ? "Clear checkmarks" : "Häkchen zurücksetzen") { collected = []; saveChecklist() }
                } label: { Image(systemName: "ellipsis.circle") }.fixedSize()
                    .accessibilityLabel(english ? "Material list actions" : "Materiallisten-Aktionen")
            }
            Text(english ? "Full quantities, ordered by first use. Tools and test supplies are included; gather these before building." : "Gesamtmengen nach erstem Einsatz sortiert. Werkzeuge und Testmaterial sind enthalten; vor dem Bau bereitstellen.").font(.caption).foregroundStyle(.secondary)
            ForEach(orderedMaterials, id: \.self) { i in
                HStack(alignment: .top, spacing: 12) {
                    Toggle(isOn: Binding(get: { collected.contains(i) }, set: { checked in
                        if checked { collected.insert(i) } else { collected.remove(i) }; saveChecklist()
                    })) { Text(guide.materials[i].count.value(english)).font(.callout.monospaced().bold()).frame(width: 88, alignment: .leading) }
                        .accessibilityLabel(guide.materials[i].name.value(english))
                    Text(guide.materials[i].name.value(english)).frame(maxWidth: .infinity, alignment: .leading)
                    Text(english ? "Step \(guide.materialFirstSteps[i])" : "Schritt \(guide.materialFirstSteps[i])").font(.caption).foregroundStyle(.secondary)
                }.foregroundStyle(collected.contains(i) ? Color.secondary : Color.primary)
                if i != orderedMaterials.last { Divider() }
            }
        }.padding(20).companionPanel()
    }
    private var orderedMaterials: [Int] {
        guide.materials.indices.sorted { a, b in guide.materialFirstSteps[a] == guide.materialFirstSteps[b] ? a < b : guide.materialFirstSteps[a] < guide.materialFirstSteps[b] }
    }
    private func saveChecklist() { UserDefaults.standard.set(collected.sorted(), forKey: "buildMaterials.\(guide.id)") }
    private var instructionBook: some View {
        let stage = guide.instructionStages[stepIndex]
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(english ? "Build step by step" : "Schritt für Schritt bauen").font(.title2.bold())
                Spacer()
                Text("\(stepIndex + 1) / \(guide.steps.count)").monospacedDigit().foregroundStyle(.secondary)
            }
            HStack {
                Button { stepIndex -= 1 } label: { Label(english ? "Back" : "Zurück", systemImage: "chevron.left") }.disabled(stepIndex == 0)
                Picker(english ? "Step" : "Schritt", selection: $stepIndex) {
                    ForEach(guide.steps.indices, id: \.self) { i in Text(english ? "Step \(i+1)" : "Schritt \(i+1)").tag(i) }
                }.labelsHidden().frame(width: 150)
                Spacer()
                Button { stepIndex += 1 } label: { Label(english ? "Next" : "Weiter", systemImage: "chevron.right") }.disabled(stepIndex == guide.steps.count - 1)
            }
            HStack {
                Picker(english ? "Build preview" : "Bauvorschau", selection: $show3D) {
                    Text(english ? "2D grid" : "2D-Raster").tag(false)
                    Text(english ? "3D model" : "3D-Modell").tag(true)
                }.pickerStyle(.segmented).frame(maxWidth: 320)
                Spacer()
                Button(english ? "Last step" : "Letzter Schritt") { stepIndex = guide.steps.count - 1 }
            }
            Text(guide.steps[stepIndex].value(english)).font(.title3).fixedSize(horizontal: false, vertical: true)
            let introduced = orderedMaterials.filter { guide.materialFirstSteps[$0] == stepIndex + 1 }
            if !introduced.isEmpty {
                Text((english ? "First needed now: " : "Ab hier benötigt: ") + introduced.map { guide.materials[$0].name.value(english) }.joined(separator: " · "))
                    .font(.callout).foregroundStyle(theme.accent)
            }
            if show3D {
                BuildGuide3DView(guide: guide, blocks: blocks, step: stepIndex, english: english) { key, coordinate in
                    selectedCell = key; selectedCoordinate = coordinate
                }
            } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    stageDiagram(stage.top, highlights: stage.topNew, title: english ? "Top view" : "Draufsicht").frame(width: 350)
                    stageDiagram(stage.side, highlights: stage.sideNew, title: english ? "Side view" : "Seitenansicht").frame(width: 350)
                }
                VStack(alignment: .leading, spacing: 20) {
                    stageDiagram(stage.top, highlights: stage.topNew, title: english ? "Top view" : "Draufsicht")
                    stageDiagram(stage.side, highlights: stage.sideNew, title: english ? "Side view" : "Seitenansicht")
                }
            }
            }
            if let key = selectedCell, let block = blocks[key] {
                Text("\(selectedCoordinate) · \(block.name.value(english))\n\(block.detail.value(english))").font(.callout).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(theme.accent.opacity(0.1))
            }
            let used = Set((stage.top.cells + stage.side.cells).flatMap { $0 }).subtracting(["."])
            DisclosureGroup(english ? "Legend & reading the plan" : "Legende & Plan lesen") {
                Text(english ? "Color = new in this step · pale = already present. Green in 3D = new or changed. Growth and test positions are illustrative, not extra materials." : "Farbig = neu · blass = bereits vorhanden. Grün im 3D-Modell = neu oder geändert. Wachstum und Teststellungen sind Hinweise, keine zusätzlichen Materialien.").font(.caption).foregroundStyle(.secondary)
            Text(used.sorted().compactMap { key in blocks[key].map { "\($0.symbol) = \($0.name.value(english))" } }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(20).companionPanel().onChange(of: stepIndex) { _, _ in selectedCell = nil; selectedCoordinate = "" }
    }
    private func stageDiagram(_ plane: BuildPlane, highlights: [String], title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(plane.title.value(english)).font(.caption).foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                BuildPaperGrid(plane: plane, blocks: blocks, english: english, cellSize: 44, highlighted: Set(highlights)) { key, coordinate in
                    selectedCell = key; selectedCoordinate = "\(plane.title.value(english)) · \(coordinate)"
                }
            }
            Text(plane.note.value(english)).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
    private var testLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(english ? "Your test log" : "Dein Testprotokoll").font(.title2.bold())
            Picker(english ? "Your result" : "Dein Ergebnis", selection: $testResult) {
                Text(english ? "Not tested" : "Nicht getestet").tag("untested")
                Text(english ? "Works" : "Funktioniert").tag("works")
                Text(english ? "Partially" : "Teilweise").tag("partial")
                Text(english ? "Does not work" : "Funktioniert nicht").tag("failed")
            }.pickerStyle(.segmented)
            Text(english ? "Game version, platform, result and observations:" : "Spielversion, Plattform, Ergebnis und Beobachtungen:").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $testNotes).font(.body).frame(height: 80).padding(4)
                .overlay(Rectangle().stroke(theme.border)).accessibilityLabel(english ? "Test notes" : "Testnotizen")
            Text(english ? "Saved automatically on this Mac, separately for each build. Your result does not change the source verification status. Repeat after reloading the world." : "Wird je Aufbau automatisch auf diesem Mac gespeichert. Dein Ergebnis ändert den Quellenstatus nicht. Nach erneutem Laden der Welt wiederholen.").font(.caption).foregroundStyle(.secondary)
        }.padding(20).companionPanel()
            .onChange(of: testResult) { _, value in UserDefaults.standard.set(value, forKey: "buildTest.\(guide.id)") }
            .onChange(of: testNotes) { _, value in UserDefaults.standard.set(value, forKey: "buildNotes.\(guide.id)") }
    }
    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title2.bold())
            Text(text).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).companionPanel()
    }
}

private func buildColor(_ name: String) -> Color {
    switch name {
    case "stone": return Color(red: 0.76, green: 0.79, blue: 0.78)
    case "signal": return Color(red: 0.97, green: 0.67, blue: 0.61)
    case "light": return Color(red: 0.99, green: 0.86, blue: 0.45)
    case "water": return Color(red: 0.60, green: 0.82, blue: 0.96)
    case "plant": return Color(red: 0.69, green: 0.85, blue: 0.46)
    case "soil": return Color(red: 0.80, green: 0.66, blue: 0.49)
    case "wood": return Color(red: 0.94, green: 0.78, blue: 0.52)
    case "metal": return Color(red: 0.64, green: 0.76, blue: 0.80)
    case "machine": return Color(red: 0.73, green: 0.74, blue: 0.91)
    default: return Color.clear
    }
}

/// Shared by all plan cells and the legend. Never invent a texture for a generic marker.
struct BuildBlockGlyph: View {
    let block: BuildBlock
    let size: Double
    var elevation = false
    @AppStorage("buildGuideIconDisplay") private var useIcons = false
    @AppStorage("companionIconPack") private var selectedPack = "kenney"
    @ObservedObject private var store = ItemIconStore.shared
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if useIcons, block.itemID == 95 {
                Rectangle().fill(Color.red).frame(width: size, height: size)
                if block.symbol == "BK" {
                    Rectangle().fill(.white).frame(width: size * 0.85, height: size * 0.4).frame(width: size, height: size, alignment: .bottom)
                }
                Text(block.symbol).font(.system(size: max(9, size * 0.22), weight: .bold, design: .monospaced)).foregroundStyle(.black).background(.white.opacity(0.9))
            } else if useIcons, let id = BuildGuideTexture.surfaceID(for: block),
               let image = store.image(for: id, pack: IconPack(rawValue: selectedPack) ?? .kenney) {
                Image(nsImage: BuildGuideTexture.image(image, for: block)).resizable().interpolation(.none)
                    .aspectRatio(block.itemID == 168 ? 1 : nil, contentMode: .fit)
                    .frame(width: size, height: size)
                Text(block.symbol).font(.system(size: max(9, size * 0.22), weight: .bold, design: .monospaced))
                    .foregroundStyle(.black).padding(.horizontal, 2)
                    .background(.white.opacity(0.9)).accessibilityHidden(true)
            } else {
                Text(block.symbol).font(.system(size: size * 0.3, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.black.opacity(block.color == "air" ? 0.28 : 0.9))
                    .frame(width: size, height: size)
            }
        }.frame(width: size, height: size).background(buildColor(block.color).opacity(0.87))
            .mask(BuildGuideCellShape(itemID: block.itemID, symbol: block.symbol, elevation: elevation))
            .overlay(alignment: .bottomTrailing) {
                if elevation, [95,152,261,466].contains(block.itemID ?? -1) {
                    Text(block.symbol).font(.system(size: max(9, size * 0.22), weight: .bold, design: .monospaced))
                        .foregroundStyle(.black).padding(.horizontal, 2).background(.white.opacity(0.9)).accessibilityHidden(true)
                }
            }
    }
}

/// Side elevations show occupied height; top views retain the full footprint.
struct BuildGuideCellShape: Shape {
    let itemID: Int?
    let symbol: String
    let elevation: Bool
    func path(in rect: CGRect) -> Path {
        guard elevation else { return Path(rect) }
        if itemID == 466 { return Path(CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2)) }
        if [152,261].contains(itemID ?? -1), symbol.contains("→") || symbol.contains("←") {
            var result = Path(CGRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2))
            result.addRect(CGRect(x: symbol.contains("←") ? rect.minX : rect.midX, y: rect.minY, width: rect.width / 2, height: rect.height / 2))
            return result
        }
        if itemID == 95 { return Path(CGRect(x: rect.minX, y: rect.minY + rect.height * 0.45, width: rect.width, height: rect.height * 0.55)) }
        return Path(rect)
    }
}

struct BuildPaperGrid: View {
    let plane: BuildPlane
    let blocks: [String: BuildBlock]
    let english: Bool
    let cellSize: Double
    var highlighted: Set<String>? = nil
    let select: (String, String) -> Void
    private let margin: CGFloat = 36
    var body: some View {
        let width = CGFloat(plane.columns.count) * cellSize
        let height = CGFloat(plane.rows.count) * cellSize
        ZStack(alignment: .topLeading) {
            Color(red: 0.97, green: 0.97, blue: 0.92)
            Canvas { context, _ in
                let spacing = cellSize / 5
                var fine = Path()
                for i in 0...(plane.columns.count * 5) {
                    let x = margin + CGFloat(i) * spacing
                    fine.move(to: CGPoint(x: x, y: margin)); fine.addLine(to: CGPoint(x: x, y: margin + height))
                }
                for i in 0...(plane.rows.count * 5) {
                    let y = margin + CGFloat(i) * spacing
                    fine.move(to: CGPoint(x: margin, y: y)); fine.addLine(to: CGPoint(x: margin + width, y: y))
                }
                context.stroke(fine, with: .color(.teal.opacity(0.16)), lineWidth: 0.5)
                var major = Path()
                for i in 0...plane.columns.count {
                    let x = margin + CGFloat(i) * cellSize
                    major.move(to: CGPoint(x: x, y: margin)); major.addLine(to: CGPoint(x: x, y: margin + height))
                }
                for i in 0...plane.rows.count {
                    let y = margin + CGFloat(i) * cellSize
                    major.move(to: CGPoint(x: margin, y: y)); major.addLine(to: CGPoint(x: margin + width, y: y))
                }
                context.stroke(major, with: .color(.teal.opacity(0.6)), lineWidth: 1)
            }.accessibilityHidden(true)
            Text("\(plane.rowAxis) / \(plane.columnAxis)").font(.system(size: 10, design: .monospaced)).foregroundStyle(.black.opacity(0.7)).padding(5)
            ForEach(plane.columns.indices, id: \.self) { col in
                Text(plane.columns[col]).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(.black.opacity(0.7))
                    .frame(width: cellSize, height: margin).offset(x: margin + CGFloat(col) * cellSize)
            }
            ForEach(plane.rows.indices, id: \.self) { row in
                Text(plane.rows[row]).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(.black.opacity(0.7))
                    .frame(width: margin, height: cellSize).offset(y: margin + CGFloat(row) * cellSize)
                ForEach(plane.columns.indices, id: \.self) { col in
                    let key = plane.cells[row][col]
                    if let block = blocks[key] {
                        let coordinate = "\(plane.columnAxis)=\(plane.columns[col]), \(plane.rowAxis)=\(plane.rows[row])"
                        Button { select(key, coordinate) } label: {
                            BuildBlockGlyph(block: block, size: cellSize - 6, elevation: plane.rowAxis == "y")
                                .overlay(Rectangle().strokeBorder(key == "." ? Color.clear : .black.opacity(0.25), lineWidth: 1))
                                .frame(width: cellSize, height: cellSize)
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .opacity(highlighted.map { $0.contains("\(row):\(col)") ? 1 : 0.42 } ?? 1)
                            .help("\(coordinate) · \(block.name.value(english))\n\(block.detail.value(english))")
                            .accessibilityLabel("\(coordinate), \(block.name.value(english))")
                            .offset(x: margin + CGFloat(col) * cellSize, y: margin + CGFloat(row) * cellSize)
                    }
                }
            }
        }.frame(width: width + margin + 16, height: height + margin + 16).clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

@MainActor final class VideoTipSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var speaking = false
    @Published private(set) var notice = ""
    override init() { super.init(); synthesizer.delegate = self }
    func read(_ text: String, english: Bool) {
        stop()
        guard let voice = AVSpeechSynthesisVoice(language: english ? "en-GB" : "de-DE") else {
            notice = english ? "No English system voice available." : "Keine deutsche Systemstimme verfügbar."
            return
        }
        notice = ""
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speaking = true
        synthesizer.speak(utterance)
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate); speaking = false }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speaking = self.synthesizer.isSpeaking }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speaking = self.synthesizer.isSpeaking }
    }
}

private struct VideoThumbnail: View {
    let tip: VideoTip
    let english: Bool
    var body: some View {
        AsyncImage(url: tip.thumbnailURL) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                ZStack {
                    Color.secondary.opacity(0.08)
                    Label(english ? "YouTube preview" : "YouTube-Vorschaubild", systemImage: "photo")
                        .font(.caption).foregroundStyle(.secondary)
                }.aspectRatio(4.0 / 3.0, contentMode: .fit)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Text(VideoTip.time(tip.duration)).font(.caption.monospacedDigit().bold())
                .padding(4).foregroundStyle(.white).background(.black.opacity(0.8))
                .padding(6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel((english ? "YouTube thumbnail: " : "YouTube-Vorschaubild: ") + tip.originalTitle)
    }
}

private struct VideoOriginalMetadata: View {
    let tip: VideoTip
    let english: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
                    Link(destination: tip.videoURL) {
                        VideoThumbnail(tip: tip, english: english).frame(maxWidth: 420)
                    }.buttonStyle(.plain)
                    Text(english ? "Original YouTube title" : "Originaltitel auf YouTube").font(.caption).foregroundStyle(.secondary)
                    Link(tip.originalTitle, destination: tip.videoURL).font(.title3).fixedSize(horizontal: false, vertical: true)
                    Text((english ? "Channel: " : "Kanal: ") + tip.channel).font(.callout)
                    Text((english ? "Uploaded: " : "Hochgeladen: ") + tip.published + " · " + (english ? "Duration: " : "Dauer: ") + VideoTip.time(tip.duration))
                        .font(.callout.monospacedDigit()).foregroundStyle(.secondary)
        }
    }
}

private struct VideoCatalogRow: View {
    let tip: VideoTip
    let english: Bool
    let selected: Bool
    @Environment(\.companionTheme) private var theme
    var body: some View {
                                    VStack(alignment: .leading, spacing: 7) {
                                        VideoThumbnail(tip: tip, english: english)
                                        Text(tip.originalTitle).font(.headline).fixedSize(horizontal: false, vertical: true)
                                        Text(tip.title.value(english)).font(.caption).foregroundStyle(.secondary)
                                        Text(tip.channel).font(.caption).foregroundStyle(.secondary)
                                        Text((tip.isShort ? "Short · " : "") + tip.coverageLabel(english)).font(.caption).foregroundStyle(theme.accent)
                                        Text("\(tip.published) · \(VideoTip.time(tip.duration))").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                    }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                        .background(selected ? theme.accent.opacity(0.15) : theme.surface)
                                        .overlay(alignment: .leading) { Rectangle().fill(selected ? theme.accent : .clear).frame(width: 3) }
    }
}

struct VideoTipsView: View {
    let language: String
    @Environment(\.companionTheme) private var theme
    @State private var query = ""
    @State private var category = "all"
    @State private var selected: String? = nil
    @State private var coverage = "all"
    @State private var sortOrder: VideoSortOrder = .newest
    private let tips = VideoTip.bundled
    private var english: Bool { language == "en" }
    private var filtered: [VideoTip] { sortOrder.sorted((tips ?? []).filter {
        (category == "all" || $0.category == category)
        && (coverage == "all" || (coverage == "curated" && $0.isCurated) || (coverage == "pending" && !$0.isCurated) || (coverage == "visual" && $0.isVisualReviewOnly) || (coverage == "transcript" && $0.hasTranscript) || (coverage == "short" && $0.isShort))
        && $0.matches(query)
    }) }
    private var visible: VideoTip? { filtered.first { $0.id == selected } ?? filtered.first }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Video tips & guides" : "Video-Tipps & Anleitungen") {
                TextField(english ? "Search topic, material or tip" : "Thema, Material oder Tipp suchen", text: $query)
                    .textFieldStyle(.roundedBorder).frame(width: CompanionLayout.searchWidth)
            }
            Divider()
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Picker(english ? "Topic" : "Thema", selection: $category) {
                        ForEach(["all", "farms", "processing", "transport", "building", "equipment", "exploration", "survival", "other"], id: \.self) { Text(buildCategory($0, english)).tag($0) }
                    }.padding(.top, 16)
                    Picker(english ? "Content" : "Inhalt", selection: $coverage) {
                        Text(english ? "All videos" : "Alle Videos").tag("all")
                        Text(english ? "Reviewed contributions" : "Aufbereitete Beiträge").tag("curated")
                        Text(english ? "Visual notes only" : "Nur Bildauswertung").tag("visual")
                        Text(english ? "Review pending" : "Auswertung noch offen").tag("pending")
                        Text(english ? "With transcript index" : "Mit Transkriptindex").tag("transcript")
                        Text("Shorts").tag("short")
                    }
                    Picker(english ? "Sort by" : "Sortierung", selection: $sortOrder) {
                        ForEach(VideoSortOrder.allCases, id: \.self) { order in
                            Text(order.label(english)).tag(order)
                        }
                    }
                    HStack {
                        Text(english ? "\(filtered.count) of \(tips?.count ?? 0) videos" : "\(filtered.count) von \(tips?.count ?? 0) Videos")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        if !query.isEmpty || category != "all" || coverage != "all" || sortOrder != .newest {
                            Button(english ? "Reset" : "Zurücksetzen") { query = ""; category = "all"; coverage = "all"; sortOrder = .newest; selected = nil }
                                .font(.caption).buttonStyle(.borderless)
                        }
                    }
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(filtered) { tip in
                                Button { selected = tip.id } label: {
                                    VideoCatalogRow(tip: tip, english: english, selected: visible?.id == tip.id)
                                }.buttonStyle(.plain).accessibilityAddTraits(visible?.id == tip.id ? .isSelected : [])
                            }
                        }
                    }
                    Text(english ? "\((tips ?? []).filter(\.isCurated).count) of \(tips?.count ?? 0) contributions reviewed\n\((tips ?? []).filter { !$0.isCurated }.count) reviews pending\n\((tips ?? []).filter(\.hasTranscript).count) transcripts indexed" : "\((tips ?? []).filter(\.isCurated).count) von \(tips?.count ?? 0) Beiträgen aufbereitet\n\((tips ?? []).filter { !$0.isCurated }.count) Auswertungen noch offen\n\((tips ?? []).filter(\.hasTranscript).count) Transkripte durchsuchbar")
                        .font(.caption).foregroundStyle(.secondary).padding(.bottom, 16)
                }.padding(.horizontal, 16).frame(width: CompanionTheme.sidebarWidth).background(theme.surface.opacity(0.4))
                Divider()
                if let tip = visible {
                    VideoTipDetail(tip: tip, english: english, query: query).id(tip.id)
                } else {
                    ContentUnavailableView(english ? "No video tips" : "Keine Video-Tipps", systemImage: "play.rectangle",
                        description: Text(tips == nil ? (english ? "The video catalog could not be loaded." : "Der Videokatalog konnte nicht geladen werden.") : (english ? "Change your search or select all topics." : "Suche ändern oder alle Themen wählen.")))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

struct VideoTipDetail: View {
    let tip: VideoTip
    let english: Bool
    var query: String = ""
    @StateObject private var speech = VideoTipSpeech()
    @State private var audioLanguage = "de"
    @AppStorage(VideoKnowledgeExport.selectionKey) private var videoSelection = ""
    @State private var exportNotice = ""
    @State private var transcriptLimit = 40
    @Environment(\.companionTheme) private var theme
    private var audioEnglish: Bool { audioLanguage == "en" }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(buildCategory(tip.category, english).uppercased(), systemImage: "play.rectangle.fill")
                        .font(.caption.bold()).foregroundStyle(theme.accent)
                    Text(tip.title.value(english)).font(CompanionLayout.detailTitle)
                    VideoOriginalMetadata(tip: tip, english: english)
                    Text(english ? "Short summary" : "Kurzfassung").font(.headline)
                    Text(tip.summary.value(english)).font(.title3).foregroundStyle(.secondary)
                    Text(tip.coverageLabel(english) + (tip.isShort ? " · Short" : "")).font(.caption.bold()).foregroundStyle(theme.accent)
                    Label(tip.sourceScope?.value(english) ?? (english ? "PCVR / Steam · Quest untested" : "PCVR / Steam · Quest ungetestet"), systemImage: "info.circle")
                        .font(.caption.bold()).foregroundStyle(.orange)
                    Link(english ? "Open original video ↗" : "Originalvideo öffnen ↗", destination: tip.videoURL)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(english ? "Export for an agent" : "Für einen Agenten exportieren").font(.headline)
                    Toggle(english ? "Include this video in the overall AI export" : "Dieses Video in den KI-Gesamtexport aufnehmen", isOn: Binding(
                        get: { VideoKnowledgeExport.selectedIDs(videoSelection).contains(tip.videoID) },
                        set: { videoSelection = VideoKnowledgeExport.selecting(tip.videoID, in: videoSelection, enabled: $0) }
                    )).toggleStyle(.checkbox)
                    Button(english ? "Export video as Markdown…" : "Video als Markdown exportieren …") { exportVideo() }
                    Text(english ? "Includes summary, authored steps, timestamp links and review status. No full transcript or audio. Your selection is remembered; AI export can place video notes in a second file." : "Enthält Kurzfassung, aufbereitete Schritte, Sprungmarken und Prüfstatus. Kein Volltranskript oder Audio. Die Auswahl bleibt gespeichert; der KI-Export kann Videonotizen in einer zweiten Datei ablegen.").font(.caption).foregroundStyle(.secondary)
                    if !exportNotice.isEmpty { Text(exportNotice).font(.caption).textSelection(.enabled) }
                }.padding(CompanionLayout.panelInset).companionPanel()
                VStack(alignment: .leading, spacing: 12) {
                    Text(english ? "Listen" : "Anhören").font(.headline)
                    Picker(english ? "Reading language" : "Vorlesesprache", selection: $audioLanguage) {
                        Text("Deutsch").tag("de"); Text("English").tag("en")
                    }.pickerStyle(.segmented).frame(maxWidth: 280)
                    HStack {
                        Button {
                            let en = audioEnglish
                            let text = ([tip.title.value(en), tip.summary.value(en), tip.prerequisites.value(en)] + tip.steps.map { $0.title.value(en) + ". " + $0.text.value(en) } + [tip.limitations.value(en)]).joined(separator: "\n\n")
                            speech.read(text, english: en)
                        } label: { Label(tip.isCurated ? (english ? "Read notes" : "Beitrag vorlesen") : (english ? "Read overview" : "Überblick vorlesen"), systemImage: "speaker.wave.2") }
                        Button(english ? "Stop" : "Stopp") { speech.stop() }.disabled(!speech.speaking)
                    }
                    Text(english ? "System voice reads our edited summary, not a full video dub. For the creator’s voice, open YouTube → Settings → Audio track → Original (if offered). YouTube chooses the track; the link cannot force it." : "Die Systemstimme liest unsere aufbereitete Zusammenfassung, keine vollständige Synchronfassung. Für die Stimme des Autors: YouTube öffnen → Einstellungen → Audiotrack → Original (falls angeboten). Die Tonspur wählst du auf YouTube.")
                        .font(.caption).foregroundStyle(.secondary)
                    if !speech.notice.isEmpty { Text(speech.notice).foregroundStyle(.orange) }
                }.padding(CompanionLayout.panelInset).companionPanel()
                if tip.isCurated { note(english ? "What you need" : "Was du brauchst", tip.prerequisites.value(english)) }
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !tip.steps.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(english ? "Matching video moments" : "Passende Videostellen").font(.headline)
                        let matches = tip.steps.filter { $0.matches(query) }
                        if matches.isEmpty {
                            Text(english ? "This video matches through its topic, materials or several steps. See the reviewed notes below." : "Dieses Video passt über sein Thema, Materialien oder mehrere Schritte. Die aufbereiteten Notizen stehen unten.")
                                .font(.callout).foregroundStyle(.secondary)
                        }
                        ForEach(matches.indices, id: \.self) { index in
                            let step = matches[index]
                            Link(destination: tip.url(at: step.seconds)) {
                                Label(VideoTip.time(step.seconds) + " · " + step.title.value(english), systemImage: "play.circle")
                            }
                            Text(step.text.value(english)).font(.callout).textSelection(.enabled)
                        }
                    }.padding(CompanionLayout.panelInset).frame(maxWidth: .infinity, alignment: .leading).companionPanel()
                }
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && tip.hasTranscript {
                    let moments = tip.transcriptMatches(query)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(english ? "Transcript matches · \(moments.count)" : "Transkripttreffer · \(moments.count)").font(.headline)
                        Text(english ? "Automatic captions, grouped into 30-second search windows. Links start slightly earlier; check the explanation in the original video. German topic terms also match the English index." : "Automatische Untertitel in 30-Sekunden-Suchfenstern. Links starten etwas früher; die Erklärung bitte im Originalvideo prüfen. Deutsche Themenbegriffe finden auch Stellen im englischen Index.")
                            .font(.caption).foregroundStyle(.secondary)
                        ForEach(Array(moments.prefix(transcriptLimit).enumerated()), id: \.offset) { _, moment in
                            Link(destination: tip.url(at: max(0, moment.seconds - 5))) {
                                Label(VideoTip.time(moment.seconds) + " · " + query, systemImage: "play.circle")
                            }
                        }
                        if moments.count > transcriptLimit {
                            Button(english ? "Show more matches" : "Weitere Treffer zeigen") { transcriptLimit += 40 }
                        }
                        if moments.isEmpty { Text(english ? "Terms occur in different passages or in the topic description." : "Die Begriffe stehen in verschiedenen Abschnitten oder in der Themenbeschreibung.").font(.caption) }
                    }.padding(CompanionLayout.panelInset).frame(maxWidth: .infinity, alignment: .leading).companionPanel()
                }
                if let topics = tip.topics, !topics.isEmpty {
                    note(english ? "Search topics" : "Suchthemen", topics.map { $0.value(english) }.joined(separator: " · "))
                }
                if !tip.steps.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text(english ? "Steps & practical tips" : "Schritte & praktische Tipps").font(.title2.bold())
                    ForEach(tip.steps.indices, id: \.self) { index in
                        let step = tip.steps[index]
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(index + 1) · \(step.title.value(english))").font(.headline)
                            Text(step.text.value(english)).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                            HStack(spacing: 18) {
                                Link(destination: tip.url(at: step.seconds)) {
                                    Label((english ? "Watch from " : "Im Video ab ") + VideoTip.time(step.seconds), systemImage: "play.circle")
                                }
                                Button { speech.read(step.title.value(audioEnglish) + ". " + step.text.value(audioEnglish), english: audioEnglish) } label: {
                                    Label(english ? "Read step" : "Schritt vorlesen", systemImage: "speaker.wave.2")
                                }.buttonStyle(.borderless)
                            }.font(.callout)
                        }.padding(CompanionLayout.panelInset).frame(maxWidth: .infinity, alignment: .leading).companionPanel()
                    }
                }
                }
                note(english ? "Scope & open questions" : "Grenzen & offene Punkte", tip.limitations.value(english))
                DisclosureGroup(english ? "Evidence & source" : "Belege & Quelle") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(tip.isCurated ? (english ? "The review method and inspected sections are documented below. Visual samples are not a complete motion review or an independent in-game test." : "Prüfmethode und gesichtete Abschnitte sind unten dokumentiert. Bildstichproben ersetzen keine vollständige Bewegungsanalyse und keinen unabhängigen Spieltest.") : (english ? "Channel entry from public title and description. Available captions are indexed automatically; content review is still pending." : "Kanaleintrag aus öffentlichem Titel und Beschreibung. Verfügbare Untertitel sind automatisch indexiert; die inhaltliche Auswertung steht noch aus."))
                        Text(tip.visualReview.value(english))
                        Link(tip.originalTitle, destination: tip.videoURL)
                        ForEach(tip.relatedSources.indices, id: \.self) { i in Link(tip.relatedSources[i].title, destination: tip.relatedSources[i].url) }
                    }.font(.caption).foregroundStyle(.secondary).padding(.top, 12)
                }.padding(CompanionLayout.panelInset).companionPanel()
            }.padding(CompanionLayout.pageInset).frame(maxWidth: 1000, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
        }.onAppear { audioLanguage = english ? "en" : "de" }
            .onChange(of: audioLanguage) { _, _ in speech.stop() }
            .onChange(of: query) { _, _ in transcriptLimit = 40 }
            .onDisappear { speech.stop() }
    }
    private func exportVideo() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.nameFieldStringValue = "RealmCraft-Video-\(tip.videoID)-\(english ? "en" : "de").md"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            _ = try MarkdownExportPackage.write(markdown: VideoKnowledgeExport.markdown([tip], english: english), videoMarkdown: nil, to: url, library: UserDefaults.standard.string(forKey: "libraryPath").map { URL(fileURLWithPath: $0) } ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/RealmCraftLibrary/Savegames"))
            exportNotice = (english ? "Saved: " : "Gespeichert: ") + url.path
        } catch { exportNotice = error.localizedDescription }
    }
    private func note(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(text).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}


struct BuildGuidesView: View {
    let language: String
    @State private var source = "videos"
    var body: some View {
        VStack(spacing: 0) {
            Picker(language == "en" ? "Guide library" : "Anleitungssammlung", selection: $source) {
                Text(language == "en" ? "Videos & tips" : "Videos & Tipps").tag("videos")
                Text(language == "en" ? "Offline test builds" : "Offline-Testaufbauten").tag("builds")
            }.pickerStyle(.segmented).frame(maxWidth: 500).padding(12)
            if source == "videos" { VideoTipsView(language: language) }
            else { OfflineBuildGuidesView(language: language) }
        }
    }
}
