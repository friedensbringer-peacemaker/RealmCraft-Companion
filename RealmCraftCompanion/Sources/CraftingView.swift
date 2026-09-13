import SwiftUI

struct CraftingView: View {
    @Environment(\.companionLookup) private var lookup
    let language: String
    private let result: Result<CraftingIndex, Error>
    private let planURL: URL
    private static let bundled: Result<CraftingIndex, Error> = Result { try CraftingCatalog.load().index() }
    @State private var query = ""
    @State private var category = "all"
    @State private var station = "all"
    @State private var coverage = "all"
    @State private var showFilters = false
    @State private var selected: String?
    @State private var history: [String] = []
    @State private var showMaterialPlan = false
    @State private var showIcons = false
    @State private var showAgentSelection = false
    @State private var onlyVerified = false
    @ObservedObject private var agentLibrary: CraftingAgentLibrary
    @State private var planAddition: (recipe: CraftingRecipe, quantity: Int)?
    private var english: Bool { language == "en" }
    init(language: String, catalog: CraftingCatalog? = nil, initialItem: String = "crafting_table", initialQuery: String = "", planURL: URL = CraftingPlanStorage.defaultURL, agentLibrary: CraftingAgentLibrary = .shared) {
        self.language = language
        self.planURL = planURL
        self.agentLibrary = agentLibrary
        result = catalog.map { .success($0.index()) } ?? Self.bundled
        _selected = State(initialValue: initialItem)
        _query = State(initialValue: initialQuery)
    }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Crafting / Recipes" : "Crafting / Rezepte") {
                Button { showIcons = true } label: { Label(english ? "Item icons" : "Gegenstands-Icons", systemImage: "photo") }
                Button(english ? "For agents" : "Für Agenten") { showAgentSelection = true }
                    .disabled({ if case .failure = result { return true }; return false }())
                Button(english ? "Material plan" : "Materialplan") {
                    planAddition = nil; showMaterialPlan = true
                }.disabled({ if case .failure = result { return true }; return false }())
            }
            switch result {
            case .failure(let error):
                ContentUnavailableView(english ? "Catalog unavailable" : "Katalog nicht verfügbar", systemImage: "exclamationmark.triangle", description: Text(error.localizedDescription))
            case .success(let index):
                content(index)
            }
        }
        .sheet(isPresented: $showIcons) { ItemIconSettings(english: english) }
    }
    private func content(_ index: CraftingIndex) -> some View {
        let visible = visibleItems(index)
        let groups = CraftingBrowseGroup.make(visible, english: english)
        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                CompanionDetails(english ? "Catalog scope & counts" : "Katalogumfang & Anzahl") {
                Text(english ? "\(index.catalog.items.filter { $0.itemID != nil }.count) catalog entries · \(index.catalog.recipes.count) comparison recipes · \(index.recipes.count) items with recipes"
                     : "\(index.catalog.items.filter { $0.itemID != nil }.count) Katalogeinträge · \(index.catalog.recipes.count) Vergleichsrezepte · \(index.recipes.count) Gegenstände mit Rezept")
                    .font(.subheadline.weight(.semibold))
                    Text(english ? "\(index.acquisitions.count) entries with obtaining instructions" : "\(index.acquisitions.count) Einträge mit Beschaffungsanleitung")
                        .font(.subheadline)
                }.font(.caption)
                Text(english ? "Recipes, obtaining methods and name mappings are Minecraft references, unverified in RealmCraft VR. RealmCraft wiki evidence is noted separately. This is not a complete, confirmed list of game content."
                     : "Rezepte, Beschaffungswege und Namenszuordnungen sind Minecraft-Referenzen, in RealmCraft VR ungeprüft. RealmCraft-Wiki-Belege stehen separat dabei. Dies ist keine vollständige, bestätigte Liste der Spielinhalte.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)

            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            Divider()
            HSplitView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        TextField(english ? "Item, alias or ID" : "Gegenstand, Begriff oder ID", text: $query)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("crafting.search")
                        Button { showFilters.toggle() } label: {
                            Image(systemName: activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundStyle(activeFilterCount > 0 ? Color.accentColor : .secondary)
                        }
                        .buttonStyle(.plain).font(.title3)
                        .accessibilityLabel(english ? "Filter items" : "Gegenstände filtern")
                        .accessibilityValue(english ? "\(activeFilterCount) active filters" : "\(activeFilterCount) aktive Filter")
                        .accessibilityIdentifier("crafting.filters")
                        .help(english ? "Category, station and coverage" : "Kategorie, Herstellungsort und Datenlage")
                        .popover(isPresented: $showFilters, arrowEdge: .top) { filterPopover }
                    }.padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 8)
                    HStack {
                        Text(english ? "\(visible.count) matches · \(activeFilterCount) filters" : "\(visible.count) Treffer · \(activeFilterCount) Filter")
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 4)
                        if activeFilterCount > 0 || !query.isEmpty {
                            Button(english ? "Reset" : "Zurücksetzen") { resetFilters() }.buttonStyle(.plain)
                        }
                    }.font(.caption).padding(.horizontal, 12).padding(.bottom, 8)
                    if visible.isEmpty {
                        Text(english ? "No matches. Clear search or filters." : "Keine Treffer. Suche oder Filter zurücksetzen.")
                            .foregroundStyle(.secondary).padding()
                        Button(english ? "Reset filters" : "Filter zurücksetzen") { resetFilters() }.padding(.horizontal)
                        Spacer()
                    } else {
                        List(selection: $selected) {
                            ForEach(groups) { group in
                                if group.type.isFamily {
                                    Section {
                                        ForEach(group.items) { item in itemRow(item, index: index) }
                                    } header: {
                                        Text(group.type.title.value(english) + " · \(group.items.count)").foregroundStyle(.secondary)
                                    }
                                } else {
                                    ForEach(group.items) { item in itemRow(item, index: index) }
                                }
                            }
                        }.listStyle(.sidebar).scrollContentBackground(.hidden)
                    }
                }.frame(minWidth: 220, idealWidth: 270, maxWidth: 320)
                VStack(spacing: 0) {
                    if !history.isEmpty {
                        HStack {
                            Button { selected = history.removeLast() } label: { Label(english ? "Back" : "Zurück", systemImage: "chevron.left") }
                            Spacer()
                        }.padding(.horizontal, 20).padding(.top, 12)
                    }
                    if let selected, let item = index.items[selected] {
                        CraftingItemDetail(item: item, index: index, english: english, agentLibrary: agentLibrary, openItem: openItem, addToPlan: { recipe, quantity in
                            planAddition = (recipe, quantity); showMaterialPlan = true
                        }).id(selected)
                    } else {
                        ContentUnavailableView(english ? "Choose an item" : "Gegenstand auswählen", systemImage: "square.grid.3x3")
                    }
                }.frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { agentLibrary.reload(); applyLookup(index) }
        .onChange(of: lookup) { _, _ in applyLookup(index) }
        .onChange(of: query) { _, _ in synchronizeSelection(index) }
        .onChange(of: category) { _, _ in synchronizeSelection(index) }
        .onChange(of: station) { _, _ in synchronizeSelection(index) }
        .onChange(of: coverage) { _, _ in synchronizeSelection(index) }
        .onChange(of: onlyVerified) { _, _ in synchronizeSelection(index) }
        .onChange(of: agentLibrary.state) { _, _ in if onlyVerified { synchronizeSelection(index) } }
        .sheet(isPresented: $showAgentSelection) {
            CraftingAgentSelectionView(library: agentLibrary, index: index, english: english)
        }
        .sheet(isPresented: $showMaterialPlan) {
            CraftingPlanView(index: index, english: english, addition: planAddition, url: planURL)
        }
    }
    private var filterPopover: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(english ? "Filter items" : "Gegenstände filtern").font(.headline)
                Spacer()
                Button { showFilters = false } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).accessibilityLabel(english ? "Close filters" : "Filter schließen")
            }
            Picker(english ? "Category" : "Kategorie", selection: $category) {
                Text(english ? "All categories" : "Alle Kategorien").tag("all")
                ForEach(["blocks", "tools", "armor", "food", "transport", "circuits", "materials"], id: \.self) { key in
                    Text(categoryTitle(key)).tag(key)
                }
            }
            Picker(english ? "Station" : "Herstellungsort", selection: $station) {
                Text(english ? "All methods" : "Alle Herstellungswege").tag("all")
                Text(english ? "Obtain outside crafting" : "Außerhalb von Crafting beschaffen").tag("acquisition")
                ForEach(CraftingStation.allCases, id: \.rawValue) { value in Text(value.title(english)).tag(value.rawValue) }
            }
            Divider()
            Text(english ? "Show entries" : "Einträge anzeigen").font(.subheadline.weight(.semibold))
            VStack(alignment: .leading, spacing: 10) {
                coverageOption("all", title: english ? "All entries" : "Alle Einträge")
                coverageOption("recipes", title: english ? "With recipe" : "Mit Rezept")
                coverageOption("acquisition", title: english ? "With obtaining guide" : "Mit Beschaffungsanleitung")
                coverageOption("open", title: english ? "Instructions still open" : "Anleitung noch offen")
                coverageOption("wiki", title: english ? "RealmCraft wiki evidence" : "Mit RealmCraft-Wiki-Beleg")
            }
            Toggle(english ? "Only personally verified guides" : "Nur persönlich verifizierte Anleitungen", isOn: $onlyVerified).toggleStyle(.checkbox)
                .disabled(!agentLibrary.failure.isEmpty)
            CraftingAgentErrorView(library: agentLibrary, english: english)
            Button(english ? "Reset filters" : "Filter zurücksetzen") { category = "all"; station = "all"; coverage = "all"; onlyVerified = false }
                .disabled(activeFilterCount == 0)
            Text(english ? "Filters apply to the item list. The search term stays when you reset filters here." : "Filter gelten für die Gegenstandsliste. Beim Zurücksetzen hier bleibt dein Suchbegriff erhalten.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.padding(20).frame(width: 350)
    }
    private func coverageOption(_ key: String, title: String) -> some View {
        Toggle(title, isOn: Binding(get: { coverage == key }, set: { enabled in coverage = enabled ? key : "all" }))
            .toggleStyle(.checkbox)
    }
    private func applyLookup(_ index: CraftingIndex) {
        guard let lookup, lookup.kind == .crafting, index.items[lookup.item] != nil else { return }
        resetFilters(); history = []; selected = lookup.item
    }
    private func itemRow(_ item: CraftingItem, index: CraftingIndex) -> some View {
        HStack(spacing: 8) {
            CraftingItemIcon(itemID: item.itemID, english: english)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title.value(english)).foregroundStyle(.primary).lineLimit(2)
                let recipes = index.recipes[item.id, default: []]
                Text(recipes.isEmpty ? (index.acquisitions[item.id] != nil ? (english ? "Obtaining guide" : "Beschaffung erklärt") : (english ? "Instructions open" : "Anleitung offen")) : (english ? "\(recipes.count) reference recipe(s)" : "\(recipes.count) Rezeptreferenz(en)"))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 4).tag(item.id)
    }
    private func visibleItems(_ index: CraftingIndex) -> [CraftingItem] {
        let items = index.filtered(query: query, category: category, station: station, coverage: coverage, english: english)
        guard onlyVerified else { return items }
        guard agentLibrary.failure.isEmpty else { return [] }
        let verified = Set(CraftingInstruction.all(index).filter { agentLibrary.state.records[$0.id]?.isVerified($0, index: index) == true }.map(\.itemID))
        return items.filter { verified.contains($0.id) }
    }
    private func synchronizeSelection(_ index: CraftingIndex) {
        let visible = CraftingBrowseGroup.make(visibleItems(index), english: english).flatMap(\.items)
        if !visible.contains(where: { $0.id == selected }) { selected = visible.first?.id }
        history = []
    }
    private func resetFilters() { query = ""; category = "all"; station = "all"; coverage = "all"; onlyVerified = false }
    private var activeFilterCount: Int { [category, station, coverage].filter { $0 != "all" }.count + (onlyVerified ? 1 : 0) }
    private func openItem(_ id: String) {
        guard id != selected else { return }
        if let selected { history.append(selected) }
        // Ingredient navigation retains filters and back history; the detail may be outside the filtered list.
        selected = id
    }
    private func categoryTitle(_ key: String) -> String {
        switch key {
        case "blocks": return english ? "Blocks & decoration" : "Blöcke & Dekoration"
        case "tools": return english ? "Tools & weapons" : "Werkzeuge & Waffen"
        case "armor": return english ? "Armor" : "Rüstung"
        case "food": return english ? "Food" : "Nahrung"
        case "transport": return english ? "Transport" : "Transport"
        case "circuits": return english ? "Circuits" : "Schaltungen"
        default: return english ? "Materials & other" : "Materialien & Sonstiges"
        }
    }
}

private struct CraftingItemDetail: View {
    let item: CraftingItem
    let index: CraftingIndex
    let english: Bool
    @ObservedObject var agentLibrary: CraftingAgentLibrary
    let openItem: (String) -> Void
    var addToPlan: (CraftingRecipe, Int) -> Void = { _, _ in }
    @State private var recipeID = ""
    @State private var desired = 1
    @State private var showBasics = false
    private var recipes: [CraftingRecipe] {
        index.recipes[item.id, default: []].sorted { a, b in
            let order = CraftingStation.allCases
            let ai = order.firstIndex(of: a.station)!, bi = order.firstIndex(of: b.station)!
            return ai == bi ? a.id < b.id : ai < bi
        }
    }
    private var recipe: CraftingRecipe? { recipes.first { $0.id == recipeID } ?? recipes.first }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    CraftingItemIcon(itemID: item.itemID, english: english, size: 44)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.title.value(english)).font(CompanionLayout.detailTitle)
                        Text(english ? item.title.de : item.title.en).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                if let recipe {
                    recipeContent(recipe)
                } else if index.acquisitions[item.id] == nil {
                    GroupBox {
                        Text(english ? "No recipe is documented for this entry in this catalog. This does not mean it cannot be crafted. It may be obtained by mining, harvesting, loot, trading, breeding or another process, or belong to a different game version. Check the in-game recipe list."
                             : "Für diesen Eintrag ist hier kein Rezept dokumentiert. Das bedeutet nicht, dass er nicht herstellbar ist. Mögliche Bezugswege sind Abbau, Ernte, Beute, Handel, Zucht oder ein anderes Verfahren; auch eine andere Spielversion ist möglich. Prüfe die Rezeptliste im Spiel.")
                        if item.itemID == nil {
                            Text(english ? "This ingredient belongs to the Minecraft source and has no mapping in the Companion catalog." : "Diese Zutat stammt aus der Minecraft-Quelle und hat keine Zuordnung im Companion-Katalog.").foregroundStyle(.secondary)
                        }
                    } label: { Label(english ? "Instructions open" : "Anleitung offen", systemImage: "questionmark.circle") }
                }
                if let guide = index.acquisitions[item.id] {
                    CraftingAcquisitionView(item: item, guide: guide, index: index, english: english, agentLibrary: agentLibrary, openItem: openItem)
                }
                DisclosureGroup(english ? "How crafting works in RealmCraft" : "So funktioniert Crafting in RealmCraft", isExpanded: $showBasics) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(english ? "The RealmCraft wiki describes a 2 × 2 grid in the backpack and a 3 × 3 grid at a crafting table. Select a recipe from the list; its ingredients are placed automatically. Missing ingredients prevent crafting. This description concerns the documented interface; Quest controls have not been checked."
                             : "Die RealmCraft-Wiki beschreibt ein 2 × 2-Feld im Rucksack und ein 3 × 3-Feld an der Werkbank. Wähle ein Rezept aus der Liste; die Zutaten werden automatisch angeordnet. Fehlen Zutaten, ist Herstellen nicht möglich. Diese Beschreibung betrifft die dokumentierte Oberfläche; Quest-Controller wurden nicht geprüft.")
                        Text(english ? "The grids below explain one batch. Alternatives mean a total from the listed choices, not the stated quantity of every choice. Smelting, brewing, enchanting and repairing are separate processes. Dynamic recipes and brewing chains are not yet covered by this catalog."
                             : "Die Raster erklären jeweils einen Durchgang. Bei Alternativen gilt die Gesamtmenge aus den aufgeführten Möglichkeiten, nicht die genannte Menge von jeder Möglichkeit. Schmelzen, Brauen, Verzaubern und Reparieren sind eigene Verfahren. Dynamische Rezepte und Brauketten sind in diesem Katalog noch nicht abgedeckt.")
                        Link("RealmCraft Game Wiki · Crafting", destination: URL(string: "https://realmcraftgame.fandom.com/wiki/Crafting")!)
                    }.padding(.top, 10)
                }
                let uses = index.uses[item.id, default: []]
                if !uses.isEmpty {
                    DisclosureGroup(english ? "Used in \(uses.count) reference recipes" : "Verwendung in \(uses.count) Rezeptreferenzen") {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(uses) { use in
                                Button { openItem(use.output) } label: {
                                    Text((index.items[use.output]?.title.value(english) ?? use.output) + " · " + use.station.title(english))
                                }.buttonStyle(.plain)
                            }
                        }.padding(.top, 10)
                    }
                }
                let checked = index.acquisitions[item.id]?.checked ?? index.catalog.checked
                Text(english ? "100% vibe-coded with OpenAI Codex · Sources checked \(checked)." : "100 % mit OpenAI Codex entwickelt · Quellen geprüft am \(checked).")
                    .font(.caption2).foregroundStyle(.secondary)
            }.textSelection(.enabled).padding(24).frame(maxWidth: 920, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    private func recipeContent(_ recipe: CraftingRecipe) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if recipes.count > 1 {
                Picker(english ? "Recipe variant" : "Rezeptvariante", selection: Binding(get: { self.recipe?.id ?? "" }, set: { recipeID = $0 })) {
                    ForEach(recipes) { r in
                        Text(r.station.title(english) + " · " + r.ingredients.map { index.ingredientName($0, english: english) }.joined(separator: " + ")).tag(r.id)
                    }
                }
            }
            Label(english ? "Catalog source: Minecraft comparison · no project test in RealmCraft VR" : "Katalogquelle: Minecraft-Vergleich · kein Projekttest in RealmCraft VR", systemImage: "info.circle")
                .font(.callout.weight(.medium)).foregroundStyle(.orange)
            if let evidence = recipe.corroboration {
                VStack(alignment: .leading, spacing: 6) {
                    Text(evidence.scope.value(english)).font(.callout)
                    Link(evidence.title, destination: evidence.url).font(.caption)
                }
            }
            CraftingAgentControls(library: agentLibrary, instruction: .recipe(recipe), index: index, english: english, desired: desired)
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(english ? "Reference station" : "Herstellungsort laut Referenz").font(.caption).foregroundStyle(.secondary)
                    Text(recipe.station.title(english)).font(.headline)
                    if recipe.station == .inventory {
                        Text(english ? "Also fits a crafting table." : "Passt auch auf eine Werkbank.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(english ? "Yield per batch" : "Ergebnis pro Durchgang").font(.caption).foregroundStyle(.secondary)
                    Text(english ? "\(recipe.count) item(s)" : "\(recipe.count) Stück").font(.headline)
                }
            }
            GroupBox {
                HStack {
                    Text(english ? "Desired quantity" : "Gewünschte Menge")
                    TextField("", value: $desired, format: .number.grouping(.never)).textFieldStyle(.roundedBorder).frame(width: 75)
                        .accessibilityLabel(english ? "Desired quantity" : "Gewünschte Menge")
                    Stepper("", value: $desired, in: 1...9999).labelsHidden()
                    Spacer()
                }
                .onChange(of: desired) { _, value in desired = min(9999, max(1, value)) }
                let batches = recipe.batches(for: desired), produced = recipe.produced(for: desired)
                Text(english ? "\(batches) batches → \(produced) items · \(produced - desired) extra" : "\(batches) Durchgänge → \(produced) Stück · \(produced - desired) übrig")
                    .font(.subheadline.weight(.semibold))
                Text(english ? "Direct ingredients; click an ingredient to look up its own recipe." : "Direkte Zutaten; klicke eine Zutat an, um ihr eigenes Rezept nachzuschlagen.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { offset, ingredient in
                    ingredientRow(ingredient, number: offset + 1, batches: batches)
                }
                if recipe.station.usesFuel {
                    Label(english ? "Add fuel separately. Its quantity is not verified for RealmCraft." : "Brennstoff separat hinzufügen. Seine Menge ist für RealmCraft nicht geprüft.", systemImage: "flame")
                        .font(.callout).foregroundStyle(.secondary)
                }
            } label: { Text(english ? "Ingredients & quantities" : "Zutaten & Mengen").font(.headline) }
            if recipe.shaped {
                VStack(alignment: .leading, spacing: 10) {
                    Text(english ? "Recipe grid · one batch" : "Rezept-Raster · ein Durchgang").font(.headline)
                    CraftingRecipeGrid(recipe: recipe, index: index, english: english)
                    Text(english ? "Numbers refer to the ingredient groups above. Every occupied slot takes one item; empty slots stay empty. A representative alternative is shown."
                         : "Die Nummern gehören zu den Zutatengruppen oben. Jedes belegte Feld benötigt ein Stück; leere Felder bleiben leer. Bei Alternativen wird ein Beispiel angezeigt.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else if recipe.kind == "crafting_shapeless" {
                Label(english ? "Shapeless recipe: no fixed arrangement. Use the listed ingredients." : "Formloses Rezept: keine feste Anordnung. Verwende die aufgeführten Zutaten.", systemImage: "square.grid.2x2")
            }
            GroupBox { Text(recipe.station.instructions(english)).fixedSize(horizontal: false, vertical: true) }
                label: { Text(english ? "Step by step" : "Schritt für Schritt").font(.headline) }
            HStack {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(index.summary(recipe, desired: desired, english: english), forType: .string)
                } label: { Label(english ? "Copy recipe & quantities" : "Rezept & Mengen kopieren", systemImage: "doc.on.doc") }
                Button(english ? "Add to material plan" : "Zum Materialplan hinzufügen") { addToPlan(recipe, desired) }
                Spacer()
            }
            DisclosureGroup(english ? "Recipe source & scope" : "Rezeptquelle & Gültigkeit") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(index.catalog.referenceVersion + " · " + recipe.sourcePath).font(.caption).textSelection(.enabled)
                    Text(english ? "Ingredient counts and patterns come from the pinned original data. Linking by item name does not prove that an item, station or recipe exists in RealmCraft. Other Minecraft versions may also differ."
                         : "Zutatenmengen und Muster stammen aus den festgehaltenen Originaldaten. Die Zuordnung über Namen beweist nicht, dass Gegenstand, Station oder Rezept in RealmCraft vorhanden sind. Auch andere Minecraft-Versionen können abweichen.")
                    Link(english ? "Mojang original data (client JAR download)" : "Mojang-Originaldaten (Client-JAR herunterladen)", destination: index.catalog.sourceURL)
                    Text("SHA-1: " + index.catalog.sourceSHA1).font(.caption2)
                }.padding(.top, 10)
            }
        }
    }
    private func ingredientRow(_ ingredient: CraftingIngredient, number: Int, batches: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)").font(.caption.bold()).frame(width: 22, height: 22).background(.quaternary, in: Circle())
            Text("\(ingredient.count * batches) ×").font(.headline).monospacedDigit().frame(minWidth: 50, alignment: .trailing)
            VStack(alignment: .leading, spacing: 6) {
                if ingredient.options.count == 1, let id = ingredient.options.first {
                    Button { openItem(id) } label: {
                        CraftingItemLabel(id: id, index: index, english: english)
                    }.buttonStyle(.plain).foregroundStyle(Color.accentColor)
                } else {
                    Text(english ? "Total from these alternatives:" : "Insgesamt aus diesen Alternativen:").font(.callout)
                    DisclosureGroup(ingredient.options.prefix(2).map { index.items[$0]?.title.value(english) ?? $0 }.joined(separator: english ? " or " : " oder ") + (ingredient.options.count > 2 ? " … (\(ingredient.options.count))" : "")) {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(ingredient.options, id: \.self) { id in
                                Button { openItem(id) } label: {
                                    CraftingItemLabel(id: id, index: index, english: english)
                                }.buttonStyle(.plain).foregroundStyle(Color.accentColor)
                            }
                        }.padding(.vertical, 6)
                    }.font(.caption)
                }
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 4)
    }
}

private struct CraftingRecipeGrid: View {
    let recipe: CraftingRecipe
    let index: CraftingIndex
    let english: Bool
    @Environment(\.companionTheme) private var theme
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: recipe.station.gridSize), spacing: 6) {
            ForEach(recipe.grid.indices, id: \.self) { offset in
                let number = recipe.grid[offset]
                VStack(spacing: 3) {
                    if number > 0, number <= recipe.ingredients.count,
                       let id = recipe.ingredients[number - 1].options.first, let item = index.items[id] {
                        HStack(spacing: 5) {
                            Text("\(number)").font(.headline).foregroundStyle(theme.accent)
                            CraftingItemIcon(itemID: item.itemID, english: english, size: 28)
                        }
                        Text(item.title.value(english)).font(.caption2).multilineTextAlignment(.center).lineLimit(2)
                    } else {
                        Text("·").foregroundStyle(.tertiary).accessibilityLabel(english ? "Empty slot" : "Leeres Feld")
                    }
                }.frame(maxWidth: .infinity).frame(height: 68).padding(4)
                    .background(theme.surface).overlay(RoundedRectangle(cornerRadius: 3).stroke(theme.border))
                    .accessibilityElement(children: .combine)
            }
        }.frame(maxWidth: 350)
    }
}

private struct CraftingAcquisitionView: View {
    let item: CraftingItem
    let guide: CraftingAcquisition
    let index: CraftingIndex
    let english: Bool
    @ObservedObject var agentLibrary: CraftingAgentLibrary
    let openItem: (String) -> Void
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(english ? "How to obtain this item" : "So bekommst du den Gegenstand", systemImage: "hand.point.up.left")
                .font(.title3.weight(.semibold))
            CraftingAgentControls(library: agentLibrary, instruction: .acquisition(item: item.id, guide: guide), index: index, english: english)
            Text(guide.method.value(english)).font(.headline)
            Text(guide.summary.value(english))
            Label(guide.evidence.value(english), systemImage: "info.circle")
                .font(.caption).foregroundStyle(.orange)
            GroupBox {
                Text(guide.requirements.value(english)).frame(maxWidth: .infinity, alignment: .leading).padding(8)
            } label: { Text(english ? "You need" : "Du brauchst").font(.headline) }
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(guide.steps.enumerated()), id: \.element.id) { number, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(number + 1)").font(.headline).frame(width: 28, height: 28).background(.quaternary, in: Circle())
                        VStack(alignment: .leading, spacing: 5) {
                            Text(step.title.value(english)).font(.headline)
                            Text(step.text.value(english))
                        }
                    }
                }
            }
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(guide.details) { detail in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(detail.title.value(english)).font(.subheadline.weight(.semibold))
                            Text(detail.text.value(english))
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
            } label: { Text(english ? "Things to know" : "Besonderheiten").font(.headline) }
            if !guide.relatedItems.isEmpty {
                DisclosureGroup(english ? "Look up prerequisites & related items" : "Voraussetzungen & passende Gegenstände nachschlagen") {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(guide.relatedItems, id: \.self) { id in
                            if let related = index.items[id] {
                                Button { openItem(id) } label: {
                                    Label(related.title.value(english), systemImage: "arrow.turn.down.right")
                                }.buttonStyle(.plain)
                            }
                        }
                    }.padding(.top, 10)
                }
            }
            Button {
                NSPasteboard.general.clearContents()
                copied = NSPasteboard.general.setString(guide.report(item: item, english: english), forType: .string)
            } label: { Label(copied ? (english ? "Guide copied" : "Anleitung kopiert") : (english ? "Copy guide & sources" : "Anleitung & Quellen kopieren"), systemImage: "doc.on.doc") }
            DisclosureGroup(english ? "Sources & evidence · checked \(guide.checked)" : "Quellen & Datenlage · geprüft \(guide.checked)") {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(guide.sources) { source in
                        VStack(alignment: .leading, spacing: 4) {
                            Link(source.title.value(english), destination: source.url)
                            Text(source.scope.value(english)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }.padding(.top, 10)
            }
        }.fixedSize(horizontal: false, vertical: true)
    }
}
