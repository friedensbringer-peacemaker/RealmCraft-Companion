import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor final class Model: ObservableObject {
    @Published var saves: [Savegame] = []
    @Published var worldNames: [String:String] = [:]
    @Published var selection: String? { didSet { UserDefaults.standard.set(selection, forKey: "lastSaveID") } }
    @Published var devices: [Device] = []
    @Published var serial = "" { didSet { if !serial.isEmpty { UserDefaults.standard.set(serial, forKey: "lastDevice") } } }
    @Published var worlds: [String] = []
    @Published var world = "" { didSet { if !world.isEmpty { UserDefaults.standard.set(world, forKey: "lastWorld") } } }
    @Published var busy = false
    @Published var status = "Quest per USB verbinden und RealmCraft beenden."
    @Published var error: String?
    @Published var query = ""
    @Published var setup = SetupReport()
    @Published var showSetup = false
    @Published var scanning = false
    @Published var history: [String] = []
    let library: Library
    let queue = DispatchQueue(label: "RealmCraft.Library", qos: .userInitiated)
    init() {
        library = try! Library()
        selection = UserDefaults.standard.string(forKey: "lastSaveID")
        serial = UserDefaults.standard.string(forKey: "lastDevice") ?? ""
        world = UserDefaults.standard.string(forKey: "lastWorld") ?? ""
        reload()
        showSetup = !UserDefaults.standard.bool(forKey: "setupSeen")
        library.progress = { [weak self] message in DispatchQueue.main.async { self?.status = message } }
    }
    var selected: Savegame? { saves.first { $0.id == selection } }
    var filtered: [Savegame] { saves.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.world.contains(query) || (worldNames[$0.world]?.localizedCaseInsensitiveContains(query) ?? false) } }
    var saveGroups: [SavegameWorldGroup] { SavegameWorldGroup.make(filtered) }
    func worldTitle(_ id: String, english: Bool) -> String { worldNames[id] ?? ((english ? "World " : "Welt ") + id) }
    private var annotationPromptScheduled = false
    func reload() {
        do {
            saves = try library.entries()
            worldNames = Dictionary(uniqueKeysWithValues: SavegameWorldGroup.make(saves).compactMap { group in
                guard let name = group.saves.lazy.compactMap({ self.library.worldDisplayName($0) }).first else { return nil }
                return (group.id, name)
            })
        } catch { self.error = error.localizedDescription }
        if !saves.contains(where: { $0.id == selection }) { selection = saves.first?.id }
        offerAnnotationImport()
    }
    private func offerAnnotationImport() {
        guard !annotationPromptScheduled else { return }
        let defaults = UserDefaults.standard
        guard let target = saves.first(where: { defaults.string(forKey: "annotations.pending." + $0.id) != nil }) else { return }
        annotationPromptScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            defer { self.annotationPromptScheduled = false; self.offerAnnotationImport() }
            let key = "annotations.pending." + target.id
            guard let sourceID = defaults.string(forKey: key), let source = self.saves.first(where: { $0.id == sourceID }) else { defaults.removeObject(forKey: key); return }
            let en = defaults.string(forKey: "appLanguage") == "en"
            let alert = NSAlert()
            alert.messageText = en ? "Import places and ownership?" : "Orte und Besitz übernehmen?"
            alert.informativeText = en ? "‘\(target.title)’ has the same world ID (\(target.world)) as ‘\(source.title)’ from \(source.date.formatted()). It is probably another backup of the same world. Copy your places, custom names, chest ownership and visibility settings? The original backup stays unchanged. The same world ID does not guarantee the same playthrough." : "„\(target.title)“ hat dieselbe Welt-ID (\(target.world)) wie „\(source.title)“ vom \(source.date.formatted()). Vermutlich ist dies ein weiterer Stand derselben Welt. Eigene Orte, Ortsnamen, Kistenbesitz und Sichtbarkeit kopieren? Die ursprüngliche Sicherung bleibt unverändert. Dieselbe Welt-ID garantiert nicht denselben Spielverlauf."
            alert.addButton(withTitle: en ? "Import" : "Übernehmen")
            alert.addButton(withTitle: en ? "Don't import" : "Nicht übernehmen")
            if alert.runModal() == .alertFirstButtonReturn {
                AnnotationTransfer.copy(from: source.annotationScope, to: target.annotationScope, defaults: defaults)
            }
            defaults.removeObject(forKey: key)
            self.objectWillChange.send()
        }
    }
    func work(_ message: String, lockLibrary: Bool = true, action: @escaping () throws -> String) {
        guard !busy else { return }
        busy = true; status = message
        history.append("\(Date().formatted()) · \(message)")
        let backend = library
        queue.async {
            let result = Result { if lockLibrary { return try backend.withExclusiveOperation { try action() } }; return try action() }
            DispatchQueue.main.async {
                self.busy = false; self.reload()
                switch result {
                case .success(let text): self.status = text
                case .failure(let error): self.status = "Aktion nicht abgeschlossen."; self.error = error.localizedDescription; self.history.append(error.localizedDescription)
                }
                self.history.append("\(Date().formatted()) · \(self.status)")
                self.connect()
            }
        }
    }
    private var lastConnectionCheck = Date.distantPast
    func connect(force: Bool = true) {
        guard !busy && !scanning else { return }
        guard force || Date().timeIntervalSince(lastConnectionCheck) >= 8 else { return }
        lastConnectionCheck = Date()
        scanning = true
        let requestedSerial = serial
        let preferred = serial.isEmpty ? (UserDefaults.standard.string(forKey: "lastDevice") ?? "") : serial
        let backend = library
        queue.async {
            let report = backend.setupReport(preferred: preferred)
            DispatchQueue.main.async {
                self.scanning = false
                // Discard results for a device the user has switched away from.
                guard self.serial == requestedSerial else { self.connect(); return }
                let showingConnection = self.status.hasPrefix("Quest per") || self.status == self.setup.message
                self.setup = report; self.devices = report.devices; self.serial = report.serial
                self.worlds = report.worlds
                let remembered = self.world.isEmpty ? (UserDefaults.standard.string(forKey: "lastWorld") ?? "") : self.world
                self.world = report.worlds.contains(remembered) ? remembered : report.worlds.first ?? ""
                if showingConnection { self.status = report.message }
            }
        }
    }
    func selectDevice(_ selected: String) {
        guard serial != selected else { return }
        serial = selected
        worlds = []; world = ""; setup.package = ""
        status = "Quest per USB verbinden und RealmCraft beenden."
        connect()
    }
    func backup() {
        let serial = serial, world = world
        work("Sicherung vorbereiten …") {
            let save = try self.library.backup(serial, world: world)
            DispatchQueue.main.async { self.selection = save.id }
            return "Gesichert und geprüft · \(displayCount(save.count)) Dateien."
        }
    }
    func restore(_ save: Savegame) {
        let serial = serial
        work("Wiederherstellung vorbereiten …") {
            try self.library.restore(save, serial: serial)
            return "Wiederhergestellt und geprüft. Du kannst RealmCraft jetzt starten."
        }
    }
    func deleteConfirmed(_ request: SavegameDeletion) {
        let backend = library, english = UserDefaults.standard.string(forKey: "appLanguage") == "en"
        work(english ? "Moving savegame to Trash…" : "Spielstand wird in den Papierkorb verschoben …") {
            try backend.trashSave(request.save, expectedRoot: request.root)
            return english ? "Moved to Trash: \(request.save.title)" : "In den Papierkorb verschoben: \(request.save.title)"
        }
    }
    func importPanel() {
        let panel = NSOpenPanel()
        panel.title = tr("RealmCraft-Savegame importieren")
        panel.message = tr("Wähle einen Weltordner (z. B. 1234567890) oder eine ZIP-Datei.")
        panel.canChooseDirectories = true; panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = library.root
        guard panel.runModal() == .OK, let url = panel.url else { return }
        work("Savegame importieren …") {
            let save = try self.library.importSave(url)
            DispatchQueue.main.async { self.selection = save.id }
            return "Importiert · \(displayCount(save.count)) Dateien geprüft."
        }
    }
    func exportPanel(_ save: Savegame) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        panel.nameFieldStringValue = "RealmCraft-\(formatter.string(from: save.date))-\(save.world).zip"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        work("ZIP exportieren …") {
            try self.library.export(save, to: url)
            return "ZIP exportiert: \(url.lastPathComponent)"
        }
    }
    func exportLibraryPanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        panel.nameFieldStringValue = "RealmCraft-Library-Backup-\(formatter.string(from: Date())).zip"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        work("Library-ZIP exportieren …") {
            try self.library.exportLibraryArchive(to: url)
            return "Library-ZIP exportiert: \(url.lastPathComponent)"
        }
    }
    func chooseCloudBackupFolder() {
        let panel = NSOpenPanel()
        panel.title = UserDefaults.standard.string(forKey: "appLanguage") == "en" ? "Choose cloud backup folder" : "Cloud-Backup-Ordner wählen"
        panel.message = UserDefaults.standard.string(forKey: "appLanguage") == "en" ? "Choose an iCloud Drive folder, external sync folder or local folder for automatic library ZIP backups." : "Wähle einen iCloud-Drive-Ordner, Sync-Ordner oder lokalen Ordner für automatische Library-ZIP-Backups."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        if let path = UserDefaults.standard.string(forKey: "cloudBackupFolder") {
            panel.directoryURL = URL(fileURLWithPath: path)
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        UserDefaults.standard.set(url.path, forKey: "cloudBackupFolder")
        status = UserDefaults.standard.string(forKey: "appLanguage") == "en" ? "Cloud backup folder set: \(url.lastPathComponent)" : "Cloud-Backup-Ordner gesetzt: \(url.lastPathComponent)"
    }
    func exportLibraryToCloudFolder() {
        guard let path = UserDefaults.standard.string(forKey: "cloudBackupFolder"), !path.isEmpty else {
            chooseCloudBackupFolder()
            return
        }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let target = folder.appendingPathComponent("RealmCraft-Library-Backup-\(formatter.string(from: Date())).zip")
        work("Cloud-Backup-ZIP exportieren …") {
            var isDirectory: ObjCBool = false
            guard self.library.fm.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                throw LibraryError("Cloud backup folder is not available / Cloud-Backup-Ordner ist nicht verfügbar.")
            }
            try self.library.exportLibraryArchive(to: target)
            return "Cloud-Backup-ZIP exportiert: \(target.lastPathComponent)"
        }
    }
    func compactLibrary(backupFirst: Bool = false) {
        var backupURL: URL?
        if backupFirst {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.zip]
            let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            panel.nameFieldStringValue = "RealmCraft-Library-Before-Optimize-\(formatter.string(from: Date())).zip"
            if let path = UserDefaults.standard.string(forKey: "cloudBackupFolder") {
                panel.directoryURL = URL(fileURLWithPath: path, isDirectory: true)
            }
            guard panel.runModal() == .OK, let url = panel.url else { return }
            backupURL = url
        }
        work("Speicher optimieren …") {
            if let backupURL {
                try self.library.exportLibraryArchive(to: backupURL)
            }
            return try self.library.compactLibrary()
        }
    }
}

struct MainView: View {
    @Environment(\.companionTheme) private var theme
    @ObservedObject var model: Model
    var onMap: (() -> Void)? = nil
    @AppStorage("appLanguage") private var language = "en"
    @Environment(\.openWindow) private var openWindow
    @State private var restoreCandidate: Savegame?
    @State private var deletion: SavegameDeletion?
    @State private var editTitle = ""
    @State private var renaming = false
    @State private var confirmingStop = false
    @State private var confirmingOptimize = false
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: "Savegames") {
                Button { model.backup() } label: { Label(language == "en" ? "Backup from device" : "Vom Gerät sichern", systemImage: "arrow.down.to.line") }
                    .buttonStyle(CompanionButtonStyle(prominent: true)).disabled(model.scanning || model.serial.isEmpty || model.world.isEmpty || model.setup.package.isEmpty)
            } menu: {
                Group {
                    Button(language == "en" ? "Import savegame…" : "Spielstand importieren …") { model.importPanel() }
                    if let save = model.selected {
                        Button(language == "en" ? "Restore to Quest…" : "Auf Quest wiederherstellen …") { restoreCandidate = save }
                            .disabled(model.scanning || model.serial.isEmpty || model.setup.package.isEmpty)
                        Button(language == "en" ? "Export ZIP…" : "ZIP exportieren …") { model.exportPanel(save) }
                        Button(language == "en" ? "Rename…" : "Umbenennen …") { editTitle = save.title; renaming = true }
                        if let onMap { Button(language == "en" ? "Open world map" : "Weltkarte öffnen", action: onMap) }
                        Button(language == "en" ? "Show in Finder" : "Im Finder anzeigen") { NSWorkspace.shared.activateFileViewerSelecting([model.library.worldFolder(save)]) }
                        Divider()
                        Button(language == "en" ? "Delete savegame…" : "Savegame löschen …", role: .destructive) { requestDeletion(save) }
                    }
                    Divider()
                    Menu(language == "en" ? "Device & world" : "Gerät & Welt") {
                        Picker(language == "en" ? "Device" : "Gerät", selection: Binding(get: { model.serial }, set: { model.selectDevice($0) })) {
                            ForEach(model.devices) { Text($0.name).tag($0.id) }
                        }
                        Picker(language == "en" ? "World" : "Welt", selection: $model.world) { ForEach(model.worlds, id: \.self) { Text($0).tag($0) } }
                        Button(language == "en" ? "Check connection" : "Verbindung prüfen") { model.connect() }
                        Button(language == "en" ? "Close RealmCraft on Quest…" : "RealmCraft auf Quest beenden …") { confirmingStop = true }
                            .disabled(model.scanning || model.serial.isEmpty || model.setup.package.isEmpty)
                    }
                    Button(language == "en" ? "Refresh library" : "Bibliothek aktualisieren") { model.reload() }
                    Button(language == "en" ? "Optimize storage…" : "Speicher optimieren …") { confirmingOptimize = true }
                    Button(language == "en" ? "Export library backup ZIP…" : "Library-Backup-ZIP exportieren …") { model.exportLibraryPanel() }
                    Button(language == "en" ? "Set cloud backup folder…" : "Cloud-Backup-Ordner festlegen …") { model.chooseCloudBackupFolder() }
                    Button(language == "en" ? "Back up library to cloud folder" : "Library in Cloud-Ordner sichern") { model.exportLibraryToCloudFolder() }
                    Button(language == "en" ? "Open library folder" : "Bibliotheksordner öffnen") { NSWorkspace.shared.open(model.library.root) }
                }
            }
            HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Spielstände suchen", text: $model.query).textFieldStyle(.roundedBorder).padding(.horizontal, 16).frame(height: 64)
                List(selection: $model.selection) {
                    ForEach(model.saveGroups) { group in
                        Section {
                            ForEach(group.saves) { save in
                                saveRow(save).tag(save.id)
                                    .contextMenu { Button(language == "en" ? "Delete savegame…" : "Savegame löschen …", role: .destructive) { requestDeletion(save) } }
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 4) {
                                Label(model.worldTitle(group.id, english: language == "en"), systemImage: "globe.europe.africa.fill").font(.headline).foregroundStyle(theme.accent)
                                Text("ID \(group.id) · \(group.saves.count) " + (language == "en" ? "savegames" : "Spielstände")).font(.caption2).foregroundStyle(.secondary)
                            }.textCase(nil).padding(.top, 12).padding(.bottom, 6)
                        }
                    }
                }.listStyle(.sidebar).scrollContentBackground(.hidden).id(language)
                HStack {
                    Text(model.saves.count == 1 ? tr("1 Spielstand") : "\(model.saves.count) " + tr("Spielstände")).foregroundStyle(.secondary)
                    Spacer()
                }.font(.caption).padding(14)
            }.frame(width: CompanionTheme.sidebarWidth).background(theme.surface)
            Divider()
            VStack(spacing: 0) {
                if let save = model.selected {
                    saveDetail(save)
                } else {
                    VStack(spacing: 18) {
                        Image(systemName: "archivebox.fill").font(.system(size: 54)).foregroundStyle(theme.accent)
                        Text("Platz für deine Welten").font(.title.bold())
                        Text("Sichere deine Quest-Welt oder importiere einen vorhandenen Spielstand.")
                            .foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Savegame importieren …") { model.importPanel() }.controlSize(.large)
                    }.padding(40).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Divider()
                HStack(spacing: 12) {
                    if model.busy { ProgressView().controlSize(.small) }
                    else { Image(systemName: "info.circle").foregroundStyle(theme.accent) }
                    Text(tr(model.status)).font(.callout).lineLimit(2).help(tr(model.status)).textSelection(.enabled)
                    Spacer()
                }.padding(.horizontal, CompanionLayout.pageInset).frame(height: 54).background(theme.surface)
            }
            }
        }
        .disabled(model.busy)
        .onChange(of: model.serial) { _, _ in restoreCandidate = nil; confirmingStop = false; confirmingOptimize = false }
        .alert(language == "en" ? "Optimize savegame storage?" : "Savegame-Speicher optimieren?", isPresented: $confirmingOptimize) {
            Button(language == "en" ? "Cancel" : "Abbrechen", role: .cancel) {}
            Button(language == "en" ? "Create backup & optimize…" : "Backup erstellen & optimieren …") { model.compactLibrary(backupFirst: true) }
            Button(language == "en" ? "Optimize without backup" : "Ohne Backup optimieren", role: .destructive) { model.compactLibrary() }
        } message: {
            Text(language == "en" ? "The library will be verified and identical savegame files will be replaced with shared storage links. Existing backups should stay readable, but creating a ZIP first gives you an independent restore point." : "Die Library wird geprüft und identische Savegame-Dateien werden durch gemeinsame Speicherlinks ersetzt. Bestehende Backups sollten lesbar bleiben; ein ZIP vorher gibt dir aber einen unabhängigen Rückfallstand.")
        }
        .alert(language == "en" ? "Really delete this savegame?" : "Dieses Savegame wirklich löschen?", isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } })) {
            Button(language == "en" ? "Cancel" : "Abbrechen", role: .cancel) { deletion = nil }
            Button(language == "en" ? "Move to Trash" : "In den Papierkorb", role: .destructive) {
                if let request = deletion { model.deleteConfirmed(request) }; deletion = nil
            }
        } message: {
            if let request = deletion {
                Text("\(request.save.title)\n\(model.worldTitle(request.save.world, english: language == "en")) · ID \(request.save.world)\n\(displayDate(request.save.date, language: language)) · \(displayBytes(request.save.bytes))\n\n" + (language == "en" ? "This local backup will be moved to the Mac Trash. Other backups and the world on Quest are kept. You can recover it from the Trash." : "Diese lokale Sicherung wird in den Mac-Papierkorb verschoben. Andere Sicherungen und die Welt auf der Quest bleiben erhalten. Du kannst sie aus dem Papierkorb wiederherstellen."))
            }
        }
        .alert("Spielstand auf Quest wiederherstellen?", isPresented: Binding(get: { restoreCandidate != nil }, set: { if !$0 { restoreCandidate = nil } })) {
            Button("Abbrechen", role: .cancel) { restoreCandidate = nil }
            Button("Sichern & wiederherstellen", role: .destructive) {
                if let save = restoreCandidate { model.restore(save) }; restoreCandidate = nil
            }
        } message: {
            if let save = restoreCandidate {
                Text(restoreMessage(save, device: model.devices.first(where: { $0.id == model.serial })?.name ?? "Quest"))
            }
        }
        .alert("RealmCraft sofort beenden?", isPresented: $confirmingStop) {
            Button("Abbrechen", role: .cancel) {}
            Button("Spiel beenden", role: .destructive) {
                let serial = model.serial
                model.work("RealmCraft auf der Quest beenden …") {
                    try model.library.stopGame(serial)
                    return "RealmCraft ist beendet. Du kannst jetzt sichern oder wiederherstellen."
                }
            }
        } message: {
            Text("Bitte zuerst im Spiel speichern. ADB beendet RealmCraft sofort; ungespeicherter Fortschritt kann verloren gehen.")
        }
        .alert("Spielstand umbenennen", isPresented: $renaming) {
            TextField("Name", text: $editTitle)
            Button("Abbrechen", role: .cancel) {}
            Button("Speichern") {
                if let save = model.selected {
                    do { try model.library.rename(save, title: editTitle); model.reload() }
                    catch { model.error = error.localizedDescription }
                }
            }
        }
        .alert("Aktion nicht abgeschlossen", isPresented: Binding(get: { model.error != nil && !model.showSetup }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(tr(model.error ?? "")) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.locale, Locale(identifier: language))
    }
    private func requestDeletion(_ save: Savegame) {
        deletion = SavegameDeletion(save: save, root: model.library.root)
    }
    private func saveRow(_ save: Savegame) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(save.title).font(.headline).lineLimit(2)
            Text(displayDate(save.date, language: language)).font(.caption).foregroundStyle(.secondary)
            HStack {
                Image(systemName: save.source == "Automatische Sicherung" ? "shield.lefthalf.filled" : "archivebox")
                Text(displayBytes(save.bytes))
                Spacer()
                Text(save.source.hasPrefix("Editor") ? "Editor · Beta" : save.source == "Automatische Sicherung" ? "Auto" : save.source == "Import" ? "Import" : "Quest")
            }.font(.caption2).foregroundStyle(.secondary)
        }.padding(.vertical, 7)
    }
    private func saveDetail(_ save: Savegame) -> some View {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(save.title).font(.system(size: 24, weight: .bold)).textSelection(.enabled)
                                    Text(displayDate(save.date)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button { requestDeletion(save) } label: { Image(systemName: "trash") }
                                    .help(language == "en" ? "Delete this local savegame…" : "Dieses lokale Savegame löschen …")
                                    .accessibilityLabel(language == "en" ? "Delete savegame" : "Savegame löschen")
                            }
                            Label(model.worldTitle(save.world, english: language == "en"), systemImage: "globe.europe.africa.fill").font(.headline).foregroundStyle(theme.accent)
                            if let preview = NSImage(contentsOf: model.library.worldFolder(save).appendingPathComponent("screenshot.jpg")) {
                                Image(nsImage: preview).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 190)
                                    .background(Color.black.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: theme.radius))
                            }
                            HStack(spacing: 14) {
                                info("Welt", save.world, icon: "globe.europe.africa")
                                info("Dateien", displayCount(save.count), icon: "doc.on.doc")
                                info("Größe", displayBytes(save.bytes), icon: "externaldrive")
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Mit SHA-256-Prüfsummen gespeichert", systemImage: "checkmark.shield.fill").foregroundStyle(theme.accent)
                                SavegameStatusView(model: model, save: save)
                                Text("Letzte Dateiänderung: \(displayDate(save.gameDate))")
                                    .foregroundStyle(.secondary)
                                Text("Herkunft: \(tr(save.source))").foregroundStyle(.secondary)
                            }.font(.callout)

                        }.padding(CompanionLayout.pageInset).frame(maxWidth: .infinity, alignment: .leading)
                    }
    }
    func info(_ title: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(tr(title), systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.headline, design: .rounded)).textSelection(.enabled)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    var model: Model?
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if CompanionLifecycle.shared.isWorking && !CompanionLifecycle.shared.allowsTermination { return .terminateCancel }
        if model?.busy == true {
            let alert = NSAlert(); alert.messageText = tr("Übertragung läuft")
            alert.informativeText = tr("Bitte warte, bis die Sicherung oder Wiederherstellung abgeschlossen ist.")
            alert.runModal(); return .terminateCancel
        }
        return .terminateNow
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { model?.busy != true }
}
struct RealmApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var model = Model()
    @AppStorage("appLanguage") private var language = "en"
    var body: some Scene {
        WindowGroup("RealmCraft Companion") {
            CompanionView(model: model).companionAppearance().background(WindowFramePersistence(name: "RealmCraftLibrary.Main")).onAppear { delegate.model = model }
        }.defaultSize(width: 1200, height: 820)
        .commands { CommandGroup(replacing: .newItem) {}; HelpCommands(); CompanionNavigationCommands(model: model) }
        Window(language == "en" ? "RealmCraft · Help" : "RealmCraft · Hilfe", id: "help") { HelpView().companionAppearance().background(WindowFramePersistence(name: "RealmCraftLibrary.Help", title: language == "en" ? "RealmCraft · Help" : "RealmCraft · Hilfe")) }
            .defaultSize(width: 900, height: 780)
    }
}

UserDefaults.standard.register(defaults: ["appLanguage": "en"])

if CommandLine.arguments.dropFirst().first == "--companion-relaunch" {
    exit(MainActor.assumeIsolated { CompanionLifecycle.runRelaunchHelper(arguments: CommandLine.arguments) })
}

// CLI entry points exercise the exact same transfer engine as the GUI.
if CommandLine.arguments.dropFirst().first?.hasPrefix("--") == true {
    do {
        let args = CommandLine.arguments
        let env = ProcessInfo.processInfo.environment
        let lib = try Library(root: env["REALMCRAFT_LIBRARY"].map { URL(fileURLWithPath: $0) }, adb: env["REALMCRAFT_ADB"])
        lib.progress = { print($0) }
        switch args[1] {
        case "--import":
            guard args.count == 3 else { throw LibraryError("--import PATH") }
            let save = try lib.importSave(URL(fileURLWithPath: args[2])); print("IMPORTED \(save.id)")
        case "--setup":
            let r = lib.setupReport(preferred: ""); print(r.adbVersion); print(r.message); print(r.package); print(r.worlds)
        case "--install-adb": print(try lib.installADB())
        case "--list":
            for save in try lib.entries() { print("\(save.id) | \(save.date) | \(save.title) | \(save.count)") }
        case "--verify":
            for save in try lib.entries() { _ = try lib.verify(save); print("VERIFIED \(save.id)") }
        case "--backup":
            guard args.count == 4 else { throw LibraryError("--backup SERIAL WORLD") }
            let save = try lib.backup(args[2], world: args[3]); print("BACKED_UP \(save.id)")
        case "--restore":
            guard args.count == 4, let save = try lib.entries().first(where: { $0.id == args[3] }) else { throw LibraryError("--restore SERIAL SAVE_ID") }
            try lib.restore(save, serial: args[2]); print("RESTORED")
        case "--export":
            guard args.count == 4, let save = try lib.entries().first(where: { $0.id == args[2] }) else { throw LibraryError("--export SAVE_ID ZIP_PATH") }
            try lib.export(save, to: URL(fileURLWithPath: args[3])); print("EXPORTED")
        case "--export-library":
            guard args.count == 3 else { throw LibraryError("--export-library ZIP_PATH") }
            try lib.exportLibraryArchive(to: URL(fileURLWithPath: args[2])); print("EXPORTED_LIBRARY")
        case "--compact":
            print(try lib.compactLibrary())
        default: throw LibraryError("Unbekanntes Argument")
        }
    } catch { fputs("\(error.localizedDescription)\n", stderr); exit(1) }
} else {
    RealmApp.main()
}
