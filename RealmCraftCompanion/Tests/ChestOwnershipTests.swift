import Foundation
@main struct ChestOwnershipTests {
    static func main() {
        func check(_ value: Bool, _ message: String) { if !value { fatalError(message) } }
        let existing: Set<String> = ["o:1,64,2", "n:1,64,2"]
        let added = ChestOwnership.apply(["world":"world-a", "action":"add", "ids":["o:-1,0,2", "o:-1,255,2", "o:-1,0,2"]], world:"world-a", existing:existing)!
        check(added.ids.count == 4 && added.changed == 2 && added.ids.contains("n:1,64,2"), "Delta preserves other locations and dimensions")
        let removed = ChestOwnership.apply(["world":"world-a", "action":"remove", "ids":["o:-1,0,2"]], world:"world-a", existing:added.ids)!
        check(removed.ids.count == 3 && removed.changed == 1, "Remove only specified chest")
        for id in ["o:1,256,2", "o:1,-1,2", "o:01,64,2", "o:1,64,2:extra", "q:1,64,2", "o:30000001,64,2", "o:NaN,64,2"] { check(!ChestOwnership.validID(id), "Reject malformed ID") }
        check(ChestOwnership.apply(["world":"world-b", "action":"add", "ids":["o:1,64,2"]], world:"world-a", existing:existing) == nil, "Reject different world")
        check(ChestOwnership.apply(["world":"world-a", "action":"replace", "ids":["o:1,64,2"]], world:"world-a", existing:existing) == nil, "No replace-all operation")
        check(ChestOwnership.apply(["world":"world-a", "action":"add", "ids":["o:1,64,2", "invalid"]], world:"world-a", existing:existing) == nil, "Malformed batch rejected atomically")
        print("Chest ownership tests passed")
    }
}
