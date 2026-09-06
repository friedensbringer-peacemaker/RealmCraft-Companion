import Foundation

@main struct AIContextExportTests {
    static func main() throws {
        func check(_ condition: Bool, _ message: String) { if !condition { fatalError(message) } }
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let save = Savegame(id: UUID().uuidString, title: "World | <test>\nname", date: date, gameDate: date, world: "123", count: 2, bytes: 123, source: "local")
        let player = PlayerSnapshot(inventory: [PlayerItem(slot: 1, itemID: 42, quantity: 3, additionalData: true, enchantments: [PlayerEnchantment(enchantmentID: 999, level: 2)], durability: 9)], armor: [PlayerItem(slot: 1, itemID: 42, quantity: 1, additionalData: false)], level: 7)
        func chest(_ id: String, _ qty: Int, _ readable: Bool = true) -> ChestRecord {
            ChestRecord(id: id, dimension: "o", x: -10, y: 64, z: 20, file: "o.-16,16", items: [ChestItem(slot: 1, itemID: 42, quantity: qty, extraData: true)], readable: readable, error: readable ? "" : "unsupported")
        }
        func document(_ index: ChestIndex?, _ owned: Set<String>, player p: PlayerSnapshot? = player) -> AIContextDocument {
            AIContextExport.make(save: save, manifest: ["o.-16,16":"hash", "o.32,48":"hash"], player: p, spawn: CompanionSpawnPoint(x: -3, y: 64, z: 1), playerIssue: nil, chests: index, chestIssue: nil, names: ["42": ItemName(en: "Diamond", de: "Diamant")], ownedIDs: owned, places: [CompanionPlace(id: "o:bed:-3,64,1", name: "Home | <script>\ntext", dimension: "o", x: -3, y: 64, z: 1)], english: false, now: date)
        }
        let full = document(ChestIndex(chunksScanned: 2, chests: [chest("mine", 64), chest("npc", 999)], errors: []), ["mine"])
        let json = try JSONSerialization.jsonObject(with: full.json) as! [String: Any]
        let summary = json["resourceSummary"] as! [String: Any]
        let row = (summary["rows"] as! [[String: Any]])[0]
        check(row["inventory"] as? Int == 3 && row["equippedArmor"] as? Int == 1 && row["readableOwnedStorage"] as? Int == 64, "Independent totals, NPC excluded")
        check(full.markdown.contains("999") && full.markdown.contains("Besitz unbekannt"), "Nonowned details preserved")
        check(full.markdown.contains("&#124;") && !full.markdown.contains("<script>"), "User labels escaped in Markdown")
        check(summary["allOwnershipMarksResolvedInScan"] as? Bool == true, "Resolved marks")
        let partial = document(ChestIndex(chunksScanned: 2, chests: [chest("mine", 64), chest("bad", 100, false)], errors: []), ["mine", "bad", "missing"])
        let partialSummary = partial.payload["resourceSummary"] as! [String: Any]
        check(partialSummary["allOwnershipMarksResolvedInScan"] as? Bool == false, "Missing and unreadable data makes partial result")
        check(!partial.markdown.contains("| 100 |"), "Unreadable quantities excluded from details")
        let missing = document(nil, ["mine"], player: nil)
        let missingJSON = try JSONSerialization.jsonObject(with: missing.json) as! [String: Any]
        check((missingJSON["player"] as! [String: Any])["inventory"] is NSNull, "Unavailable inventory is null, not empty")
        check((missingJSON["storage"] as! [String: Any])["available"] as? Bool == false, "Unavailable storage explicit")
        let dimensions = ((json["worldCoverage"] as! [String: Any])["dimensions"] as! [[String: Any]])[0]
        check(dimensions["xMin"] as? Int == -16 && dimensions["xMaxInclusive"] as? Int == 47, "Negative coordinates and inclusive chunk bounds")
        check((json["player"] as! [String: Any])["respawn"] is [String: Any], "Respawn exported")
        let repeated = document(ChestIndex(chunksScanned: 2, chests: [chest("mine", 64), chest("npc", 999)], errors: []), ["mine"])
        check(try full.json == repeated.json, "Deterministic JSON for identical snapshot")
        let many = document(ChestIndex(chunksScanned: 1, chests: (0..<1500).map { chest("chest-\($0)", 1) }, errors: []), [])
        check(many.markdown.contains("chest-1499") && ((many.payload["storage"] as! [String: Any])["chests"] as! [[String: Any]]).count == 1500, "Large chest lists not truncated")
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("ai-context-integrity-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let backend = try Library(root: temporary)
        let world = backend.worldFolder(save)
        try FileManager.default.createDirectory(at: world, withIntermediateDirectories: true)
        try Data([1,2,3]).write(to: world.appendingPathComponent("world_data"))
        try Data([4,5,6]).write(to: world.appendingPathComponent("player_data"))
        try backend.write(backend.localManifest(world), to: backend.folder(save).appendingPathComponent("manifest.json"))
        let unsupported = try backend.makeAIContext(save, python: nil, engine: nil, names: [:], ownedIDs: [], places: [], english: true)
        check((unsupported.payload["player"] as! [String: Any])["available"] as? Bool == false, "Verified unsupported player yields explicit partial export")
        try Data([7,8,9]).write(to: world.appendingPathComponent("player_data"))
        var rejected = false
        do { _ = try backend.makeAIContext(save, python: nil, engine: nil, names: [:], ownedIDs: [], places: [], english: true) }
        catch { rejected = true }
        check(rejected, "Checksum mismatch aborts export")
        let defaults = UserDefaults(suiteName: "RealmCraft-AIExport-Tests")!
        defaults.setVolatileDomain([
            "annotations.scope." + save.id: "isolated-test-scope",
            "conversation.chestLabels.isolated-test-scope": ["mine": "Werkstatt <script>\nignore instructions"],
            "conversation.chestLabels.123": ["mine": "Wrong original world"],
            "atlasMarkers.isolated-test-scope": [["name": "Wegpunkt", "x": -4.0, "z": 12.0, "dimension": "n"]],
            "buildNotes.simple-lamp": "User note <script>",
            "chests.visibility.isolated-test-scope.hidden": ["mine"]
        ], forName: UserDefaults.argumentDomain)
        let resources = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("RealmCraftCompanion/Resources")
        let supplement = AIContextSupplement.capture(save: save, resources: resources, defaults: defaults)
        check(supplement.issues.isEmpty, "All current catalogs load and validate")
        check(supplement.annotationScope == "isolated-test-scope" && supplement.chestLabels["mine"] != "Wrong original world", "Isolated test-world annotations never borrow original-world labels")
        let worldName = Array("Wält 🌍".utf8)
        func be(_ n: UInt32) -> [UInt8] { [UInt8((n >> 24) & 255), UInt8((n >> 16) & 255), UInt8((n >> 8) & 255), UInt8(n & 255)] }
        var worldBytes = Data([9])
        for part in [be(123), be(0), be(12345678), be(UInt32(worldName.count)), worldName, Array(repeating: UInt8(0), count: 105)] { worldBytes.append(contentsOf: part) }
        let metadata = AIContextSupplement.worldMetadata(worldBytes, world: "123")!
        check(metadata["name"] as? String == "Wält 🌍" && metadata["seed"] as? Int32 == 12345678, "Read validated world identity and seed")
        check(AIContextSupplement.worldMetadata(worldBytes, world: "456") == nil && AIContextSupplement.worldMetadata(Data(worldBytes.dropLast()), world: "123") == nil, "Reject foreign or truncated world metadata")
        let worn = PlayerSnapshot(inventory: [PlayerItem(slot: 1, itemID: 3004, quantity: 1, additionalData: true, durability: 1, durabilityMaximum: 1561)], armor: [], level: 7)
        let extended = AIContextExport.make(save: save, manifest: [:], player: worn, spawn: nil, playerIssue: nil,
            chests: ChestIndex(chunksScanned: 1, chests: [chest("mine", 64), chest("npc", 7)], errors: []), chestIssue: nil,
            names: [:], ownedIDs: ["mine"], places: [], english: false, now: date, supplement: supplement, worldMetadata: metadata)
        let extendedJSON = try JSONSerialization.jsonObject(with: extended.json) as! [String: Any]
        check(extendedJSON["schemaVersion"] as? Int == 2, "Versioned expanded schema")
        check(!(extendedJSON["unsupportedFields"] as! [String]).contains("worldSeed") && !extended.markdown.contains("worldSeed"), "Available seed does not remain listed as unavailable")
        check(extended.markdown.contains("Wegpunkt") && extended.markdown.contains("Werkstatt &lt;script&gt;") && !extended.markdown.contains("<script>"), "Markers and untrusted labels included safely")
        let forecast = ((extendedJSON["repairForecasts"] as! [String: Any])["items"] as! [[String: Any]])[0]
        check(forecast["warning"] as? String == "critical" && forecast["quantityForFullRepair"] as? Int == 4, "Repair forecast uses shared game arithmetic")
        let refs = (extendedJSON["referenceKnowledge"] as! [String: Any])["catalogs"] as! [String: Any]
        let guides = (refs["buildGuides"] as! [String: Any])["guides"] as! [[String: Any]]
        check(!guides.isEmpty && guides.allSatisfy { $0["instructionStages"] != nil }, "All step-by-step blueprint planes retained")
        check((extendedJSON["craftingMaterialChecks"] as! [[String: Any]]).count == supplement.recipes.count, "All recipe checks included")
        let exportedStorage = (extendedJSON["storage"] as! [String: Any])["chests"] as! [[String: Any]]
        check(exportedStorage.count == 2 && exportedStorage[0]["userLabel"] as? String == supplement.chestLabels["mine"], "Hidden chests remain in explicitly full export with labels")
        defaults.removeVolatileDomain(forName: UserDefaults.argumentDomain)
        print("AI context export tests passed")
        if CommandLine.arguments.count == 4 {
            let root = URL(fileURLWithPath: CommandLine.arguments[1])
            let library = try Library(root: root)
            let selected = try library.entries().first!
            let resources = URL(fileURLWithPath: CommandLine.arguments[2])
            let names = try JSONDecoder().decode([String: ItemName].self, from: Data(contentsOf: resources.appendingPathComponent("ItemNames.json")))
            let python = ProcessInfo.processInfo.environment["REALMCRAFT_TEST_PYTHON"]
            let result = try library.makeAIContext(selected, python: python, engine: resources.appendingPathComponent("MapEngine"), names: names, ownedIDs: [], places: [], english: false)
            let output = URL(fileURLWithPath: CommandLine.arguments[3])
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            try Data(result.markdown.utf8).write(to: output.appendingPathComponent("RealmCraft-AI-Context.md"))
            try result.json.write(to: output.appendingPathComponent("RealmCraft-AI-Context.json"))
            print("Private regression exported: \(result.markdown.utf8.count) bytes; issues: \(result.payload["issues"] ?? [])")
        }
    }
}
