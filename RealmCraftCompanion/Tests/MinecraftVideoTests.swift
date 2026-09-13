import Foundation
@main struct MinecraftVideoTests {
    static func main() throws {
        let tips = try VideoTip.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
        let minecraft = tips.filter(\.isMinecraft)
        precondition(minecraft.count == 12)
        precondition(minecraft.allSatisfy { !$0.isCurated && $0.transferAssessment != nil && $0.matches("minecraft") })
        let unknown = minecraft.first { $0.duration == 0 }!
        precondition(unknown.durationLabel(false) == "Dauer unbekannt")
        let reviewed = minecraft.first { $0.videoID == "4kOAg1AEJtU" }!
        precondition(reviewed.reviewMethod == "transcript-only" && reviewed.steps.count == 6)
        let md = VideoKnowledgeExport.markdown([reviewed], english: false)
        precondition(md.contains("Spiel der Quelle: Minecraft") && md.contains("WorldEdit") && md.contains("t=311s"))
        precondition(md.contains("Keine fertige RealmCraft-Bauanleitung"))
        precondition(tips.filter { !$0.isMinecraft }.count == 197)
        if CommandLine.arguments.count > 2 {
            try VideoKnowledgeExport.markdown(minecraft, english: false).write(toFile: CommandLine.arguments[2], atomically: true, encoding: .utf8)
        }
        print("PASS: Minecraft identity, transfer limitations, timestamps, unknown duration, existing catalog")
    }
}
