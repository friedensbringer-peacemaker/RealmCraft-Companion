import AppKit
import Combine

/// User-selected destinations and temporary AirDrop files never touch managed saves.
enum AIExportFiles {
    static func filename(world: String, date: Date = Date()) -> String {
        let safe = String(world.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) || $0 == "-" ? String($0) : "_" }.joined().prefix(80))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "RealmCraft-\(safe)-\(formatter.string(from: date))-\(UUID().uuidString.prefix(8)).md"
    }

    static func write(markdown: String, world: String, folder: URL, library: URL) throws -> URL {
        let directory = folder.resolvingSymlinksInPath().standardizedFileURL
        let root = library.resolvingSymlinksInPath().standardizedFileURL.path
        guard directory.path != root, !directory.path.hasPrefix(root + "/") else {
            throw NSError(domain: "AIExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Exportziel liegt innerhalb der Spielstand-Bibliothek / Export destination is inside the savegame library."])
        }
        let target = directory.appendingPathComponent(filename(world: world))
        let staging = directory.appendingPathComponent(".RealmCraft-\(UUID().uuidString).tmp")
        defer { try? FileManager.default.removeItem(at: staging) }
        try Data(markdown.utf8).write(to: staging, options: .withoutOverwriting)
        try FileManager.default.moveItem(at: staging, to: target)
        return target
    }

    static func writePackage(markdown: String, videoMarkdown: String?, world: String, folder: URL, library: URL) throws -> [URL] {
        let primary = try write(markdown: markdown, world: world, folder: folder, library: library)
        do {
            return try MarkdownExportPackage.write(markdown: markdown, videoMarkdown: videoMarkdown, to: primary, library: library)
        } catch {
            try? FileManager.default.removeItem(at: primary)
            throw error
        }
    }

    static var cloudDrive: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs", isDirectory: true)
    }
    static func isCloudFolder(_ url: URL) -> Bool {
        if FileManager.default.isUbiquitousItem(at: url) { return true }
        let path = url.resolvingSymlinksInPath().standardizedFileURL.path
        let root = cloudDrive.resolvingSymlinksInPath().standardizedFileURL.path
        return path == root || path.hasPrefix(root + "/")
    }
}

final class AIExportSharing: NSObject, ObservableObject, NSSharingServiceDelegate {
    @Published private(set) var folder: URL?
    @Published private(set) var status = ""
    @Published private(set) var failure = ""
    @Published private(set) var sharing = false
    @Published private(set) var lastSaved: URL?
    private let defaults: UserDefaults
    private let bookmarkKey = "aiExport.iCloudFolderBookmark"
    private var service: NSSharingService?
    private var staging: URL?
    // Retain the delegate and staged attachment even when navigating away from KI-Export.
    private var activeOperation: AIExportSharing?
    private var english = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        do { folder = try resolveFolder() }
        catch { failure = "iCloud-Ordner bitte erneut auswählen / Please select the iCloud folder again." }
    }

    private func resolveFolder() throws -> URL? {
        guard let data = defaults.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        let url = try URL(resolvingBookmarkData: data, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale)
        if stale {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            defaults.set(try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil), forKey: bookmarkKey)
        }
        return url
    }

    func chooseFolder(english: Bool) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = english ? "Use folder" : "Ordner verwenden"
        panel.message = english ? "Choose a folder in iCloud Drive for your AI exports." : "Wähle einen Ordner in iCloud Drive für deine KI-Exporte."
        panel.directoryURL = folder ?? (FileManager.default.fileExists(atPath: AIExportFiles.cloudDrive.path) ? AIExportFiles.cloudDrive : nil)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            guard AIExportFiles.isCloudFolder(url) else {
                throw NSError(domain: "AIExport", code: 2, userInfo: [NSLocalizedDescriptionKey: english ? "Choose a folder inside iCloud Drive." : "Wähle einen Ordner innerhalb von iCloud Drive."])
            }
            let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(bookmark, forKey: bookmarkKey)
            folder = url; failure = ""; status = ""; lastSaved = nil
        } catch { failure = error.localizedDescription }
    }

    func forgetFolder() {
        defaults.removeObject(forKey: bookmarkKey)
        folder = nil; lastSaved = nil; status = ""; failure = ""
    }

    func saveToCloud(markdown: String, videoMarkdown: String? = nil, world: String, library: URL, english: Bool) {
        if folder == nil { chooseFolder(english: english) }
        guard folder != nil else { return }
        do {
            guard let url = try resolveFolder() else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            guard AIExportFiles.isCloudFolder(url) else {
                throw NSError(domain: "AIExport", code: 3, userInfo: [NSLocalizedDescriptionKey: english ? "The folder is no longer in iCloud Drive. Select it again." : "Der Ordner liegt nicht mehr in iCloud Drive. Bitte erneut auswählen."])
            }
            let files = try AIExportFiles.writePackage(markdown: markdown, videoMarkdown: videoMarkdown, world: world, folder: url, library: library)
            lastSaved = files.first
            folder = url; failure = ""
            status = english ? "Saved in your iCloud folder. macOS handles syncing. On iPhone: Files → iCloud Drive → select the file and attach it in your AI app." : "Im iCloud-Ordner gespeichert. macOS übernimmt die Synchronisierung. Am iPhone: Dateien → iCloud Drive → Datei auswählen und in deiner KI-App anhängen."
            if files.count > 1 { status += english ? " Attach both Markdown files." : " Beide Markdown-Dateien anhängen." }
        } catch { failure = error.localizedDescription; status = "" }
    }

    func airDrop(markdown: String, videoMarkdown: String? = nil, world: String, library: URL, english: Bool) {
        guard !sharing else { return }
        self.english = english
        failure = ""; status = ""
        do {
            guard let service = NSSharingService(named: .sendViaAirDrop) else { throw CocoaError(.featureUnsupported) }
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("RealmCraft-AirDrop-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
            staging = directory
            let files = try AIExportFiles.writePackage(markdown: markdown, videoMarkdown: videoMarkdown, world: world, folder: directory, library: library)
            guard service.canPerform(withItems: files) else { throw CocoaError(.featureUnsupported) }
            self.service = service; service.delegate = self
            sharing = true; activeOperation = self
            status = english ? "Select your iPhone in AirDrop and accept the file there." : "Wähle dein iPhone in AirDrop und nimm die Datei dort an."
            service.perform(withItems: files)
        } catch { failure = error.localizedDescription; cleanup() }
    }
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        // AirDrop also invokes this callback when its recipient chooser is cancelled.
        status = english ? "AirDrop dialog closed. If you selected a recipient, check the file on your iPhone." : "AirDrop-Dialog geschlossen. Falls du einen Empfänger ausgewählt hast, prüfe die Datei auf deinem iPhone."
        cleanup()
    }
    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        status = ""; failure = error.localizedDescription
        cleanup()
    }
    private func cleanup() {
        if let staging { try? FileManager.default.removeItem(at: staging) }
        staging = nil; service = nil; sharing = false; activeOperation = nil
    }
}
