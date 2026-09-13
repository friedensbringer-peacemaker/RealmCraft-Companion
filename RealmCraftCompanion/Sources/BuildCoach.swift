import Foundation

/// A viewing checkpoint is not evidence that any blocks were placed in the game.
enum BuildCoach {
    static func reference(english: Bool) -> String {
        english
        ? "This build is untested and AI-generated. Agree on one fixed reference before building. Mark the front-left floor corner as zero. From there, x increases to the right and z toward the back of the build. The floor block is height y zero; y one is directly above it. These directions belong to the build, even when you turn your head. All counts are block positions, not metres. Stop and re-establish the reference whenever you lose orientation."
        : "Dieser Aufbau ist ungetestet und KI-generiert. Vereinbare vor dem Bauen einen festen Bezugspunkt. Markiere die vordere linke Bodenecke als Nullpunkt. Von dort wächst x nach rechts und z nach hinten in den Aufbau. Der Bodenblock hat die Höhe y null; y eins liegt direkt darüber. Diese Richtungen gehören zum Bauwerk, auch wenn du den Kopf drehst. Alle Abstände zählen Blockpositionen, keine Meter. Wenn die Orientierung verloren geht, halte an und kläre den Bezugspunkt erneut."
    }
    static func checkpoint(guide: BuildGuide, step: Int, english: Bool) -> String {
        let index = min(max(0, step), guide.steps.count - 1)
        return "\(guide.title.value(english))\nID: \(guide.id)\n" + (english
            ? "Viewing step \(index + 1) of \(guide.steps.count). Placement is not confirmed. On resuming, ask which actions were actually completed and establish the building reference again.\nCurrent instruction: "
            : "Angezeigter Schritt \(index + 1) von \(guide.steps.count). Platzierung ist nicht bestätigt. Beim Fortsetzen nach tatsächlich erledigten Aufgaben fragen und den Baubezug erneut klären.\nAktuelle Aufgabe: ") + guide.steps[index].value(english)
    }
    static func save(guide: BuildGuide, step: Int, defaults: UserDefaults = .standard) {
        defaults.set(["step": min(max(0, step), guide.steps.count - 1), "plan": guide.steps.map(\.en).joined(separator: "\n")], forKey: "buildCoach.position.\(guide.id)")
    }
    static func restore(guide: BuildGuide, defaults: UserDefaults = .standard) -> Int {
        guard let state = defaults.dictionary(forKey: "buildCoach.position.\(guide.id)"),
              state["plan"] as? String == guide.steps.map(\.en).joined(separator: "\n"),
              let step = state["step"] as? Int, guide.steps.indices.contains(step) else { return 0 }
        return step
    }
}
