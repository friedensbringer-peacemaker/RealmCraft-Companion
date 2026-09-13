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
    @State private var planAddition: (recipe: CraftingRecipe, quantity: Int)?
    private var english: Bool { language == "en" }
    init(language: String, catalog: CraftingCatalog? = nil, initialItem: String = "crafting_table", initialQuery: String = "", planURL: URL = CraftingPlanStorage.defaultURL) {
        self.language = language
        self.planURL = planURL
        result = catalog.map { .success($0.index()) } ?? Self.bundled
        _selected = State(initialValue: initialItem)
        _query = State(initialValue: initialQuery)
    }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Crafting / Recipes" : "Crafting / Rezepte") {
                Button { showIcons = true } label: { Label(english ? "Item icons" : "Gegenstands-Icons", systemImage: "photo") }
                Button(english ? "Material plan" : "Materialplan") {
                    planAddition = nil; showMaterialPlan = true
                }.disabled({ if case .failure = result { return true }; return false }())
                TextField(english ? "Item, alias or ID" : "Gegenstand, Begriff oder ID", text: $query)
                    .textFieldStyle(.roundedBorder).frame(width: CompanionLayout.searchWidth)
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
        let visible = index.filtered(query: query, category: category, station: station, coverage: coverage, english: english)
        let groups = CraftingBrowseGroup.make(visible, english: english)
        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                CompanionDetails(english ? "Catalog scope & counts" : "Katalogumfang & Anzahl") {
                Text(english ? "\(index.catalog.items.filter { $0.itemID != nil }.count) catalog entries · \(index.catalog.recipes.count) comparison recipes · \(index.recipes.count) items with recipes"
                     : "\(index.catalog.items.filter { $0.itemID != nil }.count) Katalogeinträge · \(index.catalog.recipes.count) Vergleichsrezepte · \(index.recipes.count) Gegenstände mit Rezept")
                    .font(.subheadline.weight(.semibold))
                }.font(.caption)
                Text(english ? "Recipes, stations and name mappings are Minecraft references, unverified in RealmCraft VR. RealmCraft wiki evidence is noted separately. This is not a complete, confirmed list of game content."
                     : "Rezepte, Stationen und Namenszuordnungen sind Minecraft-Referenzen, in RealmCraft VR ungeprüft. RealmCraft-Wiki-Belege stehen separat dabei. Dies ist keine vollständige, bestätigte Liste der Spielinhalte.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(english ? "\(visible.count) matches · \(activeFilterCount) active filters" : "\(visible.count) Treffer · \(activeFilterCount) aktive Filter").font(.caption)
                    Spacer()
                    if activeFilterCount > 0 || !query.isEmpty {
                        Button(english ? "Reset" : "Zurücksetzen") { resetFilters() }.font(.caption)
                    }
                }
                DisclosureGroup(english ? "Category, station & evidence" : "Kategorie, Herstellungsort & Datenlage", isExpanded: $showFilters) {
                  VStack(alignment: .leading, spacing: 8) {
                    Picker(english ? "Category" : "Kategorie", selection: $category) {
                        Text(english ? "All categories" : "Alle Kategorien").tag("all")
                        ForEach(["blocks", "tools", "armor", "food", "transport", "circuits", "materials"], id: \.self) { key in
                            Text(categoryTitle(key)).tag(key)
                        }
                    }
                    Picker(english ? "Station" : "Herstellungsort", selection: $station) {
                        Text(english ? "All stations" : "Alle Stationen").tag("all")
                        ForEach(CraftingStation.allCases, id: \.rawValue) { value in Text(value.title(english)).tag(value.rawValue) }
                    }
                    Picker(english ? "Coverage" : "Datenlage", selection: $coverage) {
                        Text(english ? "All entries" : "Alle Einträge").tag("all")
                        Text(english ? "With recipe" : "Mit Rezept").tag("recipes")
                        Text(english ? "Recipe open" : "Rezept offen").tag("open")
                        Text(english ? "Wiki evidence" : "Mit Wiki-Beleg").tag("wiki")
                    }
                  }.font(.caption).padding(.top, 6)
                }
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            Divider()
            HSplitView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(english ? "\(visible.count) matches · by type" : "\(visible.count) Treffer · nach Typ").font(.caption).foregroundStyle(.secondary).padding(12)
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
                        CraftingItemDetail(item: item, index: index, english: english, openItem: openItem, addToPlan: { recipe, quantity in
                            planAddition = (recipe, quantity); showMaterialPlan = true
                        }).id(selected)
                    } else {
                        ContentUnavailableView(english ? "Choose an item" : "Gegenstand auswählen", systemImage: "square.grid.3x3")
                    }
                }.frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { applyLookup(index) }
        .onChange(of: lookup) { _, _ in applyLookup(index) }
        .onChange(of: query) { _, _ in synchronizeSelection(index) }
        .onChange(of: category) { _, _ in synchronizeSelection(index) }
        .onChange(of: station) { _, _ in synchronizeSelection(index) }
        .onChange(of: coverage) { _, _ in synchronizeSelection(index) }
        .sheet(isPresented: $showMaterialPlan) {
            CraftingPlanView(index: index, english: english, addition: planAddition, url: planURL)
        }
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
                Text(recipes.isEmpty ? (english ? "Recipe open" : "Rezept offen") : (english ? "\(recipes.count) reference recipe(s)" : "\(recipes.count) Rezeptreferenz(en)"))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 4).tag(item.id)
    }
    private func synchronizeSelection(_ index: CraftingIndex) {
        let visible = CraftingBrowseGroup.make(index.filtered(query: query, category: category, station: station, coverage: coverage, english: english), english: english).flatMap(\.items)
        if !visible.contains(where: { $0.id == selected }) { selected = visible.first?.id }
        history = []
    }
    private func resetFilters() { query = ""; category = "all"; station = "all"; coverage = "all" }
    private var activeFilterCount: Int { [category, station, coverage].filter { $0 != "all" }.count }
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
                } else {
                    GroupBox {
                        Text(english ? "No recipe is documented for this entry in this catalog. This does not mean it cannot be crafted. It may be obtained by mining, harvesting, loot, trading, breeding or another process, or belong to a different game version. Check the in-game recipe list."
                             : "Für diesen Eintrag ist hier kein Rezept dokumentiert. Das bedeutet nicht, dass er nicht herstellbar ist. Mögliche Bezugswege sind Abbau, Ernte, Beute, Handel, Zucht oder ein anderes Verfahren; auch eine andere Spielversion ist möglich. Prüfe die Rezeptliste im Spiel.")
                        if item.itemID == nil {
                            Text(english ? "This ingredient belongs to the Minecraft source and has no mapping in the Companion catalog." : "Diese Zutat stammt aus der Minecraft-Quelle und hat keine Zuordnung im Companion-Katalog.").foregroundStyle(.secondary)
                        }
                    } label: { Label(english ? "Recipe open" : "Rezept offen", systemImage: "questionmark.circle") }
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
                Text(english ? "100% vibe-coded with OpenAI Codex · Sources checked \(index.catalog.checked)." : "100 % mit OpenAI Codex entwickelt · Quellen geprüft am \(index.catalog.checked).")
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
            Label(english ? "Minecraft comparison · unverified in RealmCraft VR" : "Minecraft-Vergleich · in RealmCraft VR ungeprüft", systemImage: "info.circle")
                .font(.callout.weight(.medium)).foregroundStyle(.orange)
            if let evidence = recipe.corroboration {
                VStack(alignment: .leading, spacing: 6) {
                    Text(evidence.scope.value(english)).font(.callout)
                    Link(evidence.title, destination: evidence.url).font(.caption)
                }
            }
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
