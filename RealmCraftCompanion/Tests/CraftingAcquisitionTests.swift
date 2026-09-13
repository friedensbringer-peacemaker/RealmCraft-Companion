import Foundation

@main struct CraftingAcquisitionTests {
    static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let catalog = try CraftingCatalog.load(from: url), index = catalog.index()
        var checks = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); checks += 1 }
        let lava = index.acquisitions["lava_bucket"]!
        check(index.recipes["lava_bucket"] == nil, "Obtaining is not a fabricated crafting recipe")
        for term in ["Lavakübel", "Lavaeimer", "Lavakuebel", "lava bucket"] {
            check(index.filtered(query: term, coverage: "acquisition", english: false).map(\.id) == ["lava_bucket"], "Bucket aliases in both languages")
        }
        check(index.filtered(query: "Lavakübel", coverage: "open", english: false).isEmpty, "Explained acquisition no longer appears as unknown")
        check(index.filtered(query: "Lavakübel", station: "acquisition", english: false).count == 1, "Outside-crafting station filter")
        check(index.filtered(query: "Lavakübel", station: "table", english: false).isEmpty, "No table station invented for filling")
        check(index.filtered(query: "Lavakübel", coverage: "wiki", english: false).count == 1, "Field-scoped RealmCraft mode evidence can be found")
        check(!index.filtered(query: "", coverage: "wiki", english: true).contains { $0.id == "milk_bucket" }, "Minecraft evidence is not RealmCraft wiki evidence")
        let report = lava.report(item: index.items["lava_bucket"]!, english: false)
        check(report.contains("Quellblock") && report.contains("Kreativmodus") && report.contains("ungeprüft") && report.contains("https://"), "Copy preserves procedure, mode and evidence")
        check(lava.relatedItems.contains("bucket") && index.recipes["bucket"]?.first?.ingredients.first?.count == 3, "Prerequisite links to the existing bucket recipe")
        check(index.acquisitions["bucket_of_cod"]?.id == index.acquisitions["bucket_of_salmon"]?.id, "Explicit family coverage")
        check(index.acquisitions["bucket_of_axolotl"] == nil, "Do not extend fish instructions to other creatures by suffix")
        check(index.acquisitions["oak_leaves"]?.id != index.acquisitions["oak_sapling"]?.id, "Different tools and drops keep separate guides")
        var conversation = CraftingConversation(index: index)
        check(conversation.answer("Wie bekomme ich einen Lavakübel?", english: false)?.text.contains("Quellblock") == true, "Natural German obtaining request")
        check(conversation.answer("How do I obtain a lava bucket?", english: true)?.text.contains("source block") == true, "English obtaining request")
        check(conversation.answer("Wie bekomme ich 4 Lavakübel?", english: false)?.text.contains("keine Crafting-Stückliste") == true, "Obtaining does not invent scaled recipe arithmetic")
        check(conversation.answer("How do I obtain leather?", english: true)?.text.contains("creature") == true, "Obtaining request can choose a guide when a conversion recipe also exists")
        var changed = catalog
        changed.acquisitionGuides.append(lava)
        do { try changed.validate(); fatalError("Accepted duplicate guide and item coverage") } catch { checks += 1 }
        let resource = url.deletingLastPathComponent().appendingPathComponent("CraftingAcquisition.json")
        var rows = try JSONSerialization.jsonObject(with: Data(contentsOf: resource)) as! [[String: Any]]
        rows[0]["relatedItems"] = ["nonexistent_synthetic_item"]
        changed.acquisitionGuides = try JSONDecoder().decode([CraftingAcquisition].self, from: JSONSerialization.data(withJSONObject: rows))
        do { try changed.validate(); fatalError("Accepted broken prerequisite link") } catch { checks += 1 }
        print("PASS: \(checks) obtaining checks; \(catalog.acquisitionGuides.count) guides for \(index.acquisitions.count) entries")
    }
}
