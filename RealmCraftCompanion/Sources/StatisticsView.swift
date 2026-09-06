import SwiftUI

struct StatisticsView: View {
    @ObservedObject var model: Model
    let language: String
    @State private var snapshot: WorldStatistics?
    @State private var source = ""
    @State private var failure: String?
    @State private var sourceKey = ""
    @Environment(\.companionTheme) private var theme
    private var english: Bool { language == "en" }
    private var selectionKey: String { model.library.root.path + ":" + (model.selection ?? "") }
    private var current: WorldStatistics? { sourceKey == selectionKey ? snapshot : nil }

    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Statistics · Beta" : "Statistiken · Beta") {
                Button(english ? "Read statistics" : "Statistik auslesen", action: read)
                    .buttonStyle(CompanionButtonStyle(prominent: true))
                    .disabled(model.selected == nil || model.busy || model.scanning)
            }
            VStack(alignment: .leading, spacing: 10) {
                Picker(english ? "Backup" : "Sicherung", selection: $model.selection) {
                    Text(english ? "Choose a backup" : "Sicherung wählen").tag(Optional<String>.none)
                    ForEach(model.saves) { save in
                        Text(save.title + " · " + displayDate(save.date, language: language) + " · " + save.world).tag(Optional(save.id))
                    }
                }.frame(maxWidth: 700).disabled(model.busy || model.scanning)
                Text(english ? "Reads a local backup with checksum verification. To see new activity, first create a new backup in Savegames." : "Liest eine lokale Sicherung mit Prüfsummenprüfung. Für neue Aktivitäten zuerst unter Savegames eine neue Sicherung erstellen.")
                    .font(.caption).foregroundStyle(.secondary)
                if model.busy { HStack { ProgressView().controlSize(.small); Text(tr(model.status)).font(.caption) } }
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let failure { Label(failure, systemImage: "exclamationmark.triangle").foregroundStyle(.orange).textSelection(.enabled) }
                    if let value = current {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(english ? "Build/dig actions" : "Bau-/Abbauaktionen").font(.title2.bold())
                                Spacer()
                                Text("BETA").font(.caption.bold()).padding(.horizontal, 9).padding(.vertical, 5)
                                    .background(theme.accent.opacity(0.14)).clipShape(Capsule())
                            }
                            Text(value.buildDigActions.formatted(.number.locale(Locale(identifier: language))))
                                .font(.system(size: 44, weight: .bold, design: .rounded)).monospacedDigit().textSelection(.enabled)
                            Text(value.worldName + " · " + String(value.worldID)).font(.headline)
                            Text(source).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                            Divider()
                            Text(english ? "Directly read game counter: building and digging both increase this shared world total. It cannot be split by action, material or player. Repeated actions at the same position can count again." : "Direkt gelesener Spielzähler: Bauen und Abbauen erhöhen dieselbe Weltsumme. Keine Aufteilung nach Aktion, Material oder Spieler. Wiederholte Aktionen an derselben Position können erneut zählen.")
                                .fixedSize(horizontal: false, vertical: true)
                            Text(english ? "Beta refers to coverage: special tools and other game versions are not yet fully validated. This is not a count of mined blocks alone, and is not an estimate of missing history." : "Beta betrifft die Abdeckung: Sonderwerkzeuge und andere Spielversionen sind noch nicht vollständig geprüft. Dies ist keine reine Abbauzahl und keine Schätzung fehlender Spielhistorie.")
                                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }.padding(22).background(theme.surface).clipShape(RoundedRectangle(cornerRadius: theme.radius))
                    } else if failure == nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(english ? "Your world's activity" : "Die Aktivitäten deiner Welt", systemImage: "chart.bar.xaxis").font(.title2.bold())
                            Text(model.saves.isEmpty
                                 ? (english ? "First import or create a backup in Savegames." : "Zuerst unter Savegames eine Sicherung importieren oder erstellen.")
                                 : (english ? "Choose a backup and read its saved build/dig counter." : "Wähle eine Sicherung und lies ihren gespeicherten Bau-/Abbauzähler aus."))
                                .foregroundStyle(.secondary)
                        }.padding(.vertical, 16)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        Text(english ? "Historical statistics not currently readable" : "Historische Statistiken derzeit nicht auslesbar").font(.headline)
                        unavailable(english ? "Blocks mined / resources collected by type" : "Abgebaute Blöcke / gesammelte Ressourcen je Typ",
                                    english ? "No separate historical counters identified. Current inventory and chest contents are available in Player and Chests." : "Keine getrennten historischen Zähler identifiziert. Aktuelle Bestände findest du unter Spieler und Kisten.")
                        unavailable(english ? "Animals and mobs killed" : "Getötete Tiere und Mobs",
                                    english ? "No saved totals by creature type identified." : "Keine gespeicherten Summen nach Kreaturentyp identifiziert.")
                        unavailable(english ? "Distance travelled, deaths and crafting totals" : "Zurückgelegter Weg, Todesfälle und Crafting-Summen",
                                    english ? "No reliable saved lifetime counters identified. Missing data is not zero." : "Keine verlässlichen gespeicherten Gesamtzähler identifiziert. Fehlende Daten bedeuten nicht null.")
                    }
                }.padding(CompanionLayout.pageInset).frame(maxWidth: 1000, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onChange(of: selectionKey) { _, newKey in
            // A fast read can finish before SwiftUI delivers this change notification.
            // Preserve an already-loaded result belonging to the new selection.
            if sourceKey != newKey { snapshot = nil; source = ""; failure = nil; sourceKey = "" }
        }
    }

    private func unavailable(_ title: String, _ explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: "minus.circle").font(.callout.weight(.medium))
            Text(explanation).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func read() {
        guard let save = model.selected, !model.busy, !model.scanning else { return }
        let key = selectionKey, library = model.library, en = english
        snapshot = nil; failure = nil; sourceKey = ""
        model.work(en ? "Reading statistics…" : "Statistik wird gelesen …") {
            do {
                let value = try StatisticsReader.parse(library.readStatisticsData(save), expectedWorld: save.world)
                DispatchQueue.main.async {
                    guard selectionKey == key else { return }
                    snapshot = value; sourceKey = key
                    source = save.title + " · " + displayDate(save.date, language: en ? "en" : "de")
                }
                return en ? "Statistics ready. Backup unchanged." : "Statistik bereit. Sicherung unverändert."
            } catch {
                DispatchQueue.main.async {
                    guard selectionKey == key else { return }
                    failure = en ? "Statistics could not be read. No value is displayed; see the error details." : "Statistik konnte nicht gelesen werden. Es wird kein Wert angezeigt; Details in der Fehlermeldung."
                }
                throw error
            }
        }
    }
}
