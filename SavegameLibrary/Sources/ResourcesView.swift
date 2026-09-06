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
    let language: String
    @State private var query = ""
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(english ? "Resources & community" : "Ressourcen & Community").font(.largeTitle.bold())
                        Text(english ? "Useful places to learn, watch and connect." : "Hilfreiche Anlaufstellen zum Lernen, Anschauen und Austauschen.").foregroundStyle(.secondary)
                    }
                    Spacer()
                    TextField(english ? "Search resources" : "Ressourcen suchen", text: $query).textFieldStyle(.roundedBorder).frame(width: 240)
                }
                ForEach(categories, id: \.self) { category in
                    let items = filtered.filter { $0.category == category }
                    if !items.isEmpty {
                        Text(title(category)).font(.title2.bold())
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(items) { item in ResourceCard(item: item, english: english) }
                        }
                    }
                }
                if filtered.isEmpty { Text(english ? "No matching resources." : "Keine passenden Ressourcen.").foregroundStyle(.secondary).padding(.vertical, 30) }
                Text(english ? "Links checked 5 September 2026. Websites open in your default browser; external content needs internet. No pages or videos load in the background." : "Links geprüft am 5. September 2026. Websites öffnen im Standardbrowser; externe Inhalte benötigen Internet. Seiten oder Videos werden nicht im Hintergrund geladen.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(32).frame(maxWidth: 1200).frame(maxWidth: .infinity)
        }
    }
}
private struct ResourceCard: View {
    let item: CompanionResource
    let english: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Image(systemName: item.icon).foregroundStyle(.teal).font(.title2); Text(item.title).font(.headline); Spacer() }
            Text(english ? item.en : item.de).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(item.url.host ?? "").font(.caption.monospaced()).foregroundStyle(.secondary)
            HStack {
                Link(destination: item.url) { Label(english ? "Open website" : "Website öffnen", systemImage: "arrow.up.right.square") }.buttonStyle(.bordered)
                Spacer()
                Link(english ? "Source" : "Quelle", destination: item.source).font(.caption)
            }
        }.padding(20).frame(maxWidth: .infinity, minHeight: 175, alignment: .leading)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }
}
