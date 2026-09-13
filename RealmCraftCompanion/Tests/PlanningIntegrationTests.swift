import Foundation

@main struct PlanningIntegrationTests {
    static func check(_ value: @autoclosure () throws -> Bool) throws { let result = try value(); precondition(result) }
    static func rejected(_ action: () throws -> Void) { do { try action(); fatalError("Expected rejection") } catch {} }
    static func main() throws {
        let a = MetroStation(id: UUID().uuidString, name: "Start", dimension: "n", x: -16, y: 65, z: 0, status: .confirmed)
        let b = MetroStation(id: UUID().uuidString, name: "Portal", dimension: "n", x: 0, y: 65, z: 0, status: .confirmed)
        let c = MetroStation(id: UUID().uuidString, name: "Exit", dimension: "o", x: 19, y: 70, z: -8, status: .confirmed)
        let d = MetroStation(id: UUID().uuidString, name: "Finish", dimension: "o", x: 32, y: 70, z: -8, status: .confirmed)
        let line = MetroLine(id: UUID().uuidString, name: "N1", color: "#88AA77")
        let second = MetroLine(id: UUID().uuidString, name: "E1", color: "#7788AA")
        let ab = MetroEdge(id: UUID().uuidString, from: a.id, to: b.id, lineID: line.id, mode: .rail, status: .confirmed, lengthBlocks: 16, durationSeconds: 5, note: "", path: [MetroPoint(a),MetroPoint(b)])
        let bc = MetroEdge(id: UUID().uuidString, from: b.id, to: c.id, mode: .portal, status: .confirmed, lengthBlocks: 0, durationSeconds: 9, note: "")
        let cd = MetroEdge(id: UUID().uuidString, from: c.id, to: d.id, lineID: second.id, mode: .rail, status: .confirmed, lengthBlocks: 13, durationSeconds: 6, note: "")
        let network = MetroNetworkStore.Document(stations: [a,b,c,d], lines: [line,second], edges: [ab,bc,cd])
        let route = MetroNetworkStore.route(network, from: a.id, to: d.id)!
        var journey = MetroJourney(name: "Synthetic journey", saveID: "after", world: "515151", networkHash: try MetroJourney.fingerprint(network), from: a.id, to: d.id, edgeIDs: route.edges.map(\.id))
        journey.completedLegs = 2
        try check(try journey.route(in: network, saveID: "after", world: "515151").totalSeconds == 20)
        rejected { _ = try journey.route(in: network, saveID: "different", world: "515151") }
        var changed = network; changed.edges[0].durationSeconds = 6
        rejected { _ = try journey.route(in: changed, saveID: "after", world: "515151") }
        var invalid = journey; invalid.completedLegs = 4; try check(!invalid.valid)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("planning-tests-"+UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = PlanningStore(url: root.appendingPathComponent("journeys.json"), empty: MetroJourneyJournal())
        let journal = MetroJourneyJournal(activeID: journey.id, journeys: [journey])
        try store.save(journal, replacing: MetroJourneyJournal())
        try check(try store.load() == journal)
        rejected { try store.save(MetroJourneyJournal(), replacing: MetroJourneyJournal()) }
        try Data("corrupt".utf8).write(to: store.url)
        rejected { _ = try store.load() }
        let pack = try MetroJourneyExport(network: network, route: route, saveID: "after", world: "515151", title: "Synthetic", date: Date(), completed: 2, sharedGuidance: "No live tracking.")
        try check(pack.lastConfirmedStation.stationID == c.id && pack.legs[1].from.dimension == "n" && pack.legs[1].to.dimension == "o")
        try check(pack.legs[2].transfer && pack.legs.allSatisfy(\.confirmationRequired) && pack.legs[0].recordedPath?.count == 2)
        let decoded = try JSONDecoder().decode(MetroJourneyExport.self, from: JSONEncoder().encode(pack))
        try check(decoded.completedLegs == 2 && decoded.markdown.contains("PORTAL:") && decoded.markdown.contains("TRANSFER") && decoded.markdown.contains("unplanned"))
        let preset = OrePreset(name: "Gold", world: "515151", dimension: "n", bounds: [-16,15,12,24,-32,-1], materials: ["gold","diamond"], oreID: "gold", biomeID: "4", nonAirOnly: true, sampleSize: 128, seed: 123)
        try check(preset.valid)
        let presets = OrePresetCollection(presets: [preset])
        let presetStore = PlanningStore(url: root.appendingPathComponent("presets.json"), empty: OrePresetCollection())
        try presetStore.save(presets, replacing: OrePresetCollection())
        try check(try presetStore.load() == presets)
        let bad = OrePreset(name: "", world: "515151", dimension: "o", bounds: [0,1,-1,256,0,1], materials: [], oreID: "gold", biomeID: "all", nonAirOnly: false, sampleSize: 0, seed: 0)
        try check(!bad.valid)
        let changes = ChunkChange.compare(before: ["o.-16,0":"a","o.0,0":"b","n.0,0":"c","world_data":"x"], after: ["o.-16,0":"a","o.0,0":"d","o.16,0":"e","world_data":"y"])
        try check(changes.count == 4 && changes.filter { $0.status == .added }.count == 1 && changes.filter { $0.status == .changed }.count == 1 && changes.filter { $0.status == .missing }.count == 1 && changes.filter { $0.status == .unchanged }.count == 1)
        try check(ChunkChange.position("o.-1,0") == nil && ChunkChange.position("../o.0,0") == nil && ChunkChange.position("o.30000016,0") == nil)
        print("PASS: journey resume/staleness, metadata round trips, dimension-aware export/transfers, presets and chunk changes")
    }
}
