import Foundation

@main struct PlayerTests {
    static func main() throws {
        // Synthetic fixture: no personal saves are included in the distributed source.
        func be(_ n: Int) -> [UInt8] { [UInt8((n>>24)&255),UInt8((n>>16)&255),UInt8((n>>8)&255),UInt8(n&255)] }
        func item(_ id: Int, _ quantity: Int, _ slot: Int, extra: Bool = false, effectID: Int = 7, effectLevel: Int = 4, durability: Int = 100, anvilUses: Int = 2) -> [UInt8] {
            var b = be(id) + [0,1,2,0,55] + Array(repeating: UInt8(42), count: 16) + [0,8,1] + be(id) + be(quantity) + [0,0,0,0]
            if extra { b += [0,24,1] + be(durability) + be(anvilUses) + [0,59,0] + be(1) + [UInt8(effectID>>8),UInt8(effectID&255)] + be(effectLevel) }
            return b + [0,12,0] + be(slot) + [255,255]
        }
        func fixture(inventory: [[UInt8]], armor: [[UInt8]]) -> Data {
            var b: [UInt8] = [2,0,0,0,1,0,0,0,0]
            b += Array(repeating: 0, count: 129)
            b += [0,13,1,0,0,0,7,1] + be(36) + be(inventory.count)
            for i in inventory { b += i }
            b += [1] + be(4) + be(armor.count)
            for i in armor { b += i }
            b += [0,41,1] + Array(repeating: 0, count: 11) + [245,1,0,0,0,0,143,190,112]
            b.replaceSubrange(5..<9, with: be(b.count-9))
            return Data(b)
        }
        let good = fixture(inventory: [item(3028,1,0,extra:true),item(147,56,35)], armor:[item(3047,1,3,extra:true)])
        let p = try PlayerReader.parse(good)
        precondition(p.level == 501 && p.inventory.count == 2 && p.inventory[1].slot == 36 && p.armor[0].itemID == 3047)
        precondition(p.inventory[0].additionalData && !p.inventory[1].additionalData)
        precondition(p.inventory[0].enchantments.first?.enchantmentID == 7 && p.inventory[0].enchantments.first?.level == 4)
        precondition(p.inventory[1].enchantments.isEmpty && p.armor[0].enchantments.count == 1)
        let unknown = try PlayerReader.parse(fixture(inventory: [item(3028,1,0,extra:true,effectID:60000,effectLevel:12)],armor:[]))
        precondition(unknown.inventory[0].enchantments[0].enchantmentID == 60000 && unknown.inventory[0].enchantments[0].level == 12)
        precondition(p.inventory[0].durability == 100 && p.inventory[1].durability == nil && p.armor[0].durability == 100)
        // Zero is a saved condition, never a missing value; unknown item IDs keep their raw state.
        let zero = try PlayerReader.parse(fixture(inventory:[item(60000,1,0,extra:true,durability:0)],armor:[]))
        precondition(zero.inventory[0].durability == 0)
        let high = try PlayerReader.parse(fixture(inventory:[item(60000,1,0,extra:true,durability:2147483647)],armor:[]))
        precondition(high.inventory[0].durability == 2147483647)
        let legacy = Data("{\"slot\":1,\"itemID\":147,\"quantity\":2,\"additionalData\":false,\"enchantments\":[]}".utf8)
        let legacyItem = try JSONDecoder().decode(PlayerItem.self,from:legacy)
        precondition(legacyItem.durability == nil)
        precondition(p.inventory[0].durabilityMaximum == 1561 && p.armor[0].durabilityMaximum == 363)
        precondition(p.inventory[1].durabilityMaximum == nil && zero.inventory[0].durabilityFraction == nil)
        let full = try PlayerReader.parse(fixture(inventory:[item(3004,1,0,extra:true,durability:1561)],armor:[]))
        precondition(full.inventory[0].durabilityFraction == 1)
        let depleted = try PlayerReader.parse(fixture(inventory:[item(3069,1,0,extra:true,durability:0)],armor:[]))
        precondition(depleted.inventory[0].durabilityFraction == 0)
        let over = try PlayerReader.parse(fixture(inventory:[item(3004,1,0,extra:true,durability:1562)],armor:[]))
        precondition(over.inventory[0].durability == 1562 && over.inventory[0].durabilityFraction == nil)
        precondition(DurabilityCatalog.maxima.count == 61 && DurabilityCatalog.maxima[3069] == 384)
        let exported = try JSONEncoder().encode(unknown)
        let decoded = try JSONDecoder().decode(PlayerSnapshot.self,from:exported)
        precondition(decoded.inventory[0].enchantments[0].enchantmentID == 60000)
        precondition(decoded.inventory[0].durability == 100 && decoded.inventory[0].durabilityMaximum == 1561)
        let empty = try PlayerReader.parse(fixture(inventory:[],armor:[]));precondition(empty.inventory.isEmpty && empty.armor.isEmpty)
        func rejects(_ d: Data) {
            do { _ = try PlayerReader.parse(d); fatalError("Accepted invalid data") } catch {}
        }
        for length in 0..<good.count { rejects(good.prefix(length)) }
        rejects(fixture(inventory:[item(1,1,0),item(2,1,0)],armor:[]))
        rejects(fixture(inventory:[item(1,0,0)],armor:[]))
        rejects(fixture(inventory:[item(1,1,36)],armor:[]))
        rejects(fixture(inventory:[item(3028,1,0,extra:true,effectLevel:0)],armor:[]))
        rejects(fixture(inventory:[item(3028,1,0,extra:true,durability:2147483648)],armor:[]))
        rejects(fixture(inventory:[item(3028,1,0,extra:true,anvilUses:4294967295)],armor:[]))
        var duplicate = item(3028,1,0,extra:true)
        let effect = Array(duplicate[58..<64]); duplicate.insert(contentsOf: effect,at:64)
        duplicate.replaceSubrange(54..<58,with:be(2))
        rejects(fixture(inventory:[duplicate],armor:[]))
        var bad = good; bad[0] = 3; rejects(bad)
        // Optional personal regression paths stay outside the packaged test sources.
        for path in CommandLine.arguments.dropFirst() {
            let result = try PlayerReader.parse(Data(contentsOf: URL(fileURLWithPath:path)))
            print("Personal regression: level \(result.level.map(String.init) ?? "unknown"), inventory \(result.inventory.count), armor \(result.armor.count)")
        }
        print("Player parser tests passed")
    }
}
