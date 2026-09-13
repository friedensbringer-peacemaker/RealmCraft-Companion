import Foundation
import Darwin

/// Coordinate shared renderer/cache writes across windows and app instances, without locking the save library.
final class MapCacheLease {
    private let descriptor: Int32
    init(support: URL) throws {
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        let fd = open(support.appendingPathComponent(".render-cache.lock").path, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw CocoaError(.fileWriteNoPermission) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            close(fd)
            throw NSError(domain: "RealmCraft.MapCache", code: 1, userInfo: [NSLocalizedDescriptionKey: "Another map/cache job is active. Try again later / Ein anderer Karten-/Cache-Auftrag läuft. Später erneut versuchen."])
        }
        descriptor = fd
    }
    deinit { flock(descriptor, LOCK_UN); close(descriptor) }
}
