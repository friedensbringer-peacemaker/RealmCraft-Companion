import SwiftUI

// Add a feature here, then provide its view in CompanionView. Storage and ADB remain shared.
enum CompanionFeature: String, CaseIterable, Identifiable {
    case editor, home, saves, maps, chests, resources, builds, videos, guide, player, conversation, mobs, aiExport, statistics, skills
    static let worldFeatures: [Self] = [.saves, .player, .maps, .chests, .statistics, .editor]
    static let aiFeatures: [Self] = [.aiExport, .conversation, .skills]
    static let knowledgeFeatures: [Self] = [.videos, .builds, .mobs, .resources, .guide]
    static var navigationOrder: [Self] { [.home] + worldFeatures + aiFeatures + knowledgeFeatures }
    var id: String { rawValue }
    var icon: String {
        switch self { case .skills: return "text.book.closed"; case .videos: return "play.rectangle"; case .statistics: return "chart.bar.xaxis"; case .editor: return "slider.horizontal.3"; case .aiExport: return "doc.text.magnifyingglass"; case .mobs: return "pawprint"; case .conversation: return "bubble.left.and.bubble.right"; case .player: return "person.crop.rectangle"; case .home: return "square.grid.2x2"; case .saves: return "archivebox"; case .maps: return "map"; case .chests: return "shippingbox"; case .resources: return "globe"; case .builds: return "square.grid.3x3"; case .guide: return "questionmark.circle" }
    }
    func title(_ english: Bool) -> String {
        switch self { case .skills: return "Skills"; case .videos: return english ? "Videos & tips" : "Videos & Tipps"; case .statistics: return english ? "Statistics · Beta" : "Statistiken · Beta"; case .editor: return "Editor · Beta"; case .aiExport: return english ? "AI export" : "KI-Export"; case .mobs: return "Mobs & Animals"; case .conversation: return english ? "Conversation · Beta" : "Gespräch · Beta"; case .player: return english ? "Player" : "Spieler"; case .home: return english ? "Home" : "Start"; case .saves: return "Savegames"; case .maps: return english ? "Maps" : "Karten"; case .chests: return english ? "Chests" : "Kisten"; case .resources: return english ? "Links & Knowledge" : "Links & Wissen"; case .builds: return english ? "Build guides" : "Bauanleitungen"; case .guide: return english ? "Help" : "Hilfe" }
    }
    func detail(_ english: Bool) -> String {
        switch self {
        case .skills: return english ? "Manage reusable instructions and personal context for agents." : "Wiederverwendbare Anweisungen und eigene Angaben für Agenten verwalten."
        case .videos: return english ? "Search video topics and jump to timestamped tips." : "Videothemen durchsuchen und direkt zu passenden Tipps springen."
        case .statistics: return english ? "Read the saved build/dig counter from a backup." : "Gespeicherten Bau-/Abbauzähler einer Sicherung auslesen."
        case .editor: return english ? "Patch savegames · Beta / Preview" : "Spielstände bearbeiten · Beta / Preview"
        case .aiExport: return english ? "Export a world snapshot for external agents." : "Weltkontext für externe Agenten exportieren."
        case .mobs: return english ? "AI-generated mob catalog with sources." : "KI-generiertes Kreaturenregister mit Quellen."
        case .conversation: return english ? "Ask about named places and crafting." : "Nach benannten Orten und Crafting fragen."
        case .player: return english ? "Read level, inventory and equipped armor." : "Level, Inventar und angelegte Rüstung auslesen."
        case .home: return english ? "Your RealmCraft companion" : "Dein Begleiter für RealmCraft"
        case .saves: return english ? "Back up, restore and organize your Quest worlds." : "Quest-Welten sichern, wiederherstellen und verwalten."
        case .maps: return english ? "Generate and explore maps from your saved worlds." : "Karten aus deinen gespeicherten Welten erzeugen und erkunden."
        case .chests: return english ? "Find stored items, quantities and chest coordinates." : "Gelagerte Gegenstände, Mengen und Kistenkoordinaten finden."
        case .resources: return english ? "Minecraft comparison, wikis, official links and community." : "Minecraft-Vergleich, Wikis, offizielle Links und Community."
        case .builds: return english ? "Build machines and farms with offline grid plans." : "Maschinen und Farmen mit Offline-Blockplänen bauen."
        case .guide: return english ? "Step-by-step setup, agent help and release notes." : "Einrichtung, Agent-Hilfe und Versionshinweise."
        }
    }
}

enum CompanionKeyboardFocus: Hashable {
    case sidebar, editorStorage
}

struct CompanionView: View {
    @FocusState private var keyboardFocus: CompanionKeyboardFocus?
    @ObservedObject var model: Model
    @ObservedObject private var lifecycle = CompanionLifecycle.shared
    @State private var feedback: FeedbackRequest?
    @State private var openLatestExport = false
    @State private var exportRequest: UUID?
    @State private var requestedMapRadius: String?
    @AppStorage("agentSkill.selectedID") private var selectedSkillID = "realmcraft-world-context"
    @State private var showMapExport = false
    @State private var showItemIcons = false
    @State private var showSpoilers = false
    @AppStorage("homeIntroductionExpanded") private var introductionExpanded = false
    @AppStorage("lastHelpTopic") private var helpTopic = "start"
    @StateObject private var maps = MapController()
    @StateObject private var chests = ChestController()
    @StateObject private var player = PlayerController()
    @Environment(\.companionTheme) private var theme
    @AppStorage("appLanguage") private var language = "en"
    @AppStorage("companionSkin") private var skin = "block"
    @AppStorage("companionFeature") private var selected = CompanionFeature.home.rawValue
    private var english: Bool { language == "en" }
    private var feature: CompanionFeature { CompanionFeature(rawValue: selected) ?? .home }
    private let poll = Timer.publish(every: 8, on: .main, in: .common).autoconnect()
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "cube.fill").font(.system(size: 23)).foregroundStyle(theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RealmCraft").font(.headline)
                        Text("Companion").font(.caption).foregroundStyle(.secondary)
                        Text("Version \(AppInfo.version)").font(.caption2).foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }.padding(.horizontal, 18).frame(height: 74)
                List(selection: $selected) {
                    Label(CompanionFeature.home.title(english), systemImage: CompanionFeature.home.icon)
                        .padding(.vertical, 5).tag(CompanionFeature.home.rawValue)
                    Section(english ? "Your world" : "Deine Welt") {
                        ForEach(CompanionFeature.worldFeatures) { item in
                            Label(item.title(english), systemImage: item.icon).padding(.vertical, 5).tag(item.rawValue)
                        }
                    }
                    Section(english ? "AI tools" : "KI-Werkzeuge") {
                        ForEach(CompanionFeature.aiFeatures) { item in
                            Label(item.title(english), systemImage: item.icon).padding(.vertical, 5).tag(item.rawValue)
                        }
                    }
                    Section(english ? "Knowledge & help" : "Wissen & Hilfe") {
                        ForEach(CompanionFeature.knowledgeFeatures) { item in
                            Label(item.title(english), systemImage: item.icon).padding(.vertical, 5).tag(item.rawValue)
                        }
                    }
                }.listStyle(.sidebar).scrollContentBackground(.hidden).disabled(model.busy)
                    .focused($keyboardFocus, equals: .sidebar)
                    .onKeyPress(.rightArrow) {
                        guard feature == .editor else { return .ignored }
                        keyboardFocus = .editorStorage
                        return .handled
                    }
                VStack(alignment: .leading, spacing: 14) {
                    Button { openFeedback(FeedbackContext(area: feature.rawValue)) } label: {
                        Label(english ? "Report data / bug" : "Daten / Bug melden", systemImage: "flag")
                    }
                    Label(model.setup.package.isEmpty ? (english ? "Quest not connected" : "Quest nicht verbunden") : (english ? "Quest connected" : "Quest verbunden"), systemImage: model.setup.package.isEmpty ? "circle" : "circle.fill")
                        .font(.caption).foregroundStyle(.secondary).help(tr(model.setup.message))
                    Menu {
                        settingsMenuItems
                    } label: { Label(english ? "Settings" : "Einstellungen", systemImage: "gearshape") }
                        .menuStyle(.borderlessButton).fixedSize().disabled(model.busy)
                }.padding(18)
            }.frame(width: 212).background(theme.surface)
            Divider()
            Group {
                switch feature {
                case .editor: SaveEditorView(model: model, maps: maps, chests: chests, language: language, keyboardFocus: $keyboardFocus)
                case .home: home
                case .saves: MainView(model: model, onMap: { selected = CompanionFeature.maps.rawValue })
                case .maps: MapsView(model: model, maps: maps, language: language, requestedRadius: requestedMapRadius)
                case .chests: ChestsView(model: model, maps: maps, chests: chests, language: language, openMaps: { selected = CompanionFeature.maps.rawValue })
                case .statistics: StatisticsView(model: model, maps: maps, chests: chests, openMaps: { selected = CompanionFeature.maps.rawValue }, language: language)
                case .player: PlayerView(model: model, player: player, names: chests, language: language)
                case .conversation: ConversationView(model: model, maps: maps, chests: chests, language: language, openMaps: { selected = CompanionFeature.maps.rawValue }, openAIExport: { selected = CompanionFeature.aiExport.rawValue })
                case .mobs: MobsView(language: language, report: openFeedback)
                case .aiExport: AIContextExportView(model: model, maps: maps, chests: chests, language: language, generateRequest: $exportRequest, openLatest: $openLatestExport, openSkills: { selected = CompanionFeature.skills.rawValue })
                case .skills: AgentSkillsView(language: language, saveLibrary: model.library.root) { id in selectedSkillID = id; selected = CompanionFeature.aiExport.rawValue }
                case .resources: ResourcesView(language: language)
                case .builds: OfflineBuildGuidesView(language: language)
                case .videos: VideoTipsView(language: language)
                case .guide: HelpView(embedded: true)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(\.companionSettingsItems, AnyView(settingsMenuItems))
        .frame(minWidth: 1080, minHeight: 700)
        .disabled(lifecycle.isWorking)
        .overlay(alignment: .bottomTrailing) {
            if lifecycle.isWorking {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text(english ? "Closing Companion instances…" : "Companion-Instanzen werden beendet …").font(.callout)
                }.padding(12).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8)).padding(16)
            }
        }
        .environment(\.locale, Locale(identifier: language))
        .sheet(item: $feedback) { request in
            FeedbackView(context: request.context, english: english, sourceWindow: request.window).companionAppearance()
        }
        .sheet(isPresented: $showSpoilers) { SpoilerSettings(english: english).companionAppearance() }
        .sheet(isPresented: $showMapExport) { MapExportSettings(english: english).companionAppearance() }
        .sheet(isPresented: $showItemIcons) { ItemIconSettings(english: english).companionAppearance() }
        .sheet(isPresented: $model.showSetup) { SetupView(model: model, maps: maps).companionAppearance() }
        .alert(english ? "Action incomplete" : "Aktion nicht abgeschlossen", isPresented: Binding(get: { model.error != nil && feature != .saves && !model.showSetup }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(tr(model.error ?? "")) }
        .onAppear { model.connect() }
        .onReceive(poll) { _ in model.connect(force: false) }
    }
    private var settingsMenuItems: some View {
        Group {
            Button(english ? "Quest setup…" : "Quest einrichten …") { model.showSetup = true }
            Divider()
            Picker(english ? "Appearance" : "Optik", selection: $skin) {
                Text(english ? "Block world" : "Blockwelt").tag("block")
                Text(english ? "Classic" : "Klassisch").tag("classic")
            }
            Button(english ? "Exploration & spoilers…" : "Erkundung & Spoiler …") { showSpoilers = true }
            Button(english ? "Map export…" : "Kartenexport …") { showMapExport = true }
            Button(english ? "Item icons…" : "Gegenstands-Icons …") { showItemIcons = true }
            Picker("Language / Sprache", selection: $language) { Text("Deutsch").tag("de"); Text("English").tag("en") }
            Divider()
            CompanionLifecycleActions(model: model, english: english)
        }.disabled(model.busy)
    }
    private func openFeedback(_ context: FeedbackContext) {
        feedback = FeedbackRequest(context: context, window: NSApp.keyWindow ?? NSApp.mainWindow)
    }
    private var home: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Overview" : "Übersicht") { EmptyView() }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(english ? "Your worlds, safely kept on this Mac." : "Deine Welten, sicher auf diesem Mac.").font(.title3).foregroundStyle(.secondary)
                    }
                    CompanionHomeActivityView(model: model, maps: maps, language: language, open: { destination, saveID in
                        if let saveID, model.saves.contains(where: { $0.id == saveID }) { model.selection = saveID }
                        if destination == .aiExport { openLatestExport = true }
                        if destination == .maps { requestedMapRadius = CompanionActivity.shared.latest("map", root: model.library.root)?.radius }
                        selected = destination.rawValue
                    }, generateMap: {
                        if model.selected == nil { model.selection = model.saves.first?.id }
                        requestedMapRadius = "128"
                        if let save = model.selected, maps.ready { maps.generate(model, save: save, radius: "128", language: language) }
                        selected = CompanionFeature.maps.rawValue
                    }, generateExport: {
                        if model.selected == nil { model.selection = model.saves.first?.id }
                        openLatestExport = false; exportRequest = UUID(); selected = CompanionFeature.aiExport.rawValue
                    })
                    homeIntroduction
                    if let save = model.saves.first,
                       let image = NSImage(contentsOf: model.library.worldFolder(save).appendingPathComponent("screenshot.jpg")) {
                        Image(nsImage: image).resizable().scaledToFill().frame(height: 230).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius))
                            .allowsHitTesting(false)
                            .accessibilityLabel(english ? "Preview of your latest saved world" : "Vorschau deiner zuletzt gesicherten Welt")
                    }
                    HStack(spacing: 36) {
                        summary(english ? "Savegames" : "Spielstände", value: "\(model.saves.count)")
                        summary(english ? "Storage" : "Speicher", value: displayBytes(model.saves.reduce(0) { $0 + $1.bytes }))
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(english ? "Recently saved" : "Zuletzt gesichert").font(.headline)
                        if model.saves.isEmpty {
                            Text(english ? "Your library is empty. Import or back up a world in Savegames." : "Deine Bibliothek ist leer. Importiere oder sichere eine Welt unter Savegames.").foregroundStyle(.secondary)
                        }
                        ForEach(Array(model.saves.prefix(5))) { save in
                            Button {
                                model.selection = save.id
                                selected = CompanionFeature.saves.rawValue
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "archivebox").foregroundStyle(.secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(save.title).font(.body.weight(.medium)).lineLimit(1)
                                        Text(displayDate(save.date, language: language)).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(displayBytes(save.bytes)).font(.callout).foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                                }.padding(.vertical, 14).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                            Divider()
                        }
                    }
                    Text(AppInfo.title).font(.caption).foregroundStyle(.tertiary)
                }.padding(CompanionLayout.pageInset).frame(maxWidth: 1020, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    private var homeIntroduction: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(english ? "A quick guide to your Companion" : "Dein Companion, kurz erklärt")
                .font(.headline)
            Text(english
                ? "Start in Savegames: back up a world from your device or import an existing backup. Then inspect your player’s inventory and equipment, explore the map and find items in chests. These views show saved data, not live gameplay."
                : "Starte unter Savegames: Sichere eine Welt von deinem Gerät oder importiere eine vorhandene Sicherung. Danach kannst du das Inventar und die Ausrüstung deines Spielers ansehen, die Karte erkunden und Gegenstände in Kisten finden. Die Ansichten zeigen gespeicherte Daten, keine Live-Spielwerte.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            DisclosureGroup(isExpanded: $introductionExpanded) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(CompanionFeature.navigationOrder.filter { $0 != .home && $0 != .guide }) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.icon).foregroundStyle(.secondary).frame(width: 20)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title(english)).font(.callout.weight(.medium))
                                Text(item.detail(english)).font(.callout).foregroundStyle(.secondary)
                            }
                        }.fixedSize(horizontal: false, vertical: true)
                    }
                }.padding(.top, 12).padding(.bottom, 4)
            } label: {
                Text(english ? "What each section does" : "Die Bereiche im Überblick").font(.callout.weight(.medium))
            }.disclosureGroupStyle(OverviewDisclosureStyle(english: english))
            Button {
                helpTopic = "start"
                selected = CompanionFeature.guide.rawValue
            } label: {
                Label(english ? "Open the step-by-step help" : "Zur Schritt-für-Schritt-Hilfe", systemImage: "questionmark.circle")
                    .font(.callout).foregroundStyle(theme.accent)
            }.buttonStyle(.plain).disabled(model.busy)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Divider().allowsHitTesting(false) }
        .overlay(alignment: .bottom) { Divider().allowsHitTesting(false) }
    }
    private func summary(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(size: 24, weight: .semibold)).monospacedDigit()
            Text(title).font(.callout).foregroundStyle(.secondary)
        }
    }
}

struct CompanionNavigationCommands: Commands {
    @ObservedObject var model: Model
    @AppStorage("companionMobImages") private var showMobImages = false
    @AppStorage("appLanguage") private var language = "en"
    @AppStorage("companionFeature") private var selected = CompanionFeature.home.rawValue
    var body: some Commands {
        CommandGroup(before: .appTermination) {
            CompanionLifecycleActions(model: model, english: language == "en")
            Divider()
        }
        CommandGroup(after: .toolbar) {
            Toggle(language == "en" ? "Mobs & Animals: Show images" : "Mobs & Animals: Bilder einblenden", isOn: $showMobImages)
        }
        CommandMenu(language == "en" ? "Go" : "Gehe zu") {
            ForEach(CompanionFeature.navigationOrder) { item in
                // Keep existing shortcuts while matching the sidebar's display order.
                let index = CompanionFeature.allCases.firstIndex(of: item)!
                Button(item.title(language == "en")) {
                    selected = item.rawValue
                }.keyboardShortcut(index < 10 ? KeyEquivalent(Character(String((index + 1) % 10))) : (item == .statistics ? "s" : item == .skills ? "k" : "e"), modifiers: index < 10 ? .command : [.command, .shift]).disabled(model.busy)
            }
            Divider()
            Button(language == "en" ? "Quest setup…" : "Quest einrichten …") { model.showSetup = true }.disabled(model.busy)
        }
    }
}

private struct FeedbackRequest: Identifiable {
    let id = UUID()
    let context: FeedbackContext
    let window: NSWindow?
}

// Keep the complete disclosure row clickable, including the space after its label.
private struct OverviewDisclosureStyle: DisclosureGroupStyle {
    let english: Bool
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { configuration.isExpanded.toggle() } label: {
                HStack(spacing: 8) {
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold)).frame(width: 12).accessibilityHidden(true)
                    configuration.label
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(configuration.isExpanded ? (english ? "Expanded" : "Ausgeklappt") : (english ? "Collapsed" : "Eingeklappt"))
            if configuration.isExpanded { configuration.content }
        }
    }
}


struct SpoilerSettings: View {
    let english: Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage("exploration.spoilerFree") private var spoilerFree = false
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(english ? "Exploration & spoilers" : "Erkundung & Spoiler").font(.title2.bold())
            Toggle(english ? "Spoiler-light mode · all worlds" : "Spoilerarmer Modus · alle Welten", isOn: $spoilerFree)
            Text(english ? "Chests: only player-owned or manually marked known chests. Other chests remain hidden, including in searches. Turn this mode off to mark additional discoveries." : "Kisten: nur eigene oder manuell als bekannt markierte Kisten. Andere bleiben auch bei der Suche verborgen. Zum Markieren weiterer Entdeckungen diesen Modus ausschalten.")
            Text(english ? "Map: surface elevation only, without underground layers, block inspection or automatic places. Known chests and your own map markers remain available. This prevents the map from exposing ore types and underground loot." : "Karte: nur Oberflächenhöhe, ohne unterirdische Ebenen, Blockabfrage oder automatische Fundorte. Bekannte Kisten und deine Kartenmarkierungen bleiben verfügbar. So zeigt die Karte keine Erztypen oder unterirdische Beute.")
            Text(english ? "Not a discovered-area map: saved chunks can include unexplored terrain. No reliable discovery history is decoded. The landscape outline remains visible; knowledge is based on your marks, not inferred from generated chunks. Raw JSON and AI exports are not filtered by this display setting." : "Keine Karte ausschließlich entdeckter Gebiete: gespeicherte Chunks können unerforschte Landschaft enthalten. Eine verlässliche Entdeckungshistorie wird nicht decodiert. Der Landschaftsumriss bleibt sichtbar; als bekannt gelten deine Markierungen, nicht generierte Chunks. Roh-JSON und KI-Exporte werden durch diese Anzeigeeinstellung nicht gefiltert.").font(.callout).foregroundStyle(.secondary)
            HStack { Spacer(); Button(english ? "Done" : "Fertig") { dismiss() }.keyboardShortcut(.defaultAction) }
        }.padding(28).frame(width: 580)
    }
}
