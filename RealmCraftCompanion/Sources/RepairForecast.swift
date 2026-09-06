import Foundation

// Quantity arithmetic is verified against Anvil.TryApplyMaterialRepair / DurabilityCombine.
// Material choices are conservative suggestions by equipment material, not a decoded recipe table.
struct RepairForecast {
    let materialDE: String?
    let materialEN: String?
    let count: Int
    let donorMinimum: Int?

    static func forItem(_ item: PlayerItem) -> RepairForecast? {
        guard let remaining = item.durability, let maximum = item.durabilityMaximum,
              item.durabilityFraction != nil, remaining < maximum else { return nil }
        let missing = maximum - remaining
        let material: (String, String)?
        if (3000...3029).contains(item.itemID) {
            material = [("Holzbretter", "wood planks"), ("Bruchstein", "cobblestone"),
                        ("Eisenbarren", "iron ingots"), ("Goldbarren", "gold ingots"),
                        ("Diamanten", "diamonds"), ("Netheritbarren", "netherite ingots")][(item.itemID - 3000) % 6]
        } else {
            switch item.itemID {
            case 3031...3034: material = ("Leder", "leather")
            case 3035...3042: material = ("Eisenbarren", "iron ingots")
            case 3043...3046: material = ("Goldbarren", "gold ingots")
            case 3047...3050: material = ("Diamanten", "diamonds")
            case 3051...3054: material = ("Netheritbarren", "netherite ingots")
            default: material = nil
            }
        }
        if let material, maximum >= 4 {
            let perUnit = maximum / 4
            return RepairForecast(materialDE: material.0, materialEN: material.1,
                                  count: (missing + perUnit - 1) / perUnit, donorMinimum: nil)
        }
        // The native game uses float32 multiplication, floors the 12% combining bonus,
        // then caps remainingA + remainingB + bonus at maximum.
        let bonus = Int(floor(Float(maximum) * Float(0.12)))
        return RepairForecast(materialDE: nil, materialEN: nil, count: 1,
                              donorMinimum: max(1, missing - bonus))
    }
}
