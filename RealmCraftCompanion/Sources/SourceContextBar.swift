import SwiftUI

struct SourceContextBar: View {
    let saves: [Savegame]
    @Binding var selection: String?
    let language: String
    var dimension: String? = nil
    var resultDate: Date? = nil
    var compact = false
    private var english: Bool { language == "en" }
    private var save: Savegame? { saves.first { $0.id == selection } }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            backupPicker.companionField(english ? "Backup" : "Sicherung")
            if let save {
                Text((english ? "Saved game state: " : "Gespeicherter Spielstand: ") + displayDate(save.gameDate, language: language) + (english ? " · not live" : " · nicht live"))
                    .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                if !compact && (dimension != nil || resultDate != nil) {
                    Text([dimension.map { $0 == "n" ? "Nether" : (english ? "Overworld" : "Oberwelt") },
                          resultDate.map { (english ? "Result: " : "Ergebnis: ") + displayDate($0, language: language) }].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                DisclosureGroup(english ? "Source details" : "Quelldetails") {
                    if compact && (dimension != nil || resultDate != nil) {
                        Text([dimension.map { $0 == "n" ? "Nether" : (english ? "Overworld" : "Oberwelt") },
                              resultDate.map { (english ? "Result: " : "Ergebnis: ") + displayDate($0, language: language) }].compactMap { $0 }.joined(separator: " · "))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text((english ? "World ID: " : "Welt-ID: ") + save.world + " · " + (english ? "Backup ID: " : "Sicherungs-ID: ") + save.id)
                        .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                }.font(.caption).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).companionActionAligned()
    }
    var backupPicker: some View {
        CompanionPopup(title: english ? "Backup" : "Sicherung", selection: $selection, options: backupOptions)
            .accessibilityIdentifier("source.backup")
    }
    private var backupOptions: [(String?, String)] {
        var options: [(String?, String)] = [(nil, english ? "Choose a backup" : "Sicherung wählen")]
        for row in saves {
            let title = row.title + " · " + displayDate(row.date, language: language) + " · " + String(row.id.suffix(6))
            options.append((row.id, title))
        }
        return options
    }
}
