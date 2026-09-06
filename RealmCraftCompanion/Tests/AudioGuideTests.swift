import Foundation
@main struct AudioGuideTests {
 static func main() throws {
  let catalog = try JSONDecoder().decode(BuildCatalog.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
  try catalog.validate()
  for guide in catalog.guides {
   for english in [false, true] {
    let text = guide.audioAgentPrompt(blocks: catalog.blocks, english: english)
    precondition(text.contains(guide.title.value(english)))
    for m in guide.materials { precondition(text.contains(m.name.value(english))) }
    for step in guide.steps { precondition(text.contains(step.value(english))) }
    precondition(text.contains(english ? "WAIT" : "WARTE"))
    precondition(text.contains(english ? "checkpoint" : "Zwischenstand"))
    precondition(text.contains(english ? "not additional construction" : "kein zusätzlicher Bau"))
   }
  }
  let tree = catalog.guides.first { $0.id == "tree_bridge" }!
  let text = tree.audioAgentPrompt(blocks: catalog.blocks, english: false)
  precondition(text.contains("columns=x; rows=z"))
  precondition(text.contains("0…10=tree_plank"))
  try text.write(toFile: "/tmp/RealmCraft-Audioguide-tree_bridge.txt", atomically: true, encoding: .utf8)
  print("PASS: bilingual audio handoff completeness for \(catalog.guides.count) guides")
 }
}
