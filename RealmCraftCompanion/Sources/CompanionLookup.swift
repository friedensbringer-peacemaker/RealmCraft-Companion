import SwiftUI

enum QuickFindKind: String, CaseIterable, Codable {
    case crafting, builds, videos, guide
    func title(_ english: Bool) -> String {
        switch self {
        case .crafting: return english ? "Recipes" : "Rezepte"
        case .builds: return english ? "Build guides" : "Bauanleitungen"
        case .videos: return english ? "Videos & tips" : "Videos & Tipps"
        case .guide: return english ? "Help" : "Hilfe"
        }
    }
    var icon: String {
        switch self { case .crafting: return "square.grid.3x3"; case .builds: return "hammer"; case .videos: return "play.rectangle"; case .guide: return "questionmark.circle" }
    }
}
struct QuickFindTarget: Equatable, Identifiable {
    let kind: QuickFindKind
    let item: String
    var id = UUID()
}
private struct CompanionLookupKey: EnvironmentKey { static let defaultValue: QuickFindTarget? = nil }
extension EnvironmentValues {
    var companionLookup: QuickFindTarget? {
        get { self[CompanionLookupKey.self] }
        set { self[CompanionLookupKey.self] = newValue }
    }
}
