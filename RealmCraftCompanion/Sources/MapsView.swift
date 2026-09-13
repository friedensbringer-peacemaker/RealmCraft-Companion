import SwiftUI
import AppKit
import WebKit

@MainActor final class MapController: ObservableObject {
    let notifications = MapNotifications()
    @Published var mapURL: URL?
    @Published var focusTarget: MapFocusTarget?
    @Published var ready = false
    @Published var checking = false
    @Published var python = ""
    @Published var notice = ""
    @Published var builtFor = ""
    @Published var cacheBytes: Int64?
    @Published var generating = false
    @Published var cancellable = false
    struct FinishedMap { let saveID: String; let root: URL; let radius: String; let language: String }
    @Published var backgroundStatus = ""
    @Published var finishedMap: FinishedMap?
    private let renderQueue = DispatchQueue(label: "RealmCraft.MapRender", qos: .utility)
    private var displayRequest = ""
    private var job: MapRenderJob?
    private var cacheSizeRequest = UUID()
    let support = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/RealmCraftLibrary/Maps")
    var tools: MapTools { MapTools(support: support) }
    func check(_ model: Model) {
        guard !checking && !model.busy else { return }
        checking = true
        let backend = model.library, tools = tools
        model.queue.async {
            let candidate = tools.readyPython(using: backend)
            DispatchQueue.main.async {
                self.python = candidate ?? ""
                self.ready = candidate != nil
                self.checking = false
            }
        }
    }
    @Published var installing = false
    func install(_ model: Model, english: Bool) {
        guard !model.busy && !checking && !installing else { return }
        let backend = model.library, tools = tools
        installing = true
        model.work(english ? "Preparing map tools…" : "Kartenwerkzeuge werden eingerichtet …", lockLibrary: false) {
            defer { DispatchQueue.main.async { self.installing = false } }
            let executable = try tools.install(using: backend, english: english)
            DispatchQueue.main.async { self.python = executable; self.ready = true }
            return english ? "Python, NumPy and Pillow are ready for maps and chests." : "Python, NumPy und Pillow sind für Karten und Kisten bereit."
        }
    }
    func clearCache(_ model: Model, language: String) {
        guard !model.busy && model.backgroundMapJobs == 0 else { return }
        let cache = support.appendingPathComponent("cache", isDirectory: true)
        let english = language == "en"
        cacheSizeRequest = UUID()
        model.work(english ? "Clearing map cache…" : "Karten-Cache wird geleert …", lockLibrary: false) {
            let lease = try MapCacheLease(support: cache.deletingLastPathComponent())
            defer { withExtendedLifetime(lease) {} }
            let files = FileManager.default
            if files.fileExists(atPath: cache.path) {
                try files.removeItem(at: cache)
            }
            try files.createDirectory(at: cache, withIntermediateDirectories: true)
            DispatchQueue.main.async { self.cacheBytes = 0 }
            return english ? "Map cache cleared. Your savegames and generated maps are unchanged." : "Karten-Cache geleert. Spielstände und erzeugte Karten bleiben unverändert."
        }
    }
    func refreshCacheSize() {
        let cache = support.appendingPathComponent("cache", isDirectory: true)
        let request = UUID()
        cacheSizeRequest = request
        DispatchQueue.global(qos: .utility).async {
            let files = FileManager.default
            var total: Int64 = 0
            if let entries = files.enumerator(at: cache, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]) {
                for case let entry as URL in entries {
                    let values = try? entry.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    if values?.isRegularFile == true { total += Int64(values?.fileSize ?? 0) }
                }
            }
            DispatchQueue.main.async {
                guard self.cacheSizeRequest == request else { return }
                self.cacheBytes = total
            }
        }
    }
    func cancelGeneration() { job?.cancel(); cancellable = false }
    func restoreLast(_ save: Savegame?, radius: String, language: String) {
        displayRequest = (save?.id ?? "") + ":" + radius + ":" + language
        mapURL = nil; builtFor = ""; notice = ""
        guard let save else { return }
        let alternateLanguage = language == "en" ? "de" : "en"
        guard let stored = UserDefaults.standard.string(forKey: "map.\(save.id).\(radius).\(language)")
            ?? UserDefaults.standard.string(forKey: "map.\(save.id).\(radius).\(alternateLanguage)") else { return }
        let url = URL(fileURLWithPath: stored).resolvingSymlinksInPath()
        guard url.path.hasPrefix(support.resolvingSymlinksInPath().path + "/"), FileManager.default.fileExists(atPath: url.path), FileManager.default.fileExists(atPath: url.deletingLastPathComponent().appendingPathComponent("biomes.js").path) else { return }
        // Refresh only the viewer assets; cached world data and map tiles stay intact.
        let directory = url.deletingLastPathComponent()
        let stamp = directory.appendingPathComponent(".viewer-version")
        let viewerVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown") + ":annotations-2-signs-1-resources-3-metro-4-tools-1:" + language
        if (try? String(contentsOf: stamp, encoding: .utf8)) != viewerVersion {
            do {
                if let web = Bundle.main.resourceURL?.appendingPathComponent("MapEngine/realmcraft_map/web") {
                    for asset in try FileManager.default.contentsOfDirectory(at: web, includingPropertiesForKeys: nil) {
                        try Data(contentsOf: asset).write(to: directory.appendingPathComponent(asset.lastPathComponent), options: .atomic)
                    }
                    if language == "en" { try MapLocalization.english(directory) }
                    try viewerVersion.write(to: stamp, atomically: true, encoding: .utf8)
                }
            } catch {
                notice = language == "en" ? "Please generate the map again to update its viewer." : "Bitte die Karte erneut erzeugen, um die Kartenansicht zu aktualisieren."
            }
        }
        mapURL = url; builtFor = save.title
    }
    func generate(_ model: Model, save: Savegame, radius: String, language: String) {
        guard ready && !generating && !model.busy && model.backgroundMapJobs == 0 else { return }
        guard let backend = try? Library(root: model.library.root, adb: model.library.adb) else { return }
        backend.package = model.library.package
        let english = language == "en", interpreter = python
        let activityRoot = backend.root
        let output = support.appendingPathComponent(save.id).appendingPathComponent(UUID().uuidString)
        let inputURL = FileManager.default.temporaryDirectory.appendingPathComponent("realmcraft-map-input-" + UUID().uuidString)
        let cache = support.appendingPathComponent("cache")
        guard let engine = Bundle.main.resourceURL?.appendingPathComponent("MapEngine") else { return }
        let job = MapRenderJob(); self.job = job; generating = true; cancellable = true
        let notificationJobID = UUID()
        let request = save.id + ":" + radius + ":" + language
        displayRequest = request; model.backgroundMapJobs += 1
        notice = ""; finishedMap = nil
        backgroundStatus = (english ? "Preparing map in background: " : "Karte im Hintergrund vorbereiten: ") + save.title
        renderQueue.async {
            var completed = false
            defer {
                if !completed { try? FileManager.default.removeItem(at: output) }
                try? FileManager.default.removeItem(at: inputURL)
                DispatchQueue.main.async {
                    self.generating = false; self.cancellable = false; self.job = nil; self.refreshCacheSize()
                    model.backgroundMapJobs = max(0, model.backgroundMapJobs - 1)
                }
            }
            do {
            try job.checkCancellation()
            let lease = try MapCacheLease(support: cache.deletingLastPathComponent())
            defer { withExtendedLifetime(lease) {} }
            let input = try MapSnapshotInput.prepare(library: backend, save: save, directory: inputURL)
            try job.checkCancellation()
            DispatchQueue.main.async { self.backgroundStatus = (english ? "Rendering in background: " : "Karte wird im Hintergrund gerendert: ") + save.title }
            let workers = String(max(1, min(4, ProcessInfo.processInfo.activeProcessorCount - 2)))
            var arguments = ["-I", "-B", "-u", "-c", "import sys; sys.path.insert(0, sys.argv.pop(1)); from realmcraft_map.__main__ import main; raise SystemExit(main())", engine.path, input.directory.path, "--output", output.path, "--workers", workers, "--cache", cache.path]
            if radius != "all" { arguments += ["--radius", radius] }
            let result = try job.run(executable: interpreter, arguments: arguments)
            guard result.code == 0 || result.code == 2 else { throw LibraryError(String(result.output.suffix(4000))) }
            try backend.assertSame(input.manifest, backend.localManifest(input.directory))
            let index = output.appendingPathComponent("index.html")
            guard FileManager.default.fileExists(atPath: index.path) else { throw LibraryError(english ? "No map was produced." : "Es wurde keine Karte erzeugt.") }
            if english { try MapLocalization.english(output) }
            try job.beginCommit()
            DispatchQueue.main.async { self.cancellable = false }
            UserDefaults.standard.set(index.path, forKey: "map.\(save.id).\(radius).\(language)")
            DispatchQueue.main.async {
                if model.selection == save.id && model.library.root == activityRoot && self.displayRequest == request {
                    self.mapURL = index; self.builtFor = save.title
                    self.notice = result.code == 2 ? (english ? "Incomplete coverage; see audit.json." : "Unvollständige Abdeckung; siehe audit.json.") : ""
                }
                self.finishedMap = FinishedMap(saveID: save.id, root: activityRoot, radius: radius, language: language)
                Task { await self.notifications.finished(jobID:notificationJobID,gaps:result.code == 2,english:english) }
                self.backgroundStatus = (result.code == 2 ? (english ? "Map ready with gaps: " : "Karte mit Lücken fertig: ") : (english ? "Map ready: " : "Karte fertig: ")) + save.title
                model.history.append(self.backgroundStatus)
                self.refreshCacheSize()
                CompanionActivity.shared.record(CompanionActivityRecord(date: Date(), saveID: save.id, title: save.title, path: index.path, radius: radius, language: language), kind: "map", root: activityRoot)
            }
            completed = true
            } catch MapRenderJob.Failure.cancelled {
                DispatchQueue.main.async { self.backgroundStatus = english ? "Map generation cancelled. Previous map retained." : "Kartenerzeugung abgebrochen. Vorherige Karte bleibt erhalten." }
            } catch MapRenderJob.Failure.timedOut {
                DispatchQueue.main.async { self.backgroundStatus = english ? "Map generation exceeded one hour. Try a smaller area." : "Kartenerzeugung hat eine Stunde überschritten. Bitte einen kleineren Bereich wählen." }
            } catch {
                DispatchQueue.main.async { self.backgroundStatus = (english ? "Map generation failed: " : "Kartenerzeugung fehlgeschlagen: ") + String(error.localizedDescription.prefix(500)); model.history.append(self.backgroundStatus) }
            }
        }
    }
}

struct MapsView: View {
    @Environment(\.companionTheme) private var theme
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    let language: String
    var requestedRadius: String? = nil
    var openPortals: () -> Void = {}
    var openOreAnalysis: () -> Void = {}
    @State private var radius = "128"
    @State private var showMapExport = false
    @State private var confirmCacheClear = false
    @State private var showNotifications = false
    private var english: Bool { language == "en" }
    private var cacheSize: String { ByteCountFormatter.string(fromByteCount: maps.cacheBytes ?? 0, countStyle: .file) }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Maps" : "Karten") {
                    if maps.generating { Button(english ? "Cancel" : "Abbrechen") { maps.cancelGeneration() }.disabled(!maps.cancellable) }
                    else { Button(english ? "Generate map" : "Karte erzeugen") { if let save = model.selected { maps.generate(model, save: save, radius: radius, language: language) } }.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(model.busy || model.backgroundMapJobs > 0 || !maps.ready || model.selected == nil || maps.checking) }

            } menu: {
                Group {
                    Button(english ? "Open in browser" : "Im Browser öffnen") { if let url = maps.mapURL { NSWorkspace.shared.open(url) } }
                    Button(english ? "Show in Finder" : "Im Finder anzeigen") { if let url = maps.mapURL { NSWorkspace.shared.activateFileViewerSelecting([url]) } }
                }
                .disabled(maps.mapURL == nil)
                Divider()
                Button(english ? "Map export settings…" : "Kartenexport-Einstellungen …") { showMapExport = true }
                Button(english ? "Completion notifications…" : "Fertigmeldungen …") { showNotifications = true }
                Divider()
                if maps.cacheBytes != nil {
                    Text(english ? "Map cache: \(cacheSize)" : "Karten-Cache: \(cacheSize)")
                }
                Button(english ? "Clear map cache…" : "Karten-Cache leeren …") { confirmCacheClear = true }
                    .disabled(model.busy || model.backgroundMapJobs > 0)
            }
            VStack(alignment: .leading, spacing: 12) {
                MapSourceControls(saves: model.saves, selection: $model.selection, radius: $radius, english: english).disabled(model.busy)
                if model.busy { Text(tr(model.status)).font(.caption).foregroundStyle(.secondary) }
                if !maps.ready || maps.installing {
                    MapToolsSetup(model: model, maps: maps, english: english)
                }
                if !maps.notice.isEmpty { Text(maps.notice).font(.callout).foregroundStyle(.orange) }
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            .sheet(isPresented: $showMapExport) { MapExportSettings(english: english).companionAppearance() }
            .sheet(isPresented: $showNotifications) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(english ? "Completion notifications (optional)" : "Fertigmeldungen (optional)").font(.headline)
                    MapNotificationControls(notifications: maps.notifications, english: english)
                    Button(english ? "Close" : "Schließen") { showNotifications = false }.keyboardShortcut(.cancelAction)
                }.padding(24).frame(width: 440).companionAppearance()
            }
            .alert(english ? "Clear map cache?" : "Karten-Cache leeren?", isPresented: $confirmCacheClear) {
                Button(english ? "Cancel" : "Abbrechen", role: .cancel) { }
                Button(english ? "Clear cache" : "Cache leeren", role: .destructive) { maps.clearCache(model, language: language) }
            } message: {
                Text(english ? "Only temporary map-rendering cache data will be removed. Savegames and generated maps stay unchanged." : "Es werden nur temporäre Daten der Kartenerzeugung entfernt. Spielstände und erzeugte Karten bleiben unverändert.")
            }
            Divider()
            if let url = maps.mapURL { LocalMapWebView(url: url, world: model.selected?.world ?? "", scope: model.selected?.annotationScope ?? "", library: model.library.root, english: english, saveID: model.selected?.id ?? "", worldFolder: model.selected.map { model.library.worldFolder($0) }, openPortals: openPortals, openOreAnalysis: openOreAnalysis, focusTarget: maps.focusTarget, displayName: model.selected?.title ?? "").id(url) }
            else {
                VStack(spacing: 14) {
                    Image(systemName: "map.fill").font(.system(size: 50)).foregroundStyle(theme.accent)
                    Text(english ? "Explore a saved world" : "Eine gesicherte Welt erkunden").font(.title.bold())
                    Text(english ? "Choose a backup and generate its map. Start with the area around the origin for a quick preview." : "Wähle eine Sicherung und erzeuge ihre Karte. Die Umgebung des Ursprungs eignet sich für eine schnelle Vorschau.").foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 500)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { if let requestedRadius { radius = requestedRadius }; maps.check(model); maps.refreshCacheSize(); maps.restoreLast(model.selected, radius: radius, language: language) }
        .onChange(of: model.selection) { _, _ in maps.restoreLast(model.selected, radius: radius, language: language) }
        .onChange(of: radius) { _, _ in maps.restoreLast(model.selected, radius: radius, language: language) }
        .onChange(of: language) { _, _ in maps.restoreLast(model.selected, radius: radius, language: language) }
    }
}
struct LocalMapWebView: NSViewRepresentable {
    let url: URL
    let world: String
    let scope: String
    let library: URL
    let english: Bool
    let saveID: String
    let worldFolder: URL?
    let openPortals: () -> Void
    let openOreAnalysis: () -> Void
    var metroWorkspace = false
    var metroDocument: MetroNetworkStore.Document? = nil
    var metroFocus: String? = nil
    var metroPick: ((MetroMapSelection) -> Void)? = nil
    var metroCapturing = false
    var metroCancel: (() -> Void)? = nil
    var focusTarget: MapFocusTarget? = nil
    var displayName = ""
    private var targetScript: String {
        guard let target = focusTarget, target.valid, target.saveID == saveID, target.world == world, !metroWorkspace,
              let data = try? JSONEncoder().encode(target) else { return "" }
        return "window.ATLAS_FOCUS_TARGET=" + String(decoding: data, as: UTF8.self) + ";window.dispatchEvent(new CustomEvent('atlas-focus-target',{detail:window.ATLAS_FOCUS_TARGET}));"
    }
    private var portalScript: String {
        var value: [String: Any] = ["saveID": saveID, "world": world, "portals": [], "plans": []]
        do {
            if let worldFolder {
                value["portals"] = try PortalReader.read(worldFolder).portals.map { p in
                    ["id": p.id, "dimension": p.dimension, "x": p.anchor.x, "y": p.anchor.y, "z": p.anchor.z, "bounds": p.bounds, "count": p.blocks.count] as [String: Any]
                }
            }
        } catch { value["inventoryError"] = english ? "Saved portal inventory unavailable for this snapshot." : "Gespeicherter Portalbestand für diese Sicherung nicht verfügbar." }
        do {
            let store = PortalPlanStore(url: library.appendingPathComponent(".portal-plans").appendingPathComponent(saveID + ".json"))
            value["plans"] = try store.load().map(\.mapValue)
        } catch { value["plansError"] = error.localizedDescription }
        let data = (try? JSONSerialization.data(withJSONObject: value)) ?? Data("{}".utf8)
        return "window.ATLAS_PORTALS=" + String(decoding: data, as: UTF8.self) + ";"
    }
    private var metroScript: String {
        var value: [String: Any] = ["saveID": saveID, "world": world, "workspace": metroWorkspace, "capturing": metroCapturing, "stations": [], "lines": [], "edges": []]
        do {
            let store = MetroNetworkStore(url: library.appendingPathComponent(".metro-networks").appendingPathComponent(saveID + ".json"))
            let document = try metroDocument ?? store.load()
            value["stations"] = document.stations.map { ["id": $0.id, "name": $0.name, "dimension": $0.dimension, "x": $0.x, "y": $0.y, "z": $0.z, "status": $0.status.rawValue, "portalCandidate": $0.portalCandidate == true] }
            value["lines"] = document.lines.map { ["id": $0.id, "name": $0.name, "color": $0.color] }
            value["edges"] = document.edges.map { edge in
                var item: [String: Any] = ["id": edge.id, "from": edge.from, "to": edge.to, "mode": edge.mode.rawValue, "status": edge.status.rawValue]
                if let lineID = edge.lineID { item["lineID"] = lineID }
                if let path = edge.path { item["path"] = path.map { ["x": $0.x, "y": $0.y, "z": $0.z] } }
                return item
            }
            if let metroFocus { value["focusID"] = metroFocus }
        } catch { value["error"] = error.localizedDescription }
        let data = (try? JSONSerialization.data(withJSONObject: value)) ?? Data("{}".utf8)
        return "window.ATLAS_METRO=" + String(decoding: data, as: UTF8.self) + ";window.dispatchEvent(new CustomEvent('atlas-metro-update',{detail:window.ATLAS_METRO}));"
    }
    @AppStorage("exploration.spoilerFree") private var spoilerFree = false
    private var privacyScript: String {
        let state = ChestVisibility.load(world: scope)
        let payload: [String: Any] = ["enabled": spoilerFree, "owned": state.owned.sorted(), "visible": state.visible.sorted(), "hidden": state.hidden.sorted(), "suspected": state.hideSuspected]
        let data = try! JSONSerialization.data(withJSONObject: payload)
        return "window.ATLAS_PRIVACY=" + String(decoding: data, as: UTF8.self) + ";window.AtlasPrivacy?.apply(window.ATLAS_PRIVACY);"
    }
    @Environment(\.companionTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    private var styleScript: String {
        let css = Bundle.main.url(forResource: "CompanionMap", withExtension: "css").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        let data = try! JSONSerialization.data(withJSONObject: [css, theme.block ? "block" : "classic", colorScheme == .dark ? "dark" : "light"])
        let args = String(data: data, encoding: .utf8)!
        return "(() => { const [css, skin, appearance] = " + args + "; let style = document.getElementById('companion-skin'); if (!style) { style = document.createElement('style'); style.id = 'companion-skin'; document.head.appendChild(style); } style.textContent = css; document.documentElement.dataset.companion = skin; document.documentElement.dataset.appearance = appearance; })();"
    }
    func makeCoordinator() -> Coordinator { Coordinator(world: world, scope: scope, library: library, english: english, saveID: saveID, mapURL: url, openPortals: openPortals, openOreAnalysis: openOreAnalysis) }
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let displayData = try! JSONSerialization.data(withJSONObject: [displayName])
        configuration.userContentController.addUserScript(WKUserScript(source: "window.ATLAS_DISPLAY_NAME=" + String(decoding: displayData, as: UTF8.self) + "[0];", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.addUserScript(WKUserScript(source: targetScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        context.coordinator.lastTargetScript = targetScript
        context.coordinator.metroPick = metroPick
        context.coordinator.metroCancel = metroCancel
        configuration.userContentController.addUserScript(WKUserScript(source: portalScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.addUserScript(WKUserScript(source: metroScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(context.coordinator, name: "atlasPortals")
        configuration.userContentController.add(context.coordinator, name: "atlasMetro")
        configuration.userContentController.add(context.coordinator, name: "atlasResources")
        configuration.userContentController.addUserScript(WKUserScript(source: privacyScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let markerValue: Any = UserDefaults.standard.object(forKey: "atlasMarkers." + scope) ?? (scope == world ? NSNull() : [] as Any)
        let orientation = UserDefaults.standard.dictionary(forKey: "atlasOrientation." + world) ?? [:]
        let orientationData = try! JSONSerialization.data(withJSONObject: orientation)
        configuration.userContentController.addUserScript(WKUserScript(source: "window.ATLAS_NATIVE_ORIENTATION=" + String(decoding: orientationData, as: UTF8.self) + ";", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(context.coordinator, name: "atlasOrientation")
        configuration.userContentController.add(context.coordinator, name: "atlasNavigation")
        configuration.userContentController.add(context.coordinator, name: "atlasNavigationExport")
        let markerData = try! JSONSerialization.data(withJSONObject: ["scope": scope, "markers": markerValue])
        configuration.userContentController.addUserScript(WKUserScript(source: "{const a=" + String(decoding: markerData, as: UTF8.self) + ";window.ATLAS_ANNOTATION_SCOPE=a.scope;window.ATLAS_NATIVE_MARKERS=a.markers;}", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(context.coordinator, name: "atlasMarkers")
        let names = UserDefaults.standard.dictionary(forKey: "atlasPOI." + scope) ?? [:]
        let data = (try? JSONSerialization.data(withJSONObject: names)) ?? Data("{}".utf8)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        configuration.userContentController.addUserScript(WKUserScript(source: "window.ATLAS_NATIVE_NAMES=" + json + ";", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(context.coordinator, name: "atlasPOINames")
        let owned = UserDefaults.standard.stringArray(forKey: "conversation.ownedChests." + scope) ?? []
        let ownedData = (try? JSONSerialization.data(withJSONObject: owned)) ?? Data("[]".utf8)
        configuration.userContentController.addUserScript(WKUserScript(source: "window.ATLAS_NATIVE_OWNED=" + String(decoding: ownedData, as: UTF8.self) + ";", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(context.coordinator, name: "atlasOwnership")
        context.coordinator.styleScript = styleScript + privacyScript
        configuration.userContentController.addUserScript(WKUserScript(source: styleScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return view
    }
    func updateNSView(_ view: WKWebView, context: Context) {
        context.coordinator.metroCancel = metroCancel
        context.coordinator.pendingTargetScript = targetScript
        context.coordinator.pendingMetroScript = metroWorkspace ? metroScript : ""
        if !view.isLoading && context.coordinator.lastTargetScript != targetScript {
            context.coordinator.lastTargetScript = targetScript
            view.evaluateJavaScript(targetScript, completionHandler: nil)
        }
        context.coordinator.metroPick = metroPick
        if metroWorkspace && !view.isLoading && context.coordinator.lastMetroScript != metroScript {
            context.coordinator.lastMetroScript = metroScript
            view.evaluateJavaScript(metroScript, completionHandler: nil)
        }
        context.coordinator.styleScript = styleScript + privacyScript
        if !view.isLoading { view.evaluateJavaScript(styleScript + privacyScript, completionHandler: nil) }
    }
    static func dismantleNSView(_ view: WKWebView, coordinator: Coordinator) { view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasPortals"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasMetro"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasResources"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasNavigationExport"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasNavigation"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasOrientation"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasMarkers"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasPOINames"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasOwnership") }
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKDownloadDelegate {
        let world: String
        let scope: String
        let library: URL
        let english: Bool
        let saveID: String
        let mapURL: URL
        let openPortals: () -> Void
        let openOreAnalysis: () -> Void
        var styleScript = ""
        var lastMetroScript = ""
        var lastTargetScript = ""
        var pendingTargetScript = ""
        var pendingMetroScript = ""
        var metroPick: ((MetroMapSelection) -> Void)?
        var metroCancel: (() -> Void)?
        private func chunkOriginIndex(_ coordinate: Int) -> Int { coordinate >= 0 ? coordinate / 16 : (coordinate - 15) / 16 }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(styleScript, completionHandler: nil)
            if !pendingTargetScript.isEmpty && pendingTargetScript != lastTargetScript {
                lastTargetScript = pendingTargetScript
                webView.evaluateJavaScript(pendingTargetScript, completionHandler: nil)
            }
            if !pendingMetroScript.isEmpty && pendingMetroScript != lastMetroScript {
                lastMetroScript = pendingMetroScript
                webView.evaluateJavaScript(pendingMetroScript, completionHandler: nil)
            }
        }
        init(world: String, scope: String, library: URL, english: Bool, saveID: String, mapURL: URL, openPortals: @escaping () -> Void, openOreAnalysis: @escaping () -> Void) { self.world = world; self.scope = scope; self.library = library; self.english = english; self.saveID = saveID; self.mapURL = mapURL; self.openPortals = openPortals; self.openOreAnalysis = openOreAnalysis }
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "atlasMetro", message.frameInfo.isMainFrame,
               message.frameInfo.request.url?.standardizedFileURL == mapURL.standardizedFileURL,
               let body = message.body as? [String: Any], body["saveID"] as? String == saveID,
               body["world"] as? String == world, body["action"] as? String == "cancelCapture" {
                metroCancel?(); return
            }
            if message.name == "atlasMetro" {
                guard let callback = metroPick, message.frameInfo.isMainFrame,
                      message.frameInfo.request.url?.standardizedFileURL == mapURL.standardizedFileURL,
                      let body = message.body as? [String: Any], body["saveID"] as? String == saveID,
                      body["world"] as? String == world, body["action"] as? String == "pick",
                      let selection = MetroMapSelection.read(body) else { return }
                callback(selection)
                return
            }
            if message.name == "atlasResources" {
                guard message.frameInfo.isMainFrame,
                      message.frameInfo.request.url?.standardizedFileURL == mapURL.standardizedFileURL,
                      let body = message.body as? [String: Any], body["world"] as? String == world,
                      let dimension = body["dimension"] as? String, ["o", "n"].contains(dimension),
                      let x0 = body["x0"] as? Int, let x1 = body["x1"] as? Int,
                      let z0 = body["z0"] as? Int, let z1 = body["z1"] as? Int,
                      x0 <= x1, z0 <= z1,
                      abs(Double(x0)) <= 30_000_000, abs(Double(x1)) <= 30_000_000,
                      abs(Double(z0)) <= 30_000_000, abs(Double(z1)) <= 30_000_000,
                      (chunkOriginIndex(x1) - chunkOriginIndex(x0) + 1) * (chunkOriginIndex(z1) - chunkOriginIndex(z0) + 1) <= 4096 else { return }
                UserDefaults.standard.set(["dimension": dimension, "x0": x0, "x1": x1, "z0": z0, "z1": z1], forKey: "ore.region." + saveID)
                openOreAnalysis()
                return
            }
            if message.name == "atlasPortals" {
                guard message.frameInfo.isMainFrame,
                      message.frameInfo.request.url?.standardizedFileURL == mapURL.standardizedFileURL,
                      UUID(uuidString: saveID) != nil,
                      let body = message.body as? [String: Any], body["saveID"] as? String == saveID,
                      body["world"] as? String == world, let action = body["action"] as? String else { return }
                if action == "open" { openPortals(); return }
                var reply: [String: Any] = ["ok": false]
                do {
                    guard action == "add", let plan = PortalPlanStore.request(body) else { throw PortalPlanStore.StoreError.invalid }
                    let store = PortalPlanStore(url: library.appendingPathComponent(".portal-plans").appendingPathComponent(saveID + ".json"))
                    reply = ["ok": true, "plans": try store.add(plan).map(\.mapValue)]
                } catch { reply["error"] = error.localizedDescription }
                if let data = try? JSONSerialization.data(withJSONObject: reply) {
                    message.webView?.evaluateJavaScript("window.dispatchEvent(new CustomEvent('atlas-portals-saved',{detail:" + String(decoding: data, as: UTF8.self) + "}));", completionHandler: nil)
                }
                return
            }
            if message.name == "atlasNavigationExport" {
                guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.isFileURL == true,
                      let body = message.body as? [String: Any], let action = body["action"] as? String,
                      let requestID = body["requestID"] as? String, requestID.count <= 80 else { return }
                var result = english ? "Navigation export unavailable." : "Navigations-Export nicht verfügbar."
                if !UserDefaults.standard.bool(forKey: "exploration.spoilerFree"),
                   ["copy", "cloud"].contains(action), let raw = body["pack"], JSONSerialization.isValidJSONObject(raw),
                   let data = try? JSONSerialization.data(withJSONObject: raw), data.count <= 8_000_000,
                   let pack = try? JSONDecoder().decode(NavigationPack.self, from: data), pack.valid, pack.world == world {
                    if action == "copy" {
                        NSPasteboard.general.clearContents()
                        let copied = NSPasteboard.general.setString(pack.markdown, forType: .string)
                        result = copied ? (english ? "Navigation copied. Paste it into your AI chat." : "Navigation kopiert. In deinen KI-Chat einfügen.") : (english ? "Copy failed. Use Markdown export." : "Kopieren fehlgeschlagen. Bitte Markdown exportieren.")
                    } else {
                        let sharing = AIExportSharing(bookmarkKey: MapExportSettings.bookmarkKey)
                        sharing.saveToCloud(markdown: pack.markdown, world: "Navigation-" + pack.world, library: library, english: english)
                        result = !sharing.failure.isEmpty ? sharing.failure : !sharing.status.isEmpty ? sharing.status : (english ? "Export cancelled." : "Export abgebrochen.")
                    }
                }
                if let data = try? JSONSerialization.data(withJSONObject: ["requestID": requestID, "message": result]) {
                    message.webView?.evaluateJavaScript("window.dispatchEvent(new CustomEvent('atlas-navigation-exported', {detail: " + String(decoding: data, as: UTF8.self) + "}));", completionHandler: nil)
                }
                return
            }
            if message.name == "atlasNavigation" {
                guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.isFileURL == true else { return }
                let accepted = NavigationPack.accept(message.body, world: world, scope: scope)
                message.webView?.evaluateJavaScript("window.dispatchEvent(new CustomEvent('atlas-navigation-saved', {detail: " + String(accepted) + "}));", completionHandler: nil)
                return
            }
            if message.name == "atlasOrientation" {
                guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.isFileURL == true,
                      let body = message.body as? [String: Any], body["world"] as? String == world,
                      let value = body["orientation"] as? [String: Any], let angle = value["angle"] as? Double,
                      angle.isFinite, let flipX = value["flipX"] as? Bool, let flipZ = value["flipZ"] as? Bool else { return }
                UserDefaults.standard.set(["angle": angle, "flipX": flipX, "flipZ": flipZ], forKey: "atlasOrientation." + world)
                return
            }
            if message.name == "atlasMarkers" {
                guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.isFileURL == true,
                      let body = message.body as? [String: Any], body["world"] as? String == world,
                      let markers = body["markers"] as? [[String: Any]], markers.count <= 1000,
                      markers.allSatisfy({ marker in
                          guard let name = marker["name"] as? String, name.count <= 60,
                                let x = marker["x"] as? Double, x.isFinite,
                                let z = marker["z"] as? Double, z.isFinite,
                                let dimension = marker["dimension"] as? String, ["o", "n"].contains(dimension) else { return false }
                          return true
                      }) else { return }
                UserDefaults.standard.set(markers, forKey: "atlasMarkers." + scope)
                return
            }
            if message.name == "atlasOwnership" {
                guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.isFileURL == true,
                      let body = message.body as? [String: Any] else { return }
                let key = "conversation.ownedChests." + scope
                let existing = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
                var reply: [String: Any] = ["error": true]
                if let result = ChestOwnership.apply(body, world: world, existing: existing) {
                    UserDefaults.standard.set(result.ids.sorted(), forKey: key)
                    reply = ["ownedIDs": result.ids.sorted(), "changed": result.changed]
                }
                if let data = try? JSONSerialization.data(withJSONObject: reply) {
                    message.webView?.evaluateJavaScript("window.ATLAS_OWNERSHIP?.receive(" + String(decoding: data, as: UTF8.self) + ");", completionHandler: nil)
                }
                return
            }
            guard message.name == "atlasPOINames", message.frameInfo.isMainFrame, let body = message.body as? [String:Any], body["world"] as? String == world,
                  let names = body["names"] as? [String:String], names.count <= 10000,
                  names.allSatisfy({ $0.key.count <= 160 && $0.value.count <= 60 }) else { return }
            UserDefaults.standard.set(names, forKey: "atlasPOI." + scope)
        }
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(action.shouldPerformDownload ? .download : .allow)
        }
        func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) { download.delegate = self }
        func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
            let panel = NSSavePanel(); panel.nameFieldStringValue = suggestedFilename
            panel.begin { result in completionHandler(result == .OK ? panel.url : nil) }
        }
    }
}


struct MapToolsSetup: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    let english: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(english ? "Map & chest tools" : "Karten- & Kistenwerkzeuge",
                  systemImage: maps.ready ? "checkmark.circle.fill" : "map")
                .font(.headline)
            Text(maps.ready
                 ? (english ? "Python, NumPy and Pillow are ready." : "Python, NumPy und Pillow sind bereit.")
                 : (english ? "Install everything for maps and chest searches with one click. No Python installation is needed beforehand." : "Alles für Karten und Kistensuche mit einem Klick installieren. Python muss vorher nicht installiert sein."))
                .font(.callout)
            if maps.installing {
                HStack {
                    ProgressView().controlSize(.small)
                    Text(model.status).font(.callout)
                }
            } else {
                HStack {
                    Button(maps.ready ? (english ? "Reinstall map tools" : "Kartenwerkzeuge neu installieren")
                                      : (english ? "Install map tools" : "Kartenwerkzeuge installieren")) {
                        maps.install(model, english: english)
                    }.buttonStyle(CompanionButtonStyle(prominent: !maps.ready))
                    Button(english ? "Check again" : "Erneut prüfen") { maps.check(model) }
                    if maps.checking { ProgressView().controlSize(.small) }
                }.disabled(model.busy || maps.checking)
            }
            Text(english
                 ? "Internet is needed for installation. Downloads: Python from Astral/GitHub, NumPy and Pillow from PyPI. Installation stays in your user folder; no administrator password is needed. Existing Python installations are unchanged."
                 : "Die Installation benötigt Internet. Downloads: Python von Astral/GitHub, NumPy und Pillow von PyPI. Die Installation erfolgt im Benutzerordner, ohne Administratorpasswort. Vorhandene Python-Installationen bleiben unverändert.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
