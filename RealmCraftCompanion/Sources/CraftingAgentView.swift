import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class CraftingAgentLibrary: ObservableObject {
    static let shared = CraftingAgentLibrary()
    let storage: CraftingAgentStorage
    @Published private(set) var state = CraftingAgentPreferences()
    @Published private(set) var failure = ""
    init(url: URL = CraftingAgentStorage.defaultURL) { storage = .init(url: url); reload() }
    private func accept(_ value: CraftingAgentPreferences) { if state != value { state = value }; failure = "" }
    func reload() {
        do { accept(try storage.load()) } catch { failure = error.localizedDescription }
    }
    func update(_ change: (inout CraftingAgentPreferences) -> Void) {
        do { accept(try storage.update(change)) } catch { failure = error.localizedDescription }
    }
    func snapshot(index: CraftingIndex, instructions: [CraftingInstruction]? = nil, desired: Int = 1, english: Bool) throws -> CraftingAgentSnapshot {
        let latest: CraftingAgentPreferences
        do { latest = try storage.load(); failure = "" }
        catch { failure = error.localizedDescription; throw error }
        // Capturing a document must not publish a deferred selection change that cancels its generation.
        return try .make(index: index, preferences: latest, instructions: instructions, desired: desired, english: english)
    }
}

struct CraftingAgentErrorView: View {
    @ObservedObject var library: CraftingAgentLibrary
    let english: Bool
    var body: some View {
        if !library.failure.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(english ? "Checkmarks or export unavailable. Reload to retry; existing data is preserved." : "Häkchen oder Export nicht verfügbar. Zum Wiederholen neu laden; vorhandene Daten bleiben erhalten.")
                    .foregroundStyle(.red)
                Text(library.failure).font(.caption).textSelection(.enabled)
                Button(english ? "Reload checkmarks" : "Häkchen neu laden") { library.reload() }
            }
        }
    }
}

/// Same controls for every exact recipe variant and every obtaining item.
struct CraftingAgentControls: View {
    @ObservedObject var library: CraftingAgentLibrary
    let instruction: CraftingInstruction
    let index: CraftingIndex
    let english: Bool
    var desired = 1
    @State private var notice = ""
    @State private var exportFailure = ""
    private var record: CraftingAgentRecord { library.state.records[instruction.id, default: .init()] }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(english ? "Verified by me in RealmCraft" : "Von mir in RealmCraft verifiziert", isOn: Binding(
                get: { record.isVerified(instruction, index: index) },
                set: { enabled in library.update { $0.verify(instruction, index: index, enabled: enabled) } }
            )).toggleStyle(.checkbox).accessibilityIdentifier("crafting.agent.verified")
            if record.verifiedAt != nil && !record.isVerified(instruction, index: index) {
                Label(english ? "Guide changed · verify again" : "Anleitung geändert · erneut prüfen", systemImage: "arrow.clockwise").foregroundStyle(.orange).font(.caption)
            }
            Toggle(english ? "Include in the combined AI export" : "In den KI-Gesamtexport aufnehmen", isOn: Binding(
                get: { record.selected },
                set: { enabled in library.update { $0.records[instruction.id, default: .init()].selected = enabled } }
            )).toggleStyle(.checkbox).accessibilityIdentifier("crafting.agent.selected")
            Text(english ? "Applies only to this recipe variant or obtaining guide for this item. Confirm after trying it in your game; source limitations remain visible." : "Gilt nur für diese Rezeptvariante oder Beschaffungsanleitung dieses Gegenstands. Nach dem Ausprobieren im eigenen Spiel bestätigen; Quellengrenzen bleiben sichtbar.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack { exportButton; copyButton }
                VStack(alignment: .leading) { exportButton; copyButton }
            }
            if !notice.isEmpty { Text(notice).font(.caption).textSelection(.enabled) }
            if !exportFailure.isEmpty { Text(exportFailure).font(.caption).foregroundStyle(.red) }
        }
        .disabled(!library.failure.isEmpty)
        .onChange(of: instruction.id) { _, _ in notice = ""; exportFailure = "" }
        CraftingAgentErrorView(library: library, english: english)
    }
    private var exportButton: some View {
        Button(english ? "Save agent Markdown…" : "Agenten-Markdown speichern …") { export(copy: false) }
            .accessibilityIdentifier("crafting.agent.save")
    }
    private var copyButton: some View {
        Button(english ? "Copy agent Markdown" : "Agenten-Markdown kopieren") { export(copy: true) }
    }
    private func export(copy: Bool) {
        do {
            let snapshot = try library.snapshot(index: index, instructions: [instruction], desired: desired, english: english)
            if copy { try CraftingAgentFile.copy(snapshot.markdown, english: english) }
            else if !CraftingAgentFile.save(snapshot.markdown, name: "RealmCraft-" + instruction.itemID + ".md", english: english) { return }
            notice = copy ? (english ? "Markdown copied. Paste it into your agent." : "Markdown kopiert. Bei deinem Agenten einfügen.") : (english ? "Markdown saved. Attach the file to your agent." : "Markdown gespeichert. Die Datei bei deinem Agenten anhängen.")
            exportFailure = ""
        } catch { exportFailure = error.localizedDescription }
    }
}

enum CraftingAgentFile {
    static func copy(_ markdown: String, english: Bool) throws {
        NSPasteboard.general.clearContents()
        guard NSPasteboard.general.setString(markdown, forType: .string) else {
            throw NSError(domain: "CraftingAgent", code: 2, userInfo: [NSLocalizedDescriptionKey: english ? "Could not copy Markdown." : "Markdown konnte nicht kopiert werden."])
        }
    }
    static func save(_ markdown: String, name: String, english: Bool) -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.nameFieldStringValue = name
        guard panel.runModal() == .OK, let target = panel.url else { return false }
        do {
            let library = UserDefaults.standard.string(forKey: "libraryPath").map { URL(fileURLWithPath: $0) }
                ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("RealmCraftLibrary/Savegames")
            _ = try MarkdownExportPackage.write(markdown: markdown, videoMarkdown: nil, to: target, library: library)
            return true
        } catch { NSAlert(error: error).runModal(); return false }
    }
}

struct CraftingAgentSelectionView: View {
    @ObservedObject var library: CraftingAgentLibrary
    let index: CraftingIndex
    let english: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var notice = ""
    @State private var failure = ""
    private var instructions: [CraftingInstruction] { CraftingInstruction.all(index) }
    private var verified: [CraftingInstruction] { instructions.filter { library.state.records[$0.id]?.isVerified($0, index: index) == true } }
    private var selected: [CraftingInstruction] { instructions.filter { library.state.selectedIDs.contains($0.id) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(english ? "Guides for the agent" : "Anleitungen für den Agenten").font(.title2.bold())
                Spacer()
                Button(english ? "Done" : "Fertig") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            Text(english ? "\(verified.count) personally verified · \(library.state.selectedIDs.count) selected" : "\(verified.count) persönlich verifiziert · \(library.state.selectedIDs.count) ausgewählt")
            Text(english ? "Select guides in their details or add all current personal confirmations here. The selection also appears in AI export. Markdown includes steps, quantities, sources and verification status; combined exports use one batch per recipe." : "Wähle Anleitungen in ihren Details oder füge hier alle aktuellen persönlichen Bestätigungen hinzu. Die Auswahl steht auch im KI-Export bereit. Markdown enthält Schritte, Mengen, Quellen und Prüfstatus; Gesamtexporte verwenden einen Durchgang je Rezept.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button(english ? "Add all verified guides" : "Alle verifizierten hinzufügen") { library.update { $0.selectVerified(index) } }
                    .disabled(verified.isEmpty || !library.failure.isEmpty)
                Button(english ? "Clear selection" : "Auswahl leeren") {
                    library.update { state in for key in Array(state.records.keys) { state.records[key]?.selected = false } }
                }.disabled(library.state.selectedIDs.isEmpty || !library.failure.isEmpty)
            }
            if library.state.selectedIDs.count > selected.count {
                Label(english ? "Selected guides are missing. Clear the selection and select the available guides again." : "Ausgewählte Anleitungen fehlen. Auswahl leeren und verfügbare Anleitungen erneut auswählen.", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
            }
            if selected.isEmpty {
                Text(english ? "No guides selected yet. Use the checkbox in a recipe or obtaining guide." : "Noch keine Anleitungen ausgewählt. Nutze die Checkbox in einem Rezept oder einer Beschaffungsanleitung.")
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 160)
            } else {
                List(selected) { instruction in
                    VStack(alignment: .leading, spacing: 5) {
                        Toggle(instruction.title(index, english: english), isOn: Binding(
                            get: { library.state.records[instruction.id]?.selected == true },
                            set: { value in library.update { $0.records[instruction.id]?.selected = value } }
                        )).toggleStyle(.checkbox)
                        if let recipe = instruction.recipe {
                            Text(recipe.ingredients.map { "\($0.count) × " + index.ingredientName($0, english: english) }.joined(separator: " + "))
                                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                        let verified = library.state.records[instruction.id]?.isVerified(instruction, index: index) == true
                        Text(verified ? (english ? "Personally verified" : "Persönlich verifiziert") : (english ? "Not currently verified" : "Aktuell nicht verifiziert"))
                            .font(.caption).foregroundStyle(verified ? Color.secondary : Color.orange)
                    }
                }.frame(minHeight: 160).disabled(!library.failure.isEmpty)
            }
            CraftingAgentErrorView(library: library, english: english)
            if !failure.isEmpty { Text(failure).foregroundStyle(.red).textSelection(.enabled) }
            if !notice.isEmpty { Text(notice).font(.caption) }
            HStack {
                Button(english ? "Save selection as Markdown…" : "Auswahl als Markdown speichern …") { export(copy: false) }
                Button(english ? "Copy Markdown" : "Markdown kopieren") { export(copy: true) }
            }.disabled(library.state.selectedIDs.isEmpty || !library.failure.isEmpty || library.state.selectedIDs.count != selected.count)
        }.padding(24).frame(minWidth: 620, idealWidth: 700, minHeight: 490, idealHeight: 600)
        .onAppear { library.reload() }
    }
    private func export(copy: Bool) {
        do {
            let snapshot = try library.snapshot(index: index, english: english)
            if copy { try CraftingAgentFile.copy(snapshot.markdown, english: english) }
            else if !CraftingAgentFile.save(snapshot.markdown, name: "RealmCraft-Agent-Guides.md", english: english) { return }
            notice = copy ? (english ? "Markdown copied." : "Markdown kopiert.") : (english ? "Markdown saved. Attach the file to your agent." : "Markdown gespeichert. Die Datei bei deinem Agenten anhängen.")
            failure = ""
        } catch { failure = error.localizedDescription }
    }
}
