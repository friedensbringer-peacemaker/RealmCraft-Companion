import SwiftUI
import CryptoKit

// Version-pinned, optional downloads. Only mapped textures and original credits are installed.
enum IconPack: String, CaseIterable, Identifiable {
    case kenney, pixel
    var id: String { rawValue }
    var title: String { self == .kenney ? "Kenney Voxel Pack" : "Pixel Perfection Legacy" }
    var version: String { self == .kenney ? "1.0" : "26.2-88.0-1" }
    var author: String { self == .kenney ? "Kenney Vleugels / Kenney" : "XSSheep, Nova_Wostra, freejusticehere, HexaBlu" }
    var license: String { self == .kenney ? "CC0" : "CC BY-SA 4.0 / CC BY 4.0" }
    var size: String { self == .kenney ? "1.3 MB" : "36.5 MB" }
    var source: URL { URL(string: self == .kenney ? "https://kenney.nl/assets/voxel-pack" : "https://modrinth.com/resourcepack/pixel-perfection-legacy")! }
    var licenseURL: URL { URL(string: self == .kenney ? "https://creativecommons.org/publicdomain/zero/1.0/" : "https://creativecommons.org/licenses/by-sa/4.0/")! }
    var downloadURL: URL { URL(string: self == .kenney
        ? "https://kenney.nl/media/pages/assets/voxel-pack/a3a73d0ff7-1677662501/kenney_voxel-pack.zip"
        : "https://cdn.modrinth.com/data/6w3F4SEu/versions/M27tmode/Pixel%20Perfection%20Legacy%2026.2-88.0-1.zip")! }
    var digest: String { self == .kenney
        ? "667c05e3f6d95718aaef888c7fc06f7137ba5dede95f4574deb17d4436257958"
        : "be579ea5be914b0673ecdde0a869a0ddca6c6653b732b3193e86a760579105d6" }
    var folder: String { self == .kenney ? "KenneyVoxel-1" : "PixelPerfection-26.2-88.0-1" }
    var manifest: String { self == .kenney ? "ItemIcons" : "PixelItemIcons" }
    var creditFile: String { self == .kenney ? "License.txt" : "pack.txt" }
    static var root: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RealmCraftCompanion/OptionalAssets", isDirectory: true)
    }
    func terms(_ english: Bool) -> String {
        if self == .kenney {
            return english ? "CC0: personal and commercial use; attribution is optional." : "CC0: privat und kommerziell nutzbar; Namensnennung ist freiwillig."
        }
        return english
            ? "Original artwork: CC BY-SA 4.0. Modrinth also lists CC BY 4.0. We retain both notices and follow the ShareAlike terms: credit, license links and the same license for adaptations. Original credits remain installed with the pack."
            : "Originalgrafiken: CC BY-SA 4.0. Modrinth nennt zusätzlich CC BY 4.0. Wir behalten beide Angaben bei und beachten ShareAlike: Namensnennung, Lizenzlinks und dieselbe Lizenz für Bearbeitungen. Die Original-Credits bleiben beim Pack erhalten."
    }
    var licenseNotice: String {
        "# \(title) · \(version)\n\nAuthors: \(author)\nSource: \(source.absoluteString)\nLicense: \(license)\n\(licenseURL.absoluteString)\n\n\(terms(true))\n\nSelected PNG textures are used unchanged. No shaders, sound, game code or third-party add-ons are installed. These assets are separate from the Companion source-code license.\n"
        + (self == .pixel ? "\nhttps://creativecommons.org/licenses/by/4.0/\nhttps://www.curseforge.com/minecraft/texture-packs/pixel-perfection-legacy/license\nSee pack.txt for the original contributor credits.\n" : "")
    }
    func mapping(at url: URL?) -> [String: String] {
        guard let url, let data = try? Data(contentsOf: url),
              let values = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return values.filter { ($0.value.hasPrefix("PNG/") || $0.value.hasPrefix("assets/minecraft/textures/")) && !$0.value.contains("..") && $0.value.hasSuffix(".png") }
    }
    func validInstallation(at root: URL, mapping: [String: String]) -> Bool {
        guard !mapping.isEmpty,
              (try? String(contentsOf: root.appendingPathComponent("verified.sha256"), encoding: .utf8)) == digest,
              FileManager.default.fileExists(atPath: root.appendingPathComponent(creditFile).path) else { return false }
        return mapping.values.allSatisfy { NSImage(contentsOf: root.appendingPathComponent($0)) != nil }
    }
    func install(archive: URL, destination: URL, mapping: [String: String]) throws {
        let data = try Data(contentsOf: archive, options: .mappedIfSafe)
        guard data.count < 60_000_000,
              SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == digest else {
            throw NSError(domain: "VoxelPack", code: 1, userInfo: [NSLocalizedDescriptionKey: "The download does not match the verified pack. / Der Download entspricht nicht dem geprüften Grafikpaket."])
        }
        let fm = FileManager.default
        let stage = destination.deletingLastPathComponent().appendingPathComponent(".voxel-\(UUID().uuidString)")
        try fm.createDirectory(at: stage, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: stage) }
        // Only this exact, hash-verified archive is extracted. No arbitrary ZIP imports.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", archive.path] + Array(Set(mapping.values)).sorted() + [creditFile, "-d", stage.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw CocoaError(.fileReadCorruptFile) }
        try licenseNotice.write(to: stage.appendingPathComponent("Companion-LICENSE.md"), atomically: true, encoding: .utf8)
        try digest.write(to: stage.appendingPathComponent("verified.sha256"), atomically: true, encoding: .utf8)
        guard validInstallation(at: stage, mapping: mapping) else { throw CocoaError(.fileReadCorruptFile) }
        if fm.fileExists(atPath: destination.path) {
            _ = try fm.replaceItemAt(destination, withItemAt: stage)
        } else {
            try fm.moveItem(at: stage, to: destination)
        }
    }
}

@MainActor final class ItemIconStore: ObservableObject {
    static let shared = ItemIconStore()
    @Published private(set) var installed: Set<IconPack> = []
    @Published private(set) var downloading: IconPack?
    @Published var error: String?
    var busy: Bool { downloading != nil }
    let root: URL
    let defaults: UserDefaults
    private let mappings: [IconPack: [String: String]]
    private var images: [String: NSImage] = [:]
    init(root: URL = IconPack.root, resources: URL = Bundle.main.resourceURL!, defaults: UserDefaults = .standard) {
        self.root = root; self.defaults = defaults
        mappings = Dictionary(uniqueKeysWithValues: IconPack.allCases.map { ($0, $0.mapping(at: resources.appendingPathComponent($0.manifest + ".json"))) })
        refresh()
    }
    var activePack: IconPack { IconPack(rawValue: defaults.string(forKey: "companionIconPack") ?? "kenney") ?? .kenney }
    func directory(_ pack: IconPack) -> URL { root.appendingPathComponent(pack.folder) }
    func count(_ pack: IconPack) -> Int { mappings[pack]?.count ?? 0 }
    func refresh() {
        installed = Set(IconPack.allCases.filter { $0.validInstallation(at: directory($0), mapping: mappings[$0] ?? [:]) })
        images.removeAll()
    }
    func image(for id: Int, pack: IconPack) -> NSImage? {
        guard installed.contains(pack), let path = mappings[pack]?[String(id)] else { return nil }
        let key = "\(pack.rawValue):\(id)"
        if let image = images[key] { return image }
        guard let image = NSImage(contentsOf: directory(pack).appendingPathComponent(path)) else { return nil }
        images[key] = image
        return image
    }
    func activate(_ pack: IconPack) {
        guard installed.contains(pack), !busy else { return }
        defaults.set(pack.rawValue, forKey: "companionIconPack")
        defaults.set(true, forKey: "companionItemIcons")
        objectWillChange.send()
    }
    func download(_ pack: IconPack) {
        guard !busy else { return }
        downloading = pack; error = nil
        Task {
            defer { downloading = nil }
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 180
            let session = URLSession(configuration: config)
            defer { session.invalidateAndCancel() }
            do {
                let (file, response) = try await session.download(from: pack.downloadURL)
                defer { try? FileManager.default.removeItem(at: file) }
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
                let mapping = mappings[pack] ?? [:]
                let destination = directory(pack)
                try await Task.detached(priority: .utility) {
                    try pack.install(archive: file, destination: destination, mapping: mapping)
                }.value
                refresh()
                downloading = nil
                activate(pack)
            } catch { self.error = error.localizedDescription }
        }
    }
    func remove(_ pack: IconPack) {
        guard !busy else { return }
        error = nil
        do {
            if FileManager.default.fileExists(atPath: directory(pack).path) { try FileManager.default.removeItem(at: directory(pack)) }
            if activePack == pack { defaults.set(false, forKey: "companionItemIcons") }
            refresh()
        } catch { self.error = error.localizedDescription }
    }
}

struct ItemIcon: View {
    let itemID: Int
    @ObservedObject var store = ItemIconStore.shared
    @AppStorage("companionItemIcons") private var enabled = false
    @AppStorage("companionIconPack") private var selectedPack = "kenney"
    var body: some View {
        if enabled, let image = store.image(for: itemID, pack: IconPack(rawValue: selectedPack) ?? .kenney) {
            Image(nsImage: image).resizable().interpolation(.none).scaledToFit()
                .frame(width: 32, height: 32).accessibilityHidden(true)
        }
    }
}

struct ItemIconSettings: View {
    let english: Bool
    @ObservedObject var store = ItemIconStore.shared
    @AppStorage("companionItemIcons") private var enabled = false
    @AppStorage("companionIconPack") private var active = "kenney"
    @State private var inspected: IconPack = .kenney
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(english ? "Item icons" : "Gegenstands-Icons").font(.title2.bold())
                Spacer()
                Button(english ? "Done" : "Fertig") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            Picker(english ? "Display" : "Anzeige", selection: $enabled) {
                Text(english ? "Text only" : "Nur Text").tag(false)
                Text(english ? "Icons + text" : "Icons + Text").tag(true)
                    .disabled(!store.installed.contains(IconPack(rawValue: active) ?? .kenney))
            }.pickerStyle(.segmented).disabled(store.busy)
            Text(enabled && store.installed.contains(IconPack(rawValue: active) ?? .kenney)
                 ? (english ? "Active: " : "Aktiv: ") + (IconPack(rawValue: active) ?? .kenney).title
                 : (english ? "Active: text only" : "Aktiv: Nur Text")).font(.caption).foregroundStyle(.secondary)
            Divider()
            Picker(english ? "Graphics pack" : "Grafikpaket", selection: $inspected) {
                ForEach(IconPack.allCases) { pack in Text(pack.title).tag(pack) }
            }.disabled(store.busy)
            Text("\(inspected.version) · \(store.count(inspected)) " + (english ? "mapped items / blocks" : "zugeordnete Gegenstände / Blöcke") + " · \(inspected.size)")
                .font(.caption).foregroundStyle(.secondary)
            Text(inspected.author).font(.callout)
            Text(inspected.license).font(.headline)
            Text(inspected.terms(english)).font(.callout)
            HStack {
                Link(english ? "Pack & source" : "Pack & Quelle", destination: inspected.source)
                Link(english ? "License" : "Lizenz", destination: inspected.licenseURL)
                if inspected == .pixel { Link("CC BY 4.0", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!) }
            }
            Text(english ? "Independent artwork, not original RealmCraft graphics. Block textures are shown in 2D. Unmatched items keep their text labels." : "Eigenständige Grafiken, keine RealmCraft-Originalgrafiken. Blocktexturen werden in 2D angezeigt. Gegenstände ohne Zuordnung bleiben Text.")
                .font(.caption).foregroundStyle(.secondary)
            if store.installed.contains(inspected) {
                HStack(spacing: 16) {
                    ForEach([3022, 3000, 3047, 1], id: \.self) { id in
                        if let image = store.image(for: id, pack: inspected) {
                            Image(nsImage: image).resizable().interpolation(.none).scaledToFit().frame(width: 36, height: 36)
                        }
                    }
                    Spacer()
                    Text(english ? "Pack preview" : "Pack-Vorschau").font(.caption).foregroundStyle(.secondary)
                }.padding(12).companionPanel()
                HStack {
                    Button(english ? "Use this pack" : "Dieses Pack nutzen") { store.activate(inspected) }
                    Spacer()
                    Button(english ? "Remove pack" : "Pack entfernen", role: .destructive) { store.remove(inspected) }
                }.disabled(store.busy)
                Text(english ? "Installed · offline available. Other installed packs are retained." : "Installiert · offline verfügbar. Andere installierte Packs bleiben erhalten.").font(.caption).foregroundStyle(.secondary)
            } else {
                Text(english ? "Downloaded only when you choose Download & use. Your current display stays active until installation succeeds." : "Download erst mit „Herunterladen & nutzen“. Deine aktuelle Anzeige bleibt bis zur erfolgreichen Installation aktiv.").font(.caption)
                Button(english ? "Download & use" : "Herunterladen & nutzen") { store.download(inspected) }.disabled(store.busy)
            }
            if let pack = store.downloading {
                HStack { ProgressView().controlSize(.small); Text((english ? "Downloading and verifying: " : "Download und Prüfung: ") + pack.title).font(.caption) }
            }
            if let error = store.error { Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled) }
        }.padding(24).frame(width: 610).fixedSize(horizontal: false, vertical: true)
        .onAppear { store.refresh(); inspected = IconPack(rawValue: active) ?? .kenney }
    }
}
