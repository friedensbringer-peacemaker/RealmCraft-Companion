import Foundation
@main struct ChestStatisticsTests {
    static func main() throws {
        func chest(_ id: String, _ items: [(Int,Int)], dimension: String = "o", readable: Bool = true) -> ChestRecord {
            ChestRecord(id: id, dimension: dimension, x: 0, y: 64, z: 0, file: "fixture", items: items.enumerated().map { ChestItem(slot: $0.offset, itemID: $0.element.0, quantity: $0.element.1, extraData: false) }, readable: readable, error: "")
        }
        let a = chest("o:0,64,0", [(3157,64),(3157,12),(13,40),(9999,5),(0,0)])
        let b = chest("o:1,64,0", [(3157,10),(13,8),(12,0),(1,-2)])
        let n = chest("n:0,64,0", [(3157,20)], dimension: "n")
        let bad = chest("o:2,64,0", [(3157,999)], readable: false)
        let index = ChestIndex(chunksScanned: 2, chests: [a,b,n,bad,a], errors: ["fixture"])
        var visibility = ChestVisibility(); visibility.owned = [a.id,bad.id]; visibility.hidden = [a.id]; visibility.visible = [b.id]
        let result = try ChestStockSummary.make(index: index, visibility: visibility)
        let diamond = result.items.first { $0.id == 3157 }!
        precondition(diamond.all == 106 && diamond.player == 76 && diamond.allChests == 3 && diamond.playerChests == 1)
        precondition(result.readable == 3 && result.unreadable == 1 && result.playerReadable == 1 && result.playerUnreadable == 1)
        precondition(result.scanIssues == 1 && result.duplicateRecords == 1 && result.invalidStacks == 1)
        let allTotal = try ChestStockSummary.total(result.items, player: false); precondition(allTotal == 159)
        let playerTotal = try ChestStockSummary.total(result.items, player: true); precondition(playerTotal == 121)
        precondition(result.items.allSatisfy { $0.player <= $0.all })
        let unowned = try ChestStockSummary.make(index: index, visibility: ChestVisibility())
        precondition(unowned.items.allSatisfy { $0.player == 0 && $0.playerChests == 0 })
        precondition(unowned.filtered(names: [:], query: "", category: "all", playerOnly: true, sort: "player", ascending: false, english: true).isEmpty)
        let known = try ChestStockSummary.make(index: index, visibility: visibility, knownOnly: true)
        precondition(known.readable == 2 && known.items.first { $0.id == 3157 }!.all == 86)
        let nether = try ChestStockSummary.make(index: index, visibility: visibility, dimension: "n")
        precondition(nether.readable == 1 && nether.playerReadable == 0 && nether.items.count == 1)
        let names = try JSONDecoder().decode([String:ItemName].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        func filter(_ query: String = "", category: String = "all", player: Bool = false, sort: String = "all", ascending: Bool = false) -> [ChestStockItem] {
            result.filtered(names: names, query: query, category: category, playerOnly: player, sort: sort, ascending: ascending, english: false)
        }
        precondition(filter("diamant 3157").map(\.id) == [3157])
        precondition(filter("diamond").map(\.id) == [3157])
        precondition(filter("9999").map(\.id) == [9999])
        precondition(filter("missing").isEmpty)
        precondition(filter(category: "wood").map(\.id) == [13])
        precondition(filter(sort: "id", ascending: true).map(\.id) == [13,3157,9999])
        precondition(filter(sort: "all").map(\.id) == [3157,13,9999])
        precondition(filter(sort: "all", ascending: true).map(\.id) == [9999,13,3157])
        let empty = try ChestStockSummary.make(index: ChestIndex(chunksScanned: 0, chests: [], errors: []), visibility: visibility); precondition(empty.items.isEmpty)
        for (id, category) in [(3157,ChestItemCategory.minerals),(3159,.minerals),(33,.minerals),(140,.minerals),(141,.minerals),(157,.minerals),(422,.minerals),(13,.wood),(38,.wood),(1,.stone),(12,.stone),(3212,.food),(3217,.food),(3270,.mechanisms),(3271,.mechanisms),(3300,.equipment),(3149,.plants)] {
            precondition(ChestItemCategory.classify(itemID: id, name: names[String(id)]) == category, "Category mismatch for \(id)")
        }
        for (name, category) in [("Diamond Pickaxe",ChestItemCategory.equipment),("Wooden Sword",.equipment),("Pig Spawn Egg",.other),("Crafting Table",.decoration),("Bowl",.ingredients)] {
            precondition(ChestItemCategory.classify(itemID: name == "Bowl" ? 3163 : 40000, name: ItemName(en: name, de: name)) == category, name)
        }
        precondition(ChestItemCategory.classify(itemID: 9999, name: nil) == .other)
        do { _ = try ChestStockSummary.add(Int64.max, 1); preconditionFailure("overflow accepted") } catch {}
        print("PASS: chest aggregation, stack quantities, ownership, hidden/known/dimension coverage, unreadable records, deduplication, search, filters, sorting, themes and overflow")
    }
}
