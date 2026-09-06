import SwiftUI
import AppKit

struct MapExportSettings: View {
    static let bookmarkKey = "mapExport.iCloudFolderBookmark"
    let english: Bool
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sharing = AIExportSharing(bookmarkKey: MapExportSettings.bookmarkKey)
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(english ? "Map export" : "Kartenexport").font(.title2.bold())
            Text(english ? "Save navigation Markdown directly to this iCloud folder. This destination is separate from the general AI export folder." : "Navigations-Markdown direkt in diesem iCloud-Ordner speichern. Dieses Ziel ist unabhängig vom Ordner des allgemeinen KI-Exports.")
            Text(sharing.folder?.path ?? (english ? "No folder selected" : "Kein Ordner ausgewählt")).font(.callout).textSelection(.enabled)
            HStack {
                Button(english ? "Choose iCloud folder…" : "iCloud-Ordner auswählen …") { sharing.chooseFolder(english: english) }
                if let folder = sharing.folder {
                    Button(english ? "Show in Finder" : "Im Finder anzeigen") { NSWorkspace.shared.open(folder) }
                    Button(english ? "Forget folder" : "Ordnerauswahl entfernen") { sharing.forgetFolder() }
                }
            }
            if !sharing.failure.isEmpty { Text(sharing.failure).foregroundStyle(.red) }
            Text(english ? "Each export creates a new file. macOS handles iCloud syncing." : "Jeder Export erstellt eine neue Datei. macOS übernimmt die iCloud-Synchronisierung.").font(.caption).foregroundStyle(.secondary)
            HStack { Spacer(); Button(english ? "Done" : "Fertig") { dismiss() }.keyboardShortcut(.defaultAction) }
        }.padding(24).frame(width: 540)
    }
}
