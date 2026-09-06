import Foundation
@main struct GuideIconModelTests {
 static func main() throws {
  let root = URL(fileURLWithPath: CommandLine.arguments[1])
  let catalog = try JSONDecoder().decode(BuildCatalog.self, from: Data(contentsOf: root.appendingPathComponent("BuildGuides.json")))
  precondition(catalog.blocks["uw_stone"]?.itemID == 236)
  precondition(catalog.blocks["."]?.itemID == nil)
  precondition(catalog.blocks["#"]?.itemID == 12)
  precondition(catalog.blocks["ar_oak_px"]?.itemID == catalog.blocks["ar_oak_nx"]?.itemID)
  precondition(catalog.blocks["ar_oak_px"]?.symbol != catalog.blocks["ar_oak_nx"]?.symbol)
  print("PASS explicit texture identity, empty fallback and cobblestone support and distinct orientation labels")
 }
}
