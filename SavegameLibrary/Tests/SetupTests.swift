import Foundation
@main struct SetupTests {
    static func main() throws {
        let base = URL(fileURLWithPath: CommandLine.arguments[1])
        let fm = FileManager.default
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        let lib = try Library(root: base.appendingPathComponent("library"))
        if CommandLine.arguments.contains("--download") {
            lib.progress = { print($0) }
            let version = try lib.installADB(supportFolder: base.appendingPathComponent("tools"), persist: false)
            print(version)
            print(try lib.checked("/usr/bin/lipo", ["-archs", lib.adb]))
            print("PASS: official download, archive verification, installation and executable version check")
        } else {
            let world = base.appendingPathComponent("1234567890")
            try fm.createDirectory(at: world, withIntermediateDirectories: true)
            try Data("world".utf8).write(to: world.appendingPathComponent("world_data"))
            try Data("player".utf8).write(to: world.appendingPathComponent("player_data"))
            let save = try lib.importSave(world)
            let original = lib.folder(save)
            try lib.changeRoot(base.appendingPathComponent("migrated"), migrate: true, persist: false)
            _ = try lib.verify(save)
            precondition(fm.fileExists(atPath: original.path))
            let entries = try lib.entries()
            precondition(entries.count == 1)
            print("PASS: library migration preserves originals and verifies copied files")
            let conflict = base.appendingPathComponent("conflict")
            let conflictEntry = conflict.appendingPathComponent(save.id)
            try fm.createDirectory(at: conflictEntry, withIntermediateDirectories: true)
            try fm.copyItem(at: lib.worldFolder(save), to: conflictEntry.appendingPathComponent(save.world))
            let currentRoot = lib.root
            do {
                try lib.changeRoot(conflict, migrate: true, persist: false)
                fatalError("Incomplete destination metadata must be rejected")
            } catch {
                precondition(lib.root == currentRoot)
                _ = try lib.verify(save)
            }
            print("PASS: incomplete migration destination rejected without switching library")
            let fakeADB = base.appendingPathComponent("adb")
            try Data("#!/bin/sh\nif [ \"$1\" = version ]; then echo 'Android Debug Bridge version test'; else echo 'List of devices attached'; fi\n".utf8).write(to: fakeADB)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fakeADB.path)
            let discovery = try Library(root: lib.root, adb: fakeADB.path)
            let report = discovery.setupReport(preferred: "missing")
            precondition(report.devices.isEmpty && report.serial.isEmpty && report.package.isEmpty)
            precondition(report.adbVersion.contains("Android Debug Bridge"))
            print("PASS: empty device discovery reports disconnected without losing ADB status")
            let started = Date()
            do {
                _ = try lib.run("/bin/sleep", ["10"], timeout: 0.1)
                fatalError("Process should time out")
            } catch { precondition(Date().timeIntervalSince(started) < 5) }
            print("PASS: stalled process terminates within timeout")
            try lib.withExclusiveOperation {
                do {
                    try lib.withExclusiveOperation { throw LibraryError("Lock test entered unexpectedly") }
                    fatalError("Second lock must fail")
                } catch {
                    precondition(error.localizedDescription.contains("andere App-Kopie"))
                }
            }
            print("PASS: concurrent app copies cannot modify the same library")
            do {
                try lib.changeRoot(lib.root.appendingPathComponent("nested"), migrate: true, persist: false)
                fatalError("Nested migration should have failed")
            } catch { print("PASS: nested library migration refused") }
        }
    }
}
