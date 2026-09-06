import Foundation
@main struct RepairForecastTests {
    static func main() {
        func item(_ id: Int = 3004, _ remaining: Int, maximum: Int? = nil) -> PlayerItem {
            PlayerItem(slot: 1, itemID: id, quantity: 1, additionalData: true,
                       durability: remaining, durabilityMaximum: maximum ?? DurabilityCatalog.maxima[id])
        }
        precondition(item(3004, 408).durabilityWarning == .caution)
        precondition(item(3004, 100).durabilityWarning == .critical)
        precondition(item(3002, 125).durabilityWarning == .normal) // exactly 50%
        precondition(item(3002, 124).durabilityWarning == .caution)
        precondition(item(3002, 50).durabilityWarning == .caution) // exactly 20%
        precondition(item(3002, 49).durabilityWarning == .critical)
        precondition(item(3002, 0).durabilityWarning == .critical)
        precondition(item(60000, 10).durabilityWarning == .unknown)
        precondition(item(3002, 251).durabilityWarning == .unknown)
        let pickaxe = RepairForecast.forItem(item(3004, 408))!
        precondition(pickaxe.count == 3 && pickaxe.materialDE == "Diamanten")
        precondition(RepairForecast.forItem(item(3047, 333))?.count == 1)
        // Integer division: 1561 / 4 = 390, four materials leave one point at zero.
        precondition(RepairForecast.forItem(item(3004, 0))?.count == 5)
        precondition(RepairForecast.forItem(item(3004, 1171))?.count == 1)
        precondition(RepairForecast.forItem(item(3004, 1170))?.count == 2)
        precondition(RepairForecast.forItem(item(3004, 1561)) == nil)
        precondition(RepairForecast.forItem(item(3004, 1562)) == nil)
        precondition(RepairForecast.forItem(item(60000, 1)) == nil)
        let bow = RepairForecast.forItem(item(3069, 100))!
        precondition(bow.count == 1 && bow.materialDE == nil && bow.donorMinimum == 238)
        precondition(RepairForecast.forItem(item(3069, 383))?.donorMinimum == 1)
        print("PASS: strict 50%/20% boundaries, material rounding, full/unknown/invalid state, donor forecast")
    }
}
