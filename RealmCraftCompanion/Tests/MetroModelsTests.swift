import Foundation

@main struct MetroModelsTests {
    static func main() throws {
        let a = MetroStation(id: UUID().uuidString, name: "Central", dimension: "n", x: 0, y: 64, z: 0, status: .confirmed)
        let b = MetroStation(id: UUID().uuidString, name: "North hub", dimension: "n", x: 0, y: 64, z: -500, status: .confirmed)
        let c = MetroStation(id: UUID().uuidString, name: "Forest exit", dimension: "o", x: 0, y: 70, z: -4000, status: .confirmed)
        let line = MetroLine(id: UUID().uuidString, name: "N1", color: "#54E0EF")
        let rail = MetroEdge(id: UUID().uuidString, from: a.id, to: b.id, lineID: line.id, mode: .rail, status: .confirmed, lengthBlocks: 500, durationSeconds: 75, note: "Synthetic measured ride")
        let portal = MetroEdge(id: UUID().uuidString, from: b.id, to: c.id, lineID: nil, mode: .portal, status: .confirmed, lengthBlocks: 0, durationSeconds: 8, note: "Synthetic directed observation")
        let planned = MetroEdge(id: UUID().uuidString, from: a.id, to: b.id, lineID: line.id, mode: .rail, status: .planned, lengthBlocks: 100, durationSeconds: 1, note: "")
        let document = MetroNetworkStore.Document(stations: [a, b, c], lines: [line], edges: [rail, portal, planned])
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("metro-tests-" + UUID().uuidString)
        let store = MetroNetworkStore(url: root.appendingPathComponent("network.json"))
        precondition(store.valid(document)); try store.save(document); let saved = try store.load(); precondition(saved.edges.count == 3)
        let route = MetroNetworkStore.route(document, from: a.id, to: c.id)!
        precondition(route.edges.map(\.id) == [rail.id, portal.id] && route.totalBlocks == 500 && route.totalSeconds == 83)
        let lineB = MetroLine(id: UUID().uuidString, name: "N2", color: "#F78CDB")
        let alternate = MetroEdge(id: UUID().uuidString, from: b.id, to: a.id, lineID: lineB.id, mode: .rail, status: .confirmed, lengthBlocks: 500, durationSeconds: 75, note: "")
        let again = MetroEdge(id: UUID().uuidString, from: a.id, to: b.id, lineID: line.id, mode: .rail, status: .confirmed, lengthBlocks: 500, durationSeconds: 75, note: "")
        precondition(MetroRoute(edges: [rail, alternate, again], totalBlocks: 1500, totalSeconds: 225).transfers == 2)
        let invalidRail = MetroEdge(id: UUID().uuidString, from: a.id, to: c.id, lineID: nil, mode: .rail, status: .planned, lengthBlocks: 1, durationSeconds: nil, note: "")
        precondition(!store.valid(.init(stations: [a, b, c], lines: [line], edges: [invalidRail])))
        let unmeasured = MetroEdge(id: UUID().uuidString, from: b.id, to: c.id, lineID: nil, mode: .portal, status: .confirmed, lengthBlocks: 0, durationSeconds: nil, note: "")
        precondition(MetroNetworkStore.route(.init(stations: [a, b, c], lines: [line], edges: [rail, unmeasured]), from: a.id, to: c.id) == nil)
        var unconfirmedMiddle = b; unconfirmedMiddle.status = .planned
        precondition(MetroNetworkStore.route(.init(stations: [a, unconfirmedMiddle, c], lines: [line], edges: [rail, portal]), from: a.id, to: c.id) == nil)
        // Old version-one files remain readable without new optional fields.
        let legacy = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode(MetroNetworkStore.Document.self, from: legacy)
        precondition(decoded.originID == nil && decoded.stations.allSatisfy { $0.portalID == nil })
        var origin = a; origin.x = 640; origin.z = 640; origin.y = 32
        var radial = MetroNetworkStore.Document(stations: [origin], lines: [], edges: [], originID: origin.id)
        radial = try radial.extending(direction: "N", spacing: 128, count: 2, line: line)
        precondition(radial.stations.map(\.z) == [640, 512, 384])
        precondition(radial.stations.allSatisfy { $0.x == 640 && $0.y == 32 })
        precondition(radial.edges.allSatisfy { $0.status == .planned && $0.durationSeconds == nil && $0.path == nil })
        precondition(MetroNaming.lineName(from: radial.stations[1], existing: [line], origin: origin) == "N2")
        precondition(MetroNaming.stationName(x: 640, z: 512, existing: radial.stations, origin: origin) == "N Station 3")
        precondition((try? radial.extending(direction: "N", spacing: 0, count: 2, line: line)) == nil)
        precondition((try? radial.extending(direction: "N", spacing: 128, count: 17, line: line)) == nil)
        precondition(MetroNetworkStore.route(radial, from: origin.id, to: radial.stations[2].id) == nil)
        var captured = rail
        captured.path = [MetroPoint(a), MetroPoint(x: 30, y: 64, z: 0), MetroPoint(x: 30, y: 64, z: -500), MetroPoint(b)]
        precondition(MetroPoint.length(captured.path!) == 560)
        var geometryDocument = document; geometryDocument.edges = [captured, portal]
        precondition(store.valid(geometryDocument))
        geometryDocument.stations[0].x = 1
        precondition(!store.valid(geometryDocument))
        var badOrigin = document; badOrigin.originID = c.id
        precondition(!store.valid(badOrigin))
        precondition(MetroRoute(edges: [rail, portal, alternate], totalBlocks: 1000, totalSeconds: 158).transfers == 1)
        let pick: [String: Any] = ["dimension": "n", "x": 640, "y": 32, "z": 512, "knownHeight": true]
        precondition(MetroMapSelection.read(pick)?.point.y == 32)
        var unknown = pick; unknown.removeValue(forKey: "y")
        precondition(MetroMapSelection.read(unknown) == nil)
        unknown = pick; unknown["knownHeight"] = false
        precondition(MetroMapSelection.read(unknown) == nil)
        unknown = pick; unknown["y"] = 999
        precondition(MetroMapSelection.read(unknown) == nil)
        var changed = document; changed.originID = a.id
        try store.save(changed, replacing: document)
        do { try store.save(document, replacing: document); preconditionFailure("Stale state overwrote the newer network") }
        catch { let retained = try store.load(); precondition(retained == changed) }
        let largeEdges = (0..<30).map { _ in
            MetroEdge(id: UUID().uuidString, from: a.id, to: b.id, lineID: line.id, mode: .rail, status: .planned, lengthBlocks: 500, durationSeconds: nil, note: "", path: [MetroPoint(a)] + Array(repeating: MetroPoint(b), count: 1999))
        }
        let oversized = MetroNetworkStore.Document(stations: [a,b], lines: [line], edges: largeEdges)
        precondition(store.valid(oversized))
        do { try store.save(oversized); preconditionFailure("Saved a document larger than the read limit") }
        catch { let retained = try store.load(); precondition(retained == changed) }
        print("PASS: Metro persistence, legacy decoding, stale-write guard, directed routing, transfers, relative naming, radial proposals, path geometry and map selection validation")
    }
}
