import Foundation
import SwiftUI
// Standalone test model: compile this file with Sources/CompanionLifecycle.swift.
@MainActor final class Model: ObservableObject {
 @Published var busy = false
 @Published var error: String?
}
@main struct CompanionLifecycleTests {
 @MainActor static func main() async throws {
  var requests = 0; var exited = false; var pauses = 0
  let normal = CompanionQuitTarget(requestQuit: { requests += 1; return true }, hasExited: { exited })
  let result = try await CompanionQuitSequence.close([normal], attempts: 3) { pauses += 1; exited = true }
  precondition(result && requests == 1 && pauses == 1)
  let refused = CompanionQuitTarget(requestQuit: { false }, hasExited: { false })
  let denied = try await CompanionQuitSequence.close([refused]) { fatalError("Must not wait after explicit refusal") }
  precondition(!denied)
  pauses = 0
  let stuck = CompanionQuitTarget(requestQuit: { true }, hasExited: { false })
  let timedOut = try await CompanionQuitSequence.close([stuck], attempts: 3) { pauses += 1 }
  precondition(!timedOut && pauses == 3)
  let gone = CompanionQuitTarget(requestQuit: { fatalError("Already exited") }, hasExited: { true })
  let goneResult = try await CompanionQuitSequence.close([gone]) { fatalError("No wait needed") }
  precondition(goneResult)
  let empty = try await CompanionQuitSequence.close([]) { fatalError("No wait needed") }
  precondition(empty)
  do {
   _ = try await CompanionQuitSequence.close([stuck]) { throw CancellationError() }
   fatalError("Cancellation must propagate")
  } catch is CancellationError {}
  var justExited = false
  let race = CompanionQuitTarget(requestQuit: { justExited = true; return false }, hasExited: { justExited })
  let raceResult = try await CompanionQuitSequence.close([race]) { fatalError("Already exited during request") }
  precondition(raceResult)
  precondition(CompanionLifecycle.runRelaunchHelper(arguments: ["test", "--companion-relaunch", "invalid", "0"]) == 2)
  print("Passed: graceful quit, refusal, timeout, already exited, empty list, cancellation, exit race, invalid helper arguments")
 }
}
