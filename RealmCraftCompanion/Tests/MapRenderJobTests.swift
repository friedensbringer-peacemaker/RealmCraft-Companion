import Foundation

@main struct MapRenderJobTests {
    static func main() throws {
        let success = try MapRenderJob().run(executable: "/bin/sh", arguments: ["-c", "printf map-ready"], timeout: 2)
        precondition(success.code == 0 && success.output == "map-ready")
        let failed = try MapRenderJob().run(executable: "/bin/sh", arguments: ["-c", "exit 7"], timeout: 2)
        precondition(failed.code == 7)
        let before = MapRenderJob(); before.cancel()
        do { _ = try before.run(executable: "/missing", arguments: []); fatalError("Launched after cancellation") }
        catch MapRenderJob.Failure.cancelled { }
        let running = MapRenderJob()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { running.cancel() }
        let start = Date()
        do { _ = try running.run(executable: "/bin/sh", arguments: ["-c", "trap '' TERM; while :; do :; done"], timeout: 5, terminationGrace: 0.1); fatalError("Expected cancellation") }
        catch MapRenderJob.Failure.cancelled { }
        precondition(Date().timeIntervalSince(start) < 3)
        do { _ = try MapRenderJob().run(executable: "/bin/sleep", arguments: ["10"], timeout: 0.1, terminationGrace: 0.1); fatalError("Expected timeout") }
        catch MapRenderJob.Failure.timedOut { }
        let finalizing = MapRenderJob()
        _ = try finalizing.run(executable: "/usr/bin/true", arguments: [])
        finalizing.cancel()
        do { try finalizing.beginCommit(); fatalError("Committed cancelled result") }
        catch MapRenderJob.Failure.cancelled { }
        let committed = MapRenderJob(); try committed.beginCommit()
        precondition(!committed.cancel())
        print("PASS: renderer success, failure, early/active/final cancellation, timeout and commit boundary")
    }
}
