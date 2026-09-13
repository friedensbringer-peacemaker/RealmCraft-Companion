import Foundation

struct MetroCarryForward {
    struct Snapshot {
        let id: String
        let world: String
        let date: Date
        let worldFolder: URL
        let networkURL: URL
    }
    enum Failure: LocalizedError {
        case incompatible, targetNotEmpty, changed
        var errorDescription: String? {
            switch self {
            case .incompatible: return "Choose an older backup of the same world / Ältere Sicherung derselben Welt wählen."
            case .targetNotEmpty: return "Target network must be empty / Das Zielnetz muss leer sein."
            case .changed: return "Source or portal evidence changed; preview again / Quelle oder Portalbelege geändert; Vorschau erneut öffnen."
            }
        }
    }
    struct Review: Identifiable {
        let id = UUID()
        let source: Snapshot
        let target: Snapshot
        let original: MetroNetworkStore.Document
        let proposal: MetroNetworkStore.Document
        let sourceFingerprint: String
        let targetFingerprint: String
        let portalChanges: [String]
    }
    static func store(_ save: Snapshot) -> MetroNetworkStore {
        MetroNetworkStore(url: save.networkURL)
    }
    static func prepare(source: Snapshot, target: Snapshot) throws -> Review {
        guard source.id != target.id, source.world == target.world, source.date < target.date else {
            throw Failure.incompatible
        }
        let original = try store(source).load()
        let existing = try store(target).load()
        guard !original.stations.isEmpty, existing.stations.isEmpty, existing.lines.isEmpty, existing.edges.isEmpty else {
            throw Failure.targetNotEmpty
        }
        let before = try PortalReader.read(source.worldFolder)
        let after = try PortalReader.read(target.worldFolder)
        var proposal = original
        var changes: [String] = []
        for index in proposal.stations.indices {
            let station = proposal.stations[index]
            // A new snapshot needs fresh travel confirmation even when portal geometry matches.
            proposal.stations[index].status = .planned
            if let portalID = station.portalID {
                let old = before.portals.first { $0.id == portalID }
                let new = after.portals.first { $0.id == portalID }
                if old == nil || new == nil || old?.blocks != new?.blocks {
                    proposal.stations[index].portalID = nil
                    changes.append(station.name)
                }
            }
        }
        for index in proposal.edges.indices { proposal.edges[index].status = .planned }
        return Review(source: source, target: target, original: original, proposal: proposal,
                      sourceFingerprint: before.fingerprint, targetFingerprint: after.fingerprint, portalChanges: changes)
    }
    static func apply(_ review: Review) throws {
            let current = try prepare(source: review.source, target: review.target)
            guard current.original == review.original,
                  current.sourceFingerprint == review.sourceFingerprint,
                  current.targetFingerprint == review.targetFingerprint else {
                throw Failure.changed
            }
            try store(review.target).save(review.proposal, replacing: .init(stations: [], lines: [], edges: []))
    }
}
