import Foundation
import CryptoKit
import Darwin

struct LibraryError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
struct Savegame: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var date: Date
    var gameDate: Date
    var world: String
    var count: Int
    var bytes: Int64
    var source: String
}
struct Device: Identifiable, Hashable {
    var id: String
    var name: String
}
struct CommandResult { let code: Int32; let output: String }

// Operations run on a serial worker. Mutable configuration is also protected for UI reads.
final class Library: @unchecked Sendable {
    private let stateLock = NSLock()
    private var storedRoot = URL(fileURLWithPath: "/")
    private var storedADB = ""
    private var storedPackage = "com.TellurionMobile.RealmCraft"
    var root: URL {
        get { stateLock.lock(); defer { stateLock.unlock() }; return storedRoot }
        set { stateLock.lock(); defer { stateLock.unlock() }; storedRoot = newValue }
    }
    let fm = FileManager.default
    var package: String {
        get { stateLock.lock(); defer { stateLock.unlock() }; return storedPackage }
        set { stateLock.lock(); defer { stateLock.unlock() }; storedPackage = newValue }
    }
    var remote: String { "/sdcard/Android/data/\(package)/files/local" }
    var adb: String {
        get { stateLock.lock(); defer { stateLock.unlock() }; return storedADB }
        set { stateLock.lock(); defer { stateLock.unlock() }; storedADB = newValue }
    }
    var progress: (String) -> Void = { _ in }

    init(root: URL? = nil, adb: String? = nil) throws {
        self.root = root ?? UserDefaults.standard.string(forKey: "libraryPath").map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/RealmCraftLibrary/Savegames", isDirectory: true)
        self.adb = adb ?? [UserDefaults.standard.string(forKey: "adbPath"),
                          FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/RealmCraftLibrary/platform-tools/adb").path,
                          FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Android/sdk/platform-tools/adb").path,
                          Bundle.main.resourceURL?.appendingPathComponent("adb").path,
                          "/opt/homebrew/bin/adb", "/usr/local/bin/adb"].compactMap { $0 }
            .first { FileManager.default.isExecutableFile(atPath: $0) } ?? "/opt/homebrew/bin/adb"

    }
    func withExclusiveOperation<T>(_ action: () throws -> T) throws -> T {
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        let lockPath = root.appendingPathComponent(".operation.lock").path
        let descriptor = open(lockPath, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw LibraryError("Die Library konnte nicht für die Übertragung gesperrt werden.") }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            throw LibraryError("Eine andere App-Kopie arbeitet gerade mit dieser Library. Bitte warte, bis sie fertig ist.")
        }
        defer { flock(descriptor, LOCK_UN) }
        return try action()
    }
    func run(_ executable: String, _ arguments: [String], timeout: TimeInterval = 600) throws -> CommandResult {
        let outputURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        fm.createFile(atPath: outputURL.path, contents: nil)
        defer { try? fm.removeItem(at: outputURL) }
        let output = try FileHandle(forWritingTo: outputURL)
        defer { try? output.close() }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: executable)
        p.arguments = arguments
        p.standardOutput = output
        p.standardError = output
        do { try p.run() } catch { throw LibraryError("Programm konnte nicht gestartet werden: \(executable)\n\(error.localizedDescription)") }
        let deadline = Date().addingTimeInterval(timeout)
        while p.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.05) }
        if p.isRunning {
            p.terminate()
            Thread.sleep(forTimeInterval: 0.2)
            if p.isRunning { kill(p.processIdentifier, SIGKILL) }
            p.waitUntilExit()
            throw LibraryError("Zeitüberschreitung. USB-Verbindung prüfen. Eine laufende Wiederherstellung nicht durch Starten des Spiels unterbrechen.")
        }
        p.waitUntilExit()
        let data = try Data(contentsOf: outputURL)
        return CommandResult(code: p.terminationStatus, output: String(decoding: data, as: UTF8.self))
    }
    func checked(_ executable: String, _ args: [String], timeout: TimeInterval = 600) throws -> String {
        let r = try run(executable, args, timeout: timeout)
        guard r.code == 0 else { throw LibraryError(String(r.output.suffix(5000))) }
        return r.output
    }
    func command(_ serial: String, _ args: [String], timeout: TimeInterval = 600) throws -> String {
        try checked(adb, ["-s", serial] + args, timeout: timeout)
    }
    func quote(_ s: String) -> String { "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }
    func validWorld(_ s: String) -> Bool {
        !s.isEmpty && s.count <= 80 && s.allSatisfy { $0.isASCII && ($0.isNumber || $0.isLetter || $0 == "-" || $0 == "_") }
    }
    func devices() throws -> [Device] {
        guard fm.isExecutableFile(atPath: adb) else { throw LibraryError("ADB fehlt. Bitte Android Platform Tools installieren.") }
        let text = try checked(adb, ["devices", "-l"], timeout: 15)
        let devices = text.split(separator: "\n").compactMap { line -> Device? in
            let parts = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count > 1, parts[1] == "device" else { return nil }
            let name = parts.first(where: { $0.hasPrefix("model:") })?.dropFirst(6) ?? "Android"
            return Device(id: parts[0], name: String(name).replacingOccurrences(of: "_", with: " "))
        }
        if devices.isEmpty {
            throw LibraryError(text.contains("unauthorized") ? "Bitte in der Quest die USB-Debugging-Abfrage bestätigen und erneut verbinden." : "Keine Quest verbunden. USB-Kabel anschließen, Quest aufwecken und USB-Debugging erlauben.")
        }
        return devices
    }
    func requireClosed(_ serial: String) throws {
        _ = try command(serial, ["get-state"])
        let r = try run(adb, ["-s", serial, "shell", "pidof \(package)"])
        if r.code == 0 && !r.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw LibraryError("RealmCraft läuft noch. Bitte im Spiel speichern, das Spiel vollständig beenden und erneut versuchen.")
        }
        guard r.code == 1 && r.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LibraryError("Spielstatus konnte nicht sicher geprüft werden: \(r.output)")
        }
    }
    func stopGame(_ serial: String) throws {
        _ = try command(serial, ["shell", "am", "force-stop", package])
        try requireClosed(serial)
    }
    func worlds(_ serial: String, timeout: TimeInterval = 600) throws -> [String] {
        let output = try command(serial, ["shell", "ls -1 \(quote(remote))"], timeout: timeout)
        let candidates = output.split(whereSeparator: { $0.isNewline }).map(String.init).filter(validWorld).sorted()
        return try candidates.filter { world in
            let r = try run(adb, ["-s", serial, "shell", "test -f \(quote(remote + "/" + world + "/world_data")) && test -f \(quote(remote + "/" + world + "/player_data"))"], timeout: timeout)
            return r.code == 0
        }
    }
    func entries() throws -> [Savegame] {
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        return try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            .filter { !$0.lastPathComponent.hasPrefix(".") }
            .compactMap { folder in
                guard let data = try? Data(contentsOf: folder.appendingPathComponent("savegame.json")),
                      let entry = try? JSONDecoder().decode(Savegame.self, from: data),
                      entry.id == folder.lastPathComponent, validWorld(entry.world) else { return nil }
                if (try? folder.resourceValues(forKeys: [.isHiddenKey]).isHidden) == true { try? makeVisible(folder) }
                return entry
            }.sorted { $0.date > $1.date }
    }
    // Completed backups must be visible in Finder; preserve every other file flag.
    func makeVisible(_ directory: URL) throws {
        var items = [directory]
        if let iterator = fm.enumerator(at: directory, includingPropertiesForKeys: [.isSymbolicLinkKey]) {
            for case let item as URL in iterator { items.append(item) }
        }
        for item in items {
            var metadata = stat()
            guard lstat(item.path, &metadata) == 0 else { continue }
            guard (metadata.st_mode & S_IFMT) != S_IFLNK else { continue }
            if metadata.st_flags & UInt32(UF_HIDDEN) != 0 {
                guard chflags(item.path, metadata.st_flags & ~UInt32(UF_HIDDEN)) == 0 else {
                    throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
                }
            }
        }
    }
    func folder(_ save: Savegame) -> URL { root.appendingPathComponent(save.id) }
    func worldFolder(_ save: Savegame) -> URL { folder(save).appendingPathComponent(save.world) }
    func write<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: url, options: .atomic)
    }
    func rename(_ save: Savegame, title: String) throws {
        var save = save
        save.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !save.title.isEmpty else { throw LibraryError("Bitte einen Namen eingeben.") }
        try write(save, to: folder(save).appendingPathComponent("savegame.json"))
    }
    func localManifest(_ dir: URL) throws -> [String: String] {
        if try dir.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true {
            throw LibraryError("Bitte einen echten Weltordner auswählen, keine symbolische Verknüpfung.")
        }
        let dir = dir.resolvingSymlinksInPath()
        var result: [String: String] = [:]
        guard let enumerator = fm.enumerator(atPath: dir.path) else {
            throw LibraryError("Savegame-Ordner konnte nicht gelesen werden.")
        }
        for case let name as String in enumerator {
            let url = dir.appendingPathComponent(name)
            let attrs = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard attrs.isSymbolicLink != true else { throw LibraryError("Verknüpfungen sind in Savegames nicht erlaubt.") }
            if attrs.isRegularFile == true {
                guard !name.contains("\n"), !name.contains("\r") else { throw LibraryError("Ungültiger Dateiname.") }
                if result.count % 1000 == 0 { progress("Dateien prüfen · \(result.count) …") }
                result[name] = SHA256.hash(data: try Data(contentsOf: url, options: .mappedIfSafe)).map { String(format: "%02x", $0) }.joined()
            }
        }
        guard result["world_data"] != nil, result["player_data"] != nil else {
            throw LibraryError("Kein vollständiges RealmCraft-Savegame: world_data oder player_data fehlt. Gefunden: \(result.keys.sorted().prefix(5).joined(separator: ", "))")
        }
        return result
    }
    func remoteManifest(_ serial: String, path: String) throws -> [String: String] {
        let output = try command(serial, ["shell", "cd \(quote(path)) && find . -type f -print0 | xargs -0 sha256sum"])
        var result: [String: String] = [:]
        for line in output.split(whereSeparator: { $0.isNewline }) {
            guard line.count > 68 else { throw LibraryError("Quest-Prüfsummen konnten nicht gelesen werden.") }
            let hash = String(line.prefix(64))
            let rest = String(line.dropFirst(64))
            guard rest.hasPrefix("  ./"), hash.allSatisfy({ $0.isHexDigit }) else { throw LibraryError("Ungültige Quest-Prüfsumme.") }
            result[String(rest.dropFirst(4))] = hash
        }
        guard !result.isEmpty else { throw LibraryError("Auf der Quest wurden keine Savegame-Dateien gefunden.") }
        return result
    }
    func assertSame(_ a: [String:String], _ b: [String:String]) throws {
        guard a == b else { throw LibraryError("Die Dateien stimmen nicht überein. Das Spiel muss während der gesamten Übertragung beendet bleiben. Es wurde kein ungeprüfter Spielstand aktiviert.") }
    }
    func finish(_ staging: URL, world: String, title: String, source: String, manifest: [String:String], date: Date = Date()) throws -> Savegame {
        var bytes: Int64 = 0
        var gameDate = Date.distantPast
        for name in manifest.keys {
            let attrs = try fm.attributesOfItem(atPath: staging.appendingPathComponent(world).appendingPathComponent(name).path)
            bytes += (attrs[.size] as? NSNumber)?.int64Value ?? 0
            gameDate = max(gameDate, attrs[.modificationDate] as? Date ?? .distantPast)
        }
        let save = Savegame(id: UUID().uuidString, title: title, date: date, gameDate: gameDate, world: world, count: manifest.count, bytes: bytes, source: source)
        try write(manifest, to: staging.appendingPathComponent("manifest.json"))
        try write(save, to: staging.appendingPathComponent("savegame.json"))
        try makeVisible(staging)
        try fm.moveItem(at: staging, to: folder(save))
        return save
    }
    func backup(_ serial: String, world: String, title: String = "Quest-Sicherung", source: String = "Quest → Mac") throws -> Savegame {
        let title = title == "Quest-Sicherung" && UserDefaults.standard.string(forKey: "appLanguage") == "en" ? "Quest backup" : title
        guard validWorld(world) else { throw LibraryError("Bitte eine Quest-Welt auswählen.") }
        try requireClosed(serial)
        let staging = root.appendingPathComponent(".partial-" + UUID().uuidString)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }
        progress("Quest-Dateien prüfen …")
        let before = try remoteManifest(serial, path: remote + "/" + world)
        progress("Savegame von der Quest kopieren …")
        _ = try command(serial, ["pull", "-a", remote + "/" + world, staging.path + "/"])
        progress("Kopie auf Vollständigkeit prüfen …")
        let local = try localManifest(staging.appendingPathComponent(world))
        try assertSame(before, local)
        try assertSame(local, remoteManifest(serial, path: remote + "/" + world))
        try requireClosed(serial)
        return try finish(staging, world: world, title: title, source: source, manifest: local)
    }
    func verify(_ save: Savegame) throws -> [String:String] {
        let recorded = try JSONDecoder().decode([String:String].self, from: Data(contentsOf: folder(save).appendingPathComponent("manifest.json")))
        let actual = try localManifest(worldFolder(save))
        try assertSame(recorded, actual)
        return actual
    }
    func restore(_ save: Savegame, serial: String) throws {
        guard validWorld(save.world) else { throw LibraryError("Ungültige Welt-ID.") }
        progress("Ausgewähltes Savegame prüfen …")
        let expected = try verify(save)
        try requireClosed(serial)
        let target = remote + "/" + save.world
        let exists = try run(adb, ["-s", serial, "shell", "test -d \(quote(target))"])
        guard exists.code == 0 || (exists.code == 1 && exists.output.isEmpty) else { throw LibraryError(exists.output) }
        var original: [String:String]? = nil
        if exists.code == 0 {
            progress("Aktuellen Quest-Spielstand automatisch sichern …")
            let safety = try backup(serial, world: save.world, title: (UserDefaults.standard.string(forKey: "appLanguage") == "en" ? "Before restore · " : "Vor Wiederherstellung · ") + save.title, source: "Automatische Sicherung")
            original = try verify(safety)
        }
        let token = UUID().uuidString
        let stage = remote + "/../.library-stage-" + token
        let previous = remote + "/../.library-previous-" + token
        progress("Savegame auf die Quest übertragen …")
        _ = try command(serial, ["shell", "mkdir -p \(quote(remote)) && mkdir \(quote(stage))"])
        // Retain the stage on failure; never delete device data after an uncertain command result.
        _ = try command(serial, ["push", worldFolder(save).path, stage + "/"])
        progress("Übertragung auf der Quest prüfen …")
        try assertSame(expected, remoteManifest(serial, path: stage + "/" + save.world))
        try requireClosed(serial)
        if let original { try assertSame(original, remoteManifest(serial, path: target)) }
        progress("Geprüftes Savegame aktivieren …")
        let activate: String
        if original != nil {
            activate = "mv \(quote(target)) \(quote(previous)) && { mv \(quote(stage + "/" + save.world)) \(quote(target)) || { mv \(quote(previous)) \(quote(target)); exit 1; }; }"
        } else {
            activate = "test ! -e \(quote(target)) && mv \(quote(stage + "/" + save.world)) \(quote(target))"
        }
        do {
            _ = try command(serial, ["shell", activate])
            try assertSame(expected, remoteManifest(serial, path: target))
        } catch {
            throw LibraryError("Aktivierung konnte nicht abschließend bestätigt werden. RealmCraft vorerst geschlossen lassen. Die automatische Sicherung ist in der Library; eine vorherige Quest-Kopie bleibt unter \(previous).\n\(error.localizedDescription)")
        }
        // Old device copy remains as additional recovery protection. It is outside the game's local worlds folder.
        _ = try? command(serial, ["shell", "rmdir \(quote(stage))"])
    }
    func importSave(_ input: URL) throws -> Savegame {
        let staging = root.appendingPathComponent(".partial-" + UUID().uuidString)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }
        var source = input
        let unpack = fm.temporaryDirectory.appendingPathComponent("RealmCraft-" + UUID().uuidString)
        defer { try? fm.removeItem(at: unpack) }
        if input.pathExtension.lowercased() == "zip" {
            progress("ZIP-Datei prüfen und entpacken …")
            let listing = try checked("/usr/bin/unzip", ["-Z1", input.path])
            for name in listing.split(whereSeparator: { $0.isNewline }).map(String.init) {
                guard !name.hasPrefix("/"), !name.contains("\\"), !name.split(separator: "/").contains("..") else {
                    throw LibraryError("Das ZIP enthält unsichere Dateipfade.")
                }
            }
            let details = try checked("/usr/bin/unzip", ["-Z", "-l", input.path])
            guard !details.split(separator: "\n").contains(where: { $0.hasPrefix("l") }) else {
                throw LibraryError("ZIP-Dateien mit symbolischen Verknüpfungen werden nicht importiert.")
            }
            _ = try checked("/usr/bin/ditto", ["-x", "-k", input.path, unpack.path])
            source = unpack
        }
        var worldURL: URL?
        if fm.fileExists(atPath: source.appendingPathComponent("world_data").path) { worldURL = source }
        else {
            let children = try fm.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
                .filter { fm.fileExists(atPath: $0.appendingPathComponent("world_data").path) }
            guard children.count == 1 else { throw LibraryError("Bitte einen einzelnen Weltordner oder ein ZIP mit genau einer RealmCraft-Welt wählen.") }
            worldURL = children[0]
        }
        guard let worldURL, validWorld(worldURL.lastPathComponent) else { throw LibraryError("Der Weltordner muss die ursprüngliche Welt-ID als Namen haben, z. B. 1234567890.") }
        let world = worldURL.lastPathComponent
        progress("Savegame in die Library aufnehmen …")
        let before = try localManifest(worldURL)
        try fm.copyItem(at: worldURL, to: staging.appendingPathComponent(world))
        let actual = try localManifest(staging.appendingPathComponent(world))
        try assertSame(before, actual)
        let metadataURL = source.appendingPathComponent("savegame.json")
        let old = (try? Data(contentsOf: metadataURL)).flatMap { try? JSONDecoder().decode(Savegame.self, from: $0) }
        if let recorded = try? Data(contentsOf: source.appendingPathComponent("manifest.json")) {
            try assertSame(actual, JSONDecoder().decode([String:String].self, from: recorded))
        }
        let title = old?.title ?? input.deletingPathExtension().lastPathComponent
        return try finish(staging, world: world, title: title, source: "Import", manifest: actual, date: old?.date ?? Date())
    }
    func export(_ save: Savegame, to destination: URL) throws {
        progress("Savegame vor ZIP-Export prüfen …")
        _ = try verify(save)
        let temporary = destination.deletingLastPathComponent().appendingPathComponent(".\(UUID().uuidString).zip")
        defer { try? fm.removeItem(at: temporary) }
        progress("ZIP-Datei erstellen …")
        _ = try checked("/usr/bin/ditto", ["-c", "-k", "--norsrc", folder(save).path, temporary.path])
        _ = try checked("/usr/bin/unzip", ["-tq", temporary.path])
        if fm.fileExists(atPath: destination.path) { _ = try fm.replaceItemAt(destination, withItemAt: temporary) }
        else { try fm.moveItem(at: temporary, to: destination) }
    }
}
