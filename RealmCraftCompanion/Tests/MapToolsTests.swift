import Foundation
import CryptoKit

@main struct MapToolsTests {
    static func main() throws {
        let fm = FileManager.default
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let tools = MapTools(support: root.appendingPathComponent("Maps with spaces"))
        let backend = try Library(root: root.appendingPathComponent("unused-library"))
        backend.progress = { print($0) }
        try fm.createDirectory(at: tools.support, withIntermediateDirectories: true)
        let oldID = UUID().uuidString
        try oldID.write(to: tools.marker, atomically: true, encoding: .utf8)
        let oldPath = tools.managedPython!
        try fm.createDirectory(at: oldPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("previous-runtime".utf8).write(to: oldPath)

        for listing in ["", "python/../../outside", "/tmp/python/file", "other/file", "python/../outside"] {
            do { try MapTools.validateMembers(listing); fatalError("Unsafe archive accepted") } catch {}
        }
        try MapTools.validateMembers("python/\npython/bin/python3\npython/lib/file")
        print("PASS: archive paths validated")

        do {
            _ = try tools.install(using: backend, english: true) { _, archive in
                // A second installation must fail before invoking its downloader.
                do {
                    _ = try tools.install(using: backend, english: true) { _, _ in fatalError("Concurrent download started") }
                    fatalError("Concurrent installation accepted")
                } catch { precondition(error.localizedDescription.contains("Another app copy")) }
                try Data("corrupted-download".utf8).write(to: archive)
            }
            fatalError("Invalid checksum accepted")
        } catch { precondition(error.localizedDescription.contains("checksum")) }
        precondition(tools.managedPython == oldPath)
        let oldData = try Data(contentsOf: oldPath)
        precondition(String(decoding: oldData, as: UTF8.self) == "previous-runtime")
        let remaining = try fm.contentsOfDirectory(atPath: tools.support.appendingPathComponent("toolchains").path)
        precondition(remaining == [oldID])
        print("PASS: checksum failure and concurrent install preserve previous runtime; attempt cleaned up")

        do {
            _ = try tools.install(using: backend, english: false) { _, _ in throw LibraryError("Simulierter Netzwerkausfall") }
            fatalError("Download failure accepted")
        } catch { precondition(error.localizedDescription.contains("Netzwerkausfall")) }
        precondition(tools.managedPython == oldPath)
        print("PASS: offline failure leaves activation unchanged")

        if CommandLine.arguments.count > 2 {
            let archive = URL(fileURLWithPath: CommandLine.arguments[2])
            let executable = try tools.install(using: backend, english: true) { _, destination in
                try fm.copyItem(at: archive, to: destination)
            }
            precondition(tools.managedPython?.path == executable)
            precondition(tools.readyPython(using: backend) == executable)
            precondition(fm.fileExists(atPath: oldPath.path))
            print(try backend.checked(executable, ["-I", "-c", "import sys,numpy,PIL; print(sys.version); print('NumPy',numpy.__version__,'Pillow',PIL.__version__)"]))
            if CommandLine.arguments.count > 3 {
                let engine = CommandLine.arguments[3]
                _ = try backend.checked(executable, ["-I", "-c", "import sys; sys.path.insert(0, sys.argv[1]); from realmcraft_map.__main__ import main; sys.argv = ['realmcraft-map', '--help']; main()", engine])
                print("PASS: bundled map engine starts with newly installed Python")
            }
            print("PASS: fresh standalone runtime, binary packages, NumPy/PNG smoke test, activation and discovery")
        }
    }
}
