import SwiftUI
import UniformTypeIdentifiers

struct CraftingPlanView: View {
    let index: CraftingIndex
    let english: Bool
    let addition: (recipe: CraftingRecipe, quantity: Int)?
    let buildAddition: CraftingBuildSource?
    @Environment(\.draftTransitions) private var drafts
    @State private var draftID = UUID()
    @Environment(\.dismiss) private var dismiss
    @State private var plan: CraftingPlan
    @State private var baseline: CraftingPlan
    @State private var error = ""
    @State private var loaded = false
    @State private var canSave = false
    @State private var confirmClose = false
    @State private var confirmReload = false
    @State private var confirmReset = false
    @State private var notice = ""
    @State private var targetSearch = ""
    @State private var showIcons = false
    private let storage: CraftingPlanStorage
    init(index: CraftingIndex, english: Bool, addition: (recipe: CraftingRecipe, quantity: Int)? = nil, buildAddition: CraftingBuildSource? = nil, url: URL = CraftingPlanStorage.defaultURL) {
        self.index = index; self.english = english; self.addition = addition; self.buildAddition = buildAddition
        let empty = CraftingPlan(catalog: CraftingPlan.fingerprint(index))
        storage = CraftingPlanStorage(url: url, empty: empty)
        _plan = State(initialValue: empty); _baseline = State(initialValue: empty)
    }
    private var dirty: Bool { plan != baseline }
    private var result: CraftingPlanResult { CraftingPlanCalculator.calculate(plan, index: index, english: english) }
    private func name(_ id: String) -> String { index.items[id]?.title.value(english) ?? id }
    var body: some View {
        let calculation = result
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(english ? "Material plan" : "Materialplan").font(.title2.bold())
                if dirty { Text(english ? "Unsaved" : "Ungespeichert").foregroundStyle(.orange) }
                Spacer()
                Button { showIcons = true } label: { Label(english ? "Item icons" : "Gegenstands-Icons", systemImage: "photo") }
                Button(english ? "Close" : "Schließen") { if dirty { confirmClose = true } else { dismiss() } }
            }
            Text(english ? "Minecraft comparison · unverified in RealmCraft VR. No stock deduction. Fuel and station construction are not included."
                 : "Minecraft-Vergleich · in RealmCraft VR ungeprüft. Kein Vorratsabzug. Brennstoff und Stationsbau sind nicht enthalten.")
                .font(.callout).foregroundStyle(.secondary)
            if !error.isEmpty { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            if !notice.isEmpty { Text(notice).font(.callout).foregroundStyle(.secondary) }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    GroupBox(english ? "Targets" : "Ziele") {
                        VStack(alignment: .leading) {
                            TextField(english ? "Add a target · name or ID" : "Ziel ergänzen · Name oder ID", text: $targetSearch).textFieldStyle(.roundedBorder)
                            if !targetSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                let matches = index.filtered(query: targetSearch, english: english)
                                Text(english ? "\(matches.count) matches · up to 8 shown" : "\(matches.count) Treffer · maximal 8 angezeigt").font(.caption).foregroundStyle(.secondary)
                                ForEach(Array(matches.prefix(8))) { item in
                                    Button {
                                        let old = plan.targets[item.id, default: 0]
                                        guard old < 9999, old > 0 || plan.targets.count < 50 else {
                                            error = english ? "Limit: 50 targets, 9999 items each." : "Grenze: 50 Ziele, je 9999 Stück."
                                            return
                                        }
                                        plan.targets[item.id] = old + 1; targetSearch = ""
                                        notice = english ? "Target added; adjust its quantity below." : "Ziel ergänzt; Menge unten anpassen."
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle")
                                            CraftingItemLabel(id: item.id, index: index, english: english)
                                        }
                                    }
                                        .disabled(!canSave)
                                }
                            }
                            if plan.targets.isEmpty {
                                Text(english ? "Search above or open a recipe and choose Add to material plan."
                                     : "Suche oben oder öffne ein Rezept und wähle Zum Materialplan hinzufügen.")
                            }
                            ForEach(plan.targets.keys.sorted(), id: \.self) { item in
                                HStack {
                                    CraftingItemLabel(id: item, index: index, english: english).frame(maxWidth: .infinity, alignment: .leading)
                                    TextField("", value: Binding(get: { plan.targets[item, default: 1] }, set: { plan.targets[item] = min(9999, max(1, $0)) }), format: .number.grouping(.never))
                                        .textFieldStyle(.roundedBorder).frame(width: 85).accessibilityLabel(name(item))
                                    Button(english ? "Remove" : "Entfernen") { plan.targets.removeValue(forKey: item) }
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Picker(english ? "Calculation" : "Berechnung", selection: $plan.recursive) {
                        Text(english ? "Direct ingredients" : "Direkte Zutaten").tag(false)
                        Text(english ? "Expand intermediate products" : "Zwischenprodukte auflösen").tag(true)
                    }.pickerStyle(.segmented)
                    if !calculation.choices.isEmpty {
                        GroupBox(english ? "Recipes & alternatives" : "Rezepte & Alternativen") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(english ? "One production route per item. Supply stops expansion, including reversible recipes. Each ingredient group uses one selected alternative."
                                     : "Ein Herstellungsweg je Gegenstand. Bereitstellen stoppt die Auflösung, auch bei umkehrbaren Rezepten. Jede Zutatengruppe verwendet genau eine gewählte Alternative.")
                                    .font(.caption).foregroundStyle(.secondary)
                                ForEach(calculation.choices) { choice in choicePicker(choice) }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    ForEach(Array(calculation.issues.enumerated()), id: \.offset) { _, issue in
                        Label(issue, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                    }
                    if !calculation.complete {
                        Text(english ? "Incomplete: resolve choices and issues before quantities can be shown or exported."
                             : "Unvollständig: erst Auswahlen und Probleme klären, dann können Mengen angezeigt oder exportiert werden.").font(.headline)
                    } else if !plan.targets.isEmpty {
                        GroupBox(english ? "Supply · not further expanded" : "Bereitstellen · nicht weiter aufgelöst") {
                            VStack(alignment: .leading, spacing: 7) {
                                Text(english ? "These are not necessarily raw materials. Missing recipes are not proof that an item cannot be crafted."
                                     : "Dies sind nicht zwingend Grundstoffe. Fehlende Rezepte bedeuten nicht, dass ein Gegenstand nicht herstellbar ist.").font(.caption).foregroundStyle(.secondary)
                                ForEach(calculation.materials.keys.sorted(), id: \.self) { item in
                                    CraftingItemLabel(id: item, index: index, english: english, quantity: calculation.materials[item])
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        GroupBox(english ? "Crafting steps & surplus" : "Herstellungsschritte & Überschuss") {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(calculation.steps.enumerated()), id: \.offset) { offset, step in
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(alignment: .top) {
                                            CraftingItemIcon(itemID: index.items[step.recipe.output]?.itemID, english: english)
                                            Text("\(offset + 1). \(name(step.recipe.output)) · \(step.batches) × \(step.recipe.station.title(english)) → \(step.produced) · \(english ? "extra" : "übrig"): \(step.produced - step.required)")
                                        }
                                        Text(step.recipe.id).font(.caption).foregroundStyle(.secondary)
                                        if step.recipe.station.usesFuel { Label(english ? "Additional fuel required; quantity unverified" : "Zusätzlicher Brennstoff erforderlich; Menge ungeprüft", systemImage: "flame").font(.caption) }
                                    }
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }.padding(2)
            }
            HStack {
                Button(english ? "Save plan" : "Plan speichern") { save() }.disabled(!canSave || !dirty)
                Button(english ? "Reload" : "Neu laden") { if dirty { confirmReload = true } else { reload() } }
                Button(english ? "Reset choices" : "Auswahl zurücksetzen") { confirmReset = true }.disabled(!canSave)
                Spacer()
                Button(english ? "Copy" : "Kopieren") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(report(calculation), forType: .string)
                    notice = english ? "Plan copied with source and scope notes." : "Plan mit Quellen und Gültigkeitshinweisen kopiert."
                }.disabled(!calculation.complete || plan.targets.isEmpty || !canSave)
                Button(english ? "Export text…" : "Text exportieren …") { export(calculation) }
                    .disabled(!calculation.complete || plan.targets.isEmpty || !canSave)
            }
            if let sources = plan.buildSources, !sources.isEmpty {
                Text((english ? "Reviewed guide imports: " : "Geprüfte Bauplan-Übernahmen: ") + sources.map { english ? $0.enTitle : $0.deTitle }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Text(english ? "One local plan, independent of savegames. Save before closing. Targets can be added directly above."
                 : "Ein lokaler Plan, unabhängig von Spielständen. Vor dem Schließen speichern. Weitere Ziele lassen sich direkt oben ergänzen.").font(.caption).foregroundStyle(.secondary)
        }.padding(22).frame(minWidth: 800, idealWidth: 960, minHeight: 580, idealHeight: 740)
        .trackDraft(drafts, id: draftID, token: DraftTransitions.fingerprint(plan), dirty: { dirty }, title: english ? "Material plan" : "Materialplan", save: { canSave && save() }, discard: { plan = baseline })
        .interactiveDismissDisabled(dirty)
        .sheet(isPresented: $showIcons) { ItemIconSettings(english: english) }
        .onAppear {
            guard !loaded else { return }; loaded = true
            reload()
            if canSave, let source = buildAddition {
                do { plan = try plan.adding(source, index: index); notice = english ? "Reviewed guide materials added. Save the plan explicitly." : "Geprüfte Baumaterialien ergänzt. Plan ausdrücklich speichern." }
                catch { self.error = english ? "Import not applied: catalog mismatch or plan limits. Existing plan is unchanged." : "Übernahme nicht angewendet: Katalogabweichung oder Plangrenzen. Bestehender Plan unverändert." }
            }
            if canSave, let addition {
                let item = addition.recipe.output, old = plan.targets[addition.recipe.output, default: 0]
                if (plan.targets[item] != nil || plan.targets.count < 50), old + addition.quantity <= 9999 {
                    plan.targets[item] = old + addition.quantity
                    if old == 0 { plan.recipes[item] = addition.recipe.id }
                    notice = english ? "Target added. Existing production choices are retained for repeated targets." : "Ziel ergänzt. Bei wiederholten Zielen bleibt der gewählte Herstellungsweg erhalten."
                } else { error = english ? "Target not added: limit of 50 targets or 9999 items exceeded." : "Ziel nicht ergänzt: Grenze von 50 Zielen oder 9999 Stück überschritten." }
            }
        }
        .confirmationDialog(english ? "Discard unsaved changes?" : "Ungespeicherte Änderungen verwerfen?", isPresented: $confirmClose) {
            Button(english ? "Discard and close" : "Verwerfen und schließen", role: .destructive) { dismiss() }
            Button(english ? "Save and close" : "Speichern und schließen") { if save() { dismiss() } }.disabled(!canSave)
        }
        .confirmationDialog(english ? "Discard changes and reload?" : "Änderungen verwerfen und neu laden?", isPresented: $confirmReload) {
            Button(english ? "Reload" : "Neu laden", role: .destructive) { reload() }
        }
        .confirmationDialog(english ? "Reset all recipe and ingredient choices? Targets are retained." : "Alle Rezept- und Zutatenauswahlen zurücksetzen? Ziele bleiben erhalten.", isPresented: $confirmReset) {
            Button(english ? "Reset choices" : "Auswahl zurücksetzen", role: .destructive) {
                plan.recipes = [:]; plan.alternatives = [:]; plan.catalog = CraftingPlan.fingerprint(index)
            }
        }
    }
    private func choicePicker(_ choice: CraftingPlanChoice) -> some View {
        let label = name(choice.item) + (choice.ingredient.map { " · \(english ? "ingredient" : "Zutat") \($0 + 1)" } ?? "")
        return HStack(alignment: .top) {
            CraftingItemIcon(itemID: index.items[choice.ingredient != nil && !choice.selected.isEmpty ? choice.selected : choice.item]?.itemID, english: english)
            Picker(label, selection: Binding(get: { choice.selected }, set: { value in
            if choice.ingredient != nil { plan.alternatives[choice.id] = value }
            else { plan.recipes[choice.id] = value }
        })) {
            Text(english ? "Choose…" : "Bitte auswählen …").tag("")
            ForEach(choice.options, id: \.self) { option in
                Text(optionTitle(option, choice: choice)).tag(option)
            }
        }.foregroundStyle(choice.selected.isEmpty ? Color.orange : Color.primary)
        }
    }
    private func optionTitle(_ option: String, choice: CraftingPlanChoice) -> String {
        if choice.ingredient != nil { return name(option) }
        if option == CraftingPlan.supply { return english ? "Supply / stop expansion" : "Bereitstellen / nicht weiter auflösen" }
        let recipe = index.recipes[choice.item, default: []].first { $0.id == option }
        return (recipe?.station.title(english) ?? "") + " · " + option
    }
    private func reload() {
        do { let value = try storage.load(); baseline = value; plan = value; canSave = true; error = ""; notice = "" }
        catch { self.error = error.localizedDescription; canSave = false }
    }
    @discardableResult private func save() -> Bool {
        do { try storage.save(plan, replacing: baseline); baseline = plan; error = ""; notice = english ? "Plan saved." : "Plan gespeichert."; return true }
        catch { self.error = error.localizedDescription; return false }
    }
    private func report(_ result: CraftingPlanResult) -> String { CraftingPlanCalculator.report(plan, result: result, index: index, english: english) }
    private func export(_ result: CraftingPlanResult) {
        let panel = NSSavePanel(); panel.allowedContentTypes = [.plainText]; panel.nameFieldStringValue = "material-plan.txt"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try report(result).write(to: url, atomically: true, encoding: .utf8); notice = english ? "Text exported." : "Text exportiert." }
        catch { self.error = error.localizedDescription }
    }
}
