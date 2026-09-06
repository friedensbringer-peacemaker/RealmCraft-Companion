import SwiftUI

// Add a feature here, then provide its view in CompanionView. Storage and ADB remain shared.
enum CompanionFeature: String, CaseIterable, Identifiable {
    case home, saves, maps, chests, resources, guide
    var id: String { rawValue }
    var icon: String {
        switch self { case .home: return "square.grid.2x2"; case .saves: return "archivebox"; case .maps: return "map"; case .chests: return "shippingbox"; case .resources: return "globe"; case .guide: return "questionmark.circle" }
    }
    func title(_ english: Bool) -> String {
        switch self { case .home: return english ? "Home" : "Start"; case .saves: return "Savegames"; case .maps: return english ? "Maps" : "Karten"; case .chests: return english ? "Chests" : "Kisten"; case .resources: return english ? "Resources" : "Ressourcen"; case .guide: return english ? "Help" : "Hilfe" }
    }
    func detail(_ english: Bool) -> String {
        switch self {
        case .home: return english ? "Your RealmCraft companion" : "Dein Begleiter für RealmCraft"
        case .saves: return english ? "Back up, restore and organize your Quest worlds." : "Quest-Welten sichern, wiederherstellen und verwalten."
        case .maps: return english ? "Generate and explore maps from your saved worlds." : "Karten aus deinen gespeicherten Welten erzeugen und erkunden."
        case .chests: return english ? "Find stored items, quantities and chest coordinates." : "Gelagerte Gegenstände, Mengen und Kistenkoordinaten finden."
        case .resources: return english ? "Official website, videos, wiki and community." : "Offizielle Website, Videos, Wiki und Community."
        case .guide: return english ? "Step-by-step setup, agent help and release notes." : "Einrichtung, Agent-Hilfe und Versionshinweise."
        }
    }
}

struct CompanionView: View {
    @ObservedObject var model: Model
    @StateObject private var maps = MapController()
    @StateObject private var chests = ChestController()
    @AppStorage("appLanguage") private var language = "en"
    @AppStorage("companionFeature") private var selected = CompanionFeature.home.rawValue
    private var english: Bool { language == "en" }
    private var feature: CompanionFeature { CompanionFeature(rawValue: selected) ?? .home }
    private let poll = Timer.publish(every: 8, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                Image(systemName: "cube.transparent.fill").font(.system(size: 29)).foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 3) {
                    Text("RealmCraft Companion").font(.headline)
                    Text(english ? "Independent community app" : "Unabhängige Community-App").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Language", selection: $language) { Text("Deutsch").tag("de"); Text("English").tag("en") }
                    .labelsHidden().pickerStyle(.segmented).frame(width: 160)
                Button { model.showSetup = true } label: { Label(english ? "Setup" : "Einrichtung", systemImage: "gearshape") }
            }.padding(.horizontal, 24).padding(.vertical, 16).disabled(model.busy)
            HStack(spacing: 10) {
                ForEach(CompanionFeature.allCases) { item in
                    Button { selected = item.rawValue } label: {
                        Label(item.title(english), systemImage: item.icon).font(.system(size: 13, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 10)
                            .background(feature == item ? Color.teal.opacity(0.18) : Color.clear, in: RoundedRectangle(cornerRadius: 9))
                            .foregroundStyle(feature == item ? Color.teal : Color.primary)
                    }.buttonStyle(.plain).accessibilityAddTraits(feature == item ? .isSelected : [])
                }
                Spacer()
                if feature == .saves {
                    Button { model.importPanel() } label: { Label(english ? "Import" : "Importieren", systemImage: "square.and.arrow.down") }
                    Button { model.reload() } label: { Image(systemName: "arrow.clockwise") }.help(english ? "Refresh library" : "Library aktualisieren")
                }
            }.padding(.horizontal, 24).padding(.bottom, 12).disabled(model.busy)
            Divider()
            Group {
                switch feature {
                case .home: home
                case .saves: MainView(model: model, onMap: { selected = CompanionFeature.maps.rawValue })
                case .maps: MapsView(model: model, maps: maps, language: language)
                case .chests: ChestsView(model: model, maps: maps, chests: chests, language: language, openMaps: { selected = CompanionFeature.maps.rawValue })
                case .resources: ResourcesView(language: language)
                case .guide: HelpView(embedded: true)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 1000, minHeight: 850)
        .environment(\.locale, Locale(identifier: language))
        .sheet(isPresented: $model.showSetup) { SetupView(model: model) }
        .alert(english ? "Action incomplete" : "Aktion nicht abgeschlossen", isPresented: Binding(get: { model.error != nil && feature != .saves && !model.showSetup }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(tr(model.error ?? "")) }
        .onAppear { model.connect() }
        .onReceive(poll) { _ in model.connect() }
    }
    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(english ? "YOUR REALMCRAFT HUB" : "DEIN REALMCRAFT-BEGLEITER").font(.caption.bold()).tracking(2).foregroundStyle(.teal)
                    Text(english ? "More room for your adventures." : "Mehr Raum für deine Abenteuer.").font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(english ? "Manage your worlds, discover useful resources and get help — all in one place." : "Verwalte deine Welten, entdecke hilfreiche Quellen und finde Unterstützung – alles an einem Ort.")
                        .font(.title3).foregroundStyle(.secondary)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    ForEach([CompanionFeature.saves, .maps, .chests, .resources, .guide]) { item in
                        Button { selected = item.rawValue } label: {
                            VStack(alignment: .leading, spacing: 16) {
                                Image(systemName: item.icon).font(.system(size: 30)).foregroundStyle(.teal)
                                Text(item.title(english)).font(.title2.bold())
                                Text(item.detail(english)).font(.body).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                                Spacer(minLength: 0)
                                Label(english ? "Open" : "Öffnen", systemImage: "arrow.right").font(.callout.weight(.semibold)).foregroundStyle(.teal)
                            }.padding(24).frame(maxWidth: .infinity, minHeight: 210, alignment: .leading)
                                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
                        }.buttonStyle(.plain)
                    }
                    Button { model.showSetup = true } label: {
                        VStack(alignment: .leading, spacing: 16) {
                            Image(systemName: "gearshape").font(.system(size: 30)).foregroundStyle(.teal)
                            Text(english ? "Quest setup" : "Quest einrichten").font(.title2.bold())
                            Text(english ? "Check your connection, install ADB and choose your library." : "Verbindung prüfen, ADB installieren und die Library auswählen.").foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                            Spacer(minLength: 0)
                            Label(english ? "Open" : "Öffnen", systemImage: "arrow.right").font(.callout.weight(.semibold)).foregroundStyle(.teal)
                        }.padding(24).frame(maxWidth: .infinity, minHeight: 210, alignment: .leading).background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
                GroupBox {
                    HStack(spacing: 18) {
                        Image(systemName: "visionpro").font(.title).foregroundStyle(.teal)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(english ? "Quest connection" : "Quest-Verbindung").font(.headline)
                            Text(model.scanning ? (english ? "Checking connection…" : "Verbindung wird geprüft …") : tr(model.setup.message)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(english ? "Open setup" : "Einrichtung öffnen") { model.showSetup = true }
                    }.padding(14)
                }
                HStack {
                    Label(english ? "\(model.saves.count) saved world(s) in your library" : "\(model.saves.count) gesicherte Welt(en) in deiner Library", systemImage: "externaldrive")
                    Spacer()
                    Text("Companion 1.1.0").font(.caption)
                }.foregroundStyle(.secondary)
                Text(english ? "Community-built with OpenAI Codex and GPT-6 Astra. Not affiliated with the game publisher." : "Für die Community mit OpenAI Codex und GPT-6 Astra entwickelt. Nicht mit dem Spielehersteller verbunden.").font(.caption).foregroundStyle(.secondary)
            }.padding(32).frame(maxWidth: 1200).frame(maxWidth: .infinity)
        }
    }
}
