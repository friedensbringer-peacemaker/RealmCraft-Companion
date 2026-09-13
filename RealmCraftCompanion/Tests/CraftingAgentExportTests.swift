import Foundation

@main struct CraftingAgentExportTests {
    static func main() throws {
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let catalog = try CraftingCatalog.load(from: source), index = catalog.index()
        var checks = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); checks += 1 }
        let all = CraftingInstruction.all(index)
        check(all.count == catalog.recipes.count + index.acquisitions.count, "Every variant and obtaining item has an export target")
        check(Set(all.map(\.id)).count == all.count, "Unique instruction identities")
        let lava = all.first { $0.itemID == "lava_bucket" }!
        let bucket = all.first { $0.itemID == "bucket" }!
        let cod = all.first { $0.itemID == "bucket_of_cod" }!
        let salmon = all.first { $0.itemID == "bucket_of_salmon" }!
        var prefs = CraftingAgentPreferences()
        prefs.verify(lava, index: index, enabled: true, date: Date(timeIntervalSince1970: 1000))
        prefs.verify(cod, index: index, enabled: true)
        check(prefs.records[lava.id]!.isVerified(lava, index: index), "Personal confirmation")
        check(prefs.records[salmon.id] == nil, "Shared fish guide does not verify another item")
        check(prefs.selectedIDs.isEmpty, "Selection and verification are independent")
        prefs.selectVerified(index)
        check(prefs.selectedIDs == [lava.id, cod.id], "Bulk selects only currently personally verified guides")
        prefs.records[bucket.id, default: .init()].selected = true
        prefs.selectVerified(index)
        check(prefs.selectedIDs.contains(bucket.id), "Bulk preserves explicit selection")
        let multiple = Dictionary(grouping: all.filter { $0.recipe != nil }, by: \.itemID).values.first { $0.count > 1 }!
        prefs.verify(multiple[0], index: index, enabled: true)
        check(prefs.records[multiple[1].id] == nil, "Recipe variants do not share a checkmark")
        let lavaDE = try CraftingAgentSnapshot.make(index: index, preferences: prefs, instructions: [lava], english: false)
        check(lavaDE.markdown.contains("Quellblock") && lavaDE.markdown.contains("Kreativmodus") && lavaDE.markdown.contains("Besonderheiten"), "Complete obtaining steps and special cases")
        check(lavaDE.markdown.contains("https://") && lavaDE.markdown.contains("Vom Nutzer in RealmCraft verifiziert"), "Sources and personal evidence travel together")
        check(lavaDE.markdown.contains("Spielversion und Plattform wurden nicht erfasst"), "No invented platform evidence")
        let recipeEN = try CraftingAgentSnapshot.make(index: index, preferences: prefs, instructions: [bucket], desired: 4, english: true)
        check(recipeEN.markdown.contains("12 ×") && recipeEN.markdown.contains("Desired quantity: 4"), "Single export honors desired quantity")
        check(recipeEN.markdown.contains("```text\n1 · 1\n· 1 ·\n· · ·\n```"), "Markdown grid preserves rows")
        check(recipeEN.markdown.contains("not tested") && recipeEN.markdown.contains("SHA-256:"), "Original recipe provenance retained")
        let combined = try CraftingAgentSnapshot.make(index: index, preferences: prefs, english: true)
        check(combined.entries.count == 3 && combined.markdown.contains("3 ×"), "Combined export includes all selected entries, one batch per recipe")
        check(!combined.markdown.contains("12 ×"), "Combined export does not reuse a transient detail quantity")
        var modified = catalog
        var guideRows = try JSONSerialization.jsonObject(with: Data(contentsOf: source.deletingLastPathComponent().appendingPathComponent("CraftingAcquisition.json"))) as! [[String: Any]]
        let position = guideRows.firstIndex { ($0["items"] as? [String])?.contains("lava_bucket") == true }!
        var summary = guideRows[position]["summary"] as! [String: String]
        summary["de"]! += " Synthetische Änderung."
        guideRows[position]["summary"] = summary
        modified.acquisitionGuides = try JSONDecoder().decode([CraftingAcquisition].self, from: JSONSerialization.data(withJSONObject: guideRows))
        let changed = modified.index(), changedLava = CraftingInstruction.all(changed).first { $0.id == lava.id }!
        check(!prefs.records[lava.id]!.isVerified(changedLava, index: changed), "Changed source text invalidates personal confirmation")
        check(prefs.records[cod.id]!.isVerified(cod, index: changed), "Unrelated guide remains verified")
        var changedSelection = prefs
        for key in changedSelection.records.keys { changedSelection.records[key]?.selected = false }
        changedSelection.selectVerified(changed)
        check(!changedSelection.selectedIDs.contains(lava.id) && changedSelection.selectedIDs.contains(cod.id), "Bulk excludes stale confirmation")
        let stale = try CraftingAgentSnapshot.make(index: changed, preferences: prefs, english: false)
        let staleEntry = stale.entries.first { $0["id"] as? String == lava.id }!
        check(staleEntry["verificationStatus"] as? String == "needs-recheck", "Stale selected entry exported explicitly")
        check(stale.markdown.contains("erneut prüfen") && stale.markdown.contains("1970-01-01"), "Old date never means current verification")
        prefs.verify(lava, index: index, enabled: false)
        check(prefs.records[lava.id]?.verifiedAt == nil && prefs.records[lava.id]?.selected == true, "Unverify preserves export selection")
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("crafting-agent-test-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = CraftingAgentStorage(url: root.appendingPathComponent("agent.json"))
        check(try storage.load() == .init(), "First run empty")
        try storage.update { $0 = prefs }
        check(try CraftingAgentStorage(url: storage.url).load() == prefs, "Checkmarks persist across instances")
        let second = CraftingAgentStorage(url: storage.url)
        try storage.update { $0.records[lava.id]?.selected = false }
        try second.update { $0.verify(bucket, index: index, enabled: true) }
        let merged = try storage.load()
        check(merged.records[lava.id]?.selected == false && merged.records[bucket.id]?.verifiedDigest != nil, "Fresh locked mutation merges independent writers")
        try Data("broken synthetic data".utf8).write(to: storage.url)
        do { _ = try storage.load(); fatalError("Corrupt state accepted") } catch { checks += 1 }
        do { try storage.update { $0 = .init() }; fatalError("Corrupt state overwritten") } catch { checks += 1 }
        check(try String(contentsOf: storage.url, encoding: .utf8) == "broken synthetic data", "Corrupt original preserved")
        var missing = prefs
        missing.records["recipe:missing_synthetic_recipe"] = .init(selected: true)
        do { _ = try CraftingAgentSnapshot.make(index: index, preferences: missing, english: true); fatalError("Missing selection silently dropped") } catch { checks += 1 }
        let empty = try CraftingAgentSnapshot.make(index: index, preferences: .init(), english: true)
        check(empty.entries.isEmpty, "No fabricated default verification or selection")
        let base = AIContextDocument(payload: ["sentinel": 42], markdown: "# Synthetic world", videoMarkdown: "# Synthetic video")
        let attached = base.addingCrafting(combined)
        check(attached.markdown.contains(combined.markdown) && attached.videoMarkdown == base.videoMarkdown, "Composition preserves full Markdown and existing video companion")
        let json = try JSONSerialization.jsonObject(with: attached.json) as! [String: Any]
        check(json["sentinel"] as? Int == 42, "Existing payload preserved")
        let knowledge = json["craftingKnowledge"] as! [String: Any]
        check(knowledge["markdown"] as? String == combined.markdown && (knowledge["entries"] as? [[String: Any]])?.count == 3, "Markdown and JSON carry same snapshot")
        check(knowledge["userConfirmedOnly"] as? Bool == false, "Mixed evidence correctly labeled")
        check(base.addingCrafting(empty).markdown == base.markdown, "Empty selection does not add an empty section")
        let target = root.appendingPathComponent("guides.md")
        _ = try MarkdownExportPackage.write(markdown: combined.markdown, videoMarkdown: nil, to: target)
        check(try String(contentsOf: target, encoding: .utf8) == combined.markdown, "Standalone Markdown exact, untruncated")
        print("PASS: \(checks) crafting agent checks; \(all.count) exportable instructions")
    }
}
