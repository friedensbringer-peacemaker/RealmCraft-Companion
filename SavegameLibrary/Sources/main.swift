import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor final class Model: ObservableObject {
    @Published var saves: [Savegame] = []
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
    var filtered: [Savegame] { saves.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.world.contains(query) } }
    func reload() {
        do { saves = try library.entries() } catch { self.error = error.localizedDescription }
        if !saves.contains(where: { $0.id == selection }) { selection = saves.first?.id }
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
    func connect() {
        guard !busy && !scanning else { return }
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
}

struct MainView: View {
    @ObservedObject var model: Model
    var onMap: (() -> Void)? = nil
    @AppStorage("appLanguage") private var language = "en"
    @Environment(\.openWindow) private var openWindow
    @State private var restoreCandidate: Savegame?
    @State private var editTitle = ""
    @State private var renaming = false
    @State private var confirmingStop = false
    private let poll = Timer.publish(every: 8, on: .main, in: .common).autoconnect()
    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "cube.transparent.fill").font(.system(size: 29)).foregroundStyle(.teal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("REALMCRAFT").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(2)
                        Text("Savegame Library").font(.headline)
                    }
                }.padding(20)
                TextField("Spielstände suchen", text: $model.query).textFieldStyle(.roundedBorder).padding(.horizontal, 14).padding(.bottom, 10)
                List(selection: $model.selection) {
                    ForEach(model.filtered) { save in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(save.title).font(.headline).lineLimit(2)
                            Text(displayDate(save.date))
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: save.source == "Automatische Sicherung" ? "shield.lefthalf.filled" : "archivebox")
                                Text(displayBytes(save.bytes))
                                Spacer()
                                Text(save.source == "Automatische Sicherung" ? "Auto" : save.source == "Import" ? "Import" : "Quest")
                            }.font(.caption2).foregroundStyle(.secondary)
                        }.padding(.vertical, 7).tag(save.id)
                    }
                }.listStyle(.sidebar).id(language)
                HStack {
                    Text(model.saves.count == 1 ? tr("1 Spielstand") : "\(model.saves.count) " + tr("Spielstände")).foregroundStyle(.secondary)
                    Spacer()
                    Button { NSWorkspace.shared.open(model.library.root) } label: { Image(systemName: "folder") }
                        .help("Library im Finder öffnen")
                }.font(.caption).padding(14)
            }.navigationSplitViewColumnWidth(min: 245, ideal: 285, max: 370)
        } detail: {
            VStack(spacing: 0) {
                deviceBar
                Divider()
                if let save = model.selected {
                    saveDetail(save)
                } else {
                    VStack(spacing: 18) {
                        Image(systemName: "archivebox.fill").font(.system(size: 54)).foregroundStyle(.teal)
                        Text("Platz für deine Welten").font(.title.bold())
                        Text("Sichere deine Quest-Welt oder importiere einen vorhandenen Spielstand.")
                            .foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Savegame importieren …") { model.importPanel() }.controlSize(.large)
                    }.padding(40).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Divider()
                HStack(spacing: 12) {
                    if model.busy { ProgressView().controlSize(.small) }
                    else { Image(systemName: "info.circle").foregroundStyle(.teal) }
                    Text(tr(model.status)).font(.callout).textSelection(.enabled)
                    Spacer()
                }.padding(16).frame(minHeight: 54).background(.bar)
            }
        }
        .disabled(model.busy)
        .onChange(of: model.serial) { _, _ in restoreCandidate = nil; confirmingStop = false }
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
        .frame(minWidth: 940, minHeight: 700)
        .environment(\.locale, Locale(identifier: language))
    }
    private func saveDetail(_ save: Savegame) -> some View {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("DEINE SPIELSTÄNDE").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.teal)
                                    Text(save.title).font(.system(size: 29, weight: .bold, design: .rounded)).textSelection(.enabled)
                                    Text(displayDate(save.date)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button { editTitle = save.title; renaming = true } label: { Image(systemName: "pencil") }.help("Spielstand umbenennen")
                            }
                            HStack(spacing: 12) {
                                Button { restoreCandidate = save } label: { Label("Auf Quest wiederherstellen", systemImage: "arrow.up.to.line") }
                                    .buttonStyle(.borderedProminent).tint(.teal).disabled(model.scanning || model.serial.isEmpty || model.setup.package.isEmpty)
                                Button { model.exportPanel(save) } label: { Label("Als ZIP exportieren", systemImage: "doc.zipper") }
                                Button { NSWorkspace.shared.activateFileViewerSelecting([model.library.worldFolder(save)]) } label: { Image(systemName: "folder") }
                                    .help("Spielstand im Finder anzeigen")
                            }.controlSize(.large)
                            if let onMap {
                                Button(action: onMap) { Label(language == "en" ? "Create / view world map" : "Weltkarte erzeugen / ansehen", systemImage: "map") }
                            }
                            Text("Vor dem Wiederherstellen wird die aktuelle Quest-Welt automatisch in der Library gesichert.")
                                .font(.caption).foregroundStyle(.secondary)
                            if let preview = NSImage(contentsOf: model.library.worldFolder(save).appendingPathComponent("screenshot.jpg")) {
                                Image(nsImage: preview).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 190)
                                    .background(Color.black.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            HStack(spacing: 14) {
                                info("Welt", save.world, icon: "globe.europe.africa")
                                info("Dateien", displayCount(save.count), icon: "doc.on.doc")
                                info("Größe", displayBytes(save.bytes), icon: "externaldrive")
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Mit SHA-256-Prüfsummen gespeichert", systemImage: "checkmark.shield.fill").foregroundStyle(.teal)
                                Text("Letzte Dateiänderung: \(displayDate(save.gameDate))")
                                    .foregroundStyle(.secondary)
                                Text("Herkunft: \(tr(save.source))").foregroundStyle(.secondary)
                            }.font(.callout)

                        }.padding(24).frame(maxWidth: 900, alignment: .leading).frame(maxWidth: .infinity)
                    }
    }
    var deviceBar: some View {
        HStack(spacing: 14) {
            Image(systemName: "visionpro").font(.title2).foregroundStyle(.teal)
            if model.devices.isEmpty {
                VStack(alignment: .leading) { Text("Quest verbinden").font(.headline); Text(tr(model.setup.adbVersion == "Nicht installiert" ? "ADB in Einrichtung installieren" : "USB · Debugging erlauben")).font(.caption).foregroundStyle(.secondary) }
            } else {
                Picker("Gerät", selection: Binding(get: { model.serial }, set: { model.selectDevice($0) })) {
                    ForEach(model.devices) { device in Text(device.name).tag(device.id) }
                }.labelsHidden().frame(maxWidth: 150)
                Picker("Welt", selection: $model.world) {
                    if model.worlds.isEmpty { Text("Keine Welt").tag("") }
                    ForEach(model.worlds, id: \.self) { Text($0).tag($0) }
                }.frame(maxWidth: 200)
            }
            Spacer()
            Button { model.connect() } label: { Image(systemName: "arrow.triangle.2.circlepath") }.help("Quest-Verbindung prüfen")
            Button { confirmingStop = true } label: { Image(systemName: "stop.circle") }
                .help("RealmCraft auf der Quest beenden").disabled(model.scanning || model.serial.isEmpty || model.setup.package.isEmpty)
            Button { model.backup() } label: { Label("Quest → Mac sichern", systemImage: "arrow.down.to.line") }
                .buttonStyle(.borderedProminent).disabled(model.scanning || model.serial.isEmpty || model.world.isEmpty || model.setup.package.isEmpty)
        }.padding(18)
    }
    func info(_ title: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(tr(title), systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.headline, design: .rounded)).textSelection(.enabled)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    var model: Model?
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
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
            CompanionView(model: model).background(WindowFramePersistence(name: "RealmCraftLibrary.Main")).onAppear { delegate.model = model }
        }.defaultSize(width: 1120, height: 880)
        .commands { CommandGroup(replacing: .newItem) {}; HelpCommands() }
        Window(language == "en" ? "RealmCraft · Help" : "RealmCraft · Hilfe", id: "help") { HelpView().background(WindowFramePersistence(name: "RealmCraftLibrary.Help", title: language == "en" ? "RealmCraft · Help" : "RealmCraft · Hilfe")) }
            .defaultSize(width: 900, height: 780)
    }
}

UserDefaults.standard.register(defaults: ["appLanguage": "en"])

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
        default: throw LibraryError("Unbekanntes Argument")
        }
    } catch { fputs("\(error.localizedDescription)\n", stderr); exit(1) }
} else {
    RealmApp.main()
}
