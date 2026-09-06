import Foundation

struct ChestItem: Codable, Identifiable {
    let slot: Int; let itemID: Int; let quantity: Int; let extraData: Bool
    var id: Int { slot }
}
struct ChestRecord: Codable, Identifiable {
    let id: String; let dimension: String; let x: Int; let y: Int; let z: Int
    let file: String; let items: [ChestItem]; let readable: Bool; let error: String
    var nearbySign: String? = nil
    var coordinates: String { "X \(x) · Y \(y) · Z \(z)" }
}
struct ChestGroup: Identifiable {
    let id: String
    let members: [ChestRecord]
    var anchor: ChestRecord { members[0] }
    static func make(_ chests: [ChestRecord]) -> [ChestGroup] {
        // Connected components: each connecting pair lies within six blocks,
        // including height. Dimensions never merge. Sparse buckets avoid n² work.
        var parent = Array(chests.indices)
        func root(_ index: Int) -> Int { var p = index; while parent[p] != p { p = parent[p] }; return p }
        var buckets: [String:[Int]] = [:]
        for (i, chest) in chests.enumerated() {
            let x = Int(floor(Double(chest.x) / 6)), y = Int(floor(Double(chest.y) / 6)), z = Int(floor(Double(chest.z) / 6))
            for dx in -1...1 { for dy in -1...1 { for dz in -1...1 {
                for j in buckets["\(chest.dimension):\(x+dx),\(y+dy),\(z+dz)"] ?? [] {
                    let other = chests[j], a = Double(chest.x-other.x), b = Double(chest.y-other.y), c = Double(chest.z-other.z)
                    if a*a+b*b+c*c <= 36 { parent[root(i)] = root(j) }
                }
            } } }
            buckets["\(chest.dimension):\(x),\(y),\(z)", default: []].append(i)
        }
        var groups: [Int:[ChestRecord]] = [:]
        for i in chests.indices { groups[root(i), default: []].append(chests[i]) }
        return groups.values.map { members in
            let sorted = members.sorted { $0.id < $1.id }
            return ChestGroup(id: sorted[0].id, members: sorted)
        }.sorted {
            let a = $0.anchor, b = $1.anchor
            let da = Double(a.x)*Double(a.x)+Double(a.z)*Double(a.z), db = Double(b.x)*Double(b.x)+Double(b.z)*Double(b.z)
            return da == db ? $0.id < $1.id : da < db
        }
    }
}
struct ChestIndex: Codable { let chunksScanned: Int; let chests: [ChestRecord]; let errors: [String] }
struct ItemName: Codable { let en: String; let de: String }

/// A user-controlled hint, never evidence that a chest has not been discovered.
struct ChestVisibility {
    var hidden: Set<String> = []
    var visible: Set<String> = []
    var owned: Set<String> = []
    var hideSuspected = false

    static func suspectedDungeon(_ chest: ChestRecord) -> Bool {
        guard chest.readable, chest.dimension == "o", chest.y <= 50 else { return false }
        let ids = Set(chest.items.filter { $0.quantity > 0 }.map(\.itemID))
        // Local item catalog: rail, redstone dust, torch, golden apple.
        // Height alone and individual items are deliberately insufficient.
        return ids.contains(170) && ids.contains(3270) && (ids.contains(147) || ids.contains(3213))
    }
    func isKnown(_ chest: ChestRecord) -> Bool { owned.contains(chest.id) || visible.contains(chest.id) }
    func isHidden(_ chest: ChestRecord) -> Bool {
        if hidden.contains(chest.id) { return true }
        if visible.contains(chest.id) || owned.contains(chest.id) { return false }
        return hideSuspected && Self.suspectedDungeon(chest)
    }
    mutating func setHidden(_ value: Bool, for chests: [ChestRecord]) {
        for chest in chests {
            if value { hidden.insert(chest.id); visible.remove(chest.id) }
            else { hidden.remove(chest.id); visible.insert(chest.id) }
        }
    }
    static func load(world: String, defaults: UserDefaults = .standard) -> Self {
        let key = "chests.visibility." + world
        return Self(hidden: Set(defaults.stringArray(forKey: key + ".hidden") ?? []),
                    visible: Set(defaults.stringArray(forKey: key + ".visible") ?? []),
                    owned: Set(defaults.stringArray(forKey: "conversation.ownedChests." + world) ?? []),
                    hideSuspected: defaults.bool(forKey: key + ".suspected"))
    }
    func save(world: String, defaults: UserDefaults = .standard) {
        let key = "chests.visibility." + world
        defaults.set(hidden.sorted(), forKey: key + ".hidden")
        defaults.set(visible.sorted(), forKey: key + ".visible")
        defaults.set(hideSuspected, forKey: key + ".suspected")
    }
}

/// Explicit resource IDs from ItemNames.json; equipment names must not match resources.
struct ChestMaterialShortcut: Identifiable {
    let id: String
    let de: String
    let en: String
    let itemIDs: Set<Int>
    let detailDE: String
    let detailEN: String
    static let all: [Self] = [
        .init(id: "diamond", de: "Diamanten", en: "Diamonds", itemIDs: [3157,155,156,157], detailDE: "Diamanten, Erze und Diamantblöcke", detailEN: "Diamonds, ores and diamond blocks"),
        .init(id: "gold", de: "Gold", en: "Gold", itemIDs: [3165,3160,3179,31,32,37,140,895], detailDE: "Barren, Nuggets, Rohgold, Erze und Goldblöcke", detailEN: "Ingots, nuggets, raw gold, ores and gold blocks"),
        .init(id: "iron", de: "Eisen", en: "Iron", itemIDs: [3159,3175,3180,33,34,141,893], detailDE: "Barren, Nuggets, Roheisen, Erze und Eisenblöcke", detailEN: "Ingots, nuggets, raw iron, ores and iron blocks"),
        .init(id: "wood", de: "Holz", en: "Wood", itemIDs: Set(Array(13...18) + Array(38...61) + [697,698,706,707,718,719,900]), detailDE: "Stämme, Holz und Bretter; keine fertigen Möbel oder Werkzeuge", detailEN: "Logs, wood, stems and planks; no furniture or tools"),
        .init(id: "cobble", de: "Bruchstein", en: "Cobblestone", itemIDs: [12], detailDE: "Gewöhnlicher Bruchstein; keine Treppen, Mauern oder Stufen", detailEN: "Plain cobblestone; no stairs, walls or slabs"),
        .init(id: "coal", de: "Kohle", en: "Coal", itemIDs: [3155,3156,35,36,422], detailDE: "Kohle, Holzkohle, Kohleerze und Kohleblöcke", detailEN: "Coal, charcoal, coal ores and coal blocks"),
        .init(id: "redstone", de: "Redstone", en: "Redstone", itemIDs: [3270,187,188,347], detailDE: "Redstone-Staub, Erze und Blöcke; keine Schaltungen", detailEN: "Redstone dust, ores and blocks; no circuit components")
    ]
    static func matches(_ chest: ChestRecord, selected: Set<String>, requireAll: Bool) -> Bool {
        guard !selected.isEmpty else { return true }
        guard chest.readable else { return false }
        let presets = all.filter { selected.contains($0.id) }
        guard presets.count == selected.count else { return false }
        let contents = Set(chest.items.filter { $0.quantity > 0 }.map(\.itemID))
        return requireAll ? presets.allSatisfy { !$0.itemIDs.isDisjoint(with: contents) } : presets.contains { !$0.itemIDs.isDisjoint(with: contents) }
    }
    static func highlights(_ item: ChestItem, selected: Set<String>) -> Bool {
        item.quantity > 0 && all.contains { selected.contains($0.id) && $0.itemIDs.contains(item.itemID) }
    }
}

enum ChestSortOrder: String, CaseIterable {
    case origin, most, least, distance
    func title(_ en: Bool) -> String {
        switch self {
        case .origin: return en ? "Near origin" : "Nähe zum Ursprung"
        case .most: return en ? "Most items first" : "Größte Menge zuerst"
        case .least: return en ? "Fewest items first" : "Kleinste Menge zuerst"
        case .distance: return en ? "Near reference chest" : "Nähe zur Bezugskiste"
        }
    }
}
enum ChestSorting {
    static func quantity(_ chest: ChestRecord, matching: (ChestItem) -> Bool) -> Int64? {
        guard chest.readable else { return nil }
        return chest.items.filter { $0.quantity > 0 && matching($0) }.reduce(Int64(0)) { total, item in
            let (sum, overflow) = total.addingReportingOverflow(Int64(item.quantity))
            return overflow ? Int64.max : sum
        }
    }
    static func distance(_ chest: ChestRecord, from reference: ChestRecord) -> Double? {
        guard chest.dimension == reference.dimension else { return nil }
        let x = Double(chest.x) - Double(reference.x), y = Double(chest.y) - Double(reference.y), z = Double(chest.z) - Double(reference.z)
        return sqrt(x*x + y*y + z*z)
    }
    static func sorted(_ records: [ChestRecord], order: ChestSortOrder, reference: ChestRecord?, matching: (ChestItem) -> Bool) -> [ChestRecord] {
        let quantities = Dictionary(uniqueKeysWithValues: records.map { ($0.id, quantity($0, matching: matching)) })
        return records.sorted { a, b in
            if order == .most || order == .least {
                let qa = quantities[a.id] ?? nil, qb = quantities[b.id] ?? nil
                if let qa, let qb { if qa != qb { return order == .most ? qa > qb : qa < qb } }
                else if (qa == nil) != (qb == nil) { return qa != nil }
            } else if order == .distance, let reference {
                let da = distance(a, from: reference) ?? .infinity, db = distance(b, from: reference) ?? .infinity
                if da != db { return da < db }
            } else {
                let da = hypot(Double(a.x), Double(a.z)), db = hypot(Double(b.x), Double(b.z))
                if da != db { return da < db }
            }
            return a.id < b.id
        }
    }
}
