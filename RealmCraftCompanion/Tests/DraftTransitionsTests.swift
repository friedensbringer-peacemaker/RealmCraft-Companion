import Foundation

@main struct DraftTransitionsTests {
    @MainActor static func main() {
        let guarder = DraftTransitions()
        let id = UUID()
        var dirty = false, saved = false, discarded = false, moved = false
        var prompts = 0, choice = DraftTransitions.Choice.cancel, saveWorks = true
        guarder.choose = { _ in prompts += 1; return choice }
        func register() {
            guarder.register(id, dirty: { dirty }, title: "Synthetic draft", save: {
                guard saveWorks else { return false }
                saved = true; dirty = false; return true
            }, discard: { discarded = true; dirty = false })
        }
        var checks = 0
        func check(_ condition: Bool, _ reason: String) { precondition(condition, reason); checks += 1 }
        register()
        guarder.perform { moved = true }
        check(moved && prompts == 0, "Clean transitions need no prompt")
        dirty = true; moved = false
        check(guarder.hasChanges, "Live state is evaluated without re-registering")
        guarder.perform { moved = true }
        check(!moved && dirty && !saved && !discarded, "Cancel preserves draft/source and prevents navigation")
        choice = .save; saveWorks = false
        guarder.perform { moved = true }
        check(!moved && dirty && guarder.hasChanges, "Failed save never navigates")
        saveWorks = true
        guarder.perform { moved = true }
        check(moved && saved && !guarder.hasChanges, "Successful save permits exactly the pending transition")
        dirty = true; moved = false; register(); choice = .discard
        guarder.perform { moved = true }
        check(moved && discarded && !dirty, "Explicit discard permits navigation")
        dirty = true; register(); guarder.remove(id)
        check(!guarder.hasChanges, "Disappeared editor is unregistered")
        let other = UUID()
        guarder.register(other, dirty: { true }, title: "Other window", save: { false }, discard: {})
        choice = .cancel
        check(!guarder.authorize(), "Other-window draft also protects shared source/quit")
        guarder.remove(other)
        guarder.register(id, dirty: { true }, title: "Nested save", save: {
            check(guarder.authorize(), "Internal save transition must not recursively prompt")
            return true
        }, discard: {})
        choice = .save
        check(guarder.authorize(), "Nested save completes")
        guarder.register(id, dirty: { true }, title: "Modal re-entry", save: { true }, discard: {})
        guarder.choose = { _ in
            check(!guarder.authorize(), "External re-entry during a prompt is blocked")
            return .cancel
        }
        check(!guarder.authorize(), "Modal cancel remains blocked")
        check(DraftTransitions.fingerprint(["a": 1, "b": 2]) == DraftTransitions.fingerprint(["b": 2, "a": 1]), "Stable dictionary fingerprint")
        print("Draft transitions: \(checks) checks passed; no dialogs, library or device")
    }
}
