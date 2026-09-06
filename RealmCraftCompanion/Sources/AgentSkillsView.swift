import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AgentSkillsView: View {
    let language: String
    let saveLibrary: URL
    let useSkill: (String) -> Void
    @ObservedObject private var library = AgentSkillLibrary.shared
    @State private var selected: String?
    @State private var query = ""
    @State private var archived = false
    @State private var editing: AgentSkill?
    @State private var isNew = false
    @State private var showProfile = false
    @State private var deleting: AgentSkill?
    @State private var notice = ""
    private var en: Bool { language == "en" }
    private var filtered: [AgentSkill] {
        library.state.skills.filter { $0.archived == archived && (query.isEmpty || ($0.title + $0.summary + $0.instructions + $0.notes + $0.localized(en ? "en" : "de").title + $0.localized(en ? "en" : "de").summary).localizedCaseInsensitiveContains(query)) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
    private var current: AgentSkill? { filtered.first { $0.id == selected } ?? filtered.first }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: en ? "Skill library" : "Skill-Bibliothek") {
                TextField(en ? "Search skills" : "Skills suchen", text: $query).textFieldStyle(.roundedBorder).frame(width: 200)
                Button(en ? "New skill" : "Neuer Skill") {
                    isNew = true; editing = AgentSkill(title: "", summary: "", instructions: "")
                }.buttonStyle(CompanionButtonStyle(prominent: true))
                Menu {
                    Button(en ? "Personal context…" : "Persönliche Angaben …") { showProfile = true }
                    Button(en ? "Import skill package…" : "Skill-Paket importieren …", action: importPackage)
                    Button(en ? "Export entire library…" : "Gesamte Bibliothek exportieren …") { exportPackage(library.state.skills) }
                    Button(en ? "Import Markdown…" : "Markdown importieren …", action: importFile)
                    Button(en ? "Reload library" : "Bibliothek neu laden") { perform { try library.reload() } }
                } label: { Image(systemName: "ellipsis.circle") }
            }
            Divider()
            if let error = library.error { Text(error).foregroundStyle(.red).textSelection(.enabled).padding(16) }
            HStack(spacing: 0) {
                VStack(spacing: 12) {
                    Picker(en ? "Collection" : "Sammlung", selection: $archived) {
                        Text(en ? "Active" : "Aktiv").tag(false); Text(en ? "Archive" : "Archiv").tag(true)
                    }.pickerStyle(.segmented).labelsHidden().padding(.horizontal, 16).padding(.top, 16)
                    List(selection: $selected) {
                        ForEach(filtered) { skill in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(skill.localized(en ? "en" : "de").title).font(.headline).lineLimit(2)
                                Text(skill.localized(en ? "en" : "de").summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }.padding(.vertical, 6).tag(skill.id)
                        }
                    }.listStyle(.sidebar).scrollContentBackground(.hidden)
                    Text(en ? "\(filtered.count) skills · stored on this Mac" : "\(filtered.count) Skills · lokal auf diesem Mac")
                        .font(.caption).foregroundStyle(.secondary).padding(16)
                }.frame(width: CompanionTheme.sidebarWidth)
                Divider()
                if let skill = current {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(skill.localized(en ? "en" : "de").title).font(.title.bold())
                            Text(skill.localized(en ? "en" : "de").summary).foregroundStyle(.secondary)
                            HStack {
                                Button(en ? "Edit / Rename" : "Bearbeiten / Umbenennen") { isNew = false; editing = skill }
                                Button(en ? "Use for AI export" : "Für KI-Export verwenden") { useSkill(skill.id) }
                                    .buttonStyle(CompanionButtonStyle(prominent: true)).disabled(skill.archived)
                                Menu {
                                    Button(en ? "Copy Markdown" : "Markdown kopieren") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(skill.localized(en ? "en" : "de").markdown, forType: .string); notice = en ? "Copied." : "Kopiert." }
                                    Button(en ? "Export with versions…" : "Mit Versionen exportieren …") { exportPackage([skill]) }
                                    Menu(en ? "Export Markdown" : "Markdown exportieren") {
                                        Button("Deutsch…") { export(skill, language: "de") }.disabled(!skill.hasLanguage("de"))
                                        Button("English…") { export(skill, language: "en") }.disabled(!skill.hasLanguage("en"))
                                        Button("Deutsch + English…") { export(skill, language: "both") }.disabled(!skill.hasLanguage("de") || !skill.hasLanguage("en"))
                                    }
                                    Button(en ? "Duplicate" : "Duplizieren") {
                                        var copy = skill; copy.id = UUID().uuidString; copy.title += en ? " · Copy" : " · Kopie"
                                        copy.archived = false; copy.createdAt = Date(); copy.revision = UUID().uuidString
                                        isNew = true; editing = copy
                                    }
                                    Divider()
                                    Button(skill.archived ? (en ? "Restore" : "Wiederherstellen") : (en ? "Archive" : "Archivieren")) {
                                        perform { try library.archive(skill, archived: !skill.archived) }
                                    }
                                    Button(en ? "Delete…" : "Löschen …", role: .destructive) { deleting = skill }
                                } label: { Image(systemName: "ellipsis.circle") }
                            }
                            if !notice.isEmpty { Text(notice).font(.caption).foregroundStyle(.secondary) }
                            Divider()
                            DisclosureGroup(en ? "Version history (\(library.versions(of: skill).count))" : "Versionshistorie (\(library.versions(of: skill).count))") {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array(library.versions(of: skill).enumerated()).reversed(), id: \.offset) { index, version in
                                        DisclosureGroup("V\(index + 1) · \(version.localized(en ? "en" : "de").title) · \(version.updatedAt.formatted(date: .abbreviated, time: .shortened))") {
                                            VStack(alignment: .leading, spacing: 10) {
                                                Text(version.localized(en ? "en" : "de").summary).foregroundStyle(.secondary)
                                                Text(version.localized(en ? "en" : "de").instructions).textSelection(.enabled)
                                                if !version.localized(en ? "en" : "de").notes.isEmpty { Text(version.localized(en ? "en" : "de").notes).textSelection(.enabled) }
                                                if index < library.versions(of: skill).count - 1 {
                                                    Button(en ? "Restore as new version" : "Als neue Version wiederherstellen") {
                                                        perform { try library.restore(version, current: skill) }
                                                    }
                                                }
                                            }.padding(10)
                                        }
                                    }
                                }.padding(.top, 10)
                            }
                            Text((en ? "Available languages: " : "Verfügbare Sprachen: ") + ["de", "en"].filter { skill.hasLanguage($0) }.map { $0 == "de" ? "Deutsch" : "English" }.joined(separator: " · ")).font(.caption)
                            Text(en ? "Instructions" : "Anweisungen").font(.headline)
                            Text(skill.localized(en ? "en" : "de").instructions).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                            if !skill.localized(en ? "en" : "de").notes.isEmpty {
                                Divider(); Text(en ? "Personal additions" : "Persönliche Ergänzungen").font(.headline)
                                Text(skill.localized(en ? "en" : "de").notes).textSelection(.enabled)
                            }
                            Divider()
                            Text(en ? "Attach the Markdown file or paste its text into GPT, Copilot, Claude or another agent. Automatic skill recognition depends on the agent. Personal context is only added to world exports when you select it there."
                                 : "Markdown-Datei anhängen oder den Text in GPT, Copilot, Claude oder einen anderen Agenten einfügen. Automatische Skill-Erkennung hängt vom Agenten ab. Persönliche Angaben werden dem Weltexport nur auf Wunsch beigefügt.")
                                .font(.callout).foregroundStyle(.secondary)
                            Button(en ? "Edit personal context…" : "Persönliche Angaben bearbeiten …") { showProfile = true }
                            Text((en ? "Updated: " : "Bearbeitet: ") + skill.updatedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                        }.padding(CompanionLayout.pageInset).frame(maxWidth: 900, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
                    }.id(skill.id)
                } else {
                    ContentUnavailableView(en ? "No skills here yet" : "Hier sind noch keine Skills", systemImage: "text.book.closed", description: Text(en ? "Create a skill, import Markdown or change the filter." : "Erstelle einen Skill, importiere Markdown oder ändere den Filter."))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .sheet(item: $editing) { skill in AgentSkillEditor(skill: skill, isNew: isNew, library: library, english: en) { selected = $0; archived = false }.companionAppearance() }
        .sheet(isPresented: $showProfile) { AgentProfileEditor(library: library, english: en).companionAppearance() }
        .alert(en ? "Permanently delete skill?" : "Skill endgültig löschen?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button(en ? "Cancel" : "Abbrechen", role: .cancel) { deleting = nil }
            Button(en ? "Delete" : "Löschen", role: .destructive) { if let skill = deleting { perform { try library.delete(skill) } }; deleting = nil }
        } message: { Text(en ? "Existing export files are kept. You can archive the skill instead." : "Vorhandene Exportdateien bleiben erhalten. Alternativ kannst du den Skill archivieren.") }
        .onAppear { perform { try library.reload() } }
    }
    private func perform(_ action: () throws -> Void) { do { try action(); notice = "" } catch { library.error = error.localizedDescription } }
    private func importPackage() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        perform {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 20_000_000 else { throw AgentSkillError(message: "Maximal 20 MB / Maximum 20 MB.") }
            try library.importPackage(Data(contentsOf: url)); archived = false
            notice = en ? "Imported. Matching IDs were added as copies." : "Importiert. Gleiche IDs wurden als Kopien angelegt."
        }
    }
    private func exportPackage(_ skills: [AgentSkill]) {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "RealmCraft-Skills.json"; panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        perform {
            try checkDestination(url)
            try library.package(skills).write(to: url, options: .atomic)
            notice = en ? "Exported with all versions and skill notes. Personal profile is excluded." : "Mit allen Versionen und Skill-Ergänzungen exportiert. Persönliches Profil ist nicht enthalten."
        }
    }
    private func checkDestination(_ url: URL) throws {
        let destination = url.resolvingSymlinksInPath().standardizedFileURL.path
        let root = saveLibrary.resolvingSymlinksInPath().standardizedFileURL.path
        guard destination != root, !destination.hasPrefix(root + "/") else { throw AgentSkillError(message: "Bitte außerhalb der Spielstand-Bibliothek speichern / Save outside the savegame library.") }
    }
    private func importFile() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.plainText, UTType(filenameExtension: "md") ?? .plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        perform {
            guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 2_000_000 else { throw AgentSkillError(message: "Maximal 2 MB / Maximum 2 MB.") }
            let data = try Data(contentsOf: url)
            guard data.count <= 2_000_000, let text = String(data: data, encoding: .utf8) else { throw AgentSkillError(message: "Bitte eine UTF-8-Textdatei bis 2 MB wählen / Choose UTF-8 text up to 2 MB.") }
            isNew = true; editing = AgentSkill.imported(text, filename: url.deletingPathExtension().lastPathComponent)
        }
    }
    private func export(_ skill: AgentSkill, language: String) {
        let panel = NSSavePanel(); panel.nameFieldStringValue = language == "both" ? "SKILL-de-en.md" : "SKILL.md"; panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        perform {
            try checkDestination(url)
            let markdown = language == "both" ? ["de", "en"].map { code in
                let item = skill.localized(code)
                return "# " + (code == "de" ? "Deutsch" : "English") + " · " + item.title + "\n\n" + item.summary + "\n\n" + item.instructions + (item.notes.isEmpty ? "" : "\n\n" + item.notes)
            }.joined(separator: "\n\n---\n\n") : skill.localized(language).markdown
            try Data(markdown.utf8).write(to: url, options: .atomic); notice = en ? "Skill exported." : "Skill exportiert."
        }
    }
}

private struct AgentSkillEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AgentSkill
    @State private var error = ""
    @State private var editLanguage: String
    @State private var text: AgentSkillText
    @State private var translating = false
    @State private var relabeling = false
    @State private var translationTask: Task<Void, Never>?

    let isNew: Bool
    let library: AgentSkillLibrary
    let english: Bool
    let saved: (String) -> Void
    init(skill: AgentSkill, isNew: Bool, library: AgentSkillLibrary, english: Bool, saved: @escaping (String) -> Void) {
        _draft = State(initialValue: skill); _editLanguage = State(initialValue: english && skill.hasLanguage("en") ? "en" : skill.language ?? "de"); _text = State(initialValue: skill.localized(english && skill.hasLanguage("en") ? "en" : skill.language ?? "de").text); self.isNew = isNew; self.library = library; self.english = english; self.saved = saved
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(english ? "Edit skill" : "Skill bearbeiten").font(.title2.bold())
            if isNew && draft.translations?.isEmpty != false {
                Picker(english ? "Original text language" : "Sprache des Originaltexts", selection: Binding(get: { draft.language ?? "de" }, set: { code in
                    draft.setText(text, language: editLanguage)
                    draft.language = code
                    relabeling = editLanguage != code
                    editLanguage = code
                })) { Text("Deutsch").tag("de"); Text("English").tag("en") }.disabled(translating)
            }
            Picker(english ? "Language" : "Sprache", selection: $editLanguage) {
                Text("Deutsch").tag("de"); Text("English").tag("en")
            }.pickerStyle(.segmented).disabled(translating)
            .onChange(of: editLanguage) { old, new in
                if relabeling { relabeling = false; return }
                draft.setText(text, language: old)
                text = draft.hasLanguage(new) ? draft.localized(new).text : AgentSkillText(title: "", summary: "", instructions: "")
            }
            HStack {
                Button(english ? "Translate from other language with local Qwen" : "Aus anderer Sprache mit lokalem Qwen übersetzen") { translate() }
                    .disabled(translating || !draft.hasLanguage(editLanguage == "de" ? "en" : "de"))
                if translating { ProgressView().controlSize(.small); Button(english ? "Cancel translation" : "Übersetzung abbrechen") { translationTask?.cancel() } }
            }
            Text(english ? "Qwen drafts a translation locally through LM Studio (port 1234). Review it before saving. It replaces the visible draft; saving creates a version. No cloud fallback." : "Qwen erstellt lokal über LM Studio (Port 1234) einen Übersetzungsentwurf. Vor dem Speichern prüfen. Der sichtbare Entwurf wird ersetzt; Speichern erstellt eine Version. Kein Cloud-Fallback.").font(.caption).foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField(english ? "Title" : "Titel", text: $text.title).textFieldStyle(.roundedBorder)
                    TextField(english ? "Description · when to use this skill" : "Kurzbeschreibung · wann dieser Skill passt", text: $text.summary).textFieldStyle(.roundedBorder)
                    Text(english ? "Instructions (Markdown)" : "Anweisungen (Markdown)").font(.headline)
                    TextEditor(text: $text.instructions).font(.system(.body, design: .monospaced)).frame(minHeight: 260).padding(8).companionPanel()
                    Text(english ? "Personal additions for this skill" : "Eigene Ergänzungen für diesen Skill").font(.headline)
                    TextEditor(text: $text.notes).frame(minHeight: 110).padding(8).companionPanel()
                }.padding(.trailing, 8)
            }
            if !error.isEmpty { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            HStack {
                Spacer(); Button(english ? "Cancel" : "Abbrechen") { dismiss() }
                Button(english ? "Save" : "Speichern") {
                    do { draft.setText(text, language: editLanguage); try library.save(draft, isNew: isNew); saved(draft.id); dismiss() } catch { self.error = error.localizedDescription }
                }.buttonStyle(CompanionButtonStyle(prominent: true)).keyboardShortcut(.defaultAction).disabled(translating)
            }
        }.padding(28).frame(width: 720, height: 650).interactiveDismissDisabled().onDisappear { translationTask?.cancel() }
    }
    private func translate() {
        let source = draft.localized(editLanguage == "de" ? "en" : "de").text
        let target = editLanguage
        translating = true; error = ""
        translationTask = Task { @MainActor in
            defer { translating = false }
            do {
                let result = try await AgentSkillTranslation.translate(source, target: target)
                try Task.checkCancellation()
                text = result
                error = english ? "AI translation draft — review before saving." : "KI-Übersetzungsentwurf – vor dem Speichern prüfen."
            } catch is CancellationError { }
            catch { self.error = error.localizedDescription }
        }
    }

}
private struct AgentProfileEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var error = ""
    let revision: String
    let library: AgentSkillLibrary
    let english: Bool
    init(library: AgentSkillLibrary, english: Bool) {
        self.library = library; self.english = english; self.revision = library.state.profileRevision; _text = State(initialValue: library.state.profile)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(english ? "Personal context for agents" : "Persönliche Angaben für Agenten").font(.title2.bold())
            Text(english ? "For example: platform, game version, preferred language, spoiler limits, current projects and play style. This stays on this Mac until you include it in an export." : "Zum Beispiel: Hardware, Spielversion, Antwortsprache, Spoilerwünsche, aktuelle Projekte und Spielweise. Diese Angaben bleiben auf diesem Mac, bis du sie in einen Export aufnimmst.").foregroundStyle(.secondary)
            TextEditor(text: $text).padding(8).companionPanel()
            if !error.isEmpty { Text(error).foregroundStyle(.red) }
            HStack {
                Spacer(); Button(english ? "Cancel" : "Abbrechen") { dismiss() }
                Button(english ? "Save" : "Speichern") {
                    do { try library.saveProfile(text, revision: revision); dismiss() } catch { self.error = error.localizedDescription }
                }.buttonStyle(CompanionButtonStyle(prominent: true)).keyboardShortcut(.defaultAction)
            }
        }.padding(28).frame(width: 660, height: 450).interactiveDismissDisabled()
    }
}
