import Foundation

@main struct PortalPlansTests {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("portal-tests-" + UUID().uuidString)
        let store = PortalPlanStore(url: root.appendingPathComponent("snapshot-a.json"))
        let other = PortalPlanStore(url: root.appendingPathComponent("snapshot-b.json"))
        func make(_ d: String, _ x: Int, _ z: Int) -> PortalPlan {
            PortalPlan(id: UUID().uuidString, name: "Synthetic plan", dimension: d, x: x, z: z, referenceY: 50, createdAt: Date())
        }
        let a = make("o", -804, 404)
        precondition(a.targetX == -100.5 && a.targetZ == 50.5 && a.targetBlockX == -101 && a.targetBlockZ == 51)
        let b = make("n", -101, 51)
        precondition(b.targetX == -808 && b.targetZ == 408 && b.targetDimension == "o")
        for value in [-30_000_000, -8, 0, 8, 30_000_000] {
            let p = make("n", value, value); precondition(p.valid && p.targetX == Double(value) * 8)
        }
        precondition(!make("end", 0, 0).valid && !make("o", Int.max, 0).valid)
        let initial = try store.load(); precondition(initial.isEmpty)
        _ = try store.add(a); _ = try store.add(b)
        let saved = try store.load(), isolated = try other.load()
        precondition(saved == [a,b] && isolated.isEmpty)
        do { _ = try store.add(a); fatalError("Duplicate accepted") } catch {}
        let good: [String:Any] = ["name":"Map plan", "dimension":"o", "x":-804.0, "z":404.0, "referenceY":64.0]
        precondition(PortalPlanStore.request(good)?.targetBlockX == -101)
        for (key,value) in [("x",Double.nan as Any),("x",0.5 as Any),("x",Double.infinity as Any),("z",30_000_001.0 as Any),("name","" as Any),("dimension","end" as Any),("referenceY",256.0 as Any)] {
            var bad = good; bad[key] = value; precondition(PortalPlanStore.request(bad) == nil)
        }
        let malformed = Data("{broken".utf8); try malformed.write(to: store.url)
        do { _ = try store.add(make("n", 1, 2)); fatalError("Corrupt metadata overwritten") } catch {}
        let retained = try Data(contentsOf: store.url); precondition(retained == malformed)
        print("PASS: bidirectional conversion, half-away rounding, bounds, input validation, persistence, snapshot isolation and corrupt-file preservation")
    }
}
