import Foundation
@main struct CraftingTests {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let recipes = try JSONDecoder().decode([ConversationRecipe].self, from: Data(contentsOf: root.appendingPathComponent("ConversationRecipes.json")))
        let names = try JSONDecoder().decode([String: ItemName].self, from: Data(contentsOf: root.appendingPathComponent("ItemNames.json")))
        let date = Date(timeIntervalSince1970: 1788600000)
        func chest(_ id: String, _ pairs: [(Int, Int)], readable: Bool = true) -> ChestRecord {
            ChestRecord(id: id, dimension: "o", x: 12, y: 64, z: -4, file: "fixture", items: pairs.enumerated().map { .init(slot: $0.offset, itemID: $0.element.0, quantity: $0.element.1, extraData: false) }, readable: readable, error: readable ? "" : "fixture error")
        }
        func context(_ chests: [ChestRecord], own: Set<String> = ["mine"], errors: [String] = []) -> CompanionStorageContext {
            CompanionStorageContext(savedAt: date, backupAt: date, index: ChestIndex(chunksScanned: 1, chests: chests, errors: errors), ownedIDs: own, itemNames: names, chestLabels: ["mine": "Werkzeuglager"])
        }
        var count = 0
        func check(_ condition: Bool, _ message: String) { precondition(condition, message); count += 1 }
        let bed = recipes.first { $0.id == "bed" }!, box = recipes.first { $0.id == "chest" }!
        let mixed = context([chest("mine", [(13,3),(108,1),(109,1),(110,1)]), chest("npc", [(108,999),(13,999)])])
        let mixedText = mixed.craft(bed, english: false).text
        check(mixedText.contains("fehlen 2"), "Mixed wool colors and NPC stock cannot complete bed")
        check(mixedText.contains("Minecraft") && mixedText.contains("Spielstand vom") && mixedText.contains("ungenau"), "Recipe and save caveats")
        let ready = context([chest("mine", [(13,8),(108,3)])])
        check(ready.craft(bed, english: false).text.contains("reichen für eine Ausführung"), "Enough direct ingredients")
        check(ready.craft(box, english: true).text.contains("cover one execution"), "English chest comparison")
        let locations = ready.craft(bed, english: false, locations: true).text
        check(locations.contains("Werkzeuglager") && locations.contains("X 12"), "Named chest coordinates")
        check(!(ready.craft(bed, english: false).spokenText ?? "").contains("X 12"), "Brief speech omits detailed coordinates")
        let partial = context([chest("mine", [(13,1)]), chest("broken", [], readable: false)], own: ["mine", "broken"])
        check(!partial.completeOwnedIndex && partial.craft(box, english: false).text.contains("in lesbaren Kisten nicht gefunden"), "Unreadable chest not definitive missing")
        check(!context([chest("mine", [])], own: ["mine", "absent"]).completeOwnedIndex, "Absent owner marker")
        check(!context([chest("mine", [])], errors: ["scan error"]).completeOwnedIndex, "Scan issue completeness")
        let none = context([chest("mine", [(13,99)])], own: [])
        check(none.craft(box, english: false).text.contains("markiere deine Kisten"), "No ownership is unknown, not zero")
        var knowledge = ConversationKnowledge(recipes: recipes, guides: [])
        func ask(_ question: String, world: String = "a") -> CompanionAnswer {
            knowledge.answer(question, world: world, places: [], english: false, storage: ready)
        }
        check(ask("Kann ich ein Bett craften?").text.contains("gefunden 3"), "Craft check route")
        check(ask("Wo liegen die Materialien?").text.contains("Werkzeuglager"), "Material location followup")
        check(ask("Habe ich genügend Material, um ein Bett zu bauen?").text.contains("gefunden 3"), "Natural sufficiency question")
        check(ask("Was fehlt mir dafür?").text.contains("Holzbretter"), "Missing-material followup")
        check(!ask("Kann ich eine Rakete bauen?").text.contains("gefunden 3"), "Unknown recipe never reuses bed")
        check(!ask("Wo liegen die Materialien?", world: "b").text.contains("Werkzeuglager"), "No context across worlds")
        check(ask("Kann ich 2 Bett craften?").text.contains("eine Rezeptausführung"), "Unsupported quantity explicit")
        check(!ask("Wo starte ich nach dem Sterben?").handled, "Unresolved location wording can reach the local model")
        check(!ask("Habe ich ausreichend Zeug für eine Schlafgelegenheit?").handled, "Unresolved craft target can reach the local model")
        check(ask("Kann ich ein Bett craften?").handled, "Exact craft query bypasses unnecessary reinterpretation")
        print("Crafting checks passed: \(count)")
    }
}
