import SwiftUI

struct CompanionResource: Decodable, Identifiable {
    let id: String
    let icon: String
    let category: String
    let title: String
    let de: String
    let en: String
    let url: URL
    let source: URL
}
struct ResourcesView: View {
    @Environment(\.companionTheme) private var theme
    let language: String
    @State private var query = ""
    @State private var section = "knowledge"
    private var english: Bool { language == "en" }
    private let categories = ["official", "community", "reference"]
    private let resources: [CompanionResource] = {
        guard let url = Bundle.main.url(forResource: "CommunityLinks", withExtension: "json"), let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([CompanionResource].self, from: data) else { return [] }
        return items.filter { $0.url.scheme == "https" && $0.source.scheme == "https" }
    }()
    private var filtered: [CompanionResource] { resources.filter { query.isEmpty || ($0.title + (english ? $0.en : $0.de)).localizedCaseInsensitiveContains(query) } }
    private func title(_ category: String) -> String {
        switch category { case "official": return english ? "Official RealmCraft VR links" : "Offizielle RealmCraft-VR-Links"; case "community": return "Community"; default: return english ? "Wiki & reference" : "Wiki & Nachschlagen" }
    }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Links & Knowledge" : "Links & Wissen") {
                TextField(english ? "Search this section" : "Diesen Bereich durchsuchen", text: $query).textFieldStyle(.roundedBorder).frame(width: CompanionLayout.searchWidth)
            }
            HStack {
                Picker(english ? "Section" : "Bereich", selection: $section) {
                    Text(english ? "Minecraft comparison" : "Minecraft-Vergleich").tag("knowledge")
                    Text(english ? "Content checklist" : "Inhalte-Checkliste").tag("checklist")
                    Text(english ? "Links & community" : "Links & Community").tag("links")
                }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 640)
                Spacer()
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            Divider()
            if section == "knowledge" {
                MinecraftComparisonView(english: english, query: query)
            } else if section == "checklist" {
                MinecraftChecklistView(english: english, query: query)
            } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                ForEach(categories, id: \.self) { category in
                    let items = filtered.filter { $0.category == category }
                    if !items.isEmpty {
                        Text(title(category)).font(.title2.bold())
                        LazyVStack(spacing: 0) {
                            ForEach(items) { item in ResourceCard(item: item, english: english) }
                        }
                    }
                }
                if filtered.isEmpty { Text(english ? "No matching links." : "Keine passenden Links.").foregroundStyle(.secondary).padding(.vertical, 30) }
                Text(english ? "Reference collection dated 5 September 2026. Websites open in your default browser; external content needs internet. No pages or videos load in the background." : "Quellensammlung vom 5. September 2026. Websites öffnen im Standardbrowser; externe Inhalte benötigen Internet. Seiten oder Videos werden nicht im Hintergrund geladen.")
                    .font(.caption).foregroundStyle(.secondary)
                }.padding(CompanionLayout.pageInset).frame(maxWidth: 1280).frame(maxWidth: .infinity, alignment: .leading)
            }.id(section)
            }
        }
    }
}
private struct ResourceCard: View {
    @Environment(\.companionTheme) private var theme
    let item: CompanionResource
    let english: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: item.icon).foregroundStyle(.secondary).font(.title3).frame(width: 24).padding(.top, 2)
            VStack(alignment: .leading, spacing: 6) {
                Link(item.title, destination: item.url).buttonStyle(.plain).font(.headline).foregroundStyle(theme.accent)
                Text(english ? item.en : item.de).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    Text(item.url.host ?? "").foregroundStyle(.tertiary)
                    Link(english ? "Source" : "Quelle", destination: item.source).buttonStyle(.plain).foregroundStyle(.secondary)
                }.font(.caption)
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 18).frame(maxWidth: .infinity, alignment: .leading)
        Divider()
    }
}


private struct ComparisonText: Decodable {
    let de: String
    let en: String
    func value(_ english: Bool) -> String { english ? en : de }
}
private struct ComparisonSource: Decodable, Identifiable {
    let title: String
    let url: URL
    var id: String { url.absoluteString }
}
private struct MinecraftComparison: Decodable, Identifiable {
    let id: String
    let category: String
    let status: String
    let title: ComparisonText
    let realmcraft: ComparisonText
    let minecraft: ComparisonText
    let difference: ComparisonText
    let realmcraftWiki: URL
    let minecraftWiki: URL
    let sources: [ComparisonSource]
    let version: String
    func matches(_ query: String) -> Bool {
        let text = [title.de, title.en, realmcraft.de, realmcraft.en, minecraft.de, minecraft.en,
                    difference.de, difference.en, version, "Minecraft RealmCraft"]
        return query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || text.joined(separator: " ").localizedCaseInsensitiveContains(query)
    }
}
private struct MinecraftComparisonView: View {
    @Environment(\.companionTheme) private var theme
    let english: Bool
    let query: String
    @State private var category = "all"
    @State private var selectedTopic: String?
    private let categories = ["all", "blocks", "items", "mobs", "mechanics", "world"]
    private let entries: [MinecraftComparison] = {
        guard let url = Bundle.main.url(forResource: "MinecraftComparison", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([MinecraftComparison].self, from: data) else { return [] }
        return entries.filter {
            $0.realmcraftWiki.scheme == "https" && $0.minecraftWiki.scheme == "https"
                && $0.sources.allSatisfy { $0.url.scheme == "https" }
        }
    }()
    private var sortLocale: Locale { Locale(identifier: english ? "en" : "de") }
    private func alphabeticallyBefore(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: [.caseInsensitive, .numeric], locale: sortLocale) == .orderedAscending
    }
    private var sortedCategories: [String] {
        categories.filter { $0 != "all" }.sorted { alphabeticallyBefore(categoryTitle($0), categoryTitle($1)) }
    }
    private var filtered: [MinecraftComparison] {
        entries.filter { (category == "all" || $0.category == category) && $0.matches(query) }
            .sorted { lhs, rhs in
                if lhs.category != rhs.category {
                    return alphabeticallyBefore(categoryTitle(lhs.category), categoryTitle(rhs.category))
                }
                return alphabeticallyBefore(lhs.title.value(english), rhs.title.value(english))
            }
    }
    private func categoryTitle(_ value: String) -> String {
        switch value {
        case "blocks": return english ? "Blocks" : "Blöcke"
        case "items": return english ? "Items" : "Gegenstände"
        case "mobs": return "Mobs"
        case "mechanics": return english ? "Mechanics" : "Mechaniken"
        case "world": return english ? "World" : "Welt"
        default: return english ? "All topics" : "Alle Themen"
        }
    }
    private var current: MinecraftComparison? {
        filtered.first { $0.id == selectedTopic } ?? filtered.first
    }
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Picker(english ? "Category" : "Kategorie", selection: $category) {
                    ForEach(["all"] + sortedCategories, id: \.self) { Text(categoryTitle($0)).tag($0) }
                }.labelsHidden().padding(.horizontal, 16).padding(.top, 16)
                List(selection: Binding<String?>(get: { current?.id }, set: { selectedTopic = $0 })) {
                    ForEach(sortedCategories, id: \.self) { group in
                        let items = filtered.filter { $0.category == group }
                        if !items.isEmpty {
                            Section(categoryTitle(group)) {
                                ForEach(items) { item in
                                    Text(item.title.value(english))
                                        .font(.callout).fixedSize(horizontal: false, vertical: true)
                                        .padding(.vertical, 7).tag(item.id)
                                }
                            }
                        }
                    }
                }.listStyle(.sidebar).scrollContentBackground(.hidden)
                Text(english ? "\(filtered.count) topics" : "\(filtered.count) Themen")
                    .font(.caption).foregroundStyle(.secondary).padding(16)
            }.frame(width: CompanionTheme.sidebarWidth)
            Divider()
            if let item = current {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("RealmCraft VR ↔ Minecraft").font(.subheadline).foregroundStyle(.secondary)
                        ComparisonCard(item: item, english: english).id(item.id)
            DisclosureGroup(english ? "About this comparison · 5 September 2026" : "Über diesen Vergleich · 5. September 2026") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(english
                         ? "RealmCraft VR: published updates through 1.0.3 (20 August 2026); availability on your device depends on the installed version. Minecraft: vanilla Java/Bedrock, with edition differences where relevant. This is a sourced selection, not a complete inventory or an in-game audit."
                         : "RealmCraft VR: veröffentlichte Updates bis 1.0.3 (20. August 2026); auf deinem Gerät zählt die installierte Version. Minecraft: Vanilla Java/Bedrock, mit Hinweisen auf Editionsunterschiede. Dies ist eine belegte Auswahl, kein vollständiges Inventar und kein Ingame-Test.")
                    Text(english
                         ? "Included = documented in VR updates. Partial / unconfirmed = only the stated scope is established. The RealmCraft Wiki covers the general game, not specifically VR. Minecraft Wiki articles describe Minecraft; neither wiki proves VR feature parity."
                         : "Enthalten = in VR-Quellen dokumentiert. Teilweise / offen = nur der genannte Umfang ist belegt. Das RealmCraft-Wiki beschreibt das allgemeine Spiel, nicht speziell VR. Die Minecraft-Wiki-Artikel beschreiben Minecraft; beide Wikis belegen keine VR-Funktionsgleichheit.")
            Text(english
                 ? "Source note: the old Steam Early Access text still mentions an Overworld-only build. Later dated updates establish the Nether and other additions. Catalog names and numeric IDs alone do not prove that a block, item or mechanic is usable. Wiki destinations are reference links; automated access to some wiki pages was restricted."
                 : "Quellenhinweis: Der ältere Steam-Early-Access-Text beschreibt noch eine Version nur mit Oberwelt. Spätere datierte Updates belegen den Nether und weitere Ergänzungen. Katalognamen und numerische IDs allein beweisen nicht, dass ein Block, Gegenstand oder eine Mechanik nutzbar ist. Wiki-Ziele dienen zum Nachschlagen; der automatisierte Zugriff auf einige Wiki-Seiten war eingeschränkt.")
                .font(.caption).foregroundStyle(.secondary)

                    HStack(spacing: 20) {
                        Link("RealmCraft Wiki", destination: URL(string: "https://realmcraftgame.fandom.com/wiki/RealmCraft_Game_Wiki")!)
                        Link("Minecraft Wiki", destination: URL(string: "https://minecraft.wiki/")!)
                    }
                }.buttonStyle(.plain).font(.callout).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 12)
            }.padding(.vertical, 12)

                    }.padding(CompanionLayout.pageInset).frame(maxWidth: 900, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.id(item.id)
            } else {
                ContentUnavailableView(english ? "No matching topics" : "Keine passenden Themen",
                    systemImage: "text.magnifyingglass",
                    description: Text(entries.isEmpty
                        ? (english ? "The comparison could not be loaded." : "Der Vergleich konnte nicht geladen werden.")
                        : (english ? "Change your search or select all topics." : "Ändere die Suche oder wähle alle Themen.")))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct ComparisonCard: View {
    @Environment(\.companionTheme) private var theme
    let item: MinecraftComparison
    let english: Bool
    private var included: Bool { item.status == "included" }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title.value(english)).font(.title2.bold())
                Label(included ? (english ? "Included in VR" : "In VR enthalten")
                      : (english ? "Partial / unconfirmed" : "Teilweise / offen"),
                      systemImage: included ? "checkmark.circle" : "circle.lefthalf.filled")
                    .font(.caption.weight(.semibold)).foregroundStyle(included ? theme.accent : Color.orange)
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    column("RealmCraft VR", item.realmcraft.value(english)).frame(minWidth: 240)
                    column("Minecraft", item.minecraft.value(english)).frame(minWidth: 240)
                }
                VStack(alignment: .leading, spacing: 20) {
                    column("RealmCraft VR", item.realmcraft.value(english))
                    column("Minecraft", item.minecraft.value(english))
                }
            }

            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text(english ? "Differences & what to check" : "Unterschiede & worauf du achten solltest").font(.headline)
                Text(item.difference.value(english)).fixedSize(horizontal: false, vertical: true)
            }
            Text(item.version).font(.caption.monospaced()).foregroundStyle(.secondary)
            DisclosureGroup(english ? "Sources & update evidence" : "Quellen & Update-Belege") {
                VStack(alignment: .leading, spacing: 8) {
                    Link("RealmCraft Wiki", destination: item.realmcraftWiki)
                    Link("Minecraft Wiki", destination: item.minecraftWiki)
                    ForEach(item.sources) { source in Link(source.title, destination: source.url) }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
            }.font(.callout)
        }.textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)

    }
    private func column(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(theme.accent)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
