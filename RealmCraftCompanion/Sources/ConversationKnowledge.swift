import Foundation

struct CompanionPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let dimension: String
    let x: Int, y: Int, z: Int

    static func named(_ names: [String: String]) -> [CompanionPlace] {
        names.compactMap { id, name in
            let parts = id.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 3, ["o", "n"].contains(String(parts[0])),
                  ["building", "chest", "bed", "glass", "workbench", "furnace"].contains(String(parts[1])),
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            let coordinates = parts[2].split(separator: ",").compactMap { Int($0) }
            guard coordinates.count == 3 else { return nil }
            return CompanionPlace(id: id, name: name, dimension: String(parts[0]), x: coordinates[0], y: coordinates[1], z: coordinates[2])
        }.sorted { $0.name == $1.name ? $0.id < $1.id : $0.name < $1.name }
    }
    func description(_ en: Bool) -> String {
        let dim = dimension == "o" ? (en ? "Overworld" : "Oberwelt") : "Nether"
        return "\(name): X \(x), Y \(y), Z \(z) · \(dim)."
    }
}

struct ConversationRecipe: Decodable, Identifiable {
    let id: String
    let title: BuildText
    let aliases: [String]
    let materials: BuildText
    let steps: BuildText
    let source: BuildSource
    let evidence: BuildText
    static func load() throws -> [ConversationRecipe] {
        guard let url = Bundle.main.url(forResource: "ConversationRecipes", withExtension: "json") else { throw BuildCatalog.CatalogError.invalid }
        let recipes = try JSONDecoder().decode([ConversationRecipe].self, from: Data(contentsOf: url))
        guard !recipes.isEmpty, Set(recipes.map(\.id)).count == recipes.count,
              recipes.allSatisfy({ !$0.aliases.isEmpty && $0.source.url.scheme == "https" && !$0.materials.de.isEmpty && !$0.materials.en.isEmpty }) else { throw BuildCatalog.CatalogError.invalid }
        return recipes
    }
}

struct CompanionAnswer {
    let text: String
    var sources: [BuildSource] = []
    var handled = true
    var spokenText: String?
}

/// Local retrieval only: no generated game facts, live position inference or game writes.
struct ConversationKnowledge {
    let recipes: [ConversationRecipe]
    let guides: [BuildGuide]
    let videoTips: [VideoTip]
    private(set) var lastRecipe: String?
    private(set) var lastGuide: String?
    private(set) var lastPlace: String?
    private var lastStorageItem: Int?
    private var scope = ""
    private var lastAnswer: CompanionAnswer?
    var crafting: CraftingConversation?
    private var usedCrafting = false

    init(recipes: [ConversationRecipe], guides: [BuildGuide], videoTips: [VideoTip] = VideoTip.bundled ?? [], craftingIndex: CraftingIndex? = nil) {
        self.recipes = recipes; self.guides = guides; self.videoTips = videoTips
        crafting = craftingIndex.map { CraftingConversation(index: $0) }
    }
    mutating func reset() {
        lastRecipe = nil; lastGuide = nil; lastPlace = nil; lastStorageItem = nil; lastAnswer = nil
        crafting?.lastItem = nil; crafting?.lastQuantity = 1; crafting?.lastRecipeID = nil
    }
    mutating func remember(_ answer: CompanionAnswer, world: String?, english: Bool) {
        reset(); scope = (world ?? "") + (english ? ":en" : ":de"); lastAnswer = answer
    }
    static func normalized(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE"))
        return folded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }
    static func contains(_ text: String, phrase: String) -> Bool {
        (" " + text + " ").contains(" " + normalized(phrase) + " ")
    }
    mutating func answer(_ question: String, world: String?, places: [CompanionPlace], english en: Bool, storage: CompanionStorageContext? = nil, spawn: CompanionSpawnPoint? = nil, spawnNotice: String = "") -> CompanionAnswer {
        let newScope = (world ?? "") + (en ? ":en" : ":de")
        if scope != newScope { reset(); scope = newScope }
        usedCrafting = false
        let answer = respond(question, world: world, places: places, english: en, storage: storage, spawn: spawn, spawnNotice: spawnNotice)
        if !usedCrafting { crafting?.lastItem = nil }
        lastAnswer = answer
        return answer
    }
    private mutating func respond(_ question: String, world: String?, places: [CompanionPlace], english en: Bool, storage: CompanionStorageContext? = nil, spawn: CompanionSpawnPoint? = nil, spawnNotice: String = "") -> CompanionAnswer {
        let q = Self.normalized(question)
        func has(_ phrases: [String]) -> Bool { phrases.contains { Self.contains(q, phrase: $0) } }
        func result(_ de: String, _ english: String, handled: Bool = true) -> CompanionAnswer { CompanionAnswer(text: en ? english : de, handled: handled) }
        if has(["wiederholen", "noch einmal", "nochmal", "repeat", "say that again"]), let lastAnswer { usedCrafting = crafting?.lastItem != nil; return lastAnswer }
        let videoRequest = has(["video", "videos", "videotipps", "video tipps", "tipps", "anleitung", "guide", "tutorial", "wie baue ich", "how do i build"])
        let allVideoMatches = videoTips.filter { tip in
            (tip.aliases + [tip.title.de, tip.title.en]).contains { alias in
                let normalized = Self.normalized(alias)
                return q == normalized || (videoRequest && Self.contains(q, phrase: alias))
            }
        }
        let curatedMatches = allVideoMatches.filter(\.isCurated)
        let videoMatches = curatedMatches.isEmpty ? allVideoMatches : curatedMatches
        if videoRequest && has(["welche videos", "welche videotipps", "welche video tipps", "list videos", "video guides"]) && videoMatches.isEmpty {
            return CompanionAnswer(text: (en ? "Video guides: " : "Video-Anleitungen: ") + videoTips.prefix(12).map { $0.title.value(en) }.joined(separator: ", ") + (videoTips.count > 12 ? (en ? ". Browse all \(videoTips.count) entries in Videos & tips." : ". Alle \(videoTips.count) Einträge findest du unter Videos & Tipps.") : ""), sources: videoTips.prefix(12).map { BuildSource(title: $0.title.value(en), url: $0.videoURL) })
        }
        if !videoMatches.isEmpty {
            lastRecipe = nil; lastGuide = nil; lastPlace = nil; lastStorageItem = nil
            if videoMatches.count > 1 {
                return CompanionAnswer(text: (en ? "Which video guide? " : "Welche Video-Anleitung? ") + videoMatches.prefix(8).map { $0.title.value(en) }.joined(separator: ", ") + (videoMatches.count > 8 ? (en ? ". More matches in Videos & tips." : ". Weitere Treffer unter Videos & Tipps.") : ""), sources: videoMatches.prefix(8).map { BuildSource(title: $0.title.value(en), url: $0.videoURL) })
            }
            let tip = videoMatches[0]
            let steps = tip.steps.enumerated().map { "\($0.offset + 1). \($0.element.title.value(en)): \($0.element.text.value(en))" }.joined(separator: "\n")
            return CompanionAnswer(text: tip.title.value(en) + "\n" + tip.summary.value(en) + "\n\n" + steps + "\n\n" + (en ? "Source: TarantNET Gaming. " : "Quelle: TarantNET Gaming. ") + (tip.sourceScope?.value(en) ?? (en ? "PCVR/Steam; Quest untested. " : "PCVR/Steam; Quest ungetestet. ")) + " " + tip.limitations.value(en), sources: tip.steps.isEmpty ? [BuildSource(title: tip.title.value(en), url: tip.videoURL)] : tip.steps.map { BuildSource(title: VideoTip.time($0.seconds) + " · " + $0.title.value(en), url: tip.url(at: $0.seconds)) })
        }
        if has(["spawn", "spawnpunkt", "spawn point", "respawn", "respawnpunkt", "respawn point", "wiedereinstiegspunkt"]) {
            guard world != nil else { return result("Wähle zuerst einen Spielstand für den gespeicherten Spawnpunkt.", "Choose a savegame to read its saved spawn point.") }
            let provenance = storage.map { context -> String in
                let formatter = DateFormatter(); formatter.locale = Locale(identifier: en ? "en_GB" : "de_AT"); formatter.dateStyle = .medium; formatter.timeStyle = .short
                return en ? " Savegame dated \(formatter.string(from: context.savedAt)); backup dated \(formatter.string(from: context.backupAt)). These data may be inaccurate or out of date." : " Spielstand vom \(formatter.string(from: context.savedAt)); Sicherung vom \(formatter.string(from: context.backupAt)). Diese Daten können ungenau oder veraltet sein."
            } ?? ""
            guard let spawn else {
                return CompanionAnswer(text: (spawnNotice.isEmpty ? (en ? "The saved respawn point is unavailable for this save format. I won't substitute a bed or the world origin." : "Der gespeicherte Respawnpunkt ist für dieses Speicherformat nicht verfügbar. Ich ersetze ihn nicht durch ein Bett oder den Weltursprung.") : spawnNotice) + provenance)
            }
            lastStorageItem = nil; lastPlace = nil; lastRecipe = nil; lastGuide = nil
            return CompanionAnswer(text: (en ? "Saved respawn coordinates: " : "Gespeicherte Respawn-Koordinaten: ") + "X \(spawn.x), Y \(spawn.y), Z \(spawn.z)." + (en ? " The dimension and whether this respawn point is still usable are not decoded." : " Die Dimension und ob dieser Respawnpunkt noch nutzbar ist, werden noch nicht ausgelesen.") + provenance)
        }
        let craftCheck = (has(["kann ich", "can i"]) && has(["craften", "craft", "bauen", "build", "herstellen", "make"])) || has(["habe ich genug", "habe ich ausreichend", "habe ich genugend", "besitze ich genug", "habe ich alles", "reicht", "reichen", "fehlt", "fehlen", "can i craft", "can i make", "enough", "missing materials", "check materials", "materialcheck", "was fehlt mir dafur"])
        let materialLocations = (lastRecipe != nil && ["wo genau", "where exactly"].contains(q)) || ["wo liegen die materialien", "wo finde ich die zutaten", "where are the materials", "where are the ingredients"].contains(q)
        if craftCheck || materialLocations {
            let named = recipes.filter { recipe in (recipe.aliases + [recipe.title.de, recipe.title.en]).contains { Self.contains(q, phrase: $0) } }
            let generic = ["kann ich das craften", "kann ich das bauen", "was fehlt mir dafur", "was fehlt noch", "reicht das", "can i craft it", "can i make it", "what am i missing", "check materials"].contains(q)
            let recipe = named.count == 1 ? named.first : ((generic || materialLocations) ? recipes.first { $0.id == lastRecipe } : nil)
            guard let recipe else { lastRecipe = nil; return result("Für welches Rezept soll ich die Materialien prüfen? Zum Beispiel: Kann ich ein Bett craften?", "Which recipe should I check? For example: Can I craft a bed?", handled: false) }
            guard world != nil, let storage else { return result("Wähle zuerst einen Spielstand und lies deine eigenen Kisten ein.", "Choose a savegame and read your own chests first.") }
            if has(["zwei", "drei", "vier", "two", "three", "four"]) || q.split(separator: " ").contains(where: { (Int($0) ?? 0) > 1 }) {
                return result("Der Materialcheck unterstützt derzeit eine Rezeptausführung pro Frage. Frage zum Beispiel: Kann ich ein Bett craften?", "The material check currently supports one recipe execution per question. Try: Can I craft a bed?")
            }
            lastRecipe = recipe.id; lastStorageItem = nil; lastPlace = nil; lastGuide = nil
            return storage.craft(recipe, english: en, locations: materialLocations)
        }
        let storageQuestion = has(["wie viele", "wieviele", "wie viel", "wieviel", "how many", "how much", "habe ich", "do i have", "in meinen kisten", "in my chests"]) && !has(["brauche", "benotige", "need for", "need to craft"])
        let storageFollowup = ["wo genau", "wo sind die", "wo liegen die", "welche kisten", "where exactly", "where are they", "which chests"].contains(q)
        if storageQuestion || (storageFollowup && lastStorageItem != nil) {
            guard let storage, world != nil else { return result("Wähle zuerst einen Spielstand und lies unter Eigene Kisten den Kistenbestand ein. Ohne diese Daten kann ich keine Anzahl nennen.", "Choose a savegame and read its chests under My chests first. I cannot give a count without those data.") }
            if storageFollowup, let id = lastStorageItem { return storage.count(itemID: id, english: en, locations: true) }
            let items = storage.itemMatches(q)
            if items.count == 1 {
                lastStorageItem = items[0].0; lastPlace = nil; lastRecipe = nil; lastGuide = nil
                return storage.count(itemID: items[0].0, english: en)
            }
            if items.count > 1 {
                return CompanionAnswer(text: (en ? "Which item do you mean? " : "Welchen Gegenstand meinst du? ") + items.map { item in storage.itemNames[String(item.0)].map { en ? $0.en : $0.de } ?? item.1 }.joined(separator: ", "))
            }
            return result("Nenne einen eindeutigen Gegenstand, zum Beispiel: Wie viele Diamanten habe ich?", "Name a specific item, for example: How many diamonds do I have?", handled: false)
        }
        if has(["wo bin ich", "wie weit", "wie komme ich", "welche richtung", "where am i", "how far", "how do i get", "which direction"]) {
            return result("Deine aktuelle Position auf der Quest kenne ich noch nicht. Ich kann dir gespeicherte Koordinaten benannter Orte nennen, aber keine Live-Route. Frage zum Beispiel: Wo ist mein Haus?", "I don't know your current Quest position yet. I can read saved coordinates of named places, but cannot give a live route. Try: Where is my house?")
        }
        let whereQuestion = has(["wo", "where", "koordinaten", "coordinates", "finde", "find", "liegt", "located"])
        let followup = has(["dafur", "dazu", "das", "dem", "dort", "es", "davon", "die", "that", "it", "there", "those", "materials", "materialien", "zutaten"])
        let recipeQuestion = has(["craft", "craften", "crafte", "crafted", "crafting", "rezept", "recipe", "herstellen", "stelle", "brauche", "benotige", "materials", "materialien", "zutaten", "make", "need", "bauen", "baue", "build"])
        let listPlaces = has(["welche orte", "meine orte", "benannte orte", "list places", "my places", "named places"])
        let matchedPlaces = places.filter { Self.contains(q, phrase: $0.name) }
        if listPlaces || whereQuestion || (!matchedPlaces.isEmpty && !recipeQuestion) {
            guard world != nil else { return result("Wähle zuerst einen Spielstand für die Ortsauskunft.", "Choose a savegame first to look up places.") }
            if listPlaces {
                guard !places.isEmpty else { return missingPlace(en) }
                return CompanionAnswer(text: (en ? "Named places: " : "Benannte Orte: ") + places.map(\.name).joined(separator: ", ") + ".")
            }
            var matches = matchedPlaces
            if matches.isEmpty && has(["haus", "hause", "zuhause", "home", "house", "base", "basis"]) {
                matches = places.filter { place in ["haus", "hause", "zuhause", "home", "house", "base", "basis"].contains { Self.contains(Self.normalized(place.name), phrase: $0) } }
            }
            if matches.isEmpty && followup, let previous = places.first(where: { $0.id == lastPlace }), !recipeQuestion {
                // Resolve only explicit place pronouns, never an unknown named destination.
                if has(["wo ist das", "wo war das", "wo ist es", "where is it", "where was that", "koordinaten davon"]) { matches = [previous] }
            }
            if matches.count > 1 {
                return CompanionAnswer(text: (en ? "I found several places. Use the exact name: " : "Ich finde mehrere Orte. Verwende den genauen Namen: ") + matches.map { $0.description(en) }.joined(separator: " "))
            }
            if let place = matches.first {
                lastStorageItem = nil; lastPlace = place.id; lastRecipe = nil; lastGuide = nil
                return CompanionAnswer(text: place.description(en) + (en ? " This is a saved map label, not a live location." : " Das ist eine gespeicherte Kartenmarkierung, keine Live-Position."))
            }
            return missingPlace(en)
        }
        if has(["welche rezepte", "what recipes", "list recipes", "was kannst du craften"]) {
            if let catalog = crafting?.index.catalog {
                return result("Im erweiterten Katalog stehen \(catalog.recipes.count) ungeprüfte Vergleichsrezepte. Frage nach einem Gegenstand oder nutze die schnelle Rezeptsuche unter Orte & Rezepte. Eigene Vorräte werden weiterhin nur für die zehn bisherigen Referenzen geprüft.", "The extended catalog contains \(catalog.recipes.count) unverified comparison recipes. Ask for an item or use the quick recipe search under Places & recipes. Owned supplies are still checked only for the ten existing references.")
            }
            return CompanionAnswer(text: (en ? "Available recipe references: " : "Verfügbare Rezeptreferenzen: ") + recipes.map { $0.title.value(en) }.joined(separator: ", ") + (en ? ". These still need testing in RealmCraft VR." : ". Diese müssen in RealmCraft VR noch geprüft werden."))
        }
        if has(["habe ich", "fehlt mir", "fehlen mir", "do i have", "am i missing", "how many do i have"]) {
            return result("Ein automatischer Abgleich mit deinem Inventar ist hier noch nicht eingebaut. Unter Spieler kannst du den gespeicherten Bestand einlesen. Die Rezeptauskunft nennt den gesamten Materialbedarf.", "Automatic inventory comparison is not included yet. Read your saved inventory under Player. Recipe answers give the total material requirement.")
        }
        let matches = recipes.filter { recipe in (recipe.aliases + [recipe.title.de, recipe.title.en]).contains { Self.contains(q, phrase: $0) } }
        if matches.count > 1 {
            return CompanionAnswer(text: (en ? "Which recipe do you mean? " : "Welches Rezept meinst du? ") + matches.map { $0.title.value(en) }.joined(separator: ", ") + ".")
        }
        let guideMatches = guides.filter { Self.contains(q, phrase: $0.title.de) || Self.contains(q, phrase: $0.title.en) }
        if let guide = guideMatches.first {
            lastStorageItem = nil; lastGuide = guide.id; lastRecipe = nil; lastPlace = nil
            return guideAnswer(guide, en)
        }
        if let answer = crafting?.answer(question, english: en) {
            usedCrafting = true
            lastStorageItem = nil; lastRecipe = nil; lastGuide = nil; lastPlace = nil
            return CompanionAnswer(text: answer.text, spokenText: answer.spoken)
        }
        let isShortFollowup = followup && q.split(separator: " ").count <= 9
        if let recipe = matches.first ?? (isShortFollowup ? recipes.first { $0.id == lastRecipe } : nil) {
            // A named, unknown object must not silently reuse the previous recipe.
            let generic = ["was brauche ich dafur", "was brauche ich dazu", "welche materialien", "welche materialien brauche ich dafur", "welche materialien brauche ich", "wie mache ich das", "wie geht das", "what do i need", "what do i need for that", "how do i make it", "what materials", "what materials do i need"].contains(q)
            guard !matches.isEmpty || generic else { return help(en) }
            lastStorageItem = nil; lastRecipe = recipe.id; lastGuide = nil; lastPlace = nil
            return CompanionAnswer(text: recipe.evidence.value(en) + "\n\n" + recipe.title.value(en) + ": " + recipe.materials.value(en) + "\n" + recipe.steps.value(en), sources: [recipe.source])
        }
        if isShortFollowup, let guide = guides.first(where: { $0.id == lastGuide }) { return guideAnswer(guide, en) }
        if recipeQuestion {
            return result("Dieses Rezept ist noch nicht im lokalen Katalog. Unter Orte & Rezepte findest du die verfügbaren Anleitungen, zum Beispiel Bett, Kiste und Werkbank. Ich erfinde keine fehlenden Materialmengen.", "This recipe is not in the local catalog yet. Places & recipes lists available instructions, including bed, chest and crafting table. I won't invent missing material quantities.", handled: false)
        }
        return help(en)
    }
    private func guideAnswer(_ guide: BuildGuide, _ en: Bool) -> CompanionAnswer {
        CompanionAnswer(text: guide.evidence.value(en) + "\n\n" + guide.title.value(en) + "\n" + guide.materials.map { $0.count.value(en) + " " + $0.name.value(en) }.joined(separator: ", ") + "\n" + guide.steps.enumerated().map { "\($0.offset + 1). \($0.element.value(en))" }.joined(separator: "\n"), sources: guide.sources)
    }
    private func missingPlace(_ en: Bool) -> CompanionAnswer {
        CompanionAnswer(text: en ? "I can't uniquely identify that place. In Maps, select a marker under Interesting places, name it (for example House), and save the name. Then ask for that exact name. I only use places named in the selected world." : "Diesen Ort kann ich nicht eindeutig zuordnen. Wähle unter Karten bei Interessante Orte eine Markierung, benenne sie zum Beispiel Haus und speichere den Namen. Frage dann nach genau diesem Namen. Ich verwende nur benannte Orte der ausgewählten Welt.", handled: false)
    }
    private func help(_ en: Bool) -> CompanionAnswer {
        CompanionAnswer(text: en ? "I can look up named places, explain the included recipe references and read build-guide materials. Try: Where is my house? How do I craft a crafting table? What do I need for that? Which recipes are available? For a build guide, use its full title. I don't yet have a reliable answer to other questions." : "Ich kann benannte Orte nachschlagen, enthaltene Rezeptreferenzen erklären und Materiallisten der Bauanleitungen vorlesen. Versuche: Wo ist mein Haus? Wie crafte ich eine Werkbank? Was brauche ich dafür? Welche Rezepte kennst du? Bei einer Bauanleitung verwende den vollständigen Titel. Für andere Fragen habe ich noch keine verlässliche Antwort.", handled: false)
    }
}

struct CompanionStorageContext {
    let savedAt: Date
    let backupAt: Date
    let index: ChestIndex?
    let ownedIDs: Set<String>
    let itemNames: [String: ItemName]
    var chestLabels: [String: String] = [:]

    func provenance(_ en: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: en ? "en_GB" : "de_AT")
        formatter.dateStyle = .medium; formatter.timeStyle = .short
        let saved = formatter.string(from: savedAt), backup = formatter.string(from: backupAt)
        return en ? "Savegame dated \(saved); backup dated \(backup). These data may be inaccurate, incomplete or out of date. Only chests marked as yours are counted; your player inventory is not included."
            : "Spielstand vom \(saved); Sicherung vom \(backup). Diese Daten können ungenau, unvollständig oder veraltet sein. Gezählt werden nur als eigene markierte Kisten; dein Spielerinventar ist nicht enthalten."
    }
    func itemMatches(_ question: String) -> [(Int, String)] {
        let q = ConversationKnowledge.normalized(question).replacingOccurrences(of: "in meinen kisten", with: "").replacingOccurrences(of: "in den kisten", with: "").replacingOccurrences(of: "in my chests", with: "").replacingOccurrences(of: "in meinen truhen", with: "")
        let words = q.split(separator: " ").map(String.init)
        return itemNames.compactMap { key, name in
            guard let id = Int(key) else { return nil }
            let aliases = [name.de, name.en].map(ConversationKnowledge.normalized)
            let match = aliases.contains { alias in
                if ConversationKnowledge.contains(q, phrase: alias) { return true }
                if !alias.contains(" ") { return words.contains(alias + "en") || words.contains(alias + "e") || words.contains(alias + "s") }
                return false
            }
            return match ? (id, name.de) : nil
        }.sorted { $0.0 < $1.0 }
    }
    func count(itemID: Int, english en: Bool, locations: Bool = false) -> CompanionAnswer {
        let name = itemNames[String(itemID)].map { en ? $0.en : $0.de } ?? "ID \(itemID)"
        let footer = "\n\n" + provenance(en)
        guard let index else { return CompanionAnswer(text: (en ? "Read the chests of the selected savegame first, then mark which ones belong to you under My chests." : "Lies zuerst die Kisten des ausgewählten Spielstands ein und markiere unter Eigene Kisten, welche dir gehören.") + footer) }
        guard !ownedIDs.isEmpty else { return CompanionAnswer(text: (en ? "No chests are marked as yours in this world. Choose them under My chests. I cannot infer ownership or exclude NPC houses automatically." : "In dieser Welt sind noch keine Kisten als eigene markiert. Wähle sie unter Eigene Kisten aus. Besitz und NPC-Häuser kann ich nicht automatisch unterscheiden.") + footer) }
        let selected = index.chests.filter { ownedIDs.contains($0.id) }
        let unreadable = selected.filter { !$0.readable }.count
        let missing = ownedIDs.subtracting(Set(index.chests.map(\.id))).count
        let partial = unreadable > 0 || missing > 0 || !index.errors.isEmpty
        var total: Int64 = 0
        var lines: [String] = []
        for chest in selected where chest.readable {
            let quantity = chest.items.filter { $0.itemID == itemID }.reduce(Int64(0)) { $0 + Int64($1.quantity) }
            guard quantity > 0 else { continue }
            total += quantity
            let dimension = chest.dimension == "o" ? (en ? "Overworld" : "Oberwelt") : "Nether"
            lines.append((chest.displayName(manual: chestLabels[chest.id]).map { $0 + ": " } ?? "") + "\(quantity) · \(chest.coordinates) · \(dimension)")
        }
        let headline = en ? "\(name): \(partial ? "at least " : "")\(total) found in your marked chests." : "\(name): \(partial ? "mindestens " : "")\(total) in deinen markierten Kisten gefunden."
        let issue = partial ? (en ? "\nIncomplete result: \(unreadable) unreadable owned chests, \(missing) marked chests absent from this index, \(index.errors.count) scan issue(s)." : "\nUnvollständiges Ergebnis: \(unreadable) eigene Kisten nicht lesbar, \(missing) markierte Kisten nicht im Index, \(index.errors.count) Probleme beim Einlesen.") : ""
        return CompanionAnswer(text: headline + (lines.isEmpty ? "" : "\n" + lines.joined(separator: "\n")) + issue + footer, spokenText: locations ? nil : headline + " " + shortProvenance(en) + (partial ? (en ? " The count is incomplete." : " Die Zählung ist unvollständig.") : "") + (en ? " Ask where exactly for coordinates." : " Frage wo genau für Koordinaten."))
    }
}

struct CompanionSpawnPoint: Equatable {
    let x: Int, y: Int, z: Int
    /// Observed v2 entity prefix: RespawnData (component 15, version 0), Vector3i,
    /// followed by a zero rotation byte and Health (component 5, version 1).
    /// Component ID confirmed from local v107 metadata field default 7690 = 15.
    static func parse(_ data: Data) -> CompanionSpawnPoint? {
        let b = Array(data)
        guard b.count >= 110, b.count <= 4_000_000, Array(b[0..<5]) == [2,0,0,0,1] else { return nil }
        func u32(_ p: Int) -> UInt32 { b[p..<p+4].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) } }
        guard u32(5) == UInt32(b.count - 9),
              Array(b[30..<39]) == [0,14,0,1,1,0,0,2,1],
              Array(b[63..<67]) == [0,0,3,0],
              Array(b[78..<87]) == [0,0,9,0,0,0,0,15,0],
              Array(b[99..<103]) == [0,0,5,1] else { return nil }
        let x = Int(Int32(bitPattern: u32(87))), y = Int(Int32(bitPattern: u32(91))), z = Int(Int32(bitPattern: u32(95)))
        guard abs(x) <= 30_000_000, (0...255).contains(y), abs(z) <= 30_000_000 else { return nil }
        return CompanionSpawnPoint(x: x, y: y, z: z)
    }
}

/// Structured counterparts of the bundled, explicitly unverified Minecraft references.
/// IDs are matched against the local item catalog; no free-form quantity parsing.
struct CompanionIngredient {
    let de: String
    let en: String
    let ids: [Int]
    let quantity: Int64
    var sameVariant = false
}
extension ConversationRecipe {
    var ingredients: [CompanionIngredient]? {
        func wood(_ n: Int64, same: Bool = false) -> CompanionIngredient { .init(de: "Holzbretter", en: "wooden planks", ids: Array(13...18), quantity: n, sameVariant: same) }
        func sticks(_ n: Int64) -> CompanionIngredient { .init(de: "Stöcke", en: "sticks", ids: [3154], quantity: n) }
        switch id {
        case "planks": return [.init(de: "Holzstamm", en: "log", ids: Array(38...49), quantity: 1)]
        case "table": return [wood(4)]
        case "sticks": return [wood(2)]
        case "pickaxe": return [wood(3), sticks(2)]
        case "furnace": return [.init(de: "Bruchstein", en: "cobblestone", ids: [12], quantity: 8)]
        case "sword": return [wood(2), sticks(1)]
        case "hoe": return [wood(2), sticks(2)]
        case "gate": return [wood(2, same: true), sticks(4)]
        case "bed": return [.init(de: "Wolle derselben Farbe", en: "wool of one color", ids: Array(108...123), quantity: 3, sameVariant: true), wood(3)]
        case "chest": return [wood(8)]
        default: return nil
        }
    }
}
extension CompanionStorageContext {
    var completeOwnedIndex: Bool {
        guard let index, !ownedIDs.isEmpty else { return false }
        return index.errors.isEmpty && ownedIDs.isSubset(of: Set(index.chests.map(\.id))) && index.chests.filter { ownedIDs.contains($0.id) }.allSatisfy(\.readable)
    }
    func craft(_ recipe: ConversationRecipe, english en: Bool, locations: Bool = false) -> CompanionAnswer {
        guard let ingredients = recipe.ingredients else { return CompanionAnswer(text: en ? "No structured material comparison is available for this recipe." : "Für dieses Rezept ist noch kein strukturierter Materialabgleich verfügbar.") }
        let footer = "\n\n" + provenance(en)
        guard let index, !ownedIDs.isEmpty else {
            return CompanionAnswer(text: (en ? "Read the selected savegame's chests under My chests and mark your own containers first. Without that data I cannot determine missing materials." : "Lies unter Eigene Kisten den gewählten Spielstand ein und markiere deine Kisten. Ohne diese Daten kann ich keine Fehlmengen bestimmen.") + footer)
        }
        let chests = index.chests.filter { ownedIDs.contains($0.id) && $0.readable }
        var sufficient = true
        var rows: [String] = []
        for ingredient in ingredients {
            var ids = Set(ingredient.ids)
            if ingredient.sameVariant {
                let best = ingredient.ids.max { lhs, rhs in
                    func total(_ id: Int) -> Int64 { chests.flatMap(\.items).filter { $0.itemID == id && $0.quantity > 0 }.reduce(0) { $0 + Int64($1.quantity) } }
                    return total(lhs) < total(rhs)
                }!
                ids = [best]
            }
            let available = chests.flatMap(\.items).filter { ids.contains($0.itemID) && $0.quantity > 0 }.reduce(Int64(0)) { $0 + Int64($1.quantity) }
            let missing = max(0, ingredient.quantity - available)
            sufficient = sufficient && missing == 0
            let name = en ? ingredient.en : ingredient.de
            var row = en ? "\(name): need \(ingredient.quantity), found \(available)" : "\(name): benötigt \(ingredient.quantity), gefunden \(available)"
            if missing > 0 { row += en ? ", \(completeOwnedIndex ? "missing" : "not found in readable chests") \(missing)" : ", \(completeOwnedIndex ? "fehlen" : "in lesbaren Kisten nicht gefunden") \(missing)" }
            if ingredient.sameVariant, available > 0, let id = ids.first, let variant = itemNames[String(id)] { row += " (" + (en ? variant.en : variant.de) + ")" }
            if locations {
                let found = chests.compactMap { chest -> String? in
                    let count = chest.items.filter { ids.contains($0.itemID) && $0.quantity > 0 }.reduce(Int64(0)) { $0 + Int64($1.quantity) }
                    guard count > 0 else { return nil }
                    return (chest.displayName(manual: chestLabels[chest.id]).map { $0 + ": " } ?? "") + "\(count) · \(chest.coordinates) · " + (chest.dimension == "o" ? (en ? "Overworld" : "Oberwelt") : "Nether")
                }
                row += found.isEmpty ? "" : "\n" + found.joined(separator: "\n")
            }
            rows.append(row)
        }
        let verdict = sufficient ? (en ? "The counted materials cover one execution of this reference recipe." : "Die gezählten Materialien reichen für eine Ausführung dieses Referenzrezepts.") : (en ? "The counted materials do not cover one execution of this reference recipe." : "Die gezählten Materialien reichen für eine Ausführung dieses Referenzrezepts nicht aus.")
        let limitations = en ? "Only direct ingredients are compared; no intermediate crafting, crafting station or player inventory check. Ask ‘Where are the materials?’ for chest coordinates." : "Verglichen werden direkte Zutaten; Zwischenprodukte, Werkstation und Spielerinventar werden nicht geprüft. Frage „Wo liegen die Materialien?“ für die Kistenkoordinaten."
        let text = recipe.title.value(en) + ": " + verdict + "\n" + recipe.evidence.value(en) + "\n\n" + rows.joined(separator: "\n") + "\n" + limitations + footer
        let spoken = recipe.title.value(en) + ": " + verdict + " " + (en ? "Minecraft reference, not verified in RealmCraft. " : "Minecraft-Referenz, in RealmCraft nicht geprüft. ") + rows.map { $0.components(separatedBy: "\n")[0] }.joined(separator: ". ") + " " + shortProvenance(en)
        return CompanionAnswer(text: text, sources: [recipe.source], spokenText: locations ? text : spoken)
    }
    func shortProvenance(_ en: Bool) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: en ? "en_GB" : "de_AT"); formatter.dateStyle = .medium; formatter.timeStyle = .short
        return en ? "Savegame \(formatter.string(from: savedAt)); data may be inaccurate or outdated. Only marked chests." : "Spielstand vom \(formatter.string(from: savedAt)); Daten möglicherweise ungenau oder veraltet. Nur markierte Kisten."
    }
}
