import Foundation
import Combine
import CryptoKit

struct CompanionActivityRecord: Codable, Equatable {
    var date: Date
    var saveID: String
    var title: String
    var path: String
    var radius: String? = nil
    var language: String? = nil
    var recovered = false
}
@MainActor final class CompanionActivity: ObservableObject {
    static let shared = CompanionActivity()
    @Published private(set) var revision = 0
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    nonisolated static func namespace(_ root: URL) -> String {
        SHA256.hash(data: Data(root.resolvingSymlinksInPath().standardizedFileURL.path.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    private func key(_ kind: String, root: URL) -> String { "companion.activity.\(Self.namespace(root)).\(kind)" }
    func latest(_ kind: String, root: URL) -> CompanionActivityRecord? {
        guard let data = defaults.data(forKey: key(kind, root: root)) else { return nil }
        return try? JSONDecoder().decode(CompanionActivityRecord.self, from: data)
    }
    func record(_ item: CompanionActivityRecord, kind: String, root: URL) {
        if let old = latest(kind, root: root), old.date > item.date { return }
        if let data = try? JSONEncoder().encode(item) { defaults.set(data, forKey: key(kind, root: root)); revision += 1 }
    }
    func recoverMap(saves: [(id: String, title: String)], root: URL, support: URL) {
        guard latest("map", root: root) == nil else { return }
        let allowed = support.resolvingSymlinksInPath().standardizedFileURL.path + "/"
        var newest: CompanionActivityRecord?
        for save in saves {
            for radius in ["128", "256", "512", "1024", "2048", "all"] {
                for language in ["de", "en"] {
                    guard let path = defaults.string(forKey: "map.\(save.id).\(radius).\(language)") else { continue }
                    let index = URL(fileURLWithPath: path).resolvingSymlinksInPath()
                    let folder = index.deletingLastPathComponent()
                    guard index.path.hasPrefix(allowed), FileManager.default.fileExists(atPath: index.path),
                          FileManager.default.fileExists(atPath: folder.appendingPathComponent("biomes.js").path),
                          let date = try? folder.resourceValues(forKeys: [.creationDateKey]).creationDate else { continue }
                    let candidate = CompanionActivityRecord(date: date, saveID: save.id, title: save.title, path: index.path, radius: radius, language: language, recovered: true)
                    if newest == nil || candidate.date > newest!.date { newest = candidate }
                }
            }
        }
        if let newest { record(newest, kind: "map", root: root) }
    }
}

enum CompanionExportArchive {
    static var support: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/RealmCraftLibrary/AIExports") }
    static func write(markdown: String, json: Data, root: URL, videoMarkdown: String? = nil, support: URL = support) throws -> URL {
        let parent = support.appendingPathComponent(CompanionActivity.namespace(root))
        let resolved = parent.resolvingSymlinksInPath().standardizedFileURL.path
        let library = root.resolvingSymlinksInPath().standardizedFileURL.path
        guard resolved != library, !resolved.hasPrefix(library + "/") else { throw CocoaError(.fileWriteInvalidFileName) }
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let staging = parent.appendingPathComponent(".pending-" + UUID().uuidString)
        let target = parent.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: staging) }
        try Data(markdown.utf8).write(to: staging.appendingPathComponent("context.md"), options: .atomic)
        if let videoMarkdown { try Data(videoMarkdown.utf8).write(to: staging.appendingPathComponent("videos.md"), options: .atomic) }
        try json.write(to: staging.appendingPathComponent("context.json"), options: .atomic)
        try FileManager.default.moveItem(at: staging, to: target)
        return target.appendingPathComponent("context.md")
    }
    static func read(_ record: CompanionActivityRecord, root: URL, support: URL = support) throws -> AIContextDocument {
        let file = URL(fileURLWithPath: record.path).resolvingSymlinksInPath()
        let allowed = support.appendingPathComponent(CompanionActivity.namespace(root)).resolvingSymlinksInPath().path + "/"
        guard file.path.hasPrefix(allowed) else { throw CocoaError(.fileReadNoPermission) }
        let json = try Data(contentsOf: file.deletingLastPathComponent().appendingPathComponent("context.json"))
        guard let payload = try JSONSerialization.jsonObject(with: json) as? [String: Any] else { throw CocoaError(.fileReadCorruptFile) }
        let videos = payload["videoKnowledge"] as? [String: Any]
        let videoMarkdown = videos?["separateMarkdownFile"] as? Bool == true ? videos?["markdown"] as? String : nil
        return AIContextDocument(payload: payload, markdown: try String(contentsOf: file, encoding: .utf8), videoMarkdown: (try? String(contentsOf: file.deletingLastPathComponent().appendingPathComponent("videos.md"), encoding: .utf8)) ?? videoMarkdown)
    }
}
