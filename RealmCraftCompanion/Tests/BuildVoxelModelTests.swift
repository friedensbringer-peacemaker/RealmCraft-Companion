import Foundation
@main struct BuildVoxelModelTests {
 static func main() throws {
  let root = URL(fileURLWithPath: CommandLine.arguments[1])
  let catalog = try JSONDecoder().decode(BuildCatalog.self, from: Data(contentsOf: root.appendingPathComponent("BuildGuides.json")))
  let models = try JSONDecoder().decode([String:BuildVoxelGuide].self, from: Data(contentsOf: root.appendingPathComponent("BuildGuideVoxels.json")))
  for guide in catalog.guides { try models[guide.id]!.validate(guide: guide, blocks: catalog.blocks) }
  let invalid = try JSONDecoder().decode(BuildVoxelGuide.self, from: Data("{\"complete\":true,\"stages\":[[[0,0,0,\"#\"],[0,0,0,\"#\"]],[],[],[]]}".utf8))
  do { try invalid.validate(guide: catalog.guides[0], blocks: catalog.blocks); fatalError("invalid model accepted") } catch {}
  print("PASS decoded preview catalog and invalid data rejection")
 }
}
