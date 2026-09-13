import Foundation

@main struct CraftingBrowseTests {
    static func main() throws {
        let index = try CraftingCatalog.load(from: URL(fileURLWithPath: CommandLine.arguments[1])).index()
        var checks = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); checks += 1 }
        func type(_ id: String) -> String { CraftingBrowseType.of(index.items[id]!).id }
        check(type("acacia_boat") == type("oak_boat"), "Wood varieties share a boat family")
        check(type("oak_chest_boat") != type("oak_boat"), "Chest boats do not become ordinary boats")
        check(type("bamboo_raft") != type("bamboo_chest_raft"), "Chest rafts remain distinct")
        check(type("oak_fence") != type("oak_fence_gate"), "Fence gates use the longer type")
        check(type("iron_pickaxe") != type("iron_axe"), "Pickaxe is not an axe")
        check(type("oak_trapdoor") != type("oak_door"), "Trapdoors remain distinct")
        check(type("red_stained_glass") != type("red_stained_glass_pane"), "Panes are not glass blocks")
        check(type("red_concrete_powder") != type("red_concrete"), "Concrete powder is not hardened concrete")
        check(type("red_glazed_terracotta") != type("red_terracotta"), "Glazed and plain terracotta stay distinct")
        check(type("redstone") == "item:redstone", "Unrecognized items keep independent identity")
        let fixture = ["acacia_boat", "oak_button", "oak_boat", "acacia_door"].map { index.items[$0]! }
        for en in [false, true] {
            let groups = CraftingBrowseGroup.make(fixture, english: en)
            check(groups.map(\.id) == ["type:boat", "type:button", "type:door"], "Type order precedes material name")
            check(groups[0].items.map(\.id) == ["acacia_boat", "oak_boat"], "Materials sort inside their type")
            check(groups[0].type.title.value(en) == (en ? "Boats" : "Boote"), "Localized family heading")
            for query in ["", "boat", "birch", "3157", "no-such-fixture"] {
                let filtered = index.filtered(query: query, english: en)
                let grouped = CraftingBrowseGroup.make(filtered, english: en).flatMap(\.items)
                check(filtered.count == grouped.count && Set(filtered.map(\.id)) == Set(grouped.map(\.id)), "Grouping loses, duplicates or adds no filtered entry")
                check(CraftingBrowseGroup.make(Array(filtered.reversed()), english: en).flatMap(\.items).map(\.id) == grouped.map(\.id), "Stable order regardless of input order")
            }
        }
        for wood in ["oak", "birch", "acacia"] {
            let recipe = index.recipes[wood + "_boat"]!.first!
            check(recipe.ingredients.contains { $0.options == [wood + "_planks"] }, "Grouping does not mix a boat recipe's wood ingredients")
        }
        let tied = [CraftingItem(id: "z_boat", itemID: 1, title: .init(de: "Ä", en: "A")), CraftingItem(id: "a_boat", itemID: 2, title: .init(de: "a", en: "a"))]
        for en in [false, true] {
            check(CraftingBrowseGroup.make(tied, english: en)[0].items.map(\.id) == ["a_boat", "z_boat"], "Collation ties use stable item IDs")
        }
        print("Crafting browse: \(checks) type/variant/order/identity checks passed")
    }
}
