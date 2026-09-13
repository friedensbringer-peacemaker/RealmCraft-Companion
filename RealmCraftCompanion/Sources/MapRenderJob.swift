import Foundation
import Darwin

/// Owns one renderer. Cancellation is accepted until the result enters its commit phase.
final class MapRenderJob: @unchecked Sendable {
    enum Failure: Error { case cancelled, timedOut }
    struct Result { let code: Int32; let output: String }
    private let lock = NSLock()
    private var cancelled = false
    private var committing = false

    @discardableResult func cancel() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !committing else { return false }
        cancelled = true
        return true
    }
    func checkCancellation() throws {
        lock.lock(); defer { lock.unlock() }
        if cancelled { throw Failure.cancelled }
    }
    func beginCommit() throws {
        lock.lock(); defer { lock.unlock() }
        if cancelled { throw Failure.cancelled }
        committing = true
    }
    func run(executable: String, arguments: [String], timeout: TimeInterval = 3600,
             terminationGrace: TimeInterval = 1) throws -> Result {
        try checkCancellation()
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        guard FileManager.default.createFile(atPath: outputURL.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer { try? FileManager.default.removeItem(at: outputURL) }
        let output = try FileHandle(forWritingTo: outputURL)
        defer { try? output.close() }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output; process.standardError = output
        try process.run()
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        var stopped: Failure?
        var killAt: TimeInterval?
        // The Atlas renderer uses threads, not child processes; reap the owned process before cleanup.
        while process.isRunning {
            let now = ProcessInfo.processInfo.systemUptime
            if stopped == nil {
                do { try checkCancellation() } catch { stopped = .cancelled }
                if stopped == nil && now >= deadline { stopped = .timedOut }
                if stopped != nil {
                    process.terminate()
                    killAt = now + terminationGrace
                }
            } else if let killAt, now >= killAt, process.isRunning {
                kill(process.processIdentifier, SIGKILL)
            }
            Thread.sleep(forTimeInterval: 0.025)
        }
        process.waitUntilExit()
        if let stopped { throw stopped }
        try checkCancellation()
        return Result(code: process.terminationStatus, output: String(decoding: try Data(contentsOf: outputURL), as: UTF8.self))
    }
}
