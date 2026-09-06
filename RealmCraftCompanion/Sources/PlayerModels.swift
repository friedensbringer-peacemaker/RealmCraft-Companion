import Foundation

struct PlayerEnchantment: Codable, Identifiable {
    let enchantmentID: Int
    let level: Int
    var id: Int { enchantmentID }
}
enum DurabilityWarning { case normal, caution, critical, unknown }
struct PlayerItem: Codable, Identifiable {
    let slot: Int
    let itemID: Int
    let quantity: Int
    let additionalData: Bool
    var enchantments: [PlayerEnchantment] = []
    var durability: Int? = nil
    var durabilityMaximum: Int? = nil
    var durabilityFraction: Double? {
        guard let remaining = durability, let maximum = durabilityMaximum,
              maximum > 0, remaining >= 0, remaining <= maximum else { return nil }
        return Double(remaining) / Double(maximum)
    }
    var durabilityWarning: DurabilityWarning {
        guard let fraction = durabilityFraction else { return .unknown }
        if fraction < 0.20 { return .critical }
        if fraction < 0.50 { return .caution }
        return .normal
    }
    var id: Int { slot }
}
struct PlayerSnapshot: Codable {
    let inventory: [PlayerItem]
    let armor: [PlayerItem]
    let level: Int?
}
struct PlayerReadError: LocalizedError {
    let errorDescription: String?
    init(_ text: String) { errorDescription = text }
}

// Only the observed version-2 player / version-1 item layout is accepted.
// Container bounds and structured item lengths prevent payload bytes from becoming slots.
enum PlayerReader {
    static func parse(_ data: Data) throws -> PlayerSnapshot {
        let b = Array(data)
        func require(_ ok: Bool) throws {
            if !ok { throw PlayerReadError("Unsupported or incomplete player data / Nicht unterstützte oder unvollständige Spielerdaten.") }
        }
        func matches(_ p: Int, _ bytes: [UInt8]) -> Bool {
            p >= 0 && p + bytes.count <= b.count && Array(b[p..<p+bytes.count]) == bytes
        }
        func number(_ p: Int, little: Bool = false) throws -> Int {
            try require(p >= 0 && p + 4 <= b.count)
            let bytes = little ? Array(b[p..<p+4].reversed()) : Array(b[p..<p+4])
            return bytes.reduce(0) { ($0 << 8) | Int($1) }
        }
        func occurrences(_ bytes: [UInt8], from: Int = 0) -> [Int] {
            guard from >= 0, b.count >= bytes.count, from <= b.count-bytes.count else { return [] }
            return (from...b.count-bytes.count).filter { matches($0, bytes) }
        }
        try require(b.count >= 150 && b.count <= 4_000_000 && matches(0, [2,0,0,0,1]))
        try require(try number(5) == b.count-9)
        let anchors = occurrences([0,13,1]).filter { matches($0+7, [1,0,0,0,36]) }
        try require(anchors.count == 1)
        var p = anchors[0]+7
        func container(_ capacity: Int) throws -> [PlayerItem] {
            try require(matches(p, [1]))
            try require(try number(p+1) == capacity)
            let count = try number(p+5)
            try require(count <= capacity)
            p += 9
            var result: [PlayerItem] = []
            var slots = Set<Int>()
            for _ in 0..<count {
                let id = try number(p)
                try require(matches(p+4, [0,1,2,0,55]) && matches(p+25, [0,8,1]))
                try require(try number(p+28) == id)
                let quantity = try number(p+32)
                try require(id > 0 && id <= 65535 && quantity > 0 && quantity <= 2147483647)
                p += 36
                try require(matches(p, [0,0,0,0])); p += 4
                var durability: Int?
                var extra = false
                var enchantments: [PlayerEnchantment] = []
                if matches(p, [0,24,1]) {
                    extra = true
                    // DurabilityComponent v1 serializes remaining durability, then AnvilUses.
                    let remaining = try number(p+3)
                    let anvilUses = try number(p+7)
                    try require(remaining <= Int(Int32.max) && anvilUses <= Int(Int32.max))
                    durability = remaining
                    p += 11
                    try require(matches(p, [0,59,0]))
                    let effects = try number(p+3)
                    try require(effects <= 256)
                    p += 7
                    var effectIDs = Set<Int>()
                    for _ in 0..<effects {
                        try require(p+6 <= b.count)
                        let id = Int(b[p]) << 8 | Int(b[p+1])
                        let level = try number(p+2)
                        try require(level > 0 && level <= 2147483647 && effectIDs.insert(id).inserted)
                        enchantments.append(PlayerEnchantment(enchantmentID: id, level: level))
                        p += 6
                    }
                }
                try require(matches(p, [0,12,0]))
                let slot = try number(p+3)
                try require(slot < capacity && slots.insert(slot).inserted && matches(p+7, [255,255]))
                p += 9
                result.append(PlayerItem(slot: slot+1, itemID: id, quantity: quantity, additionalData: extra, enchantments: enchantments, durability: durability, durabilityMaximum: durability == nil ? nil : DurabilityCatalog.maxima[id]))
            }
            return result.sorted { $0.slot < $1.slot }
        }
        let inventory = try container(36)
        let armor = try container(4)
        // Relative field location, validated against saved levels 3, 300 and 501.
        // Unknown/ambiguous experience components do not produce an invented level.
        let experience = occurrences([0,41,1], from: p)
        var level: Int?
        if experience.count == 1 {
            let start = experience[0]
            if matches(start+18, [0,0,143,190,112]) {
                let value = try number(start+14, little: true)
                if value <= 1_000_000 { level = value }
            }
        }
        return PlayerSnapshot(inventory: inventory, armor: armor, level: level)
    }
}
