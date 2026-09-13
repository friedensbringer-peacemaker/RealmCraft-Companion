import Foundation

@main struct UXIntegrationTests {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let catalog = QuickFindCatalog.load(resources: root)
        var checks = 0
        func check(_ value: Bool, _ reason: String) { precondition(value, reason); checks += 1 }
        check(catalog.unavailable.isEmpty, "All four bundled catalogs load")
        check(catalog.search("  \n ", english: true).isEmpty, "Empty global query")
        check(catalog.search("zzqNoSuchSyntheticTerm", english: false).isEmpty, "No invented matches")
        check(catalog.search("lever", english: true, kinds: []).isEmpty, "No selected search categories means no results")
        for english in [false, true] {
            let all = catalog.search("lever", english: english)
            for kind in QuickFindKind.allCases {
                check(catalog.search("lever", english: english, kinds: [kind]).map(\.id) == all.filter { $0.kind == kind }.map(\.id), "Category filtering preserves exact result identity and order")
            }
            check(catalog.search("lever", english: english, kinds: [.crafting, .builds]).map(\.id) == all.filter { $0.kind == .crafting || $0.kind == .builds }.map(\.id), "Combined category filters do not broaden the search")
        }
        for english in [false, true] {
            check(catalog.search("Hebel", english: english).contains { $0.kind == .crafting && $0.item == "lever" }, "German recipe retrieval in either interface language")
            check(catalog.search("lever", english: english).contains { $0.kind == .builds }, "Build material retrieval")
            check(catalog.search("Metro", english: english).contains { $0.kind == .guide && $0.item == "metro" }, "Exact help target")
        }
        let resourcesMissing = QuickFindCatalog.load(resources: root.appendingPathComponent("not-present"))
        check(resourcesMissing.unavailable.count == 4, "Missing catalogs reported, not fabricated")
        let first = catalog.search("Metro", english: true).first!
        check(first.target.item == first.item && first.target.kind == first.kind, "Result handoff preserves identity")
        check(first.target.id != first.target.id, "Repeated activation has a fresh request ID")
        let index = catalog.crafting!, builds = catalog.builds!, guide = builds.guides.first { $0.id == "lamp" }!
        var rows = BuildMaterialHandoff.rows(guide: guide, blocks: builds.blocks, index: index, english: true)
        check(rows[0].included && rows[0].item == "lever" && rows[0].quantity == "1", "Explicit bilingual block identity is mapped")
        check(!rows.last!.included && rows.last!.item.isEmpty, "Generic building blocks are never guessed")
        for value in ["1–4", "~12", "2 stacks", "1.5", "0", "10000", "-1", "", "many"] {
            check(BuildMaterialHandoff.exactCount(value) == nil, "Ambiguous/invalid quantity \(value)")
        }
        check(BuildMaterialHandoff.exactCount(" 64 ") == 64, "Exact whole count")
        var conflict = builds.blocks
        var alternate = conflict["H"]!; alternate.itemID = 12; conflict["conflict"] = alternate
        check(!BuildMaterialHandoff.rows(guide: guide, blocks: conflict, index: index, english: true)[0].included, "Conflicting explicit mappings remain unresolved")
        let source = try BuildMaterialHandoff.reviewed(guide: guide, rows: rows, index: index)
        check(source.targets["lever"] == 1 && source.review.contains { $0.contains("omitted") }, "Review records included and excluded rows")
        var plan = CraftingPlan(catalog: CraftingPlan.fingerprint(index), targets: ["lever": 2], recipes: ["lever": CraftingPlan.supply])
        let merged = try plan.adding(source, index: index)
        check(merged.targets["lever"] == 3 && merged.recipes["lever"] == CraftingPlan.supply, "Existing target/choice preserved and accumulated")
        check(plan.targets["lever"] == 2 && plan.buildSources == nil, "Merge does not mutate original plan")
        let text = CraftingPlanCalculator.report(merged, result: CraftingPlanCalculator.calculate(merged, index: index, english: true), index: index, english: true)
        check(text.contains(guide.id) && text.contains("omitted") && text.contains(source.sources[0]), "Export preserves reviewed provenance and omissions")
        let decoded = try JSONDecoder().decode(CraftingPlan.self, from: JSONEncoder().encode(merged))
        check(decoded == merged, "Provenance survives persistence round trip")
        let legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(plan)) as! [String: Any]
        check(try JSONDecoder().decode(CraftingPlan.self, from: JSONSerialization.data(withJSONObject: legacy)).buildSources == nil, "Old plans without provenance still load")
        func rejects(_ body: () throws -> Void) {
            do { try body(); preconditionFailure("Invalid handoff accepted") } catch { checks += 1 }
        }
        plan.targets["lever"] = 9999
        rejects { _ = try plan.adding(source, index: index) }
        rows[0].quantity = "1–4"
        rejects { _ = try BuildMaterialHandoff.reviewed(guide: guide, rows: rows, index: index) }
        rows[0].quantity = "1"; rows[0].item = "nonexistent-synthetic-item"
        rejects { _ = try BuildMaterialHandoff.reviewed(guide: guide, rows: rows, index: index) }
        for i in rows.indices { rows[i].included = false }
        rejects { _ = try BuildMaterialHandoff.reviewed(guide: guide, rows: rows, index: index) }
        print("UX integration: \(checks) quick-find and material-handoff checks passed")
    }
}
