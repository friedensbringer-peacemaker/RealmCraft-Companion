import Foundation

@main struct ConversationTests {
    static func main() throws {
        let resource = URL(fileURLWithPath: CommandLine.arguments[1])
        let recipes = try JSONDecoder().decode([ConversationRecipe].self, from: Data(contentsOf: resource.appendingPathComponent("ConversationRecipes.json")))
        let guides = try JSONDecoder().decode(BuildCatalog.self, from: Data(contentsOf: resource.appendingPathComponent("BuildGuides.json"))).guides
        var engine = ConversationKnowledge(recipes: recipes, guides: guides)
        let places = CompanionPlace.named(["o:building:-12,64,30": "Haus", "n:chest:5,70,-8": "Netherlager", "bad": "Bogus", "o:bed:bad,3,4": "Invalid"])
        var count = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); count += 1 }
        check(places.count == 2, "Only valid named points")
        func ask(_ text: String, world: String? = "world-a", en: Bool = false, names: [CompanionPlace]? = nil) -> CompanionAnswer {
            engine.answer(text, world: world, places: names ?? places, english: en)
        }
        check(ask("Wo ist mein Haus?").text.contains("X -12, Y 64, Z 30"), "House lookup")
        check(ask("Wo war das?").text.contains("X -12"), "Place followup")
        check(!ask("Wo ist meine Burg?").text.contains("X -12"), "Unknown place does not reuse house")
        check(ask("Wo ist mein Haus?", world: nil).text.contains("Spielstand"), "World required")
        check(!ask("Wo ist mein Haus?", world: "world-b", names: []).text.contains("X -12"), "No cross-world place")
        check(ask("Wo bin ich?").text.contains("aktuelle Position"), "No fabricated player position")
        check(ask("Wie weit ist mein Haus?").text.contains("keine Live-Route"), "No fabricated route")
        let table = ask("Wie crafte ich eine Werkbank?")
        check(table.text.contains("4 Holzbretter"), "Recipe materials")
        check(table.text.contains("noch nicht geprüft") && !table.sources.isEmpty, "Evidence and source required")
        check(ask("Was brauche ich dafür?").text.contains("4 Holzbretter"), "Recipe followup")
        check(ask("Nochmal").text.contains("4 Holzbretter"), "Repeat")
        check(!ask("Wie crafte ich ein Laserschwert?").text.contains("4 Holzbretter"), "Unknown recipe not old recipe")
        check(!ask("Welche Materialien brauche ich für ein Laserschwert?").text.contains("4 Holzbretter"), "Unknown named material request not old recipe")
        check(ask("Was fehlt mir dafür?").text.contains("Spielstand"), "Missing storage remains explicit")
        check(!ask("Was brauche ich dafür?", world: "world-b").text.contains("4 Holzbretter"), "World change clears recipe context")
        check(ask("How do I craft a wooden pickaxe?", en: true).text.contains("3 wooden planks and 2 sticks"), "English recipe")
        check(ask("What do I need for that?", en: true).text.contains("3 wooden planks"), "English followup")
        check(ask("Wo ist mein Haus?", names: CompanionPlace.named(["o:bed:1,2,3":"Haus", "n:bed:3,4,5":"Haus"])).text.contains("mehrere Orte"), "Duplicate name not silently selected")
        check(ask("Welche Rezepte kennst du?").text.contains("Zauntor"), "Recipe discovery")
        let guide = guides[0]
        check(ask(guide.title.de).text.contains(guide.materials[0].name.de), "Build guide materials")
        check(ask("Was brauche ich dafür?").text.contains(guide.materials[0].name.de), "Build guide followup")
        check(ask("Was brauche ich für ein Bett?").text.contains("3 Wollblöcke"), "Bed recipe")
        check(ask("how do i craft a chest", en: true).text.contains("8 wooden planks"), "Screenshot chest regression")
        func chest(_ id: String, _ qty: Int, _ readable: Bool = true) -> ChestRecord {
            ChestRecord(id: id, dimension: "o", x: 10, y: 64, z: 20, file: "fixture", items: [ChestItem(slot: 0, itemID: 42, quantity: qty, extraData: false)], readable: readable, error: "")
        }
        let date = Date(timeIntervalSince1970: 1788602400)
        let index = ChestIndex(chunksScanned: 1, chests: [chest("mine", 64), chest("mine2", 32), chest("npc", 999)], errors: [])
        let names = ["42": ItemName(en: "Diamond", de: "Diamant")]
        let storage = CompanionStorageContext(savedAt: date, backupAt: date, index: index, ownedIDs: ["mine", "mine2"], itemNames: names)
        let counted = engine.answer("Wie viele Diamanten habe ich?", world: "world-a", places: [], english: false, storage: storage).text
        check(counted.contains("96") && !counted.contains("999"), "NPC chests excluded")
        check(counted.contains("X 10") && counted.contains("Sicherung vom") && counted.contains("ungenau"), "Count includes coordinates, date and caveat")
        check(engine.answer("Wo genau?", world: "world-a", places: [], english: false, storage: storage).text.contains("96"), "Storage followup")
        let partial = CompanionStorageContext(savedAt: date, backupAt: date, index: ChestIndex(chunksScanned: 1, chests: [chest("mine", 64), chest("mine2", 32, false)], errors: []), ownedIDs: ["mine", "mine2", "missing"], itemNames: names)
        check(partial.count(itemID: 42, english: false).text.contains("mindestens 64"), "Unreadable chests not treated as empty")
        let empty = CompanionStorageContext(savedAt: date, backupAt: date, index: index, ownedIDs: [], itemNames: names)
        check(empty.count(itemID: 42, english: false).text.contains("noch keine Kisten"), "Ownership must be explicit")
        let noIndex = CompanionStorageContext(savedAt: date, backupAt: date, index: nil, ownedIDs: ["mine"], itemNames: names)
        check(noIndex.count(itemID: 42, english: true).text.contains("Read the chests"), "No index is not zero")
        var prefix = [UInt8](repeating: 0, count: 110)
        prefix.replaceSubrange(0..<5, with: [2,0,0,0,1]); prefix[8] = 101
        prefix.replaceSubrange(30..<39, with: [0,14,0,1,1,0,0,2,1])
        prefix.replaceSubrange(63..<67, with: [0,0,3,0]); prefix.replaceSubrange(78..<87, with: [0,0,9,0,0,0,0,15,0]); prefix.replaceSubrange(99..<103, with: [0,0,5,1])
        prefix.replaceSubrange(87..<91, with: [255,255,255,235]); prefix[94] = 68; prefix[98] = 8
        let spawn = CompanionSpawnPoint.parse(Data(prefix))
        check(spawn == CompanionSpawnPoint(x: -21, y: 68, z: 8), "Signed spawn coordinates")
        for length in 0..<110 { check(CompanionSpawnPoint.parse(Data(prefix.prefix(length))) == nil, "Truncated spawn rejected") }
        prefix[86] = 1
        check(CompanionSpawnPoint.parse(Data(prefix)) == nil, "Unknown respawn version rejected")
        let spawnAnswer = engine.answer("Wo ist mein letzter Spawnpunkt?", world: "world-a", places: [], english: false, storage: storage, spawn: spawn).text
        check(spawnAnswer.contains("X -21") && spawnAnswer.contains("Spielstand vom") && spawnAnswer.contains("ungenau"), "Spawn answer provenance")
        check(!engine.answer("Spawnpunkt?", world: "world-a", places: places, english: false).text.contains("X -12"), "No invented spawn from named house")
        if CommandLine.arguments.count > 2 {
            let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
            check(CompanionSpawnPoint.parse(data) != nil, "Private save spawn regression")
        }
        print("Conversation tests passed: \(count)")
    }
}
