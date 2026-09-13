import SwiftUI
import AppKit
import WebKit
import CryptoKit

struct TectonicusProgress: Decodable {
    var phase: String
    var detail: String
    var fraction: Double?
    func title(_ en: Bool) -> String {
        switch phase {
        case "download": return en ? "Downloading tools" : "Werkzeuge herunterladen"
        case "java": return en ? "Preparing Java" : "Java einrichten"
        case "verify": return en ? "Verifying savegame" : "Spielstand prüfen"
        case "export": return en ? "Exporting chunks" : "Chunks exportieren"
        case "render": return en ? "Rendering terrain" : "Gelände rendern"
        case "zoom": return en ? "Generating zoom levels" : "Zoomstufen erstellen"
        case "complete": return en ? "Render complete" : "Rendering abgeschlossen"
        case "cancelled": return en ? "Cancelled" : "Abgebrochen"
        case "error": return en ? "Action incomplete" : "Aktion nicht abgeschlossen"
        default: return en ? "Preparing tools" : "Werkzeuge vorbereiten"
        }
    }
}

// One owned worker; SIGTERM lets Python stop and reap its renderer/download child.
final class TectonicusJob: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var cancelled = false
    func cancel() {
        lock.lock(); defer { lock.unlock() }
        cancelled = true
        if let process, process.isRunning { process.terminate() }
    }
    func run(python: String, worker: URL, args: [String], progressURL: URL,
             report: @escaping (TectonicusProgress) -> Void) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: python)
        p.arguments = ["-I", "-B", "-u", worker.path] + args + ["--progress", progressURL.path]
        p.standardOutput = FileHandle.nullDevice; p.standardError = FileHandle.nullDevice
        lock.lock()
        if cancelled { lock.unlock(); throw LibraryError("Cancelled / Abgebrochen") }
        do { try p.run(); process = p; lock.unlock() }
        catch { lock.unlock(); throw error }
        var previous = Data()
        while p.isRunning {
            if let data = try? Data(contentsOf: progressURL), data != previous,
               let event = try? JSONDecoder().decode(TectonicusProgress.self, from: data) {
                previous = data; report(event)
            }
            Thread.sleep(forTimeInterval: 0.25)
        }
        p.waitUntilExit()
        let event = (try? Data(contentsOf: progressURL)).flatMap { try? JSONDecoder().decode(TectonicusProgress.self, from: $0) }
        if let event { report(event) }
        lock.lock(); process = nil; let wasCancelled = cancelled; lock.unlock()
        if wasCancelled { throw LibraryError("Cancelled / Abgebrochen") }
        guard p.terminationStatus == 0 else { throw LibraryError(event?.detail ?? "Tectonicus worker failed.") }
    }
}

struct TectonicusResult: Decodable {
    var status: String
    var title: String
    var date: Double
    var chunks: Int
    var placeholders: Int
    var camera_angle: Int?
    var camera_elevation: Int?
}

private enum TectonicusDirection: Int, CaseIterable {
    case north = 270, northeast = 315, east = 0, southeast = 45
    case south = 90, southwest = 135, west = 180, northwest = 225
    func title(_ en: Bool) -> String {
        switch self {
        case .north: return en ? "North" : "Norden"
        case .northeast: return en ? "Northeast" : "Nordosten"
        case .east: return en ? "East" : "Osten"
        case .southeast: return en ? "Southeast" : "Südosten"
        case .south: return en ? "South" : "Süden"
        case .southwest: return en ? "Southwest" : "Südwesten"
        case .west: return en ? "West" : "Westen"
        case .northwest: return en ? "Northwest" : "Nordwesten"
        }
    }
}

@MainActor final class TectonicusController: ObservableObject {
    @Published var ready = false
    @Published var checking = false
    @Published var working = false
    @Published var cancellable = false
    @Published var event: TectonicusProgress?
    @Published var mapURL: URL?
    @Published var result: TectonicusResult?
    @Published var output: URL?
    @Published var notice = ""
    private var job: TectonicusJob?
    private var server: Process?
    private var serverTicket = UUID()
    private var python = ""
    let support: URL = ProcessInfo.processInfo.environment["REALMCRAFT_TECTONICUS_ROOT"].map { URL(fileURLWithPath: $0) }
        ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/RealmCraftLibrary/Tectonicus")
    private var worker: URL? { Bundle.main.resourceURL?.appendingPathComponent("Tectonicus/worker.py") }
    private var mapTools: MapTools {
        MapTools(support: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/RealmCraftLibrary/Maps"))
    }
    private func bucket(_ save: Savegame) -> URL {
        let key = SHA256.hash(data: Data(save.id.utf8)).map { String(format: "%02x", $0) }.joined()
        return support.appendingPathComponent("renders/" + key)
    }
    func check(_ model: Model) {
        guard !checking && !working && !model.busy, let worker else { return }
        checking = true
        let backend = model.library, tools = mapTools, support = support
        model.queue.async {
            let candidate = tools.readyPython(using: backend)
            var valid = false
            if let candidate {
                let progress = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
                defer { try? FileManager.default.removeItem(at: progress); try? FileManager.default.removeItem(at: progress.deletingPathExtension().appendingPathExtension("command.log")) }
                valid = (try? backend.run(candidate, ["-I", "-B", worker.path, "status", "--support", support.path, "--progress", progress.path], timeout: 90).code) == 0
            }
            DispatchQueue.main.async { self.python = candidate ?? ""; self.ready = valid; self.checking = false; self.restore(model.selected) }
        }
    }
    func start(_ model: Model, save: Savegame?, radius: Int, detail: Int, angle: Int, elevation: Int, consent: Bool, english: Bool) {
        guard !model.busy && !checking && !working, let worker, consent || ready else { return }
        let job = TectonicusJob(); self.job = job
        let backend = model.library, tools = mapTools, support = support
        let destination = save.map { bucket($0).appendingPathComponent(UUID().uuidString) }
        let progressURL = support.appendingPathComponent("jobs/" + UUID().uuidString + ".json")
        let knownReady = ready
        working = true; notice = ""; event = nil
        if save != nil { stopPreview(); result = nil; output = destination }
        model.work(english ? "Preparing Tectonicus…" : "Tectonicus wird vorbereitet …", lockLibrary: save != nil) {
            defer { DispatchQueue.main.async { self.working = false; self.cancellable = false; self.job = nil } }
            do {
                let python = try tools.readyPython(using: backend) ?? tools.install(using: backend, english: english)
                let report: (TectonicusProgress) -> Void = { progress in
                    DispatchQueue.main.async { self.event = progress; model.status = progress.title(english) + " · " + progress.detail }
                }
                DispatchQueue.main.async { self.python = python; self.cancellable = true }
                var setupArgs = [knownReady && !consent ? "status" : "setup", "--support", support.path]
                if consent { setupArgs += ["--accept-minecraft-resources"] }
                try job.run(python: python, worker: worker, args: setupArgs, progressURL: progressURL, report: report)
                DispatchQueue.main.async { self.ready = true }
                if let save, let destination {
                    _ = try backend.verify(save)
                    try job.run(python: python, worker: worker,
                        args: ["render", "--support", support.path, "--source", backend.worldFolder(save).path,
                               "--output", destination.path, "--radius", String(radius), "--detail", String(detail),
                               "--camera-angle", String(angle), "--camera-elevation", String(elevation), "--title", save.title],
                        progressURL: progressURL, report: report)
                    _ = try backend.verify(save)
                    // Persist only after the full library manifest passes the final check.
                    try "verified".write(to: destination.appendingPathComponent(".library-verified"), atomically: true, encoding: .utf8)
                    DispatchQueue.main.async { self.restore(save) }
                }
                return english ? "Tectonicus is ready. Original savegame unchanged." : "Tectonicus ist bereit. Original-Spielstand unverändert."
            } catch {
                DispatchQueue.main.async { self.notice = error.localizedDescription }
                if error.localizedDescription == "Cancelled / Abgebrochen" { return english ? "Tectonicus cancelled." : "Tectonicus abgebrochen." }
                throw error
            }
        }
    }
    func cancel() { job?.cancel(); cancellable = false }
    func stopPreview() {
        serverTicket = UUID()
        if let server, server.isRunning { server.terminate() }
        server = nil; mapURL = nil
    }
    func restore(_ save: Savegame?) {
        stopPreview(); result = nil; output = nil
        guard let save else { return }
        let folders = (try? FileManager.default.contentsOfDirectory(at: bucket(save), includingPropertiesForKeys: nil)) ?? []
        let results: [(URL, TectonicusResult)] = folders.compactMap { folder in
            guard FileManager.default.fileExists(atPath: folder.appendingPathComponent(".library-verified").path),
                  let data = try? Data(contentsOf: folder.appendingPathComponent("result.json")),
                  let result = try? JSONDecoder().decode(TectonicusResult.self, from: data), result.status == "complete",
                  FileManager.default.fileExists(atPath: folder.appendingPathComponent("map/map.html").path) else { return nil }
            return (folder, result)
        }.sorted { $0.1.date > $1.1.date }
        guard let latest = results.first else { return }
        output = latest.0; result = latest.1
        openPreview(latest.0.appendingPathComponent("map"))
    }
    private func openPreview(_ folder: URL) {
        guard !python.isEmpty, let worker else { return }
        let ticket = UUID(); serverTicket = ticket
        let progress = FileManager.default.temporaryDirectory.appendingPathComponent("tectonicus-preview-" + ticket.uuidString + ".json")
        let p = Process(); p.executableURL = URL(fileURLWithPath: python)
        p.arguments = ["-I", "-B", worker.path, "serve", "--support", support.path, "--source", folder.path,
                       "--progress", progress.path, "--parent", String(ProcessInfo.processInfo.processIdentifier)]
        p.standardOutput = FileHandle.nullDevice; p.standardError = FileHandle.nullDevice
        do { try p.run(); server = p }
        catch { notice = error.localizedDescription; return }
        Task { @MainActor in
            defer { try? FileManager.default.removeItem(at: progress) }
            for _ in 0..<100 {
                guard serverTicket == ticket, p.isRunning else { return }
                if let data = try? Data(contentsOf: progress),
                   let event = try? JSONDecoder().decode(TectonicusProgress.self, from: data),
                   event.phase == "serving", let port = Int(event.detail), (1...65535).contains(port) {
                    mapURL = URL(string: "http://127.0.0.1:\(port)/map.html"); return
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
            if serverTicket == ticket { notice = "Preview unavailable / Vorschau nicht verfügbar"; stopPreview() }
        }
    }
}

struct TectonicusView: View {
    @ObservedObject var model: Model
    @ObservedObject var tectonicus: TectonicusController
    let language: String
    @AppStorage("tectonicus.minecraftResourcesConsent") private var consent = false
    @AppStorage("tectonicus.cameraAngle") private var angle = TectonicusDirection.north.rawValue
    @AppStorage("tectonicus.cameraElevation") private var elevation = 90
    @AppStorage("tectonicus.mirrorHorizontally") private var mirrored = true
    @State private var radius = 0
    @State private var detail = 32
    @State private var settings = false
    @State private var information = false
    private var en: Bool { language == "en" }
    private var previewURL: URL? {
        guard let url = tectonicus.mapURL, var parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        parts.queryItems = (parts.queryItems ?? []).filter { $0.name != "mirror" } + [URLQueryItem(name: "mirror", value: mirrored ? "1" : "0")]
        return parts.url
    }
    private var areaOptions: [(Int, String)] {
        [(0, en ? "All saved chunks" : "Alle gespeicherten Chunks")] + [128,256,512,1024].map { ($0, "±\($0) · " + (en ? "origin" : "Ursprung")) }
    }
    private var detailOptions: [(Int, String)] {
        [(64, en ? "Fast" : "Schnell"), (32, "Standard"), (16, en ? "High" : "Hoch")]
    }
    private var renderSummary: String {
        [areaOptions.first { $0.0 == radius }?.1 ?? "", detailOptions.first { $0.0 == detail }?.1 ?? "",
         TectonicusDirection(rawValue: angle)?.title(en) ?? "—", "\(elevation)°"].joined(separator: " · ")
    }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: "Tectonicus · Beta") {
                if tectonicus.working {
                    Button(en ? "Cancel" : "Abbrechen") { tectonicus.cancel() }.disabled(!tectonicus.cancellable)
                } else {
                    Button(tectonicus.ready ? (en ? "Render savegame" : "Spielstand rendern") : (en ? "Set up & render" : "Einrichten & rendern")) {
                        settings = false
                        tectonicus.start(model, save: model.selected, radius: radius, detail: detail, angle: angle, elevation: elevation, consent: consent, english: en)
                    }.buttonStyle(CompanionButtonStyle(prominent: true))
                        .disabled(model.busy || tectonicus.checking || model.selected == nil || (!consent && !tectonicus.ready))
                }
            } menu: {
                Button(en ? "Open in browser" : "Im Browser öffnen") { if let url = previewURL { NSWorkspace.shared.open(url) } }.disabled(previewURL == nil)
                Button(en ? "Show render folder" : "Render-Ordner anzeigen") { if let output = tectonicus.output { NSWorkspace.shared.activateFileViewerSelecting([output]) } }.disabled(tectonicus.output == nil)
                Divider()
                Button(en ? "Set up / check tools" : "Werkzeuge einrichten / prüfen") {
                    tectonicus.start(model, save: nil, radius: radius, detail: detail, angle: angle, elevation: elevation, consent: consent, english: en)
                }.disabled(model.busy || tectonicus.checking || (!consent && !tectonicus.ready))
                Link(en ? "Tectonicus project" : "Tectonicus-Projekt", destination: URL(string: "https://github.com/tectonicus/tectonicus")!)
            }
            VStack(alignment: .leading, spacing: 6) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .bottom, spacing: 16) {
                        backupControl.frame(minWidth: 220)
                        settingsButton
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        backupControl
                        settingsButton.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }.companionActionAligned()
                if let save = model.selected {
                    Text((en ? "Saved game state: " : "Gespeicherter Spielstand: ") + displayDate(save.gameDate, language: language) + (en ? " · not live" : " · nicht live"))
                        .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
                Text((en ? "Next render: " : "Nächstes Rendering: ") + renderSummary)
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if let result = tectonicus.result, result.placeholders > 0 {
                    Text(en ? "The displayed map contains \(result.placeholders) placeholder blocks. See map information." : "Die angezeigte Karte enthält \(result.placeholders) Platzhalter-Blöcke. Siehe Karteninfos.")
                        .font(.caption).foregroundStyle(.orange)
                }
                if !tectonicus.ready { setupConsent }
                if tectonicus.working || tectonicus.checking { progress }
                if !tectonicus.notice.isEmpty { Text(tectonicus.notice).font(.caption).foregroundStyle(.orange).textSelection(.enabled).lineLimit(4) }
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 10)
            Divider()
            if let url = previewURL {
                TectonicusWebView(url: url).id(url).frame(maxWidth: .infinity, maxHeight: .infinity).layoutPriority(1)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "map.fill").font(.system(size: 44)).foregroundStyle(.secondary)
                    Text(en ? "Render your saved world with Tectonicus" : "Deine gesicherte Welt mit Tectonicus rendern").font(.title3)
                    Text(en ? "Choose a backup, then start setup and rendering above." : "Wähle eine Sicherung und starte oben Einrichtung und Rendering.").foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { tectonicus.check(model) }
        .onChange(of: model.selection) { _, _ in if !tectonicus.working { tectonicus.restore(model.selected) } }
    }
    private var backupControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(en ? "Backup" : "Sicherung").font(.caption)
                Button { information.toggle() } label: { Image(systemName: "info.circle") }
                    .buttonStyle(.plain)
                    .help(en ? "Source and map information" : "Quelle und Karteninfos")
                    .accessibilityLabel(en ? "Source and map information" : "Quelle und Karteninfos")
                    .accessibilityIdentifier("tectonicus.information")
                    .popover(isPresented: $information) {
                        ScrollView { mapInformation.padding(20) }.frame(width: 420, height: 430)
                    }
            }
            SourceContextBar(saves: model.saves, selection: $model.selection, language: language).backupPicker.disabled(model.busy)
        }
    }
    private var settingsButton: some View {
        Button { settings.toggle() } label: {
            Label(en ? "Render settings" : "Render-Einstellungen", systemImage: "slider.horizontal.3")
        }.buttonStyle(CompanionButtonStyle()).frame(width: CompanionLayout.primaryActionWidth)
            .accessibilityIdentifier("tectonicus.settings")
            .popover(isPresented: $settings) {
                ScrollView { renderSettings.padding(20) }.frame(width: 440, height: 430)
            }
    }
    private var renderSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(en ? "Render settings" : "Render-Einstellungen").font(.headline)
                Spacer()
                Button { settings = false } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).accessibilityLabel(en ? "Close" : "Schließen")
            }
            Group {
                CompanionPopup(title: en ? "Overworld" : "Oberwelt", selection: $radius, options: areaOptions).companionField(en ? "Overworld" : "Oberwelt")
                CompanionPopup(title: en ? "Detail" : "Details", selection: $detail, options: detailOptions).companionField(en ? "Detail" : "Details")
                CompanionPopup(title: en ? "View from" : "Blick von", selection: $angle,
                    options: TectonicusDirection.allCases.map { ($0.rawValue, $0.title(en)) }).companionField(en ? "View from" : "Blick von")
                CompanionPopup(title: en ? "Elevation" : "Neigung", selection: $elevation,
                    options: [(30, en ? "30° · Low" : "30° · Flach"), (45, en ? "45° · Oblique" : "45° · Schräg"), (60, en ? "60° · Steep" : "60° · Steil"), (90, en ? "90° · Top-down · Standard" : "90° · Draufsicht · Standard")]).companionField(en ? "Elevation" : "Neigung")
                Text(en ? "Direction and elevation are saved for the next render. Changing them requires a new render." : "Blickrichtung und Neigung werden für das nächste Rendering gespeichert. Änderungen benötigen einen neuen Renderlauf.")
                    .font(.caption).foregroundStyle(.secondary)
                Divider()
                Toggle(en ? "Mirror left and right" : "Links und rechts spiegeln", isOn: $mirrored)
                    .accessibilityIdentifier("tectonicus.mirror")
                Text(en ? "Mirroring applies immediately to the displayed map and browser view, including existing renders. Controls and markers stay readable." : "Die Spiegelung gilt sofort für die angezeigte Karte und die Browser-Ansicht, auch bei bestehenden Renderings. Bedienelemente und Marker bleiben lesbar.")
                    .font(.caption).foregroundStyle(.secondary)
                Button(en ? "Use standard view" : "Standardansicht verwenden") {
                    angle = TectonicusDirection.north.rawValue; elevation = 90; mirrored = true
                }
                Text(en ? "Standard: North, 90° top-down, mirrored left and right." : "Standard: Norden, 90° Draufsicht, links und rechts gespiegelt.")
                    .font(.caption).foregroundStyle(.secondary)
            }.disabled(model.busy)
        }
    }
    private var mapInformation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(en ? "Source and map information" : "Quelle und Karteninfos").font(.headline)
            if let save = model.selected {
                Text(save.title).font(.subheadline.bold())
                Text((en ? "Backup created: " : "Sicherung erstellt: ") + displayDate(save.date, language: language))
                Text((en ? "World ID: " : "Welt-ID: ") + save.world + "\n" + (en ? "Backup ID: " : "Sicherungs-ID: ") + save.id)
            }
            if let result = tectonicus.result {
                Divider()
                Text(en ? "Displayed map" : "Angezeigte Karte").font(.subheadline.bold())
                Text("\(result.chunks) " + (en ? "chunks rendered" : "Chunks gerendert") + " · \(result.placeholders) " + (en ? "placeholder blocks" : "Platzhalter-Blöcke") + " · " + Date(timeIntervalSince1970: result.date).formatted())
                // Older results without perspective metadata used 45°/45°.
                Text((en ? "Rendered from " : "Gerendert von ") + (TectonicusDirection(rawValue: result.camera_angle ?? 45)?.title(en) ?? "—") + " · \(result.camera_elevation ?? 45)°")
                Text(mirrored ? (en ? "Display: mirrored left and right" : "Anzeige: links und rechts gespiegelt") : (en ? "Display: original orientation" : "Anzeige: ursprüngliche Ausrichtung"))
            }
            Divider()
            Text(en ? "Experimental rendering copy · Overworld only. Block states and lighting are approximate; sign text and entities are omitted. Unknown blocks appear magenta. Each run keeps its own output; large worlds may require several GB. The source savegame stays unchanged." : "Experimentelle Render-Kopie · nur Oberwelt. Blockzustände und Beleuchtung sind vereinfacht; Schildtexte und Entitäten fehlen. Unbekannte Blöcke erscheinen magenta. Jeder Lauf behält seine eigene Ausgabe; große Welten können mehrere GB benötigen. Der Quell-Spielstand bleibt unverändert.")
        }.font(.callout).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
    }
    private var setupConsent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(en ? "I own Minecraft Java and allow the download of its rendering resources." : "Ich besitze Minecraft Java und erlaube den Download seiner Render-Ressourcen.", isOn: $consent).disabled(model.busy)
            DisclosureGroup(en ? "Setup details" : "Einrichtungsdetails") {
                Text(en ? "Setup downloads Tectonicus 2.31, a verified Java 21 installer and Minecraft 1.17.1 resources. Python is prepared automatically if needed. Internet and several hundred MB of free space are required." : "Die Einrichtung lädt Tectonicus 2.31, einen geprüften Java-21-Installer und Minecraft-1.17.1-Ressourcen. Python wird bei Bedarf automatisch eingerichtet. Internet und mehrere hundert MB freier Speicher werden benötigt.")
            }.font(.caption).foregroundStyle(.secondary)
        }
    }
    private var progress: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ProgressView().controlSize(.small)
                Text(tectonicus.event.map { $0.title(en) + " · " + $0.detail } ?? (tectonicus.checking ? (en ? "Checking tools…" : "Werkzeuge werden geprüft …") : tr(model.status))).font(.callout)
            }
            if let fraction = tectonicus.event?.fraction { ProgressView(value: fraction) }
        }
    }
}

private struct TectonicusWebView: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> WKWebView {
        let view = WKWebView(); view.load(URLRequest(url: url)); return view
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
