import SwiftUI
import AppKit

// Compile with HelpContent, CompanionLookup, HelpView, CompanionStyle and AppInfo only.
// No application model, real library, device or shared preferences are loaded.
@main struct RenderHelp {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let resources = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let articles = try HelpCatalog.load(resources: resources)
        let suite = "HelpRender-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for english in [false, true] {
            for block in [false, true] {
                defaults.set(english ? "en" : "de", forKey: "appLanguage")
                defaults.set(block ? "block" : "classic", forKey: "companionSkin")
                for id in ["maps", "ores", "videos", "metroJourneys", "ore3D", "materialPlan", "builds"] {
                    let article = articles.first { $0.id == id }!
                    let view = VStack(alignment: .leading, spacing: 22) {
                        Label(article.title(english), systemImage: article.icon).font(CompanionLayout.detailTitle)
                        HelpParagraphs(content: article.content(english)).lineSpacing(3)
                        Divider()
                        Text(english ? "Related topics" : "Weiterführende Themen").font(.headline)
                        ForEach(article.related, id: \.self) { id in
                            if let target = articles.first(where: { $0.id == id }) {
                                Label(target.title(english), systemImage: target.icon)
                            }
                        }
                    }.padding(28).frame(width: 640, alignment: .leading)
                        .companionAppearance().defaultAppStorage(defaults)
                        .environment(\.colorScheme, block ? .dark : .light)
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 1
                    guard let image = renderer.cgImage else { fatalError("Help render failed") }
                    precondition(image.width == 640 && image.height > 300)
                    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
                    try data.write(to: output.appendingPathComponent("\(id)-\(english ? "en" : "de")-\(block ? "block" : "classic").png"))
                }
            }
        }
        print("Rendered 28 production help content samples (DE/EN, classic/block); native list/search interaction requires separate acceptance.")
    }
}
