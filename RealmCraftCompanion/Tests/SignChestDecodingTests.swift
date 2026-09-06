import Foundation
@main struct SignChestDecodingTests {
 static func main() throws {
  var record: [String: Any] = ["id":"o:1,50,2","dimension":"o","x":1,"y":50,"z":2,"file":"o.0,0","items":[],"readable":true,"error":""]
  func decode() throws -> ChestRecord { try JSONDecoder().decode(ChestRecord.self,from:JSONSerialization.data(withJSONObject:record)) }
  let legacy = try decode(); precondition(legacy.nearbySign == nil)
  record["nearbySign"] = "o:sign:1,55,2"
  let tagged = try decode(); precondition(tagged.nearbySign == "o:sign:1,55,2")
  print("PASS: legacy and sign-aware chest indexes")
 }
}
