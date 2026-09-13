import SwiftUI

/// The area control shares the primary action's width and right edge.
struct MapSourceControls: View {
    let saves: [Savegame]
    @Binding var selection: String?
    @Binding var radius: String
    let english: Bool
    @State private var information = false
    private func t(_ de: String, _ en: String) -> String { english ? en : de }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .bottom, spacing: 16) {
                    backup.frame(minWidth: 260)
                    area
                }
                VStack(alignment: .leading, spacing: 12) {
                    backup
                    area.frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            if selection != nil {
                Text(t("Gespeicherter Stand · nicht live", "Saved snapshot · not live"))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.companionActionAligned()
    }
    private var backup: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(t("Sicherung", "Backup")).font(.caption)
                Button { information.toggle() } label: { Image(systemName: "info.circle") }
                    .buttonStyle(.plain).help(t("Quelle und Kartenhinweise", "Source and map information"))
                    .accessibilityLabel(t("Quelle und Kartenhinweise", "Source and map information"))
                    .popover(isPresented: $information) { details.padding(20).frame(width: 380) }
            }
            SourceContextBar(saves: saves, selection: $selection, language: english ? "en" : "de").backupPicker
        }
    }
    private var area: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t("Bereich", "Area")).font(.caption)
            CompanionPopup(title: t("Bereich", "Area"), selection: $radius, options: [
                ("128", t("Ursprung ±128 Blöcke", "Origin ±128 blocks")),
                ("256", t("Ursprung ±256 Blöcke", "Origin ±256 blocks")),
                ("512", t("Ursprung ±512 Blöcke", "Origin ±512 blocks")),
                ("1024", t("Ursprung ±1024 Blöcke", "Origin ±1024 blocks")),
                ("2048", t("Ursprung ±2048 Blöcke", "Origin ±2048 blocks")),
                ("all", t("Alle gespeicherten Chunks", "All saved chunks"))
            ]).accessibilityIdentifier("map.area")
        }.frame(width: CompanionLayout.primaryActionWidth)
    }
    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("Quelle und Kartenhinweise", "Source and map information")).font(.headline)
            if let save = saves.first(where: { $0.id == selection }) {
                Text(save.title).font(.subheadline.bold()).textSelection(.enabled)
                Text(t("Gespeicherter Spielstand: ", "Saved game state: ") + displayDate(save.gameDate, language: english ? "en" : "de"))
                Text(t("Sicherung erstellt: ", "Backup created: ") + displayDate(save.date, language: english ? "en" : "de"))
                Text(t("Welt-ID: ", "World ID: ") + save.world + "\n" + t("Sicherungs-ID: ", "Backup ID: ") + save.id).textSelection(.enabled)
                Divider()
            }
            Text(t("Karten entstehen lokal aus gespeicherten Chunks, nicht aus Live-Daten der Quest. Große Welten können mehrere Minuten dauern. Farben sind schematisch; unbekannte Blöcke können abweichen.", "Maps are built locally from saved chunks, not live Quest data. Large worlds can take several minutes. Colors are schematic; unknown blocks may differ."))
        }.font(.callout).fixedSize(horizontal: false, vertical: true)
    }
}
