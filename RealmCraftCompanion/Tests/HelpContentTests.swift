import Foundation

@main struct HelpContentTests {
    static func main() throws {
        let resources = URL(fileURLWithPath: CommandLine.arguments[1])
        let articles = try HelpCatalog.load(resources: resources)
        var checks = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            precondition(condition(), message); checks += 1
        }
        func rejects(_ values: [HelpArticle]) {
            do { try HelpCatalog.validate(values); preconditionFailure("Invalid catalog accepted") }
            catch { checks += 1 }
        }
        func sample(_ id: String, de: String = "Größe der Oberfläche", en: String = "Surface size", related: [String] = []) -> HelpArticle {
            HelpArticle(id: id, icon: "book", category: .gettingStarted, deTitle: "Einstieg", enTitle: "Start", de: de, en: en, deResource: nil, enResource: nil, related: related)
        }
        let ids = Set(articles.map(\.id))
        let legacy = Set("start companion setup appearance library backup restore zip player maps navigation places biomes ores tectonicus chests statistics editor aiExport conversation skills videos builds crafting mobs resources trouble feedback agent origin privacy development windows manualTransfer updates backlog".split(separator: " ").map(String.init))
        check(legacy.isSubset(of: ids), "Existing saved topic IDs must remain valid")
        for id in "start library player maps ores portals metro tectonicus chests statistics editor aiExport conversation skills videos builds crafting mobs resources companion".split(separator: " ") {
            check(ids.contains(String(id)), "Missing navigation coverage: \(id)")
        }
        let order = HelpCategory.allCases
        let categoryIndices = articles.map { order.firstIndex(of: $0.category)! }
        check(categoryIndices == categoryIndices.sorted(), "Topics must follow category order")
        for article in articles {
            check(!HelpBlock.parse(article.de).isEmpty && !HelpBlock.parse(article.en).isEmpty, "Both languages must render")
            check(!article.related.isEmpty, "Every topic needs a next step")
        }
        let samples = [sample("start"), sample("metro", de: "Gemessene Fahrt", en: "Measured journey")]
        check(HelpCatalog.filtered(samples, query: "  GROßE   oberflache ").map(\.id) == ["start"], "Case, accents and all-token matching")
        check(HelpCatalog.filtered(samples, query: "measured JOURNEY").map(\.id) == ["metro"], "English search must work independently of UI language")
        check(HelpCatalog.filtered(samples, query: "gemessene").map(\.id) == ["metro"], "German search")
        check(HelpCatalog.filtered(samples, query: "   \n ") == samples, "Empty search")
        check(HelpCatalog.filtered(samples, query: "journey surface").isEmpty, "Do not combine words across articles")
        check(HelpCatalog.visibleID(selected: "metro", in: samples) == "metro", "Keep selected match")
        check(HelpCatalog.visibleID(selected: "metro", in: [samples[0]]) == "start", "Select a matching topic after filtering")
        check(HelpCatalog.visibleID(selected: "start", in: []) == nil, "No hits must not show stale content")
        check(HelpCatalog.visibleID(selected: "removed", in: samples) == "start", "Recover invalid saved selection")
        rejects([]); rejects([sample("other")]); rejects([sample("start"), sample("start")])
        rejects([sample("start", en: " \n ")]); rejects([sample("start", related: ["missing"])])
        rejects([sample("start", related: ["start"])])
        rejects([sample("start", related: ["metro", "metro"]), sample("metro")])
        let parsed = HelpBlock.parse("# Heading\n\nWrapped first\nsecond line\n\n1. First item\n- Second item\n\nLIMITS\n\nFinal text.")
        check(parsed == [.heading("Heading"), .paragraph("Wrapped first\nsecond line"), .item(marker: "1.", text: "First item"), .item(marker: "•", text: "Second item"), .heading("LIMITS"), .paragraph("Final text.")], "Production paragraph/list parser")
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("help-tests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        func rejectsDocument(_ data: Data) throws {
            try data.write(to: temp.appendingPathComponent("HelpArticles.json"))
            do { _ = try HelpCatalog.load(resources: temp); preconditionFailure("Invalid resource accepted") }
            catch { checks += 1 }
        }
        try rejectsDocument(JSONEncoder().encode(HelpCatalog.Document(schema: 2, articles: [sample("start")])))
        let unsafe = HelpArticle(id: "start", icon: "book", category: .gettingStarted, deTitle: "Start", enTitle: "Start", de: "Text", en: "Text", deResource: "../private", enResource: nil, related: [])
        try rejectsDocument(JSONEncoder().encode(HelpCatalog.Document(schema: 1, articles: [unsafe])))
        try rejectsDocument(Data("{broken".utf8))
        let missing = HelpArticle(id: "start", icon: "book", category: .gettingStarted, deTitle: "Start", enTitle: "Start", de: "Text", en: "Text", deResource: "SETUP-de", enResource: nil, related: [])
        try rejectsDocument(JSONEncoder().encode(HelpCatalog.Document(schema: 1, articles: [missing])))
        for language in ["de", "en"] {
            let setup = try String(contentsOf: resources.appendingPathComponent("SETUP-\(language).md"), encoding: .utf8)
            let agent = try String(contentsOf: resources.appendingPathComponent("AGENT-SETUP-\(language).md"), encoding: .utf8)
            check(agent.hasSuffix(setup), "Embedded setup must match standalone guide exactly")
            check(agent.count > setup.count, "Preserve independent agent safety instructions")
        }
        print("Help catalog: \(articles.count) bilingual topics, \(checks) checks passed")
    }
}
