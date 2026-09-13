import Foundation
import CryptoKit

struct OreReference: Decodable {
    let version: String, reviewed: String
    let entries: [OreKind]
    let sources: [URL]
    static func load(_ url: URL? = Bundle.main.url(forResource: "OreReference", withExtension: "json")) throws -> Self {
        guard let url else { throw OreError("Ore catalog missing / Erzkatalog fehlt") }
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}
struct OreKind: Decodable, Identifiable {
    let id: String, de: String, en: String, dimension: String
    let blockIDs: [Int]
    let notesDE: String, notesEN: String
    let wiki: URL
    let batches: [OreBatch]
    func name(_ english: Bool) -> String { english ? en : de }
}
struct OreBatch: Decodable, Identifiable {
    let id: String, shape: String, condition: String
    let low: Int, high: Int, size: Int
    let attempts: Double, airSkip: Double
    let sources: [URL]
    // Discrete convolution used for the zero-plateau trapezoid (triangle) height provider.
    func weight(at y: Int) -> Double {
        guard y >= low && y <= high else { return 0 }
        if shape == "uniform" { return attempts / Double(high - low + 1) }
        let a = (high-low)/2, b = high-low-a, k = y-low
        let ways = max(0, min(a,k)-max(0,k-b)+1)
        return attempts * Double(ways) / Double((a+1)*(b+1))
    }
    func conditionName(_ en: Bool) -> String {
        switch condition {
        case "badlands": return en ? "Extra: badlands" : "Zusätzlich: Tafelberge"
        case "mountains": return en ? "Mountain / windswept biomes" : "Berg- / windgepeitschte Biome"
        case "dripstone": return en ? "Dripstone caves" : "Tropfsteinhöhlen"
        case "deltas": return en ? "Basalt deltas" : "Basaltdeltas"
        case "other": return en ? "Other eligible biomes" : "Andere passende Biome"
        default: return en ? "All eligible biomes" : "Alle passenden Biome"
        }
    }
}
struct OreHeightMapping {
    var mode: String = "scaled"
    var offset: Int = 0
    var legacy = false
    func map(_ y: Double, dimension: String) -> Double {
        if mode == "offset" { return y + Double(offset) }
        if mode == "identity" || dimension == "n" || legacy { return y }
        return (y + 64) * 255 / 383
    }
    func band(_ batch: OreBatch, dimension: String) -> ClosedRange<Int>? {
        let floor = dimension == "n" || legacy ? 0 : -64, top = dimension == "n" ? 127 : legacy ? 255 : 319
        let lo = map(Double(max(batch.low,floor)),dimension: dimension)
        let hi = map(Double(min(batch.high,top)),dimension: dimension)
        guard hi >= 0, lo <= 255, hi >= lo else { return nil }
        return max(0,Int(lo.rounded()))...min(255,Int(hi.rounded()))
    }
}
struct OreError: LocalizedError {
    var message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
struct OreLevel: Codable, Identifiable {
    let y: Int, blocks: Int, nonAir: Int, unknown: Int
    let ores: [String:Int]
    // Optional for compatibility with measurements written before the general
    // selected-area material report was introduced.
    let materials: [String:Int]?
    init(y: Int, blocks: Int, nonAir: Int, unknown: Int, ores: [String:Int], materials: [String:Int]? = nil) {
        self.y = y; self.blocks = blocks; self.nonAir = nonAir; self.unknown = unknown
        self.ores = ores; self.materials = materials
    }
    var id: Int { y }
    func rate(_ ore: String, nonAirOnly: Bool = false) -> Double? {
        let denominator = nonAirOnly ? nonAir : blocks
        guard denominator > 0 else { return nil }
        return Double(ores[ore] ?? 0) / Double(denominator)
    }
    func material(_ id: String) -> Int { materials?[id] ?? ores[id] ?? 0 }
}
struct OreProbe: Codable {
    let volume: Int, compared: Int, beforeAir: Int, removed: Int, remaining: Int, otherChanges: Int, unknown: Int
    let counts: [String:Int]
    let complete: Bool
}
struct OreBiome: Codable, Identifiable {
    let id: String, chunks: Int, columns: Int
    let levels: [OreLevel]
}
struct OreSampling: Codable {
    let seed: Int, requested: Int, eligible: Int, sectors: Int, method: String
    let selected: [String]
}
struct OreScan: Codable {
    let schema: Int, dimension: String, bounds: [Int], expected: Int, scanned: Int
    let missing: [String:String], errors: [String], metadataErrors: [String]
    let levels: [OreLevel]
    let hashes: [String:String], beforeHashes: [String:String]
    let chests: [ChestRecord], beforeChests: [ChestRecord]
    let probe: OreProbe?
    let biomes: [OreBiome]?
    let sampling: OreSampling?
    var spatial: OreSpatial? = nil
    var areas: [OreArea]? = nil
    var complete: Bool { scanned > 0 && errors.isEmpty && missing.isEmpty }
    var volume: Int { levels.reduce(0) { $0 + $1.blocks } }
    func count(_ ore: String) -> Int { levels.reduce(0) { $0 + ($1.ores[ore] ?? 0) } }
    func peak(_ ore: String) -> Int? {
        guard count(ore)>0 else { return nil }
        return levels.max { ($0.rate(ore) ?? 0) < ($1.rate(ore) ?? 0) }?.y
    }
}
struct OrePlan: Codable, Equatable {
    var code = "RC-ORE-001"
    var dimension = "o"
    var x = 0, y = 16, z = 0, length = 100, width = 1, height = 2
    var direction = "+x"
    var biome = "unknown"
    var gameVersion = ""
    var note = ""
    var bounds: [Int] {
        guard (try? validate()) != nil else { return [] }
        let endX = x + (direction == "+x" ? length-1 : direction == "-x" ? -(length-1) : width-1)
        let endZ = z + (direction == "+z" ? length-1 : direction == "-z" ? -(length-1) : width-1)
        return [min(x,endX),max(x,endX),y,y+height-1,min(z,endZ),max(z,endZ)]
    }
    var volume: Int { (try? validate()) != nil ? length*width*height : 0 }
    func validate() throws {
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,code.count<=64,
              ["o","n"].contains(dimension),["+x","-x","+z","-z"].contains(direction),
              (1...2000).contains(length),(1...16).contains(width),(1...16).contains(height),
              (0...255).contains(y),y+height<=256,abs(Double(x))<29_990_000,abs(Double(z))<29_990_000 else {
            throw OreError("Invalid trial: Y 0–255, length 1–2000, width/height 1–16. / Ungültiger Testlauf: Y 0–255, Länge 1–2000, Breite/Höhe 1–16.")
        }
    }
    func overlaps(_ other: Self) -> Bool {
        guard dimension==other.dimension,(try? validate()) != nil,(try? other.validate()) != nil else { return false }
        let a=bounds,b=other.bounds
        return a[0]<=b[1] && b[0]<=a[1] && a[2]<=b[3] && b[2]<=a[3] && a[4]<=b[5] && b[4]<=a[5]
    }
    var group: String { [dimension,String(y),String(height),biome,gameVersion].joined(separator:"|") }
    func instructions(_ en: Bool) -> String {
        let b=bounds
        return en ? """
        1. Choose untouched terrain before viewing its ore map. Fix this route in advance: first block X \(x), Y \(y), Z \(z), direction \(direction). Y is the lowest mined block, not the floor beneath your feet.
        2. Label a dedicated empty chest with \(code). Record the game version and biome. Create the BEFORE backup after placing the sign and chest, outside the test volume.
        3. Excavate exactly \(length) × \(width) × \(height) = \(volume) positions: X \(b[0])…\(b[1]), Y \(b[2])…\(b[3]), Z \(b[4])…\(b[5]). Width extends toward positive Z for X tunnels, or positive X for Z tunnels.
        4. Count only ore blocks inside this volume. Do not follow veins or include wall discoveries. Note pre-existing air/caves. If unsafe or obstructed, stop and record an incomplete trial.
        5. Put this trial's yield in its chest only. Do not add existing stock, craft, smelt or withdraw items. Drops and ore blocks remain separate; record tool/enchantments in notes.
        6. Save and create the AFTER backup. Compare the two snapshots and attach the matching chest. Check incomplete changes and the denominator before accepting counts.
        7. Repeat with equal-length, non-overlapping, preselected routes at other heights and several separated locations per height. Log zero finds too; do not select routes after seeing ore locations.
        """ : """
        1. Unberührtes Gelände vor dem Blick auf die Erzkarte wählen. Route vorab festlegen: erster Block X \(x), Y \(y), Z \(z), Richtung \(direction). Y ist der unterste abgebaute Block, nicht der Boden unter den Füßen.
        2. Eine eigene leere Truhe mit \(code) beschriften. Spielversion und Biom eintragen. VORHER-Sicherung nach dem Aufstellen von Schild und Truhe außerhalb des Testvolumens erstellen.
        3. Genau \(length) × \(width) × \(height) = \(volume) Positionen ausheben: X \(b[0])…\(b[1]), Y \(b[2])…\(b[3]), Z \(b[4])…\(b[5]). Breite verläuft bei X-Stollen nach +Z, bei Z-Stollen nach +X.
        4. Nur Erzblöcke innerhalb dieses Volumens zählen. Keine Adern verfolgen oder Funde in den Wänden addieren. Vorhandene Luft/Höhlen notieren. Bei Gefahr oder Hindernissen abbrechen und den Lauf als unvollständig dokumentieren.
        5. Nur die Ausbeute dieses Laufs in die Testtruhe legen. Keine Altbestände hinzufügen, nichts craften, schmelzen oder entnehmen. Drops und Erzblöcke getrennt lassen; Werkzeug/Verzauberungen in den Notizen erfassen.
        6. Speichern und NACHHER-Sicherung erstellen. Beide Sicherungen vergleichen und die passende Truhe zuordnen. Unvollständige Änderungen und Bezugsmenge vor der Übernahme prüfen.
        7. Gleich lange, überlappungsfreie und vorab gewählte Strecken auf anderen Höhen sowie mehrere getrennte Orte je Höhe prüfen. Auch Nullfunde erfassen; Routen nicht nach sichtbaren Erzvorkommen auswählen.
        """
    }
}
struct OreTrial: Codable, Identifiable {
    var id = UUID().uuidString
    var supersedes: String? = nil
    var date = Date()
    var world: String
    var saveID: String
    var beforeSaveID: String?
    var plan: OrePlan
    var tested: Int?
    var counts: [String:Int]
    var method: String // manual-blocks or snapshot-diff; never drops
    var accepted: Bool
    var evidenceFile: String?
    var chestID: String?
    var chestDelta: [String:Int] = [:] // item IDs, deliberately not converted to ore counts
    func validate() throws {
        try plan.validate()
        guard UUID(uuidString:id) != nil, !world.isEmpty,
              tested.map({$0>0 && $0<=plan.volume}) ?? !accepted,
              counts.values.allSatisfy({$0>=0 && $0<=(tested ?? plan.volume)}),
              counts.values.reduce(0,+)<=(tested ?? plan.volume),
              ["manual-blocks","snapshot-diff"].contains(method) else { throw OreError("Invalid block counts / Ungültige Blockzahlen") }
        if accepted && (plan.biome.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || plan.gameVersion.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty) {
            throw OreError("Record biome (or unknown) and game version first. / Zuerst Biom (oder unbekannt) und Spielversion eintragen.")
        }
    }
}
struct OreTrialSummary: Identifiable {
    let id: String, plan: OrePlan, runs: Int, hits: Int, tested: Int
    let minimum: Double, maximum: Double
    var probability: Double { Double(hits)/Double(tested) }
    static func make(_ trials: [OreTrial], ore: String) -> [Self] {
        let valid=trials.filter { $0.accepted && $0.tested != nil && $0.counts[ore] != nil }
        let groups=Dictionary(grouping:valid,by:{$0.world+"|"+$0.plan.group})
        return groups.map { key,rows in
            let rates=rows.map { Double($0.counts[ore]!)/Double($0.tested!) }
            return Self(id:key,plan:rows[0].plan,runs:rows.count,hits:rows.reduce(0){$0+$1.counts[ore]!},tested:rows.reduce(0){$0+$1.tested!},minimum:rates.min()!,maximum:rates.max()!)
        }.sorted { $0.plan.y < $1.plan.y }
    }
}
enum OreJournal {
    static func directory(root: URL, world: String) -> URL {
        let key=SHA256.hash(data:Data(world.utf8)).map{String(format:"%02x",$0)}.joined()
        return root.appendingPathComponent(".ore-research/"+key)
    }
    static func load(_ directory: URL) throws -> [OreTrial] {
        guard FileManager.default.fileExists(atPath:directory.path) else { return [] }
        let paths=try FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil).filter{$0.lastPathComponent.hasPrefix("trial-") && $0.pathExtension=="json"}
        let rows=try paths.map { try JSONDecoder().decode(OreTrial.self,from:Data(contentsOf:$0)) }
        for row in rows { try row.validate() }
        let replaced=Set(rows.compactMap(\.supersedes))
        return rows.filter{!replaced.contains($0.id)}.sorted{$0.date>$1.date}
    }
    static func save(_ row: OreTrial, directory: URL) throws {
        try row.validate()
        let existing=try load(directory)
        if row.accepted,existing.contains(where:{$0.id != row.supersedes && $0.accepted && $0.world==row.world && $0.plan.overlaps(row.plan)}) {
            throw OreError("Accepted trials overlap. Keep this as a draft or choose another route. / Ausgewertete Testläufe überlappen. Als Entwurf speichern oder eine andere Route wählen.")
        }
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        let url=directory.appendingPathComponent("trial-"+row.id+".json")
        guard !FileManager.default.fileExists(atPath:url.path) else { throw OreError("Trial revision already exists / Testversion existiert bereits") }
        let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
        try encoder.encode(row).write(to:url,options:.atomic)
    }
    static func delta(before: ChestRecord, after: ChestRecord) throws -> [String:Int] {
        guard before.id==after.id,before.readable,after.readable else { throw OreError("Readable matching chest required / Lesbare identische Truhe erforderlich") }
        var delta:[String:Int]=[:]
        for item in after.items {delta[String(item.itemID),default:0] += item.quantity}
        for item in before.items {delta[String(item.itemID),default:0] -= item.quantity}
        return delta.filter{$0.value != 0}
    }
}

struct OreRank {
    let row: OreLevel
    let tiedHeights: [Int]
}
enum OreRanking {
    static func topThree(_ levels:[OreLevel],ore:String,nonAirOnly:Bool)->[OreRank] {
        let rows=levels.filter{($0.ores[ore] ?? 0)>0 && $0.rate(ore,nonAirOnly:nonAirOnly) != nil}
            .sorted { a,b in
                let ar=a.rate(ore,nonAirOnly:nonAirOnly)!,br=b.rate(ore,nonAirOnly:nonAirOnly)!
                return abs(ar-br)<1e-12 ? a.y<b.y : ar>br
            }
        return rows.prefix(3).map { row in
            OreRank(row:row,tiedHeights:rows.filter {abs($0.rate(ore,nonAirOnly:nonAirOnly)!-row.rate(ore,nonAirOnly:nonAirOnly)!)<1e-12}.map(\.y).sorted())
        }
    }
}

enum OreLayerNavigation {
    static func next(current: Int, available: [Int], direction: Int) -> Int? {
        let heights = Array(Set(available)).sorted()
        guard !heights.isEmpty, direction != 0 else { return nil }
        if direction > 0 { return heights.first(where: { $0 > current }) ?? heights[0] }
        return heights.reversed().first(where: { $0 < current }) ?? heights[heights.count - 1]
    }
}


/// Snapshot-only, little-endian UInt16 cells, ordered Y → Z → X. 65535 is missing.
struct OreSpatial: Codable {
    let encoding: String
    let data: Data
    func cell(x: Int, y: Int, z: Int, bounds b: [Int]) -> Int? {
        guard encoding == "u16le-yzx-v1", b.count == 6,
              b.allSatisfy({abs(Double($0)) <= 30_000_000}),
              b[0] <= x, x <= b[1], b[2] <= y, y <= b[3], b[4] <= z, z <= b[5],
              b[1]-b[0] < 65536, b[5]-b[4] < 65536, b[3]-b[2] < 256 else { return nil }
        let index = ((y-b[2])*(b[5]-b[4]+1)*(b[1]-b[0]+1)+(z-b[4])*(b[1]-b[0]+1)+x-b[0])*2
        guard index >= 0, index+1 < data.count else { return nil }
        let value = Int(data[index]) | Int(data[index+1]) << 8
        return value == 65535 ? nil : value
    }
}
struct OreArea: Codable, Identifiable {
    let x0: Int, x1: Int, z0: Int, z1: Int, blocks: Int
    let materials: [String: Int]
    var id: String { "\(x0),\(z0)" }
    func count(_ ids: Set<String>) -> Int { ids.reduce(0) { $0 + (materials[$1] ?? 0) } }
}

extension OreSpatial {
    /// Four face neighbors in one horizontal layer; unknown/outside cells break connectivity.
    func connectedCount(x: Int, y: Int, z: Int, bounds b: [Int], blockIDs: Set<Int>) -> Int {
        guard let first = cell(x:x,y:y,z:z,bounds:b), blockIDs.contains(first), b.count == 6 else { return 0 }
        let width = b[1]-b[0]+1
        guard width > 0, (b[5]-b[4]+1) > 0, width*(b[5]-b[4]+1) <= 65536 else { return 0 }
        var queue = [(x,z)], visited: Set<Int> = [(z-b[4])*width+x-b[0]], cursor = 0
        while cursor < queue.count {
            let (cx,cz) = queue[cursor]; cursor += 1
            for (nx,nz) in [(cx-1,cz),(cx+1,cz),(cx,cz-1),(cx,cz+1)] {
                guard let id = cell(x:nx,y:y,z:nz,bounds:b), blockIDs.contains(id) else { continue }
                if visited.insert((nz-b[4])*width+nx-b[0]).inserted { queue.append((nx,nz)) }
            }
        }
        return queue.count
    }
}

extension OreArea {
    static func grouped(_ areas: [OreArea], size: Int, bounds: [Int]? = nil) -> [OreArea] {
        guard [16,64].contains(size) else { return [] }
        let groups = Dictionary(grouping:areas) { a in
            "\(Int(floor(Double(a.x0)/Double(size)))):\(Int(floor(Double(a.z0)/Double(size))))"
        }
        return groups.values.compactMap { values in
            guard let first = values.first else { return nil }
            let tileX = Int(floor(Double(first.x0)/Double(size))) * size
            let tileZ = Int(floor(Double(first.z0)/Double(size))) * size
            var x0=max(tileX, bounds?[0] ?? first.x0), x1=min(tileX+size-1, bounds?[1] ?? first.x1)
            var z0=max(tileZ, bounds?[4] ?? first.z0), z1=min(tileZ+size-1, bounds?[5] ?? first.z1), blocks=0
            if bounds == nil { x0=first.x0;x1=first.x1;z0=first.z0;z1=first.z1 }
            var totals: [String:Int] = [:]
            for a in values {
                x0=min(x0,a.x0);x1=max(x1,a.x1);z0=min(z0,a.z0);z1=max(z1,a.z1);blocks += a.blocks
                for (key,value) in a.materials { totals[key,default:0] += value }
            }
            return OreArea(x0:x0,x1:x1,z0:z0,z1:z1,blocks:blocks,materials:totals)
        }
    }
}

extension OreScan {
    func validateDisplay() throws {
        guard bounds.count == 6, ["o","n"].contains(dimension),
              bounds.allSatisfy({abs(Double($0)) <= 30_000_000}),
              bounds[0] <= bounds[1], bounds[4] <= bounds[5], 0 <= bounds[2], bounds[2] <= bounds[3], bounds[3] <= 255,
              Set(levels.map(\.y)).count == levels.count,
              levels.allSatisfy({ $0.y >= bounds[2] && $0.y <= bounds[3] && $0.blocks >= 0 && $0.nonAir >= 0 && $0.nonAir <= $0.blocks }) else {
            throw OreError("Invalid measurement geometry / Ungültige Messgeometrie")
        }
        if let spatial {
            let size = Double(bounds[1]-bounds[0]+1)*Double(bounds[3]-bounds[2]+1)*Double(bounds[5]-bounds[4]+1)
            guard spatial.encoding == "u16le-yzx-v1", size <= 4_194_304, spatial.data.count == Int(size)*2 else { throw OreError("Invalid layer data / Ungültige Schichtdaten") }
        }
    }
}
