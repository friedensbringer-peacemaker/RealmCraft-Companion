import SwiftUI

struct BuildMaterialHandoffView: View {
    let guide: BuildGuide
    let blocks: [String: BuildBlock]
    let english: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var index: CraftingIndex?
    @State private var rows: [BuildMaterialReviewRow] = []
    @State private var reviewed = false
    @State private var error = ""
    @State private var addition: CraftingBuildSource?
    var body: some View {
      Group {
        if let source = addition, let index {
            VStack(spacing: 0) {
                Text(english ? "2 of 2 · Preview quantities and save the plan. Close ends this import." : "2 von 2 · Mengen prüfen und Plan speichern. Schließen beendet diese Übernahme.")
                    .font(.callout).padding(12).frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                CraftingPlanView(index: index, english: english, buildAddition: source)
            }
        } else {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(english ? "1 of 2 · Review materials" : "1 von 2 · Materialien prüfen").font(.title2.bold())
                Spacer(); Button(english ? "Close" : "Schließen") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            Text(guide.title.value(english)).font(.headline)
            Text(english ? "Guide and recipes remain unverified in RealmCraft. Generic materials and ranges need your choice; omitted rows stay in the import record. No stock is deducted."
                 : "Anleitung und Rezepte bleiben in RealmCraft ungeprüft. Allgemeine Materialien und Mengenbereiche brauchen deine Auswahl; ausgelassene Zeilen bleiben im Übernahmeprotokoll. Kein Vorrat wird abgezogen.").font(.caption).foregroundStyle(.secondary)
            if !error.isEmpty { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }
            if let index {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(rows.indices, id: \.self) { i in row(i, index: index) }
                    }.padding(3)
                }
                Text("\(rows.filter(\.included).count) / \(rows.count) " + (english ? "rows selected" : "Zeilen ausgewählt")).font(.caption)
                Toggle(english ? "I reviewed mappings, quantities and omitted rows." : "Ich habe Zuordnungen, Mengen und ausgelassene Zeilen geprüft.", isOn: $reviewed)
                Button(english ? "Add to material plan…" : "In Materialplan übernehmen …") {
                    do { addition = try BuildMaterialHandoff.reviewed(guide: guide, rows: rows, index: index); error = "" }
                    catch { self.error = english ? "Select at least one known item with a whole quantity from 1 to 9999; combined quantities must fit this limit." : "Mindestens einen bekannten Gegenstand mit einer ganzen Menge von 1 bis 9999 wählen; zusammengefasste Mengen müssen innerhalb dieser Grenze bleiben." }
                }.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(!reviewed || !rows.contains(where: \.included))
                Text(english ? "The plan opens as an unsaved draft. Save plan is still required; existing targets and choices are preserved." : "Der Plan öffnet sich als ungespeicherter Entwurf. Plan speichern bleibt erforderlich; bestehende Ziele und Auswahlen bleiben erhalten.").font(.caption).foregroundStyle(.secondary)
            } else { Spacer() }
        }.padding(22).frame(minWidth: 640, idealWidth: 820, minHeight: 480, idealHeight: 640)
        }
      }
        .onAppear {
            guard index == nil else { return }
            do { let value = try CraftingCatalog.load().index(); index = value; rows = BuildMaterialHandoff.rows(guide: guide, blocks: blocks, index: value, english: english) }
            catch { self.error = error.localizedDescription }
        }
        .onChange(of: rows.map { [$0.item, $0.quantity, String($0.included)] }) { _, _ in reviewed = false }
    }
    private func row(_ i: Int, index: CraftingIndex) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 9) {
                Toggle("\(rows[i].originalCount) × \(rows[i].name)", isOn: $rows[i].included).font(.headline)
                HStack {
                    if let item = index.items[rows[i].item] {
                        CraftingItemLabel(id: item.id, index: index, english: english)
                    } else { Label(english ? "Unmapped · choose an item" : "Nicht zugeordnet · Gegenstand wählen", systemImage: "questionmark.square.dashed").foregroundStyle(.orange) }
                    Spacer()
                    TextField(english ? "Quantity" : "Menge", text: $rows[i].quantity).textFieldStyle(.roundedBorder).frame(width: 90)
                        .accessibilityLabel(english ? "Quantity for \(rows[i].name)" : "Menge für \(rows[i].name)")
                }
                TextField(english ? "Change item · search name or ID" : "Gegenstand ändern · Name oder ID suchen", text: $rows[i].query).textFieldStyle(.roundedBorder)
                if !rows[i].query.trimmingCharacters(in: .whitespaces).isEmpty {
                    let matches = Array(index.filtered(query: rows[i].query, english: english).prefix(8))
                    if matches.isEmpty { Text(english ? "No matching items" : "Keine passenden Gegenstände").font(.caption) }
                    ForEach(matches) { item in
                        Button { rows[i].item = item.id; rows[i].included = true; rows[i].query = ""; reviewed = false } label: {
                            CraftingItemLabel(id: item.id, index: index, english: english)
                        }
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
