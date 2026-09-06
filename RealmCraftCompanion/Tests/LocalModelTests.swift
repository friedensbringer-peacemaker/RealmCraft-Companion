import Foundation
@main struct LocalModelTests {
    static func main() throws {
        let recipes = try JSONDecoder().decode([ConversationRecipe].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("ConversationRecipes.json")))
        func check(_ action: String, _ target: String, _ expected: String) {
            let actual = ConversationLocalModel.Intent(action: action, target: target).query(original: "original", recipes: recipes, guides: [])
            precondition(actual == expected, "\(action): \(actual)")
        }
        check("recipe", "Bed", "How do I craft Bed?")
        check("craftCheck", "Bed", "Can I craft Bed?")
        check("craftCheck", "Invented laser", "original")
        check("inventory", "Diamond", "How many Diamond do I have?")
        check("inventory", "", "original")
        check("spawn", "invented coords", "spawn point")
        check("recipe", "Invented laser", "original")
        check("unsupported", "anything", "original")
        check("place", "Haus", "Where is Haus?")
        precondition(ConversationLocalModel.base.host == "127.0.0.1")
        print("10 local model routing checks passed")
    }
}
