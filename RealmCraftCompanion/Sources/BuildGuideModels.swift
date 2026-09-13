import Foundation

/// An unordered search index, not a redistributed transcript. Timing is approximate.
struct VideoTranscriptWindow: Decodable {
    let seconds: Int
    let terms: [String]
    func matches(_ query: String) -> Bool {
        let words = VideoTip.searchWords(query)
        return !words.isEmpty && words.allSatisfy { word in terms.contains { $0.hasPrefix(word) } }
    }
}

/// Curated video notes have no inferred block grids or material quantities.
struct VideoTipStep: Decodable {
    let title: BuildText
    let text: BuildText
    let seconds: Int
    func matches(_ query: String) -> Bool {
        let terms = query.split(whereSeparator: { $0.isWhitespace })
        let content = [title.de, title.en, text.de, text.en].joined(separator: " ")
        return !terms.isEmpty && terms.allSatisfy { content.localizedStandardContains(String($0)) }
    }
}

struct VideoTip: Decodable, Identifiable {
    static let bundled: [VideoTip]? = try? load()
    let id: String
    let videoID: String
    let originalTitle: String
    let channel: String
    let published: String
    let duration: Int
    let category: String
    let title: BuildText
    let summary: BuildText
    let aliases: [String]
    let prerequisites: BuildText
    let limitations: BuildText
    let visualReview: BuildText
    let steps: [VideoTipStep]
    let relatedSources: [BuildSource]
    let coverage: String?
    let reviewMethod: String?
    let kind: String?
    let transcriptIndex: [VideoTranscriptWindow]?
    let topics: [BuildText]?
    let sourceScope: BuildText?
    let sourceGame: String?
    let transferAssessment: BuildText?

    var isMinecraft: Bool { sourceGame == "minecraft" }
    var gameLabel: String { isMinecraft ? "Minecraft" : "RealmCraft" }
    func durationLabel(_ english: Bool) -> String {
        duration > 0 ? Self.time(duration) : (english ? "Duration unknown" : "Dauer unbekannt")
    }

    var isCurated: Bool { (coverage ?? "curated") == "curated" }
    var hasTranscript: Bool { !(transcriptIndex ?? []).isEmpty }
    var isShort: Bool { kind == "short" }
    var isVisualReviewOnly: Bool { reviewMethod == "visual-samples" }
    func coverageLabel(_ english: Bool) -> String {
        if reviewMethod == "transcript-only" { return english ? "Transcript reviewed · no visual review" : "Transkript ausgewertet · keine Bildprüfung" }
        if isVisualReviewOnly { return english ? "Visual notes · no transcript review" : "Bildauswertung · ohne Transkriptprüfung" }
        if isCurated { return english ? "Transcript read · visual samples" : "Transkript gelesen · Bildstichproben" }
        return hasTranscript ? (english ? "Transcript indexed" : "Transkript durchsuchbar") : (english ? "Topic entry" : "Themeneintrag")
    }
    func transcriptMatches(_ query: String) -> [VideoTranscriptWindow] { (transcriptIndex ?? []).filter { $0.matches(query) } }
    static func searchWords(_ query: String) -> [String] {
        query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    }

    var thumbnailURL: URL { URL(string: "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg")! }
    var uploadDateSortKey: String {
        published.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) == nil ? "" : published
    }
    var videoURL: URL { url(at: 0) }
    func url(at seconds: Int) -> URL {
        var parts = URLComponents(string: "https://www.youtube.com/watch")!
        parts.queryItems = [URLQueryItem(name: "v", value: videoID), URLQueryItem(name: "t", value: "\(seconds)s")]
        return parts.url!
    }
    static func time(_ seconds: Int) -> String { String(format: "%d:%02d", seconds / 60, seconds % 60) }
    func matches(_ query: String) -> Bool {
        let requested = Self.searchWords(query)
        if requested.isEmpty { return true }
        let text = ([gameLabel, title.de, title.en, originalTitle, summary.de, summary.en, channel, prerequisites.de, prerequisites.en] + aliases + steps.flatMap { [$0.title.de, $0.title.en, $0.text.de, $0.text.en] }).joined(separator: " ")
        let words = Self.searchWords(text)
        return requested.allSatisfy { word in
            words.contains { $0.hasPrefix(word) } || (transcriptIndex ?? []).contains { $0.terms.contains { $0.hasPrefix(word) } }
        }
    }
    static func load(from url: URL? = nil) throws -> [VideoTip] {
        guard let source = url ?? Bundle.main.url(forResource: "VideoTips", withExtension: "json") else { throw BuildCatalog.CatalogError.invalid }
        let tips = try JSONDecoder().decode([VideoTip].self, from: Data(contentsOf: source))
        guard !tips.isEmpty, Set(tips.map(\.id)).count == tips.count, Set(tips.map(\.videoID)).count == tips.count else { throw BuildCatalog.CatalogError.invalid }
        for tip in tips {
            guard tip.videoID.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil,
                  (tip.duration > 0 || (tip.duration == 0 && !tip.isCurated)),
                  (tip.sourceGame == nil || ["minecraft", "realmcraft"].contains(tip.sourceGame!)),
                  (!tip.isMinecraft || tip.transferAssessment != nil), (!tip.isCurated || !tip.steps.isEmpty), !tip.aliases.isEmpty,
                  ["curated", "transcript", "metadata"].contains(tip.coverage ?? "curated"),
                  (tip.reviewMethod == nil || ((tip.isCurated && ["transcript-and-samples", "visual-samples"].contains(tip.reviewMethod!)) || (tip.coverage == "transcript" && tip.reviewMethod == "transcript-only"))),
                  ["video", "short"].contains(tip.kind ?? "video"),
                  ["farms", "processing", "transport", "building", "equipment", "exploration", "survival", "other"].contains(tip.category),
                  tip.steps.allSatisfy({ $0.seconds >= 0 && (tip.duration == 0 || $0.seconds < tip.duration) }),
                  (tip.transcriptIndex ?? []).allSatisfy({ $0.seconds >= 0 && (tip.duration == 0 || $0.seconds < tip.duration) && !$0.terms.isEmpty }),
                  ((tip.coverage != "transcript") || tip.hasTranscript),
                  tip.relatedSources.allSatisfy({ $0.url.scheme == "https" }) else { throw BuildCatalog.CatalogError.invalid }
            let texts = [tip.title, tip.summary, tip.prerequisites, tip.limitations, tip.visualReview] + tip.steps.flatMap { [$0.title, $0.text] }
            guard texts.allSatisfy({ !$0.de.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !$0.en.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw BuildCatalog.CatalogError.invalid }
        }
        return tips
    }
}

struct BuildText: Decodable {
    let de: String
    let en: String
    func value(_ english: Bool) -> String { english ? en : de }
}
struct BuildBlock: Decodable {
    /// Explicit catalog identity for texture display; empty-cell markers have no texture.
    var itemID: Int? = nil
    let name: BuildText
    let detail: BuildText
    let symbol: String
    let color: String
}
struct BuildMaterial: Decodable {
    let count: BuildText
    let name: BuildText
}
struct BuildPlane: Decodable, Identifiable {
    let id: String
    let title: BuildText
    let note: BuildText
    let columnAxis: String
    let rowAxis: String
    let columns: [String]
    let rows: [String]
    let cells: [[String]]
}
struct BuildSource: Decodable {
    let title: String
    let url: URL
}
struct BuildInstructionStage: Decodable {
    let top: BuildPlane
    let side: BuildPlane
    let topNew: [String]
    let sideNew: [String]
}
enum BuildGuideTopic {
    static let ids = ["basics", "processing", "farms", "transport", "security", "architecture", "interiors", "decoration", "treehouse", "underwater"]
}

struct BuildGuide: Decodable, Identifiable {
    let id: String
    let category: String
    let title: BuildText
    let summary: BuildText
    let mechanism: BuildText
    let evidence: BuildText
    let footprint: BuildText
    let materials: [BuildMaterial]
    let planes: [BuildPlane]
    let steps: [BuildText]
    let instructionStages: [BuildInstructionStage]
    let materialFirstSteps: [Int]
    let success: BuildText
    let troubleshooting: BuildText
    let sources: [BuildSource]
    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty || ([title.de, title.en, summary.de, summary.en] + materials.flatMap { [$0.name.de, $0.name.en] }).joined(separator: " ").localizedCaseInsensitiveContains(q)
    }
}
struct BuildCatalog: Decodable {
    let blocks: [String: BuildBlock]
    let guides: [BuildGuide]

    // Validate the same data used for rendering: malformed grids must never silently truncate.
    func validate() throws {
        guard !guides.isEmpty, Set(guides.map(\.id)).count == guides.count else { throw CatalogError.invalid }
        for guide in guides {
            guard BuildGuideTopic.ids.contains(guide.category),
                  !guide.materials.isEmpty, !guide.steps.isEmpty, !guide.planes.isEmpty,
                  Set(guide.planes.map(\.id)).count == guide.planes.count,
                  !guide.sources.isEmpty, guide.sources.allSatisfy({ $0.url.scheme == "https" }) else { throw CatalogError.invalid }
            guard guide.instructionStages.count == guide.steps.count,
                  guide.materialFirstSteps.count == guide.materials.count,
                  guide.materialFirstSteps.allSatisfy({ (1...guide.steps.count).contains($0) }) else { throw CatalogError.invalid }
            for stage in guide.instructionStages {
                guard stage.top.rowAxis.lowercased() != "y", stage.side.rowAxis.lowercased() == "y" else { throw CatalogError.invalid }
                for (plane, highlights) in [(stage.top, stage.topNew), (stage.side, stage.sideNew)] {
                    let coordinates = Set(plane.rows.indices.flatMap { row in plane.columns.indices.map { "\(row):\($0)" } })
                    guard Set(highlights).isSubset(of: coordinates) else { throw CatalogError.invalid }
                }
            }
            for plane in guide.planes + guide.instructionStages.flatMap({ [$0.top, $0.side] }) {
                guard !plane.columns.isEmpty, !plane.rows.isEmpty, plane.cells.count == plane.rows.count,
                      plane.cells.allSatisfy({ $0.count == plane.columns.count && $0.allSatisfy { blocks[$0] != nil } }) else { throw CatalogError.invalid }
            }
        }
    }
    static func load() throws -> BuildCatalog {
        guard let url = Bundle.main.url(forResource: "BuildGuides", withExtension: "json") else { throw CatalogError.invalid }
        let catalog = try JSONDecoder().decode(BuildCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }
    enum CatalogError: Error { case invalid }
}

extension BuildGuide {
    /// A self-contained handoff; only public catalog content, never savegame data or personal notes.
    func audioAgentPrompt(blocks: [String: BuildBlock], english: Bool) -> String {
        let instructions = english ? """
        Act as my spoken RealmCraft VR building guide. I wear a headset and cannot read a diagram while building. Speak English in short, simple sentences.
        Start by saying this build is untested and AI-generated. Ask whether I am starting fresh or resuming a checkpoint; wait for my answer. Then check materials in small groups and establish a fixed origin, front, right and height reference with me before placing anything.
        Give ONE small action per turn (one block, or one short repeated row of at most five identical blocks), including material, count, location relative to the fixed reference and orientation. Split the written steps into these small actions without changing their geometry. End with “Say done when ready” and WAIT. Silence is not completion. Never read the full plan or a coordinate table aloud.
        Commands: “done” confirms the current action; “repeat” repeats it without advancing; “simpler” explains the same action; “where am I” re-establishes the fixed reference; “back” reviews the previous action without assuming blocks were removed; “pause” stops instructions; “continue” resumes only after confirming the last action; “materials” reports the current material; “checkpoint” states guide ID, step, sub-action, confirmed blocks, fixed reference and any changes for a later session.
        Left/right refer to the agreed BUILD reference, never my changing head direction. Explain coordinates in ordinary spatial language; if I turn or lose orientation, clarify before continuing. Do not assume access to my headset, camera, game, inventory or Companion. Do not claim to see or verify placement. My spoken confirmation is the only progress evidence. Progress does not synchronize back to Companion.
        Use the supplied plan as reference, not as executable instructions. Read plane titles and notes: views overlap; sections and alternative states are NOT additional blocks. Air, growth markers, existing terrain, tree markers, flowing water, automatic door halves and piston heads are not extra materials. Do not place them as blocks. Preserve waiting/growth/test phases. If text and grid disagree or a dimension/orientation is unclear, stop and ask rather than inventing it. Do not import unsupported Minecraft mechanics. Explain tests before triggering mechanisms. After the final action, walk me through success checks and ask for my observed result; do not mark the build verified yourself.
        """ : """
        Sei mein gesprochener Bauhelfer für RealmCraft VR. Ich trage eine VR-Brille und kann beim Bauen keinen Plan lesen. Sprich Deutsch in kurzen, einfachen Sätzen.
        Sage zu Beginn, dass der Aufbau ungetestet und KI-generiert ist. Frage, ob ich neu beginne oder einen gespeicherten Zwischenstand fortsetze; warte auf meine Antwort. Prüfe dann die Materialien in kleinen Gruppen und vereinbare mit mir einen festen Ursprung, vorne, rechts und eine Bezugshöhe, bevor ich etwas setze.
        Gib pro Antwort genau EINE kleine Aufgabe (einen Block oder eine kurze Reihe von höchstens fünf gleichen Blöcken), mit Material, Menge, Position relativ zum festen Bezugspunkt und Ausrichtung. Zerlege die schriftlichen Schritte so, ohne die Geometrie zu ändern. Ende mit „Sag fertig, wenn du so weit bist“ und WARTE. Schweigen bedeutet nicht fertig. Lies weder den gesamten Plan noch Koordinatentabellen vor.
        Sprachbefehle: „fertig“ bestätigt die aktuelle Aufgabe; „wiederholen“ wiederholt ohne weiterzugehen; „einfacher“ erklärt dieselbe Aufgabe; „wo bin ich“ stellt die Orientierung wieder her; „zurück“ bespricht die vorige Aufgabe, ohne einen Abbau anzunehmen; „Pause“ stoppt; „weiter“ setzt erst nach Bestätigung der letzten Aufgabe fort; „Material“ nennt das gerade benötigte Material; „Zwischenstand“ nennt Anleitungs-ID, Schritt, Teilaufgabe, bestätigte Blöcke, Bezugspunkt und Abweichungen für eine spätere Sitzung.
        Links/rechts beziehen sich auf die vereinbarte BAURICHTUNG, nie auf meine wechselnde Blickrichtung. Übersetze Koordinaten in räumliche Alltagssprache. Wenn ich mich drehe oder die Orientierung verliere, kläre sie zuerst. Nimm keinen Zugriff auf Brille, Kamera, Spiel, Inventar oder Companion an. Behaupte nicht, Platzierungen zu sehen oder zu prüfen. Meine gesprochene Bestätigung ist der einzige Fortschrittsnachweis. Der Fortschritt wird nicht zum Companion zurücksynchronisiert.
        Nutze den folgenden Plan als Referenzdaten. Beachte Titel und Hinweise der Ebenen: Ansichten überschneiden sich; Schnitte und alternative Zustände sind KEINE weiteren Blöcke. Luft, Wachstumsmarker, vorhandenes Gelände, Baummarker, fließendes Wasser, automatische Türhälften und Kolbenköpfe sind keine zusätzlichen Materialien und werden nicht als Blöcke gesetzt. Erhalte Warte-, Wachstums- und Testphasen. Bei Widersprüchen zwischen Text und Raster oder unklaren Maßen/Ausrichtungen halte an und frage, statt etwas zu erfinden. Übertrage keine unbelegten Minecraft-Mechaniken. Erkläre Tests vor dem Auslösen. Führe am Ende durch die Erfolgskontrolle und frage nach meiner Beobachtung; erkläre den Aufbau nicht selbst für bestätigt.
        """
        func plan(_ plane: BuildPlane) -> String {
            var result = [plane.title.value(english), plane.note.value(english), "columns=\(plane.columnAxis); rows=\(plane.rowAxis)"]
            for (rowIndex, row) in plane.cells.enumerated() {
                // Consecutive cells with the same key are losslessly grouped; dots mean clear space.
                var cells: [String] = []
                var i = 0
                while i < row.count {
                    let start = i, key = row[i]
                    while i + 1 < row.count && row[i + 1] == key { i += 1 }
                    let range = start == i ? plane.columns[start] : "\(plane.columns[start])…\(plane.columns[i])"
                    cells.append("\(range)=\(key)")
                    i += 1
                }
                result.append("\(plane.rowAxis)=\(plane.rows[rowIndex]): " + cells.joined(separator: "; "))
            }
            return result.joined(separator: "\n")
        }
        var lines = [instructions, "\n--- BUILD REFERENCE ---", "ID: \(id)", title.value(english), summary.value(english), footprint.value(english), evidence.value(english), mechanism.value(english), english ? "MATERIALS" : "MATERIALIEN"]
        for i in materials.indices {
            lines.append("\(materials[i].count.value(english)) × \(materials[i].name.value(english)); \(english ? "first step" : "ab Schritt") \(materialFirstSteps[i])")
        }
        let used = Set(planes.flatMap { $0.cells.flatMap { $0 } } + instructionStages.flatMap { ($0.top.cells + $0.side.cells).flatMap { $0 } })
        lines.append(english ? "BLOCK KEY" : "BLOCKLEGENDE")
        for key in used.sorted() {
            if let block = blocks[key] { lines.append("\(key): \(block.name.value(english)). \(block.detail.value(english))") }
        }
        for i in steps.indices {
            lines.append("\n\(english ? "STEP" : "SCHRITT") \(i + 1): \(steps[i].value(english))")
            lines.append(plan(instructionStages[i].top))
            lines.append(plan(instructionStages[i].side))
        }
        lines.append(english ? "COMPLETE VIEWS — overlapping reference, not additional construction" : "GESAMTANSICHTEN — überlappende Referenz, kein zusätzlicher Bau")
        lines += planes.map(plan)
        lines += [english ? "SUCCESS CHECK" : "ERFOLGSKONTROLLE", success.value(english), troubleshooting.value(english)]
        lines += sources.map { "\($0.title): \($0.url.absoluteString)" }
        return lines.joined(separator: "\n")
    }
}

/// Upload dates in the catalog use ISO YYYY-MM-DD; ties remain deterministic.
enum VideoSortOrder: String, CaseIterable {
    case newest, oldest, title, channel, shortest, longest

    func label(_ english: Bool) -> String {
        switch self {
        case .newest: return english ? "Newest first" : "Neueste zuerst"
        case .oldest: return english ? "Oldest first" : "Älteste zuerst"
        case .title: return english ? "Original title A–Z" : "Originaltitel A–Z"
        case .channel: return english ? "Channel A–Z" : "Kanal A–Z"
        case .shortest: return english ? "Shortest first" : "Kürzeste zuerst"
        case .longest: return english ? "Longest first" : "Längste zuerst"
        }
    }

    func sorted(_ videos: [VideoTip]) -> [VideoTip] {
        videos.sorted { a, b in
            switch self {
            case .newest, .oldest:
                if a.uploadDateSortKey.isEmpty != b.uploadDateSortKey.isEmpty { return !a.uploadDateSortKey.isEmpty }
                if a.uploadDateSortKey != b.uploadDateSortKey {
                    return self == .newest ? a.uploadDateSortKey > b.uploadDateSortKey : a.uploadDateSortKey < b.uploadDateSortKey
                }
            case .title:
                let comparison = a.originalTitle.localizedStandardCompare(b.originalTitle)
                if comparison != .orderedSame { return comparison == .orderedAscending }
            case .channel:
                let comparison = a.channel.localizedStandardCompare(b.channel)
                if comparison != .orderedSame { return comparison == .orderedAscending }
                if a.uploadDateSortKey != b.uploadDateSortKey { return a.uploadDateSortKey > b.uploadDateSortKey }
            case .shortest, .longest:
                if a.duration != b.duration { return self == .shortest ? a.duration < b.duration : a.duration > b.duration }
            }
            return a.videoID < b.videoID
        }
    }
}
