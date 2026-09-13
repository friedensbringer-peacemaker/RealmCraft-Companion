import Foundation

// Local planning metadata only: this never predicts or changes a RealmCraft portal link.
enum MetroStatus: String, Codable, CaseIterable { case planned, built, confirmed; var routable: Bool { self == .confirmed } }
enum MetroMode: String, Codable, CaseIterable { case rail, portal, walk }

struct MetroPoint: Codable, Hashable {
    var x: Int; var y: Int; var z: Int
    init(x: Int, y: Int, z: Int) { self.x = x; self.y = y; self.z = z }
    init(_ station: MetroStation) { self.init(x: station.x, y: station.y, z: station.z) }
    var valid: Bool { (-30_000_000...30_000_000).contains(x) && (-30_000_000...30_000_000).contains(z) && (0...255).contains(y) }
    static func length(_ points: [Self]) -> Int {
        Int(zip(points, points.dropFirst()).reduce(0.0) { sum, pair in
            let dx = Double(pair.1.x) - Double(pair.0.x), dy = Double(pair.1.y) - Double(pair.0.y), dz = Double(pair.1.z) - Double(pair.0.z)
            return sum + (dx * dx + dy * dy + dz * dz).squareRoot()
        }.rounded())
    }
}

struct MetroMapSelection {
    let dimension: String; let point: MetroPoint; let portalID: String?
    static func read(_ body: [String: Any]) -> Self? {
        guard let dimension = body["dimension"] as? String, ["o", "n"].contains(dimension),
              let x = body["x"] as? Int, let y = body["y"] as? Int, let z = body["z"] as? Int,
              body["knownHeight"] as? Bool == true else { return nil }
        let point = MetroPoint(x: x, y: y, z: z)
        guard point.valid else { return nil }
        return Self(dimension: dimension, point: point, portalID: body["portalID"] as? String)
    }
}

enum MetroNaming {
    static func direction(x: Int, z: Int) -> String {
        if abs(x) > abs(z) { return x >= 0 ? "E" : "W" }
        return z >= 0 ? "S" : "N"
    }
    static func stationName(x: Int, z: Int, existing: [MetroStation], origin: MetroStation? = nil) -> String {
        let prefix = direction(x: x - (origin?.x ?? 0), z: z - (origin?.z ?? 0))
        var number = 1
        while existing.contains(where: { $0.name == "\(prefix) Station \(number)" }) { number += 1 }
        return "\(prefix) Station \(number)"
    }
    static func lineName(from: MetroStation, existing: [MetroLine], origin: MetroStation? = nil) -> String {
        let prefix = direction(x: from.x - (origin?.x ?? 0), z: from.z - (origin?.z ?? 0))
        var number = 1
        while existing.contains(where: { $0.name == "\(prefix)\(number)" }) { number += 1 }
        return "\(prefix)\(number)"
    }
}

struct MetroStation: Codable, Identifiable, Hashable {
    let id: String; var name: String; var dimension: String; var x: Int; var y: Int; var z: Int; var status: MetroStatus
    var portalID: String? = nil
    var portalCandidate: Bool? = nil
    var destination: String? = nil
    var valid: Bool { UUID(uuidString: id) != nil && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 80 && ["o", "n"].contains(dimension) && (-30_000_000...30_000_000).contains(x) && (-30_000_000...30_000_000).contains(z) && (0...255).contains(y) }
}
struct MetroLine: Codable, Identifiable, Hashable {
    let id: String; var name: String; var color: String
    var valid: Bool { UUID(uuidString: id) != nil && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 50 && color.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil }
}
struct MetroEdge: Codable, Identifiable, Hashable {
    let id: String; var from: String; var to: String; var lineID: String?; var mode: MetroMode; var status: MetroStatus; var lengthBlocks: Int; var durationSeconds: Int?; var note: String
    // User-recorded geometry is distinct from a detected rail path and a direct connector.
    var path: [MetroPoint]? = nil
    var valid: Bool { UUID(uuidString: id) != nil && UUID(uuidString: from) != nil && UUID(uuidString: to) != nil && from != to && (lineID == nil || UUID(uuidString: lineID!) != nil) && (0...2_000_000).contains(lengthBlocks) && (durationSeconds == nil || (0...86_400).contains(durationSeconds!)) && note.count <= 500 }
}
struct MetroRoute {
    let edges: [MetroEdge]; let totalBlocks: Int; let totalSeconds: Int?
    var transfers: Int {
        let lines = edges.compactMap(\.lineID)
        return zip(lines, lines.dropFirst()).filter { $0 != $1 }.count
    }
}

struct MetroNetworkStore {
    struct Document: Codable, Equatable {
        var version = 1; var stations: [MetroStation]; var lines: [MetroLine]; var edges: [MetroEdge]
        var originID: String? = nil
        var origin: MetroStation? { stations.first { $0.id == originID } }
        func servingLines(_ stationID: String) -> [MetroLine] {
            let ids = Set(edges.filter { $0.from == stationID || $0.to == stationID }.compactMap(\.lineID))
            return lines.filter { ids.contains($0.id) }
        }
        func extending(direction: String, spacing: Int, count: Int, line: MetroLine) throws -> Self {
            guard let origin, ["N", "S", "E", "W"].contains(direction), (1...4096).contains(spacing), (1...16).contains(count) else { throw StoreError.invalid }
            var copy = self
            if !copy.lines.contains(where: { $0.id == line.id }) { copy.lines.append(line) }
            var previous = origin
            for index in 1...count {
                let x = origin.x + (direction == "E" ? 1 : direction == "W" ? -1 : 0) * spacing * index
                let z = origin.z + (direction == "S" ? 1 : direction == "N" ? -1 : 0) * spacing * index
                let station = MetroStation(id: UUID().uuidString, name: MetroNaming.stationName(x: x, z: z, existing: copy.stations, origin: origin), dimension: "n", x: x, y: origin.y, z: z, status: .planned)
                copy.stations.append(station)
                copy.edges.append(MetroEdge(id: UUID().uuidString, from: previous.id, to: station.id, lineID: line.id, mode: .rail, status: .planned, lengthBlocks: spacing, durationSeconds: nil, note: "Radial proposal; build site and rail path unverified."))
                previous = station
            }
            guard MetroNetworkStore(url: URL(fileURLWithPath: "/dev/null")).valid(copy) else { throw StoreError.invalid }
            return copy
        }
    }
    enum StoreError: LocalizedError { case invalid; var errorDescription: String? { "Metro network could not be read or saved / Metronetz konnte nicht gelesen oder gespeichert werden." } }
    let url: URL
    func load() throws -> Document { guard FileManager.default.fileExists(atPath: url.path) else { return Document(stations: [], lines: [], edges: []) }; let data = try Data(contentsOf: url); guard data.count <= 2_000_000, let document = try? JSONDecoder().decode(Document.self, from: data), valid(document) else { throw StoreError.invalid }; return document }
    func save(_ document: Document) throws {
        guard valid(document) else { throw StoreError.invalid }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        guard data.count <= 2_000_000 else { throw StoreError.invalid }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
    func save(_ proposal: Document, replacing expected: Document) throws {
        guard try load() == expected else { throw StoreError.invalid }
        try save(proposal)
    }
    func valid(_ document: Document) -> Bool {
        Self.validate(document)
    }
    static func validate(_ document: Document) -> Bool {
        guard document.version == 1 && document.stations.count <= 500 && document.lines.count <= 100 && document.edges.count <= 2_000 && document.stations.allSatisfy(\.valid) && document.lines.allSatisfy(\.valid) && document.edges.allSatisfy(\.valid) else { return false }
        let stationIDs = Set(document.stations.map(\.id)), lineIDs = Set(document.lines.map(\.id))
        guard stationIDs.count == document.stations.count && lineIDs.count == document.lines.count && Set(document.edges.map(\.id)).count == document.edges.count else { return false }
        guard document.originID == nil || document.origin?.dimension == "n",
              document.stations.allSatisfy({ ($0.destination?.count ?? 0) <= 120 && ($0.portalID?.count ?? 0) <= 160 }) else { return false }
        return document.edges.allSatisfy { edge in
            guard let a = document.stations.first(where: { $0.id == edge.from }), let b = document.stations.first(where: { $0.id == edge.to }), edge.lineID.map({ lineIDs.contains($0) }) ?? true else { return false }
            if let path = edge.path {
                guard edge.mode != .portal, path.count >= 2, path.count <= 2000, path.allSatisfy(\.valid),
                      path.first == MetroPoint(a), path.last == MetroPoint(b) else { return false }
            }
            return edge.mode == .portal ? a.dimension != b.dimension : a.dimension == b.dimension
        }
    }
    static func route(_ document: Document, from: String, to: String) -> MetroRoute? {
        guard from != to, document.stations.contains(where: { $0.id == from && $0.status.routable }), document.stations.contains(where: { $0.id == to && $0.status.routable }) else { return nil }
        let stations = Dictionary(uniqueKeysWithValues: document.stations.map { ($0.id, $0) })
        let usable = document.edges.filter { edge in edge.status.routable && edge.durationSeconds != nil && stations[edge.from]?.status.routable == true && stations[edge.to]?.status.routable == true }; var queue = [(from, 0)], costs = [from: 0], prior = [String: MetroEdge]()
        while !queue.isEmpty { queue.sort { $0.1 < $1.1 }; let current = queue.removeFirst(); guard current.1 == costs[current.0] else { continue }; if current.0 == to { break }; for edge in usable where edge.from == current.0 { let next = current.1 + (edge.durationSeconds ?? 0); if next < (costs[edge.to] ?? .max) { costs[edge.to] = next; prior[edge.to] = edge; queue.append((edge.to, next)) } } }
        guard costs[to] != nil else { return nil }; var result: [MetroEdge] = [], cursor = to
        while cursor != from { guard let edge = prior[cursor] else { return nil }; result.append(edge); cursor = edge.from }; result.reverse()
        return MetroRoute(edges: result, totalBlocks: result.reduce(0) { $0 + $1.lengthBlocks }, totalSeconds: result.compactMap(\.durationSeconds).reduce(0, +))
    }
}
