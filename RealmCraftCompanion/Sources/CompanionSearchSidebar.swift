import SwiftUI

/// One local index and one query for the persistent field and its advanced filters.
/// Navigation is supplied by the shell; result activation still passes through its draft guard.
struct CompanionSearchSidebar<Navigation: View>: View {
    let english: Bool
    @Binding var focusRequest: UUID
    let open: (QuickFindTarget) -> Bool
    @ViewBuilder let navigation: () -> Navigation
    @State private var catalog: QuickFindCatalog?
    @State private var query = ""
    @State private var kinds = Set(QuickFindKind.allCases)
    @State private var showFilters = false
    @State private var selection: String?
    @FocusState private var focused: Bool
    init(english: Bool, focusRequest: Binding<UUID>, catalog: QuickFindCatalog? = nil,
         query: String = "", kinds: Set<QuickFindKind> = Set(QuickFindKind.allCases),
         open: @escaping (QuickFindTarget) -> Bool, @ViewBuilder navigation: @escaping () -> Navigation) {
        self.english = english; _focusRequest = focusRequest; self.open = open; self.navigation = navigation
        _catalog = State(initialValue: catalog); _query = State(initialValue: query); _kinds = State(initialValue: kinds)
    }
    private var searching: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var matches: [QuickFindMatch] { catalog?.search(query, english: english, kinds: kinds) ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { focused = true } label: { Image(systemName: "magnifyingglass") }
                    .buttonStyle(.plain).frame(width: 24, height: 28)
                    .keyboardShortcut("f", modifiers: [.command, .shift])
                    .accessibilityLabel(english ? "Focus quick find" : "Schnellsuche fokussieren")
                TextField(english ? "Quick find…" : "Schnellsuche …", text: $query)
                    .textFieldStyle(.roundedBorder).focused($focused)
                    .accessibilityIdentifier("quickFind.search")
                    .help(english ? "Recipes, build guides, video notes and help · DE / EN" : "Rezepte, Bauanleitungen, Videonotizen und Hilfe · DE / EN")
                    .onSubmit { activateSelection() }
                    .onKeyPress(.escape) { clear(); return .handled }
                if searching {
                    Button { clear(); focused = true } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).accessibilityLabel(english ? "Clear search" : "Suche leeren")
                }
                Button { showFilters.toggle() } label: {
                    Image(systemName: kinds.count == QuickFindKind.allCases.count ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }.buttonStyle(.plain).frame(width: 28, height: 28)
                    .accessibilityLabel(english ? "Advanced search" : "Erweiterte Suche")
                    .help(english ? "Advanced search" : "Erweiterte Suche")
                    .popover(isPresented: $showFilters) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(english ? "Search in" : "Suchen in").font(.headline)
                            ForEach(QuickFindKind.allCases, id: \.self) { kind in
                                Toggle(kind.title(english), isOn: Binding(get: { kinds.contains(kind) }, set: { enabled in
                                    if enabled { kinds.insert(kind) } else { kinds.remove(kind) }
                                }))
                            }
                            Button(english ? "All categories" : "Alle Kategorien") { kinds = Set(QuickFindKind.allCases) }
                            Text(english ? "Local knowledge only. No world scan, playback or AI request. Opening a video page may load online thumbnails." : "Nur lokales Wissen. Kein Welt-Scan, Videostart oder KI-Auftrag. Videoseiten können Online-Vorschaubilder laden.")
                                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }.padding(18).frame(width: 290)
                    }
            }.padding(.horizontal, 10).padding(.bottom, 8)
            if kinds.count != QuickFindKind.allCases.count {
                HStack {
                    Text(english ? "\(kinds.count) of 4 categories" : "\(kinds.count) von 4 Kategorien").font(.caption)
                    Spacer()
                    Button(english ? "Reset" : "Zurücksetzen") { kinds = Set(QuickFindKind.allCases) }.font(.caption)
                }.padding(.horizontal, 14).padding(.bottom, 8)
            }
            if searching { results } else { navigation() }
        }
        .task {
            guard catalog == nil, let resources = Bundle.main.resourceURL else { return }
            catalog = await Task.detached(priority: .userInitiated) { QuickFindCatalog.load(resources: resources) }.value
        }
        .onChange(of: focusRequest) { _, _ in focused = true }
        .onChange(of: query) { _, _ in selection = nil }
        .onChange(of: kinds) { _, _ in selection = nil }
    }
    private var results: some View {
        let found = matches
        return VStack(alignment: .leading, spacing: 6) {
            Text(english ? "Knowledge & help" : "Wissen & Hilfe").font(.caption.weight(.semibold)).padding(.horizontal, 14)
            if let catalog {
                if !catalog.unavailable.isEmpty {
                    Label((english ? "Unavailable: " : "Nicht verfügbar: ") + catalog.unavailable.map { $0.title(english) }.joined(separator: ", "), systemImage: "exclamationmark.triangle")
                        .font(.caption).padding(.horizontal, 14)
                }
                if found.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(kinds.isEmpty ? (english ? "Select a search category." : "Wähle eine Suchkategorie.") : (english ? "No matches. Try a shorter term or the other language." : "Keine Treffer. Versuche einen kürzeren Begriff oder die andere Sprache."))
                            .font(.callout).foregroundStyle(.secondary)
                        Button(english ? "Back to navigation" : "Zur Navigation") { clear() }
                    }.padding(14)
                    Spacer()
                } else {
                    List(selection: $selection) {
                        ForEach(QuickFindKind.allCases, id: \.self) { kind in
                            let group = found.filter { $0.kind == kind }
                            if !group.isEmpty {
                                Section {
                                    ForEach(Array(group.prefix(20))) { result in
                                        Button { activate(result) } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(result.title).font(.callout.weight(.medium)).foregroundStyle(.primary).lineLimit(3)
                                                Text(result.detail).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
                                        }.buttonStyle(.plain).tag(result.id)
                                    }
                                    if group.count > 20 { Text(english ? "First 20 shown. Refine your search." : "Erste 20 angezeigt. Suche eingrenzen.").font(.caption) }
                                } header: {
                                    Text("\(kind.title(english)) · \(group.count)").foregroundStyle(.secondary)
                                }
                            }
                        }
                    }.listStyle(.sidebar).scrollContentBackground(.hidden)
                        .onKeyPress(.return) { activateSelection(); return .handled }
                        .onKeyPress(.escape) { clear(); focused = true; return .handled }
                }
            } else { ProgressView().padding(); Spacer() }
        }
    }
    private func clear() { query = ""; selection = nil }
    private func activate(_ result: QuickFindMatch) {
        if open(result.target) { clear(); focused = false }
    }
    private func activateSelection() {
        guard let result = matches.first(where: { $0.id == selection }) ?? matches.first else { return }
        activate(result)
    }
}
