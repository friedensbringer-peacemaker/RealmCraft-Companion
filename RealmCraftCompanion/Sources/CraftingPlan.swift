import Foundation
import CryptoKit
import Darwin

struct CraftingBuildSource: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    let guideID: String
    let deTitle: String
    let enTitle: String
    let targets: [String: Int]
    let review: [String]
    let sources: [String]
    var date = Date()
    var valid: Bool {
        !id.isEmpty && guideID.count <= 160 && !guideID.isEmpty && deTitle.count <= 500 && enTitle.count <= 500 &&
        !targets.isEmpty && targets.count <= 50 && targets.values.allSatisfy { (1...9999).contains($0) } &&
        review.count <= 200 && review.allSatisfy { $0.count <= 4096 } &&
        sources.count <= 40 && sources.allSatisfy { $0.count <= 2048 && URL(string: $0)?.scheme == "https" }
    }
}

struct CraftingPlan: Codable, Equatable {
    var schema = 1
    var catalog: String
    var targets: [String: Int] = [:]
    var recursive = false
    var recipes: [String: String] = [:]
    var alternatives: [String: String] = [:]
    var buildSources: [CraftingBuildSource]? = nil
    static let supply = "@supply"
    static func fingerprint(_ index: CraftingIndex) -> String {
        let data = try? JSONSerialization.data(withJSONObject: [
            "version": index.catalog.referenceVersion,
            "source": index.catalog.sourceSHA1,
            "recipes": index.catalog.recipes.sorted { $0.id < $1.id }.map { recipe -> [String: Any] in
                ["id": recipe.id, "output": recipe.output, "count": recipe.count,
                 "station": recipe.station.rawValue, "source": recipe.sourceSHA256,
                 "ingredients": recipe.ingredients.map { ["options": $0.options, "count": $0.count] as [String: Any] }]
            },
            "items": index.catalog.items.map(\.id).sorted()
        ], options: [.sortedKeys])
        return SHA256.hash(data: data ?? Data()).map { String(format: "%02x", $0) }.joined()
    }
    func validate() throws {
        guard schema == 1, targets.count <= 50, targets.values.allSatisfy({ (1...9999).contains($0) }),
              recipes.count <= 2048, alternatives.count <= 8192,
              (buildSources?.count ?? 0) <= 50, (buildSources ?? []).allSatisfy(\.valid) else { throw PlanningError.invalid }
    }
    func adding(_ source: CraftingBuildSource, index: CraftingIndex) throws -> CraftingPlan {
        try validate()
        guard source.valid, catalog == Self.fingerprint(index), source.targets.keys.allSatisfy({ index.items[$0] != nil }) else { throw PlanningError.invalid }
        var copy = self
        for (item, quantity) in source.targets {
            let old = copy.targets[item, default: 0]
            guard old <= 9999 - quantity else { throw PlanningError.invalid }
            copy.targets[item] = old + quantity
        }
        copy.buildSources = (copy.buildSources ?? []) + [source]
        try copy.validate()
        return copy
    }
}

struct CraftingPlanChoice: Identifiable {
    let id: String
    let item: String
    let ingredient: Int?
    let options: [String]
    let selected: String
}
struct CraftingPlanStep {
    let recipe: CraftingRecipe
    let required: Int
    let batches: Int
    var produced: Int { batches * recipe.count }
}
struct CraftingPlanResult {
    var choices: [CraftingPlanChoice] = []
    var issues: [String] = []
    var materials: [String: Int] = [:]
    var steps: [CraftingPlanStep] = []
    var complete: Bool { issues.isEmpty && choices.allSatisfy { !$0.selected.isEmpty } }
}

/// Resolve choices first; aggregate every consumer before rounding a shared intermediate.
/// No stock, fuel quantity, station construction or RealmCraft compatibility is inferred.
enum CraftingPlanCalculator {
    static func calculate(_ plan: CraftingPlan, index: CraftingIndex, english: Bool) -> CraftingPlanResult {
        var result = CraftingPlanResult()
        func issue(_ de: String, _ en: String) { result.issues.append(english ? en : de) }
        guard (try? plan.validate()) != nil else {
            issue("Ungültiger Plan (maximal 50 Ziele, je 1–9999 Stück).", "Invalid plan (up to 50 targets, 1–9999 items each).")
            return result
        }
        guard plan.catalog == CraftingPlan.fingerprint(index) else {
            issue("Der Rezeptkatalog wurde geändert. Auswahl zurücksetzen und erneut prüfen.", "The recipe catalog changed. Reset choices and review the plan.")
            return result
        }
        var selected: [String: CraftingRecipe] = [:]
        var edges: [String: [(String, Int)]] = [:]
        var visited = Set<String>(), active = Set<String>(), order: [String] = []
        func visit(_ item: String, depth: Int) {
            guard depth <= 64, visited.count < 512 else {
                issue("Plan zu komplex (maximal 512 Gegenstände / 64 Ebenen).", "Plan too complex (512 items / 64 levels maximum).")
                return
            }
            if active.contains(item) {
                let name = index.items[item]?.title.value(english) ?? item
                issue("Rezeptkreislauf bei \(name). Wähle dort ‚Bereitstellen‘ oder einen anderen Herstellungsweg.", "Recipe cycle at \(name). Choose Supply or a different recipe there.")
                return
            }
            guard !visited.contains(item) else { return }
            guard index.items[item] != nil else {
                issue("Unbekannter Gegenstand: \(item). Ziel entfernen und neu auswählen.", "Unknown item: \(item). Remove and select the target again.")
                return
            }
            visited.insert(item)
            let variants = index.recipes[item, default: []].sorted { $0.id < $1.id }
            if !variants.isEmpty {
                let choice = plan.recipes[item] ?? (variants.count == 1 ? variants[0].id : "")
                let valid = choice == CraftingPlan.supply || variants.contains { $0.id == choice }
                result.choices.append(.init(id: item, item: item, ingredient: nil,
                                            options: variants.map(\.id) + [CraftingPlan.supply], selected: valid ? choice : ""))
                if let recipe = variants.first(where: { $0.id == choice }) {
                    selected[item] = recipe
                    active.insert(item)
                    for (offset, ingredient) in recipe.ingredients.enumerated() {
                        let key = recipe.id + "#" + String(offset)
                        let alternative = plan.alternatives[key] ?? (ingredient.options.count == 1 ? ingredient.options[0] : "")
                        let valid = ingredient.options.contains(alternative)
                        if ingredient.options.count > 1 || !valid {
                            result.choices.append(.init(id: key, item: item, ingredient: offset,
                                                        options: ingredient.options, selected: valid ? alternative : ""))
                        }
                        if valid {
                            edges[item, default: []].append((alternative, ingredient.count))
                            if plan.recursive { visit(alternative, depth: depth + 1) }
                        }
                    }
                    active.remove(item)
                }
            }
            order.append(item)
        }
        for item in plan.targets.keys.sorted() { visit(item, depth: 0) }
        guard result.complete else { return result }
        let limit = 1_000_000_000
        func add(_ amount: Int, to item: String, in values: inout [String: Int]) -> Bool {
            let old = values[item, default: 0]
            guard amount >= 0, amount <= limit, old <= limit - amount else { return false }
            values[item] = old + amount
            return true
        }
        var demand = plan.targets
        var valid = true
        for item in (plan.recursive ? Array(order.reversed()) : plan.targets.keys.sorted()) {
            let required = demand[item, default: 0]
            if let recipe = selected[item] {
                let batches = (required - 1) / recipe.count + 1
                guard batches <= limit / recipe.count else { valid = false; break }
                result.steps.append(.init(recipe: recipe, required: required, batches: batches))
                for (ingredient, count) in edges[item, default: []] {
                    guard batches <= limit / count else { valid = false; break }
                    if plan.recursive { valid = add(batches * count, to: ingredient, in: &demand) && valid }
                    else { valid = add(batches * count, to: ingredient, in: &result.materials) && valid }
                }
            } else {
                valid = add(required, to: item, in: &result.materials) && valid
            }
        }
        if !valid {
            result.materials = [:]; result.steps = []
            issue("Mengenlimit überschritten (1 Milliarde). Plan verkleinern.", "Quantity limit exceeded (1 billion). Reduce the plan.")
        }
        // Consumer-first calculation, ingredient-first instructions.
        if plan.recursive { result.steps.reverse() }
        return result
    }

    static func report(_ plan: CraftingPlan, result: CraftingPlanResult, index: CraftingIndex, english: Bool) -> String {
        func name(_ id: String) -> String { index.items[id]?.title.value(english) ?? id }
        var lines = [english ? "Material plan" : "Materialplan",
                     english ? "Minecraft comparison; unverified in RealmCraft VR. No personal stock checked. Fuel and station construction excluded."
                     : "Minecraft-Vergleich; in RealmCraft VR ungeprüft. Kein persönlicher Vorrat geprüft. Brennstoff und Stationsbau nicht enthalten.",
                     (plan.recursive ? (english ? "Recursive" : "Rekursiv") : (english ? "Direct ingredients" : "Direkte Zutaten")),
                     english ? "Targets:" : "Ziele:"]
        lines += plan.targets.keys.sorted().map { "\(plan.targets[$0]!) × \(name($0))" }
        if let sources = plan.buildSources, !sources.isEmpty {
            lines.append(english ? "Reviewed build imports (historical quantities, not current stock or verified game recipes):" : "Geprüfte Bauplan-Übernahmen (historische Mengen, kein Bestand oder bestätigtes Spielrezept):")
            for source in sources {
                lines.append((english ? source.enTitle : source.deTitle) + " · " + source.guideID)
                lines += source.review
                lines += source.sources
            }
        }
        guard result.complete else { return (lines + [english ? "INCOMPLETE — resolve choices and issues first." : "UNVOLLSTÄNDIG — erst Auswahlen und Probleme klären."] + result.issues).joined(separator: "\n") }
        lines.append(english ? "Supply (not further expanded; not necessarily raw materials):" : "Bereitstellen (nicht weiter aufgelöst; nicht zwingend Grundstoffe):")
        lines += result.materials.keys.sorted().map { "\(result.materials[$0]!) × \(name($0))" }
        lines.append(english ? "Crafting steps:" : "Herstellungsschritte:")
        for step in result.steps {
            lines.append("\(name(step.recipe.output)) · \(step.batches) × \(step.recipe.station.title(english)) → \(step.produced) (\(english ? "extra" : "übrig"): \(step.produced - step.required))")
            for (offset, ingredient) in step.recipe.ingredients.enumerated() {
                let option = plan.alternatives[step.recipe.id + "#" + String(offset)] ?? ingredient.options[0]
                lines.append("  \(step.batches * ingredient.count) × \(name(option))")
            }
            lines.append("  \(step.recipe.id) · \(step.recipe.sourcePath) · SHA-256 \(step.recipe.sourceSHA256)")
        }
        lines.append("\(index.catalog.referenceVersion) · \(index.catalog.sourceURL.absoluteString) · SHA-1 \(index.catalog.sourceSHA1)")
        return lines.joined(separator: "\n")
    }
}

struct CraftingPlanStorage {
    let url: URL
    let empty: CraftingPlan
    static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RealmCraftLibrary/Crafting/material-plan.json")
    }
    func load() throws -> CraftingPlan {
        let value = try PlanningStore(url: url, empty: empty).load()
        try value.validate()
        return value
    }
    func save(_ value: CraftingPlan, replacing expected: CraftingPlan) throws {
        try value.validate()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fd = open(url.appendingPathExtension("lock").path, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw CocoaError(.fileWriteNoPermission) }
        defer { close(fd) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw PlanningError.changed }
        defer { flock(fd, LOCK_UN) }
        try PlanningStore(url: url, empty: empty).save(value, replacing: expected)
    }
}
