import Foundation
@main struct VideoChannelTests {
 static func main() throws {
  let url=URL(fileURLWithPath: CommandLine.arguments[1])
  let tips=try VideoTip.load(from:url)
  precondition(tips.count == 196)
  precondition(tips.filter(\.isShort).count == 21)
  precondition(tips.filter(\.isCurated).count >= 48)
  precondition(tips.filter(\.isCurated).allSatisfy { $0.reviewMethod != nil })
  let visual = tips.first { $0.videoID == "9B5sX802vAw" }!
  precondition(visual.isVisualReviewOnly && !visual.hasTranscript)
  precondition(visual.coverageLabel(false).contains("ohne Transkriptprüfung"))
  precondition(Set(tips.map(\.videoID)).count == 196)
  for videoID in ["rD6mmzjkoZU", "uSh9_PDoj2I", "797_CRXYH_8"] {
   let source = tips.first { $0.videoID == videoID }!
   precondition(!source.isCurated && source.reviewMethod == nil)
   precondition(!source.relatedSources.isEmpty)
  }
  precondition(tips.contains { $0.channel == "Home Daddy VR" && $0.matches("Home Daddy") })
  let update = tips.first { $0.videoID == "mHWOp1d14xI" }!
  precondition(update.isCurated && update.matches("Controllerbelegung"))
  let generator=tips.first { $0.videoID == "KXkqSDpm4zg" }!
  precondition(generator.matches("Bruchstein Behutsamkeit"))
  precondition(!generator.transcriptMatches("Lava").isEmpty)
  let cane=tips.first { $0.videoID == "clJ1Sw0A-20" }!
  precondition(cane.matches("Zuckerrohr"))
  precondition(cane.isCurated && !cane.isVisualReviewOnly)
  precondition(cane.steps.contains { $0.matches("Frostläufer") })
  let boat = tips.first { $0.videoID == "ZMYEOyawbP0" }!
  precondition(boat.steps.contains { $0.matches("Schnellplatz") })
  precondition(!cane.transcriptMatches("Zuckerrohr").isEmpty)
  precondition(tips.contains { $0.videoID == "DBsd2Quk2h8" })
  precondition(tips.contains { $0.videoID == "cuOCBF0ujiw" })
  precondition(tips.contains { $0.videoID == "PmTxtG47crU" })
  precondition(!tips.contains { $0.videoID == "tQfYjlErvHU" })
  precondition(!tips.contains { $0.matches("zzzunfindable") })
  precondition(tips.allSatisfy { $0.matches("  ") })
  let window=VideoTranscriptWindow(seconds:30,terms:["gluck","fortune","diamanten"])
  precondition(window.matches("Glück Diamant"))
  precondition(!window.matches("Glück Schaf"))
  precondition(!window.matches("  "))
  let temp=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".json")
  defer { try? FileManager.default.removeItem(at:temp) }
  let raw=try JSONSerialization.jsonObject(with:Data(contentsOf:url)) as! [[String:Any]]
  func reject(_ raw:[[String:Any]]) throws {
   try JSONSerialization.data(withJSONObject:raw).write(to:temp)
   do { _=try VideoTip.load(from:temp); fatalError("Invalid catalog accepted") } catch BuildCatalog.CatalogError.invalid {}
  }
  try reject(raw + [raw[0]])
  var bad=raw;bad[0]["coverage"]="verified";try reject(bad)
  bad=raw;bad[0]["transcriptIndex"]=[["seconds":999999,"terms":["lava"]]];try reject(bad)
  bad=raw;bad[0]["coverage"]="transcript";bad[0]["transcriptIndex"]=[];try reject(bad)
  bad=raw;bad[0]["reviewMethod"]="fully-watched";try reject(bad)
  bad=raw;bad[0]["coverage"]="metadata";try reject(bad)
  print("PASS: 196 unique videos, 21 Shorts, reviewed and visual-only provenance, German/English search, classification and malformed-data rejection")
  print("Indexed transcripts: \(tips.filter(\.hasTranscript).count); windows: \(tips.reduce(0){$0+($1.transcriptIndex?.count ?? 0)})")
 }
}
