import Foundation

enum AppInfo {
    static let repositoryURL = URL(string: "https://github.com/friedensbringer-peacemaker/RealmCraft-Companion")!
    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development" }
    static var title: String { "RealmCraft Companion \(version)" }
}
