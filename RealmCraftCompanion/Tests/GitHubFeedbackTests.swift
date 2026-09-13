import Foundation

@main struct GitHubFeedbackTests {
    static func main() {
        for kind in ["bug", "suggestion", "data"] {
            let details = "Quotes \" & = ? # ü 🐾\n\n" + String(repeating: "Long synthetic report.\n", count: 1000)
            let report = FeedbackReport(schemaVersion: 1, createdAt: "PRIVATE_TIMESTAMP", type: kind,
                summary: "Synthetic issue", description: details, stepsToReproduce: "Step 1\nStep 2",
                expectedResult: "", actualResult: "Observed result",
                application: ["version": "test-version", "os": "test-os", "language": "de",
                              "privateKey": "PRIVATE_APPLICATION_VALUE", "appearance": "PRIVATE_APPEARANCE"],
                context: FeedbackContext(area: "PRIVATE_AREA", entryID: "PRIVATE_ENTRY", entryName: "PRIVATE_NAME",
                                         sources: ["PRIVATE_SOURCE"]),
                attachments: ["PRIVATE_IMAGE.png"], catalogNotice: "PRIVATE_NOTICE")
            for english in [false, true] {
                let text = report.githubMarkdown(english: english)
                precondition(text.contains(details), "Long reports and special characters must remain intact")
                precondition(text.contains("Step 1\nStep 2") && text.contains("Observed result"))
                precondition(!text.contains("PRIVATE_"), "Only explicit public metadata is exported")
                precondition(text.contains("test-version") && text.contains("test-os"))
                precondition(!text.contains("## Expected result") && !text.contains("## Erwartetes Ergebnis"))
                if kind == "suggestion" { precondition(text.contains(english ? "Feature request" : "Funktionswunsch")) }
            }
        }
        let url = URLComponents(url: FeedbackReport.githubIssueURL, resolvingAgainstBaseURL: false)!
        precondition(url.scheme == "https" && url.host == "github.com")
        precondition(url.path.hasSuffix("/RealmCraft-Companion/issues/new"))
        precondition(url.query == nil && url.fragment == nil && url.user == nil)
        print("PASS: DE/EN report types, complete long Markdown, metadata allowlist, empty fields and fixed URL without report contents")
    }
}
