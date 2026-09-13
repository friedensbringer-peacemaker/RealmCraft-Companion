import Foundation

struct CraftingText: Decodable, Equatable {
    let de: String
    let en: String
    func value(_ english: Bool) -> String { english ? en : de }
}

enum CraftingStation: String, Decodable, CaseIterable {
    case inventory, table, furnace, blastFurnace, smoker, campfire, stonecutter, smithing
    func title(_ en: Bool) -> String {
        switch self {
        case .inventory: return en ? "Inventory · 2 × 2" : "Inventar / Menü · 2 × 2"
        case .table: return en ? "Crafting table · 3 × 3" : "Werkbank · 3 × 3"
        case .furnace: return en ? "Furnace" : "Ofen"
        case .blastFurnace: return en ? "Blast furnace" : "Schmelzofen"
        case .smoker: return en ? "Smoker" : "Räucherofen"
        case .campfire: return en ? "Campfire" : "Lagerfeuer"
        case .stonecutter: return en ? "Stonecutter" : "Steinsäge"
        case .smithing: return en ? "Smithing table" : "Schmiedetisch"
        }
    }
    var usesFuel: Bool { [.furnace, .blastFurnace, .smoker].contains(self) }
    var gridSize: Int { self == .inventory ? 2 : 3 }
    func instructions(_ en: Bool) -> String {
        switch self {
        case .inventory, .table:
            return en
                ? "1. Put the listed ingredients in your backpack.\n2. Open \(self == .inventory ? "inventory crafting" : "a placed crafting table").\n3. Select the desired recipe and compare its ingredients and yield with this reference.\n4. Activate the craft button and collect the result. Repeat for the calculated batches. The RealmCraft wiki describes automatic ingredient placement; Quest controls may differ."
                : "1. Lege die aufgeführten Zutaten in deinen Rucksack.\n2. Öffne \(self == .inventory ? "Crafting im Inventar" : "eine aufgestellte Werkbank").\n3. Wähle das gewünschte Rezept und vergleiche Zutaten und Ausgabemenge mit dieser Referenz.\n4. Betätige die Herstellen-Schaltfläche und nimm das Ergebnis. Wiederhole dies für die berechneten Durchgänge. Laut RealmCraft-Wiki werden die Zutaten automatisch angeordnet; die Quest-Bedienung kann abweichen."
        case .furnace, .blastFurnace, .smoker:
            return en ? "1. Place the input in the station's input slot.\n2. Add suitable fuel in its separate fuel slot.\n3. Wait for processing and collect the output. Fuel is additional to the ingredient list; the required amount depends on fuel and game version. First check whether this station and recipe exist in your RealmCraft version."
                : "1. Lege die Zutat in das Eingabefeld der Station.\n2. Gib geeigneten Brennstoff in das separate Brennstofffeld.\n3. Warte auf die Verarbeitung und entnimm das Ergebnis. Brennstoff kommt zusätzlich zu den Zutaten hinzu; die Menge hängt von Brennstoff und Spielversion ab. Prüfe zuerst, ob Station und Rezept in deiner RealmCraft-Version vorhanden sind."
        case .campfire:
            return en ? "Reference procedure: place the food on a lit campfire and wait until cooked. Check station availability and operation in RealmCraft before using this method."
                : "Referenzablauf: Lege das Lebensmittel auf ein brennendes Lagerfeuer und warte, bis es gegart ist. Prüfe Verfügbarkeit und Bedienung in RealmCraft, bevor du diese Methode verwendest."
        case .stonecutter:
            return en ? "Reference procedure: insert the input block, select the desired shape and collect the output. Check whether RealmCraft supports this station and yield."
                : "Referenzablauf: Lege den Ausgangsblock ein, wähle die gewünschte Form und entnimm das Ergebnis. Prüfe, ob RealmCraft diese Station und Ausgabemenge unterstützt."
        case .smithing:
            return en ? "Java 1.16.5 reference: place the base equipment and upgrade material in the smithing table. This older recipe has no template. Newer Minecraft versions and RealmCraft may use different recipes; check in the game."
                : "Java-1.16.5-Referenz: Lege die Grundausrüstung und das Aufwertungsmaterial in den Schmiedetisch. Dieses ältere Rezept hat keine Vorlage. Neuere Minecraft-Versionen und RealmCraft können andere Rezepte verwenden; im Spiel prüfen."
        }
    }
}

struct CraftingItem: Decodable, Identifiable {
    let id: String
    let itemID: Int?
    let title: CraftingText
    var category: String {
        if ["helmet", "chestplate", "leggings", "boots", "shield"].contains(where: id.contains) { return "armor" }
        if ["pickaxe", "shovel", "axe", "hoe", "sword", "bow", "shears", "fishing_rod"].contains(where: id.hasSuffix) { return "tools" }
        if ["rail", "minecart", "boat", "raft", "saddle"].contains(where: id.contains) { return "transport" }
        if ["redstone", "piston", "repeater", "comparator", "hopper", "dispenser", "dropper", "lever", "button", "pressure_plate"].contains(where: id.contains) { return "circuits" }
        if ["cooked_", "raw_", "soup", "stew", "bread", "cookie", "cake", "pie", "apple", "carrot", "potato", "melon_slice", "berries"].contains(where: id.contains) { return "food" }
        return (itemID ?? 3000) < 3000 ? "blocks" : "materials"
    }
}

struct CraftingIngredient: Decodable {
    let options: [String]
    let count: Int
}

/// Presentation families only: item IDs, ingredient alternatives and recipes stay distinct.
/// Match explicit ID suffixes, longest first; never strip arbitrary material/color words.
struct CraftingBrowseType {
    let id: String
    let title: CraftingText
    let isFamily: Bool
    private static let families: [(String, String, String)] = [
        ("chest_boat", "Truhenboote", "Chest boats"), ("boat", "Boote", "Boats"),
        ("chest_raft", "Truhenflöße", "Chest rafts"), ("raft", "Flöße", "Rafts"),
        ("fence_gate", "Zauntore", "Fence gates"), ("fence", "Zäune", "Fences"),
        ("trapdoor", "Falltüren", "Trapdoors"), ("door", "Türen", "Doors"),
        ("pressure_plate", "Druckplatten", "Pressure plates"), ("button", "Knöpfe", "Buttons"),
        ("pickaxe", "Spitzhacken", "Pickaxes"), ("axe", "Äxte", "Axes"),
        ("shovel", "Schaufeln", "Shovels"), ("hoe", "Hacken", "Hoes"), ("sword", "Schwerter", "Swords"),
        ("helmet", "Helme", "Helmets"), ("chestplate", "Brustpanzer", "Chestplates"),
        ("leggings", "Beinschutz", "Leggings"), ("boots", "Stiefel", "Boots"),
        ("hanging_sign", "Hängeschilder", "Hanging signs"), ("sign", "Schilder", "Signs"),
        ("stairs", "Treppen", "Stairs"), ("slab", "Stufen", "Slabs"), ("wall", "Mauern", "Walls"),
        ("planks", "Bretter", "Planks"), ("log", "Stämme", "Logs"), ("wood", "Holzblöcke", "Wood blocks"),
        ("leaves", "Laub", "Leaves"), ("sapling", "Setzlinge", "Saplings"),
        ("stained_glass_pane", "Gefärbte Glasscheiben", "Stained glass panes"),
        ("stained_glass", "Gefärbtes Glas", "Stained glass"),
        ("glazed_terracotta", "Glasierte Keramik", "Glazed terracotta"),
        ("terracotta", "Keramik", "Terracotta"), ("concrete_powder", "Trockenbeton", "Concrete powder"),
        ("concrete", "Beton", "Concrete"), ("wool", "Wolle", "Wool"), ("carpet", "Teppiche", "Carpets"),
        ("bed", "Betten", "Beds"), ("banner", "Banner", "Banners"), ("dye", "Farbstoffe", "Dyes"),
        ("shulker_box", "Shulkerkisten", "Shulker boxes"), ("candle", "Kerzen", "Candles"),
        ("ore", "Erze", "Ores"), ("ingot", "Barren", "Ingots"), ("nugget", "Klumpen", "Nuggets"),
        ("minecart", "Loren", "Minecarts"), ("rail", "Schienen", "Rails")
    ].sorted { $0.0.count == $1.0.count ? $0.0 < $1.0 : $0.0.count > $1.0.count }

    static func of(_ item: CraftingItem) -> Self {
        if let family = families.first(where: { item.id == $0.0 || item.id.hasSuffix("_" + $0.0) }) {
            return .init(id: "type:" + family.0, title: .init(de: family.1, en: family.2), isFamily: true)
        }
        // Unknown/special items retain their complete name and an independent identity.
        return .init(id: "item:" + item.id, title: item.title, isFamily: false)
    }
}

struct CraftingBrowseGroup: Identifiable {
    let type: CraftingBrowseType
    let items: [CraftingItem]
    var id: String { type.id }
    static func make(_ items: [CraftingItem], english: Bool) -> [Self] {
        let locale = Locale(identifier: english ? "en" : "de")
        func precedes(_ lhs: String, _ rhs: String, lhsID: String, rhsID: String) -> Bool {
            let comparison = lhs.compare(rhs, options: [.caseInsensitive, .diacriticInsensitive, .numeric], locale: locale)
            return comparison == .orderedSame ? lhsID < rhsID : comparison == .orderedAscending
        }
        return Dictionary(grouping: items, by: { CraftingBrowseType.of($0).id }).values.map { members in
            Self(type: CraftingBrowseType.of(members[0]), items: members.sorted {
                let lhs = $0.title.value(english), rhs = $1.title.value(english)
                return precedes(lhs, rhs, lhsID: $0.id, rhsID: $1.id)
            })
        }.sorted {
            let lhs = $0.type.title.value(english), rhs = $1.type.title.value(english)
            return precedes(lhs, rhs, lhsID: $0.id, rhsID: $1.id)
        }
    }
}

struct CraftingCorroboration: Decodable {
    let title: String
    let url: URL
    let scope: CraftingText
}

struct CraftingRecipe: Decodable, Identifiable {
    let id: String
    let output: String
    let count: Int
    let station: CraftingStation
    let kind: String
    let ingredients: [CraftingIngredient]
    /// One-based ingredient-group indices; zero denotes an empty slot.
    let grid: [Int]
    let sourcePath: String
    let sourceSHA256: String
    let corroboration: CraftingCorroboration?
    var shaped: Bool { kind == "crafting_shaped" }
    func batches(for desired: Int) -> Int {
        let desired = min(9999, max(1, desired))
        return (desired - 1) / max(1, count) + 1
    }
    func produced(for desired: Int) -> Int { batches(for: desired) * count }
}

struct CraftingCatalog: Decodable {
    let schemaVersion: Int
    let referenceVersion: String
    let checked: String
    let sourceURL: URL
    let sourceSHA1: String
    let items: [CraftingItem]
    let recipes: [CraftingRecipe]
    enum CatalogError: LocalizedError {
        case invalid
        var errorDescription: String? { "Crafting catalog is missing or invalid. / Crafting-Katalog fehlt oder ist ungültig." }
    }
    static func load(from url: URL? = Bundle.main.url(forResource: "CraftingCatalog", withExtension: "json")) throws -> Self {
        guard let url else { throw CatalogError.invalid }
        let catalog = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }
    func validate() throws {
        let ids = Set(items.map(\.id))
        guard schemaVersion == 1, !items.isEmpty, !recipes.isEmpty,
              ids.count == items.count, Set(recipes.map(\.id)).count == recipes.count,
              sourceURL.scheme == "https",
              items.allSatisfy({ !$0.title.de.isEmpty && !$0.title.en.isEmpty }) else { throw CatalogError.invalid }
        for r in recipes {
            guard ids.contains(r.output), (1...64).contains(r.count), !r.ingredients.isEmpty,
                  r.ingredients.count <= 9,
                  r.ingredients.allSatisfy({ (1...9).contains($0.count) && !$0.options.isEmpty && Set($0.options).count == $0.options.count && $0.options.allSatisfy(ids.contains) }),
                  r.sourcePath.hasPrefix("data/minecraft/recipes/"), !r.sourcePath.contains(".."),
                  r.corroboration == nil || r.corroboration?.url.scheme == "https" else { throw CatalogError.invalid }
            if r.shaped {
                guard [.inventory, .table].contains(r.station), r.grid.count == r.station.gridSize * r.station.gridSize,
                      r.grid.allSatisfy({ (0...r.ingredients.count).contains($0) }) else { throw CatalogError.invalid }
                for (index, ingredient) in r.ingredients.enumerated() {
                    guard r.grid.filter({ $0 == index + 1 }).count == ingredient.count else { throw CatalogError.invalid }
                }
            } else if !r.grid.isEmpty { throw CatalogError.invalid }
        }
    }
    static func normalized(_ value: String) -> String {
        value.replacingOccurrences(of: "ß", with: "ss").folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_AT"))
    }
    func index() -> CraftingIndex { CraftingIndex(catalog: self) }
}

struct CraftingIndex {
    let catalog: CraftingCatalog
    let items: [String: CraftingItem]
    let recipes: [String: [CraftingRecipe]]
    let uses: [String: [CraftingRecipe]]
    private let search: [String: String]
    init(catalog: CraftingCatalog) {
        self.catalog = catalog
        items = Dictionary(uniqueKeysWithValues: catalog.items.map { ($0.id, $0) })
        recipes = Dictionary(grouping: catalog.recipes, by: \.output)
        var uses: [String: [CraftingRecipe]] = [:]
        for recipe in catalog.recipes {
            for id in Set(recipe.ingredients.flatMap(\.options)) { uses[id, default: []].append(recipe) }
        }
        self.uses = uses
        search = Dictionary(uniqueKeysWithValues: catalog.items.map { item in
            var value = item.id + " " + item.title.de + " " + item.title.en + " " + (item.itemID.map(String.init) ?? "")
            if item.id == "crafting_table" { value += " Werkbank Werktisch crafting table" }
            if item.id == "chest" { value += " Kiste Truhe" }
            if item.id.contains("redstone") { value += " Electrium Elektrium" }
            if item.id.contains("planks") { value += " Holzbretter" }
            if item.id == "stick" { value += " Stöcke Stoecke sticks" }
            let compactNames = [item.title.de, item.title.en].map { CraftingCatalog.normalized($0).filter { $0.isLetter || $0.isNumber } }.joined(separator: " ")
            return (item.id, CraftingCatalog.normalized(value) + " " + compactNames)
        })
    }
    func filtered(query: String, category: String = "all", station: String = "all", coverage: String = "all", english: Bool) -> [CraftingItem] {
        let terms = CraftingCatalog.normalized(query).split(whereSeparator: \.isWhitespace).map(String.init)
        return catalog.items.filter { item in
            guard item.itemID != nil, category == "all" || item.category == category,
                  terms.allSatisfy({ term in
                      var forms = [term]
                      if term.count >= 5 {
                          if term.hasSuffix("en") || term.hasSuffix("es") { forms.append(String(term.dropLast(2))) }
                          if term.hasSuffix("n") || term.hasSuffix("s") { forms.append(String(term.dropLast())) }
                      }
                      return forms.contains { search[item.id, default: ""].contains($0) }
                  }) else { return false }
            let candidates = recipes[item.id, default: []]
            if station != "all" && !candidates.contains(where: { $0.station.rawValue == station }) { return false }
            switch coverage {
            case "recipes": return !candidates.isEmpty
            case "open": return candidates.isEmpty
            case "wiki": return candidates.contains { $0.corroboration != nil }
            default: return true
            }
        }.sorted { $0.title.value(english).localizedStandardCompare($1.title.value(english)) == .orderedAscending }
    }
    func ingredientName(_ ingredient: CraftingIngredient, english: Bool) -> String {
        ingredient.options.map { items[$0]?.title.value(english) ?? $0 }.joined(separator: english ? " OR " : " ODER ")
    }
    func summary(_ recipe: CraftingRecipe, desired: Int, english en: Bool) -> String {
        let batches = recipe.batches(for: desired)
        let ingredients = recipe.ingredients.enumerated().map { offset, ingredient in
            "\(offset + 1). \(ingredient.count * batches) × \(ingredientName(ingredient, english: en))"
        }.joined(separator: "\n")
        var grid = ""
        if recipe.shaped {
            let size = recipe.station.gridSize
            let rows: [String] = stride(from: 0, to: recipe.grid.count, by: size).map { row in
                recipe.grid[row..<(row + size)].map { $0 == 0 ? "·" : String($0) }.joined(separator: " ")
            }
            grid = (en ? "Grid for one batch (ingredient numbers; · = empty):\n" : "Raster für einen Durchgang (Zutatennummern; · = leer):\n") + rows.joined(separator: "\n")
        }
        let parts: [String] = [items[recipe.output]?.title.value(en) ?? recipe.output,
                recipe.station.title(en),
                en ? "\(batches) batches × \(recipe.count) = \(recipe.produced(for: desired)) items" : "\(batches) Durchgänge × \(recipe.count) = \(recipe.produced(for: desired)) Stück",
                ingredients, grid,
                recipe.station.usesFuel ? (en ? "Additional fuel required; amount is not verified." : "Zusätzlicher Brennstoff erforderlich; Menge nicht geprüft.") : "",
                en ? "Each alternative group needs the stated total, not every listed option. Direct ingredients only." : "Je Alternativgruppe gilt die Gesamtmenge, nicht jede genannte Alternative. Nur direkte Zutaten.",
                recipe.station.instructions(en),
                en ? "Minecraft comparison (\(catalog.referenceVersion)); recipe, station and item mapping are unverified in RealmCraft VR." : "Minecraft-Vergleich (\(catalog.referenceVersion)); Rezept, Station und Gegenstandszuordnung sind in RealmCraft VR ungeprüft.",
                recipe.corroboration.map { $0.scope.value(en) + "\n" + $0.url.absoluteString } ?? "",
                catalog.sourceURL.absoluteString + "\n" + recipe.sourcePath]
        return parts.filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
}
