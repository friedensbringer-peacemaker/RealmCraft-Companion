import Foundation

struct MobText: Codable {
    let de: String
    let en: String
    func value(_ english: Bool) -> String { english ? en : de }
}

struct MobEntry: Codable, Identifiable {
    let id: String
    let name: MobText
    let kind: String
    let status: String
    let evidenceLabel: String
    let evidenceURL: URL
    let note: MobText
    let realmWikiURL: URL?
    let minecraftURL: URL
    let habitat: MobHabitat?

    func matches(_ query: String) -> Bool {
        let words = query.split(whereSeparator: \.isWhitespace)
        let content = ([id, name.de, name.en, note.de, note.en, evidenceLabel] + (habitat?.searchTerms ?? [])).joined(separator: " ")
        return words.allSatisfy { content.localizedCaseInsensitiveContains($0) }
    }
    func statusTitle(_ english: Bool) -> String {
        switch status {
        case "released": return english ? "VR · release documented" : "VR · Veröffentlichung belegt"
        case "planned": return english ? "VR · in progress" : "VR · in Arbeit"
        default: return english ? "VR · unconfirmed" : "VR · unbestätigt"
        }
    }
}

struct MobHabitat: Codable {
    let dimension: String
    let basis: String
    let biomes: MobText
    let reference: MobText
    let sourceURL: URL

    func dimensionTitle(_ english: Bool) -> String {
        switch dimension {
        case "overworld": return english ? "Overworld" : "Overworld (Oberwelt)"
        case "nether": return "Nether"
        default: return english ? "Not established" : "Nicht belegt"
        }
    }
    func basisTitle(_ english: Bool) -> String {
        switch basis {
        case "vr_release": return english ? "Dimension documented in VR update; spawn rules unverified." : "Dimension im VR-Update belegt; Spawnregeln ungeprüft."
        case "realmcraft_wiki": return english ? "General RealmCraft wiki reference; VR location unconfirmed." : "Orientierung aus dem allgemeinen RealmCraft-Wiki; VR-Fundort unbestätigt."
        case "minecraft": return english ? "Minecraft comparison only; VR location unconfirmed." : "Nur Minecraft-Vergleich; VR-Fundort unbestätigt."
        default: return english ? "No confirmed RealmCraft VR location." : "Kein bestätigter RealmCraft-VR-Fundort."
        }
    }
    var searchTerms: [String] {
        [dimension, dimensionTitle(false), dimensionTitle(true), biomes.de, biomes.en, reference.de, reference.en]
    }
    var isValid: Bool {
        ["overworld", "nether", "unknown"].contains(dimension)
        && ["vr_release", "realmcraft_wiki", "minecraft", "unknown"].contains(basis)
        && sourceURL.scheme == "https" && !biomes.de.isEmpty && !biomes.en.isEmpty
        && !(basis == "vr_release" && dimension == "unknown")
    }
}

struct MobCatalog: Codable {
    let schemaVersion: Int
    let reviewedAt: String
    let aiGenerated: Bool
    let entries: [MobEntry]

    static func disclaimer(_ english: Bool) -> String {
        english ? "AI-generated data — may be incorrect and may not reflect the actual game. Sources do not guarantee accuracy."
            : "KI-generierte Daten – können falsch sein und vom tatsächlichen Spiel abweichen. Auch Quellen garantieren keine Richtigkeit."
    }

    func validate() throws {
        guard schemaVersion == 1, aiGenerated, !entries.isEmpty,
              Set(entries.map(\.id)).count == entries.count,
              entries.allSatisfy({ entry in
                  ["animal", "mob"].contains(entry.kind) && ["released", "planned", "unverified"].contains(entry.status)
                  && !entry.name.de.isEmpty && !entry.name.en.isEmpty && !entry.evidenceLabel.isEmpty
                  && entry.evidenceURL.scheme == "https" && entry.minecraftURL.host == "minecraft.wiki"
                  && (entry.realmWikiURL == nil || entry.realmWikiURL?.host == "realmcraftgame.fandom.com")
                  && (entry.habitat?.isValid ?? true)
              }) else { throw NSError(domain: "MobCatalog", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Mobs.json catalog"]) }
    }

    static func load() throws -> MobCatalog {
        guard let url = Bundle.main.url(forResource: "Mobs", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let catalog = try JSONDecoder().decode(MobCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }
}

// Explicitly allowlisted original-model previews. Baby references never masquerade as baby artwork.
enum MobArtwork {
    static let available: Set<String> = ["cow", "pig", "sheep", "bee", "cat", "wolf", "ocelot", "llama", "parrot", "pufferfish", "turtle", "villager", "iron_golem", "zombie", "drowned", "creeper", "ghast", "piglin", "piglin_brute", "zombified_piglin", "hoglin", "zoglin", "chicken", "rabbit"]
    static func referenceID(for id: String) -> String? {
        let base = id.hasPrefix("baby_") ? String(id.dropFirst(5)) : id
        return available.contains(base) ? base : nil
    }
    static func url(for id: String, resources: URL? = Bundle.main.resourceURL) -> URL? {
        guard let base = referenceID(for: id), let resources else { return nil }
        let url = resources.appendingPathComponent("MobImages/\(base).png")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
