import Foundation

struct FeedbackContext: Codable {
    let area: String
    var entryID: String? = nil
    var entryName: String? = nil
    var catalogDate: String? = nil
    var evidenceStatus: String? = nil
    var sources: [String] = []
}

struct FeedbackAttachment: Identifiable {
    let id = UUID()
    let data: Data
    let fileExtension: String
}

struct FeedbackReport: Codable {
    let schemaVersion: Int
    let createdAt: String
    let type: String
    let summary: String
    let description: String
    let stepsToReproduce: String
    let expectedResult: String
    let actualResult: String
    let application: [String: String]
    let context: FeedbackContext
    let attachments: [String]
    let catalogNotice: String?

    // Strict JSON is a valid Hjson document. Encoding keeps multiline text and quotes safe.
    func document() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }

    static func attachmentNames(_ attachments: [FeedbackAttachment]) -> [String] {
        attachments.enumerated().map { "screenshot-\(String(format: "%02d", $0.offset + 1)).\($0.element.fileExtension)" }
    }

    func writePackage(to directory: URL, images: [FeedbackAttachment]) throws -> [URL] {
        guard attachments == Self.attachmentNames(images) else { throw CocoaError(.fileWriteInvalidFileName) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let documentURL = directory.appendingPathComponent("report.hjson")
        try document().write(to: documentURL, atomically: true, encoding: .utf8)
        var files = [documentURL]
        for (name, image) in zip(attachments, images) {
            guard ["png", "jpg", "jpeg", "heic"].contains(image.fileExtension) else { throw CocoaError(.fileWriteInvalidFileName) }
            let url = directory.appendingPathComponent(name)
            try image.data.write(to: url, options: .atomic)
            files.append(url)
        }
        return files
    }

    func writeArchive(to destination: URL, images: [FeedbackAttachment]) throws {
        let staging = FileManager.default.temporaryDirectory.appendingPathComponent("RealmCraft-Export-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: staging) }
        let folder = staging.appendingPathComponent("RealmCraft-Report")
        _ = try writePackage(to: folder, images: images)
        let archive = staging.appendingPathComponent("report.zip")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--norsrc", "--noextattr", "--keepParent", folder.path, archive.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw CocoaError(.fileWriteUnknown) }
        try Data(contentsOf: archive).write(to: destination, options: .atomic)
    }
}

extension FeedbackReport {
    // Open only the fixed form URL: report text never enters browser history or URL logs.
    static let githubIssueURL = URL(string: "https://github.com/friedensbringer-peacemaker/RealmCraft-Companion/issues/new")!

    func githubMarkdown(english: Bool) -> String {
        func t(_ de: String, _ en: String) -> String { english ? en : de }
        var sections: [String] = []
        func add(_ heading: String, _ value: String) {
            guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            sections.append("## \(heading)\n\n\(value)")
        }
        let reportType: String
        switch type {
        case "bug": reportType = t("Anwendungsfehler", "Application bug")
        case "suggestion": reportType = t("Funktionswunsch", "Feature request")
        default: reportType = t("Datenkorrektur", "Data correction")
        }
        add(t("Art der Meldung", "Report type"), reportType)
        add(t("Kurztitel", "Summary"), summary)
        add(t("Beschreibung", "Description"), description)
        add(t("Schritte zum Nachstellen", "Steps to reproduce"), stepsToReproduce)
        add(t("Erwartetes Ergebnis", "Expected result"), expectedResult)
        add(t("Tatsächliches Ergebnis", "Actual result"), actualResult)
        // Deliberate allowlist. No context, source links, timestamps, filenames or images.
        add(t("Companion-Version", "Companion version"), application["version"] ?? "")
        add(t("Betriebssystem", "Operating system"), application["os"] ?? "")
        add(t("Sprache", "Language"), application["language"] ?? "")
        return sections.joined(separator: "\n\n") + "\n"
    }
}
