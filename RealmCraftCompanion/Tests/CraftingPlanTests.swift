import Foundation
import Darwin

@main struct CraftingPlanTests {
    static func main() throws {
        var checks = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); checks += 1 }
        let real = try CraftingCatalog.load(from: URL(fileURLWithPath: CommandLine.arguments[1])).index()
        func recipe(_ id: String, _ output: String, _ count: Int, _ ingredients: [CraftingIngredient]) -> CraftingRecipe {
            .init(id: id, output: output, count: count, station: .table, kind: "crafting_shapeless", ingredients: ingredients, grid: [], sourcePath: "data/minecraft/recipes/\(id).json", sourceSHA256: String(repeating: "a", count: 64), corroboration: nil)
        }
        let items = ["a", "b", "wood", "plank", "alternative", "missing", "loop", "choice", "huge"]
            .map { CraftingItem(id: $0, itemID: nil, title: .init(de: $0, en: $0)) }
        let recipes = [
            recipe("a", "a", 1, [.init(options: ["plank"], count: 1)]),
            recipe("b", "b", 1, [.init(options: ["plank"], count: 1)]),
            recipe("plank", "plank", 4, [.init(options: ["wood"], count: 1)]),
            recipe("loop", "loop", 1, [.init(options: ["loop"], count: 1)]),
            recipe("choice1", "choice", 1, [.init(options: ["wood", "alternative"], count: 1)]),
            recipe("choice2", "choice", 2, [.init(options: ["missing"], count: 1)]),
            recipe("huge", "huge", 1, [.init(options: ["a"], count: 9)])
        ]
        let catalog = CraftingCatalog(schemaVersion: 1, referenceVersion: "synthetic", checked: "2026-09-12", sourceURL: URL(string: "https://example.org/fixture")!, sourceSHA1: String(repeating: "a", count: 40), items: items, recipes: recipes)
        try catalog.validate()
        let index = catalog.index()
        var plan = CraftingPlan(catalog: CraftingPlan.fingerprint(index), targets: ["a": 1, "b": 1], recursive: true)
        func result(_ value: CraftingPlan) -> CraftingPlanResult { CraftingPlanCalculator.calculate(value, index: index, english: true) }
        var r = result(plan)
        check(r.complete && r.materials == ["wood": 1], "Shared intermediate rounds once, not per target")
        check(r.steps.first?.recipe.id == "plank" && r.steps.first?.produced == 4 && r.steps.first?.required == 2, "Ingredient-first instructions and shared surplus")
        plan.targets["plank"] = 3
        r = result(plan)
        check(r.materials == ["wood": 2] && r.steps.first?.required == 5, "Target which is also intermediate aggregates before rounding")
        plan.recursive = false
        r = result(plan)
        check(r.materials == ["plank": 2, "wood": 1], "Direct mode does not recursively consume intermediate targets")
        plan.recursive = true; plan.recipes["plank"] = CraftingPlan.supply
        check(result(plan).materials == ["plank": 5], "Explicit supply breaks expansion and aggregates target")
        plan.targets = ["missing": 4]; plan.recipes = [:]
        check(result(plan).complete && result(plan).materials == ["missing": 4], "Missing recipe is supplied, not uncraftable")
        plan.targets = ["choice": 2]
        r = result(plan)
        check(!r.complete && r.materials.isEmpty && r.choices.first?.selected == "", "Ambiguous recipe requires explicit selection")
        plan.recipes["choice"] = "choice1"
        check(!result(plan).complete && result(plan).choices.contains { $0.id == "choice1#0" && $0.selected.isEmpty }, "Alternative selection required")
        plan.alternatives["choice1#0"] = "alternative"
        check(result(plan).materials == ["alternative": 2], "Only chosen alternative counted")
        plan.alternatives["choice1#0"] = "invalid"
        check(!result(plan).complete, "Invalid stored alternative does not silently substitute")
        plan.recipes["choice"] = "choice2"
        check(result(plan).materials == ["missing": 1], "Inactive alternative does not block different recipe")
        plan.recipes["choice"] = "removed"
        check(!result(plan).complete, "Stale recipe choice remains unresolved")
        plan.targets = ["loop": 1]; plan.recipes = [:]
        r = result(plan)
        check(!r.complete && r.materials.isEmpty && r.steps.isEmpty && r.issues.contains { $0.contains("cycle") }, "Cycles withhold totals")
        plan.recipes["loop"] = CraftingPlan.supply
        check(result(plan).materials == ["loop": 1], "User can resolve cycle by supply")
        plan.targets = ["huge": 9999]; plan.recipes = [:]
        r = result(plan)
        check(r.complete && r.steps.first?.required == 89991 && r.materials == ["wood": 22498], "Derived quantities above UI limit must not clamp")
        plan.targets = ["unknown": 1]
        check(!result(plan).complete, "Missing catalog target is explicit")
        plan.targets = ["a": Int.max]
        check(!result(plan).complete, "External overflow rejected before arithmetic")
        plan.targets = ["a": 0]
        check(!result(plan).complete, "Zero quantity rejected")
        plan.targets = [:]
        check(result(plan).complete && result(plan).materials.isEmpty, "Empty plan")
        plan.targets = ["a": 1]; plan.alternatives = ["a#0": "invalid"]
        check(!result(plan).complete && result(plan).materials.isEmpty, "Invalid stored single-option ingredient cannot yield false complete totals")
        plan.alternatives = [:]
        let chainItems = (0...70).map { CraftingItem(id: "node\($0)", itemID: nil, title: .init(de: "Node \($0)", en: "Node \($0)")) }
        func chain(_ count: Int) -> CraftingIndex {
            let recipes = (0..<count).map { recipe("node\($0)", "node\($0)", 1, [.init(options: ["node\($0 + 1)"], count: 9)]) }
            return CraftingCatalog(schemaVersion: 1, referenceVersion: "synthetic", checked: "2026-09-12", sourceURL: catalog.sourceURL, sourceSHA1: catalog.sourceSHA1, items: chainItems, recipes: recipes).index()
        }
        let overflow = chain(12)
        var bounded = CraftingPlan(catalog: CraftingPlan.fingerprint(overflow), targets: ["node0": 9999], recursive: true)
        let excess = CraftingPlanCalculator.calculate(bounded, index: overflow, english: true)
        check(!excess.complete && excess.steps.isEmpty && excess.materials.isEmpty && excess.issues.contains { $0.contains("Quantity limit") }, "Exponential demand fails closed without overflow or partial totals")
        let deep = chain(70); bounded.catalog = CraftingPlan.fingerprint(deep)
        check(!CraftingPlanCalculator.calculate(bounded, index: deep, english: true).complete, "Deep recursion bounded")
        let changed = CraftingCatalog(schemaVersion: 1, referenceVersion: catalog.referenceVersion, checked: catalog.checked, sourceURL: catalog.sourceURL, sourceSHA1: catalog.sourceSHA1, items: items, recipes: [recipe("a", "a", 2, [.init(options: ["plank"], count: 1)])] + Array(recipes.dropFirst())).index()
        check(CraftingPlan.fingerprint(changed) != CraftingPlan.fingerprint(index), "Fingerprint includes actual recipe semantics, not just declared source hashes")
        plan.catalog = "stale"
        check(!result(plan).complete, "Catalog fingerprint mismatch blocks totals")
        var torch = CraftingPlan(catalog: CraftingPlan.fingerprint(real), targets: ["torch": 65], recipes: ["torch": "torch"], alternatives: ["torch#0": "coal"])
        let torchRecipe = real.recipes["torch"]!.first { $0.id == "torch" }!
        torch.alternatives = [:]
        for (offset, ingredient) in torchRecipe.ingredients.enumerated() where ingredient.options.count > 1 { torch.alternatives["torch#\(offset)"] = "coal" }
        r = CraftingPlanCalculator.calculate(torch, index: real, english: false)
        check(r.complete && r.materials == ["coal": 17, "stick": 17] && r.steps.first?.produced == 68, "Real catalog torch integration")
        let report = CraftingPlanCalculator.report(torch, result: r, index: real, english: false)
        check(report.contains("ungeprüft") && report.contains("Brennstoff") && report.contains("SHA-256") && report.contains("17 ×"), "Export preserves choices, quantities, scope and provenance")
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("crafting-plan-tests-\(UUID().uuidString)")
        let empty = CraftingPlan(catalog: CraftingPlan.fingerprint(index))
        let storage = CraftingPlanStorage(url: temp.appendingPathComponent("plan.json"), empty: empty)
        check(try storage.load() == empty, "Missing local plan is empty")
        var saved = empty; saved.targets = ["a": 3]
        try storage.save(saved, replacing: empty)
        check(try storage.load() == saved, "Plan round trip")
        do { try storage.save(empty, replacing: empty); fatalError("Lost concurrent write") } catch { checks += 1 }
        let fd = open(storage.url.appendingPathExtension("lock").path, O_RDWR)
        precondition(fd >= 0 && flock(fd, LOCK_EX | LOCK_NB) == 0)
        do { try storage.save(empty, replacing: saved); fatalError("Ignored lock") } catch { checks += 1 }
        flock(fd, LOCK_UN); close(fd)
        try Data("broken fixture".utf8).write(to: storage.url)
        do { _ = try storage.load(); fatalError("Corrupt plan replaced") } catch { checks += 1 }
        do { try storage.save(empty, replacing: saved); fatalError("Corrupt plan overwritten") } catch { checks += 1 }
        print("PASS: \(checks) crafting planner checks; synthetic persistence fixture: \(temp.path)")
    }
}
