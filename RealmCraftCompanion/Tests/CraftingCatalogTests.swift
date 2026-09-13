import Foundation

@main struct CraftingCatalogTests {
    static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let catalog = try CraftingCatalog.load(from: url), index = catalog.index()
        var checks = 0
        func check(_ condition: Bool, _ message: String) { precondition(condition, message); checks += 1 }
        func recipe(_ id: String) -> CraftingRecipe { catalog.recipes.first { $0.id == id }! }
        let torch = recipe("torch"), table = recipe("crafting_table"), bed = recipe("white_bed")
        check(torch.batches(for: 65) == 17 && torch.produced(for: 65) == 68, "Round target up to whole batches")
        check(torch.ingredients.allSatisfy { $0.count * torch.batches(for: 65) == 17 }, "Scale direct ingredients")
        check(torch.batches(for: 64) == 16 && torch.produced(for: 64) == 64, "Exact output multiple")
        check(torch.batches(for: Int.min) == 1 && torch.batches(for: Int.max) == 2500, "Bound external quantity input before arithmetic")
        check(torch.ingredients.contains { Set($0.options) == ["coal", "charcoal"] }, "Alternatives survive import without adding both counts")
        check(table.station == .inventory && table.grid == [1, 1, 1, 1] && table.ingredients[0].count == 4, "2x2 workbench reference")
        check(table.ingredients[0].options.contains("crimson_planks"), "Resolve full pinned tag, not an invented restricted subset")
        check(bed.station == .table && bed.ingredients.contains { $0.options == ["white_wool"] && $0.count == 3 }, "Do not merge differently colored wool")
        check(recipe("bread").station == .table, "Three-wide row does not fit inventory")
        check(recipe("sugar_from_sugar_cane").station == .inventory, "Shapeless inventory recipe")
        check(recipe("glass").station.usesFuel && !recipe("stone_brick_slab_from_stone_stonecutting").station.usesFuel, "Separate fuel from ingredients")
        check(recipe("netherite_pickaxe_smithing").station == .smithing, "Version-specific upgrade is not a 3x3 crafting recipe")
        check(index.filtered(query: "werkbank", english: false).map(\.id).contains("crafting_table"), "German alias")
        check(index.filtered(query: "stÖcke", english: true).map(\.id).contains("stick"), "Cross-language diacritic alias")
        check(index.filtered(query: "3157", english: false).map(\.id) == ["diamond"], "Numeric catalog lookup")
        check(index.filtered(query: "unfindable fixture", english: true).isEmpty, "No matches is empty")
        check(index.filtered(query: "", station: "furnace", coverage: "open", english: false).isEmpty, "Combine filters consistently")
        check(Set(index.filtered(query: "", coverage: "wiki", english: true).map(\.id)).isSuperset(of: ["crafting_table", "enchanting_table"]), "Field-scoped wiki evidence only")
        check(index.filtered(query: "oak planks", coverage: "recipes", english: true).contains { $0.id == "oak_planks" }, "AND search retains multiword variants")
        check(index.recipes["saddle"] == nil && index.filtered(query: "saddle", coverage: "open", english: true).count == 1, "No fabricated recipe for missing entry")
        check(index.items["carrot"]?.itemID == nil && index.items["carrots"]?.itemID != nil, "Do not confuse crop block with food ingredient")
        check(index.uses["diamond", default: []].contains { $0.id == "diamond_pickaxe" }, "Reverse ingredient navigation")
        let copy = index.summary(torch, desired: 65, english: false)
        check(copy.contains("17 Durchgänge") && copy.contains("ungeprüft") && copy.contains("Raster für einen Durchgang"), "Copied recipe retains quantity, grid and caveat")
        check(index.summary(recipe("glass"), desired: 10, english: true).contains("Additional fuel"), "Copied smelting includes fuel caveat")
        for item in catalog.items { check(!item.title.de.isEmpty && !item.title.en.isEmpty, "Bilingual labels") }
        for r in catalog.recipes {
            check(r.ingredients.allSatisfy { $0.options.allSatisfy { index.items[$0] != nil } }, "No dangling ingredient links")
            check(index.items[r.output] != nil, "No dangling outputs")
        }
        var object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        var rows = object["recipes"] as! [[String: Any]]
        let position = rows.firstIndex { $0["id"] as? String == "crafting_table" }!
        rows[position]["grid"] = [1, 1, 0, 0]
        object["recipes"] = rows
        let malformed = try JSONDecoder().decode(CraftingCatalog.self, from: JSONSerialization.data(withJSONObject: object))
        do { try malformed.validate(); fatalError("Accepted inconsistent ingredient/grid count") }
        catch { checks += 1 }
        print("PASS: \(checks) crafting checks; \(catalog.recipes.count) recipe variants, \(index.recipes.count) outputs")
    }
}
