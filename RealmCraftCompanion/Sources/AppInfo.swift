import Foundation

enum AppInfo {
    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development" }
    static var title: String { "RealmCraft Companion \(version)" }
}
