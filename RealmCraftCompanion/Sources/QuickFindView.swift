import SwiftUI

struct QuickFindView: View {
    let english: Bool
    let open: (QuickFindTarget) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var catalog: QuickFindCatalog?
    @State private var query = ""
    @State private var selected: String?
    @FocusState private var focused: Bool
    private var matches: [QuickFindMatch] { catalog?.search(query, english: english) ?? [] }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(english ? "Quick find · knowledge & help" : "Schnellsuche · Wissen & Hilfe", systemImage: "magnifyingglass").font(.title2.bold())
                Spacer()
                Button(english ? "Close" : "Schließen") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            TextField(english ? "Item, material, topic or help term · DE / EN" : "Gegenstand, Material, Thema oder Hilfebegriff · DE / EN", text: $query)
                .textFieldStyle(.roundedBorder).focused($focused).onSubmit { openSelection() }
                .accessibilityIdentifier("quickFind.search")
            Text(english ? "Search is local. Opening an entry resets its filters; no scan, playback or AI request starts. Video pages may load their usual online thumbnails."
                 : "Die Suche ist lokal. Öffnen setzt Eintragsfilter zurück; kein Scan, Videostart oder KI-Auftrag beginnt. Videoseiten können ihre üblichen Online-Vorschaubilder laden.")
                .font(.caption).foregroundStyle(.secondary)
            if let catalog {
                if !catalog.unavailable.isEmpty {
                    Label((english ? "Unavailable: " : "Nicht verfügbar: ") + catalog.unavailable.map { $0.title(english) }.joined(separator: ", "), systemImage: "exclamationmark.triangle").font(.caption)
                }
                let results = matches
                if results.isEmpty {
                    ContentUnavailableView(query.isEmpty ? (english ? "What are you looking for?" : "Was möchtest du nachschlagen?") : (english ? "No matches" : "Keine Treffer"), systemImage: "magnifyingglass",
                        description: Text(english ? "Search recipes, build guides, video notes and help. Try a shorter term or the other language." : "Durchsuche Rezepte, Bauanleitungen, Videonotizen und Hilfe. Versuche einen kürzeren Begriff oder die andere Sprache."))
                } else {
                    List(selection: $selected) {
                        ForEach(QuickFindKind.allCases, id: \.self) { kind in
                            let group = results.filter { $0.kind == kind }
                            if !group.isEmpty {
                                Section("\(kind.title(english)) · \(group.count)") {
                                    ForEach(Array(group.prefix(20))) { result in
                                        Button { open(result.target) } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Label(result.title, systemImage: kind.icon).font(.headline)
                                                Text(result.detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
                                        }.buttonStyle(.plain).tag(result.id)
                                    }
                                    if group.count > 20 { Text(english ? "First 20 shown; refine your search." : "Erste 20 angezeigt; Suche eingrenzen.").font(.caption).foregroundStyle(.secondary) }
                                }
                            }
                        }
                    }.onKeyPress(.return) { openSelection(); return .handled }
                }
            } else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
        }.padding(22).frame(minWidth: 620, idealWidth: 780, minHeight: 460, idealHeight: 620)
        .task {
            guard catalog == nil, let resources = Bundle.main.resourceURL else { return }
            catalog = await Task.detached(priority: .userInitiated) { QuickFindCatalog.load(resources: resources) }.value
            focused = true
        }
        .onChange(of: query) { _, _ in selected = matches.first?.id }
    }
    private func openSelection() {
        guard let result = matches.first(where: { $0.id == selected }) ?? matches.first else { return }
        open(result.target)
    }
}
