import SwiftUI

struct ChecklistText: Decodable {
    let de: String
    let en: String
    func value(_ english: Bool) -> String { english ? en : de }
}
struct ChecklistSource: Decodable, Identifiable {
    let title: String
    let url: URL
    var id: String { url.absoluteString }
}
enum ChecklistStatus: String, Decodable, CaseIterable {
    case included, partial, planned, inProgress, unconfirmed, absent
    func title(_ english: Bool) -> String {
        switch self {
        case .included: return english ? "Present" : "Vorhanden"
        case .partial: return english ? "Partial" : "Teilweise"
        case .planned: return english ? "Planned · no release confirmed" : "Geplant · Freigabe offen"
        case .inProgress: return english ? "In progress · no release confirmed" : "In Arbeit · Freigabe offen"
        case .unconfirmed: return english ? "Unconfirmed" : "Nicht bestätigt"
        case .absent: return english ? "Confirmed absent" : "Bestätigt nicht vorhanden"
        }
    }
    var icon: String {
        switch self {
        case .included: return "checkmark.square.fill"
        case .partial: return "square.lefthalf.filled"
        case .planned, .inProgress: return "clock"
        case .unconfirmed: return "questionmark.square"
        case .absent: return "xmark.square"
        }
    }
    var color: Color {
        switch self {
        case .included: return .teal
        case .absent: return .red
        case .unconfirmed: return .secondary
        default: return .orange
        }
    }
}
struct MinecraftChecklistEntry: Decodable, Identifiable {
    let id: String
    let category: String
    let title: ChecklistText
    let minecraftStatus: ChecklistStatus
    let realmcraftStatus: ChecklistStatus
    let checkedAt: String
    let version: String
    let note: ChecklistText
    let sources: [ChecklistSource]
    let topicId: String
}
struct MinecraftChecklistCatalog: Decodable {
    let schemaVersion: Int
    let reviewedAt: String
    let realmcraftVersion: String
    let minecraftScope: String
    let entries: [MinecraftChecklistEntry]
    static func read() throws -> Self {
        guard let url = Bundle.main.url(forResource: "MinecraftChecklist", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let catalog = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard catalog.schemaVersion == 1, !catalog.entries.isEmpty,
              Set(catalog.entries.map(\.id)).count == catalog.entries.count,
              catalog.entries.allSatisfy({ !$0.sources.isEmpty && $0.sources.allSatisfy { $0.url.scheme == "https" } }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return catalog
    }
}
struct MinecraftChecklistView: View {
    let english: Bool
    let query: String
    @State private var status = "all"
    @State private var category = "all"
    private let catalog = try? MinecraftChecklistCatalog.read()
    private var categories: [String] { ["blocks", "items", "mechanics", "mobs", "world"].sorted { before(categoryName($0), categoryName($1)) } }
    private func before(_ a: String, _ b: String) -> Bool {
        a.compare(b, options: [.caseInsensitive, .numeric], locale: Locale(identifier: english ? "en" : "de")) == .orderedAscending
    }
    private func categoryName(_ key: String) -> String {
        switch key {
        case "blocks": return english ? "Blocks" : "Blöcke"
        case "items": return english ? "Items" : "Gegenstände"
        case "mechanics": return english ? "Mechanics & transport" : "Mechaniken & Transport"
        case "mobs": return "Mobs"
        default: return english ? "World" : "Welt"
        }
    }
    private var filtered: [MinecraftChecklistEntry] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return (catalog?.entries ?? []).filter { entry in
            (category == "all" || category == entry.category)
            && (status == "all" || (status == "open" ? entry.realmcraftStatus != .included : status == entry.realmcraftStatus.rawValue))
            && (search.isEmpty || [entry.title.de, entry.title.en, entry.note.de, entry.note.en, entry.version, entry.checkedAt].joined(separator: " ").localizedCaseInsensitiveContains(search))
        }.sorted { before($0.title.value(english), $1.title.value(english)) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(english ? "Minecraft ↔ RealmCraft VR · Checklist" : "Minecraft ↔ RealmCraft VR · Checkliste").font(.title2.bold())
                if let catalog {
                    Text(english ? "Reviewed: \(catalog.reviewedAt) · VR release baseline: \(catalog.realmcraftVersion) · \(catalog.minecraftScope)" : "Geprüft: \(catalog.reviewedAt) · VR-Referenzversion: \(catalog.realmcraftVersion) · \(catalog.minecraftScope)")
                        .font(.callout).foregroundStyle(.secondary)
                    Text(english ? "Selected features, not a complete block or mob inventory. Check again after every newer RealmCraft VR release. These marks record source evidence, not tasks you can tick off or observations in your world." : "Ausgewählte Inhalte, kein vollständiges Block- oder Mob-Inventar. Bei jedem neueren RealmCraft-VR-Release erneut prüfen. Die Symbole zeigen Quellenbelege, keine abhakbaren Aufgaben und keine Funde in deiner Welt.")
                    reviewNotes
                    filters
                    Text(english ? "\(filtered.count) of \(catalog.entries.count) entries" : "\(filtered.count) von \(catalog.entries.count) Einträgen").font(.caption).foregroundStyle(.secondary)
                    if filtered.isEmpty { Text(english ? "No matches. Change the search or filters." : "Keine Treffer. Suche oder Filter ändern.") }
                    ForEach(categories, id: \.self) { group in
                        let rows = filtered.filter { $0.category == group }
                        if !rows.isEmpty {
                            Text(categoryName(group)).font(.title3.bold())
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(rows) { entry in ChecklistEntryRow(entry: entry, english: english) }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(english ? "Checklist unavailable" : "Checkliste nicht verfügbar", systemImage: "exclamationmark.triangle", description: Text(english ? "The bundled checklist is missing or invalid." : "Die mitgelieferte Checkliste fehlt oder ist ungültig."))
                }
            }.padding(CompanionLayout.pageInset).frame(maxWidth: 1100, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    private var filters: some View {
        HStack {
            Picker(english ? "Category" : "Kategorie", selection: $category) {
                Text(english ? "All" : "Alle").tag("all")
                ForEach(categories, id: \.self) { Text(categoryName($0)).tag($0) }
            }
            Picker(english ? "VR status" : "VR-Status", selection: $status) {
                Text(english ? "All" : "Alle").tag("all")
                Text(english ? "Open / limited" : "Offen / eingeschränkt").tag("open")
                ForEach(ChecklistStatus.allCases, id: \.self) { Text($0.title(english)).tag($0.rawValue) }
            }
            Button(english ? "Reset filters" : "Filter zurücksetzen") { category = "all"; status = "all" }
        }
    }
    private var reviewNotes: some View {
        DisclosureGroup(english ? "Legend, wiki scope & next review" : "Legende, Wiki-Geltung & nächste Prüfung") {
            VStack(alignment: .leading, spacing: 12) {
                Text(english ? "Present = VR release evidence. Partial = limited coverage. Planned / in progress = roadmap status, with no release established here. Unconfirmed = insufficient evidence. Confirmed absent requires an explicit reliable absence statement; no entry currently meets that stricter standard. Roadmap labels can lag behind releases." : "Vorhanden = VR-Release-Beleg. Teilweise = eingeschränkter Umfang. Geplant / in Arbeit = Roadmap-Status, Veröffentlichung hier nicht belegt. Nicht bestätigt = Belege reichen nicht aus. Bestätigt nicht vorhanden verlangt einen ausdrücklichen belastbaren Negativbeleg; aktuell erfüllt kein Eintrag diesen strengeren Maßstab. Roadmap-Angaben können Releases hinterherhinken.")
                Text(english ? "The publisher links the general RealmCraft community wiki; it is not a VR-specific inventory. Minecraft Wiki is community-maintained, not a Mojang-owned official feature database. Wiki pages identify the counterpart; official VR releases and roadmap establish VR status. Some pages were available only through search excerpts or older indexed revisions; linked articles are not all freshly verified." : "Der Hersteller verlinkt das allgemeine RealmCraft-Community-Wiki; es ist kein VR-Inventar. Das Minecraft Wiki wird von der Community gepflegt und ist keine offizielle Mojang-Funktionsdatenbank. Wiki-Artikel erklären das Gegenstück; offizielle VR-Releases und Roadmap belegen den VR-Status. Manche Seiten waren nur als Suchauszug oder ältere indexierte Fassung zugänglich; nicht jeder verlinkte Artikel ist frisch verifiziert.")
                Text(english ? "Next release: check the version and platform, review both wikis and VR release notes, resolve roadmap conflicts, then update each affected entry's status, evidence, version and review date. Preserve the previous dated snapshot. This checklist does not refresh automatically." : "Nächstes Release: Version und Plattform abgleichen, beide Wikis und VR-Release-Notes prüfen, Roadmap-Widersprüche klären. Danach Status, Beleg, Version und Prüfdatum jedes betroffenen Eintrags aktualisieren. Vorherigen datierten Stand aufbewahren. Diese Checkliste aktualisiert sich nicht automatisch.")
                HStack {
                    Link("RealmCraft Wiki", destination: URL(string: "https://realmcraftgame.fandom.com/wiki/Mechanics")!)
                    Link("Minecraft Wiki", destination: URL(string: "https://de.minecraft.wiki/")!)
                    Link(english ? "VR releases" : "VR-Releases", destination: URL(string: "https://steamcommunity.com/app/2943620/allnews/")!)
                    Link("VR Roadmap", destination: URL(string: "https://realmcraft-vr.canny.io/")!)
                }
            }.font(.callout).padding(.top, 10)
        }
    }
}
private struct ChecklistEntryRow: View {
    let entry: MinecraftChecklistEntry
    let english: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.title.value(english)).font(.headline)
            HStack(alignment: .top, spacing: 24) {
                badge("Minecraft", entry.minecraftStatus)
                badge("RealmCraft VR", entry.realmcraftStatus)
            }
            Text(english ? "Reviewed \(entry.checkedAt) · Evidence: \(entry.version)" : "Geprüft \(entry.checkedAt) · Beleg: \(entry.version)")
                .font(.caption).foregroundStyle(.secondary)
            DisclosureGroup(english ? "Notes & sources" : "Hinweise & Quellen") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.note.value(english)).fixedSize(horizontal: false, vertical: true)
                    ForEach(entry.sources) { source in Link(source.title, destination: source.url) }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
            }.font(.callout)
            Divider()
        }.padding(.vertical, 12)
    }
    private func badge(_ game: String, _ status: ChecklistStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(game).font(.caption).foregroundStyle(.secondary)
            Label(status.title(english), systemImage: status.icon).foregroundStyle(status.color)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
