import Foundation
@main struct AgentSkillsTests {
    @MainActor static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Skills-Test-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("skills/library.json")
        let seed = AgentSkill(title: "Welt", summary: "Test", instructions: "Prüfe Sicherungsdaten.")
        let a = AgentSkillLibrary(file: file, seeds: [seed])
        let b = AgentSkillLibrary(file: file, seeds: [])
        precondition(a.state.skills.count == 1 && b.state.skills.count == 1)
        var first = a.state.skills[0]; first.notes = "Keine Spoiler"
        try a.save(first, isNew: false)
        do { try b.save(first, isNew: false); fatalError("Stale edits must not overwrite") } catch {}
        let new = AgentSkill(title: "Bauen", summary: "Materialien", instructions: "Plane einen Turm.")
        try b.save(new, isNew: true)
        try a.reload(); precondition(a.state.skills.count == 2 && a.state.skills.first { $0.id == first.id }!.notes == "Keine Spoiler")
        try a.archive(a.state.skills.first { $0.id == new.id }!, archived: true)
        precondition(a.state.skills.first { $0.id == new.id }!.archived)
        try a.archive(a.state.skills.first { $0.id == new.id }!, archived: false)
        try a.saveProfile("Quest, Deutsch", revision: a.state.profileRevision)
        let current = a.state.skills[0]
        let raw = AIContextDocument(payload: ["evidence": ["exact": 123]], markdown: "## Vollständige Daten\n123", videoMarkdown: "## Videos\nReference")
        let augmented = AgentSkillExport.attach(current, profile: a.state.profile, to: raw)
        precondition(augmented.videoMarkdown == raw.videoMarkdown)
        precondition(augmented.markdown.hasSuffix(raw.markdown) && raw.payload["agentHandoff"] == nil)
        let handoff = augmented.payload["agentHandoff"] as! [String: Any]
        precondition(handoff["userContext"] as? String == "Quest, Deutsch")
        let privateExport = AgentSkillExport.attach(current, profile: nil, to: raw)
        precondition((privateExport.payload["agentHandoff"] as! [String: Any])["userContext"] == nil)
        precondition(!privateExport.markdown.contains("Quest, Deutsch"))
        let plain = AgentSkillExport.attach(nil, profile: nil, to: raw)
        precondition(plain.markdown == raw.markdown)
        var quoted = seed; quoted.summary = "Quotes: \"x\"\nand newline"
        let imported = AgentSkill.imported(quoted.markdown, filename: "Imported")
        precondition(imported.summary == quoted.summary && imported.instructions == quoted.instructions)
        let libraryRoot = directory.appendingPathComponent("saves")
        let support = directory.appendingPathComponent("exports")
        let path = try CompanionExportArchive.write(markdown: augmented.markdown, json: augmented.json, root: libraryRoot, videoMarkdown: augmented.videoMarkdown, support: support)
        let other = try CompanionExportArchive.write(markdown: augmented.markdown, json: augmented.json, root: libraryRoot, videoMarkdown: augmented.videoMarkdown, support: support)
        precondition(path != other)
        let event = CompanionActivityRecord(date: Date(), saveID: "save-1", title: "Welt", path: path.path)
        let read = try CompanionExportArchive.read(event, root: libraryRoot, support: support)
        precondition(read.markdown == augmented.markdown && read.videoMarkdown == raw.videoMarkdown)
        do { _ = try CompanionExportArchive.write(markdown: "x", json: Data(), root: libraryRoot, support: libraryRoot.appendingPathComponent("exports")); fatalError("Never write into saves") } catch {}
        let suite = "skills-test-" + UUID().uuidString; let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let activity = CompanionActivity(defaults: defaults)
        activity.record(event, kind: "export", root: libraryRoot)
        precondition(CompanionActivity(defaults: defaults).latest("export", root: libraryRoot) == event)
        precondition(activity.latest("export", root: directory.appendingPathComponent("other-saves")) == nil)
        var older = event; older.date = event.date.addingTimeInterval(-100)
        activity.record(older, kind: "export", root: libraryRoot)
        precondition(activity.latest("export", root: libraryRoot)!.date == event.date)
        let mapFolder = directory.appendingPathComponent("maps/generated")
        try FileManager.default.createDirectory(at: mapFolder, withIntermediateDirectories: true)
        let mapFile = mapFolder.appendingPathComponent("index.html")
        try Data("map".utf8).write(to: mapFile)
        try Data("data".utf8).write(to: mapFolder.appendingPathComponent("biomes.js"))
        defaults.set(mapFile.path, forKey: "map.save-1.128.en")
        activity.recoverMap(saves: [(id: "save-1", title: "Welt")], root: libraryRoot, support: directory.appendingPathComponent("maps"))
        precondition(activity.latest("map", root: libraryRoot)?.recovered == true)
        let unrelated = directory.appendingPathComponent("unrelated")
        activity.recoverMap(saves: [(id: "save-1", title: "Welt")], root: unrelated, support: directory.appendingPathComponent("different-map-folder"))
        precondition(activity.latest("map", root: unrelated) == nil)
        for item in a.state.skills { try a.delete(item) }
        precondition(AgentSkillLibrary(file: file, seeds: [seed]).state.skills.isEmpty)
        let corrupt = directory.appendingPathComponent("corrupt.json");try Data("invalid".utf8).write(to: corrupt)
        let broken = AgentSkillLibrary(file: corrupt, seeds: [seed]);precondition(broken.error != nil)
        do { try broken.save(new, isNew: true);fatalError("Corrupt store must not be replaced") } catch {}
        let corruptText = try String(contentsOf: corrupt, encoding: .utf8)
        precondition(corruptText == "invalid")
        print("Passed skill persistence, revision conflicts, archive/restore/delete, profile opt-in, Markdown import, immutable handoff, export archive, history isolation and corrupt-store protection")
    }
}
