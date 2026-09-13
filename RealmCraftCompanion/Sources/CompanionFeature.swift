import Foundation

// Add a feature here, then provide its view in CompanionView. Storage and ADB remain shared.
enum CompanionFeature: String, CaseIterable, Identifiable {
    case crafting, ores, portals, metro, tectonicus, editor, home, saves, maps, chests, resources, builds, videos, guide, player, conversation, mobs, aiExport, statistics, skills
    static let worldFeatures: [Self] = [.saves, .player, .maps, .ores, .portals, .metro, .chests]
    static let aiFeatures: [Self] = [.conversation]
    static let knowledgeFeatures: [Self] = [.videos, .builds, .crafting, .mobs, .resources, .guide]
    static let specialistFeatures: [Self] = [.statistics, .tectonicus, .editor, .aiExport, .skills]
    static var navigationOrder: [Self] { [.home] + CompanionNavigationGroup.allCases.flatMap(\.features) }
    var id: String { rawValue }
    var helpID: String {
        switch self {
        case .home: return "companion"
        case .saves: return "library"
        case .guide: return "start"
        default: return rawValue
        }
    }
    var icon: String {
        switch self { case .crafting: return "square.grid.3x3.fill"; case .ores: return "diamond"; case .portals: return "arrow.left.arrow.right.circle"; case .metro: return "train.side.front.car"; case .tectonicus: return "cube.transparent"; case .skills: return "text.book.closed"; case .videos: return "play.rectangle"; case .statistics: return "chart.bar.xaxis"; case .editor: return "slider.horizontal.3"; case .aiExport: return "doc.text.magnifyingglass"; case .mobs: return "pawprint"; case .conversation: return "bubble.left.and.bubble.right"; case .player: return "person.crop.rectangle"; case .home: return "square.grid.2x2"; case .saves: return "archivebox"; case .maps: return "map"; case .chests: return "shippingbox"; case .resources: return "globe"; case .builds: return "square.grid.3x3"; case .guide: return "questionmark.circle" }
    }
    func title(_ english: Bool) -> String {
        switch self { case .crafting: return english ? "Crafting / Recipes" : "Crafting / Rezepte"; case .ores: return english ? "Ore frequency" : "Erzhäufigkeit"; case .portals: return english ? "Portal pairs" : "Portalpaare"; case .metro: return english ? "Nether Metro · Beta" : "Nether-Metro · Beta"; case .tectonicus: return "Tectonicus · Beta"; case .skills: return english ? "Assistant instructions" : "Assistenten-Anweisungen"; case .videos: return english ? "Videos & tips" : "Videos & Tipps"; case .statistics: return english ? "Statistics · Beta" : "Statistiken · Beta"; case .editor: return "Editor · Beta"; case .aiExport: return english ? "AI export" : "KI-Export"; case .mobs: return english ? "Mobs & Animals" : "Tiere & Kreaturen"; case .conversation: return english ? "Conversation · Beta" : "Gespräch · Beta"; case .player: return english ? "Player" : "Spieler"; case .home: return english ? "Home" : "Start"; case .saves: return english ? "Worlds & backups" : "Welten & Sicherungen"; case .maps: return english ? "Maps" : "Karten"; case .chests: return english ? "Chests" : "Kisten"; case .resources: return english ? "Links & Knowledge" : "Links & Wissen"; case .builds: return english ? "Build guides" : "Bauanleitungen"; case .guide: return english ? "Help" : "Hilfe" }
    }
    func detail(_ english: Bool) -> String {
        switch self {
        case .crafting: return english ? "Look up ingredients, quantities, stations and recipe grids." : "Zutaten, Mengen, Herstellungsorte und Rezept-Raster nachschlagen."
        case .ores: return english ? "Count ore blocks by height and biome; document mining trials." : "Erzblöcke nach Höhe und Biom zählen; Teststollen dokumentieren."
        case .portals: return english ? "Record Nether portal positions and connections." : "Nether-Portalpositionen und Verbindungen vermerken."
        case .metro: return english ? "Plan confirmed rail and portal journeys without assuming portal mechanics." : "Bestätigte Schienen- und Portalreisen ohne angenommene Portalmechanik planen."
        case .tectonicus: return english ? "Set up Tectonicus and render saved worlds." : "Tectonicus einrichten und gespeicherte Welten rendern."
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

/// Shared display groups for the sidebar, Home explanation and Go menu.
enum CompanionNavigationGroup: String, CaseIterable, Identifiable {
    case world, ai, knowledge, specialist
    var id: String { rawValue }
    func title(_ english: Bool) -> String {
        switch self {
        case .world: return english ? "Your world" : "Deine Welt"
        case .ai: return english ? "AI tools" : "KI-Werkzeuge"
        case .knowledge: return english ? "Knowledge & help" : "Wissen & Hilfe"
        case .specialist: return english ? "More tools" : "Weitere Werkzeuge"
        }
    }
    var features: [CompanionFeature] {
        switch self {
        case .world: return CompanionFeature.worldFeatures
        case .ai: return CompanionFeature.aiFeatures
        case .knowledge: return CompanionFeature.knowledgeFeatures
        case .specialist: return CompanionFeature.specialistFeatures
        }
    }
}
