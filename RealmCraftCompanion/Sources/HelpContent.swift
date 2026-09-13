import Foundation

enum HelpCategory: String, Codable, CaseIterable, Identifiable {
    case gettingStarted, world, ai, knowledge, specialist, support, background, updates
    var id: String { rawValue }
    func title(english: Bool) -> String {
        switch self {
        case .gettingStarted: return english ? "Getting started" : "Einstieg & Bedienung"
        case .world: return english ? "Your world" : "Deine Welt"
        case .ai: return english ? "AI tools" : "KI-Werkzeuge"
        case .knowledge: return english ? "Knowledge & help" : "Wissen & Hilfe"
        case .specialist: return english ? "More tools" : "Weitere Werkzeuge"
        case .support: return english ? "Support" : "Unterstützung"
        case .background: return english ? "About the app" : "Über die App"
        case .updates: return english ? "Updates & plans" : "Updates & Ausblick"
        }
    }
}

struct HelpArticle: Codable, Identifiable, Equatable {
    let id: String
    let icon: String
    let category: HelpCategory
    let deTitle: String
    let enTitle: String
    var de: String
    var en: String
    let deResource: String?
    let enResource: String?
    let related: [String]
    func title(_ english: Bool) -> String { english ? enTitle : deTitle }
    func content(_ english: Bool) -> String { english ? en : de }
}

enum HelpCatalog {
    struct Document: Codable { var schema: Int; var articles: [HelpArticle] }
    enum LoadError: LocalizedError {
        case invalid
        var errorDescription: String? { "Help catalog is incomplete or invalid. / Hilfekatalog ist unvollständig oder ungültig." }
    }
    static func load(resources: URL) throws -> [HelpArticle] {
        let document = try JSONDecoder().decode(Document.self, from: Data(contentsOf: resources.appendingPathComponent("HelpArticles.json")))
        guard document.schema == 1 else { throw LoadError.invalid }
        var articles = document.articles
        let allowed = Set(["SETUP-de", "SETUP-en", "TRANSFER-de", "TRANSFER-en", "CHANGELOG", "BACKLOG"])
        for i in articles.indices {
            if let resource = articles[i].deResource {
                guard allowed.contains(resource) else { throw LoadError.invalid }
                articles[i].de = try String(contentsOf: resources.appendingPathComponent(resource + ".md"), encoding: .utf8)
            }
            if let resource = articles[i].enResource {
                guard allowed.contains(resource) else { throw LoadError.invalid }
                articles[i].en = try String(contentsOf: resources.appendingPathComponent(resource + ".md"), encoding: .utf8)
            }
        }
        try validate(articles)
        return articles
    }
    static func validate(_ articles: [HelpArticle]) throws {
        let ids = Set(articles.map(\.id))
        guard !articles.isEmpty, articles.first?.id == "start", ids.count == articles.count,
              articles.allSatisfy({ article in
                  !article.id.isEmpty && !article.icon.isEmpty &&
                  [article.deTitle, article.enTitle, article.de, article.en].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } &&
                  Set(article.related).count == article.related.count &&
                  article.related.allSatisfy { ids.contains($0) && $0 != article.id }
              }) else { throw LoadError.invalid }
    }
    static func filtered(_ articles: [HelpArticle], query: String) -> [HelpArticle] {
        let words = normalized(query).split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty else { return articles }
        return articles.filter { article in
            let text = normalized([article.id, article.deTitle, article.enTitle, article.de, article.en].joined(separator: " "))
            return words.allSatisfy { text.contains($0) }
        }
    }
    static func visibleID(selected: String, in articles: [HelpArticle]) -> String? {
        articles.first(where: { $0.id == selected })?.id ?? articles.first?.id
    }
    private static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}

enum HelpBlock: Equatable {
    case heading(String)
    case paragraph(String)
    case item(marker: String, text: String)

    static func parse(_ content: String) -> [HelpBlock] {
        var blocks: [HelpBlock] = []
        var paragraph: [String] = []
        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            blocks.append(.paragraph(paragraph.joined(separator: "\n")))
            paragraph.removeAll()
        }
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
            } else if let prefix = line.range(of: "^#{1,6} +", options: .regularExpression) {
                flushParagraph(); blocks.append(.heading(String(line[prefix.upperBound...])))
            } else if let prefix = line.range(of: "^(?:[0-9]+[.)]|[•*–-]) +", options: .regularExpression) {
                flushParagraph()
                let marker = String(line[prefix]).trimmingCharacters(in: .whitespaces)
                blocks.append(.item(marker: marker.first?.isNumber == true ? marker : "•", text: String(line[prefix.upperBound...])))
            } else if line == line.uppercased() && line.count < 100 && line.contains(where: { $0.isLetter }) {
                flushParagraph(); blocks.append(.heading(line))
            } else { paragraph.append(line) }
        }
        flushParagraph()
        return blocks
    }
}
