import SwiftUI

struct EditorTestExportPlan: Identifiable {
    let id = UUID()
    let save: Savegame
    let sourceTitle: String
    let serial: String
    let package: String
    let root: URL
    let worlds: [String]
}

struct EditorTestExportView: View {
    @ObservedObject var model: Model
    let plan: EditorTestExportPlan
    let english: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var freeSpaceConfirmed = false
    @State private var riskConfirmed = false
    private var contextMatches: Bool { model.serial == plan.serial && model.library.package == plan.package && model.library.root == plan.root }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(english ? "Export a separate test world?" : "Separate Testwelt auf die Quest übertragen?").font(.title2.bold())
            Text("BETA · PREVIEW").font(.caption.bold()).foregroundStyle(.orange)
            Text(english ? "This experimental export can irreversibly damage your savegame and negatively affect your gameplay experience. The new world may not appear or may not load. Multiple worlds are supported; the maximum count and the display order have not been verified." : "Dieser experimentelle Export kann dein Savegame unwiderruflich beschädigen und deine Spielerfahrung negativ beeinträchtigen. Die neue Welt wird möglicherweise nicht angezeigt oder lädt nicht. Mehrere Welten sind möglich; die maximale Anzahl und die Anzeigereihenfolge sind nicht verifiziert.").foregroundStyle(.orange)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow { Text(english ? "Source" : "Quelle"); Text(plan.sourceTitle).lineLimit(3) }
                GridRow { Text("Quest"); Text(plan.serial) }
                GridRow { Text(english ? "New test world" : "Neue Testwelt"); Text("BETA TEST " + plan.save.world).bold() }
                GridRow { Text(english ? "Worlds detected" : "Erkannte Welten"); Text("\(plan.worlds.count) · " + plan.worlds.joined(separator: ", ")) }
            }.textSelection(.enabled)
            Text(english ? "A new world ID is used. Occupied targets are rejected, including a collision during transfer. Existing Quest worlds are checked before and after transfer. The prepared test copy remains in your library." : "Es wird eine neue Welt-ID verwendet. Belegte Ziele werden abgewiesen, auch bei einer Kollision während der Übertragung. Bestehende Quest-Welten werden vorher und nachher geprüft. Die vorbereitete Testkopie bleibt in deiner Bibliothek.").font(.callout).foregroundStyle(.secondary)
            Toggle(english ? "I want to add another world to the world list and have saved and fully closed RealmCraft." : "Ich möchte eine weitere Welt zur Weltliste hinzufügen und habe RealmCraft gespeichert und vollständig beendet.", isOn: $freeSpaceConfirmed)
            Toggle(english ? "I understand the risks and want to transfer this separate beta test world." : "Ich verstehe die Risiken und möchte diese separate Beta-Testwelt übertragen.", isOn: $riskConfirmed)
            if !contextMatches { Text(english ? "Device or library changed. Prepare the export again." : "Gerät oder Bibliothek geändert. Export erneut vorbereiten.").foregroundStyle(.orange) }
            HStack {
                Button(english ? "Cancel" : "Abbrechen") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button(english ? "Transfer test world now" : "Testwelt jetzt übertragen") { export() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!freeSpaceConfirmed || !riskConfirmed || !contextMatches || model.busy)
            }
        }.padding(28).frame(width: 660)
    }
    private func export() {
        guard contextMatches, freeSpaceConfirmed, riskConfirmed else { return }
        let backend = model.library
        dismiss()
        model.work(english ? "Transferring separate beta test world…" : "Separate Beta-Testwelt wird übertragen …") {
            try backend.exportEditorTestWorld(plan.save, serial: plan.serial, expectedPackage: plan.package, expectedWorlds: plan.worlds)
            return english ? "Test world \(plan.save.world) transferred. Check ‘BETA TEST \(plan.save.world)’ in RealmCraft. In-game compatibility remains unverified." : "Testwelt \(plan.save.world) übertragen. In RealmCraft „BETA TEST \(plan.save.world)“ prüfen. Spielkompatibilität weiterhin unbestätigt."
        }
    }
}
