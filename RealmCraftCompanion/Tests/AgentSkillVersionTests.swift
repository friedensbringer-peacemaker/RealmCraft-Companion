import Foundation

@main struct AgentSkillVersionTests {
    @MainActor static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("library.json")
        let seed = AgentSkill(title: "Initial", summary: "Synthetic", instructions: "Read synthetic data.")
        let library = AgentSkillLibrary(file: file, seeds: [seed])
        precondition(library.error == nil)
        var draft = library.state.skills[0]; draft.title = "Renamed"; draft.notes = "Test note"
        try library.save(draft, isNew: false)
        let changed = library.state.skills[0]
        precondition(library.versions(of: changed).count == 2)
        try library.restore(seed, current: changed)
        precondition(library.state.skills[0].title == "Initial")
        precondition(library.versions(of: library.state.skills[0]).count == 3)
        do { try library.save(changed, isNew: false); fatalError("Stale edit accepted") } catch {}
        try library.saveProfile("PRIVATE PROFILE", revision: library.state.profileRevision)
        let data = try library.package(library.state.skills)
        precondition(!String(decoding: data, as: UTF8.self).contains("PRIVATE PROFILE"))
        let destination = AgentSkillLibrary(file: directory.appendingPathComponent("import.json"), seeds: [])
        try destination.importPackage(data)
        precondition(destination.versions(of: destination.state.skills[0]).count == 3)
        try destination.importPackage(data)
        precondition(destination.state.skills.count == 2)
        precondition(destination.state.skills[0].id != destination.state.skills[1].id)
        precondition(destination.versions(of: destination.state.skills[1]).allSatisfy { $0.id == destination.state.skills[1].id })
        do { try destination.importPackage(Data("{}".utf8)); fatalError("Invalid package accepted") } catch {}
        precondition(destination.state.skills.count == 2)
        try library.delete(library.state.skills[0])
        let reopened = AgentSkillLibrary(file: file, seeds: [seed])
        precondition(reopened.state.skills.isEmpty)
        let added = AgentSkill(title: "New bundled skill", summary: "Test", instructions: "Example")
        let upgraded = AgentSkillLibrary(file: file, seeds: [seed, added])
        precondition(upgraded.state.skills.map(\.id) == [added.id])
        // Simulate a v1 library written before history/seed migration existed.
        var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(AgentSkillState(skills: [seed]))) as! [String: Any]
        legacy.removeValue(forKey: "history"); legacy.removeValue(forKey: "installedSeedIDs")
        let legacyFile = directory.appendingPathComponent("legacy.json")
        try JSONSerialization.data(withJSONObject: legacy).write(to: legacyFile)
        let migrated = AgentSkillLibrary(file: legacyFile, seeds: [seed, added])
        precondition(migrated.state.skills.count == 2 && migrated.state.skills[0] == seed)
        var bilingual = AgentSkill(title: "Deutsch", summary: "Beschreibung", instructions: "Prüfe die Sicherung.")
        bilingual.setText(AgentSkillText(title: "English", summary: "Description", instructions: "Check the backup."), language: "en")
        precondition(bilingual.localized("en").title == "English" && bilingual.title == "Deutsch")
        let englishImport = AgentSkill.imported(bilingual.localized("en").markdown, filename: "SKILL")
        precondition(englishImport.language == "en" && englishImport.title == "English")
        try destination.save(bilingual, isNew: true)
        let package = try destination.package([destination.state.skills.last!])
        let decoded = try JSONDecoder().decode(AgentSkillPackage.self, from: package)
        precondition(decoded.skills[0].localized("en").instructions == "Check the backup.")
        var update = destination.state.skills.last!
        update.setText(AgentSkillText(title: "English edited", summary: "Description", instructions: "Check date."), language: "en")
        try destination.save(update, isNew: false)
        let latest = destination.state.skills.last!
        precondition(latest.title == "Deutsch" && destination.versions(of: latest)[0].localized("en").title == "English")
        var incomplete = latest
        incomplete.setText(AgentSkillText(title: "Missing", summary: "", instructions: ""), language: "en")
        do { try destination.save(incomplete, isNew: false); fatalError("Incomplete translation accepted") } catch {}
        var empty = latest
        empty.setText(AgentSkillText(title: "", summary: "", instructions: ""), language: "en")
        precondition(!empty.hasLanguage("en"))
        print("Passed history, restore, conflicts, package round-trip, collision copies, profile isolation, seed upgrade, legacy migration and multilingual history/package validation")
    }
}
