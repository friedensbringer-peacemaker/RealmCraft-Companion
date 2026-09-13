// Audit-only wrapper. Never compiled into the shipping Companion.
import Foundation
import Darwin

func fail(_ message: String) -> Never {
    fputs("Audit launch refused: \(message)\n", stderr)
    exit(78)
}
let fm = FileManager.default
let bundle = Bundle.main
guard let rootPath = bundle.object(forInfoDictionaryKey: "RealmCraftAuditRoot") as? String
else { fail("missing audit root metadata") }
guard let identifier = bundle.bundleIdentifier, identifier.hasPrefix("at.local.realmcraft.audit.")
else { fail("missing audit bundle identifier") }
guard bundle.bundleURL.deletingLastPathComponent().resolvingSymlinksInPath().path == URL(fileURLWithPath: rootPath).resolvingSymlinksInPath().path
else { fail("moved audit bundle") }
let root = URL(fileURLWithPath: rootPath)
let profile = root.appendingPathComponent("Profile")
let expectedProfile = root.resolvingSymlinksInPath().path + "/Profile"
guard ProcessInfo.processInfo.environment["CFFIXED_USER_HOME"] == profile.path,
      profile.resolvingSymlinksInPath().path == expectedProfile,
      fm.homeDirectoryForCurrentUser.resolvingSymlinksInPath().path == expectedProfile,
      fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].resolvingSymlinksInPath().path == expectedProfile + "/Library/Application Support",
      fm.urls(for: .cachesDirectory, in: .userDomainMask)[0].resolvingSymlinksInPath().path == expectedProfile + "/Library/Caches"
else { fail("Foundation paths are not isolated; use Launch Services, never the target executable") }
let library = profile.appendingPathComponent("Library/Application Support/RealmCraftLibrary/Savegames")
guard library.resolvingSymlinksInPath().path == expectedProfile + "/Library/Application Support/RealmCraftLibrary/Savegames" else { fail("library is redirected") }
// Do not inherit a previous personal preference domain. The unique bundle ID
// is retained when exec replaces this wrapper with the original Mach-O.
let receipt: [String: Any] = ["bundleID": identifier, "foundationPathsChecked": true,
                            "date": ISO8601DateFormatter().string(from: Date()),
                            "securitySandbox": false]
do {
    let data = try JSONSerialization.data(withJSONObject: receipt, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: root.appendingPathComponent("launch-check.json"), options: .atomic)
} catch { fail("cannot record the path check") }
if CommandLine.arguments.dropFirst().first == "--audit-preflight" {
    print("PASS: unique bundle ID and Foundation home/support/cache paths; GUI not started")
    exit(0)
}
guard CommandLine.arguments.count == 1 else { fail("extra launch arguments are not allowed") }
guard let executable = bundle.object(forInfoDictionaryKey: "RealmCraftAuditExecutable") as? String,
      !executable.contains("/"), !executable.isEmpty else { fail("invalid target") }
let target = bundle.bundleURL.appendingPathComponent("Contents/MacOS/" + executable).path
// NSArgumentDomain outranks persisted settings. Ordinary UI view settings remain
// writable in the unique audit domain; no global defaults or HOME are changed.
let arguments = [target, "-libraryPath", library.path, "-adbPath", "/usr/bin/false", "-setupSeen", "YES"]
let pointers = arguments.map { strdup($0) } + [nil]
pointers.withUnsafeBufferPointer { buffer in _ = execv(target, buffer.baseAddress!) }
fail("could not execute the Companion")
