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
            _ = try backend.checked(python, ["-u", "-c", "import sys; sys.path.insert(0, sys.argv.pop(1)); from realmcraft_map.chests import main; raise SystemExit(main())", engine.path, backend.worldFolder(save).path, "--output", target.path], timeout: 600)
            let parsed = try JSONDecoder().decode(ChestIndex.self, from: Data(contentsOf: target))
            _ = try backend.verify(save)
            DispatchQueue.main.async { self.index = parsed; self.groups = ChestGroup.make(parsed.chests); self.saveID = save.id; self.output = target }
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
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @ObservedObject var chests: ChestController
    let language: String
    let openMaps: () -> Void
    @State private var query = ""
    @State private var dimension = "all"
    @State private var selected: String?
    @State private var chestPosition = 0
    private var english: Bool { language == "en" }
    private func matches(_ chest: ChestRecord) -> Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chest.items.contains { chests.matches($0, query: query) }
    }
    private var locations: [ChestGroup] {
        chests.groups.filter { group in (dimension == "all" || group.anchor.dimension == dimension) && group.members.contains(where: matches) }
    }
    private var currentGroup: ChestGroup? { locations.first { $0.id == selected } }
    private var members: [ChestRecord] { currentGroup?.members.filter(matches) ?? [] }
    private var current: ChestRecord? { members.indices.contains(chestPosition) ? members[chestPosition] : members.first }
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(english ? "Chest explorer" : "Kistenübersicht", systemImage: "shippingbox").font(.title2.bold())
                    Spacer()
                    if chests.index != nil { Button(english ? "Export JSON" : "JSON exportieren") { chests.export(model) }.disabled(model.busy) }
                }
                HStack {
                    Picker(english ? "Savegame" : "Spielstand", selection: $model.selection) {
                        if model.saves.isEmpty { Text(english ? "No savegames" : "Keine Spielstände").tag(nil as String?) }
                        ForEach(model.saves) { save in Text(save.title + " · " + displayDate(save.date, language: language)).tag(Optional(save.id)) }
                    }.frame(maxWidth: 600)
                    Button(english ? "Read chests" : "Kisten einlesen") { chests.scan(model, maps: maps, english: english) }.buttonStyle(.borderedProminent).disabled(!maps.ready || model.selected == nil || maps.checking)
                    Spacer()
                }.disabled(model.busy)
                Text(english ? "Search the selected backup, e.g. gold, diamond or an item ID. Nearby chests form storage locations (up to 6 blocks between linked chests). Switch between individual chests inside a location." : "Durchsuche die gewählte Sicherung, z. B. nach Gold, Diamant oder einer Gegenstands-ID. Nahe Kisten bilden Lagerorte (bis zu 6 Blöcke zwischen verbundenen Kisten). Innerhalb eines Lagerorts kannst du einzelne Kisten durchschalten.").font(.caption).foregroundStyle(.secondary)
                if !maps.ready {
                    HStack { Text(english ? "Uses the same Python tools as Maps." : "Verwendet dieselben Python-Werkzeuge wie die Karten."); Button(english ? "Set up in Maps" : "In Karten einrichten", action: openMaps) }.font(.callout)
                }
                if let index = chests.index {
                    HStack {
                        TextField(english ? "Search contents: gold, diamond, ID…" : "Inhalt suchen: Gold, Diamant, ID …", text: $query).textFieldStyle(.roundedBorder).frame(maxWidth: 420)
                        Picker("Dimension", selection: $dimension) { Text(english ? "All dimensions" : "Alle Dimensionen").tag("all"); Text(english ? "Overworld" : "Oberwelt").tag("o"); Text("Nether").tag("n") }.frame(width: 220)
                        Spacer()
                        Text(english ? "\(locations.count) locations · \(locations.reduce(0) { $0 + $1.members.filter(matches).count }) chests" : "\(locations.count) Lagerorte · \(locations.reduce(0) { $0 + $1.members.filter(matches).count }) Kisten").monospacedDigit().foregroundStyle(.secondary)
                    }
                    Text(english ? "\(index.chunksScanned) chunk files scanned · \(index.errors.count) unreadable record/chunk issue(s)" : "\(index.chunksScanned) Chunk-Dateien geprüft · \(index.errors.count) nicht lesbare Datensätze/Chunk-Probleme").font(.caption).foregroundStyle(index.errors.isEmpty ? Color.secondary : Color.orange)
                }
                if model.busy { HStack { ProgressView().controlSize(.small); Text(tr(model.status)).font(.callout) } }
            }.padding(20)
            Divider()
            if chests.index != nil {
                HSplitView {
                    List(locations, selection: $selected) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Label(english ? "Storage location" : "Lagerort", systemImage: "shippingbox.fill").font(.headline)
                            Text(group.anchor.coordinates).font(.callout).monospacedDigit()
                            Text(group.anchor.dimension == "o" ? (english ? "Overworld" : "Oberwelt") : "Nether").foregroundStyle(.secondary)
                            Text(english ? "\(group.members.count) chests · \(group.members.filter(matches).count) matching" : "\(group.members.count) Kisten · \(group.members.filter(matches).count) passend").font(.caption).foregroundStyle(.teal)
                        }.padding(.vertical, 8).tag(group.id)
                    }.frame(minWidth: 240, idealWidth: 300, maxWidth: 370)
                    ScrollView {
                        if let chest = current {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack {
                                    Button { chestPosition = (chestPosition - 1 + members.count) % members.count } label: { Image(systemName: "chevron.left") }.help(english ? "Previous chest" : "Vorherige Kiste")
                                    Picker(english ? "Chest" : "Kiste", selection: $chestPosition) {
                                        ForEach(Array(members.enumerated()), id: \.offset) { offset, member in Text("\(offset + 1) / \(members.count) · \(member.coordinates)").tag(offset) }
                                    }
                                    Button { chestPosition = (chestPosition + 1) % members.count } label: { Image(systemName: "chevron.right") }.help(english ? "Next chest" : "Nächste Kiste")
                                }.disabled(members.count < 2)
                                Text(english ? "Showing matching chests within this storage location." : "Angezeigt werden die zur Suche passenden Kisten dieses Lagerorts.").font(.caption).foregroundStyle(.secondary)
                                HStack { VStack(alignment: .leading, spacing: 6) { Text(chest.coordinates).font(.title2.bold()); Text(chest.file).font(.caption).foregroundStyle(.secondary) }; Spacer(); Button(english ? "Copy coordinates" : "Koordinaten kopieren") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(chest.coordinates, forType: .string) } }
                                if !chest.readable { Text(english ? "This container layout is not supported. It must not be treated as empty." : "Dieses Containerformat wird nicht unterstützt. Die Kiste darf nicht als leer gewertet werden.").foregroundStyle(.orange); Text(chest.error).font(.caption) }
                                else if chest.items.isEmpty { Text(english ? "This chest is empty in this backup." : "Diese Kiste ist in dieser Sicherung leer.").foregroundStyle(.secondary) }
                                else {
                                    ForEach(chest.items.sorted { $0.slot < $1.slot }) { item in
                                        HStack(spacing: 14) {
                                            Text("\(item.slot)").monospacedDigit().foregroundStyle(.secondary).frame(width: 26)
                                            VStack(alignment: .leading, spacing: 4) { Text(chests.name(item.itemID, english: english)).font(.headline); Text("ID \(item.itemID)" + (item.extraData ? (english ? " · additional item data" : " · zusätzliche Gegenstandsdaten") : "")).font(.caption).foregroundStyle(.secondary) }
                                            Spacer(); Text("× \(item.quantity)").monospacedDigit().font(.headline)
                                        }.padding(12).background(chests.matches(item, query: query) && !query.isEmpty ? Color.teal.opacity(0.15) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                        } else { Text(locations.isEmpty ? (english ? "No matching chests. Unnamed IDs and unreadable records may limit name searches." : "Keine passenden Kisten. Unbenannte IDs und nicht lesbare Datensätze können die Namenssuche einschränken.") : (english ? "Select a storage location, then browse its individual chests." : "Wähle einen Lagerort und blättere durch seine einzelnen Kisten.")).foregroundStyle(.secondary).padding(40).frame(maxWidth: .infinity) }
                    }.frame(minWidth: 440, maxWidth: .infinity)
                }
            } else { VStack(spacing: 16) { Image(systemName: "shippingbox.fill").font(.system(size: 46)).foregroundStyle(.teal); Text(english ? "Find your stored supplies" : "Finde deine gelagerten Vorräte").font(.title.bold()); Text(english ? "Choose a backup, then read its chests. Your savegame is never edited." : "Wähle eine Sicherung und lies ihre Kisten ein. Dein Spielstand wird nicht bearbeitet.").foregroundStyle(.secondary) }.frame(maxWidth: .infinity, maxHeight: .infinity) }
        }
        .onAppear { maps.check(model); if chests.saveID != model.selection { chests.reset() } }
        .onChange(of: model.selection) { _, _ in chests.reset(); selected = nil }
        .onChange(of: query) { _, _ in chestPosition = 0; if !locations.contains(where: { $0.id == selected }) { selected = locations.first?.id } }
        .onChange(of: selected) { _, _ in chestPosition = 0 }
        .onChange(of: dimension) { _, _ in chestPosition = 0; selected = locations.first?.id }
    }
}
