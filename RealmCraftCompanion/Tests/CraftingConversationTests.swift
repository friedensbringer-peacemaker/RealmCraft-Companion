import Foundation

@main struct CraftingConversationTests {
    static func main() throws {
        let index = try CraftingCatalog.load(from: URL(fileURLWithPath: CommandLine.arguments[1])).index()
        var c = CraftingConversation(index: index), checks = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); checks += 1 }
        var answer = c.answer("Was brauche ich für 65 Fackeln?", english: false)
        check(answer?.spoken.contains("17 Durchgänge") == true && answer?.spoken.contains("ungeprüft") == true, "German plural and quantity")
        answer = c.answer("Und für 64?", english: false)
        check(answer?.spoken.contains("16 Durchgänge") == true, "Explicit quantity followup")
        answer = c.answer("Was brauche ich dafür?", english: false)
        check(answer?.spoken.contains("16 Durchgänge") == true, "Generic followup retains quantity")
        answer = c.answer("What do I need for 65 torches?", english: true)
        check(answer?.spoken.contains("17 batches") == true, "English plural lookup")
        check(c.answer("Wie crafte ich eine Diamantspitzhacke?", english: false)?.spoken.contains("Diamant") == true, "Extended catalog beyond ten recipes")
        check(c.answer("Kannst du mir bitte erklären, wie ich 65 Fackeln herstelle?", english: false)?.spoken.contains("17 Durchgänge") == true, "Natural request wrappers")
        let multi = index.catalog.items.first { index.recipes[$0.id, default: []].count > 1 && $0.itemID != nil && !($0.title.en.contains("(") || $0.title.en.contains("/")) }!
        let multiReply = c.answer(multi.title.en, english: true)
        check(multiReply?.text.contains("Variant 1") == true, "Offer numbered recipe variants")
        check(c.answer("Variant 1", english: true)?.text.contains("data/minecraft/recipes/") == true, "Explicit spoken variant selects a real recipe")
        check(c.answer("Variant 9999", english: true)?.text.contains("variant number") == true, "Out-of-range variant rejected")
        check(c.answer("3157", english: true) != nil, "Numeric ID is not target quantity")
        check(c.answer("habe ich genügend Diamanten?", english: false) == nil && c.lastItem == nil, "Do not convert owned stock question to a recipe claim")
        check(c.answer("Was brauche ich für 0 Fackeln?", english: false)?.spoken.contains("1 bis 9999") == true, "Zero rejected")
        check(c.answer("Was brauche ich für -1 Fackeln?", english: false)?.spoken.contains("positive") == true, "Negative quantity rejected")
        check(c.answer("What do I need for 10000 torches?", english: true)?.spoken.contains("9999") == true, "Over-limit rejected")
        check(c.answer("How do I craft a saddle?", english: true)?.spoken.contains("does not mean") == true, "Missing recipe caveat")
        check(c.answer("Wie crafte ich eine Rakete?", english: false) == nil && c.lastItem == nil, "Unknown query clears followup")
        check(c.answer("Was brauche ich dafür?", english: false) == nil, "No stale recipe after unknown query")
        check(c.answer("oak", english: true)?.spoken.contains("Which item") == true, "Ambiguous item clarification")
        let plan = CraftingPlan(catalog: CraftingPlan.fingerprint(index), targets: ["torch": 65], recipes: ["torch": "torch"])
        check(CraftingConversation.planAnswer(plan, index: index, english: true).spoken.contains("incomplete"), "Do not read unfinished material totals")
        print("PASS: \(checks) crafting voice retrieval checks")
    }
}
