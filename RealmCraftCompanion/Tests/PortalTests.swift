import Foundation

@main struct PortalTests {
    static func fixture(_ points: [(Int32, Int32, Int32)]) -> Data {
        var bytes: [UInt8] = []
        func append(_ n: Int32) { let u = UInt32(bitPattern: n); bytes += (0..<4).reversed().map { UInt8(truncatingIfNeeded: u >> ($0*8)) } }
        append(Int32(points.count))
        for p in points { bytes += [0,0]; append(p.0); append(p.1); append(p.2); append(0) }
        return Data(bytes)
    }
    static func main() throws {
        let data = fixture([(-17,40,-16),(-16,40,-16),(-17,41,-16),(80,20,4)])
        let portals = try PortalReader.parse(data, dimension: "n")
        precondition(portals.count == 2)
        precondition(portals.first(where: { $0.blocks.count == 3 })?.anchor == PortalPosition(x: -17,y: 40,z: -16))
        let empty = try PortalReader.parse(fixture([]), dimension: "o"); precondition(empty.isEmpty)
        for end in 0..<data.count {
            do { _ = try PortalReader.parse(data.prefix(end), dimension: "o"); fatalError("Truncation accepted") } catch {}
        }
        for bad in [fixture([(0,256,0)]), fixture([(0,0,0),(0,0,0)]), data + Data([0])] {
            do { _ = try PortalReader.parse(bad, dimension: "o"); fatalError("Malformed input accepted") } catch {}
        }
        let pair = PortalPair(id: "synthetic", name: "Test", start: portals[0].id, destination: "o:1 / 2 / 3", note: "Observed forward only")
        let document = PortalPairDocument(fingerprint: "fixture", pairs: [pair])
        let result = try JSONDecoder().decode(PortalPairDocument.self, from: JSONEncoder().encode(document))
        precondition(result.pairs[0].start == pair.start && result.pairs[0].destination == pair.destination)
        func portal(_ d: String, _ x: Int, _ z: Int) -> SavedPortal { SavedPortal(dimension: d, blocks: [PortalPosition(x: x, y: 64, z: z)]) }
        let a = portal("o", 800, -400), b = portal("n", 100, -50), c = portal("o", 808, -400)
        let candidates = PortalSuggestions.make([a,b,c], recorded: [])
        precondition(candidates.count == 3)
        precondition(candidates.first(where: { $0.start == a.id })?.destination == b.id)
        precondition(candidates.first(where: { $0.start == b.id })?.destination == a.id)
        let observed = PortalPair(id: "observation", name: "Synthetic", start: b.id, destination: c.id, note: "Traveled")
        precondition(!PortalSuggestions.make([a,b,c], recorded: [observed]).contains(where: { $0.start == b.id }))
        let ties = PortalSuggestions.make([portal("o",0,0),portal("n",-1,0),portal("n",1,0)], recorded: []).filter { $0.start.hasPrefix("o:") }
        precondition(ties.count == 2 && ties.allSatisfy(\.tied))
        precondition(PortalSuggestions.make([a], recorded: []).isEmpty)
        let labels = PortalLabelStore(url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("names.json"))
        _ = try labels.save(id: a.id, name: " Synthetic gate ", fingerprint: "fixture")
        let names = try labels.load(fingerprint: "fixture"); precondition(names[a.id] == "Synthetic gate")
        do { _ = try labels.load(fingerprint: "changed"); fatalError("stale names accepted") } catch {}
        print("PASS: grouping across chunk boundaries, negative coordinates, anchor, malformed/truncated POI data, directed pair persistence")
    }
}
