import Foundation
@main struct ChestVisibilityTests {
    static func main() {
        func chest(_ ids: [Int] = [170,3270,147], y: Int = 25, dimension: String = "o", readable: Bool = true) -> ChestRecord {
            ChestRecord(id: "\(dimension):1,\(y),2", dimension: dimension, x: 1, y: y, z: 2, file: "fixture", items: ids.enumerated().map { ChestItem(slot: $0.offset, itemID: $0.element, quantity: 1, extraData: false) }, readable: readable, error: "")
        }
        let sample = chest()
        precondition(ChestVisibility.suspectedDungeon(sample))
        for other in [chest([3270]), chest([], y: 25), chest(y: 51), chest(dimension: "n"), chest(readable: false)] {
            precondition(!ChestVisibility.suspectedDungeon(other))
        }
        var state = ChestVisibility()
        precondition(!state.isHidden(sample))
        state.hideSuspected = true
        precondition(state.isHidden(sample))
        state.owned.insert(sample.id)
        precondition(!state.isHidden(sample))
        state.setHidden(true, for: [sample])
        precondition(state.isHidden(sample))
        state.owned = []
        state.setHidden(false, for: [sample])
        precondition(!state.isHidden(sample))
        let suite = "ChestVisibilityTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        state.save(world: "a", defaults: defaults)
        precondition(!ChestVisibility.load(world: "a", defaults: defaults).isHidden(sample))
        precondition(ChestVisibility.load(world: "a", defaults: defaults).hideSuspected)
        precondition(!ChestVisibility.load(world: "b", defaults: defaults).hideSuspected)
        state.setHidden(true, for: [sample, chest(dimension: "n")])
        state.save(world: "a", defaults: defaults)
        precondition(ChestVisibility.load(world: "a", defaults: defaults).hidden.count == 2)
        precondition(ChestVisibility.load(world: "b", defaults: defaults).hidden.isEmpty)
        print("PASS: heuristic guards, opt-in, ownership, manual overrides, grouped marks, persistence, world isolation")
    }
}
