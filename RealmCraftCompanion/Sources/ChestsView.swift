import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor final class ChestController: ObservableObject {
    @Published var index: ChestIndex?
    @Published var groups: [ChestGroup] = []
    @Published var saveID = ""
    @Published var output: URL?
    let names: [String:ItemName] = {
        guard let file = Bundle.main.url(forResource: "ItemNames", withExtension: "json"), let data = try? Data(contentsOf: file) else { return [:] }
        return (try? JSONDecoder().decode([String:ItemName].self, from: data)) ?? [:]
    }()
    func name(_ id: Int, english: Bool) -> String {
        if let name = names[String(id)] { return english ? name.en : name.de }
        return english ? "Unknown item · ID \(id)" : "Unbekannter Gegenstand · ID \(id)"
    }
    func matches(_ item: ChestItem, query: String) -> Bool {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return true }
        let words = term.split(whereSeparator: \.isWhitespace)
        let text = "\(name(item.itemID, english: true)) \(name(item.itemID, english: false)) \(item.itemID)"
        return words.allSatisfy { text.localizedStandardContains(String($0)) }
    }
    func reset() { index = nil; groups = []; saveID = ""; output = nil }
    func scan(_ model: Model, maps: MapController, english: Bool) {
        guard let save = model.selected, maps.ready, let engine = Bundle.main.resourceURL?.appendingPathComponent("MapEngine") else { return }
        let backend = model.library, python = maps.python
        let target = maps.support.deletingLastPathComponent().appendingPathComponent("ChestIndexes/\(save.id)-\(UUID().uuidString).json")
        model.work(english ? "Indexing chest contents…" : "Kisteninhalte werden eingelesen …") {
            _ = try backend.verify(save)
            DispatchQueue.main.async { model.status = english ? "Reading stored chest records…" : "Gespeicherte Kistendatensätze werden gelesen …" }
            _ = try backend.checked(python, ["-I", "-B", "-u", "-c", "import sys; sys.path.insert(0, sys.argv.pop(1)); from realmcraft_map.chests import main; raise SystemExit(main())", engine.path, backend.worldFolder(save).path, "--output", target.path], timeout: 600)
            let parsed = try JSONDecoder().decode(ChestIndex.self, from: Data(contentsOf: target))
            _ = try backend.verify(save)
            DispatchQueue.main.async {
                let key = "conversation.ownedChests." + save.annotationScope
                let existing = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
                let signChests = Set(parsed.chests.filter { $0.nearbySign != nil }.map(\.id))
                UserDefaults.standard.set(existing.union(signChests).sorted(), forKey: key)
                self.index = parsed; self.groups = ChestGroup.make(parsed.chests); self.saveID = save.id; self.output = target }
            return english ? "Chest index ready. Savegame unchanged." : "Kistenübersicht bereit. Spielstand unverändert."
        }
    }
    func export(_ model: Model) {
        guard let output else { return }
        let panel = NSSavePanel(); panel.allowedContentTypes = [.json]; panel.nameFieldStringValue = "RealmCraft-Chests.json"
        if panel.runModal() == .OK, let target = panel.url {
            do { try Data(contentsOf: output).write(to: target, options: .atomic) }
            catch { model.error = error.localizedDescription }
        }
    }
}
struct ChestsView: View {
    @Environment(\.companionTheme) private var theme
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @ObservedObject var chests: ChestController
    let language: String
    let openMaps: () -> Void
    @State private var query = ""
    @State private var quickMaterials: Set<String> = []
    @State private var requireAllMaterials = false
    @State private var showFilters = false
    @State private var showInfo = false
    @State private var dimension = "all"
    @AppStorage("exploration.spoilerFree") private var spoilerFree = false
    @State private var chestCategory = "player"
    @State private var visibilityFilter = "visible"
    @State private var visibility = ChestVisibility()
    @State private var selected: String?
    @State private var chestPosition = 0
    @State private var sortOrder = ChestSortOrder.origin
    @State private var distanceReference: ChestRecord?
    private var english: Bool { language == "en" }
    private func chestName(_ chest: ChestRecord) -> String? {
        let labels = model.selected.flatMap { UserDefaults.standard.dictionary(forKey: "conversation.chestLabels." + $0.annotationScope) as? [String: String] } ?? [:]
        return chest.displayName(manual: labels[chest.id])
    }
    private func eligible(_ chest: ChestRecord) -> Bool {
        (!spoilerFree || visibility.isKnown(chest)) &&
        (chestCategory == "all" || visibility.owned.contains(chest.id) == (chestCategory == "player")) &&
        (visibilityFilter == "all" || visibility.isHidden(chest) == (visibilityFilter == "hidden"))
    }
    private func matches(_ chest: ChestRecord) -> Bool {
        eligible(chest) && ChestMaterialShortcut.matches(chest, selected: quickMaterials, requireAll: requireAllMaterials) && (query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chestName(chest)?.localizedStandardContains(query.trimmingCharacters(in: .whitespacesAndNewlines)) == true || chest.items.contains { chests.matches($0, query: query) })
    }
    private func quantityMatches(_ item: ChestItem) -> Bool {
        if !quickMaterials.isEmpty { return ChestMaterialShortcut.highlights(item, selected: quickMaterials) }
        return query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chests.matches(item, query: query)
    }
    private var locations: [ChestGroup] {
        let filtered = chests.groups.compactMap { group -> ChestGroup? in
            let members = group.members.filter(eligible)
            guard let anchor = members.first, dimension == "all" || anchor.dimension == dimension,
                  members.contains(where: matches) else { return nil }
            return ChestGroup(id: group.id, members: members)
        }
        let ranked = ChestSorting.sorted(filtered.flatMap { $0.members.filter(matches) }, order: sortOrder, reference: distanceReference, matching: quantityMatches)
        let ranks = Dictionary(uniqueKeysWithValues: ranked.enumerated().map { ($0.element.id, $0.offset) })
        return filtered.map { group in
            ChestGroup(id: group.id, members: group.members.sorted { (ranks[$0.id] ?? Int.max) < (ranks[$1.id] ?? Int.max) })
        }.sorted { (ranks[$0.anchor.id] ?? Int.max) < (ranks[$1.anchor.id] ?? Int.max) }
    }
    private func useAsReference(_ chest: ChestRecord) {
        distanceReference = chest
        sortOrder = .distance
        refreshSelection()
    }
    private var sortingMenu: some View {
        Menu {
            Picker(english ? "Sort chests" : "Kisten sortieren", selection: $sortOrder) {
                ForEach(ChestSortOrder.allCases, id: \.self) { order in
                    Text(order.title(english)).tag(order).disabled(order == .distance && distanceReference == nil)
                }
            }
            if let chest = current {
                Divider()
                Button(english ? "Measure from selected chest" : "Ab ausgewählter Kiste messen") { useAsReference(chest) }
            }
        } label: { Image(systemName: "arrow.up.arrow.down") }
        .companionOverflow().help(sortOrder.title(english))
        .accessibilityLabel((english ? "Sort: " : "Sortierung: ") + sortOrder.title(english))
    }
    private func sortingDetail(_ chest: ChestRecord) -> String {
        if sortOrder == .most || sortOrder == .least {
            guard let count = ChestSorting.quantity(chest, matching: quantityMatches) else { return english ? "Quantity unknown" : "Menge unbekannt" }
            return english ? "\(count) matching items in this chest" : "\(count) passende Gegenstände in dieser Kiste"
        }
        if sortOrder == .distance, let reference = distanceReference {
            guard let distance = ChestSorting.distance(chest, from: reference) else { return english ? "Other dimension · no comparable distance" : "Andere Dimension · Entfernung nicht vergleichbar" }
            return String(format: english ? "%.1f blocks from reference" : "%.1f Blöcke zur Bezugskiste", distance)
        }
        return ""
    }
    private var currentGroup: ChestGroup? { locations.first { $0.id == selected } }
    private var members: [ChestRecord] { currentGroup?.members.filter(matches) ?? [] }
    private var current: ChestRecord? { members.indices.contains(chestPosition) ? members[chestPosition] : members.first }
    private func refreshSelection() {
        chestPosition = 0
        if !locations.contains(where: { $0.id == selected }) { selected = locations.first?.id }
    }
    private func saveVisibility() {
        guard let world = model.selected?.annotationScope else { return }
        visibility.save(world: world)
        refreshSelection()
    }
    private func mark(_ records: [ChestRecord], hidden: Bool) {
        visibility.setHidden(hidden, for: records)
        saveVisibility()
    }
    private var filterCount: Int {
        (dimension == "all" ? 0 : 1) + (visibilityFilter == "visible" ? 0 : 1) + (visibility.hideSuspected ? 1 : 0) + (chestCategory == "player" ? 0 : 1) + quickMaterials.count
    }
    private var filterSummary: String {
        var parts: [String] = []
        parts.append(chestCategory == "player" ? (english ? "Player chests" : "Eigene Kisten") : chestCategory == "random" ? (english ? "Other chests" : "Andere Kisten") : (english ? "All chests" : "Alle Kisten"))
        if !quickMaterials.isEmpty {
            let materials = ChestMaterialShortcut.all.filter { quickMaterials.contains($0.id) }.map { english ? $0.en : $0.de }
            let joiner = requireAllMaterials ? (english ? " AND " : " UND ") : (english ? " OR " : " ODER ")
            parts.append(materials.joined(separator: joiner))
        }
        if dimension != "all" { parts.append(dimension == "o" ? (english ? "Overworld" : "Oberwelt") : "Nether") }
        if visibilityFilter != "visible" { parts.append(visibilityFilter == "hidden" ? (english ? "Hidden chests" : "Ausgeblendete Kisten") : (english ? "Including hidden chests" : "Inklusive ausgeblendeter Kisten")) }
        if visibility.hideSuspected { parts.append(english ? "Dungeon estimate hidden" : "Dungeon-Schätzung ausgeblendet") }
        return parts.joined(separator: " · ")
    }
    private var searchField: some View {
        TextField(english ? "Search items or ID…" : "Gegenstand oder ID suchen …", text: $query)
            .textFieldStyle(.roundedBorder).frame(minWidth: 210, maxWidth: .infinity)
            .accessibilityLabel(english ? "Search chest contents" : "Kisteninhalte durchsuchen")
    }
    private var materialShortcuts: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 6)], alignment: .leading, spacing: 6) {
                ForEach(ChestMaterialShortcut.all) { material in
                    let active = quickMaterials.contains(material.id)
                    Button {
                        if active { quickMaterials.remove(material.id) } else { quickMaterials.insert(material.id) }
                    } label: {
                        HStack(spacing: 5) {
                            if active { Image(systemName: "checkmark").font(.caption.bold()) }
                            Text(english ? material.en : material.de).lineLimit(1)
                        }.font(.callout).padding(.horizontal, 8).padding(.vertical, 7)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(active ? theme.accent : Color.primary)
                            .background(active ? theme.accent.opacity(0.15) : theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? theme.accent : theme.border, lineWidth: 1))
                    }.buttonStyle(.plain)
                        .accessibilityLabel(english ? material.en : material.de)
                        .accessibilityValue(active ? (english ? "Selected" : "Ausgewählt") : (english ? "Not selected" : "Nicht ausgewählt"))
                        .accessibilityAddTraits(active ? [.isSelected] : [])
                        .help((english ? material.detailEN : material.detailDE) + (english ? ". Click to select or deselect." : ". Anklicken zum Aus- oder Abwählen."))
                }
            }
            if !quickMaterials.isEmpty {
                HStack(spacing: 10) {
                    if quickMaterials.count > 1 {
                        Picker(english ? "Combine" : "Kombination", selection: $requireAllMaterials) {
                            Text(english ? "Any selected material" : "Mindestens ein Material").tag(false)
                            Text(english ? "All in the same chest" : "Alle in derselben Kiste").tag(true)
                        }.labelsHidden().fixedSize()
                    } else {
                        Text(english ? "Material filter active" : "Materialfilter aktiv").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button(english ? "Clear selection" : "Auswahl aufheben") { quickMaterials = [] }
                        .buttonStyle(.plain).font(.caption).foregroundStyle(theme.accent)
                }
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(english ? "Search text additionally filters the matching chests." : "Der Suchtext grenzt die passenden Kisten zusätzlich ein.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
    private var categoryPicker: some View {
        Picker(english ? "Chest group" : "Kistengruppe", selection: $chestCategory) {
            Text(english ? "Player" : "Eigene").tag("player")
            Text(english ? "Other" : "Andere").tag("random")
            Text(english ? "All" : "Alle").tag("all")
        }.pickerStyle(.segmented).labelsHidden()
        .help(english ? "Player: marked as yours. Other: ownership not marked." : "Eigene: als Besitz markiert. Andere: nicht als Besitz markiert.")
    }
    private var filterButton: some View {
        Button { showFilters.toggle() } label: {
            Label(filterCount == 0 ? (english ? "Filters" : "Filter") : (english ? "Filters (\(filterCount))" : "Filter (\(filterCount))"), systemImage: "line.3.horizontal.decrease.circle")
        }.buttonStyle(CompanionButtonStyle(width: CompanionLayout.primaryActionWidth))
        .popover(isPresented: $showFilters, arrowEdge: .bottom) {
            ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(english ? "Filter chests" : "Kisten filtern").font(.headline)
                    Spacer()
                    Button(english ? "Reset" : "Zurücksetzen") {
                        dimension = "all"; visibilityFilter = "visible"; visibility.hideSuspected = false
                        chestCategory = "player"; quickMaterials = []; requireAllMaterials = false
                    }.buttonStyle(.plain).foregroundStyle(theme.accent).disabled(filterCount == 0)
                }
                Text(english ? "Ownership" : "Besitz").font(.subheadline.bold())
                categoryPicker
                Text(english ? "Materials" : "Materialien").font(.subheadline.bold())
                materialShortcuts
                Divider()
                Picker("Dimension", selection: $dimension) {
                    Text(english ? "All dimensions" : "Alle Dimensionen").tag("all")
                    Text(english ? "Overworld" : "Oberwelt").tag("o")
                    Text("Nether").tag("n")
                }
                Picker(english ? "Visibility" : "Sichtbarkeit", selection: $visibilityFilter) {
                    Text(english ? "Visible" : "Sichtbare").tag("visible")
                    Text(english ? "All, including hidden" : "Alle, inklusive ausgeblendeter").tag("all")
                    Text(english ? "Hidden only" : "Nur ausgeblendete").tag("hidden")
                }
                Divider()
                Toggle(english ? "Hide suspected dungeon chests" : "Vermutete Dungeon-Kisten ausblenden", isOn: $visibility.hideSuspected)
                Text(english ? "Estimate: Overworld, Y ≤ 50, rails + redstone + torch or golden apple. Owned and manually shown chests are exempt. This does not prove whether a chest was discovered." : "Schätzung: Oberwelt, Y ≤ 50, Schienen + Redstone + Fackel oder goldener Apfel. Eigene und manuell eingeblendete Kisten sind ausgenommen. Dies ist kein Nachweis des Entdeckungsstatus.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if spoilerFree {
                    Label(english ? "Spoiler-light mode still limits results to known chests." : "Der spoilerarme Modus begrenzt Ergebnisse weiterhin auf bekannte Kisten.", systemImage: "eye.slash").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(CompanionLayout.panelInset)
            }.frame(width: 440, height: 560)
        }
    }
    private var indexInformation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(english ? "Chest index" : "Kistenindex").font(.headline)
            Text(english ? "Chests within 6 blocks form storage locations. Select a location, then browse its chests." : "Kisten mit bis zu 6 Blöcken Abstand bilden Lagerorte. Wähle einen Lagerort und blättere durch seine Kisten.")
            if let index = chests.index {
                Text(english ? "\(index.chunksScanned) chunk files scanned · \(index.errors.count) scan issues" : "\(index.chunksScanned) Chunk-Dateien geprüft · \(index.errors.count) Leseprobleme")
            }
            Text(english ? "Contents reflect the selected backup. Your savegame is unchanged." : "Inhalte entsprechen der gewählten Sicherung. Dein Spielstand bleibt unverändert.").foregroundStyle(.secondary)
        }.font(.callout).padding(20).frame(width: 330)
    }
    private func chestActions(_ chest: ChestRecord) -> some View {
        Menu {
            Toggle(english ? "Belongs to me" : "Gehört mir", isOn: Binding(get: { visibility.owned.contains(chest.id) }, set: { owned in
                if owned { visibility.owned.insert(chest.id) } else { visibility.owned.remove(chest.id) }
                if let world = model.selected?.annotationScope { UserDefaults.standard.set(visibility.owned.sorted(), forKey: "conversation.ownedChests." + world) }
                refreshSelection()
            }))
            Toggle(english ? "Already discovered" : "Bereits entdeckt", isOn: Binding(get: { visibility.isKnown(chest) }, set: { known in
                if known { visibility.visible.insert(chest.id); visibility.hidden.remove(chest.id) }
                else { visibility.visible.remove(chest.id) }
                saveVisibility()
            })).disabled(visibility.owned.contains(chest.id))
            Divider()
            Button(visibility.isHidden(chest) ? (english ? "Show chest" : "Kiste einblenden") : (english ? "Hide chest" : "Kiste ausblenden")) { mark([chest], hidden: !visibility.isHidden(chest)) }
            Button(english ? "Use as distance reference" : "Als Bezugspunkt für Entfernung") { useAsReference(chest) }
            Button(english ? "Copy coordinates" : "Koordinaten kopieren") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(chest.coordinates, forType: .string) }
            Menu(english ? "Chests at this location" : "Kisten an diesem Lagerort") {
                Button(english ? "Hide listed chests" : "Angezeigte Kisten ausblenden") { mark(currentGroup?.members ?? [], hidden: true) }
                Button(english ? "Show listed chests" : "Angezeigte Kisten einblenden") { mark(currentGroup?.members ?? [], hidden: false) }
            }
        } label: { Label(english ? "Manage" : "Verwalten", systemImage: "ellipsis.circle") }
        .fixedSize()
    }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Chests" : "Kisten") {
                    Button(english ? "Read chests" : "Kisten einlesen") { chests.scan(model, maps: maps, english: english) }.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(model.busy || !maps.ready || model.selected == nil || maps.checking)

            } menu: {
                Group {
                    Button(english ? "Export JSON" : "JSON exportieren") { chests.export(model) }
                    if let chest = current {
                        Button(english ? "Copy coordinates" : "Koordinaten kopieren") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(chest.coordinates, forType: .string) }
                    }
                }
                .disabled(model.busy || chests.index == nil)
            }
            VStack(alignment: .leading, spacing: 12) {
                SourceContextBar(saves: model.saves, selection: $model.selection, language: language).disabled(model.busy)
                HStack(spacing: CompanionLayout.actionSpacing) {
                    filterButton
                    sortingMenu
                    Button { showInfo.toggle() } label: {
                        Image(systemName: "info.circle")
                            .frame(width: CompanionLayout.actionHeight, height: CompanionLayout.actionHeight)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).foregroundStyle(.secondary)
                        .accessibilityLabel(english ? "About the chest index" : "Informationen zum Kistenindex")
                        .popover(isPresented: $showInfo) { indexInformation }
                }
                if sortOrder != .origin {
                    HStack {
                        Text(sortOrder.title(english)).font(.caption.bold())
                        if sortOrder == .distance, let reference = distanceReference {
                            Text("\(reference.dimension) · \(reference.coordinates)").font(.caption)
                        }
                    }.foregroundStyle(.secondary)
                    Text(sortOrder == .distance ? (english ? "Straight-line distance including height. Other dimensions follow last. Reference stays fixed until changed in Manage." : "Luftlinie inklusive Höhe. Andere Dimensionen stehen am Ende. Bezugspunkt bleibt bis zur Änderung unter Verwalten fest.") : (english ? "Locations follow their best matching chest; chests within each location use the same order. Counts use selected materials, otherwise the search or all items. Stored units; blocks are not converted to ingots." : "Lagerorte folgen ihrer bestplatzierten Kiste; darin gilt dieselbe Reihenfolge. Gezählt werden gewählte Materialien, sonst Suchtreffer oder alle Inhalte. Gespeicherte Stückzahlen; Blöcke werden nicht in Barren umgerechnet."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !filterSummary.isEmpty || spoilerFree {
                    HStack(spacing: 8) {
                        if spoilerFree {
                            Label(english ? "Spoiler-light mode" : "Spoilerarmer Modus", systemImage: "eye.slash")
                                .help(english ? "Only owned or manually known chests. Change in Settings → Exploration & spoilers." : "Nur eigene oder manuell bekannte Kisten. Ändern unter Einstellungen → Erkundung & Spoiler.")
                        }
                        if spoilerFree && !filterSummary.isEmpty { Text("·") }
                        if !filterSummary.isEmpty { Text(filterSummary) }
                    }.font(.caption).foregroundStyle(.secondary)
                }
                CompanionStatusLane {
                if model.busy {
                    Text(tr(model.status)).font(.caption).foregroundStyle(.secondary)
                } else if let index = chests.index, !index.errors.isEmpty {
                    Label(english ? "\(index.errors.count) scan issues — see index information" : "\(index.errors.count) Leseprobleme – siehe Index-Informationen", systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange)
                } else if chests.index != nil {
                    Text(english ? "\(locations.count) locations · \(locations.reduce(0) { $0 + $1.members.filter(matches).count }) chests" : "\(locations.count) Lagerorte · \(locations.reduce(0) { $0 + $1.members.filter(matches).count }) Kisten")
                        .monospacedDigit()
                }
                }
                if !maps.ready {
                    HStack { Text(english ? "Map tools are required." : "Kartenwerkzeuge werden benötigt."); Button(english ? "Set up in Maps" : "In Karten einrichten", action: openMaps) }.font(.callout)
                }
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            Divider()
            if chests.index != nil {
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                    searchField.padding(16)
                    List(locations, selection: $selected) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Label(group.members.count == 1 ? (chestName(group.anchor) ?? (english ? "Storage location" : "Lagerort")) : (english ? "Storage location" : "Lagerort"), systemImage: "shippingbox.fill").font(.headline)
                            Text(group.anchor.coordinates).font(.callout).monospacedDigit()
                            Text(group.anchor.dimension == "o" ? (english ? "Overworld" : "Oberwelt") : "Nether").foregroundStyle(.secondary)
                            Text(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (english ? "\(group.members.count) chests" : "\(group.members.count) Kisten") : (english ? "\(group.members.filter(matches).count) of \(group.members.count) chests matching" : "\(group.members.filter(matches).count) von \(group.members.count) Kisten passend")).font(.caption).foregroundStyle(theme.accent)
                            if sortOrder != .origin { Text(sortingDetail(group.anchor)).font(.caption).foregroundStyle(.secondary) }
                        }.padding(.vertical, 8).tag(group.id)
                        .contextMenu {
                            Button(english ? "Hide listed chests at location" : "Angezeigte Kisten am Ort ausblenden") { mark(group.members, hidden: true) }
                            Button(english ? "Show listed chests at location" : "Angezeigte Kisten am Ort einblenden") { mark(group.members, hidden: false) }
                        }
                    }.listStyle(.sidebar).scrollContentBackground(.hidden)
                    }.frame(width: CompanionTheme.sidebarWidth).background(theme.surface)
                    Divider()
                    ScrollView {
                        if let chest = current {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack {
                                    Picker(english ? "Chest" : "Kiste", selection: $chestPosition) {
                                        ForEach(Array(members.enumerated()), id: \.offset) { offset, member in Text("\(offset + 1) / \(members.count) · " + (chestName(member).map { $0 + " · " } ?? "") + member.coordinates).tag(offset) }
                                    }
                                }.disabled(members.count < 2)
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let name = chestName(chest) { Text(name).font(.title2.bold()).textSelection(.enabled) }
                                        Text(chest.coordinates).font(.title2.bold()).textSelection(.enabled)
                                            .help(chest.file)
                                        HStack(spacing: 12) {
                                            Label(visibility.owned.contains(chest.id) ? (english ? "Player chest" : "Eigene Kiste") : visibility.isKnown(chest) ? (english ? "Known chest" : "Bekannte Kiste") : (english ? "Other chest" : "Andere Kiste"), systemImage: visibility.owned.contains(chest.id) ? "person.fill" : visibility.isKnown(chest) ? "checkmark.circle" : "shippingbox")
                                            if visibility.isHidden(chest) { Label(english ? "Hidden" : "Ausgeblendet", systemImage: "eye.slash") }
                                            if ChestVisibility.suspectedDungeon(chest) && !visibility.isKnown(chest) {
                                                Text(english ? "Possible dungeon loot" : "Mögliche Dungeon-Beute")
                                                    .help(english ? "Estimate based on height and contents; discovery is unknown." : "Schätzung anhand von Höhe und Inhalt; Entdeckungsstatus unbekannt.")
                                            }
                                        }.font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 8)
                                    chestActions(chest)
                                }
                                if let sign = chest.nameSign {
                                    Label(english ? "Name from adjacent sign" : "Name vom direkt angrenzenden Schild", systemImage: "signpost.right").font(.caption).foregroundStyle(.secondary).help(sign)
                                }
                                if let sign = chest.nearbySign {
                                    Label(english ? "Nearby sign: ≤30 blocks horizontally, ≤10 vertically" : "Schild in der Nähe: ≤30 Blöcke horizontal, ≤10 Höhe", systemImage: "signpost.right")
                                        .font(.caption).foregroundStyle(.secondary).help(sign)
                                }
                                if sortOrder != .origin { Text(sortingDetail(chest)).font(.caption).foregroundStyle(.secondary) }
                                if !chest.readable { Text(english ? "This container layout is not supported. It must not be treated as empty." : "Dieses Containerformat wird nicht unterstützt. Die Kiste darf nicht als leer gewertet werden.").foregroundStyle(.orange); Text(chest.error).font(.caption) }
                                else if chest.items.isEmpty { Text(english ? "This chest is empty in this backup." : "Diese Kiste ist in dieser Sicherung leer.").foregroundStyle(.secondary) }
                                else {
                                    ForEach(chest.items.sorted { $0.slot < $1.slot }) { item in
                                        HStack(spacing: 14) {
                                            Text("\(item.slot)").monospacedDigit().foregroundStyle(.secondary).frame(width: 26)
                                            ItemIcon(itemID: item.itemID)
                                            VStack(alignment: .leading, spacing: 4) { Text(chests.name(item.itemID, english: english)).font(.headline); Text("ID \(item.itemID)" + (item.extraData ? (english ? " · additional item data" : " · zusätzliche Gegenstandsdaten") : "")).font(.caption).foregroundStyle(.secondary) }
                                            Spacer(); Text("× \(item.quantity)").monospacedDigit().font(.headline)
                                        }.padding(.horizontal, 12).padding(.vertical, 10).background((chests.matches(item, query: query) && !query.isEmpty) || ChestMaterialShortcut.highlights(item, selected: quickMaterials) ? theme.accent.opacity(0.10) : Color.clear)
                                        Divider()
                                    }
                                }
                            }.padding(CompanionLayout.pageInset).frame(maxWidth: .infinity, alignment: .leading)
                        } else { Text(locations.isEmpty ? (english ? "No matching chests. Unnamed IDs and unreadable records may limit name searches." : "Keine passenden Kisten. Unbenannte IDs und nicht lesbare Datensätze können die Namenssuche einschränken.") : (english ? "Select a storage location, then browse its individual chests." : "Wähle einen Lagerort und blättere durch seine einzelnen Kisten.")).foregroundStyle(.secondary).padding(40).frame(maxWidth: .infinity) }
                    }.frame(minWidth: 360, maxWidth: .infinity)
                }
            } else { VStack(spacing: 16) { Image(systemName: "shippingbox.fill").font(.system(size: 46)).foregroundStyle(theme.accent); Text(english ? "Find your stored supplies" : "Finde deine gelagerten Vorräte").font(.title.bold()); Text(english ? "Choose a backup, then read its chests. Your savegame is never edited." : "Wähle eine Sicherung und lies ihre Kisten ein. Dein Spielstand wird nicht bearbeitet.").foregroundStyle(.secondary) }.multilineTextAlignment(.center).padding(40).frame(maxWidth: .infinity, maxHeight: .infinity) }
        }
        .onAppear { visibility = ChestVisibility.load(world: model.selected?.annotationScope ?? ""); maps.check(model); if chests.saveID != model.selection { chests.reset() } }
        .onChange(of: model.selection) { _, _ in chests.reset(); selected = nil; distanceReference = nil; if sortOrder == .distance { sortOrder = .origin }; visibility = ChestVisibility.load(world: model.selected?.annotationScope ?? "") }
        .onChange(of: sortOrder) { _, _ in refreshSelection() }
        .onChange(of: quickMaterials) { _, _ in refreshSelection() }
        .onChange(of: requireAllMaterials) { _, _ in refreshSelection() }
        .onChange(of: query) { _, _ in chestPosition = 0; if !locations.contains(where: { $0.id == selected }) { selected = locations.first?.id } }
        .onChange(of: spoilerFree) { _, _ in refreshSelection() }
        .onChange(of: chestCategory) { _, _ in refreshSelection() }
        .onChange(of: visibilityFilter) { _, _ in refreshSelection() }
        .onChange(of: visibility.hideSuspected) { _, _ in saveVisibility() }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            let owned = Set(UserDefaults.standard.stringArray(forKey: "conversation.ownedChests." + (model.selected?.annotationScope ?? "")) ?? [])
            if visibility.owned != owned { visibility.owned = owned; refreshSelection() }
        }
        .onChange(of: selected) { _, _ in chestPosition = 0 }
        .onChange(of: dimension) { _, _ in chestPosition = 0; selected = locations.first?.id }
    }
}
