import Foundation

struct BuildMaterialReviewRow: Identifiable {
    let id: Int
    let name: String
    let originalCount: String
    var item: String
    var quantity: String
    var included: Bool
    var query = ""
}

enum BuildMaterialHandoff {
    static func rows(guide: BuildGuide, blocks: [String: BuildBlock], index: CraftingIndex, english: Bool) -> [BuildMaterialReviewRow] {
        guide.materials.enumerated().map { offset, material in
            // Require agreement in both language names, an explicit block identity and one catalog match.
            let ids = Set(blocks.values.filter {
                CraftingCatalog.normalized($0.name.de) == CraftingCatalog.normalized(material.name.de) &&
                CraftingCatalog.normalized($0.name.en) == CraftingCatalog.normalized(material.name.en)
            }.compactMap(\.itemID))
            let candidates = ids.count == 1 ? index.catalog.items.filter { $0.itemID == ids.first } : []
            let item = candidates.count == 1 ? candidates[0].id : ""
            let de = exactCount(material.count.de), en = exactCount(material.count.en)
            let count = de != nil && de == en ? de : nil
            return .init(id: offset, name: material.name.value(english), originalCount: material.count.value(english), item: item,
                         quantity: count.map(String.init) ?? "", included: !item.isEmpty && count != nil)
        }
    }
    static func exactCount(_ text: String) -> Int? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.range(of: "^[0-9]+$", options: .regularExpression) != nil, let value = Int(text), (1...9999).contains(value) else { return nil }
        return value
    }
    static func reviewed(guide: BuildGuide, rows: [BuildMaterialReviewRow], index: CraftingIndex) throws -> CraftingBuildSource {
        guard rows.count == guide.materials.count, Set(rows.map(\.id)) == Set(guide.materials.indices) else { throw PlanningError.invalid }
        var targets: [String: Int] = [:]
        var review: [String] = []
        for row in rows.sorted(by: { $0.id < $1.id }) {
            let original = guide.materials[row.id]
            let title = original.name.de + " / " + original.name.en
            if row.included {
                guard let quantity = exactCount(row.quantity), index.items[row.item] != nil, targets[row.item, default: 0] <= 9999 - quantity else { throw PlanningError.invalid }
                targets[row.item, default: 0] += quantity
                review.append(title + " [" + original.count.de + " / " + original.count.en + "] → \(quantity) × \(row.item)")
            } else { review.append(title + " [" + original.count.de + " / " + original.count.en + "] → omitted / ausgelassen") }
        }
        let source = CraftingBuildSource(guideID: guide.id, deTitle: guide.title.de, enTitle: guide.title.en, targets: targets, review: review, sources: guide.sources.map { $0.url.absoluteString })
        guard source.valid else { throw PlanningError.invalid }
        return source
    }
}
