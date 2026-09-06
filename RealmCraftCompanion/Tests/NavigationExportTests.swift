import Foundation
// Minimal unrelated catalog types for this isolated test executable.
struct TestTitle { let en: String; let de: String }
struct ConversationRecipe { let title: TestTitle }
struct BuildGuide { let title: TestTitle }
struct CompanionPlace { let name: String }
enum ConversationKnowledge { static func normalized(_ s: String) -> String { s.lowercased() } }
struct AIContextDocument { let payload: [String: Any]; let markdown: String; var videoMarkdown: String? = nil }

@main struct NavigationExportTests {
    static func main() async throws {
        let data = Data("""
        {"schemaVersion":1,"world":"synthetic","generatedAt":"2026-01-01T00:00:00Z","dimension":"o","steps":[{"id":"step-1","index":1,"at":{"x":0,"y":65,"z":0},"to":{"x":0,"y":65,"z":-10},"heading":"north","action":"walk","blocks":10,"instruction":"Start facing north, then walk for 10 blocks to X 0, Y 65, Z -10."},{"id":"step-2","index":2,"at":{"x":0,"y":65,"z":-10},"to":{"x":4,"y":65,"z":-10},"heading":"east","action":"walk","blocks":4,"instruction":"Facing north, turn right, then walk for 4 blocks to X 4, Y 65, Z -10."}],"pois":[{"id":"poi-1","name":"Possible small island","x":-150,"y":64,"z":0,"source":"heuristic","stepID":"step-1","distance":150,"side":"left"}],"includePOIs":true,"radius":250,"distance":14,"guidance":["Use English. No live tracking."]}
        """.utf8)
        let pack = try JSONDecoder().decode(NavigationPack.self, from: data)
        precondition(pack.valid)
        precondition(pack.markdown.contains("150 blocks left"))
        precondition(pack.selectingPOIs(false).pois.isEmpty)
        precondition(!pack.selectingPOIs(false).markdown.contains("island"))
        let ids = try pack.validatedHighlights(["step-2", "poi-1"]); precondition(ids == ["step-2", "poi-1"])
        do { _ = try pack.validatedHighlights(["invented"]); fatalError("Invented reference accepted") } catch {}
        let document = pack.attach(to: AIContextDocument(payload: ["existing": true], markdown: "Base"))
        precondition(document.payload["existing"] as? Bool == true && document.payload["navigation"] != nil)
        precondition(pack.markdown.contains(NavigationPack.assistantInstructions))
        let exportedNavigation = document.payload["navigation"] as! [String: Any]
        precondition(exportedNavigation["assistantInstructions"] as? String == NavigationPack.assistantInstructions)
        precondition(document.markdown.contains(NavigationPack.assistantInstructions))
        precondition(pack.spokenSections.count == 1)
        precondition(pack.spokenSections[0].blocks == 14)
        precondition(pack.spokenSections[0].stepIDs == ["step-1", "step-2"])
        precondition(pack.spokenSections[0].to.x == 4)
        precondition((exportedNavigation["spokenSections"] as? [[String: Any]])?.count == 1)
        precondition(pack.markdown.contains("Spoken sections"))
        if CommandLine.arguments.contains("--live") {
            let answer = try await pack.highlightedLocally()
            precondition(!(answer.localHighlights ?? []).isEmpty)
            print("Local Qwen validated highlights:", answer.localHighlights ?? [])
        }
        print("Navigation export validation passed")
    }
}
