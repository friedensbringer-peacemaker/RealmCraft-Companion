import SwiftUI

struct ChestStatisticsView: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @ObservedObject var chests: ChestController
    let language: String
    let openMaps: () -> Void
    @AppStorage("exploration.spoilerFree") private var knownOnly = false
    @State private var query = ""
    @State private var dimension = "all"
    @State private var category = "all"
    @State private var playerOnly = false
    @State private var sort = "all"
    @State private var ascending = false
    @State private var grouped = true
    @State private var summary: ChestStockSummary?
    @State private var failure: String?
    @State private var summaryKey = ""
    @Environment(\.companionTheme) private var theme
    private var english: Bool { language == "en" }
    private var selectionKey: String { model.library.root.path + ":" + (model.selection ?? "") }
    private var current: ChestStockSummary? { summaryKey == selectionKey ? summary : nil }
    private var allLabel: String { knownOnly ? (english ? "All known" : "Alle bekannten") : (english ? "All chests" : "Alle Truhen") }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(english ? "Chest contents · Beta" : "Truhenbestände · Beta", systemImage: "shippingbox.fill").font(.title2.bold())
                Spacer()
                Button(english ? "Read chests" : "Truhen auslesen") { chests.scan(model, maps: maps, english: english) }
                    .buttonStyle(CompanionButtonStyle(prominent: true))
                    .disabled(model.selected == nil || model.busy || model.scanning || !maps.ready || maps.checking)
            }
            Text(english ? "Current quantities in the selected backup, not lifetime collected resources. Presumed player chests are a subset: your ownership marks and automatic assignments from nearby signs, as in Chests. Ownership and thematic categories are Beta estimates." : "Aktuelle Stückzahlen in der gewählten Sicherung, keine insgesamt gesammelten Ressourcen. Vermutliche Spielertruhen sind eine Teilmenge: deine Eigentumsmarkierungen und automatische Zuordnungen über nahe Schilder wie unter Kisten. Eigentum und thematische Gruppen sind Beta-Zuordnungen.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if !maps.ready {
                HStack {
                    Text(english ? "Map tools are required to read chests." : "Zum Auslesen werden die Kartenwerkzeuge benötigt.")
                    Button(english ? "Set up in Maps" : "In Karten einrichten", action: openMaps)
                }
            }
            if let failure { Label(failure, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }
            if let value = current {
                controls
                Text(english
                     ? "Readable chests: \(value.readable) · presumed player: \(value.playerReadable). Unreadable: \(value.unreadable) · presumed player: \(value.playerUnreadable)."
                     : "Lesbare Truhen: \(value.readable) · vermutlich Spieler: \(value.playerReadable). Unlesbar: \(value.unreadable) · vermutlich Spieler: \(value.playerUnreadable).")
                    .font(.caption).foregroundStyle(.secondary)
                Text(knownOnly
                     ? (english ? "Spoiler-light mode: only already-known chests are counted. Hidden known chests are included." : "Spoilerarm: Es zählen nur bereits bekannte Truhen. Ausgeblendete bekannte Truhen zählen mit.")
                     : (english ? "All includes hidden and generated chests. Search and item filters affect the totals below; the readable-chest counts above use only the dimension filter." : "Alle umfasst auch ausgeblendete und generierte Truhen. Suche und Itemfilter ändern die Summen unten; die Truhenanzahlen oben verwenden nur den Dimensionsfilter."))
                    .font(.caption).foregroundStyle(.secondary)
                if value.unreadable > 0 || value.scanIssues > 0 || value.invalidStacks > 0 || value.duplicateRecords > 0 {
                    Label(english
                          ? "Partial result: \(value.scanIssues) scan issues, \(value.invalidStacks) invalid stacks, \(value.duplicateRecords) duplicate records. Unreadable contents are excluded, not counted as zero."
                          : "Teilergebnis: \(value.scanIssues) Scanprobleme, \(value.invalidStacks) ungültige Stapel, \(value.duplicateRecords) doppelte Datensätze. Unlesbare Inhalte sind ausgeschlossen und zählen nicht als null.", systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(.orange)
                }
                results(value)
            } else if failure == nil {
                Text(english ? "Read chests to see quantities by item and theme. An index already read in Chests can also be used here." : "Lies die Truhen aus, um Stückzahlen nach Item und Thema zu sehen. Ein bereits unter Kisten gelesener Index wird auch hier verwendet.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22).background(theme.surface).clipShape(RoundedRectangle(cornerRadius: theme.radius))
        .onAppear { maps.check(model); rebuild() }
        .onChange(of: chests.output) { _, _ in rebuild() }
        .onChange(of: chests.saveID) { _, _ in rebuild() }
        .onChange(of: selectionKey) { _, _ in rebuild() }
        .onChange(of: dimension) { _, _ in rebuild() }
        .onChange(of: knownOnly) { _, _ in rebuild() }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in rebuild() }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(english ? "Search items: name or ID (English / German)" : "Items suchen: Name oder ID (Deutsch / Englisch)", text: $query)
                .textFieldStyle(.roundedBorder)
            HStack {
                Picker(english ? "Dimension" : "Dimension", selection: $dimension) {
                    Text(english ? "Both" : "Beide").tag("all")
                    Text(english ? "Overworld" : "Oberwelt").tag("o")
                    Text("Nether").tag("n")
                }
                Picker(english ? "Theme" : "Thema", selection: $category) {
                    Text(english ? "All themes" : "Alle Themen").tag("all")
                    ForEach(ChestItemCategory.allCases) { Text($0.title(english: english)).tag($0.rawValue) }
                }
            }
            Toggle(english ? "Only items in presumed player chests" : "Nur Items in vermutlichen Spielertruhen", isOn: $playerOnly)
            HStack {
                Picker(english ? "Sort by" : "Sortieren nach", selection: $sort) {
                    Text(allLabel + (english ? " · quantity" : " · Anzahl")).tag("all")
                    Text(english ? "Player · quantity" : "Spieler · Anzahl").tag("player")
                    Text(english ? "Item name" : "Itemname").tag("name")
                    Text("ID").tag("id")
                }
                Toggle(english ? "Ascending" : "Aufsteigend", isOn: $ascending)
                Toggle(english ? "Group by theme" : "Nach Thema gruppieren", isOn: $grouped)
            }
            Button(english ? "Reset filters" : "Filter zurücksetzen") {
                query = ""; dimension = "all"; category = "all"; playerOnly = false; sort = "all"; ascending = false; grouped = true
            }.font(.caption)
        }
    }

    @ViewBuilder private func results(_ value: ChestStockSummary) -> some View {
        let rows = value.filtered(names: chests.names, query: query, category: category, playerOnly: playerOnly, sort: sort, ascending: ascending, english: english)
        if let total = try? ChestStockSummary.total(rows, player: false), let player = try? ChestStockSummary.total(rows, player: true) {
            HStack(alignment: .firstTextBaseline) {
                Text(english ? "\(rows.count) item types · filtered quantities" : "\(rows.count) Itemtypen · gefilterte Stückzahlen").font(.headline)
                Spacer()
                Text(allLabel + ": " + number(total)).monospacedDigit()
                Text((english ? "Player: " : "Spieler: ") + number(player)).monospacedDigit()
            }
        } else {
            Text(english ? "Total unavailable: quantity exceeds supported range." : "Gesamtsumme nicht verfügbar: Zahlenbereich überschritten.").foregroundStyle(.orange)
        }
        HStack {
            Text("Item / ID").frame(maxWidth: .infinity, alignment: .leading)
            Text(allLabel).frame(width: 130, alignment: .trailing)
            Text(english ? "Presumed player" : "Vermutlich Spieler").frame(width: 145, alignment: .trailing)
        }.font(.caption.bold())
        Text(english ? "Each cell shows quantity and the number of chests containing this item. Sorting applies within themes; disable grouping for a global ranking." : "Je Spalte: Stückzahl und Anzahl der Truhen mit diesem Item. Sortierung gilt innerhalb der Themen; ohne Gruppierung entsteht eine gemeinsame Rangliste.")
            .font(.caption).foregroundStyle(.secondary)
        if rows.isEmpty {
            Text(english ? "No readable items match these filters." : "Keine lesbaren Items passen zu diesen Filtern.").foregroundStyle(.secondary)
        }
        LazyVStack(alignment: .leading, spacing: 0) {
            if grouped {
                ForEach(ChestItemCategory.allCases) { group in
                    let members = rows.filter { ChestItemCategory.classify(itemID: $0.id, name: chests.names[String($0.id)]) == group }
                    if !members.isEmpty {
                        Text(group.title(english: english)).font(.headline).foregroundStyle(theme.accent).padding(.top, 18).padding(.bottom, 8)
                        ForEach(members) { itemRow($0) }
                    }
                }
            } else { ForEach(rows) { itemRow($0) } }
        }
    }

    private func itemRow(_ row: ChestStockItem) -> some View {
        VStack(spacing: 0) {
            HStack {
                ItemIcon(itemID: row.id)
                VStack(alignment: .leading, spacing: 3) {
                    Text(chests.name(row.id, english: english)).font(.callout.weight(.medium))
                    Text("ID " + String(row.id)).font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                quantity(row.all, count: row.allChests).frame(width: 130, alignment: .trailing)
                quantity(row.player, count: row.playerChests).frame(width: 145, alignment: .trailing)
            }.padding(.vertical, 9)
            Divider()
        }.textSelection(.enabled)
    }

    private func quantity(_ value: Int64, count: Int) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(number(value)).font(.body.weight(.semibold)).monospacedDigit()
            Text(english ? (count == 1 ? "in 1 chest" : "in \(count) chests") : (count == 1 ? "in 1 Truhe" : "in \(count) Truhen")).font(.caption).foregroundStyle(.secondary)
        }
    }
    private func number(_ value: Int64) -> String { value.formatted(.number.locale(Locale(identifier: language))) }

    private func rebuild() {
        summary = nil; failure = nil; summaryKey = ""
        guard let save = model.selected, chests.saveID == save.id, let index = chests.index else { return }
        do {
            summary = try ChestStockSummary.make(index: index, visibility: ChestVisibility.load(world: save.annotationScope), dimension: dimension, knownOnly: knownOnly)
            summaryKey = selectionKey
        } catch {
            failure = english ? "Chest totals could not be calculated: invalid quantity range." : "Truhensummen konnten nicht berechnet werden: ungültiger Zahlenbereich."
        }
    }
}
