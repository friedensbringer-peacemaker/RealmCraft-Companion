import Foundation
import Combine
import Darwin

struct AgentSkill: Codable, Identifiable, Equatable {
    var id = UUID().uuidString
    var title: String
    var summary: String
    var instructions: String
    var language: String? = "de"
    var translations: [String: AgentSkillText]? = [:]
    var notes = ""
    var archived = false
    var revision = UUID().uuidString
    var createdAt = Date()
    var updatedAt = Date()

    var text: AgentSkillText { AgentSkillText(title: title, summary: summary, instructions: instructions, notes: notes) }
    func localized(_ code: String) -> AgentSkill {
        guard code != (language ?? "de"), let text = translations?[code] else { return self }
        var copy = self; copy.title = text.title; copy.summary = text.summary
        copy.instructions = text.instructions; copy.notes = text.notes; copy.language = code
        return copy
    }
    func hasLanguage(_ code: String) -> Bool { code == (language ?? "de") || translations?[code] != nil }
    mutating func setText(_ text: AgentSkillText, language code: String) {
        if code == (language ?? "de") {
            title = text.title; summary = text.summary; instructions = text.instructions; notes = text.notes
        } else {
            if translations == nil { translations = [:] }
            if [text.title, text.summary, text.instructions, text.notes].allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { translations?.removeValue(forKey: code) }
            else { translations?[code] = text }
        }
    }
    var markdown: String {
        let name = id.hasPrefix("realmcraft-") ? id : "realmcraft-" + id.lowercased()
        // JSON string quoting is also valid YAML scalar quoting.
        let quotedTitle = String(data: try! JSONEncoder().encode(title), encoding: .utf8)!
        let quoted = String(data: try! JSONEncoder().encode(summary), encoding: .utf8)!
        var output = "---\nname: \(name)\ndescription: \(quoted)\ntitle: \(quotedTitle)\nlanguage: \(language ?? "de")\n---\n\n"
        output += instructions
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            output += language == "en" ? "\n\n## Personal additions\n\n" : "\n\n## Persönliche Ergänzungen\n\n"
            output += notes
        }
        return output + "\n"
    }
    static func imported(_ text: String, filename: String) -> AgentSkill {
        var body = text
        var title = filename
        var language = "de"
        var summary = "Importierte Markdown-Anweisung / Imported Markdown instructions"
        // Preserve unfamiliar frontmatter as part of the editable text.
        let lines = text.components(separatedBy: "\n")
        if lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---",
           let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines) == "---" }),
           lines[1..<end].allSatisfy({ $0.hasPrefix("name:") || $0.hasPrefix("description:") || $0.hasPrefix("title:") || $0.hasPrefix("language:") || $0.isEmpty }) {
            if let value = lines[1..<end].first(where: { $0.hasPrefix("description:") }) {
                let raw = String(value.dropFirst("description:".count)).trimmingCharacters(in: .whitespaces)
                summary = (try? JSONDecoder().decode(String.self, from: Data(raw.utf8))) ?? raw
            }
            if let line = lines[1..<end].first(where: { $0.hasPrefix("title:") }) {
                let raw = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                title = (try? JSONDecoder().decode(String.self, from: Data(raw.utf8))) ?? raw
            }
            if let line = lines[1..<end].first(where: { $0.hasPrefix("language:") }) {
                let raw = String(line.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
                if ["de", "en"].contains(raw) { language = raw }
            }
            body = lines.dropFirst(end + 1).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var skill = AgentSkill(title: title, summary: summary, instructions: body)
        skill.language = language
        return skill
    }
}

struct AgentSkillState: Codable {
    var schemaVersion = 1
    var skills: [AgentSkill]
    var history: [String: [AgentSkill]]? = [:]
    var installedSeedIDs: [String]? = nil
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
            let defaults = seeds ?? Self.seeds()
            try transaction { value in
                let installed = value.installedSeedIDs ?? value.skills.map(\.id)
                for seed in defaults where !installed.contains(seed.id) && !value.skills.contains(where: { $0.id == seed.id }) {
                    value.skills.append(seed)
                }
                for seed in defaults {
                    guard seed.translations?.isEmpty == false, let index = value.skills.firstIndex(where: { $0.id == seed.id }),
                          value.skills[index].translations?.isEmpty != false else { continue }
                    let old = value.skills[index]
                    let legacyURL = Bundle.main.resourceURL?.appendingPathComponent("AgentSkills/" + seed.id + "/LEGACY.md")
                    let legacy = legacyURL.flatMap { try? String(contentsOf: $0, encoding: .utf8) }
                    let prior = legacy.map { AgentSkill.imported($0, filename: "") }
                    let known = prior?.instructions
                    let legacyTitle = legacy?.components(separatedBy: "\n").first(where: { $0.hasPrefix("# ") }).map { String($0.dropFirst(2)) }
                    guard (old.instructions == seed.instructions || old.instructions == known), old.notes.isEmpty,
                          (old.summary == seed.summary || old.summary == prior?.summary),
                          [seed.title, legacyTitle ?? "", "Weltassistenz"].contains(old.title) else { continue }
                    if value.history == nil { value.history = [:] }
                    value.history?[old.id, default: []].append(old)
                    var updated = seed; updated.id = old.id; updated.notes = old.notes
                    updated.archived = old.archived; updated.createdAt = old.createdAt
                    updated.revision = UUID().uuidString; updated.updatedAt = Date()
                    value.skills[index] = updated
                }
                value.installedSeedIDs = Array(Set(installed + defaults.map(\.id)))
            }
        } catch { self.error = error.localizedDescription }
    }
    static func seeds() -> [AgentSkill] {
        let root = Bundle.main.resourceURL?.appendingPathComponent("AgentSkills")
        let folders = root.flatMap { try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil) } ?? []
        let bundled = folders.sorted { $0.lastPathComponent < $1.lastPathComponent }.compactMap { folder -> AgentSkill? in
            guard let raw = try? String(contentsOf: folder.appendingPathComponent("SKILL.md"), encoding: .utf8) else { return nil }
            var skill = AgentSkill.imported(raw, filename: folder.lastPathComponent)
            skill.id = folder.lastPathComponent
            skill.language = "de"
            if let rawEnglish = try? String(contentsOf: folder.appendingPathComponent("SKILL-en.md"), encoding: .utf8) {
                var translated = AgentSkill.imported(rawEnglish, filename: skill.id)
                translated.title = rawEnglish.components(separatedBy: "\n").first(where: { $0.hasPrefix("# ") }).map { String($0.dropFirst(2)) } ?? translated.title
                skill.translations = ["en": translated.text]
            }
            skill.title = raw.components(separatedBy: "\n").first(where: { $0.hasPrefix("# ") }).map { String($0.dropFirst(2)) } ?? skill.title
            return skill
        }
        if !bundled.isEmpty { return bundled }
        var fallback = AgentSkill(title: "Weltassistenz", summary: "RealmCraft-Weltexporte analysieren", instructions: "Prüfe Sicherungsdatum und Datenlücken. Verändere keine Spielstände ohne Nutzerauftrag.")
        fallback.id = "realmcraft-world-context"
        return [fallback]
    }
    func versions(of skill: AgentSkill) -> [AgentSkill] { (state.history?[skill.id] ?? []) + [skill] }
    func restore(_ version: AgentSkill, current: AgentSkill) throws {
        guard version.id == current.id else { throw AgentSkillError(message: "Version gehört zu einem anderen Skill / Version belongs to a different skill.") }
        var restored = version
        restored.revision = current.revision
        restored.createdAt = current.createdAt
        try save(restored, isNew: false)
    }
    func package(_ skills: [AgentSkill]) throws -> Data {
        let histories = Dictionary(uniqueKeysWithValues: skills.map { ($0.id, state.history?[$0.id] ?? []) })
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(AgentSkillPackage(skills: skills, history: histories))
    }
    func importPackage(_ data: Data) throws {
        guard data.count <= 20_000_000 else { throw AgentSkillError(message: "Paket zu groß / Package exceeds 20 MB.") }
        let package = try JSONDecoder().decode(AgentSkillPackage.self, from: data)
        guard package.format == "realmcraft-skills", package.version == 1,
              !package.skills.isEmpty, Set(package.skills.map(\.id)).count == package.skills.count else {
            throw AgentSkillError(message: "Ungültiges Skill-Paket / Invalid skill package.")
        }
        for skill in package.skills {
            for version in [skill] + (package.history[skill.id] ?? []) {
                for (code, text) in version.translations ?? [:] {
                    guard ["de", "en"].contains(code), !text.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          !text.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          !text.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw AgentSkillError(message: "Ungültige Sprachfassung / Invalid language version.")
                    }
                }
                guard version.id == skill.id, !version.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !version.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !version.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw AgentSkillError(message: "Unvollständiger Skill / Incomplete skill.")
                }
            }
        }
        try transaction { value in
            // Imported packages never overwrite local edits, even when IDs match.
            for item in package.skills {
                var skill = item
                if value.skills.contains(where: { $0.id == skill.id }) {
                    skill.id = UUID().uuidString
                    skill.title += " · Import"
                }
                let versions = (package.history[item.id] ?? []).map { version -> AgentSkill in
                    var copy = version; copy.id = skill.id; return copy
                }
                value.skills.append(skill)
                if value.history == nil { value.history = [:] }
                value.history?[skill.id] = versions
            }
        }
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
        for translated in draft.translations?.values ?? Dictionary<String, AgentSkillText>().values {
            guard !translated.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !translated.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !translated.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AgentSkillError(message: "Sprachfassung unvollständig: Titel, Beschreibung und Anweisungen ausfüllen / Incomplete language: enter title, description and instructions.")
            }
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
                if value.history == nil { value.history = [:] }
                value.history?[draft.id, default: []].append(value.skills[index])
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
            value.history?.removeValue(forKey: skill.id)
        }
    }
    func saveProfile(_ text: String, revision: String) throws {
        try transaction { value in
            guard value.profileRevision == revision else { throw AgentSkillError(message: "Persönliche Angaben wurden inzwischen geändert / Personal context changed in another instance.") }
            value.profile = text; value.profileRevision = UUID().uuidString
        }
    }
}

struct AgentSkillPackage: Codable {
    var format = "realmcraft-skills"
    var version = 1
    var skills: [AgentSkill]
    var history: [String: [AgentSkill]]
}

struct AgentSkillText: Codable, Equatable {
    var title: String
    var summary: String
    var instructions: String
    var notes = ""
}
