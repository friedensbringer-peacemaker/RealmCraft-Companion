import Foundation

struct SetupReport {
    var adbVersion = "Nicht installiert"
    var adbPath = ""
    var devices: [Device] = []
    var serial = ""
    var package = ""
    var worlds: [String] = []
    var message = ""
}
extension Library {
    func setupReport(preferred: String) -> SetupReport {
        var report = SetupReport()
        report.adbPath = adb
        do {
            let version = try checked(adb, ["version"], timeout: 15)
            guard version.contains("Android Debug Bridge") else { throw LibraryError("Die ausgewählte Datei ist kein gültiges ADB.") }
            report.adbVersion = version.split(separator: "\n").prefix(2).joined(separator: " · ")
            report.devices = try devices()
            report.serial = report.devices.first(where: { $0.id == preferred })?.id ?? report.devices[0].id
            let packages = try command(report.serial, ["shell", "pm", "list", "packages"], timeout: 15)
                .split(whereSeparator: { $0.isNewline }).map { String($0).replacingOccurrences(of: "package:", with: "") }
                .filter { $0.lowercased().contains("realmcraft") && $0.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "." || $0 == "_") } }
            guard !packages.isEmpty else { throw LibraryError("RealmCraft ist auf diesem Gerät nicht installiert. Bitte zuerst auf der Quest installieren und eine Welt anlegen.") }
            // Prefer the known Quest edition when multiple RealmCraft variants are installed.
            package = packages.first(where: { $0 == "com.TellurionMobile.RealmCraft" }) ?? packages[0]
            report.package = package
            report.worlds = try worlds(report.serial, timeout: 15)
            report.message = report.worlds.isEmpty ? "RealmCraft gefunden. Noch keine Welt vorhanden – bitte im Spiel eine Welt anlegen und speichern." : "Quest und RealmCraft erkannt · \(report.worlds.count) Welt(en) verfügbar."
        } catch { report.message = error.localizedDescription }
        return report
    }
    func installADB(supportFolder: URL? = nil, persist: Bool = true) throws -> String {
        let support = supportFolder ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/RealmCraftLibrary")
        try fm.createDirectory(at: support, withIntermediateDirectories: true)
        let staging = support.appendingPathComponent(".download-" + UUID().uuidString)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }
        let archive = staging.appendingPathComponent("platform-tools.zip")
        progress("Android Platform Tools von Google herunterladen …")
        _ = try checked("/usr/bin/curl", ["-fL", "--proto", "=https", "--proto-redir", "=https", "--tlsv1.2", "--connect-timeout", "20", "--max-time", "240", "--output", archive.path,
                                         "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"])
        progress("Download prüfen und ADB einrichten …")
        _ = try checked("/usr/bin/unzip", ["-tq", archive.path])
        let listing = try checked("/usr/bin/unzip", ["-Z1", archive.path])
        guard listing.split(whereSeparator: { $0.isNewline }).allSatisfy({ name in
            name.hasPrefix("platform-tools/") && !name.split(separator: "/").contains("..") && !name.contains("\\")
        }) else { throw LibraryError("Unerwarteter Inhalt im Platform-Tools-Download.") }
        _ = try checked("/usr/bin/ditto", ["-x", "-k", archive.path, staging.path])
        let downloaded = staging.appendingPathComponent("platform-tools")
        let version = try checked(downloaded.appendingPathComponent("adb").path, ["version"])
        guard version.contains("Android Debug Bridge") else { throw LibraryError("Die heruntergeladene ADB-Version konnte nicht geprüft werden.") }
        let target = support.appendingPathComponent("platform-tools")
        let previous = support.appendingPathComponent(".previous-tools-" + UUID().uuidString)
        let existed = fm.fileExists(atPath: target.path)
        if existed { try fm.moveItem(at: target, to: previous) }
        do { try fm.moveItem(at: downloaded, to: target) }
        catch { if existed { try? fm.moveItem(at: previous, to: target) }; throw error }
        if existed { try? fm.removeItem(at: previous) }
        adb = target.appendingPathComponent("adb").path
        if persist { UserDefaults.standard.set(adb, forKey: "adbPath") }
        return version.split(separator: "\n").prefix(2).joined(separator: " · ")
    }
    func chooseADB(_ url: URL) throws {
        let version = try checked(url.path, ["version"])
        guard version.contains("Android Debug Bridge") else { throw LibraryError("Bitte die ausführbare Datei adb aus Android Platform Tools auswählen.") }
        adb = url.path
        UserDefaults.standard.set(adb, forKey: "adbPath")
    }
    private func canonicalPath(_ url: URL) -> String {
        var candidate = url
        var suffix: [String] = []
        while true {
            if let resolved = realpath(candidate.path, nil) {
                defer { free(resolved) }
                return ([String(cString: resolved)] + suffix).joined(separator: "/")
            }
            let parent = candidate.deletingLastPathComponent()
            if parent.path == candidate.path { return url.path }
            suffix.insert(candidate.lastPathComponent, at: 0)
            candidate = parent
        }
    }
    func changeRoot(_ url: URL, migrate: Bool, persist: Bool = true) throws {
        let destination = url.resolvingSymlinksInPath()
        let old = root.resolvingSymlinksInPath()
        let destinationPath = canonicalPath(destination).lowercased()
        let oldPath = canonicalPath(old).lowercased()
        if destinationPath == oldPath { return }
        guard !destinationPath.hasPrefix(oldPath + "/"), !oldPath.hasPrefix(destinationPath + "/") else {
            throw LibraryError("Bitte einen separaten Library-Ordner auswählen, keinen über- oder untergeordneten Ordner der aktuellen Library.")
        }
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        let probe = destination.appendingPathComponent(".write-test-" + UUID().uuidString)
        try Data("RealmCraft".utf8).write(to: probe); try fm.removeItem(at: probe)
        if migrate {
            for save in try entries() {
                progress("Library kopieren: \(save.title) …")
                let manifest = try verify(save)
                let target = destination.appendingPathComponent(save.id)
                if fm.fileExists(atPath: target.path) {
                    let targetLibrary = try Library(root: destination, adb: adb)
                    guard let existing = try targetLibrary.entries().first(where: { $0.id == save.id }), existing.world == save.world else {
                        throw LibraryError("Der Zielordner enthält einen unvollständigen Library-Eintrag. Bitte einen anderen Speicherordner wählen.")
                    }
                    try assertSame(manifest, targetLibrary.verify(existing))
                    continue
                }
                let partial = destination.appendingPathComponent(".partial-" + UUID().uuidString)
                defer { try? fm.removeItem(at: partial) }
                try fm.copyItem(at: folder(save), to: partial)
                try assertSame(manifest, localManifest(partial.appendingPathComponent(save.world)))
                try makeVisible(partial)
                try fm.moveItem(at: partial, to: target)
            }
        }
        root = destination
        if persist { UserDefaults.standard.set(root.path, forKey: "libraryPath") }
    }
}
