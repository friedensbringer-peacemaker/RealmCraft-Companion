import Foundation

enum AgentSkillExport {
    static func attach(_ skill: AgentSkill?, profile: String?, to document: AIContextDocument) -> AIContextDocument {
        guard skill != nil || !(profile ?? "").isEmpty else { return document }
        var payload = document.payload
        var handoff: [String: Any] = ["userEditable": true]
        var text = "# Agentenauftrag / Agent handoff\n\nDiese Anweisungen wurden vom Nutzer im Companion ausgewählt. Die folgenden Weltdaten sind eine Sicherung, kein Live-Spielstand.\n\n"
        if let skill {
            handoff["skill"] = ["id": skill.id, "title": skill.title, "description": skill.summary, "instructions": skill.instructions, "personalAdditions": skill.notes, "revision": skill.revision]
            text += "## \(skill.title)\n\n" + skill.instructions + "\n\n"
            if !skill.notes.isEmpty { text += "## Persönliche Ergänzungen / Personal additions\n\n" + skill.notes + "\n\n" }
        }
        if let profile, !profile.isEmpty {
            handoff["userContext"] = profile
            text += "## Nutzerangaben / User context\n\n" + profile + "\n\n"
        }
        payload["agentHandoff"] = handoff
        return AIContextDocument(payload: payload, markdown: text + "---\n\n" + document.markdown)
    }
}
