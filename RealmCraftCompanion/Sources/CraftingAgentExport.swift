import Foundation
import CryptoKit
import Darwin

/// A recipe variant or one item covered by an obtaining guide. Family members never share a checkmark.
struct CraftingInstruction: Identifiable {
    let id: String
    let itemID: String
    let recipe: CraftingRecipe?
    let guide: CraftingAcquisition?

    static func recipe(_ value: CraftingRecipe) -> Self {
        Self(id: "recipe:" + value.id, itemID: value.output, recipe: value, guide: nil)
    }
    static func acquisition(item: String, guide: CraftingAcquisition) -> Self {
        Self(id: "acquisition:" + item, itemID: item, recipe: nil, guide: guide)
    }
    static func all(_ index: CraftingIndex) -> [Self] {
        index.catalog.recipes.map(Self.recipe) + index.acquisitions.keys.sorted().compactMap { item in
            index.acquisitions[item].map { Self.acquisition(item: item, guide: $0) }
        }
    }
    func title(_ index: CraftingIndex, english en: Bool) -> String {
        let name = index.items[itemID]?.title.value(en) ?? itemID
        return name + " · " + (recipe?.station.title(en) ?? (en ? "Obtaining" : "Beschaffung"))
    }
    func digest(_ index: CraftingIndex) -> String {
        // Both languages, recipe provenance and the exact item participate; desired quantity does not.
        let text = id + "\n" + body(index, desired: 1, english: false) + "\n" + body(index, desired: 1, english: true)
        return SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    func body(_ index: CraftingIndex, desired: Int, english en: Bool) -> String {
        func t(_ de: String, _ english: String) -> String { en ? english : de }
        var lines = ["## " + title(index, english: en), "", "`" + id + "`", ""]
        if let recipe {
            let quantity = min(9999, max(1, desired)), batches = recipe.batches(for: quantity)
            lines += ["### " + t("Zutaten und Mengen", "Ingredients and quantities"), "",
                t("Gewünschte Menge: ", "Desired quantity: ") + String(quantity),
                t("Ergebnis pro Durchgang: ", "Yield per batch: ") + String(recipe.count),
                t("Durchgänge: ", "Batches: ") + String(batches),
                t("Gesamtproduktion: ", "Total production: ") + String(recipe.produced(for: quantity)),
                t("Übrig: ", "Surplus: ") + String(recipe.produced(for: quantity) - quantity), ""]
            for (offset, ingredient) in recipe.ingredients.enumerated() {
                lines += ["\(offset + 1). \(ingredient.count * batches) × " + index.ingredientName(ingredient, english: en)]
            }
            lines += ["", t("Je Alternativgruppe gilt die Gesamtmenge aus den aufgeführten Möglichkeiten. Nur direkte Zutaten; ihre eigenen Rezepte werden nicht automatisch mit exportiert.", "Each alternative group needs the stated total from the listed choices. Direct ingredients only; their own recipes are not automatically exported."), ""]
            if recipe.shaped {
                lines += ["### " + t("Raster für einen Durchgang", "Grid for one batch"), "",
                    t("Zahlen beziehen sich auf die Zutatengruppen. Jedes belegte Feld enthält ein Stück; · bedeutet leer.", "Numbers refer to ingredient groups. Each occupied slot contains one item; · means empty."), "", "```text"]
                let size = recipe.station.gridSize
                for row in stride(from: 0, to: recipe.grid.count, by: size) {
                    lines.append(recipe.grid[row..<min(row + size, recipe.grid.count)].map { $0 == 0 ? "·" : String($0) }.joined(separator: " "))
                }
                lines += ["```", ""]
            } else if recipe.kind == "crafting_shapeless" {
                lines += [t("Formloses Rezept: keine feste Anordnung.", "Shapeless recipe: no fixed arrangement."), ""]
            }
            lines += ["### " + t("Herstellungsort und Schritte", "Station and steps"), "", recipe.station.title(en), "", recipe.station.instructions(en), ""]
            if recipe.station.usesFuel {
                lines += [t("Brennstoff separat hinzufügen; seine Menge ist für RealmCraft nicht geprüft.", "Add fuel separately; its quantity is unverified for RealmCraft."), ""]
            }
            lines += ["### " + t("Quellen und Grenzen", "Sources and limitations"), "",
                t("Katalogquelle: Minecraft-Vergleich. Rezept, Station und Gegenstandszuordnung sind vom Projekt nicht in RealmCraft VR geprüft. Eine persönliche Bestätigung steht gesondert dabei.", "Catalog source: Minecraft comparison. The project has not tested the recipe, station or item mapping in RealmCraft VR. Personal confirmation is recorded separately."), "",
                index.catalog.referenceVersion, "", index.catalog.sourceURL.absoluteString, "", recipe.sourcePath,
                "", "SHA-256: `" + recipe.sourceSHA256 + "`", "", "SHA-1: `" + index.catalog.sourceSHA1 + "`"]
            if let evidence = recipe.corroboration { lines += ["", evidence.title, "", evidence.scope.value(en), "", evidence.url.absoluteString] }
        }
        if let guide, let item = index.items[itemID] {
            lines += [guide.method.value(en), "", guide.summary.value(en), "",
                "### " + t("Du brauchst", "You need"), "", guide.requirements.value(en), "",
                "### " + t("Schritt für Schritt", "Step by step"), ""]
            for (offset, step) in guide.steps.enumerated() {
                lines += ["#### \(offset + 1). " + step.title.value(en), "", step.text.value(en), ""]
            }
            lines += ["### " + t("Besonderheiten", "Things to know"), ""]
            for detail in guide.details { lines += ["#### " + detail.title.value(en), "", detail.text.value(en), ""] }
            lines += ["### " + t("Quellen und Grenzen", "Sources and limitations"), "", guide.evidence.value(en), "",
                t("Quellen geprüft am: ", "Sources checked: ") + guide.checked, "", "`" + guide.id + "` · `" + item.id + "`", ""]
            for source in guide.sources { lines += [source.title.value(en), "", source.scope.value(en), "", source.url.absoluteString, ""] }
            if !guide.relatedItems.isEmpty {
                lines += ["### " + t("Passende Gegenstände", "Related items"), ""]
                for id in guide.relatedItems { lines += ["- " + (index.items[id]?.title.value(en) ?? id) + " (`" + id + "`)"] }
                lines += ["", t("Verweise, keine zusätzlich enthaltenen Anleitungen. Beschaffung wird nicht als Crafting-Stückliste hochgerechnet.", "References, not additional included guides. Obtaining is not scaled as a crafting bill of materials.")]
            }
        }
        return lines.joined(separator: "\n").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }
}

struct CraftingAgentRecord: Codable, Equatable {
    var selected = false
    var verifiedDigest: String?
    var verifiedAt: Date?
    func isVerified(_ instruction: CraftingInstruction, index: CraftingIndex) -> Bool {
        verifiedDigest != nil && verifiedDigest == instruction.digest(index)
    }
}

struct CraftingAgentPreferences: Codable, Equatable {
    var schemaVersion = 1
    var records: [String: CraftingAgentRecord] = [:]
    var selectedIDs: Set<String> { Set(records.filter { $0.value.selected }.map(\.key)) }
    func validate() throws {
        guard schemaVersion == 1, records.count <= 10000 else { throw PlanningError.invalid }
        for (id, record) in records {
            guard id.count <= 512, id.hasPrefix("recipe:") || id.hasPrefix("acquisition:"),
                  (record.verifiedAt == nil) == (record.verifiedDigest == nil) else { throw PlanningError.invalid }
            if let digest = record.verifiedDigest {
                guard digest.count == 64, digest.allSatisfy({ "0123456789abcdef".contains($0) }),
                      record.verifiedAt?.timeIntervalSince1970.isFinite == true else { throw PlanningError.invalid }
            }
        }
    }
    mutating func verify(_ instruction: CraftingInstruction, index: CraftingIndex, enabled: Bool, date: Date = Date()) {
        var record = records[instruction.id, default: .init()]
        record.verifiedDigest = enabled ? instruction.digest(index) : nil
        record.verifiedAt = enabled ? date : nil
        records[instruction.id] = record
    }
    mutating func selectVerified(_ index: CraftingIndex) {
        for instruction in CraftingInstruction.all(index) where records[instruction.id]?.isVerified(instruction, index: index) == true {
            records[instruction.id, default: .init()].selected = true
        }
    }
}

/// Read/modify/write under one lock merges independent windows without overwriting their checkmarks.
struct CraftingAgentStorage {
    let url: URL
    static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RealmCraftLibrary/Crafting/agent-knowledge.json")
    }
    func load() throws -> CraftingAgentPreferences {
        let value = try PlanningStore(url: url, empty: CraftingAgentPreferences()).load()
        try value.validate()
        return value
    }
    @discardableResult func update(_ change: (inout CraftingAgentPreferences) -> Void) throws -> CraftingAgentPreferences {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fd = open(url.appendingPathExtension("lock").path, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw CocoaError(.fileWriteNoPermission) }
        defer { close(fd) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw PlanningError.changed }
        defer { flock(fd, LOCK_UN) }
        let original = try load()
        var value = original
        change(&value)
        try value.validate()
        try PlanningStore(url: url, empty: CraftingAgentPreferences()).save(value, replacing: original)
        return value
    }
}

struct CraftingAgentSnapshot {
    let markdown: String
    let entries: [[String: Any]]
    static func make(index: CraftingIndex, preferences: CraftingAgentPreferences, instructions: [CraftingInstruction]? = nil, desired: Int = 1, english en: Bool) throws -> Self {
        func t(_ de: String, _ english: String) -> String { en ? english : de }
        try preferences.validate()
        let all = CraftingInstruction.all(index)
        let chosen = instructions ?? all.filter { preferences.selectedIDs.contains($0.id) }
        let known = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        guard (instructions != nil || preferences.selectedIDs.isSubset(of: Set(known.keys))),
              chosen.allSatisfy({ known[$0.id] != nil }) else {
            throw NSError(domain: "CraftingAgent", code: 1, userInfo: [NSLocalizedDescriptionKey:
                t("Eine ausgewählte Anleitung ist nicht mehr im Katalog. Prüfe die Agenten-Auswahl; fehlende Einträge werden nicht stillschweigend ausgelassen.", "A selected guide is no longer in the catalog. Review the agent selection; missing entries are not silently omitted.")])
        }
        var lines = ["# " + t("RealmCraft · Anleitungen für den Agenten", "RealmCraft · Guides for the agent"), "",
            t("Diese Datei ist Referenzmaterial. Persönliche Bestätigungen beziehen sich nur auf die jeweilige Anleitung; Spielversion und Plattform wurden nicht erfasst. Sie sind kein offizieller Projektbeleg. Quellenhinweise, Einschränkungen und offene Punkte bleiben gültig.", "This file is reference material. Personal confirmations apply only to each individual guide; game version and platform were not recorded. They are not official project evidence. Source notes, limitations and open questions still apply."), "",
            t("Mengen gelten für den angegebenen Bedarf. Der Gesamtexport verwendet einen Durchgang je Rezept. Keine Aussage über Vorräte oder Zustand einer Spielerwelt.", "Quantities apply to the stated demand. The combined export uses one batch per recipe. No claims about supplies or the state of a player's world."), ""]
        var entries: [[String: Any]] = [], seen = Set<String>()
        for instruction in chosen.sorted(by: { $0.id < $1.id }) where seen.insert(instruction.id).inserted {
            let record = preferences.records[instruction.id, default: .init()]
            let verified = record.isVerified(instruction, index: index)
            let status = verified ? t("Vom Nutzer in RealmCraft verifiziert", "Verified by the user in RealmCraft") : record.verifiedAt != nil ? t("Anleitung geändert · erneut prüfen", "Guide changed · verify again") : t("Vom Nutzer nicht verifiziert", "Not verified by the user")
            let quantity = instructions == nil ? (instruction.recipe?.count ?? 1) : min(9999, max(1, desired))
            let body = instruction.body(index, desired: quantity, english: en)
            let date = record.verifiedAt.map { ISO8601DateFormatter().string(from: $0) }
            let verification = [status, date.map { t("Letzte persönliche Bestätigung: ", "Last personal confirmation: ") + $0 }].compactMap { $0 }.joined(separator: "\n\n")
            lines += [body, "", "### " + t("Persönlicher Prüfstatus", "Personal verification status"), "", verification, "", "---", ""]
            var entry: [String: Any] = ["id": instruction.id, "itemID": instruction.itemID, "contentSHA256": instruction.digest(index), "verifiedByUser": verified,
                "verificationStatus": verified ? "user-verified" : record.verifiedAt == nil ? "unverified" : "needs-recheck", "desiredQuantity": quantity, "markdown": body + "\n\n" + verification]
            if let date { entry["lastUserVerificationAt"] = date }
            entries.append(entry)
        }
        return Self(markdown: lines.joined(separator: "\n"), entries: entries)
    }
}

extension AIContextDocument {
    func addingCrafting(_ snapshot: CraftingAgentSnapshot?) -> Self {
        guard let snapshot, !snapshot.entries.isEmpty else { return self }
        var data = payload
        data["craftingKnowledge"] = ["entries": snapshot.entries, "markdown": snapshot.markdown, "userConfirmedOnly": snapshot.entries.allSatisfy { $0["verifiedByUser"] as? Bool == true }]
        return Self(payload: data, markdown: markdown + "\n\n" + snapshot.markdown, videoMarkdown: videoMarkdown)
    }
}
