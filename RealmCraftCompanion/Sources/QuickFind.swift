import Foundation

struct QuickFindMatch: Identifiable {
    let kind: QuickFindKind
    let item: String
    let title: String
    let detail: String
    var id: String { kind.rawValue + ":" + item }
    var target: QuickFindTarget { .init(kind: kind, item: item) }
}

/// Reuses each catalog's existing search rules; never reads world data or starts external work.
struct QuickFindCatalog {
    let crafting: CraftingIndex?
    let builds: BuildCatalog?
    let videos: [VideoTip]?
    let help: [HelpArticle]?
    var unavailable: [QuickFindKind] {
        [(QuickFindKind.crafting, crafting != nil), (.builds, builds != nil), (.videos, videos != nil), (.guide, help != nil)].compactMap { $0.1 ? nil : $0.0 }
    }
    static func load(resources: URL) -> QuickFindCatalog {
        let crafting = try? CraftingCatalog.load(from: resources.appendingPathComponent("CraftingCatalog.json")).index()
        let builds = try? JSONDecoder().decode(BuildCatalog.self, from: Data(contentsOf: resources.appendingPathComponent("BuildGuides.json")))
        let videos = try? VideoTip.load(from: resources.appendingPathComponent("VideoTips.json"))
        return .init(crafting: crafting, builds: (try? builds?.validate()) != nil ? builds : nil, videos: videos, help: try? HelpCatalog.load(resources: resources))
    }
    func search(_ query: String, english: Bool, kinds: Set<QuickFindKind> = Set(QuickFindKind.allCases)) -> [QuickFindMatch] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        var matches: [QuickFindMatch] = []
        matches += (crafting?.filtered(query: query, english: english) ?? []).map {
            .init(kind: .crafting, item: $0.id, title: $0.title.value(english), detail: english ? "Crafting & obtaining · RealmCraft unverified" : "Crafting & Beschaffung · RealmCraft ungeprüft")
        }
        matches += (builds?.guides.filter { $0.matches(query) } ?? []).map {
            .init(kind: .builds, item: $0.id, title: $0.title.value(english), detail: $0.summary.value(english))
        }
        matches += (videos?.filter { $0.matches(query) } ?? []).map {
            .init(kind: .videos, item: $0.id, title: $0.title.value(english), detail: $0.gameLabel + " · " + $0.coverageLabel(english))
        }
        matches += HelpCatalog.filtered(help ?? [], query: query).map {
            .init(kind: .guide, item: $0.id, title: $0.title(english), detail: $0.category.title(english: english))
        }
        return matches.filter { kinds.contains($0.kind) }
    }
}
