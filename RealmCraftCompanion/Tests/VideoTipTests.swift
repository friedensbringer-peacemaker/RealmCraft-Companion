import Foundation

@main struct VideoTipTests {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let source = root.appendingPathComponent("VideoTips.json")
        let pilotIDs = ["NSqvvmFdz3w", "KXkqSDpm4zg", "3gS6fgGQdlk"]
        let tips = try VideoTip.load(from: source).filter { pilotIDs.contains($0.videoID) }
        precondition(tips.map(\.videoID) == ["NSqvvmFdz3w", "KXkqSDpm4zg", "3gS6fgGQdlk"])
        precondition(tips.flatMap(\.steps).count == 18)
        precondition(tips[0].matches("Bienen Behutsamkeit"))
        precondition(tips[1].matches("silk generator"))
        precondition(!tips[2].matches("diamond farm"))
        for tip in tips {
            for step in tip.steps {
                let components = URLComponents(url: tip.url(at: step.seconds), resolvingAgainstBaseURL: false)!
                precondition(components.host == "www.youtube.com" && components.path == "/watch")
                precondition(components.queryItems?.first { $0.name == "v" }?.value == tip.videoID)
                precondition(components.queryItems?.first { $0.name == "t" }?.value == "\(step.seconds)s")
            }
        }
        precondition(tips[1].steps.contains { $0.matches("lava") })
        precondition(!tips[0].steps[0].matches("   "))
        precondition(!tips[1].steps.contains { $0.matches("unfindable-topic") })
        precondition(VideoTip.time(982) == "16:22")
        let original = try JSONSerialization.jsonObject(with: Data(contentsOf: source)) as! [[String: Any]]
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: temp) }
        func reject(_ entries: [[String: Any]]) throws {
            try JSONSerialization.data(withJSONObject: entries).write(to: temp)
            do { _ = try VideoTip.load(from: temp); fatalError("Malformed catalog accepted") }
            catch BuildCatalog.CatalogError.invalid { }
        }
        var bad = original
        bad[0]["videoID"] = "bad&redirect=elsewhere"
        try reject(bad)
        bad = original
        var steps = bad[0]["steps"] as! [[String: Any]]
        steps[0]["seconds"] = 99999; bad[0]["steps"] = steps
        try reject(bad)
        try reject(original + [original[0]])
        bad = original; bad[0]["title"] = ["de": "", "en": "Title"]; try reject(bad)
        let guides = try JSONDecoder().decode(BuildCatalog.self, from: Data(contentsOf: root.appendingPathComponent("BuildGuides.json")))
        try guides.validate()
        var engine = ConversationKnowledge(recipes: [], guides: guides.guides, videoTips: tips)
        func ask(_ q: String, _ en: Bool = false) -> CompanionAnswer { engine.answer(q, world: nil, places: [], english: en) }
        let answer = ask("Wie baue ich einen Steingenerator?")
        precondition(answer.text.contains("Behutsamkeit") && answer.text.contains("Quest ungetestet"))
        precondition(answer.sources.count == 6 && answer.sources.allSatisfy { $0.url.absoluteString.contains("KXkqSDpm4zg") })
        precondition(ask("video guide bees", true).text.contains("Silk Touch"))
        precondition(ask("Tipps Lorenstrecke").text.contains("Rampe"))
        precondition(ask("Welche Video Tipps gibt es?").sources.count == 3)
        precondition(!ask("Wie viele Bienen habe ich?").text.contains("3/3"), "Personal state must not be inferred from a video")
        precondition(!ask("Video Laserschwert").sources.contains { $0.url.absoluteString.contains("KXkq") })
        print("PASS: 3 catalogs, 18 timestamp URLs, multilingual search, invalid data rejection, conversation provenance and personal-state isolation")
    }
}
