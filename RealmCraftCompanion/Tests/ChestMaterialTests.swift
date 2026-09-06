import Foundation
@main struct ChestMaterialTests {
    static func main() throws {
        func chest(_ ids: [Int], readable: Bool = true) -> ChestRecord {
            ChestRecord(id: "o:1,25,2", dimension: "o", x: 1, y: 25, z: 2, file: "fixture", items: ids.enumerated().map { ChestItem(slot: $0.offset, itemID: $0.element, quantity: 1, extraData: false) }, readable: readable, error: "")
        }
        let both: Set<String> = ["diamond", "gold"]
        precondition(ChestMaterialShortcut.matches(chest([3157]), selected: both, requireAll: false))
        precondition(!ChestMaterialShortcut.matches(chest([3157]), selected: both, requireAll: true))
        precondition(ChestMaterialShortcut.matches(chest([157,3165]), selected: both, requireAll: true))
        precondition(!ChestMaterialShortcut.matches(chest([3004]), selected: ["diamond"], requireAll: false))
        precondition(!ChestMaterialShortcut.matches(chest([171]), selected: ["cobble"], requireAll: false))
        for id in [13,38,49,61,697,900] { precondition(ChestMaterialShortcut.matches(chest([id]), selected: ["wood"], requireAll: true)) }
        precondition(!ChestMaterialShortcut.matches(chest([3157]), selected: both, requireAll: true))
        precondition(!ChestMaterialShortcut.matches(chest([3165]), selected: both, requireAll: true)) // adjacent chests cannot combine their inventories
        precondition(!ChestMaterialShortcut.matches(chest([3157], readable: false), selected: ["diamond"], requireAll: false))
        precondition(ChestMaterialShortcut.matches(chest([]), selected: [], requireAll: true))
        precondition(!ChestMaterialShortcut.matches(chest([]), selected: ["invalid"], requireAll: true))
        let names = try JSONDecoder().decode([String:ItemName].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        for preset in ChestMaterialShortcut.all { for id in preset.itemIDs { precondition(names[String(id)] != nil, "Unknown catalog ID") } }
        print("PASS: any/all per chest, material variants, equipment exclusion, wood family, unreadable records, empty selection, catalog IDs")
    }
}
