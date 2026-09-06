import SwiftUI

struct CompanionHomeActivityView: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @ObservedObject private var activity = CompanionActivity.shared
    let language: String
    let open: (CompanionFeature, String?) -> Void
    let generateMap: () -> Void
    let generateExport: () -> Void
    private var en: Bool { language == "en" }
    private var backup: Savegame? {
        model.saves.filter { $0.source == "Quest → Mac" || $0.source == "Automatische Sicherung" }.max { $0.date < $1.date }
    }
    var body: some View {
        VStack(spacing: 0) {
            row(title: en ? "Last backup" : "Letztes Backup", icon: "archivebox", date: backup?.date,
                detail: backup?.title ?? (en ? "No device backup in this library yet" : "Noch keine Gerätesicherung in dieser Bibliothek"),
                action: en ? "Back up" : "Sichern", disabled: model.busy || model.scanning || model.serial.isEmpty || model.world.isEmpty || model.setup.package.isEmpty,
                show: { open(.saves, backup?.id) }, run: { model.backup() })
            Divider()
            let map = activity.latest("map", root: model.library.root)
            row(title: en ? "Last map generation" : "Letzte Kartenerstellung", icon: "map", date: map?.date,
                detail: detail(map), action: en ? "Generate" : "Erstellen", disabled: model.busy || maps.checking || model.saves.isEmpty,
                show: { open(.maps, map?.saveID) }, run: generateMap)
            Divider()
            let export = activity.latest("export", root: model.library.root)
            row(title: en ? "Last AI export" : "Letzter KI-Export", icon: "doc.text.magnifyingglass", date: export?.date,
                detail: detail(export), action: en ? "New export" : "Neuer Export", disabled: model.busy || model.saves.isEmpty,
                show: { open(.aiExport, export?.saveID) }, run: generateExport)
        }
        .onAppear { activity.recoverMap(saves: model.saves.map { (id: $0.id, title: $0.title) }, root: model.library.root, support: maps.support); maps.check(model) }
        .onChange(of: model.library.root) { _, _ in activity.recoverMap(saves: model.saves.map { (id: $0.id, title: $0.title) }, root: model.library.root, support: maps.support) }
        .onChange(of: model.saves) { _, _ in activity.recoverMap(saves: model.saves.map { (id: $0.id, title: $0.title) }, root: model.library.root, support: maps.support) }
    }
    private func detail(_ record: CompanionActivityRecord?) -> String {
        guard let record else { return en ? "Not recorded yet" : "Bisher nicht erfasst" }
        let missing = !FileManager.default.fileExists(atPath: record.path)
        return record.title + (record.recovered ? (en ? " · folder creation date" : " · Erstellungsdatum des Kartenordners") : "") +
            (missing ? (en ? " · file no longer available" : " · Datei nicht mehr vorhanden") : "")
    }
    private func row(title: String, icon: String, date: Date?, detail: String, action: String, disabled: Bool,
                     show: @escaping () -> Void, run: @escaping () -> Void) -> some View {
        HStack(spacing: 20) {
            Button(action: show) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: icon).font(.title2).frame(width: 30).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title).font(.callout).foregroundStyle(.secondary)
                        if let date { Text(date.formatted(date: .abbreviated, time: .shortened)).font(.headline) }
                        else { Text("—").font(.headline) }
                        Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain).disabled(model.busy)
            Button(action, action: run).buttonStyle(CompanionButtonStyle(width: 120)).disabled(disabled)
        }.padding(.vertical, 16)
    }
}
