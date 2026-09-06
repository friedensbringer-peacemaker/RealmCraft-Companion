import SwiftUI
import AppKit

struct SetupView: View {
    @ObservedObject var model: Model
    @AppStorage("appLanguage") private var language = "en"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @State private var acceptTerms = false
    @State private var copyLibrary = true
    @State private var imports: [URL] = []
    @State private var importSelection: String?
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: "checklist").font(.largeTitle).foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Einrichtung & Speicher").font(.title2.bold())
                    Text("Alles für deine Verbindung zwischen Quest und Mac.").foregroundStyle(.secondary)
                }
                Spacer()
                Button { openWindow(id: "help") } label: { Image(systemName: "questionmark.circle") }.help("Hilfe / Help")
                Button("Fertig") { UserDefaults.standard.set(true, forKey: "setupSeen"); dismiss() }.keyboardShortcut(.defaultAction)
            }.padding(24)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            statusRow("1. Android Debug Bridge", model.setup.adbVersion != "Nicht installiert", model.setup.adbVersion)
                            Text(model.library.adb).font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                            HStack {
                                Button("Vorhandenes ADB auswählen …") { chooseADB() }
                                Button("Erneut prüfen") { model.connect() }
                            }
                            Divider()
                            Text("ADB fehlt? Die App kann die offiziellen Android Platform Tools von Google herunterladen und im Benutzerordner installieren. Homebrew, Python und Xcode sind nicht erforderlich.").font(.callout)
                            Link("Google-Downloadseite und SDK-Lizenzbedingungen", destination: URL(string: "https://developer.android.com/tools/releases/platform-tools")!)
                            Toggle("Ich akzeptiere die Android-SDK-Lizenzbedingungen von Google.", isOn: $acceptTerms).font(.callout)
                            Button("ADB von Google installieren / aktualisieren") {
                                model.work("ADB-Installation vorbereiten …", lockLibrary: false) {
                                    _ = try model.library.installADB()
                                    return "ADB wurde installiert und erfolgreich geprüft."
                                }
                            }.buttonStyle(.borderedProminent).disabled(!acceptTerms)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
                    }
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            statusRow("2. Quest & RealmCraft", !model.setup.package.isEmpty, model.setup.message)
                            if !model.setup.package.isEmpty {
                                Text("Spiel: \(model.setup.package)\nWelten: \(model.setup.worlds.joined(separator: ", "))")
                                    .font(.caption.monospaced()).textSelection(.enabled)
                            }
                            Text("Quest per USB-Datenkabel anschließen und aufwecken. In der Meta-Horizon-App den Entwicklermodus für das Headset aktivieren. Die USB-Debugging-Abfrage im Headset erlauben. RealmCraft mindestens einmal starten, eine Welt speichern und das Spiel vor Übertragungen beenden.").font(.callout).foregroundStyle(.secondary)
                            Link("Meta: Entwicklermodus einrichten", destination: URL(string: "https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/")!)
                            Text("Gerät, Spiel und vollständige Welten werden beim Start und alle acht Sekunden automatisch gesucht.").font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
                    }
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("3. Deine Savegame-Library", systemImage: "externaldrive.fill").font(.headline)
                            Text(model.library.root.path).font(.caption.monospaced()).textSelection(.enabled)
                            Toggle("Vorhandene Spielstände in den neuen Ordner mitkopieren", isOn: $copyLibrary)
                            Text("Wähle eine vorhandene Library oder einen neuen Speicherordner. Kopien werden geprüft; der bisherige Ordner bleibt als Sicherung erhalten.").font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Button("Speicherordner ändern …") { chooseRoot() }
                                Button("Im Finder öffnen") { NSWorkspace.shared.open(model.library.root) }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
                    }
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Vorhandene Backups finden", systemImage: "magnifyingglass").font(.headline)
                            Text("Wähle einen Backup-Ordner. Darin werden ZIPs und Weltordner automatisch erkannt.").font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Button("Backups auf dem Mac suchen") { findImports() }
                                Button("Datei oder Ordner auswählen …") { model.importPanel() }
                            }
                            if !imports.isEmpty {
                                Picker("Gefunden", selection: $importSelection) {
                                    Text("Backup auswählen").tag(nil as String?)
                                    ForEach(imports, id: \.path) { url in Text(url.lastPathComponent).tag(Optional(url.path)) }
                                }
                                Button("Ausgewähltes Backup importieren") {
                                    if let path = importSelection {
                                        model.work("Gefundenes Backup importieren …") {
                                            let save = try model.library.importSave(URL(fileURLWithPath: path))
                                            DispatchQueue.main.async { model.selection = save.id }
                                            return "Backup importiert und geprüft."
                                        }
                                    }
                                }.disabled(importSelection == nil)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
                    }
                    HStack {
                        Text("RealmCraft Companion · 1.1.0\nCommunity-App · nicht mit Meta oder Tellurion Mobile verbunden.").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("Diagnose kopieren") {
                            let text = "RealmCraft Companion 1.1.0\nmacOS: \(ProcessInfo.processInfo.operatingSystemVersionString)\nADB: \(model.setup.adbVersion)\n\(model.setup.message)\n" + model.history.suffix(20).joined(separator: "\n")
                            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string)
                        }
                    }
                }.padding(24)
            }
            if model.busy {
                Divider()
                HStack { ProgressView().controlSize(.small); Text(tr(model.status)); Spacer() }.padding(18)
            }
        }.frame(width: 730, height: 780).disabled(model.busy)
        .environment(\.locale, Locale(identifier: language))
        .alert("Aktion nicht abgeschlossen", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(tr(model.error ?? "")) }
    }
    func statusRow(_ title: String, _ ready: Bool, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: ready ? "checkmark.circle.fill" : "circle.dashed").foregroundStyle(ready ? .teal : .orange).font(.title3)
            VStack(alignment: .leading, spacing: 5) { Text(tr(title)).font(.headline); Text(tr(detail)).font(.callout).foregroundStyle(.secondary).textSelection(.enabled) }
        }
    }
    func chooseADB() {
        let panel = NSOpenPanel(); panel.title = tr("ADB auswählen"); panel.message = tr("Die ausführbare Datei adb aus dem platform-tools-Ordner auswählen.")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        model.work("ADB prüfen …", lockLibrary: false) { try model.library.chooseADB(url); return "ADB ausgewählt und geprüft." }
    }
    func chooseRoot() {
        let panel = NSOpenPanel(); panel.title = tr("Library-Speicherordner auswählen")
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let migrate = copyLibrary
        model.work("Library-Speicherort wechseln …", lockLibrary: migrate) {
            try model.library.changeRoot(url, migrate: migrate)
            DispatchQueue.main.async { model.selection = nil }
            return "Library-Speicherort aktualisiert."
        }
    }
    func findImports() {
        let panel = NSOpenPanel()
        panel.title = tr("Backup-Ordner auswählen")
        panel.canChooseDirectories = true; panel.canChooseFiles = false
        panel.directoryURL = model.library.root
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        importSelection = nil
        imports = []
        let fm = FileManager.default
        func isWorld(_ url: URL) -> Bool { fm.fileExists(atPath: url.appendingPathComponent("world_data").path) && fm.fileExists(atPath: url.appendingPathComponent("player_data").path) }
        let children = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        imports = children.flatMap { url -> [URL] in
            if url.pathExtension.lowercased() == "zip" || isWorld(url) { return [url] }
            return ((try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []).filter { $0.pathExtension.lowercased() == "zip" || isWorld($0) }
        }.sorted { $0.lastPathComponent > $1.lastPathComponent }
        if isWorld(folder) { imports.insert(folder, at: 0) }
        if imports.isEmpty { model.error = "Keine passenden ZIP-Backups gefunden. Über Importieren kannst du einen anderen Ordner oder eine Datei auswählen." }
    }
}
