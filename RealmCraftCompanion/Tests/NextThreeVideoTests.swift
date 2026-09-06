import Foundation
@main struct NextThreeVideoTests {
 static func main() throws {
  let tips = try VideoTip.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
  precondition(tips.count == 196 && tips.filter(\.isCurated).count == 48)
  for (id, term) in [("XpSz72FVmrI", "Download as New"),("qVYgVZfVp20", "Wurfbewegung"),("j097gYswyLc", "Auto grip for attack")] {
   let tip = tips.first { $0.videoID == id }!
   precondition(tip.isCurated && tip.reviewMethod == "transcript-and-samples" && tip.matches(term))
   precondition(tip.steps.count >= 4)
   for step in tip.steps {
    let url = URLComponents(url:tip.url(at:step.seconds),resolvingAgainstBaseURL:false)!
    precondition(url.queryItems!.contains(URLQueryItem(name:"v",value:id)))
    precondition(url.queryItems!.contains(URLQueryItem(name:"t",value:"\(step.seconds)s")))
   }
  }
  print("PASS: 196 unique entries, 48 reviews, all three new tutorials searchable with valid timestamp links")
 }
}
