import Foundation

@main struct CraftingWalkthroughTests {
    static func main() throws {
        let catalog = try CraftingCatalog.load(from: URL(fileURLWithPath:CommandLine.arguments[1])), index = catalog.index()
        var checks = 0
        func check(_ value: Bool, _ message: String) { precondition(value,message); checks += 1 }
        let pickaxe = index.recipes["diamond_pickaxe"]!.first!
        let target = CraftingInstruction.recipe(pickaxe)
        for recipe in catalog.recipes {
            let steps = CraftingWalkthrough.recipe(recipe,index:index,desired:3,english:true)
            check(steps.count >= 4 && Set(steps.map(\.id)).count == steps.count && steps.allSatisfy { !$0.title.isEmpty && !$0.text.isEmpty },"Every recipe has usable ordered steps")
        }
        for guide in catalog.acquisitionGuides {
            check(CraftingWalkthrough.obtaining(guide,english:false).count == guide.steps.count,"Obtaining steps retain authored boundaries")
        }
        let steps = CraftingWalkthrough.recipe(pickaxe,index:index,desired:2,english:false)
        check(steps[0].text.contains("6 × Diamant") && steps[0].text.contains("4 ×"),"Pickaxe material quantities are scaled")
        check(steps.contains { $0.visual == .arrangement },"Shaped recipe has illustrated arrangement")
        check(CraftingWalkthrough.stationItem(pickaxe.station) == "crafting_table","Station is linked separately")
        var preferences = CraftingAgentPreferences()
        preferences.records[target.id] = .init(selected:true)
        preferences.verify(target,index:index,enabled:true)
        let verified = try CraftingAgentSnapshot.make(index:index,preferences:preferences,scope:.verified,includePrerequisites:true,english:true)
        check(verified.entries.count == 1 && verified.entries[0]["verifiedByUser"] as? Bool == true,"Verified-only scope never adds unverified prerequisites")
        let expanded = try CraftingAgentSnapshot.make(index:index,preferences:preferences,instructions:[target],desired:2,includePrerequisites:true,english:false)
        let ids = Set(expanded.entries.compactMap { $0["itemID"] as? String })
        check(ids.contains("stick") && ids.contains("crafting_table") && ids.contains("oak_planks"),"Pickaxe export includes intermediate and station references")
        check(expanded.entries.count < 991 && expanded.entries.count == Set(expanded.entries.compactMap { $0["id"] as? String }).count,"Dependency cycles terminate without duplicate guides")
        let main = expanded.entries.first { $0["id"] as? String == target.id }!
        let ingredients = main["ingredientOptions"] as! [[String:Any]]
        check(ingredients.contains { $0["required"] as? Int == 6 && ($0["itemIDs"] as? [String]) == ["diamond"] },"Structured quantities use the target amount")
        check((main["steps"] as? [[String:Any]])?.count == 5,"Step data and illustrated recipe agree")
        check(main["inclusion"] as? String == "requested" && main["desiredQuantity"] as? Int == 2,"Root request remains distinct from prerequisites")
        check(expanded.entries.contains { $0["inclusion"] as? String == "prerequisite-reference" && $0["verifiedByUser"] as? Bool == false },"Automatically included references retain their own evidence")
        let entire = try CraftingAgentSnapshot.make(index:index,preferences:.init(),scope:.all,english:true)
        check(entire.entries.count == 991,"Full catalog works with no manual checkmarks")
        check(entire.markdown.contains("first clarify material") && entire.markdown.contains("aggregate shared demand"),"Agent gets ambiguity and intermediate-calculation guidance")
        let document = AIContextDocument(payload:[:],markdown:"# Synthetic").addingCrafting(entire)
        let json = try JSONSerialization.jsonObject(with:document.json) as! [String:Any]
        check((json["craftingKnowledge"] as? [String:Any])?["scope"] as? String == "all","Actual AI export includes scope and structured knowledge")
        var conversation = CraftingConversation(index:index)
        check(conversation.answer("Wie baue ich eine Spitzhacke und was brauche ich dafür?",english:false)?.text.contains("Welchen Gegenstand") == true,"Unspecific pickaxe asks for material")
        check(conversation.answer("Diamant",english:false)?.text.contains("Schritt-für-Schritt-Anleitung") == true && conversation.lastItem == "diamond_pickaxe","Material-only reply resolves the pending pickaxe")
        check(conversation.answer("Wie baue ich 2 Diamantspitzhacken Schritt für Schritt?",english:false)?.text.contains("Schritt 1 von 5") == true,"Explicit one-step mode")
        check(conversation.answer("weiter",english:false)?.text.contains("Schritt 2 von 5") == true && conversation.lastQuantity == 2,"Next retains target amount")
        check(conversation.answer("Schritt 3",english:false)?.text.contains("Raster") == true,"Direct arrangement step")
        check(conversation.answer("vorheriger Schritt",english:false)?.text.contains("Schritt 2 von 5") == true,"Previous step")
        check(conversation.answer("Schritt 99",english:false)?.text.contains("1 bis 5") == true,"Invalid step does not become a quantity")
        check(conversation.answer("How do I make a pickaxe out of diamond?",english:true)?.text.contains("Diamond") == true,"Natural English material expression")
        if CommandLine.arguments.count > 2 {
            let output = URL(fileURLWithPath:CommandLine.arguments[2])
            try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
            try expanded.markdown.write(to:output.appendingPathComponent("diamond-pickaxe-with-prerequisites.md"),atomically:true,encoding:.utf8)
            try document.json.write(to:output.appendingPathComponent("all-guides-synthetic.json"))
        }
        print("PASS: \(checks) walkthrough checks; \(entire.entries.count) complete guides; \(expanded.entries.count) pickaxe/prerequisite references")
    }
}
