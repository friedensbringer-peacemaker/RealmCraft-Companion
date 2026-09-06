import Foundation

struct EditorRequest: Codable {
    var action: String
    var sourceFile: String = ""
    var sourceChest: String = ""
    var sourceSlot: Int = 1
    var targetFile: String = ""
    var targetChest: String = ""
    var targetSlot: Int = 1
    var quantity: Int = 1
}

extension Library {
    func editorCopy(_ save: Savegame, request: EditorRequest, python: String, engine: URL) throws -> Savegame {
        guard UUID(uuidString: save.id) != nil, validWorld(save.world) else { throw LibraryError("Invalid save identity") }
        let original = try verify(save)
        let stage = root.appendingPathComponent(".partial-editor-" + UUID().uuidString)
        try fm.createDirectory(at: stage, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: stage) }
        let world = stage.appendingPathComponent(save.world)
        try fm.copyItem(at: worldFolder(save), to: world)
        try materializeWorld(world)
        try assertSame(original, localManifest(world))
        if request.action == "level" {
            let file = world.appendingPathComponent("player_data")
            let data = try Data(contentsOf: file)
            guard let old = try PlayerReader.parse(data).level, request.quantity > old, request.quantity <= 1_000_000 else {
                throw LibraryError("Level must increase (maximum 1,000,000); known player format required / Level muss steigen (maximal 1.000.000); bekanntes Spielerformat erforderlich.")
            }
            var bytes = Array(data)
            let positions = (0..<max(0,bytes.count-22)).filter { Array(bytes[$0..<$0+3]) == [0,41,1] && Array(bytes[$0+18..<$0+23]) == [0,0,143,190,112] }
            guard positions.count == 1 else { throw LibraryError("Ambiguous experience component / Mehrdeutiges Erfahrungsformat") }
            let p = positions[0]+14
            for n in 0..<4 { bytes[p+n] = UInt8((request.quantity >> (8*n)) & 255) }
            let patched = Data(bytes)
            guard try PlayerReader.parse(patched).level == request.quantity else { throw LibraryError("Level verification failed") }
            try patched.write(to: file, options: .atomic)
        } else {
            let input = stage.appendingPathComponent("request.json")
            try write(request, to: input)
            _ = try checked(python, ["-I", "-B", "-c", "import sys; sys.path.insert(0, sys.argv.pop(1)); from realmcraft_map.editor import main; main()", engine.path, world.path, input.path])
            if request.sourceFile == "player_data" || request.targetFile == "player_data" {
                _ = try PlayerReader.parse(Data(contentsOf: world.appendingPathComponent("player_data")))
            }
            try fm.removeItem(at: input)
        }
        try assertSame(original, verify(save))
        let patched = try localManifest(world)
        guard patched != original else { throw LibraryError("No change / Keine Änderung") }
        let result = try finish(stage, world: save.world, title: save.title + " · Editor BETA", source: "Editor BETA / PREVIEW · \(request.action) · source \(save.id)", manifest: patched)
        return result
    }
}


/// Observed world_data v9: world ID, field5, seed, UTF-8 name, 105-byte suffix.
/// The save timestamp is at suffix+8 (.NET UTC ticks), observed against two Quest worlds.
/// Re-identification and in-game ordering remain experimental; seed and other state are preserved.
enum EditorWorldIdentity {
    static func rewrite(_ data: Data, source: String, target: String, name: String, savedAt: Date? = nil) throws -> Data {
        let b = Array(data)
        func number(_ p: Int) -> UInt32 { b[p..<p+4].reduce(0) { ($0 << 8) | UInt32($1) } }
        guard b.count >= 21, b.count <= 1_000_000, b[0] == 9,
              let sourceID = UInt32(source), let targetID = UInt32(target),
              targetID > 0, targetID <= UInt32(Int32.max), targetID != sourceID,
              number(1) == sourceID else {
            throw LibraryError("Unsupported world identity / Nicht unterstützte Welt-ID oder world_data-Version.")
        }
        let length = Int(number(13)), encoded = Array(name.utf8)
        guard length > 0, length <= 1024, b.count - (17+length) == 105,
              String(bytes: b[17..<17+length], encoding: .utf8) != nil,
              !encoded.isEmpty, encoded.count <= 128 else {
            throw LibraryError("Unsupported world name / Nicht unterstütztes Welt-Namensformat.")
        }
        func be(_ n: UInt32) -> [UInt8] { [UInt8((n >> 24)&255),UInt8((n >> 16)&255),UInt8((n >> 8)&255),UInt8(n&255)] }
        var suffix = Array(b[17+length..<b.count])
        if let savedAt {
            let oldTicks = suffix[8..<16].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            let epoch: UInt64 = 621355968000000000
            let minimum = epoch + 946684800 * 10000000
            let maximum = epoch + 4102444800 * 10000000
            let seconds = savedAt.timeIntervalSince1970
            guard oldTicks >= minimum, oldTicks < maximum, seconds >= 946684800, seconds < 4102444800 else {
                throw LibraryError("Unsupported save timestamp / Nicht unterstützter Speicherzeitstempel.")
            }
            let ticks = epoch + UInt64((seconds * 10000000).rounded())
            for n in 0..<8 { suffix[8+n] = UInt8((ticks >> (8*(7-n))) & 255) }
        }
        var result = [b[0]] + be(targetID)
        result += Array(b[5..<13])
        result += be(UInt32(encoded.count))
        result += encoded
        result += suffix
        return Data(result)
    }
}

extension Library {
    func editorTestCopy(_ save: Savegame, occupied: [String]) throws -> Savegame {
        guard UUID(uuidString: save.id) != nil, validWorld(save.world) else { throw LibraryError("Invalid save identity") }
        let before = try verify(save)
        let existing = Set(occupied + (try entries()).map(\.world) + [save.world])
        var identity = String(UInt32.random(in: 1...UInt32(Int32.max)))
        while existing.contains(identity) { identity = String(UInt32.random(in: 1...UInt32(Int32.max))) }
        let stage = root.appendingPathComponent(".partial-testworld-" + UUID().uuidString)
        try fm.createDirectory(at: stage, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: stage) }
        let world = stage.appendingPathComponent(identity)
        try fm.copyItem(at: worldFolder(save), to: world)
        try materializeWorld(world)
        try assertSame(before, localManifest(world))
        let path = world.appendingPathComponent("world_data")
        let bytes = try Data(contentsOf: path)
        let rewritten = try EditorWorldIdentity.rewrite(bytes, source: save.world, target: identity, name: "BETA TEST " + identity, savedAt: Date())
        try rewritten.write(to: path, options: .atomic)
        try assertSame(before, verify(save))
        let after = try localManifest(world)
        guard Set(before.keys) == Set(after.keys), before.filter({ $0.key != "world_data" }) == after.filter({ $0.key != "world_data" }) else {
            throw LibraryError("Unexpected test-world changes / Unerwartete Änderungen der Testwelt")
        }
        return try finish(stage, world: identity, title: "BETA TEST \(identity) · \(save.title)", source: "Editor BETA TEST · source \(save.id) / world \(save.world)", manifest: after)
    }

    /// No overwrite path exists in this operation, including collisions during activation.
    func exportEditorTestWorld(_ save: Savegame, serial: String, expectedPackage: String, expectedWorlds: [String]) throws {
        guard package == expectedPackage, save.source.hasPrefix("Editor BETA TEST"), validWorld(save.world), UUID(uuidString: save.id) != nil else {
            throw LibraryError("Test export context changed / Kontext des Testexports hat sich geändert.")
        }
        let expected = try verify(save)
        try requireClosed(serial)
        let current = try worlds(serial)
        guard Set(current) == Set(expectedWorlds), !current.contains(save.world) else {
            throw LibraryError("Quest worlds changed. Prepare export again / Quest-Welten geändert. Export erneut vorbereiten.")
        }
        let target = remote + "/" + save.world
        func requireAbsent() throws {
            let result = try run(adb, ["-s",serial,"shell","if test -e \(quote(target)) || test -L \(quote(target)); then exit 42; fi"])
            guard result.code == 0, result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw LibraryError("Target is occupied or cannot be checked. Nothing overwritten / Ziel belegt oder nicht prüfbar. Nichts überschrieben.")
            }
        }
        try requireAbsent()
        let help = try command(serial, ["shell", "mv --help"])
        guard help.contains("-n"), help.contains("-T") else { throw LibraryError("Quest does not support protected activation / Quest unterstützt die geschützte Aktivierung nicht.") }
        var originals: [String:[String:String]] = [:]
        for world in current { originals[world] = try remoteManifest(serial, path: remote + "/" + world) }
        let stage = remote + "/../.editor-test-" + UUID().uuidString
        _ = try command(serial, ["shell", "mkdir \(quote(stage))"])
        _ = try command(serial, ["push", worldFolder(save).path, stage + "/"])
        try assertSame(expected, remoteManifest(serial, path: stage + "/" + save.world))
        try requireClosed(serial)
        guard package == expectedPackage, Set(try worlds(serial)) == Set(current) else { throw LibraryError("Quest context changed; test world not activated / Quest-Kontext geändert; Testwelt nicht aktiviert.") }
        for (world, hashes) in originals { try assertSame(hashes, remoteManifest(serial, path: remote + "/" + world)) }
        try requireAbsent()
        let source = stage + "/" + save.world
        do {
            _ = try command(serial, ["shell", "mv -T -n \(quote(source)) \(quote(target)) && test ! -e \(quote(source))"])
            try assertSame(expected, remoteManifest(serial, path: target))
            for (world, hashes) in originals { try assertSame(hashes, remoteManifest(serial, path: remote + "/" + world)) }
        } catch {
            throw LibraryError("Test export could not be fully confirmed. Keep RealmCraft closed and check the Quest world list and library backups. / Testexport nicht abschließend bestätigt. RealmCraft geschlossen lassen und Quest-Welten sowie Bibliotheks-Sicherungen prüfen.\n\(error.localizedDescription)")
        }
        _ = try? command(serial, ["shell", "rmdir \(quote(stage))"])
    }
}
