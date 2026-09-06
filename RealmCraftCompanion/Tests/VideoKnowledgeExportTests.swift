import Foundation
@main struct VideoKnowledgeExportTests {
 static func main() throws {
  let tips = try VideoTip.load(from: URL(fileURLWithPath: CommandLine.arguments[1]))
  let id = "XpSz72FVmrI"
  let one = VideoKnowledgeExport.selected(tips, value: VideoKnowledgeExport.selecting(id, in: "", enabled: true))
  precondition(one.count == 1)
  precondition(VideoKnowledgeExport.selected(tips, value: "unknown").isEmpty)
  precondition(VideoKnowledgeExport.selecting(id, in: id, enabled: false).isEmpty)
  let md = VideoKnowledgeExport.markdown(one + one, english: false)
  precondition(md.components(separatedBy: "## " + one[0].title.de).count == 2)
  precondition(md.contains("Kurzfassung") && md.contains("Download as New") && md.contains("t=120s"))
  precondition(md.contains("Vollständige Originaltranskripte und Audio sind nicht enthalten"))
  let pending = tips.first { !$0.isCurated }!
  precondition(VideoKnowledgeExport.markdown([pending], english: true).contains("Content review pending"))
  let base = AIContextDocument(payload: ["sentinel":42], markdown: "# World")
  let unchanged = base.addingVideos([], english: true)
  precondition(unchanged.markdown == base.markdown && unchanged.videoMarkdown == nil)
  let inline = base.addingVideos(one, english: true, threshold: Int.max)
  precondition(inline.videoMarkdown == nil && inline.markdown.contains("Download as New"))
  let split = base.addingVideos(one, english: true, threshold: 1)
  precondition(split.videoMarkdown != nil && !split.markdown.contains("Download as New") && split.markdown.contains("BOTH"))
  let data = try JSONSerialization.jsonObject(with: split.json) as! [String:Any]
  precondition(data["sentinel"] as? Int == 42)
  precondition((data["videoKnowledge"] as! [String:Any])["markdown"] as? String == split.videoMarkdown)
  precondition(base.addingVideos(one, english: false, separate: true, threshold: Int.max).videoMarkdown != nil)
  let fm = FileManager.default
  let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fm.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? fm.removeItem(at: root) }
  let library = root.appendingPathComponent("saves")
  try fm.createDirectory(at: library, withIntermediateDirectories: false)
  let files = try MarkdownExportPackage.write(markdown: split.markdown, videoMarkdown: split.videoMarkdown, to: root.appendingPathComponent("world.md"), library: library)
  precondition(files.count == 2)
  let savedVideo = try String(contentsOf: files[1], encoding:.utf8)
  precondition(savedVideo == split.videoMarkdown!)
  let savedMain = try String(contentsOf: files[0], encoding:.utf8)
  precondition(savedMain.contains(files[1].lastPathComponent))
  let alias = root.appendingPathComponent("alias")
  try fm.createSymbolicLink(at: alias, withDestinationURL: library)
  do {
   _ = try MarkdownExportPackage.write(markdown:"bad", videoMarkdown:"bad", to:alias.appendingPathComponent("bad.md"),library:library)
   fatalError("Save library was writable")
  } catch {}
  let before = try fm.contentsOfDirectory(atPath:root.path).sorted()
  do {
   _ = try MarkdownExportPackage.write(markdown:"bad",videoMarkdown:"must roll back",to:library)
   fatalError("Directory accepted as main file")
  } catch {}
  let after = try fm.contentsOfDirectory(atPath:root.path).sorted()
  precondition(after == before)
  print("PASS: selection, summaries, provenance, time links, deduplication, inline/split/JSON parity, two-file output, symlink guard and rollback")
 }
}
