import Foundation

@main struct MetroAutoPlannerTests {
    static func main() throws {
        let origin = MetroStation(id: UUID().uuidString, name: "Synthetic hub", dimension: "n", x: 640, y: 32, z: 640, status: .confirmed)
        let base = MetroNetworkStore.Document(stations: [origin], lines: [], edges: [], originID: origin.id)
        let rings = try MetroAutoPlanner.proposals(base: base, pins: [], layout: .rings, rings: 2, spacing: 128)
        precondition(rings.count == 3 && Set(rings.map(\.strategy)).count == 3)
        precondition(rings[0].railBlocks <= rings[1].railBlocks)
        for p in rings {
            precondition(MetroNetworkStore.validate(p.network))
            precondition(p.network.stations.contains(origin) && p.addedStationIDs.count == 16)
            precondition(p.portalSites == 16 && p.network.stations.allSatisfy { $0.y == 32 })
            precondition(p.network.edges.allSatisfy { $0.status == .planned && $0.durationSeconds == nil && $0.mode == .rail })
            precondition(MetroNetworkStore.route(p.network, from: origin.id, to: p.network.stations.last!.id) == nil)
        }
        let symmetric = rings.first { $0.strategy == .symmetric }!
        precondition(symmetric.network.edges.count == 24) // Two closed eight-stop rings and four two-leg spokes.
        for edge in symmetric.network.edges {
            for (a,b) in zip(edge.path!, edge.path!.dropFirst()) { precondition(a.x == b.x || a.z == b.z) }
        }
        let target = MetroPlanPin(name: "Synthetic target", dimension: "n", point: .init(x: 940, y: 40, z: 920))
        let plans = try MetroAutoPlanner.proposals(base: base, pins: [target], layout: .targets, rings: 1, spacing: 128)
        precondition(plans[0].railBlocks < plans[1].railBlocks)
        precondition(plans[1].network.edges[0].path!.count == 3)
        precondition(plans[0].network.stations.last!.name == target.name)
        let outside = MetroPlanPin(name: "Synthetic surface destination", dimension: "o", point: .init(x: 4800, y: 70, z: 2400))
        let unresolved = try MetroAutoPlanner.proposals(base: base, pins: [outside], layout: .targets, rings: 1, spacing: 128)
        precondition(unresolved.allSatisfy { $0.unresolvedPins == 1 && $0.network.edges.isEmpty })
        let surface = MetroStation(id: UUID().uuidString, name: outside.name, dimension: "o", x: outside.point.x, y: outside.point.y, z: outside.point.z, status: .confirmed)
        let remote = MetroStation(id: UUID().uuidString, name: "Observed exit", dimension: "n", x: 760, y: 34, z: 720, status: .confirmed)
        let portal = MetroEdge(id: UUID().uuidString, from: remote.id, to: surface.id, lineID: nil, mode: .portal, status: .confirmed, lengthBlocks: 0, durationSeconds: 12, note: "Synthetic observation")
        let observed = MetroNetworkStore.Document(stations: [origin, remote, surface], lines: [], edges: [portal], originID: origin.id)
        let mapped = try MetroAutoPlanner.proposals(base: observed, pins: [outside], layout: .targets, rings: 1, spacing: 128)
        for p in mapped {
            precondition(p.unresolvedPins == 0 && p.network.edges.contains(portal))
            precondition(p.network.stations == observed.stations)
            precondition(p.network.edges.filter { $0.mode == .portal }.count == 1)
            precondition(p.network.edges.contains { $0.from == origin.id && $0.to == remote.id && $0.status == .planned })
        }
        var unmeasured = observed; unmeasured.edges[0].durationSeconds = nil
        let noMeasurement = try MetroAutoPlanner.proposals(base: unmeasured, pins: [outside], layout: .targets, rings: 1, spacing: 128)
        precondition(noMeasurement[0].unresolvedPins == 1)
        var unconfirmedSurface = observed; unconfirmedSurface.stations[2].status = .built
        let notConfirmed = try MetroAutoPlanner.proposals(base: unconfirmedSurface, pins: [outside], layout: .targets, rings: 1, spacing: 128)
        precondition(notConfirmed[0].unresolvedPins == 1)
        var ambiguous = observed
        ambiguous.edges.append(MetroEdge(id: UUID().uuidString, from: origin.id, to: surface.id, lineID: nil, mode: .portal, status: .confirmed, lengthBlocks: 0, durationSeconds: 7, note: "Other synthetic observation"))
        let conflict = try MetroAutoPlanner.proposals(base: ambiguous, pins: [outside], layout: .targets, rings: 1, spacing: 128)
        precondition(conflict[0].unresolvedPins == 1)
        precondition((try? MetroAutoPlanner.proposals(base: base, pins: [], layout: .targets, rings: 1, spacing: 128)) == nil)
        precondition((try? MetroAutoPlanner.proposals(base: base, pins: [], layout: .rings, rings: 9, spacing: 128)) == nil)
        var boundary = origin; boundary.x = 30_000_000
        let bounded = MetroNetworkStore.Document(stations: [boundary], lines: [], edges: [], originID: boundary.id)
        precondition((try? MetroAutoPlanner.proposals(base: bounded, pins: [], layout: .rings, rings: 1, spacing: 128)) == nil)
        let encoded = try JSONEncoder().encode(symmetric.network)
        let decoded = try JSONDecoder().decode(MetroNetworkStore.Document.self, from: encoded)
        precondition(decoded == symmetric.network)
        let store = MetroNetworkStore(url: FileManager.default.temporaryDirectory.appendingPathComponent("metro-auto-" + UUID().uuidString).appendingPathComponent("network.json"))
        try store.save(base)
        try store.save(symmetric.network, replacing: base)
        let persisted = try store.load()
        precondition(persisted == symmetric.network && persisted.stations.filter { $0.portalCandidate == true }.count == 16)
        do { try store.save(rings[0].network, replacing: base); preconditionFailure("A stale proposal must not overwrite the applied network") }
        catch { }
        let tooMany = Array(repeating: target, count: 33)
        precondition((try? MetroAutoPlanner.proposals(base: base, pins: tooMany, layout: .targets, rings: 1, spacing: 128)) == nil)
        print("MetroAutoPlannerTests passed")
    }
}
