import SwiftUI
import AppKit
import Darwin

// Only registered GUI instances with the same bundle identifier participate.
@MainActor struct CompanionQuitTarget {
    let requestQuit: () -> Bool
    let hasExited: () -> Bool
}
@MainActor enum CompanionQuitSequence {
    static func close(_ targets: [CompanionQuitTarget], attempts: Int = 150,
                      pause: () async throws -> Void = { try await Task.sleep(for: .milliseconds(100)) }) async throws -> Bool {
        for target in targets where !target.hasExited() {
            if !target.requestQuit() && !target.hasExited() { return false }
        }
        for _ in 0..<attempts {
            if targets.allSatisfy({ $0.hasExited() }) { return true }
            try await pause()
        }
        return targets.allSatisfy { $0.hasExited() }
    }
}

@MainActor final class CompanionLifecycle: ObservableObject {
    static let shared = CompanionLifecycle()
    @Published private(set) var isWorking = false
    private(set) var allowsTermination = false

    func perform(restart: Bool, model: Model, english: Bool) {
        guard !isWorking, !model.busy else { return }
        isWorking = true
        Task {
            // Serialize simultaneous requests made in different Companion copies.
            let path = FileManager.default.temporaryDirectory.appendingPathComponent("realmcraft-instance-control.lock").path
            let lock = Darwin.open(path, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
            defer {
                if lock >= 0 { Darwin.close(lock) }
                isWorking = false
                allowsTermination = false
            }
            guard lock >= 0, flock(lock, LOCK_EX | LOCK_NB) == 0 else {
                model.error = english ? "Another Companion instance is already closing or restarting the app."
                    : "Eine andere Companion-Instanz beendet oder startet die App bereits neu."
                return
            }
            guard let identifier = Bundle.main.bundleIdentifier else { return }
            let current = NSRunningApplication.current
            let others = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
                .filter { $0.processIdentifier != current.processIdentifier }
            let targets = others.map { app in
                CompanionQuitTarget(requestQuit: { app.terminate() }, hasExited: { app.isTerminated })
            }
            do {
                guard try await CompanionQuitSequence.close(targets), !model.busy else {
                    model.error = english ? "At least one instance is still open, possibly because a transfer or dialog is active. Finish it there and try again. No restart was started."
                        : "Mindestens eine Instanz ist noch geöffnet, möglicherweise wegen einer Übertragung oder eines Dialogs. Schließe den Vorgang dort ab und versuche es erneut. Es wurde kein Neustart gestartet."
                    return
                }
                if restart {
                    guard let executable = Bundle.main.executableURL, let launchDate = current.launchDate else {
                        throw CocoaError(.fileNoSuchFile)
                    }
                    let helper = Process()
                    helper.executableURL = executable
                    helper.arguments = ["--companion-relaunch", String(current.processIdentifier), String(launchDate.timeIntervalSince1970)]
                    helper.standardInput = FileHandle.nullDevice
                    helper.standardOutput = FileHandle.nullDevice
                    helper.standardError = FileHandle.nullDevice
                    try helper.run()
                }
                allowsTermination = true
                NSApp.terminate(nil)
            } catch {
                model.error = (english ? "Could not restart the Companion: " : "Companion konnte nicht neu gestartet werden: ") + error.localizedDescription
            }
        }
    }

    // This headless child survives the requesting GUI and opens one replacement only after it exits.
    static func runRelaunchHelper(arguments: [String]) -> Int32 {
        guard arguments.count == 4, let pid = Int32(arguments[2]),
              pid > 0, pid != ProcessInfo.processInfo.processIdentifier,
              let started = Double(arguments[3]), started.isFinite, started > 0,
              let identifier = Bundle.main.bundleIdentifier else { return 2 }
        let owner = NSRunningApplication(processIdentifier: pid)
        if let owner {
            guard owner.bundleIdentifier == identifier, let launchDate = owner.launchDate,
                  abs(launchDate.timeIntervalSince1970 - started) < 0.01 else { return 2 }
        }
        let deadline = Date().addingTimeInterval(20)
        while owner?.isTerminated == false && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        guard owner?.isTerminated != false else { return 3 }
        let configuration = NSWorkspace.OpenConfiguration()
        // The old GUI is gone. Never let Launch Services reuse this headless helper.
        configuration.createsNewApplicationInstance = true
        configuration.activates = true
        var complete = false
        var launchError: Error?
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            DispatchQueue.main.async {
                launchError = error
                complete = true
            }
        }
        let launchDeadline = Date().addingTimeInterval(20)
        while !complete && Date() < launchDeadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        if !complete || launchError != nil {
            let english = UserDefaults.standard.string(forKey: "appLanguage") != "de"
            let alert = NSAlert()
            alert.messageText = english ? "Companion could not be reopened" : "Companion konnte nicht erneut geöffnet werden"
            alert.informativeText = english ? "Please open RealmCraft Companion from Applications." : "Bitte öffne RealmCraft Companion im Programme-Ordner."
            alert.runModal()
            return 4
        }
        return 0
    }
}

struct CompanionLifecycleActions: View {
    @ObservedObject var model: Model
    @ObservedObject private var lifecycle = CompanionLifecycle.shared
    let english: Bool
    var body: some View {
        Button(english ? "Quit all Companion instances" : "Alle Companion-Instanzen beenden") {
            lifecycle.perform(restart: false, model: model, english: english)
        }.disabled(model.busy || lifecycle.isWorking)
        Button(english ? "Quit all and restart Companion" : "Alle beenden und Companion neu starten") {
            lifecycle.perform(restart: true, model: model, english: english)
        }.disabled(model.busy || lifecycle.isWorking)
    }
}
