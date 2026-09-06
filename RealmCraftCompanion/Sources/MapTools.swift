import Foundation
import CryptoKit
import Darwin

// A private, relocatable Python installation: no system installer or existing Python needed.
struct MapTools {
    let support: URL
    var marker: URL { support.appendingPathComponent("map-tools-active.txt") }

    struct Distribution {
        let architecture: String
        let sha256: String
        var url: String {
            "https://github.com/astral-sh/python-build-standalone/releases/download/20260825/cpython-3.12.14%2B20260825-\(architecture)-apple-darwin-install_only.tar.gz"
        }
        static let arm = Distribution(architecture: "aarch64", sha256: "62eef3fcf48fa4f792d0d6d267c140b81aaea0edca4ae0641d8021854314f966")
        static let intel = Distribution(architecture: "x86_64", sha256: "65da7bc373ea36cb7e413f2a20bcced9eeb7e5a83fa554ce9f6ec79abb8d7e31")
        static var current: Distribution {
            #if arch(arm64)
            return .arm
            #else
            return .intel
            #endif
        }
    }

    var managedPython: URL? {
        guard let value = try? String(contentsOf: marker, encoding: .utf8),
              UUID(uuidString: value) != nil else { return nil }
        return support.appendingPathComponent("toolchains/\(value)/python/bin/python3")
    }

    var candidates: [String] {
        ([managedPython?.path, support.appendingPathComponent("runtime/bin/python3").path,
          "/Library/Frameworks/Python.framework/Versions/Current/bin/python3",
          "/usr/local/bin/python3", "/opt/homebrew/bin/python3"].compactMap { $0 })
            .filter { FileManager.default.isExecutableFile(atPath: $0) }
    }

    // Exercise native extensions and PNG encoding, rather than accepting imports alone.
    static let probe = """
    import sys, io
    assert sys.version_info >= (3, 10)
    import numpy as np
    from PIL import Image
    pixels = np.zeros((2, 2, 3), dtype=np.uint8)
    pixels[0, 0] = [12, 34, 56]
    output = io.BytesIO()
    Image.fromarray(pixels).save(output, format='PNG')
    output.seek(0)
    assert Image.open(output).getpixel((0, 0)) == (12, 34, 56)
    """

    func readyPython(using backend: Library) -> String? {
        candidates.first { candidate in
            (try? backend.run(candidate, ["-I", "-c", Self.probe], timeout: 30).code) == 0
        }
    }

    static func validateArchive(_ url: URL, digest: String) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard actual == digest else { throw LibraryError("Python download checksum mismatch / Prüfsumme des Python-Downloads stimmt nicht überein.") }
    }

    static func validateMembers(_ listing: String) throws {
        let names = listing.split(separator: "\n").map(String.init)
        guard !names.isEmpty, names.allSatisfy({
            $0.hasPrefix("python/") && !$0.contains("\\") && !$0.split(separator: "/").contains("..")
        }) else { throw LibraryError("Invalid Python archive / Ungültiges Python-Archiv.") }
    }

    // Each attempt uses its final path from the start, so pip's absolute script paths stay valid.
    // Only the small activation marker changes after success. Failed repairs preserve the old runtime.
    func install(using backend: Library, english: Bool,
                 download: ((String, URL) throws -> Void)? = nil) throws -> String {
        let fm = FileManager.default
        try fm.createDirectory(at: support, withIntermediateDirectories: true)
        let descriptor = open(support.appendingPathComponent(".map-tools-install.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw LibraryError(english ? "Cannot prepare map tools installation." : "Karteneinrichtung konnte nicht vorbereitet werden.") }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            throw LibraryError(english ? "Another app copy is installing map tools. Please wait." : "Eine andere App-Kopie installiert bereits Kartenwerkzeuge. Bitte warten.")
        }
        defer { flock(descriptor, LOCK_UN) }
        let identifier = UUID().uuidString
        let folder = support.appendingPathComponent("toolchains/\(identifier)")
        let archive = folder.appendingPathComponent("python.tar.gz")
        let executable = folder.appendingPathComponent("python/bin/python3").path
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        var activated = false
        defer { if !activated { try? fm.removeItem(at: folder) } }

        var phase = english ? "Downloading Python" : "Python herunterladen"
        do {
            backend.progress(english ? "1/3 · Downloading Python…" : "1/3 · Python wird heruntergeladen …")
            let distribution = Distribution.current
            if let download { try download(distribution.url, archive) }
            else {
                _ = try backend.checked("/usr/bin/curl", ["--fail", "--location", "--silent", "--show-error",
                    "--proto", "=https", "--proto-redir", "=https", "--connect-timeout", "30", "--max-time", "600",
                    "--retry", "2", "--output", archive.path, distribution.url], timeout: 1900)
            }
            phase = english ? "Checking Python" : "Python prüfen"
            try Self.validateArchive(archive, digest: distribution.sha256)
            try Self.validateMembers(backend.checked("/usr/bin/tar", ["-tzf", archive.path], timeout: 60))
            _ = try backend.checked("/usr/bin/tar", ["-xzf", archive.path, "-C", folder.path], timeout: 120)
            _ = try backend.checked(executable, ["-I", "-c", "import sys; assert sys.version_info[:2] == (3, 12)"], timeout: 30)
            phase = english ? "Installing NumPy and Pillow" : "NumPy und Pillow installieren"
            backend.progress(english ? "2/3 · Installing NumPy and Pillow…" : "2/3 · NumPy und Pillow werden installiert …")
            _ = try backend.checked(executable, ["-I", "-m", "pip", "--isolated", "install",
                "--disable-pip-version-check", "--no-cache-dir", "--only-binary=:all:",
                "--index-url", "https://pypi.org/simple", "numpy>=2,<3", "Pillow>=10.4,<13"], timeout: 600)
            phase = english ? "Testing map tools" : "Kartenwerkzeuge testen"
            backend.progress(english ? "3/3 · Testing map tools…" : "3/3 · Kartenwerkzeuge werden getestet …")
            _ = try backend.checked(executable, ["-I", "-c", Self.probe], timeout: 60)
            try? fm.removeItem(at: archive)
            try identifier.write(to: marker, atomically: true, encoding: .utf8)
            activated = true
            return executable
        } catch {
            let retry = english ? "Check your internet connection and free disk space, then try again. An existing installation is preserved." : "Bitte Internetverbindung und freien Speicher prüfen und erneut versuchen. Eine vorhandene Installation bleibt erhalten."
            throw LibraryError("\(phase): \(error.localizedDescription)\n\n\(retry)")
        }
    }
}
