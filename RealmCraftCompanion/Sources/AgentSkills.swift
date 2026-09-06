import Foundation
import Combine
import Darwin

struct AgentSkill: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var title: String
    var summary: String
    var instructions: String
    var notes = ""
    var archived = false
    var revision = UUID().uuidString
    var createdAt = Date()
    var updatedAt = Date()

    var markdown: String {
        let name = id == "realmcraft-world-context" ? id : "realmcraft-" + id.lowercased()
        // JSON string quoting is also valid YAML scalar quoting.
        let quoted = String(data: try! JSONEncoder().encode(summary), encoding: .utf8)!
        return "---\nname: \(name)\ndescription: \(quoted)\n---\n\n" + instructions +
            (notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n\n## Persönliche Ergänzungen / Personal additions\n\n" + notes) + "\n"
    }
    static func imported(_ text: String, filename: String) -> AgentSkill {
        var body = text
        var summary = "Importierte Markdown-Anweisung / Imported Markdown instructions"
        // Preserve unfamiliar frontmatter as part of the editable text.
        let lines = text.components(separatedBy: "\n")
        if lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---",
           let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines) == "---" }),
           lines[1..<end].allSatisfy({ $0.hasPrefix("name:") || $0.hasPrefix("description:") || $0.isEmpty }) {
            if let value = lines[1..<end].first(where: { $0.hasPrefix("description:") }) {
                let raw = String(value.dropFirst("description:".count)).trimmingCharacters(in: .whitespaces)
                summary = (try? JSONDecoder().decode(String.self, from: Data(raw.utf8))) ?? raw
            }
            body = lines.dropFirst(end + 1).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return AgentSkill(title: filename, summary: summary, instructions: body)
    }
}

struct AgentSkillState: Codable {
    var schemaVersion = 1
    var skills: [AgentSkill]
    var profile = ""
    var profileRevision = UUID().uuidString
}
struct AgentSkillError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

@MainActor final class AgentSkillLibrary: ObservableObject {
    static let shared = AgentSkillLibrary()
    @Published private(set) var state = AgentSkillState(skills: [])
    @Published var error: String?
    let file: URL
    init(file: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/RealmCraftLibrary/AgentSkills/library.json"), seeds: [AgentSkill]? = nil) {
        self.file = file
        do {
            if !FileManager.default.fileExists(atPath: file.path) {
                try transaction { value in if value.skills.isEmpty { value.skills = seeds ?? Self.seeds() } }
            } else { try reload() }
        } catch { self.error = error.localizedDescription }
    }
    static func seeds() -> [AgentSkill] {
        let url = Bundle.main.resourceURL?.appendingPathComponent("AgentSkills/realmcraft-world-context/SKILL.md")
        let raw = url.flatMap { try? String(contentsOf: $0, encoding: .utf8) }
            ?? "Nutze den beigefügten RealmCraft-Weltexport. Unterscheide Sicherungsdaten, persönliche Angaben und Vermutungen. Fehlende Daten bleiben unbekannt. Verändere keine Spielstände ohne Nutzerauftrag."
        var base = AgentSkill.imported(raw, filename: "Weltassistenz")
        base.id = "realmcraft-world-context"
        return [base]
    }
    private func read() throws -> AgentSkillState {
        guard FileManager.default.fileExists(atPath: file.path) else { return AgentSkillState(skills: []) }
        let value = try JSONDecoder().decode(AgentSkillState.self, from: Data(contentsOf: file))
        guard value.schemaVersion == 1, Set(value.skills.map(\.id)).count == value.skills.count else {
            throw AgentSkillError(message: "Skill-Bibliothek hat ein unbekanntes Format / Unsupported skill library format.")
        }
        return value
    }
    func reload() throws { state = try read(); error = nil }
    private func transaction(_ change: (inout AgentSkillState) throws -> Void) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fd = Darwin.open(file.appendingPathExtension("lock").path, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw CocoaError(.fileWriteNoPermission) }
        defer { Darwin.close(fd) }
        guard flock(fd, LOCK_EX) == 0 else { throw CocoaError(.fileWriteUnknown) }
        var next = try read()
        try change(&next)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(next).write(to: file, options: .atomic)
        state = next; error = nil
    }
    func save(_ draft: AgentSkill, isNew: Bool) throws {
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !draft.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !draft.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentSkillError(message: "Bitte Titel, Kurzbeschreibung und Anweisungen ausfüllen / Enter a title, description and instructions.")
        }
        try transaction { value in
            var saved = draft; saved.updatedAt = Date(); saved.revision = UUID().uuidString
            if isNew {
                guard !value.skills.contains(where: { $0.id == draft.id }) else { throw CocoaError(.fileWriteFileExists) }
                value.skills.append(saved)
            } else {
                guard let index = value.skills.firstIndex(where: { $0.id == draft.id }), value.skills[index].revision == draft.revision else {
                    throw AgentSkillError(message: "Dieser Skill wurde in einer anderen Instanz geändert. Kopiere deine Änderungen und öffne den aktuellen Stand erneut / This skill changed in another instance. Copy your edits and reopen the current version.")
                }
                value.skills[index] = saved
            }
        }
    }
    func archive(_ skill: AgentSkill, archived: Bool) throws { var copy = skill; copy.archived = archived; try save(copy, isNew: false) }
    func delete(_ skill: AgentSkill) throws {
        try transaction { value in
            guard let current = value.skills.first(where: { $0.id == skill.id }), current.revision == skill.revision else {
                throw AgentSkillError(message: "Skill wurde inzwischen geändert. Bitte neu laden / Skill changed; please reload.")
            }
            value.skills.removeAll { $0.id == skill.id }
        }
    }
    func saveProfile(_ text: String, revision: String) throws {
        try transaction { value in
            guard value.profileRevision == revision else { throw AgentSkillError(message: "Persönliche Angaben wurden inzwischen geändert / Personal context changed in another instance.") }
            value.profile = text; value.profileRevision = UUID().uuidString
        }
    }
}
