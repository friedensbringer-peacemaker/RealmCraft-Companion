import Foundation

@main struct CompanionNavigationTests {
    static func main() throws {
        let expected = "home saves player maps ores portals metro chests conversation videos builds crafting mobs resources guide statistics tectonicus editor aiExport skills".split(separator: " ").map(String.init)
        precondition(CompanionFeature.navigationOrder.map(\.rawValue) == expected)
        precondition(CompanionFeature.navigationOrder.count == 20 && Set(CompanionFeature.navigationOrder).count == 20)
        precondition(Set(CompanionFeature.navigationOrder) == Set(CompanionFeature.allCases))
        precondition(CompanionFeature.allCases.map(\.rawValue) == "crafting ores portals metro tectonicus editor home saves maps chests resources builds videos guide player conversation mobs aiExport statistics skills".split(separator: " ").map(String.init), "Do not reassign existing keyboard shortcuts")
        let help = try HelpCatalog.load(resources: URL(fileURLWithPath: CommandLine.arguments[1]))
        precondition(CompanionFeature.allCases.allSatisfy { feature in help.contains { $0.id == feature.helpID } })
        // The help may insert task-specific subtopics, but its feature order and
        // display groups must agree with the actual sidebar. Welcome stays first.
        let categoryForGroup: [CompanionNavigationGroup: HelpCategory] = [
            .world: .world, .ai: .ai, .knowledge: .knowledge, .specialist: .specialist
        ]
        for group in CompanionNavigationGroup.allCases {
            let features = group.features.filter { $0 != .guide }
            let ids = features.map(\.helpID)
            let topics = help.filter { ids.contains($0.id) }
            precondition(topics.map(\.id) == ids, "Help feature order differs from sidebar")
            precondition(topics.allSatisfy { $0.category == categoryForGroup[group] }, "Help feature is in the wrong group")
            for english in [false, true] {
                precondition(categoryForGroup[group]!.title(english: english) == group.title(english))
            }
        }
        for en in [false, true] {
            precondition(CompanionNavigationGroup.allCases.allSatisfy { !$0.title(en).isEmpty })
            precondition(CompanionFeature.allCases.allSatisfy { !$0.title(en).isEmpty && !$0.detail(en).isEmpty })
        }
        print("Navigation: all 20 destinations, shared group order, existing shortcut assignments and help targets verified")
    }
}
