import Foundation

struct MetroPlanPin: Identifiable, Equatable {
    let id: String
    var name: String
    var dimension: String
    var point: MetroPoint
    init(name: String, dimension: String, point: MetroPoint) {
        id = UUID().uuidString; self.name = name; self.dimension = dimension; self.point = point
    }
}

enum MetroPlanLayout: String, CaseIterable { case rings, targets, combined }
enum MetroPlanStrategy: String, CaseIterable { case short, symmetric, balanced }

struct MetroPlanProposal: Identifiable {
    let id: String
    let strategy: MetroPlanStrategy
    let network: MetroNetworkStore.Document
    let addedStationIDs: Set<String>
    let addedEdgeIDs: Set<String>
    let unresolvedPins: Int
    var railBlocks: Int { network.edges.filter { addedEdgeIDs.contains($0.id) && $0.mode == .rail }.reduce(0) { $0 + $1.lengthBlocks } }
    var portalSites: Int { network.stations.filter { addedStationIDs.contains($0.id) && $0.portalCandidate == true }.count }
    var interchanges: Int { network.stations.filter { network.servingLines($0.id).count > 1 }.count }
}

// Geometric construction proposals, never terrain paths or portal predictions.
enum MetroAutoPlanner {
    private static func t(_ de: String, _ en: String) -> String { de + " / " + en }
    static func proposals(base: MetroNetworkStore.Document, pins: [MetroPlanPin], layout: MetroPlanLayout,
                          rings: Int, spacing: Int) throws -> [MetroPlanProposal] {
        guard MetroNetworkStore.validate(base), let origin = base.origin, (1...8).contains(rings),
              (16...4096).contains(spacing), pins.count <= 32,
              pins.allSatisfy({ $0.point.valid && ["n", "o"].contains($0.dimension) && !$0.name.isEmpty && $0.name.count <= 80 }),
              layout == .rings || !pins.isEmpty else { throw MetroNetworkStore.StoreError.invalid }
        return try MetroPlanStrategy.allCases.map { strategy in
            var document = base
            let oldStations = Set(base.stations.map(\.id)), oldEdges = Set(base.edges.map(\.id))
            var routes: [[MetroStation]] = []
            var targets: [MetroStation] = []
            var unresolved = 0
            func station(_ point: MetroPoint, dimension: String = "n", name: String? = nil) -> MetroStation {
                if let found = document.stations.first(where: { $0.dimension == dimension && MetroPoint($0) == point }) { return found }
                var value = MetroStation(id: UUID().uuidString,
                    name: name ?? MetroNaming.stationName(x: point.x, z: point.z, existing: document.stations, origin: origin),
                    dimension: dimension, x: point.x, y: point.y, z: point.z, status: .planned)
                value.portalCandidate = true
                document.stations.append(value); return value
            }
            if layout != .targets {
                var axes = Array(repeating: [origin], count: 4)
                for ring in 1...rings {
                    let r = ring * spacing
                    let points = [MetroPoint(x: origin.x, y: origin.y, z: origin.z-r),
                                  MetroPoint(x: origin.x+r, y: origin.y, z: origin.z-r),
                                  MetroPoint(x: origin.x+r, y: origin.y, z: origin.z),
                                  MetroPoint(x: origin.x+r, y: origin.y, z: origin.z+r),
                                  MetroPoint(x: origin.x, y: origin.y, z: origin.z+r),
                                  MetroPoint(x: origin.x-r, y: origin.y, z: origin.z+r),
                                  MetroPoint(x: origin.x-r, y: origin.y, z: origin.z),
                                  MetroPoint(x: origin.x-r, y: origin.y, z: origin.z-r)]
                    let stops = points.map { station($0) }
                    for i in 0..<4 { axes[i].append(stops[i * 2]) }
                    routes.append(stops + [stops[0]])
                }
                routes += axes
            }
            if layout != .rings {
                for pin in pins {
                    let stop = station(pin.point, dimension: pin.dimension, name: pin.name)
                    if pin.dimension == "n" { targets.append(stop); continue }
                    // Resolve only a directed, confirmed, measured portal observation already in the base.
                    let counterparts = base.edges.filter { edge in
                        stop.status == .confirmed &&
                        edge.mode == .portal && edge.status == .confirmed && edge.durationSeconds != nil &&
                        (edge.from == stop.id || edge.to == stop.id)
                    }.compactMap { edge in base.stations.first { $0.id == (edge.from == stop.id ? edge.to : edge.from) && $0.dimension == "n" && $0.status == .confirmed } }
                    if Set(counterparts.map(\.id)).count == 1, let counterpart = counterparts.first { targets.append(counterpart) } else { unresolved += 1 }
                }
            }
            func distance(_ a: MetroStation, _ b: MetroStation) -> Int { MetroPoint.length([MetroPoint(a), MetroPoint(b)]) }
            if strategy == .short {
                // Deterministic Prim tree over required stops; minimum straight-line construction length,
                // not minimum journey time and not a terrain-safe rail alignment.
                let required = routes.flatMap { $0 } + targets
                var remaining = Dictionary(required.filter { $0.id != origin.id }.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }).values.sorted { ($0.x, $0.z, $0.id) < ($1.x, $1.z, $1.id) }
                var connected = [origin]; routes = []
                while !remaining.isEmpty {
                    var choice = (a: 0, b: 0, cost: Int.max)
                    for a in connected.indices { for b in remaining.indices {
                        let cost = distance(connected[a], remaining[b]); if cost < choice.cost { choice = (a,b,cost) }
                    } }
                    let next = remaining.remove(at: choice.b); routes.append([connected[choice.a], next]); connected.append(next)
                }
            } else {
                var anchors = [origin] + routes.flatMap { $0 }
                for target in targets where !anchors.contains(where: { $0.id == target.id }) {
                    let anchor = strategy == .symmetric ? origin : anchors.min { distance($0, target) < distance($1, target) }!
                    routes.append([anchor, target]); anchors.append(target)
                }
            }
            let palette = ["#54C9DF", "#E8AF55", "#AC85DE", "#D96C93", "#A8CF6E", "#698FE8"]
            for (index, route) in routes.enumerated() where route.count > 1 {
                let first = route[1]
                let line = MetroLine(id: UUID().uuidString, name: MetroNaming.lineName(from: first, existing: document.lines, origin: origin), color: palette[index % palette.count])
                var added = false
                for (a,b) in zip(route, route.dropFirst()) where a.id != b.id {
                    // Retain all real/planned base links unchanged; do not create assumed reverse links.
                    if document.edges.contains(where: { ($0.from == a.id && $0.to == b.id) || ($0.from == b.id && $0.to == a.id) }) { continue }
                    var path = [MetroPoint(a)]
                    if strategy == .symmetric && a.x != b.x && a.z != b.z {
                        path.append(MetroPoint(x: b.x, y: a.y, z: a.z))
                    }
                    path.append(MetroPoint(b))
                    document.edges.append(MetroEdge(id: UUID().uuidString, from: a.id, to: b.id, lineID: line.id,
                        mode: .rail, status: .planned, lengthBlocks: MetroPoint.length(path), durationSeconds: nil,
                        note: t("Automatischer Entwurf: nur Geometrie; Gelände und Fahrt ungeprüft.", "Auto-plan: geometry only; terrain and travel unverified."), path: path))
                    added = true
                }
                if added { document.lines.append(line) }
            }
            guard MetroNetworkStore.validate(document) else { throw MetroNetworkStore.StoreError.invalid }
            return MetroPlanProposal(id: UUID().uuidString, strategy: strategy, network: document,
                addedStationIDs: Set(document.stations.map(\.id)).subtracting(oldStations),
                addedEdgeIDs: Set(document.edges.map(\.id)).subtracting(oldEdges), unresolvedPins: unresolved)
        }
    }
}
