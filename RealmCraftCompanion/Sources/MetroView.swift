import SwiftUI
import AppKit

struct MetroView: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    let language: String
    @State private var draftID = UUID()
    @State private var draftBaseline = ""
    @State private var lastSaveSucceeded = false
    @State private var compactPane = "map"
    private var draftToken: String {
        switch tool {
        case "assistant": return DraftTransitions.fingerprint([String(describing: autoPins), autoLayout.rawValue, String(autoRings), String(autoSpacing), autoSelected ?? "", autoPinName, autoPinDimension, String(autoPinX), String(autoPinY), String(autoPinZ)])
        case "station": return DraftTransitions.fingerprint(stationDraft)
        case "line": return DraftTransitions.fingerprint(lineDraft)
        case "edge": return DraftTransitions.fingerprint([DraftTransitions.fingerprint(edgeDraft), duration, DraftTransitions.fingerprint(pathPoints), String(recording)])
        default: return DraftTransitions.fingerprint([journeyFrom, journeyTo, journeyName])
        }
    }
    private var dirty: Bool { !draftBaseline.isEmpty && draftBaseline != draftToken }
    private func markClean() { draftBaseline = draftToken; model.drafts.remove(draftID) }
    private func transition(_ action: () -> Void) { model.drafts.perform(action) }
    private func saveActiveDraft() -> Bool {
        lastSaveSucceeded = false
        switch tool {
        case "assistant": applyAutoProposal()
        case "station": saveStation()
        case "line": saveLine()
        case "edge":
            guard !recording else { message = t("Zuerst die Streckenerfassung abschließen.", "Finish path recording before saving."); return false }
            saveEdge()
        default: saveJourney()
        }
        if lastSaveSucceeded { markClean() }
        return lastSaveSucceeded
    }
    private func saveLine() {
        var copy = network; copy.lines.removeAll { $0.id == lineDraft.id }; copy.lines.append(lineDraft)
        if commit(copy) { filterLine = lineDraft.id; markClean() }
    }
    @State private var network = MetroNetworkStore.Document(stations: [], lines: [], edges: [])
    @State private var loadedSave: String?
    @State private var loadFailed = false
    @State private var message: String?
    @State private var mode = "diagram"
    @State private var tool = "station"
    @State private var query = ""
    @State private var filterLine: String?
    @State private var selectedStation: String?
    @State private var stationDraft = MetroStation(id: UUID().uuidString, name: "", dimension: "n", x: 0, y: 32, z: 0, status: .planned)
    @State private var lineDraft = MetroLine(id: UUID().uuidString, name: "", color: "#A8CF6E")
    @State private var edgeDraft = MetroEdge(id: UUID().uuidString, from: "", to: "", lineID: nil, mode: .rail, status: .planned, lengthBlocks: 0, durationSeconds: nil, note: "")
    @State private var duration = ""
    @State private var recording = false
    @State private var pathPoints: [MetroPoint] = []
    @State private var radius = "128"
    @State private var portals: [SavedPortal] = []
    @State private var portalError: String?
    @State private var journeyFrom = ""
    @State private var journeyTo = ""
    @State private var deleteID: String?
    @State private var deleteLine = false
    @State private var step = 0
    @State private var radialDirection = "N"
    @State private var radialCount = 2
    @State private var radialSpacing = 128
    @State private var showCarryForward = false
    @State private var journeys = MetroJourneyJournal()
    @State private var journeyID = ""
    @State private var journeyName = ""
    @State private var journeyLoadFailed = false
    @State private var autoPins: [MetroPlanPin] = []
    @State private var autoLayout = MetroPlanLayout.combined
    @State private var autoRings = 2
    @State private var autoSpacing = 128
    @State private var autoProposals: [MetroPlanProposal] = []
    @State private var autoSelected: String?
    @State private var autoBaseline: MetroNetworkStore.Document?
    @State private var autoPinName = ""
    @State private var autoPinDimension = "n"
    @State private var autoPinX = 0
    @State private var autoPinY = 32
    @State private var autoPinZ = 0
    @Environment(\.companionTheme) private var theme
    private var en: Bool { language == "en" }
    private func t(_ de: String, _ english: String) -> String { en ? english : de }
    private var store: MetroNetworkStore? {
        guard let save = model.selected else { return nil }
        return MetroNetworkStore(url: model.library.root.appendingPathComponent(".metro-networks").appendingPathComponent(save.id + ".json"))
    }
    private var editable: Bool { store != nil && loadedSave == model.selection && !loadFailed && !model.busy }
    private var journeyStore: PlanningStore<MetroJourneyJournal>? {
        model.selected.map { PlanningStore(url: model.library.root.appendingPathComponent(".metro-journeys").appendingPathComponent($0.id + ".json"), empty: MetroJourneyJournal()) }
    }
    private var activeJourney: MetroJourney? { journeys.journeys.first { $0.id == journeyID } }
    private var route: MetroRoute? {
        if let saved = activeJourney, let save = model.selected { return try? saved.route(in: network, saveID: save.id, world: save.world) }
        return MetroNetworkStore.route(network, from: journeyFrom, to: journeyTo)
    }
    private var mapDocument: MetroNetworkStore.Document {
        if tool == "assistant" {
            if let proposal = autoProposals.first(where: { $0.id == autoSelected }) { return proposal.network }
            var preview = network
            for pin in autoPins where !preview.stations.contains(where: { $0.dimension == pin.dimension && MetroPoint($0) == pin.point }) {
                preview.stations.append(MetroStation(id: pin.id, name: pin.name, dimension: pin.dimension, x: pin.point.x, y: pin.point.y, z: pin.point.z, status: .planned))
            }
            return preview
        }
        guard recording, pathPoints.count >= 2 else { return network }
        var preview = network
        var edge = edgeDraft; edge.path = pathPoints; edge.status = .planned
        // Separate display-only endpoint: never move an existing station in the preview.
        if let last = pathPoints.last, let start = network.stations.first(where: { $0.id == edge.from }) {
            let endpoint = MetroStation(id: "metro-draft-endpoint", name: t("Streckenentwurf", "Path draft"), dimension: start.dimension, x: last.x, y: last.y, z: last.z, status: .planned)
            preview.stations.append(endpoint); edge.to = endpoint.id
        }
        preview.edges.removeAll { $0.id == edge.id }; preview.edges.append(edge)
        return preview
    }
    private var visibleStations: [MetroStation] {
        network.stations.filter { station in
            (filterLine == nil || network.servingLines(station.id).contains { $0.id == filterLine }) &&
            (query.isEmpty || (station.name + " " + (station.destination ?? "")).localizedCaseInsensitiveContains(query))
        }.sorted { ($0.dimension, $0.name) < ($1.dimension, $1.name) }
    }

    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: t("Nether-Metro", "Nether Metro")) {
                HStack(spacing: CompanionLayout.actionSpacing) {
                    Button(t("Netz-Assistent", "Network assistant")) { transition { tool = "assistant"; compactPane = "editor"; filterLine = nil; markClean() } }
                        .buttonStyle(CompanionButtonStyle()).disabled(!editable)
                    Button(t("Reise planen", "Plan journey")) { transition { tool = "journey"; compactPane = "editor"; markClean() } }.disabled(network.stations.count < 2)
                    Button(t("Station hinzufügen", "Add station"), action: { transition { newStation() } })
                        .buttonStyle(CompanionButtonStyle(prominent: true)).disabled(!editable)
                }
            } menu: {
                Button(t("Neu laden", "Reload"), action: { transition { load() } })
                Button(t("Netz aus älterer Sicherung übernehmen…", "Carry forward network from older backup…")) { transition { showCarryForward = true } }
                    .disabled(!editable || !network.stations.isEmpty || !network.lines.isEmpty || !network.edges.isEmpty)
                Button(t("Netz als JSON exportieren…", "Export network JSON…"), action: exportNetwork).disabled(!editable)
            }
            sourceBar
            if model.selected != nil && network.stations.count < 2 {
                CompanionNotice(message: t("Start: Stationen hinzufügen → verbinden → Messungen bestätigen → Reise planen. Geplante Verbindungen werden nicht für Routen verwendet.", "Start: add stations → connect → confirm measurements → plan a journey. Planned connections are not used for routing."), kind: .information)
                    .padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 8)
            }
            Divider()
            if let message {
                HStack { Image(systemName: "info.circle"); Text(message).textSelection(.enabled); Spacer(); Button { self.message = nil } label: { Image(systemName: "xmark") } }
                    .font(.caption).padding(10).background(theme.accent.opacity(0.08))
            }
            if model.selected == nil {
                ContentUnavailableView(t("Wähle eine Sicherung", "Choose a savegame"), systemImage: "archivebox",
                    description: Text(t("Dein Netz wird für diese Sicherung gespeichert.", "Your network is saved for this snapshot.")))
            } else {
                GeometryReader { geometry in
                    if geometry.size.width >= 1080 {
                        HSplitView {
                            directory.frame(minWidth: 185, idealWidth: 220, maxWidth: 280)
                            workspace.frame(minWidth: 350, maxWidth: .infinity, maxHeight: .infinity)
                            inspector.frame(minWidth: 270, idealWidth: 300, maxWidth: 380)
                        }
                    } else {
                        VStack(spacing: 0) {
                            CompanionEqualSegments(title: t("Ansicht", "View"), selection: $compactPane,
                                options: [("list", t("Stationen & Linien", "Stations & lines")),
                                          ("map", t("Karte & Netz", "Map & network")),
                                          ("editor", t("Bearbeiten & Reisen", "Edit & travel"))])
                                .companionActionAligned()
                                .padding(.horizontal, CompanionLayout.pageInset).padding(.vertical, 12)
                            if compactPane == "list" { directory }
                            else if compactPane == "editor" { inspector }
                            else { workspace }
                        }
                    }
                }
            }
            if dirty { Label(t("Ungespeicherter Entwurf", "Unsaved draft"), systemImage: "pencil.circle").font(.caption).foregroundStyle(.orange).padding(8) }
            footer
        }
        .trackDraft(model.drafts, id: draftID, token: draftToken, dirty: { dirty }, title: t("Metro-Entwurf", "Metro draft"), save: saveActiveDraft, discard: load)
        .onAppear { load(); maps.check(model); restoreMap(); markClean() }
        .sheet(isPresented: $showCarryForward) {
            if let target = model.selected { MetroCarryForwardView(model: model, target: target, english: en, completed: load).companionAppearance() }
        }
        .onChange(of: model.library.root.path + ":" + (model.selection ?? "")) { _, _ in load(); restoreMap() }
        .onChange(of: radius) { _, _ in restoreMap() }
        .onChange(of: language) { _, _ in restoreMap() }
        .onChange(of: tool) { _, value in if value != "edge" { recording = false }; if value == "journey" { filterLine = nil } }
        .confirmationDialog(t("Station löschen?", "Delete station?"), isPresented: Binding(get: { deleteID != nil }, set: { if !$0 { deleteID = nil } }), titleVisibility: .visible) {
            Button(t("Station und Verbindungen löschen", "Delete station and connections"), role: .destructive, action: deleteStation)
        } message: {
            let affected = network.edges.filter { $0.from == deleteID || $0.to == deleteID }
            Text("\(affected.count) " + t("Verbindungen werden entfernt: ", "connections will be removed: ") + affected.map { stationName($0.from) + " → " + stationName($0.to) }.joined(separator: ", "))
        }
        .confirmationDialog(t("Linie entfernen?", "Remove line?"), isPresented: $deleteLine, titleVisibility: .visible) {
            Button(t("Linie entfernen", "Remove line"), role: .destructive) {
                var copy = network; copy.lines.removeAll { $0.id == lineDraft.id }
                for index in copy.edges.indices where copy.edges[index].lineID == lineDraft.id { copy.edges[index].lineID = nil }
                if commit(copy) { filterLine = nil; lineDraft = .init(id: UUID().uuidString, name: "", color: "#54C9DF"); markClean() }
            }
        } message: { Text(t("Stationen und Verbindungen bleiben erhalten; nur ihre Linienzuordnung entfällt.", "Stations and connections are retained; only their line assignment is removed.")) }
    }

    private var sourceBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            SourceContextBar(saves: model.saves, selection: $model.selection, language: language)
            HStack(spacing: 14) {
            Spacer()
            Label("\(network.stations.count)", systemImage: "mappin.and.ellipse")
            Label("\(network.lines.count)", systemImage: "tram.fill")
            Label("\(network.edges.filter { $0.status == .confirmed }.count)/\(network.edges.count)", systemImage: "checkmark.seal")
            }
        }.font(.callout).padding(.horizontal, 28).padding(.bottom, 14)
    }
    private var directory: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text(t("LINIEN", "LINES")).font(.caption.bold()).tracking(1.5); Spacer(); Button { transition { lineDraft = .init(id: UUID().uuidString, name: "", color: "#54C9DF"); tool = "line"; compactPane = "editor"; markClean() } } label: { Image(systemName: "plus") }.disabled(!editable) }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack { Button(t("Alle", "All")) { filterLine = nil }
                    ForEach(network.lines) { line in
                        Button { transition { filterLine = line.id; lineDraft = line; tool = "line"; compactPane = "editor"; markClean() } } label: { lineBadge(line) }
                            .buttonStyle(.plain).padding(3).background(filterLine == line.id ? theme.accent.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 5))
                    }
                }
            }
            Divider()
            TextField(t("Station oder Ziel suchen", "Find station or destination"), text: $query).textFieldStyle(.roundedBorder)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if visibleStations.isEmpty { Text(t("Noch keine Stationen. Beginne am Hauptportal.", "No stations yet. Start at your main portal.")).font(.callout).foregroundStyle(.secondary).padding(.vertical, 16) }
                    ForEach(visibleStations) { station in
                        Button { transition { select(station) } } label: {
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: station.id == network.originID ? "star.circle.fill" : station.portalID != nil || station.portalCandidate == true ? "door.left.hand.open" : "circle")
                                    .foregroundStyle(station.id == network.originID ? theme.accent : .secondary).padding(.top, 2)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(station.name).font(.callout.weight(.semibold)).lineLimit(2)
                                    Text("\(dim(station.dimension)) · \(station.x), \(station.z)").font(.caption.monospaced()).foregroundStyle(.secondary)
                                    HStack(spacing: 4) { ForEach(network.servingLines(station.id)) { lineBadge($0) }; statusBadge(station.status) }
                                }
                                Spacer(minLength: 0)
                            }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedStation == station.id ? theme.accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 6))
                        }.buttonStyle(.plain)
                    }
                }
            }
            Divider()
            if let origin = network.origin { Label(origin.name, systemImage: "star.fill").font(.caption).foregroundStyle(theme.accent) }
            else { Label(t("Hauptportal festlegen", "Set your main portal"), systemImage: "star").font(.caption).foregroundStyle(.secondary) }
        }.padding(14).background(theme.surface)
    }
    private var workspace: some View {
        VStack(spacing: 0) {
            HStack {
                Picker(t("Ansicht", "View"), selection: $mode) {
                    Text(t("Netzplan", "Network")).tag("diagram")
                    Text(t("Weltkarte", "World map")).tag("map")
                }.pickerStyle(.segmented).frame(maxWidth: 260)
                Spacer(minLength: 8)
                if mode == "diagram" { Text(t("Schematisch", "Schematic")).font(.caption).foregroundStyle(.secondary) }
            }.padding(14)
            Divider()
            if mode == "diagram" {
                if network.stations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tram.fill").font(.system(size: 48, weight: .light)).foregroundStyle(theme.accent)
                        Text(t("Dein Nether. Verbunden.", "Your Nether. Connected.")).font(.title2.weight(.semibold))
                        Text(t("Starte am Hauptportal. Plane farbige Linien, verbinde Stationen und teste deine erste Reise.", "Start at the main portal. Plan colored lines, connect stations and test your first journey."))
                            .foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 320)
                        Button(t("Portal auf Karte wählen", "Choose portal on map")) { mode = "map" }.buttonStyle(CompanionButtonStyle(prominent: true))
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    MetroDiagram(network: mapDocument, selected: selectedStation, lineID: filterLine,
                        routeIDs: tool == "journey" ? Set(route?.edges.map(\.id) ?? []) : [], english: en, choose: { station in
                            if tool == "assistant" { selectedStation = station.id }
                            else { transition { select(station) } }
                        })
                }
            } else {
                mapPane
            }
            Divider()
            HStack(spacing: 12) {
                statusBadge(.planned); statusBadge(.built); statusBadge(.confirmed)
                Spacer(); Image(systemName: "circle.circle"); Text(t("Umstieg", "Transfer"))
            }.font(.caption2).padding(12)
        }
    }
    private var mapPane: some View {
        VStack(spacing: 0) {
            HStack {
                Picker(t("Bereich", "Area"), selection: $radius) {
                    Text("±128").tag("128"); Text("±512").tag("512"); Text("±2048").tag("2048"); Text(t("Alle Chunks", "All chunks")).tag("all")
                }.frame(maxWidth: 230)
                Button(t("Karte erzeugen", "Generate map")) {
                    if let save = model.selected { maps.generate(model, save: save, radius: radius, language: language) }
                }.disabled(!maps.ready || !editable)
            }.padding(10)
            if let url = maps.mapURL {
                LocalMapWebView(url: url, world: model.selected?.world ?? "", scope: model.selected?.annotationScope ?? "",
                    library: model.library.root, english: en, saveID: model.selected?.id ?? "",
                    worldFolder: model.selected.map { model.library.worldFolder($0) }, openPortals: {}, openOreAnalysis: {},
                    metroWorkspace: true, metroDocument: mapDocument, metroFocus: selectedStation, metroPick: pick,
                    metroCapturing: recording, metroCancel: { recording = false; pathPoints = [] })
                    .id(url)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "map").font(.largeTitle).foregroundStyle(theme.accent)
                    Text(t("Gemeinsame Kartenbasis", "Shared world map")).font(.headline)
                    Text(t("Erzeuge einmal eine Karte für diesen Bereich. Metro und Atlas verwenden dieselben Kacheln.", "Generate a map for this area once. Metro and Atlas use the same tiles.")).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    if !maps.ready { MapToolsSetup(model: model, maps: maps, english: en) }
                }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if !maps.notice.isEmpty || model.busy { Text(model.busy ? model.status : maps.notice).font(.caption).padding(8) }
        }
    }
    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if tool != "assistant" {
                    Picker(t("Werkzeug", "Tool"), selection: Binding(get: { tool }, set: { value in transition { tool = value; markClean() } })) {
                        Text(t("Station", "Station")).tag("station"); Text(t("Linie", "Line")).tag("line")
                        Text(t("Strecke", "Link")).tag("edge"); Text(t("Reise", "Trip")).tag("journey")
                    }.pickerStyle(.segmented).companionField(t("Werkzeug", "Tool"))
                    Button(t("Automatisch planen", "Auto-plan")) { transition { tool = "assistant"; markClean() } }
                        .buttonStyle(CompanionButtonStyle())
                } else {
                    Button(t("Zur manuellen Planung", "Back to manual planning")) { transition { tool = "station"; markClean() } }
                        .buttonStyle(CompanionButtonStyle())
                }
                if tool == "station" { stationEditor }
                if tool == "line" { lineEditor }
                if tool == "edge" { edgeEditor }
                if tool == "journey" { journeyEditor }
                if tool == "assistant" { autoPlannerEditor }
            }.frame(maxWidth: CompanionLayout.readingWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading).padding(CompanionLayout.pageInset)
        }.background(theme.surface).disabled(!editable)
    }
    private var stationEditor: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(network.stations.contains { $0.id == stationDraft.id } ? t("Station bearbeiten", "Edit station") : t("Neue Station", "New station")).font(.title3.bold())
            TextField(t("Stationsname", "Station name"), text: $stationDraft.name)
            Button(t("Namen vorschlagen", "Suggest name")) {
                stationDraft.name = MetroNaming.stationName(x: stationDraft.x, z: stationDraft.z, existing: network.stations, origin: network.origin)
            }
            CompanionPopup(title: t("Dimension", "Dimension"), selection: $stationDraft.dimension, options: [("n", "Nether"), ("o", t("Oberwelt", "Overworld"))]).companionField(t("Dimension", "Dimension"))
            coordinateFields
            TextField(t("Ziel / Biom (eigene Angabe)", "Destination / biome (your note)"), text: Binding(get: { stationDraft.destination ?? "" }, set: { stationDraft.destination = $0 }))
            statusPicker($stationDraft.status)
            Toggle(t("Geplanter Portalstandort", "Proposed portal site"), isOn: Binding(get: { stationDraft.portalCandidate == true }, set: { stationDraft.portalCandidate = $0 }))
            Button(t("Station speichern", "Save station"), action: { _ = saveActiveDraft() }).buttonStyle(CompanionButtonStyle(prominent: true))
            if network.stations.contains(where: { $0.id == stationDraft.id }) {
                Button(t("Als Hauptportal setzen", "Set as main portal")) { var copy = network; copy.originID = stationDraft.id; _ = commit(copy) }.disabled(stationDraft.dimension != "n")
                HStack {
                    Button(t("Strecke ab hier", "Connect from here")) { transition { newEdge(from: stationDraft.id) } }
                    Button(t("Schild kopieren", "Copy sign")) { copySign() }
                }
                Button(t("Station löschen…", "Delete station…"), role: .destructive) { transition { deleteID = stationDraft.id } }
                connectionsForStation
            }
            Divider()
            DisclosureGroup(t("Gespeicherte Portale", "Saved portals")) {
                if let portalError { Text(portalError).font(.caption).foregroundStyle(.orange) }
                if portals.isEmpty && portalError == nil { Text(t("Keine Portale erfasst.", "No portals recorded.")).font(.caption) }
                ForEach(portals) { portal in
                    Button {
                        guard model.drafts.authorize() else { return }
                        if let existing = network.stations.first(where: { $0.portalID == portal.id }) { select(existing); return }
                        newStation()
                        stationDraft = .init(id: UUID().uuidString, name: "", dimension: portal.dimension, x: portal.anchor.x, y: portal.anchor.y, z: portal.anchor.z, status: .built, portalID: portal.id)
                        selectedStation = nil
                    } label: { Label("\(dim(portal.dimension)) · \(portal.anchor.text)", systemImage: "door.left.hand.open") }
                }
            }
        }.textFieldStyle(.roundedBorder)
    }
    private var coordinateFields: some View {
        HStack {
            VStack(alignment: .leading) { Text("X").font(.caption); TextField("X", value: $stationDraft.x, format: .number.grouping(.never)) }
            VStack(alignment: .leading) { Text("Y").font(.caption); TextField("Y", value: $stationDraft.y, format: .number.grouping(.never)) }
            VStack(alignment: .leading) { Text("Z").font(.caption); TextField("Z", value: $stationDraft.z, format: .number.grouping(.never)) }
        }.monospacedDigit()
    }
    private var connectionsForStation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t("Verbindungen", "Connections")).font(.headline)
            ForEach(network.edges.filter { $0.from == stationDraft.id || $0.to == stationDraft.id }) { edge in
                Button { editEdge(edge) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stationName(edge.from) + " → " + stationName(edge.to)).font(.caption)
                        HStack { statusBadge(edge.status); Text(edge.durationSeconds.map { "\($0) s" } ?? "—").font(.caption) }
                    }
                }
            }
        }
    }
    private var lineEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("Linie gestalten", "Design your line")).font(.title3.bold())
            TextField(t("Linienname", "Line name"), text: $lineDraft.name)
            ColorPicker(t("Linienfarbe", "Line color"), selection: Binding(get: { Color(metroHex: lineDraft.color) }, set: { lineDraft.color = $0.metroHex }), supportsOpacity: false)
            Button(t("Kennung vorschlagen", "Suggest identifier")) {
                guard let target = network.stations.first(where: { $0.id == selectedStation }), target.dimension == "n", let origin = network.origin, target.id != origin.id else {
                    message = t("Hauptportal und eine andere Netherstation wählen. Die Richtung wird relativ zum Hauptportal bestimmt.", "Choose the main portal and another Nether station. Direction is relative to the main portal."); return
                }
                lineDraft.name = MetroNaming.lineName(from: target, existing: network.lines, origin: origin)
            }
            Text(t("N −Z · S +Z · E +X · W −X\nStationsnamen bleiben von Linienkennungen getrennt.", "N −Z · S +Z · E +X · W −X\nStation names are independent of line identifiers.")).font(.caption).foregroundStyle(.secondary)
            Button(t("Linie speichern", "Save line")) {
                _ = saveActiveDraft()
            }.buttonStyle(CompanionButtonStyle(prominent: true))
            if network.lines.contains(where: { $0.id == lineDraft.id }) {
                Button(t("Linie entfernen…", "Remove line…"), role: .destructive) { transition { deleteLine = true } }
            }
            ForEach(network.edges.filter { $0.lineID == lineDraft.id }) { edge in
                Button(stationName(edge.from) + " → " + stationName(edge.to)) { editEdge(edge) }
            }
            Divider()
            DisclosureGroup(t("Radiale Linie planen", "Plan a radial line")) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker(t("Richtung", "Direction"), selection: $radialDirection) { ForEach(["N", "S", "E", "W"], id: \.self) { Text($0).tag($0) } }
                    Stepper(t("\(radialCount) Stationen", "\(radialCount) stations"), value: $radialCount, in: 1...16)
                    TextField(t("Abstand in Blöcken", "Spacing in blocks"), value: $radialSpacing, format: .number.grouping(.never))
                    Text(t("Ab Hauptportal auf dessen Höhe. Alle Vorschläge bleiben geplant; Gegenportale werden nicht berechnet.", "From the main portal at its height. All proposals remain planned; counterpart portals are not predicted.")).font(.caption).foregroundStyle(.secondary)
                    Button(t("Vorschläge ins Netz aufnehmen", "Add proposals to network")) {
                        do {
                            var line = lineDraft
                            if line.name.isEmpty { var n = 1; while network.lines.contains(where: { $0.name == "\(radialDirection)\(n)" }) { n += 1 }; line.name = "\(radialDirection)\(n)" }
                            let proposal = try network.extending(direction: radialDirection, spacing: radialSpacing, count: radialCount, line: line)
                            if commit(proposal) { lineDraft = line; filterLine = line.id; mode = "diagram"; markClean() }
                        } catch { message = t("Hauptportal, Abstand und Linie prüfen.", "Check the main portal, spacing and line.") }
                    }.disabled(network.origin == nil)
                }.padding(.top, 8)
            }
        }.textFieldStyle(.roundedBorder)
    }
    private var edgeEditor: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(t("Gerichtete Strecke", "Directed connection")).font(.title3.bold())
            CompanionPopup(title: t("Von", "From"), selection: $edgeDraft.from, options: stationChoices).companionField(t("Von", "From"))
            CompanionPopup(title: t("Nach", "To"), selection: $edgeDraft.to, options: stationChoices).companionField(t("Nach", "To"))
            CompanionPopup(title: t("Linie", "Line"), selection: $edgeDraft.lineID,
                options: [(nil, "—")] + network.lines.map { (Optional($0.id), $0.name) }).companionField(t("Linie", "Line"))
            CompanionPopup(title: t("Art", "Mode"), selection: $edgeDraft.mode,
                options: [(.rail, t("Schiene", "Rail")), (.portal, "Portal"), (.walk, t("Fußweg", "Walk"))]).companionField(t("Art", "Mode"))
            statusPicker($edgeDraft.status)
            HStack {
                VStack(alignment: .leading) { Text(t("Länge · Blöcke", "Length · blocks")).font(.caption); TextField("0", value: $edgeDraft.lengthBlocks, format: .number.grouping(.never)) }
                VStack(alignment: .leading) { Text(t("Gemessen · s", "Measured · s")).font(.caption); TextField("—", text: $duration) }
            }
            TextField(t("Nachweis / Notiz", "Evidence / note"), text: $edgeDraft.note, axis: .vertical).lineLimit(2...4)
            if edgeDraft.mode != .portal {
                Button(recording ? t("Erfassung abschließen", "Finish geometry") : t("Verlauf auf Karte erfassen", "Record path on map")) { toggleRecording() }
                if recording { Text(t("Klicke die Kurvenpunkte in Fahrtrichtung. Start und Ziel werden ergänzt.", "Click bends in travel order. Start and end stations are included.")).font(.caption).foregroundStyle(theme.accent) }
                HStack {
                    Text("\(pathPoints.count) " + t("Streckenpunkte", "path points")).font(.caption)
                    Spacer()
                    Button(t("Zurück", "Undo point")) { if !pathPoints.isEmpty { pathPoints.removeLast() } }.disabled(!recording || pathPoints.count <= 1)
                    Button(t("Leeren", "Clear")) { pathPoints = []; edgeDraft.path = nil; recording = false }
                }
            }
            Button(t("Strecke speichern", "Save connection"), action: { _ = saveActiveDraft() }).buttonStyle(CompanionButtonStyle(prominent: true)).disabled(recording)
            if network.edges.contains(where: { $0.id == edgeDraft.id }) {
                Button(t("Rückweg separat planen", "Plan reverse separately")) {
                    guard model.drafts.authorize() else { return }
                    edgeDraft = .init(id: UUID().uuidString, from: edgeDraft.to, to: edgeDraft.from, lineID: edgeDraft.lineID, mode: edgeDraft.mode, status: .planned, lengthBlocks: edgeDraft.lengthBlocks, durationSeconds: nil, note: "")
                    duration = ""; pathPoints = []; recording = false
                }
                Button(t("Verbindung entfernen", "Remove connection"), role: .destructive) {
                    guard model.drafts.authorize() else { return }
                    var copy = network; copy.edges.removeAll { $0.id == edgeDraft.id }; if commit(copy) { newEdge(from: selectedStation ?? "") }
                }
            }
            Text(t("Jede Fahrtrichtung wird einzeln bestätigt. Erfasste Punkte sind dein dokumentierter Verlauf, keine automatische Gleiserkennung.", "Confirm each direction separately. Recorded points describe your documented path; automatic rail detection is not yet connected.")).font(.caption).foregroundStyle(.secondary)
        }.textFieldStyle(.roundedBorder)
        .onChange(of: edgeDraft.from) { _, _ in clearPathIfEndpointsChanged() }
        .onChange(of: edgeDraft.to) { _, _ in clearPathIfEndpointsChanged() }
    }
    private var journeyEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("Deine Reise", "Your journey")).font(.title3.bold())
            if !journeys.journeys.isEmpty {
                CompanionPopup(title: t("Gespeicherte Reise", "Saved journey"), selection: Binding(get: { journeyID }, set: { value in transition { resumeJourney(value); markClean() } }),
                    options: [("", t("Neue Reise", "New journey"))] + journeys.journeys.map { ($0.id, $0.name) }).companionField(t("Gespeicherte Reise", "Saved journey"))
            }
            CompanionPopup(title: t("Start", "Start"), selection: Binding(get: { journeyFrom }, set: { journeyFrom = $0; journeyID = ""; step = 0 }), options: stationChoices).companionField(t("Start", "Start"))
            CompanionPopup(title: t("Ziel", "Destination"), selection: Binding(get: { journeyTo }, set: { journeyTo = $0; journeyID = ""; step = 0 }), options: stationChoices).companionField(t("Ziel", "Destination"))
            TextField(t("Name der Reise", "Journey name"), text: $journeyName).textFieldStyle(.roundedBorder)
            Button(t("Als neue Reise speichern", "Save as new journey"), action: saveJourney).disabled(route == nil || !editable || journeyLoadFailed)
            if activeJourney != nil {
                Text(t("Fortschritt gespeichert: \(step) bestätigte Abschnitte. Vor dem Fortsetzen tatsächliche Position und Dimension prüfen.", "Progress saved: \(step) confirmed legs. Check actual position and dimension before resuming.")).font(.caption)
                if route == nil {
                    Text(t("Netzstand geändert. Gespeicherte Reise bleibt erhalten; Start/Ziel für eine neue Planung wählen.", "Network changed. Saved journey is retained; choose start/destination to replan.")).foregroundStyle(.orange)
                }
            }
            if let route {
                HStack { Label(time(route.totalSeconds ?? 0), systemImage: "clock"); Label("\(route.transfers)", systemImage: "arrow.triangle.swap") }.font(.headline)
                Text("\(route.totalBlocks) " + t("dokumentierte Blöcke · Summe gemessener Zeiten", "recorded blocks · sum of measured times")).font(.caption).foregroundStyle(.secondary)
                ForEach(Array(route.edges.enumerated()), id: \.element.id) { index, edge in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)").font(.caption.bold()).frame(width: 24, height: 24).background(index == step ? theme.accent : theme.border, in: Circle()).foregroundStyle(.black)
                        VStack(alignment: .leading, spacing: 5) {
                            if let line = network.lines.first(where: { $0.id == edge.lineID }) { lineBadge(line) }
                            Text(stationName(edge.from) + " → " + stationName(edge.to)).font(.callout.weight(.semibold))
                            Text("\(modeTitle(edge.mode)) · \(time(edge.durationSeconds ?? 0))").font(.caption).foregroundStyle(.secondary)
                            if let to = network.stations.first(where: { $0.id == edge.to }) { Text("\(dim(to.dimension)) · X \(to.x) / Y \(to.y) / Z \(to.z)").font(.caption.monospaced()) }
                        }
                    }.padding(10).frame(maxWidth: .infinity, alignment: .leading).background(index == step ? theme.accent.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 7))
                }
                Button(step >= route.edges.count ? t("Reise neu beginnen", "Restart journey") : t("Ankunft bestätigen", "Confirm arrival")) {
                    advanceJourney(route)
                }.disabled(!editable || journeyLoadFailed)
                Button(t("Navigation kopieren", "Copy navigation")) {
                    do {
                        let pack = try journeyExport(route)
                        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(pack.markdown, forType: .string)
                        message = t("Reisebriefing kopiert.", "Journey briefing copied.")
                    } catch { message = error.localizedDescription }
                }.buttonStyle(CompanionButtonStyle(prominent: true))
                Menu(t("Reise exportieren", "Export journey")) {
                    Button("JSON…") { exportJourney(route, json: true) }
                    Button("Markdown…") { exportJourney(route, json: false) }
                }.disabled(!editable)
            } else {
                Label(t("Noch keine bestätigte Route", "No confirmed route yet"), systemImage: "signpost.right").font(.headline)
                Text(t("Start, Ziel und Zwischenstationen müssen bestätigt sein. Jede gerichtete Verbindung benötigt eine gemessene Dauer.", "Start, destination and intermediate stations must be confirmed. Every directed connection needs a measured duration.")).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
    private var footer: some View {
        HStack {
            Label(t("Lokales Netz · pro Sicherung", "Local network · per snapshot"), systemImage: "externaldrive")
            Spacer()
            Text(t("Portalrouting: nur bestätigte Fahrten · keine 1:8-Prognose", "Portal routing: confirmed journeys only · no 8:1 prediction"))
        }.font(.caption2).foregroundStyle(.secondary).padding(.horizontal, 18).padding(.vertical, 9).background(theme.surface)
    }
    private var stationOptions: some View {
        Group { Text("—").tag(""); ForEach(network.stations) { Text($0.name + " · " + dim($0.dimension)).tag($0.id) } }
    }
    private var stationChoices: [(String, String)] {
        [("", "—")] + network.stations.map { ($0.id, $0.name + " · " + dim($0.dimension)) }
    }
    private func statusPicker(_ binding: Binding<MetroStatus>) -> some View {
        CompanionPopup(title: t("Nachweis", "Evidence"), selection: binding,
            options: [(.planned, t("Geplant", "Planned")), (.built, t("Gebaut", "Built")), (.confirmed, t("Bestätigt", "Confirmed"))]).companionField(t("Nachweis", "Evidence"))
    }
    private func lineBadge(_ line: MetroLine) -> some View {
        Text(line.name).font(.system(size: 10, weight: .bold)).padding(.horizontal, 7).padding(.vertical, 4)
            .foregroundStyle(Color(metroHex: line.color)).background(Color(metroHex: line.color).opacity(0.14), in: RoundedRectangle(cornerRadius: 4))
    }
    private func statusBadge(_ status: MetroStatus) -> some View {
        Text(status == .confirmed ? t("Bestätigt", "Confirmed") : status == .built ? t("Gebaut", "Built") : t("Geplant", "Planned"))
            .font(.system(size: 9, weight: .semibold)).foregroundStyle(status == .confirmed ? theme.accent : .secondary)
    }
    private func modeTitle(_ mode: MetroMode) -> String { mode == .rail ? t("Schiene", "Rail") : mode == .portal ? t("Portal", "Portal") : t("Zu Fuß", "Walk") }
    private func dim(_ dimension: String) -> String { dimension == "n" ? "Nether" : t("Oberwelt", "Overworld") }
    private func stationName(_ id: String) -> String { network.stations.first { $0.id == id }?.name ?? "—" }
    private func time(_ seconds: Int) -> String { "\(seconds / 60):" + String(format: "%02d", seconds % 60) }
    private func restoreMap() { maps.restoreLast(model.selected, radius: radius, language: language) }
    private func load() {
        defer { markClean() }
        network = .init(stations: [], lines: [], edges: []); selectedStation = nil; filterLine = nil; recording = false
        autoPins = []; autoProposals = []; autoSelected = nil; autoBaseline = nil
        lineDraft = .init(id: UUID().uuidString, name: "", color: "#54C9DF")
        edgeDraft = .init(id: UUID().uuidString, from: "", to: "", lineID: nil, mode: .rail, status: .planned, lengthBlocks: 0, durationSeconds: nil, note: "")
        pathPoints = []; duration = ""
        stationDraft = .init(id: UUID().uuidString, name: "", dimension: "n", x: 0, y: 32, z: 0, status: .planned)
        loadedSave = model.selection; loadFailed = false; portals = []; portalError = nil; message = nil
        journeyFrom = ""; journeyTo = ""; step = 0; deleteID = nil
        journeys = MetroJourneyJournal(); journeyID = ""; journeyName = ""; journeyLoadFailed = false
        guard let store, let save = model.selected else { tool = "station"; return }
        do { network = try store.load() } catch { loadFailed = true; message = error.localizedDescription }
        do { portals = try PortalReader.read(model.library.worldFolder(save)).portals } catch { portalError = t("Portalbestand konnte nicht gelesen werden.", "Saved portal inventory could not be read.") }
        if let first = network.origin ?? network.stations.first { select(first); journeyFrom = first.id } else { newStation() }
        do {
            if let journal = try journeyStore?.load() {
                guard journal.valid, journal.journeys.allSatisfy({ $0.saveID == save.id && $0.world == save.world }) else { throw PlanningError.invalid }
                journeys = journal
                if let id = journal.activeID { resumeJourney(id, persist: false) }
            }
        } catch { journeyLoadFailed = true; message = error.localizedDescription }
    }
    private func commit(_ proposal: MetroNetworkStore.Document) -> Bool {
        guard editable, let store else { message = t("Sicherung wählen oder nach Lesefehler neu laden.", "Choose a savegame or reload after a read error."); return false }
        do { try store.save(proposal, replacing: network); network = proposal; message = t("Gespeichert.", "Saved."); step = 0; lastSaveSucceeded = true; return true }
        catch { message = t("Nicht gespeichert. Daten prüfen; bei parallelen Änderungen zuerst neu laden. ", "Not saved. Check the data; reload if another window changed the network. ") + error.localizedDescription; return false }
    }

    private var autoPlannerEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(t("Netz-Assistent", "Network assistant"), systemImage: "sparkles").font(.title3.bold())
            Text(t("Vergleiche Bauentwürfe. Es wird nichts im Spiel gebaut; bestehende Verbindungen bleiben unverändert.", "Compare construction proposals. Nothing is built in the game; existing connections remain unchanged."))
                .font(.callout).foregroundStyle(.secondary)
            if network.origin == nil {
                CompanionNotice(message: t("Lege zuerst eine Nether-Station als Hauptportal fest.", "First set a Nether station as your main portal."), kind: .information)
            }
            CompanionPopup(title: t("Grundlage", "Layout"), selection: $autoLayout,
                options: [(.rings, t("Konzentrische Ringe", "Concentric rings")), (.targets, t("Ziel-Pins", "Target pins")), (.combined, t("Ringe und Ziele", "Rings and targets"))]).companionField(t("Grundlage", "Layout"))
            if autoLayout != .targets {
                Stepper(t("\(autoRings) Ringe", "\(autoRings) rings"), value: $autoRings, in: 1...8)
                TextField(t("Ringabstand in Blöcken", "Ring spacing in blocks"), value: $autoSpacing, format: .number.grouping(.never))
            }
            if autoLayout != .rings { autoPinEditor }
            Button(t("Drei Vorschläge erzeugen", "Generate three proposals")) {
                do {
                    autoProposals = try MetroAutoPlanner.proposals(base: network, pins: autoPins, layout: autoLayout, rings: autoRings, spacing: autoSpacing)
                    autoBaseline = network; autoSelected = autoProposals.first?.id; mode = "diagram"
                } catch { message = t("Eingaben prüfen: Hauptportal, Ziele und Abstand 16–4096. Das Gesamtnetz darf die Speichergrenzen nicht überschreiten.", "Check inputs: main portal, targets and spacing 16–4096. The complete network must fit the storage limits.") }
            }.buttonStyle(CompanionButtonStyle(prominent: true))
                .disabled(network.origin == nil || (autoLayout != .rings && autoPins.isEmpty))
            ForEach(autoProposals) { proposal in
                VStack(alignment: .leading, spacing: 8) {
                    Button { autoSelected = proposal.id } label: {
                        Label(autoTitle(proposal.strategy), systemImage: autoSelected == proposal.id ? "checkmark.circle.fill" : "circle")
                    }.buttonStyle(.plain).font(.headline)
                    Text(autoDescription(proposal.strategy)).font(.caption).foregroundStyle(.secondary)
                    Text(t("\(proposal.railBlocks) Schienenblöcke · \(proposal.addedStationIDs.count) neue Stationen · \(proposal.interchanges) Umstiege", "\(proposal.railBlocks) rail blocks · \(proposal.addedStationIDs.count) new stations · \(proposal.interchanges) interchanges"))
                        .font(.caption).fixedSize(horizontal: false, vertical: true)
                    Text(t("\(proposal.portalSites) neue Portalstandorte · \(proposal.unresolvedPins) Ziele ohne bestätigte Zuordnung", "\(proposal.portalSites) new portal sites · \(proposal.unresolvedPins) targets without confirmed mapping"))
                        .font(.caption).foregroundStyle(proposal.unresolvedPins > 0 ? .orange : .secondary)
                }.padding(12).frame(maxWidth: .infinity, alignment: .leading).companionPanel()
            }
            if !autoProposals.isEmpty {
                Button(t("Ausgewählten Entwurf übernehmen", "Apply selected proposal")) { _ = saveActiveDraft() }
                    .buttonStyle(CompanionButtonStyle(prominent: true))
                Text(t("Alle neuen Strecken sind geplant, nur in der gezeigten Richtung. Gelände, Portalstandorte und Fahrzeiten sind ungeprüft. Die Vorschau ist kein echter Schienenverlauf und keine Materialliste.", "All new links are planned, in the shown direction only. Terrain, portal sites and travel times are unverified. The preview is not a real rail trace or material list."))
                    .font(.caption).foregroundStyle(.orange)
            }
        }
        .onChange(of: autoLayout) { _, _ in invalidateAutoPreview() }
        .onChange(of: autoRings) { _, _ in invalidateAutoPreview() }
        .onChange(of: autoSpacing) { _, _ in invalidateAutoPreview() }
    }
    private var autoPinEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t("Ziele setzen", "Set targets")).font(.headline)
            Button(t("Mehrere Pins auf Karte setzen", "Place multiple pins on map")) { mode = "map"; compactPane = "map" }
            Text(t("Kartenklicks setzen Ziele, solange der Netz-Assistent aktiv ist. Für unbekannte Kartenbereiche Koordinaten und Höhe manuell eingeben.", "Map clicks add targets while the network assistant is active. For unknown map areas, enter coordinates and height manually."))
                .font(.caption).foregroundStyle(.secondary)
            TextField(t("Zielname (optional)", "Target name (optional)"), text: $autoPinName)
            CompanionPopup(title: t("Dimension", "Dimension"), selection: $autoPinDimension,
                options: [("n", "Nether"), ("o", t("Oberwelt", "Overworld"))]).companionField(t("Dimension", "Dimension"))
            HStack {
                TextField("X", value: $autoPinX, format: .number.grouping(.never))
                TextField("Y", value: $autoPinY, format: .number.grouping(.never))
                TextField("Z", value: $autoPinZ, format: .number.grouping(.never))
            }
            Button(t("Pin hinzufügen", "Add pin")) { addAutoPin(dimension: autoPinDimension, point: MetroPoint(x: autoPinX, y: autoPinY, z: autoPinZ)) }
            ForEach(autoPins) { pin in
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        TextField(t("Zielname", "Target name"), text: Binding(get: { autoPins.first { $0.id == pin.id }?.name ?? "" }, set: { value in
                            if let i = autoPins.firstIndex(where: { $0.id == pin.id }) { autoPins[i].name = value; invalidateAutoPreview() }
                        }))
                        Text("\(dim(pin.dimension)) · X \(pin.point.x) / Y \(pin.point.y) / Z \(pin.point.z)").font(.caption.monospaced())
                    }
                    Button { autoPins.removeAll { $0.id == pin.id }; invalidateAutoPreview() } label: { Image(systemName: "minus.circle") }
                        .help(t("Pin entfernen", "Remove pin"))
                }
            }
            Text(t("Oberwelt-Ziele nutzen nur bereits bestätigte, gemessene Portalverbindungen. Ohne diese Evidenz bleibt das Ziel unverbunden; keine 1:8-Umrechnung.", "Overworld targets use only existing confirmed, measured portal connections. Without that evidence the target remains disconnected; no 1:8 conversion."))
                .font(.caption).foregroundStyle(.orange)
        }
    }
    private func invalidateAutoPreview() { autoProposals = []; autoSelected = nil; autoBaseline = nil }
    private func addAutoPin(dimension: String, point: MetroPoint) {
        guard point.valid, autoPins.count < 32 else { message = t("Höchstens 32 gültige Pins mit Höhe 0–255 setzen.", "Place at most 32 valid pins with height 0–255."); return }
        guard !autoPins.contains(where: { $0.dimension == dimension && $0.point == point }) else { return }
        let name = autoPinName.trimmingCharacters(in: .whitespacesAndNewlines)
        autoPins.append(MetroPlanPin(name: name.isEmpty ? t("Ziel \(autoPins.count + 1)", "Target \(autoPins.count + 1)") : name, dimension: dimension, point: point))
        autoPinName = ""; invalidateAutoPreview()
    }
    private func applyAutoProposal() {
        guard autoBaseline == network, let proposal = autoProposals.first(where: { $0.id == autoSelected }) else {
            message = t("Zuerst aktuelle Vorschläge erzeugen und einen auswählen.", "Generate current proposals and select one first."); return
        }
        if commit(proposal.network) { autoPins = []; invalidateAutoPreview(); tool = "station"; markClean() }
    }
    private func autoTitle(_ strategy: MetroPlanStrategy) -> String {
        switch strategy {
        case .short: return t("Kurze Verbindungen", "Short connections")
        case .symmetric: return t("Symmetrische Bauweise", "Symmetric construction")
        case .balanced: return t("Ausgewogenes Netz", "Balanced network")
        }
    }
    private func autoDescription(_ strategy: MetroPlanStrategy) -> String {
        switch strategy {
        case .short: return t("Minimaler geometrischer Verbindungsbaum; keine Garantie für die schnellste Reise.", "Minimum geometric connection tree; not a guarantee of the fastest journey.")
        case .symmetric: return t("Regelmäßige Ringe und radiale Achsen; Zielabzweige verlaufen rechtwinklig.", "Regular rings and radial axes; target branches follow right angles.")
        case .balanced: return t("Ringe und Achsen mit kurzen Abzweigen zur jeweils nächsten Station.", "Rings and axes with short branches to the nearest station.")
        }
    }
    private func newStation() {
        selectedStation = nil; stationDraft = .init(id: UUID().uuidString, name: "", dimension: "n", x: 0, y: 32, z: 0, status: .planned)
        tool = "station"; recording = false; compactPane = "editor"; markClean()
    }
    private func select(_ station: MetroStation) { selectedStation = station.id; stationDraft = station; tool = "station"; recording = false; compactPane = "editor"; markClean() }
    private func pick(_ selection: MetroMapSelection) {
        guard editable else { return }
        if tool == "assistant" {
            addAutoPin(dimension: selection.dimension, point: selection.point)
            return
        }
        if !recording && !model.drafts.authorize() { return }
        if recording {
            guard selection.dimension == network.stations.first(where: { $0.id == edgeDraft.from })?.dimension else {
                message = t("Streckenpunkte müssen in derselben Dimension liegen.", "Path points must stay in the same dimension."); return
            }
            if pathPoints.last != selection.point { pathPoints.append(selection.point) }; return
        }
        if let station = network.stations.first(where: { $0.dimension == selection.dimension && MetroPoint($0) == selection.point }) { select(station); return }
        newStation(); stationDraft.dimension = selection.dimension; stationDraft.x = selection.point.x; stationDraft.y = selection.point.y; stationDraft.z = selection.point.z; stationDraft.portalID = selection.portalID
        stationDraft.status = selection.portalID == nil ? .planned : .built
        stationDraft.name = MetroNaming.stationName(x: selection.point.x, z: selection.point.z, existing: network.stations, origin: network.origin)
    }
    private func saveStation() {
        var draft = stationDraft
        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { draft.name = MetroNaming.stationName(x: draft.x, z: draft.z, existing: network.stations, origin: network.origin) }
        var copy = network
        if let previous = network.stations.first(where: { $0.id == draft.id }), MetroPoint(previous) != MetroPoint(draft) || previous.dimension != draft.dimension {
            if network.edges.contains(where: { ($0.from == draft.id || $0.to == draft.id) && $0.path != nil }) {
                message = t("Zuerst erfasste Verläufe der verbundenen Strecken leeren; ihre Endpunkte würden sonst nicht mehr passen.", "Clear recorded geometry on connected links first; their endpoints would no longer match."); return
            }
            draft.portalID = nil
        }
        copy.stations.removeAll { $0.id == draft.id }; copy.stations.append(draft)
        if commit(copy) { select(draft) }
    }
    private func deleteStation() {
        guard let id = deleteID else { return }
        var copy = network; copy.edges.removeAll { $0.from == id || $0.to == id }; copy.stations.removeAll { $0.id == id }
        if copy.originID == id { copy.originID = nil }
        if commit(copy) { deleteID = nil; newStation() }
    }
    private func newEdge(from: String) {
        edgeDraft = .init(id: UUID().uuidString, from: from, to: "", lineID: filterLine, mode: .rail, status: .planned, lengthBlocks: 0, durationSeconds: nil, note: "")
        pathPoints = []; recording = false; duration = ""; tool = "edge"; compactPane = "editor"; markClean()
    }
    private func editEdge(_ edge: MetroEdge) {
        // Guard every entry point, including connections opened from an unsaved line.
        transition {
            edgeDraft = edge; pathPoints = edge.path ?? []; duration = edge.durationSeconds.map(String.init) ?? ""
            recording = false; tool = "edge"; compactPane = "editor"; markClean()
        }
    }
    private func clearPathIfEndpointsChanged() {
        if let first = pathPoints.first, let last = pathPoints.last,
           let a = network.stations.first(where: { $0.id == edgeDraft.from }), let b = network.stations.first(where: { $0.id == edgeDraft.to }),
           first == MetroPoint(a), last == MetroPoint(b) { return }
        pathPoints = []; edgeDraft.path = nil; recording = false
    }
    private func toggleRecording() {
        guard let a = network.stations.first(where: { $0.id == edgeDraft.from }), let b = network.stations.first(where: { $0.id == edgeDraft.to }), a.id != b.id, a.dimension == b.dimension else {
            message = t("Zwei Stationen derselben Dimension wählen.", "Choose two stations in the same dimension."); return
        }
        if recording {
            if pathPoints.last != MetroPoint(b) { pathPoints.append(MetroPoint(b)) }
            edgeDraft.path = pathPoints; edgeDraft.lengthBlocks = MetroPoint.length(pathPoints); recording = false
        } else { pathPoints = [MetroPoint(a)]; recording = true; mode = "map"; selectedStation = a.id }
    }
    private func saveEdge() {
        var draft = edgeDraft
        let text = duration.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty || Int(text) != nil else { message = t("Dauer in ganzen Sekunden eingeben.", "Enter duration in whole seconds."); return }
        draft.durationSeconds = text.isEmpty ? nil : Int(text)
        if draft.mode == .portal { draft.path = nil }
        var copy = network; copy.edges.removeAll { $0.id == draft.id }; copy.edges.append(draft)
        if commit(copy) { edgeDraft = draft; markClean() }
    }
    private func copySign() {
        let lines = network.servingLines(stationDraft.id).map(\.name).joined(separator: " / ")
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(stationDraft.name.uppercased() + "\n" + t("Linie ", "Line ") + lines, forType: .string)
        message = t("Schildtext kopiert.", "Sign text copied.")
    }
    private func exportNetwork() {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "Metro-network.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; try encoder.encode(network).write(to: url, options: .atomic) }
        catch { message = error.localizedDescription }
    }
    private func resumeJourney(_ id: String, persist: Bool = true) {
        guard id.isEmpty || journeys.journeys.contains(where: { $0.id == id }) else { return }
        if persist {
            var copy = journeys; copy.activeID = id.isEmpty ? nil : id
            guard persistJourneys(copy) else { return }
        }
        journeyID = id; step = 0
        if let saved = activeJourney {
            journeyFrom = saved.from; journeyTo = saved.to; journeyName = saved.name; step = saved.completedLegs
            tool = "journey"
        }
    }
    private func persistJourneys(_ proposed: MetroJourneyJournal) -> Bool {
        guard editable, !journeyLoadFailed, proposed.valid, let journalStore = journeyStore, let store else { return false }
        do {
            try model.library.withExclusiveOperation {
                guard try store.load() == network else { throw PlanningError.changed }
                try journalStore.save(proposed, replacing: journeys)
            }
            journeys = proposed; return true
        } catch { message = error.localizedDescription; return false }
    }
    private func saveJourney() {
        guard let route, let save = model.selected else { return }
        do {
            let title = journeyName.trimmingCharacters(in: .whitespacesAndNewlines)
            let record = MetroJourney(name: title.isEmpty ? stationName(journeyFrom) + " → " + stationName(journeyTo) : title,
                                      saveID: save.id, world: save.world, networkHash: try MetroJourney.fingerprint(network), from: journeyFrom, to: journeyTo,
                                      edgeIDs: route.edges.map(\.id), completedLegs: step)
            var copy = journeys; copy.journeys.append(record); copy.activeID = record.id
            guard copy.valid else { throw PlanningError.invalid }
            if persistJourneys(copy) { journeyID = record.id; journeyName = record.name; message = t("Reise gespeichert.", "Journey saved."); lastSaveSucceeded = true; markClean() }
        } catch { message = error.localizedDescription }
    }
    private func advanceJourney(_ route: MetroRoute) {
        let next = step >= route.edges.count ? 0 : step + 1
        // Every journey with progress is persisted, including one not explicitly named yet.
        if activeJourney == nil { saveJourney(); guard activeJourney != nil else { return } }
        var copy = journeys
        guard let index = copy.journeys.firstIndex(where: { $0.id == journeyID }) else { return }
        copy.journeys[index].completedLegs = next; copy.journeys[index].updated = Date()
        if persistJourneys(copy) { step = next; selectedStation = next == 0 ? journeyFrom : route.edges[next - 1].to }
    }
    private func journeyExport(_ route: MetroRoute) throws -> MetroJourneyExport {
        guard editable, let save = model.selected, let store else { throw PlanningError.invalid }
        return try model.library.withExclusiveOperation {
            guard try store.load() == network else { throw PlanningError.changed }
            return try MetroJourneyExport(network: network, route: route, saveID: save.id, world: save.world,
                                          title: save.title, date: save.date, completed: step, sharedGuidance: NavigationPack.assistantInstructions)
        }
    }
    private func exportJourney(_ route: MetroRoute, json: Bool) {
        do {
            let pack = try journeyExport(route)
            let panel = NSSavePanel(); panel.nameFieldStringValue = json ? "Metro-journey.json" : "Metro-journey.md"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            if json { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601; try encoder.encode(pack).write(to: url, options: .atomic) }
            else { try pack.markdown.write(to: url, atomically: true, encoding: .utf8) }
            message = t("Reise exportiert.", "Journey exported.")
        } catch { message = error.localizedDescription }
    }
}
