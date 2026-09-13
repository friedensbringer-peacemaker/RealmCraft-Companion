import Foundation

@main struct MetroCarryForwardTests {
    static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("metro-carry-" + UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        func snapshot(_ id: String, _ date: Double, world: String = "synthetic") throws -> MetroCarryForward.Snapshot {
            let folder = root.appendingPathComponent(id)
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            for name in ["poiOverworld", "poiTheNether"] { try Data([0,0,0,0]).write(to: folder.appendingPathComponent(name)) }
            return .init(id: id, world: world, date: Date(timeIntervalSince1970: date), worldFolder: folder, networkURL: root.appendingPathComponent(id + ".json"))
        }
        func portalData(_ height: Int) -> Data {
            var data = Data([0,0,0,1,0,0])
            for n in [0, height, 0, 0] { var value = Int32(n).bigEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
            return data
        }
        let source = try snapshot("before", 1), target = try snapshot("after", 2)
        try portalData(32).write(to: source.worldFolder.appendingPathComponent("poiTheNether"))
        try portalData(32).write(to: target.worldFolder.appendingPathComponent("poiTheNether"))
        let portal = try PortalReader.read(source.worldFolder).portals[0]
        let a = MetroStation(id: UUID().uuidString, name: "Synthetic origin", dimension: "n", x: 0, y: 32, z: 0, status: .confirmed, portalID: portal.id)
        let b = MetroStation(id: UUID().uuidString, name: "Synthetic stop", dimension: "n", x: -32, y: 32, z: 0, status: .confirmed)
        let edge = MetroEdge(id: UUID().uuidString, from: a.id, to: b.id, mode: .rail, status: .confirmed, lengthBlocks: 32, durationSeconds: 10, note: "Synthetic timing")
        let original = MetroNetworkStore.Document(stations: [a,b], lines: [], edges: [edge], originID: a.id)
        try MetroCarryForward.store(source).save(original)
        let review = try MetroCarryForward.prepare(source: source, target: target)
        precondition(review.portalChanges.isEmpty && review.proposal.stations[0].portalID == portal.id)
        precondition(review.proposal.stations.allSatisfy { $0.status == .planned } && review.proposal.edges.allSatisfy { $0.status == .planned })
        precondition(MetroNetworkStore.route(review.proposal, from: a.id, to: b.id) == nil)
        let wrongWorld = try snapshot("other", 3, world: "different")
        precondition((try? MetroCarryForward.prepare(source: source, target: wrongWorld)) == nil)
        precondition((try? MetroCarryForward.prepare(source: target, target: source)) == nil)
        try portalData(33).write(to: target.worldFolder.appendingPathComponent("poiTheNether"))
        do { try MetroCarryForward.apply(review); fatalError("Accepted stale portal evidence") } catch { }
        let changed = try MetroCarryForward.prepare(source: source, target: target)
        precondition(changed.portalChanges == [a.name] && changed.proposal.stations[0].portalID == nil)
        try MetroCarryForward.apply(changed)
        let copied = try MetroCarryForward.store(target).load()
        precondition(copied == changed.proposal && copied.edges[0].durationSeconds == 10)
        let unchanged = try MetroCarryForward.store(source).load()
        precondition(unchanged == original)
        precondition((try? MetroCarryForward.prepare(source: source, target: target)) == nil)
        let target2 = try snapshot("newer", 4)
        let preview2 = try MetroCarryForward.prepare(source: source, target: target2)
        var edited = original; edited.stations[0].name = "Updated"
        try MetroCarryForward.store(source).save(edited)
        do { try MetroCarryForward.apply(preview2); fatalError("Accepted stale network") } catch { }
        print("PASS: Metro carry-forward, unchanged/changed portal evidence, source preservation, scope and stale-write rejection")
    }
}
