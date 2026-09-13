import Foundation
private final class MemoryDefaults: UserDefaults {
    var values: [String: Any] = [:]
    override func set(_ value: Any?, forKey key: String) { values[key] = value }
    override func dictionary(forKey key: String) -> [String: Any]? { values[key] as? [String: Any] }
}
@main struct BuildCoachTests {
    static func main() throws {
        let catalog = try JSONDecoder().decode(BuildCatalog.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        let guide = catalog.guides.first { $0.id == "coach_garden_arch" }!
        let defaults = MemoryDefaults()
        precondition(BuildCoach.restore(guide: guide, defaults: defaults) == 0)
        BuildCoach.save(guide: guide, step: 3, defaults: defaults)
        precondition(BuildCoach.restore(guide: guide, defaults: defaults) == 3)
        BuildCoach.save(guide: guide, step: 999, defaults: defaults)
        precondition(BuildCoach.restore(guide: guide, defaults: defaults) == guide.steps.count - 1)
        defaults.values["buildCoach.position.\(guide.id)"] = ["step": 3, "plan": "old instructions"]
        precondition(BuildCoach.restore(guide: guide, defaults: defaults) == 0)
        for en in [false,true] {
            let checkpoint = BuildCoach.checkpoint(guide: guide, step: 3, english: en)
            precondition(checkpoint.contains(guide.steps[3].value(en)))
            precondition(checkpoint.contains(en ? "not confirmed" : "nicht bestätigt"))
            precondition(BuildCoach.reference(english: en).contains(en ? "turn your head" : "Kopf drehst"))
        }
        print("PASS saved viewing position, stale-plan reset, range bounds and honest bilingual checkpoint")
    }
}
