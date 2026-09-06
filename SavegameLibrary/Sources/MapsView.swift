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
    var runtime: URL { support.appendingPathComponent("runtime/bin/python3") }
    func discoverPython() -> String? {
        let fm = FileManager.default
        return [runtime.path, "/Library/Frameworks/Python.framework/Versions/Current/bin/python3", "/usr/local/bin/python3", "/opt/homebrew/bin/python3"]
            .first { fm.isExecutableFile(atPath: $0) }
    }
    func check(_ model: Model) {
        guard !checking && !model.busy else { return }; checking = true
        let backend = model.library
        let candidate = discoverPython()
        model.queue.async {
            let result = candidate.flatMap { try? backend.run($0, ["-c", "import sys; assert sys.version_info >= (3,10); import numpy; from PIL import Image"], timeout: 20) }
            DispatchQueue.main.async {
                self.python = candidate ?? ""; self.ready = result?.code == 0; self.checking = false
            }
        }
    }
    func install(_ model: Model, english: Bool) {
        guard let base = ["/Library/Frameworks/Python.framework/Versions/Current/bin/python3", "/usr/local/bin/python3", "/opt/homebrew/bin/python3"].first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else { return }
        let backend = model.library, folder = support.appendingPathComponent("runtime"), executable = runtime.path
        model.work(english ? "Preparing map tools…" : "Kartenwerkzeuge werden eingerichtet …", lockLibrary: false) {
            try FileManager.default.createDirectory(at: self.support, withIntermediateDirectories: true)
            _ = try backend.checked(base, ["-m", "venv", folder.path], timeout: 180)
            _ = try backend.checked(executable, ["-m", "pip", "install", "--disable-pip-version-check", "--index-url", "https://pypi.org/simple", "numpy>=2,<3", "Pillow>=10.4,<13"], timeout: 600)
            _ = try backend.checked(executable, ["-c", "import numpy; from PIL import Image"], timeout: 30)
            DispatchQueue.main.async { self.python = executable; self.ready = true }
            return english ? "Map tools are ready." : "Kartenwerkzeuge sind bereit."
        }
    }
    func restoreLast(_ save: Savegame?, radius: String, language: String) {
        mapURL = nil; builtFor = ""; notice = ""
        guard let save, let stored = UserDefaults.standard.string(forKey: "map.\(save.id).\(radius).\(language)") else { return }
        let url = URL(fileURLWithPath: stored).resolvingSymlinksInPath()
        guard url.path.hasPrefix(support.resolvingSymlinksInPath().path + "/"), FileManager.default.fileExists(atPath: url.path), FileManager.default.fileExists(atPath: url.deletingLastPathComponent().appendingPathComponent("biomes.js").path) else { return }
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
            var arguments = ["-u", "-c", "import sys; sys.path.insert(0, sys.argv.pop(1)); from realmcraft_map.__main__ import main; raise SystemExit(main())", engine.path, backend.worldFolder(save).path, "--output", output.path, "--workers", "8", "--cache", cache.path]
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
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    let language: String
    @State private var radius = "128"
    private var english: Bool { language == "en" }
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(english ? "World maps" : "Weltkarten", systemImage: "map").font(.title2.bold())
                    Text(english ? "Atlas · Preview" : "Atlas · Vorschau").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if let url = maps.mapURL {
                        Button(english ? "Open in browser" : "Im Browser öffnen") { NSWorkspace.shared.open(url) }
                        Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: { Image(systemName: "folder") }
                    }
                }
                HStack {
                    Picker(english ? "Savegame" : "Spielstand", selection: $model.selection) {
                        if model.saves.isEmpty { Text(english ? "No savegames" : "Keine Spielstände").tag(nil as String?) }
                        ForEach(model.saves) { save in Text(save.title + " · " + displayDate(save.date, language: language)).tag(Optional(save.id)) }
                    }.frame(maxWidth: 500)
                    Picker(english ? "Area" : "Bereich", selection: $radius) {
                        Text(english ? "Origin ±128 blocks" : "Ursprung ±128 Blöcke").tag("128")
                        Text(english ? "Origin ±512 blocks" : "Ursprung ±512 Blöcke").tag("512")
                        Text(english ? "All saved chunks" : "Alle gespeicherten Chunks").tag("all")
                    }.frame(maxWidth: 300)
                    Button(english ? "Generate map" : "Karte erzeugen") { if let save = model.selected { maps.generate(model, save: save, radius: radius, language: language) } }
                        .buttonStyle(.borderedProminent).disabled(!maps.ready || model.selected == nil || maps.checking)
                }.disabled(model.busy)
                Text(english ? "Maps are built locally from saved chunks, not live Quest data. Large worlds can take several minutes. Colors are schematic; unknown blocks may differ." : "Karten entstehen lokal aus gespeicherten Chunks, nicht aus Live-Daten der Quest. Große Welten können mehrere Minuten dauern. Farben sind schematisch; unbekannte Blöcke können abweichen.").font(.caption).foregroundStyle(.secondary)
                if !maps.ready {
                    HStack {
                        Text(maps.checking ? (english ? "Checking map tools…" : "Kartenwerkzeuge werden geprüft …") : maps.python.isEmpty ? (english ? "Install Python 3.10 or newer first, then check again." : "Zuerst Python 3.10 oder neuer installieren, danach erneut prüfen.") : (english ? "Set up NumPy and Pillow in a separate map environment." : "NumPy und Pillow in einer separaten Kartenumgebung einrichten.")).font(.callout)
                        Spacer()
                        if !maps.python.isEmpty { Button(english ? "Set up map tools" : "Kartenwerkzeuge einrichten") { maps.install(model, english: english) } }
                        else { Link("Python.org", destination: URL(string: "https://www.python.org/downloads/macos/")!) }
                        Button(english ? "Check again" : "Erneut prüfen") { maps.check(model) }
                    }.disabled(model.busy || maps.checking)
                }
                if !maps.notice.isEmpty { Text(maps.notice).font(.callout).foregroundStyle(.orange) }
                if model.busy { HStack { ProgressView().controlSize(.small); Text(tr(model.status)).font(.callout) } }
            }.padding(20)
            Divider()
            if let url = maps.mapURL { LocalMapWebView(url: url, world: model.selected?.world ?? "").id(url) }
            else {
                VStack(spacing: 14) {
                    Image(systemName: "map.fill").font(.system(size: 50)).foregroundStyle(.teal)
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
    func makeCoordinator() -> Coordinator { Coordinator(world: world) }
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let names = UserDefaults.standard.dictionary(forKey: "atlasPOI." + world) ?? [:]
        let data = (try? JSONSerialization.data(withJSONObject: names)) ?? Data("{}".utf8)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        configuration.userContentController.addUserScript(WKUserScript(source: "window.ATLAS_NATIVE_NAMES=" + json + ";", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(context.coordinator, name: "atlasPOINames")
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return view
    }
    func updateNSView(_ view: WKWebView, context: Context) {}
    static func dismantleNSView(_ view: WKWebView, coordinator: Coordinator) { view.configuration.userContentController.removeScriptMessageHandler(forName: "atlasPOINames") }
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKDownloadDelegate {
        let world: String
        init(world: String) { self.world = world }
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame, let body = message.body as? [String:Any], body["world"] as? String == world,
                  let names = body["names"] as? [String:String], names.count <= 10000,
                  names.allSatisfy({ $0.key.count <= 160 && $0.value.count <= 60 }) else { return }
            UserDefaults.standard.set(names, forKey: "atlasPOI." + world)
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
