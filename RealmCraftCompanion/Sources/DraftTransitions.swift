import SwiftUI
import AppKit

/// One registry per application model. No draft contents are written to preferences.
@MainActor final class DraftTransitions {
    enum Choice { case save, discard, cancel }
    struct Entry {
        let dirty: () -> Bool
        let title: String
        let save: () -> Bool
        let discard: () -> Void
    }
    private var entries: [UUID: Entry] = [:]
    private var resolving = false
    private var prompting = false
    var choose: (String) -> Choice = { title in
        let en = UserDefaults.standard.string(forKey: "appLanguage") != "de"
        let alert = NSAlert()
        alert.messageText = en ? "Unsaved changes" : "Ungespeicherte Änderungen"
        alert.informativeText = title + "\n\n" + (en ? "Save before continuing? If saving fails, you stay with your draft." : "Vor dem Fortfahren speichern? Schlägt das Speichern fehl, bleibt dein Entwurf geöffnet.")
        alert.addButton(withTitle: en ? "Save" : "Speichern")
        alert.addButton(withTitle: en ? "Discard" : "Verwerfen")
        alert.addButton(withTitle: en ? "Cancel" : "Abbrechen").keyEquivalent = "\u{1b}"
        switch alert.runModal() {
        case .alertFirstButtonReturn: return .save
        case .alertSecondButtonReturn: return .discard
        default: return .cancel
        }
    }
    var hasChanges: Bool { entries.values.contains { $0.dirty() } }
    func register(_ id: UUID, dirty: @escaping () -> Bool, title: String, save: @escaping () -> Bool, discard: @escaping () -> Void) {
        entries[id] = Entry(dirty: dirty, title: title, save: save, discard: discard)
    }
    func remove(_ id: UUID) { entries[id] = nil }
    @discardableResult func authorize() -> Bool {
        if resolving { return true }
        guard !prompting else { return false }
        NSApp?.keyWindow?.makeFirstResponder(nil)
        for id in entries.keys.sorted(by: { $0.uuidString < $1.uuidString }) {
            guard let entry = entries[id], entry.dirty() else { continue }
            prompting = true
            let choice = choose(entry.title)
            prompting = false
            guard choice != .cancel else { return false }
            resolving = true
            let accepted: Bool
            if choice == .save { accepted = entry.save() }
            else { entry.discard(); accepted = true }
            resolving = false
            guard accepted else { return false }
            entries[id] = nil
        }
        return true
    }
    func perform(_ action: () -> Void) { if authorize() { action() } }
    static func fingerprint<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        return (try? encoder.encode(value).base64EncodedString()) ?? "invalid"
    }
}

private struct DraftRegistration: ViewModifier {
    let coordinator: DraftTransitions?
    let id: UUID
    let token: String
    let dirty: () -> Bool
    let title: String
    let save: () -> Bool
    let discard: () -> Void
    private func update() { coordinator?.register(id, dirty: dirty, title: title, save: save, discard: discard) }
    func body(content: Content) -> some View {
        content.onAppear(perform: update).onChange(of: token) { _, _ in update() }
            .onChange(of: dirty()) { _, _ in update() }
            .onDisappear { coordinator?.remove(id) }
    }
}
extension View {
    func trackDraft(_ coordinator: DraftTransitions?, id: UUID, token: String, dirty: @escaping () -> Bool, title: String,
                    save: @escaping () -> Bool, discard: @escaping () -> Void) -> some View {
        modifier(DraftRegistration(coordinator: coordinator, id: id, token: token, dirty: dirty, title: title, save: save, discard: discard))
    }
}

private struct DraftTransitionsKey: EnvironmentKey { static let defaultValue: DraftTransitions? = nil }
extension EnvironmentValues {
    var draftTransitions: DraftTransitions? {
        get { self[DraftTransitionsKey.self] }
        set { self[DraftTransitionsKey.self] = newValue }
    }
}
