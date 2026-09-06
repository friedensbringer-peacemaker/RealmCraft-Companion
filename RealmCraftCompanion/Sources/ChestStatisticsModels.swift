import Foundation

enum ChestItemCategory: String, CaseIterable, Identifiable {
    case minerals, stone, wood, food, plants, equipment, mechanisms, decoration, ingredients, other
    var id: String { rawValue }
    func title(english: Bool) -> String {
        switch self {
        case .minerals: return english ? "Resources · Ores, metals & gems" : "Ressourcen · Erze, Metalle & Edelsteine"
        case .stone: return english ? "Resources · Stone & earth" : "Ressourcen · Stein & Erde"
        case .wood: return english ? "Resources · Wood" : "Ressourcen · Holz"
        case .food: return english ? "Food" : "Nahrung"
        case .plants: return english ? "Plants & farming" : "Pflanzen & Landwirtschaft"
        case .equipment: return english ? "Items · Tools, weapons & armor" : "Gegenstände · Werkzeuge, Waffen & Rüstung"
        case .mechanisms: return english ? "Items · Technology & transport" : "Gegenstände · Technik & Transport"
        case .decoration: return english ? "Building & decoration" : "Bauen & Dekoration"
        case .ingredients: return english ? "Resources · Crafting ingredients" : "Ressourcen · Werkstoffe"
        case .other: return english ? "Other / unclassified" : "Sonstiges / nicht zugeordnet"
        }
    }

    // Companion themes inferred from the bundled English catalog, not saved game categories.
    // Match equipment and manufactured objects before their raw material names.
    static func classify(itemID: Int, name: ItemName?) -> Self {
        guard let name else { return .other }
        let n = name.en.lowercased()
        func has(_ terms: [String]) -> Bool { terms.contains { n.contains($0) } }
        if has(["spawn", "music disc"]) { return .other }
        if has(["pickaxe", "sword", "shovel", " axe", " hoe", "helmet", "chestplate", "leggings", "boots", "shield", "fishing rod", "shears", "bow", "trident", "flint and steel", "elytra"]) && n != "bowl" { return .equipment }
        if has(["rail", "minecart", "boat", "piston", "redstone", "repeater", "comparator", "hopper", "dispenser", "dropper", "lever", "button", "pressure plate", "observer", "daylight detector", "tnt"]) || n.hasSuffix("raft") || n == "saddle" || n == "carrot on stick" { return .mechanisms }
        if (3208...3232).contains(itemID) || [3152,3181,3185,3187,3188,3235,3237].contains(itemID) || ["carrot", "potato", "poisonous potato", "cake", "honey bottle", "glow berries", "enchanted golden apple"].contains(n) { return .food }
        if has([" ore", "ingot", "nugget", "raw iron", "raw copper", "raw gold", "netherite scrap"]) || ["diamond", "emerald", "coal", "charcoal", "lapis lazuli", "nether quartz", "ancient debris", "gold block", "iron block", "diamond block", "emerald block", "coal block", "lapis lazuli block", "lapis block", "netherite block", "copper block"].contains(n) { return .minerals }
        if has(["planks", " log", " wood", " stem", " hyphae"]) || ["bamboo block", "block of bamboo", "stripped block of bamboo"].contains(n) { return .wood }
        if has(["sapling", "leaves", "seeds", "flower", "tulip", "orchid", "allium", "daisy", "rose bush", "peony", "lilac", "dandelion", "poppy", "azalea", "fern", "vines", "mushroom", "fungus", "roots", "cactus", "sugar cane", "kelp", "seagrass", "lily pad", "wheat", "bone meal"]) || n == "bamboo" { return .plants }
        if has(["stairs", "slab", "wall", "fence", "door", "trapdoor", "sign", "bed", "carpet", "wool", "glass", "terracotta", "concrete", "lantern", "torch", "chest", "barrel", "furnace", "table", "anvil", "bookshelf", "painting", "item frame", "banner", "candle", "chain", "bricks", "block of", "block iron", "block gold"]) && n != "bedrock" { return .decoration }
        if has(["stone", "granite", "diorite", "andesite", "deepslate", "tuff", "calcite", "basalt", "dirt", "sand", "gravel", "podzol", "netherrack", "obsidian", "bedrock", "mud", "clay", "prismarine", "snow", "ice"]) && ![3182,3183,3184,3204,3258].contains(itemID) { return .stone }
        if (3153...3206).contains(itemID) || (3233...3238).contains(itemID) || [3254,3256,3258,3287,3320].contains(itemID) || has([" dye", "powder", "dust", "shard", "crystal"]) { return .ingredients }
        return .other
    }
}

struct ChestStockItem: Identifiable, Equatable {
    let id: Int
    var all: Int64 = 0
    var player: Int64 = 0
    var allChests = 0
    var playerChests = 0
}

struct ChestStockSummary {
    var items: [ChestStockItem] = []
    var readable = 0
    var unreadable = 0
    var playerReadable = 0
    var playerUnreadable = 0
    var duplicateRecords = 0
    var invalidStacks = 0
    var scanIssues = 0

    static func make(index: ChestIndex, visibility: ChestVisibility, dimension: String = "all", knownOnly: Bool = false) throws -> Self {
        var result = Self(), seen = Set<String>(), rows = [Int: ChestStockItem]()
        result.scanIssues = index.errors.count
        for chest in index.chests {
            guard dimension == "all" || chest.dimension == dimension else { continue }
            guard !knownOnly || visibility.isKnown(chest) else { continue }
            guard seen.insert(chest.id).inserted else { result.duplicateRecords += 1; continue }
            let owned = visibility.owned.contains(chest.id)
            guard chest.readable else {
                result.unreadable += 1
                if owned { result.playerUnreadable += 1 }
                continue
            }
            result.readable += 1
            if owned { result.playerReadable += 1 }
            var types = Set<Int>()
            for item in chest.items {
                guard item.quantity > 0, item.itemID > 0 else {
                    if item.quantity < 0 || (item.quantity > 0 && item.itemID <= 0) { result.invalidStacks += 1 }
                    continue
                }
                var row = rows[item.itemID] ?? ChestStockItem(id: item.itemID)
                row.all = try add(row.all, Int64(item.quantity))
                if owned { row.player = try add(row.player, Int64(item.quantity)) }
                if types.insert(item.itemID).inserted {
                    row.allChests += 1
                    if owned { row.playerChests += 1 }
                }
                rows[item.itemID] = row
            }
        }
        result.items = rows.values.sorted { $0.id < $1.id }
        return result
    }

    static func add(_ a: Int64, _ b: Int64) throws -> Int64 {
        let (value, overflow) = a.addingReportingOverflow(b)
        guard !overflow else { throw StatisticsReadError(message: "Chest quantities exceed the supported number range.") }
        return value
    }

    static func total(_ items: [ChestStockItem], player: Bool) throws -> Int64 {
        try items.reduce(Int64(0)) { try add($0, player ? $1.player : $1.all) }
    }

    func filtered(names: [String: ItemName], query: String, category: String, playerOnly: Bool, sort: String, ascending: Bool, english: Bool) -> [ChestStockItem] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        let rows = items.filter { row in
            let name = names[String(row.id)]
            let haystack = "\(row.id) \(name?.en ?? "") \(name?.de ?? "")"
            return (!playerOnly || row.player > 0)
                && (category == "all" || ChestItemCategory.classify(itemID: row.id, name: name).rawValue == category)
                && words.allSatisfy { haystack.localizedStandardContains($0) }
        }
        return rows.sorted { a, b in
            if sort == "name" {
                let an = english ? names[String(a.id)]?.en : names[String(a.id)]?.de
                let bn = english ? names[String(b.id)]?.en : names[String(b.id)]?.de
                let order = (an ?? String(a.id)).localizedStandardCompare(bn ?? String(b.id))
                if order != .orderedSame { return ascending ? order == .orderedAscending : order == .orderedDescending }
            } else {
                let av = sort == "id" ? Int64(a.id) : (sort == "player" ? a.player : a.all)
                let bv = sort == "id" ? Int64(b.id) : (sort == "player" ? b.player : b.all)
                if av != bv { return ascending ? av < bv : av > bv }
            }
            return a.id < b.id
        }
    }
}
