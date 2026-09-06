import SwiftUI
import AppKit
import WebKit

@MainActor final class MapController: ObservableObject {
    @Published var mapURL: URL?
    @Published var ready = false
    @Published var checking = false
    @Published var python = ""
    @Published var notice = ""
    @Published var builtFor = ""
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
    func restoreLast(_ save: Savegame?, radius: String, language: String) {
        mapURL = nil; builtFor = ""; notice = ""
        guard let save, let stored = UserDefaults.standard.string(forKey: "map.\(save.id).\(radius).\(language)") else { return }
        let url = URL(fileURLWithPath: stored).resolvingSymlinksInPath()
        guard url.path.hasPrefix(support.resolvingSymlinksInPath().path + "/"), FileManager.default.fileExists(atPath: url.path), FileManager.default.fileExists(atPath: url.deletingLastPathComponent().appendingPathComponent("biomes.js").path) else { return }
        // Refresh only the viewer assets; cached world data and map tiles stay intact.
        let directory = url.deletingLastPathComponent()
        let stamp = directory.appendingPathComponent(".viewer-version")
        let viewerVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown") + ":annotations-2-signs-1:" + language
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
        guard ready else { return }
        let english = language == "en", backend = model.library, interpreter = python
        let output = support.appendingPathComponent(save.id).appendingPathComponent(UUID().uuidString)
        let cache = support.appendingPathComponent("cache")
        guard let engine = Bundle.main.resourceURL?.appendingPathComponent("MapEngine") else { return }
        notice = ""
        model.work(english ? "Generating map from the selected backup…" : "Karte aus der ausgewählten Sicherung wird erstellt …") {
            _ = try backend.verify(save)
            DispatchQueue.main.async { model.status = english ? "Rendering map and locating interesting places…" : "Karte und interessante Orte werden berechnet …" }
            var arguments = ["-I", "-B", "-u", "-c", "import sys; sys.path.insert(0, sys.argv.pop(1)); from realmcraft_map.__main__ import main; raise SystemExit(main())", engine.path, backend.worldFolder(save).path, "--output", output.path, "--workers", "8", "--cache", cache.path]
            if radius != "all" { arguments += ["--radius", radius] }
            let result = try backend.run(interpreter, arguments, timeout: 3600)
            guard result.code == 0 || result.code == 2 else { throw LibraryError(String(result.output.suffix(4000))) }
            _ = try backend.verify(save)
            let index = output.appendingPathComponent("index.html")
            guard FileManager.default.fileExists(atPath: index.path) else { throw LibraryError(english ? "No map was produced." : "Es wurde keine Karte erzeugt.") }
            if english { try MapLocalization.english(output) }
            UserDefaults.standard.set(index.path, forKey: "map.\(save.id).\(radius).\(language)")
            DispatchQueue.main.async {
                self.mapURL = index; self.builtFor = save.title
                self.notice = result.code == 2 ? (english ? "Some chunks could not be read. This map has gaps; see audit.json in the map folder." : "Einige Chunks konnten nicht gelesen werden. Die Karte hat Lücken; Details stehen in audit.json im Kartenordner.") : ""
            }
            return english ? "Map generated. Your savegame is unchanged." : "Karte erzeugt. Dein Spielstand ist unverändert."
        }
    }
}

struct MapsView: View {
    @Environment(\.companionTheme) private var theme
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    let language: String
    @State private var radius = "128"
    private var english: Bool { language == "en" }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Maps" : "Karten") {
                    Button(english ? "Generate map" : "Karte erzeugen") { if let save = model.selected { maps.generate(model, save: save, radius: radius, language: language) } }
                        .buttonStyle(CompanionButtonStyle(prominent: true)).disabled(model.busy || !maps.ready || model.selected == nil || maps.checking)

                Menu {
                    Button(english ? "Open in browser" : "Im Browser öffnen") { if let url = maps.mapURL { NSWorkspace.shared.open(url) } }
                    Button(english ? "Show in Finder" : "Im Finder anzeigen") { if let url = maps.mapURL { NSWorkspace.shared.activateFileViewerSelecting([url]) } }
                } label: { Image(systemName: "ellipsis.circle") }.fixedSize().menuStyle(.borderlessButton).disabled(maps.mapURL == nil)
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Picker(english ? "Savegame" : "Spielstand", selection: $model.selection) {
                        if model.saves.isEmpty { Text(english ? "No savegames" : "Keine Spielstände").tag(nil as String?) }
                        ForEach(model.saves) { save in Text(save.title + " · " + displayDate(save.date, language: language)).tag(Optional(save.id)) }
                    }.frame(maxWidth: 440)
                    Picker(english ? "Area" : "Bereich", selection: $radius) {
                        Text(english ? "Origin ±128 blocks" : "Ursprung ±128 Blöcke").tag("128")
                        Text(english ? "Origin ±256 blocks" : "Ursprung ±256 Blöcke").tag("256")
                        Text(english ? "Origin ±512 blocks" : "Ursprung ±512 Blöcke").tag("512")
                        Text(english ? "Origin ±1024 blocks" : "Ursprung ±1024 Blöcke").tag("1024")
                        Text(english ? "Origin ±2048 blocks" : "Ursprung ±2048 Blöcke").tag("2048")
                        Text(english ? "All saved chunks" : "Alle gespeicherten Chunks").tag("all")
                    }.frame(width: 220)
                    Spacer(minLength: 0)

                }.disabled(model.busy)
                Text(model.busy ? tr(model.status) : english ? "Maps are built locally from saved chunks, not live Quest data. Large worlds can take several minutes. Colors are schematic; unknown blocks may differ." : "Karten entstehen lokal aus gespeicherten Chunks, nicht aus Live-Daten der Quest. Große Welten können mehrere Minuten dauern. Farben sind schematisch; unbekannte Blöcke können abweichen.").font(.caption).foregroundStyle(.secondary).frame(height: 24, alignment: .leading)
                if !maps.ready || maps.installing {
                    MapToolsSetup(model: model, maps: maps, english: english)
                }
                if !maps.notice.isEmpty { Text(maps.notice).font(.callout).foregroundStyle(.orange) }
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            Divider()
            if let url = maps.mapURL { LocalMapWebView(url: url, world: model.selected?.world ?? "", scope: model.selected?.annotationScope ?? "").id(url) }
            else {
                VStack(spacing: 14) {
                    Image(systemName: "map.fill").font(.system(size: 50)).foregroundStyle(theme.accent)
                    Text(english ? "Explore a saved world" : "Eine gesicherte Welt erkunden").font(.title.bold())
                    Text(english ? "Choose a backup and generate its map. Start with the area around the origin for a quick preview." : "Wähle eine Sicherung und erzeuge ihre Karte. Die Umgebung des Ursprungs eignet sich für eine schnelle Vorschau.").foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 500)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { maps.check(model); maps.restoreLast(model.selected, radius: radius, language: language) }
        .onChange(of: model.selection) { _, _ in maps.restoreLast(model.selected, radius: radius, language: language) }
        .onChange(of: radius) { _, _ in maps.restoreLast(model.selected, radius: radius, language: language) }
        .onChange(of: language) { _, _ in maps.restoreLast(model.selected, radius: radius, language: language) }
    }
}
private struct LocalMapWebView: NSViewRepresentable {
    let url: URL
    let world: String
    let scope: String
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
    func makeCoordinator() -> Coordinator { Coordinator(world: world, scope: scope) }
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(WKUserScript(source: privacyScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let markerValue: Any = UserDefaults.standard.object(forKey: "atlasMarkers." + scope) ?? (scope == world ? NSNull() : [] as Any)
        let orientation = UserDefaults.standard.dictionary(forKey: "atlasOrientation." + world) ?? [:]
        let orientationData = try! JSONSerialization.data(withJSONObject: orientation)
        configuration.userContentController.addUserScript(WKUserScript(source: "window.ATLAS_NATIVE_ORIENTATION=" + String(decoding: orientationData, as: UTF8.self) + ";", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(context.coordinator, name: "atlasOrientation")
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
        context.coordinator.styleScript = styleScript + privacyScript
        if !view.isLoading { view.evaluateJavaScript(styleScript + privacyScript, completionHandler: nil) }
    }
    static func dismantleNSView(_ view: WKWebView, coordinator: Coordinator) { view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasOrientation"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasMarkers"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasPOINames"); view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasOwnership") }
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKDownloadDelegate {
        let world: String
        let scope: String
        var styleScript = ""
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(styleScript, completionHandler: nil)
        }
        init(world: String, scope: String) { self.world = world; self.scope = scope }
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
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
