import Foundation

/// Deterministic catalog retrieval shared by typed and recognized conversation input.
/// It supplies facts to the existing assistant; no additional inference service is used.
struct CraftingConversation {
    let index: CraftingIndex
    var lastItem: String?
    var lastQuantity = 1
    var lastRecipeID: String?
    struct Reply { let text: String; let spoken: String }
    static func tokens(_ text: String) -> [String] {
        CraftingCatalog.normalized(text).components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    }
    static let filler = Set("wie was welche welchen welches wird werden ich mir man du ein eine einen einer eines der die das den dem des fur von bitte brauche benotige braucht benotigt crafte craften crafting rezept rezepte herstellen herstelle stelle her mache machen mach baue bauen erklare erklar erklaren kannst konntest erstelle erstellen suche such zeige finde how what which do does i you a an the for of please need needs craft recipe recipes make making build explain find search show me to can could would is are it ingredients materials zutaten materialien stuck items und and davon dafur dazu noch einmal".split(separator: " ").map(String.init))
    mutating func answer(_ question: String, english: Bool) -> Reply? {
        let words = Self.tokens(question), q = words.joined(separator: " ")
        let stock = ["habe ich", "kann ich", "fehlt mir", "in meinen kisten", "do i have", "can i", "my chests", "am i missing"].contains { q.contains($0) }
        guard !stock else { lastItem = nil; return nil }
        if question.range(of: #"-\s*\d"#, options: .regularExpression) != nil {
            let text = english ? "Use a positive quantity between 1 and 9999." : "Verwende eine positive Menge von 1 bis 9999."
            return Reply(text: text, spoken: text)
        }
        let numberWords = ["ein": 1, "zwei": 2, "drei": 3, "vier": 4, "acht": 8, "zehn": 10, "one": 1, "two": 2, "three": 3, "four": 4, "eight": 8, "ten": 10]
        let numeric = words.compactMap(Int.init)
        let variantRequest = words.count == 2 && ["variante", "variant"].contains(words[0]) && numeric.count == 1
        let bareID = words.count == 1 && numeric.count == 1
        let quantity = bareID ? 1 : (numeric.first ?? words.compactMap { numberWords[$0] }.first ?? 1)
        let terms = words.filter { !Self.filler.contains($0) && numberWords[$0] == nil && (bareID || Int($0) == nil) }
        let generic = ["was brauche ich dafur", "was brauche ich dazu", "what do i need for that", "what do i need", "wie mache ich das", "how do i make it"].contains(q)
            || (terms.isEmpty && numeric.count == 1 && (q.hasPrefix("und ") || q.hasPrefix("and ")))
        let matches: [CraftingItem]
        if (generic || variantRequest), let lastItem, let item = index.items[lastItem] { matches = [item] }
        else if terms.isEmpty { return nil }
        else {
            let search = terms.joined(separator: " ")
            let candidates = index.filtered(query: search, english: english)
            var exactQueries = [search]
            if search.count >= 5 {
                if search.hasSuffix("en") || search.hasSuffix("es") { exactQueries.append(String(search.dropLast(2))) }
                if search.hasSuffix("n") || search.hasSuffix("s") { exactQueries.append(String(search.dropLast())) }
            }
            let exact = candidates.filter { item in
                [Self.tokens(item.title.de).joined(separator: " "), Self.tokens(item.title.en).joined(separator: " "), item.itemID.map(String.init) ?? ""].contains { exactQueries.contains($0) }
            }
            matches = exact.isEmpty ? candidates : exact
        }
        guard !matches.isEmpty else { lastItem = nil; return nil }
        func reply(_ value: String) -> Reply { Reply(text: value, spoken: value) }
        guard matches.count == 1 else {
            lastItem = nil
            return reply((english ? "Which item? " : "Welchen Gegenstand meinst du? ") + matches.prefix(8).map { $0.title.value(english) }.joined(separator: ", ") + (matches.count > 8 ? (english ? ". Refine the search in Crafting / Recipes." : ". Grenze die Suche unter Crafting / Rezepte ein.") : "."))
        }
        let item = matches[0], desired = variantRequest || (generic && numeric.isEmpty) ? lastQuantity : quantity
        guard (1...9999).contains(desired), numeric.count <= 1 else {
            return reply(english ? "Use one target quantity between 1 and 9999; numeric catalog IDs are searched on their own." : "Verwende eine Zielmenge von 1 bis 9999; numerische Katalog-IDs bitte einzeln suchen.")
        }
        if item.id != lastItem { lastRecipeID = nil }
        lastItem = item.id; lastQuantity = desired
        let recipes = index.recipes[item.id, default: []].sorted { $0.id < $1.id }
        let caveat = english ? "Minecraft comparison, unverified in RealmCraft VR. " : "Minecraft-Vergleich, in RealmCraft VR ungeprüft. "
        guard !recipes.isEmpty else { return reply(item.title.value(english) + ": " + (english ? "No recipe documented here. This does not mean it cannot be crafted. Check in the game." : "Hier ist kein Rezept dokumentiert. Das bedeutet nicht, dass der Gegenstand nicht herstellbar ist. Im Spiel prüfen.")) }
        if variantRequest {
            guard let number = numeric.first, (1...recipes.count).contains(number) else {
                return reply(english ? "Choose a variant number from 1 to \(recipes.count)." : "Wähle eine Variantennummer von 1 bis \(recipes.count).")
            }
            lastRecipeID = recipes[number - 1].id
        }
        guard let recipe = recipes.count == 1 ? recipes.first : recipes.first(where: { $0.id == lastRecipeID }) else {
            let options = recipes.prefix(6).enumerated().map { offset, recipe in
                "\(offset + 1). \(recipe.station.title(english)): " + recipe.ingredients.map { index.ingredientName($0, english: english) }.joined(separator: " + ")
            }.joined(separator: "\n")
            let text = caveat + item.title.value(english) + (english ? " has \(recipes.count) reference variants. Reply ‘Variant 1’ or select a route under Crafting / Recipes.\n" : " hat \(recipes.count) Rezeptvarianten. Antworte ‚Variante 1‘ oder wähle einen Weg unter Crafting / Rezepte.\n") + options + (recipes.count > 6 ? (english ? "\nFurther variants in Crafting / Recipes." : "\nWeitere Varianten unter Crafting / Rezepte.") : "")
            return Reply(text: text, spoken: String(text.prefix(1800)))
        }
        let batches = recipe.batches(for: desired)
        let ingredients = recipe.ingredients.map { ingredient -> String in
            let names = ingredient.options.prefix(4).map { index.items[$0]?.title.value(english) ?? $0 }
            let label = names.joined(separator: english ? " or " : " oder ") + (ingredient.options.count > 4 ? (english ? " or another listed alternative" : " oder eine weitere aufgeführte Alternative") : "")
            return "\(ingredient.count * batches) " + label
        }.joined(separator: "; ")
        let spoken = caveat + item.title.value(english) + ". " + (english ? "For \(desired) items: \(batches) batches at \(recipe.station.title(true)), yielding \(recipe.produced(for: desired)). Direct ingredients: " : "Für \(desired) Stück: \(batches) Durchgänge an \(recipe.station.title(false)), Ergebnis \(recipe.produced(for: desired)) Stück. Direkte Zutaten: ") + ingredients + ". "
            + (english ? "Alternatives are choices, not additional quantities. Use Material plan for intermediate products. " : "Alternativen sind Wahlmöglichkeiten, keine zusätzlichen Mengen. Für Zwischenprodukte verwende den Materialplan. ")
            + (recipe.station.usesFuel ? (english ? "Additional fuel is required; amount unverified." : "Zusätzlicher Brennstoff ist nötig; Menge ungeprüft.") : "")
        return Reply(text: index.summary(recipe, desired: desired, english: english), spoken: spoken)
    }
    static func planAnswer(_ plan: CraftingPlan, index: CraftingIndex, english: Bool) -> Reply {
        let result = CraftingPlanCalculator.calculate(plan, index: index, english: english)
        let text = CraftingPlanCalculator.report(plan, result: result, index: index, english: english)
        guard result.complete else { return Reply(text: text, spoken: english ? "The material plan is incomplete. Resolve recipe choices or issues under Crafting / Recipes first." : "Der Materialplan ist unvollständig. Kläre zuerst Rezeptauswahlen oder Probleme unter Crafting / Rezepte.") }
        let materials = result.materials.keys.sorted().prefix(12).map { "\(result.materials[$0]!) " + (index.items[$0]?.title.value(english) ?? $0) }.joined(separator: "; ")
        let spoken = (english ? "Saved material plan. Minecraft comparison, unverified in RealmCraft VR. Supply: " : "Gespeicherter Materialplan. Minecraft-Vergleich, in RealmCraft VR ungeprüft. Bereitstellen: ") + (plan.targets.isEmpty ? (english ? "No targets yet." : "Noch keine Ziele.") : materials)
            + (result.materials.count > 12 ? (english ? ". More entries are shown in the written answer." : ". Weitere Einträge stehen in der Textantwort.") : ".")
            + (english ? " Stock, fuel and station construction are excluded." : " Vorräte, Brennstoff und Stationsbau sind nicht enthalten.")
        return Reply(text: text, spoken: spoken)
    }
}
