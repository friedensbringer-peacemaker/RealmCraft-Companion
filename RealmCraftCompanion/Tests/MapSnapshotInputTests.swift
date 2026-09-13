import Foundation

@main struct MapSnapshotInputTests {
    static func main() throws {
        let fm = FileManager.default, root = fm.temporaryDirectory.appendingPathComponent("map-input-test-" + UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let staging = root.appendingPathComponent("staging"), world = staging.appendingPathComponent("515151")
        try fm.createDirectory(at: world, withIntermediateDirectories: true)
        for name in ["world_data", "player_data", "o.0,0"] { try Data(("synthetic " + name).utf8).write(to: world.appendingPathComponent(name)) }
        let library = try Library(root: root.appendingPathComponent("library"), adb: "/usr/bin/false")
        let save = try library.finish(staging, world: "515151", title: "Synthetic", source: "test", manifest: library.localManifest(world))
        let original = try library.verify(save)
        let input = try MapSnapshotInput.prepare(library: library, save: save, directory: root.appendingPathComponent("input"))
        try library.assertSame(original, input.manifest)
        // Preparation released its lock; ordinary library work can proceed while a render job runs.
        let running = MapRenderJob(), group = DispatchGroup(); group.enter()
        DispatchQueue.global().async {
            defer { group.leave() }
            do { _ = try running.run(executable: "/bin/sleep", arguments: ["1"], timeout: 3) }
            catch MapRenderJob.Failure.cancelled {} catch { fatalError("Unexpected job failure: \(error)") }
        }
        try library.withExclusiveOperation { _ = try library.verify(save) }
        let source = library.worldFolder(save).appendingPathComponent("o.0,0")
        try fm.removeItem(at: source); try Data("changed source".utf8).write(to: source)
        try library.assertSame(original, library.localManifest(input.directory))
        running.cancel(); precondition(group.wait(timeout: .now() + 5) == .success)
        let bytes = try Data(contentsOf: input.directory.appendingPathComponent("o.0,0"))
        precondition(bytes == Data("synthetic o.0,0".utf8))
        do { _ = try MapSnapshotInput.prepare(library: library, save: save, directory: root.appendingPathComponent("second")); fatalError("Accepted changed source") } catch {}
        precondition(Library.safeRelativeFile("nested folder/file name") && !Library.safeRelativeFile("../escape") && !Library.safeRelativeFile("/absolute") && !Library.safeRelativeFile("nested//file"))
        var lease: MapCacheLease? = try MapCacheLease(support: root)
        do { _ = try MapCacheLease(support: root); fatalError("Two cache writers accepted") } catch {}
        withExtendedLifetime(lease) {}; lease = nil
        let available = try MapCacheLease(support: root); withExtendedLifetime(available) {}
        print("PASS: immutable map input, released library lock, concurrent work, cancellation and changed-source rejection")
    }
}
