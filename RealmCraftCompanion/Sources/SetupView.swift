import SwiftUI
import AppKit

struct SetupSettingsView: View {
    @Environment(\.companionTheme) private var theme
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @AppStorage("appLanguage") private var language = "en"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @State private var acceptTerms = false
    @State private var showADBDetails = false
    @State private var copyLibrary = true
    @State private var imports: [URL] = []
    @State private var importSelection: String?
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: "checklist").font(.largeTitle).foregroundStyle(theme.accent)
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
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            statusRow("1. Android Debug Bridge", model.setup.adbVersion != "Nicht installiert", model.setup.adbVersion)
                            DisclosureGroup(language == "en" ? "Manage ADB" : "ADB verwalten", isExpanded: $showADBDetails) {
                            Text(model.library.adb).font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                            HStack {
                                Button("Vorhandenes ADB auswählen …") { chooseADB() }
                                Button("Erneut prüfen") { model.connect() }
                            }
                            Divider()
                            Text("ADB fehlt? Die App kann die offiziellen Android Platform Tools von Google herunterladen und im Benutzerordner installieren. Homebrew, Python und Xcode sind nicht erforderlich.").font(.callout)
                            Link("Google-Downloadseite und SDK-Lizenzbedingungen", destination: URL(string: "https://developer.android.com/tools/releases/platform-tools")!).buttonStyle(.plain).foregroundStyle(theme.accent)
                            Toggle("Ich akzeptiere die Android-SDK-Lizenzbedingungen von Google.", isOn: $acceptTerms).font(.callout)
                            Button("ADB von Google installieren / aktualisieren") {
                                model.work("ADB-Installation vorbereiten …", lockLibrary: false) {
                                    _ = try model.library.installADB()
                                    return "ADB wurde installiert und erfolgreich geprüft."
                                }
                            }.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(!acceptTerms)
                            }
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
                            Link("Meta: Entwicklermodus einrichten", destination: URL(string: "https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/")!).buttonStyle(.plain).foregroundStyle(theme.accent)
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
                        MapToolsSetup(model: model, maps: maps, english: language == "en").padding(10)
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
                        Text("\(AppInfo.title)\nCommunity-App · nicht mit Meta oder Tellurion Mobile verbunden.").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("Diagnose kopieren") {
                            let text = "\(AppInfo.title)\nmacOS: \(ProcessInfo.processInfo.operatingSystemVersionString)\nADB: \(model.setup.adbVersion)\n\(model.setup.message)\n" + model.history.suffix(20).joined(separator: "\n")
                            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string)
                        }
                    }
                }.padding(24)
            }
            if model.busy {
                Divider()
                HStack { ProgressView().controlSize(.small); Text(tr(model.status)); Spacer() }.padding(18)
            }
        }.frame(width: 780, height: 660).disabled(model.busy)
        .environment(\.locale, Locale(identifier: language))
        .onAppear {
            showADBDetails = model.setup.adbVersion == "Nicht installiert"
            maps.check(model)
        }
        .alert("Aktion nicht abgeschlossen", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(tr(model.error ?? "")) }
    }
    func statusRow(_ title: String, _ ready: Bool, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: ready ? "checkmark.circle.fill" : "circle.dashed").foregroundStyle(ready ? theme.accent : .orange).font(.title3)
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

// The first-run sheet shares the same tested actions as the settings screen.
struct SetupView: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @AppStorage("appLanguage") private var language = "en"
    @AppStorage("setupGuideStep") private var savedStep = 0
    @AppStorage("setupSeen") private var setupSeen = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.companionTheme) private var theme
    @State private var settings = false
    @State private var acceptTerms = false
    private var english: Bool { language == "en" }
    private var step: Int { min(7, max(0, savedStep)) }
    private var adbReady: Bool { model.setup.adbVersion != "Nicht installiert" && !model.setup.adbVersion.isEmpty }
    private var connected: Bool { !model.setup.package.isEmpty && !model.setup.worlds.isEmpty }
    private func t(_ en: String, _ de: String) -> String { english ? en : de }
    private var titles: [String] { english
        ? ["Welcome", "Prepare your Mac", "Prepare your Meta account", "Enable developer mode", "Connect and allow access", "Check the game", "Choose your storage", "Ready for your first backup"]
        : ["Willkommen", "Mac vorbereiten", "Meta-Konto vorbereiten", "Entwicklermodus aktivieren", "Verbinden und Zugriff erlauben", "Spiel prüfen", "Speicher wählen", "Bereit für dein erstes Backup"] }
    var body: some View {
        if settings {
            VStack(spacing: 0) {
                HStack { Button(t("Back to step-by-step guide", "Zurück zur Schritt-für-Schritt-Anleitung")) { settings = false }; Spacer() }.padding(14)
                SetupSettingsView(model: model, maps: maps)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label(t("Let's set up your Companion", "Wir richten deinen Companion ein"), systemImage: "checklist").font(.title2.bold())
                    Spacer()
                    Picker("Language", selection: $language) { Text("Deutsch").tag("de"); Text("English").tag("en") }.pickerStyle(.segmented).labelsHidden().accessibilityLabel(t("Language", "Sprache")).frame(width: 180).fixedSize(horizontal: true, vertical: false)
                }.padding(24)
                ProgressView(value: Double(step + 1), total: 8).tint(theme.accent).padding(.horizontal, 24)
                Text(t("Step \(step + 1) of 8", "Schritt \(step + 1) von 8")).font(.caption).foregroundStyle(.secondary).padding(.horizontal, 24).padding(.top, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(titles[step]).font(.title.bold())
                        page
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
                }.id(step)
                Divider()
                if model.busy { HStack { ProgressView().controlSize(.small); Text(tr(model.status)).font(.callout) }.padding(12) }
                HStack {
                    Button(t("Later", "Später")) { setupSeen = true; dismiss() }.disabled(model.busy)
                    Button(t("All settings…", "Alle Einstellungen …")) { settings = true }.disabled(model.busy)
                    Spacer()
                    Button(t("Back", "Zurück")) { savedStep = step - 1 }.disabled(step == 0 || model.busy)
                    Button(step == 7 ? t("Open Companion", "Companion öffnen") : t("Next", "Weiter")) {
                        if step == 7 { setupSeen = true; dismiss() } else { savedStep = step + 1 }
                    }.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(model.busy)
                }.padding(20)
            }.frame(width: 780, height: 680)
            .onAppear { model.connect() }
            .alert(t("Action incomplete", "Aktion nicht abgeschlossen"), isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
                Button("OK") { model.error = nil }
            } message: { Text(tr(model.error ?? "")) }
        }
    }
    @ViewBuilder private var page: some View {
        switch step {
        case 0:
            instruction("macbook.and.iphone", t("You need your Mac, your Quest, a USB data cable, internet access for downloads and a phone with the Meta Horizon app paired to your headset.", "Du brauchst deinen Mac, deine Quest, ein USB-Datenkabel, Internet für Downloads und ein Smartphone mit der Meta-Horizon-App, das mit deiner Brille gekoppelt ist."))
            instruction("info.circle", t("This walkthrough was built using Meta Quest as the example. Other headsets, accounts and software versions may use different menus, permissions or save locations. Compatibility with other headsets is not guaranteed; follow their manufacturer's instructions.", "Diese Anleitung wurde am Beispiel der Meta Quest integriert. Bei anderen Brillen, Konten und Softwareversionen können Menüs, Freigaben und Speicherorte abweichen. Die Kompatibilität mit anderen Brillen ist nicht garantiert; nutze dafür die Anleitung des Herstellers."))
            Text(t("Nothing is transferred automatically. You can pause with Later and reopen this guide from Quest setup. Your step is remembered.", "Es wird nichts automatisch übertragen. Mit Später kannst du pausieren und die Anleitung über Quest einrichten wieder öffnen. Dein Schritt wird gespeichert."))
        case 1:
            instruction("desktopcomputer", t("On your Mac: keep Companion in Applications and start it there. ADB is the small connection tool that lets Companion communicate with the Quest over USB.", "Am Mac: Lege Companion unter Programme ab und starte ihn dort. ADB ist das kleine Verbindungswerkzeug, mit dem Companion über USB mit der Quest spricht."))
            status(adbReady, t("ADB detected", "ADB erkannt"), tr(model.setup.adbVersion))
            Text(t("If ADB is missing, read Google's terms, accept them below and click Install ADB. The app downloads the official platform tools into your user folder. No Terminal, Homebrew, Xcode, Android Studio or Windows USB driver is needed for this setup.", "Falls ADB fehlt: Lies Googles Bedingungen, akzeptiere sie unten und klicke ADB installieren. Die App lädt die offiziellen Platform Tools in deinen Benutzerordner. Du brauchst dafür weder Terminal, Homebrew, Xcode, Android Studio noch Windows-USB-Treiber."))
            Link(t("Google download and license terms", "Google-Download und Lizenzbedingungen"), destination: URL(string: "https://developer.android.com/tools/releases/platform-tools")!)
            Toggle(t("I accept Google's Android SDK license terms.", "Ich akzeptiere Googles Android-SDK-Lizenzbedingungen."), isOn: $acceptTerms)
            HStack {
                Button(t("Install ADB", "ADB installieren")) { model.work("ADB-Installation vorbereiten …", lockLibrary: false) { _ = try model.library.installADB(); return "ADB wurde installiert und erfolgreich geprüft." } }.disabled(!acceptTerms || model.busy)
                Button(t("Check again", "Erneut prüfen")) { model.connect() }.disabled(model.busy)
            }
            Text(t("Already have ADB? Select it under All settings → Manage ADB. Internet is only needed for downloads, not for a USB backup.", "ADB schon vorhanden? Wähle es unter Alle Einstellungen → ADB verwalten. Internet wird für Downloads benötigt, nicht für ein USB-Backup.")).font(.callout).foregroundStyle(.secondary)
        case 2:
            instruction("person.crop.circle", t("In your browser: open Meta's setup guide below. Sign in with the Meta account used on your headset. Follow the steps to join or create a developer team and verify your account. These steps are completed on Meta's website, not in Companion.", "Im Browser: Öffne unten Metas Einrichtungsanleitung. Melde dich mit dem Meta-Konto deiner Brille an. Folge den Schritten zum Beitreten oder Erstellen eines Entwicklerteams und zur Kontoverifizierung. Das erledigst du auf Metas Website, nicht im Companion."))
            Text(t("If developer mode is already enabled, continue. Meta controls eligibility and account requirements; consult the linked guide if an option is unavailable. Never enter your Meta password or verification codes in Companion.", "Wenn der Entwicklermodus schon aktiviert ist, gehe weiter. Meta bestimmt die Voraussetzungen für Konten; fehlt eine Option, prüfe die verlinkte Anleitung. Gib dein Meta-Passwort oder Bestätigungscodes niemals im Companion ein."))
            metaLink
        case 3:
            instruction("iphone", t("On your phone: open Meta Horizon → headset icon → your paired headset → Headset Settings → Developer Mode. Turn it on. Keep the headset awake and nearby. Menu names can vary with updates.", "Am Smartphone: Öffne Meta Horizon → Headset-Symbol → deine gekoppelte Brille → Headset-Einstellungen → Entwicklermodus. Schalte ihn ein. Halte die Brille wach und in der Nähe. Die Menünamen können sich durch Updates ändern."))
            Text(t("Can't find the switch? Check that the correct headset and account are selected and that the previous account step is complete. Use Meta's current instructions below. Companion cannot switch this setting on for you.", "Fehlt der Schalter? Prüfe, ob die richtige Brille und das richtige Konto ausgewählt sind und der vorherige Kontoschritt abgeschlossen ist. Nutze unten Metas aktuelle Anleitung. Companion kann diesen Schalter nicht für dich aktivieren."))
            metaLink
        case 4:
            instruction("cable.connector", t("Connect the Quest directly to your Mac using a USB data cable. A charging-only cable will not work. Put the headset on and wake it up.", "Verbinde die Quest direkt über ein USB-Datenkabel mit dem Mac. Ein reines Ladekabel funktioniert nicht. Setze die Brille auf und wecke sie auf."))
            instruction("visionpro", t("Inside the headset: allow USB debugging. On your own Mac you can also select Always allow from this computer. A separate file-access prompt is not the same as USB-debugging approval.", "In der Brille: Erlaube USB-Debugging. An deinem eigenen Mac kannst du zusätzlich Von diesem Computer immer zulassen wählen. Eine separate Dateizugriffsabfrage ersetzt die USB-Debugging-Freigabe nicht."))
            Text(t("No prompt? Unplug and reconnect, keep the headset awake, try another data cable or USB port and check developer mode. If your Quest version offers Developer → MTP Notification, follow Meta's guide to enable it. On the Mac, approve an accessory-connection prompt if macOS shows one.", "Keine Abfrage? Ziehe das Kabel ab und stecke es wieder an, halte die Brille wach, teste ein anderes Datenkabel oder einen USB-Anschluss und prüfe den Entwicklermodus. Falls deine Quest-Version Entwickler → MTP-Benachrichtigung anbietet, aktiviere diese nach Metas Anleitung. Erlaube am Mac gegebenenfalls die von macOS angefragte Zubehörverbindung."))
            Button(t("Check connection", "Verbindung prüfen")) { model.connect() }.disabled(model.busy)
            Text(tr(model.setup.message)).foregroundStyle(.secondary)
            metaLink
        case 5:
            instruction("gamecontroller", t("On the Quest: install RealmCraft if needed, start it and save a world. Save your progress and quit the game before transferring worlds. Force-stop closes the game without saving unsaved progress.", "Auf der Quest: Installiere RealmCraft bei Bedarf, starte es und speichere eine Welt. Speichere deinen Fortschritt und beende das Spiel vor Übertragungen. Erzwungenes Beenden schließt das Spiel ohne ungespeicherten Fortschritt zu sichern."))
            if !model.devices.isEmpty {
                Picker(t("Headset", "Brille"), selection: $model.serial) { ForEach(model.devices) { device in Text(device.name).tag(device.id) } }.onChange(of: model.serial) { _, _ in model.connect() }
            }
            Button(t("Check headset and game", "Brille und Spiel prüfen")) { model.connect() }.disabled(model.busy)
            status(connected, t("RealmCraft and saved worlds found", "RealmCraft und gespeicherte Welten gefunden"), tr(model.setup.message))
            Text(t("Unauthorized means you still need to allow USB debugging inside the headset. Offline: reconnect and wake it. No device: check ADB, cable and developer mode. No world: save one in RealmCraft, quit and check again.", "Unauthorized bedeutet: USB-Debugging muss noch in der Brille erlaubt werden. Offline: neu verbinden und aufwecken. Kein Gerät: ADB, Kabel und Entwicklermodus prüfen. Keine Welt: Eine Welt in RealmCraft speichern, beenden und erneut prüfen."))
        case 6:
            instruction("folder", t("On the Mac: the default library below is ready to use. Leave it unchanged if you are unsure. Backups stay on this Mac. Use All settings to choose another folder or copy an existing library; macOS may ask you to allow access to a folder you select.", "Am Mac: Der Standardordner unten ist einsatzbereit. Lass ihn unverändert, wenn du unsicher bist. Backups bleiben auf diesem Mac. Unter Alle Einstellungen kannst du einen anderen Ordner wählen oder eine bestehende Library kopieren; macOS kann für einen gewählten Ordner eine Zugriffsfreigabe anfordern."))
            Text(model.library.root.path).font(.callout.monospaced()).textSelection(.enabled)
            Text(t("Optional: map and analysis tools are separate from ADB. Install them below when you want to use maps or other save analysis features. You can do this later; they are not required for backups.", "Optional: Karten- und Analysewerkzeuge sind von ADB getrennt. Installiere sie unten, wenn du Karten oder weitere Savegame-Analysen nutzen möchtest. Das geht auch später; für Backups sind sie nicht erforderlich."))
            MapToolsSetup(model: model, maps: maps, english: english).onAppear { maps.check(model) }
        default:
            status(adbReady && connected, t("Connection ready", "Verbindung bereit"), adbReady && connected ? t("ADB, RealmCraft and a saved world were detected.", "ADB, RealmCraft und eine gespeicherte Welt wurden erkannt.") : t("Setup is not fully verified yet. You can still open Companion and return to this guide later.", "Die Einrichtung ist noch nicht vollständig geprüft. Du kannst Companion trotzdem öffnen und später zur Anleitung zurückkehren."))
            instruction("tray.and.arrow.down", t("Next: open Savegames, choose the correct headset and world, then Back up Quest → Mac. Wait for successful verification. If there are several worlds, choose deliberately and back them up separately. No backup starts when you finish this guide.", "Als Nächstes: Öffne Savegames, wähle die richtige Brille und Welt und dann Backup Quest → Mac. Warte auf die erfolgreiche Prüfung. Gibt es mehrere Welten, wähle bewusst und sichere sie separat. Beim Abschließen dieser Anleitung startet kein Backup."))
            Text(t("Help contains the full German/English instructions and an agent-assistance Markdown file you can share with GPT, Claude or another assistant. Account approval and headset prompts still require your own actions.", "Die Hilfe enthält die vollständige deutsche/englische Anleitung und eine Markdown-Datei zur Unterstützung durch GPT, Claude oder einen anderen Assistenten. Kontofreigaben und Abfragen in der Brille bestätigst du weiterhin selbst."))
            Button(t("Restart guide", "Anleitung neu beginnen")) { savedStep = 0 }
        }
    }
    private var metaLink: some View { Link(t("Open Meta's current Quest setup guide", "Aktuelle Quest-Einrichtungsanleitung von Meta öffnen"), destination: URL(string: "https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/")!) }
    private func instruction(_ icon: String, _ text: String) -> some View { Label { Text(text).fixedSize(horizontal: false, vertical: true) } icon: { Image(systemName: icon).foregroundStyle(theme.accent).frame(width: 28) } }
    private func status(_ ready: Bool, _ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(ready ? title : t("Still to check", "Noch zu prüfen"), systemImage: ready ? "checkmark.circle.fill" : "circle.dashed").font(.headline).foregroundStyle(ready ? theme.accent : .orange)
            Text(detail).font(.callout).textSelection(.enabled)
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(theme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}
