import SwiftUI
import AppKit

struct SavegameStatusView: View {
    @ObservedObject var model: Model
    let save: Savegame
    @AppStorage("appLanguage") private var language = "en"
    @AppStorage("cloudBackupFolder") private var cloudFolder = ""
    @State private var storage: SavegameStorageStatus?
    @State private var cloud: SavegameCloudStatus?
    @State private var error: String?
    @State private var refresh = UUID()
    @Environment(\.companionTheme) private var theme
    private var en: Bool { language == "en" }
    private var taskID: String { "\(save.id)|\(model.library.root.path)|\(model.busy)|\(cloudFolder)|\(refresh)" }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(en ? "Backup & storage status" : "Backup- und Speicherstatus", systemImage: "externaldrive.badge.checkmark").font(.headline)
                Spacer()
                Button { refresh = UUID() } label: { Image(systemName: "arrow.clockwise") }
                    .help(en ? "Check status again" : "Status erneut prüfen").disabled(model.busy)
            }
            if let storage {
                Label(storage.optimizedFiles == 0 ? (en ? "Not optimized" : "Nicht optimiert") : storage.optimizedFiles == storage.files ? (en ? "Optimized" : "Optimiert") : (en ? "Partially optimized" : "Teilweise optimiert"), systemImage: "square.stack.3d.up")
                Text(en ? "\(storage.optimizedFiles) of \(storage.files) files use the shared storage pool; \(storage.sharedFiles) also share storage with other savegames." : "\(storage.optimizedFiles) von \(storage.files) Dateien nutzen den gemeinsamen Speicher; \(storage.sharedFiles) teilen ihn auch mit anderen Spielständen.")
                    .font(.caption).foregroundStyle(.secondary)
                Label(en ? "Independent snapshot · no other savegame required" : "Eigenständiger Spielstand · kein anderes Savegame erforderlich", systemImage: "checkmark.shield")
                Text(en ? "Hard links share storage, not a chain of incremental backups. Deleting another savegame does not remove this snapshot’s files. This checks file structure, not content checksums." : "Hardlinks teilen Speicher, bilden aber keine Kette inkrementeller Backups. Das Löschen eines anderen Savegames entfernt die Dateien dieses Stands nicht. Hier wird die Dateistruktur geprüft, nicht der Inhalt per Prüfsumme.")
                    .font(.caption).foregroundStyle(.secondary)
                if !storage.related.isEmpty {
                    DisclosureGroup(en ? "Shares files with \(storage.related.count) savegame(s)" : "Gemeinsame Dateien mit \(storage.related.count) Spielständen") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(storage.related, id: \.save.id) { item in
                                Button { model.selection = item.save.id } label: {
                                    VStack(alignment: .leading) {
                                        Text(item.save.title)
                                        Text("\(item.save.date.formatted(date: .abbreviated, time: .shortened)) · \(item.files) " + (en ? "shared files" : "gemeinsame Dateien")).font(.caption).foregroundStyle(.secondary)
                                    }
                                }.buttonStyle(.plain)
                            }
                        }.padding(.top, 8)
                    }
                }
                if let origin = storage.originID {
                    if let parent = model.saves.first(where: { $0.id == origin }) {
                        Button { model.selection = parent.id } label: { Label((en ? "Created from: " : "Erstellt aus: ") + parent.title, systemImage: "arrow.triangle.branch") }
                    } else {
                        Text((en ? "Source snapshot no longer in this library: " : "Ursprungsstand nicht mehr in dieser Library: ") + origin).font(.caption)
                    }
                    Text(en ? "Provenance only; the source is not required for restore." : "Nur Herkunftsinformation; der Ursprung wird zum Wiederherstellen nicht benötigt.").font(.caption).foregroundStyle(.secondary)
                }
            } else if let error {
                Label(en ? "Storage status unavailable" : "Speicherstatus nicht verfügbar", systemImage: "exclamationmark.triangle")
                Text(error).font(.caption).foregroundStyle(.secondary)
            } else { ProgressView(en ? "Inspecting storage…" : "Speicher wird geprüft …") }
            Divider()
            if let cloud {
                Label(cloudTitle(cloud), systemImage: "icloud")
                if let url = cloud.archive {
                    Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: { Label(url.lastPathComponent, systemImage: "folder") }
                    Text(en ? "The archive manifest matches this snapshot. Archive contents and provider upload were not reverified by this status check." : "Das Archiv-Manifest entspricht diesem Spielstand. Archivinhalt und Upload beim Anbieter wurden bei dieser Statusprüfung nicht erneut verifiziert.").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(en ? "Checks library ZIP archives in your configured cloud backup folder. A missing match does not prove that no backup exists elsewhere." : "Prüft Library-ZIP-Archive im eingestellten Cloud-Backup-Ordner. Ein fehlender Treffer bedeutet nicht, dass anderswo kein Backup vorhanden ist.").font(.caption).foregroundStyle(.secondary)
                }
            } else { ProgressView(en ? "Checking cloud folder…" : "Cloud-Ordner wird geprüft …") }
            Text(en ? "RealmCraft / Meta online save: unknown. The Companion has no connection to these services and cannot confirm a server backup or cloud upload." : "RealmCraft-/Meta-Online-Spielstand: unbekannt. Der Companion hat keine Verbindung zu diesen Diensten und kann weder Server-Backup noch Cloud-Upload bestätigen.").font(.caption).foregroundStyle(.secondary)
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: theme.radius))
            .task(id: taskID) {
                storage = nil; cloud = nil; error = nil
                guard !model.busy else { return }
                let root = model.library.root, snapshot = save, directory = cloudFolder
                let worker = Task.detached(priority: .utility) { () -> (SavegameStorageStatus?, SavegameCloudStatus?, String?) in
                    do {
                        let library = try Library(root: root)
                        let storage = try library.storageStatus(snapshot)
                        let cloud = (try? library.cloudStatus(snapshot, directory: directory)) ?? SavegameCloudStatus(state: .unavailable)
                        return (storage, cloud, nil)
                    } catch { return (nil, .init(state: .unavailable), error.localizedDescription) }
                }
                let result = await withTaskCancellationHandler(operation: { await worker.value }, onCancel: { worker.cancel() })
                guard !Task.isCancelled else { return }
                storage = result.0; cloud = result.1; error = result.2
            }
    }
    private func cloudTitle(_ cloud: SavegameCloudStatus) -> String {
        switch cloud.state {
        case .unconfigured: return en ? "Cloud folder not configured" : "Cloud-Ordner nicht eingerichtet"
        case .found: return en ? "Matching backup in cloud folder" : "Passendes Backup im Cloud-Ordner"
        case .notFound: return en ? "No matching library backup found" : "Kein passendes Library-Backup gefunden"
        case .unavailable: return en ? "Cloud backup status unknown / unreadable" : "Cloud-Backup-Status unbekannt / nicht lesbar"
        }
    }
}
