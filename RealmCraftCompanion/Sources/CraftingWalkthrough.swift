import Foundation

struct CraftingWalkthroughStep: Identifiable {
    enum Visual: String { case ingredients, station, arrangement, action, result, obtaining }
    let id: String
    let title: String
    let text: String
    let visual: Visual
    var payload: [String: Any] { ["id": id, "title": title, "text": text, "illustration": visual.rawValue] }
}

/// One data-derived procedure drives the illustrated screen, written answers and agent exports.
enum CraftingWalkthrough {
    static func stationItem(_ station: CraftingStation) -> String? {
        switch station {
        case .inventory: return nil
        case .table: return "crafting_table"
        case .furnace: return "furnace"
        case .blastFurnace: return "blast_furnace"
        case .smoker: return "smoker"
        case .campfire: return "campfire"
        case .stonecutter: return "stonecutter"
        case .smithing: return "smithing_table"
        }
    }
    static func recipe(_ recipe: CraftingRecipe, index: CraftingIndex, desired: Int, english en: Bool) -> [CraftingWalkthroughStep] {
        func t(_ de: String, _ english: String) -> String { en ? english : de }
        let quantity = min(9999, max(1, desired)), batches = recipe.batches(for: quantity)
        let ingredients = recipe.ingredients.map { "\($0.count * batches) × " + index.ingredientName($0, english: en) }.joined(separator: "\n")
        let output = index.items[recipe.output]?.title.value(en) ?? recipe.output
        var result: [CraftingWalkthroughStep] = [
            .init(id: "prepare", title: t("Zutaten bereitlegen", "Prepare ingredients"),
                  text: ingredients + "\n\n" + t("Bei Alternativen gilt die Gesamtmenge aus den genannten Möglichkeiten. Vorhandene Zutaten können direkt verwendet werden; fehlende Zwischenprodukte über ihre verlinkten Rezepte herstellen.", "For alternatives, use the stated total from the listed choices. Use ingredients you already have directly; follow their linked recipes for missing intermediate products."), visual: .ingredients),
            .init(id: "station", title: t("Herstellungsort vorbereiten", "Prepare the station"),
                  text: recipe.station == .inventory ? t("Öffne Crafting im Inventar / Menü. Das Rezept passt in das 2 × 2-Feld.", "Open crafting in the inventory / menu. This recipe fits the 2 × 2 grid.") : recipe.station.title(en) + ". " + t("Falls die Station noch fehlt, schlage ihr eigenes Rezept nach. Stationsbau zählt zusätzlich zu den Rezeptzutaten. Brennstoff wird nur an Stationen benötigt, die ihn verbrauchen. Prüfe die Verfügbarkeit in deiner RealmCraft-Version.", "If you do not have the station, look up its own recipe. Building the station and any fuel are additional to this recipe's ingredients. Check availability in your RealmCraft version."), visual: .station)
        ]
        if recipe.shaped {
            result.append(.init(id: "arrangement", title: t("Rezept und Anordnung vergleichen", "Compare the recipe and arrangement"),
                text: t("Das Raster zeigt einen Durchgang. Nummern stehen für die Zutatengruppen; jedes belegte Feld benötigt ein Stück. Laut RealmCraft-Wiki wählst du das Rezept aus der Liste und die Zutaten werden automatisch angeordnet. Das Raster erklärt die Anordnung, keine geprüfte Quest-Geste.", "The grid shows one batch. Numbers identify ingredient groups; every occupied slot needs one item. The RealmCraft wiki describes choosing a recipe from the list with automatic ingredient placement. The grid explains the arrangement, not a tested Quest gesture."), visual: .arrangement))
        } else if recipe.kind == "crafting_shapeless" {
            result.append(.init(id: "arrangement", title: t("Formloses Rezept auswählen", "Select the shapeless recipe"),
                text: t("Verwende alle aufgeführten Zutatengruppen. Eine bestimmte räumliche Anordnung ist für dieses Vergleichsrezept nicht erforderlich.", "Use every listed ingredient group. This comparison recipe does not require a fixed spatial arrangement."), visual: .arrangement))
        }
        result += [
            .init(id: "process", title: t("Herstellen oder verarbeiten", "Craft or process"), text: recipe.station.instructions(en), visual: .action),
            .init(id: "collect", title: t("Ergebnis entnehmen und prüfen", "Collect and check the result"),
                text: "\(batches) × \(recipe.count) = \(recipe.produced(for: quantity)) × \(output). " +
                    t("Bedarf: \(quantity); übrig: \(recipe.produced(for: quantity) - quantity). Wiederhole den beschriebenen Ablauf für die berechneten Durchgänge. Vergleiche das tatsächliche Ergebnis im Spiel mit der Referenz.", "Demand: \(quantity); surplus: \(recipe.produced(for: quantity) - quantity). Repeat the procedure for the calculated batches. Compare the actual in-game result with the reference."), visual: .result)
        ]
        return result
    }
    static func obtaining(_ guide: CraftingAcquisition, english: Bool) -> [CraftingWalkthroughStep] {
        guide.steps.map { .init(id: $0.id, title: $0.title.value(english), text: $0.text.value(english), visual: .obtaining) }
    }
    static func markdown(_ steps: [CraftingWalkthroughStep], english en: Bool) -> String {
        ["### " + (en ? "Step-by-step walkthrough" : "Schritt-für-Schritt-Anleitung"), ""]
            .joined(separator: "\n") + steps.enumerated().map { "\n#### \($0.offset + 1). \($0.element.title)\n\n\($0.element.text)\n" }.joined()
    }
    static func agentGuide(english en: Bool) -> String {
        func t(_ de: String, _ english: String) -> String { en ? english : de }
        return "## " + t("Rezeptfragen mit diesen Daten beantworten", "Answering recipe questions with this data") + "\n\n" + [
            t("Bei unspezifischen Fragen wie ‚Wie baue ich eine Spitzhacke?‘ zuerst Material und gewünschte Menge klären. Gleichnamige Gegenstände, Werkstoffe und Rezeptvarianten nicht gleichsetzen. Nutze die Namen, IDs und Varianten der enthaltenen Anleitungen.", "For unspecific questions such as ‘How do I make a pickaxe?’, first clarify material and desired quantity. Do not equate similar item names, materials or recipe variants. Use the names, IDs and variants in the included guides."),
            t("Danach direkte Zutaten und Mengen, Herstellungsort, nummerierte Schritte, Anordnung, Ergebnis und Besonderheiten erklären. Auf Wunsch jeweils nur einen Schritt geben und auf ‚weiter‘ warten. Bei Rückfragen den gewählten Gegenstand, die Variante und die Menge beibehalten.", "Then explain direct ingredients and quantities, station, numbered steps, arrangement, result and special cases. On request, give one step at a time and wait for ‘next’. Retain the chosen item, variant and quantity for follow-up questions."),
            t("Fehlende Zwischenprodukte über ingredientOptions und verlinkte Gegenstands-IDs nachschlagen; Stationsbau gesondert behandeln. Vor einer Material-Gesamtsumme Zutatenalternativen und Herstellungswege klären, gemeinsame Bedarfe zuerst addieren und dann je Rezept auf ganze Durchgänge aufrunden. Überschüsse weiterverwenden. Kreisläufe nicht endlos expandieren: einen Beschaffungsweg oder ‚bereits vorhanden‘ klären. Nicht enthaltene Rezepte bleiben offen.", "Look up missing intermediate products through ingredientOptions and linked item IDs; handle station construction separately. Before calculating a total material list, resolve ingredient alternatives and routes, aggregate shared demand first, then round up to whole batches per recipe. Reuse surplus. Do not expand cycles indefinitely: clarify an obtaining route or existing supply. Recipes absent from this export remain unknown."),
            t("Bei ‚Was habe ich schon?‘ ausschließlich passende Bestandsdaten des beigefügten Backups verwenden: eigene Kisten und ausdrücklich lesbare Inventardaten. Bedarf ist kein Besitz. Fehlen solche Daten, nach vorhandenen Materialien fragen. Zufallsbeute und Brennstoff nicht mit unbelegten Mengen hochrechnen.", "For ‘What do I already have?’, use only matching stock records in the attached backup: owned chests and explicitly readable inventory. Requirements are not possessions. If those data are absent, ask about available materials. Do not invent quantities for random drops or fuel."),
            t("Prüfstatus pro Anleitung beachten. Persönliche Bestätigung, RealmCraft-Wiki-Beleg und ungeprüfter Minecraft-Vergleich sind unterschiedliche Evidenz. Keine fehlenden Rezepte, Controller-Tasten oder RealmCraft-Verfügbarkeit erfinden. Skizzen erklären den Ablauf; sie sind keine Spielscreenshots. Markdown enthält lesbare Raster, JSON zusätzlich die vollständigen Zutaten- und Schrittdaten.", "Respect verification status per guide. Personal confirmation, RealmCraft wiki evidence and an untested Minecraft comparison are different kinds of evidence. Do not invent missing recipes, controller buttons or RealmCraft availability. Sketches explain the procedure; they are not game screenshots. Markdown contains readable grids; JSON additionally contains full ingredient and step data.")
        ].enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n\n")
    }
}

enum CraftingExportScope: String, CaseIterable {
    case selected, verified, all
    func title(_ en: Bool) -> String {
        switch self {
        case .selected: return en ? "My selection" : "Meine Auswahl"
        case .verified: return en ? "All personally verified guides" : "Alle persönlich verifizierten Anleitungen"
        case .all: return en ? "All documented guides" : "Alle dokumentierten Anleitungen"
        }
    }
}
