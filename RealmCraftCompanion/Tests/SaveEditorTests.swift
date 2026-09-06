import Foundation
@main struct SaveEditorTests {
 static func main() throws {
  let fm = FileManager.default
  let root = fm.temporaryDirectory.appendingPathComponent("editor-tests-" + UUID().uuidString)
  defer { try? fm.removeItem(at: root) }
  let world = root.appendingPathComponent("123")
  try fm.createDirectory(at: world, withIntermediateDirectories: true)
  func be(_ n: Int) -> [UInt8] { [UInt8((n>>24)&255),UInt8((n>>16)&255),UInt8((n>>8)&255),UInt8(n&255)] }
  var bytes: [UInt8] = [2,0,0,0,1,0,0,0,0] + Array(repeating: 0,count:129)
  bytes += [0,13,1,0,0,0,7,1] + be(36) + be(0)
  bytes += [1] + be(4) + be(0)
  bytes += [0,41,1] + Array(repeating: 0,count:11) + [3,0,0,0,0,0,143,190,112]
  bytes.replaceSubrange(5..<9,with:be(bytes.count-9))
  try Data(bytes).write(to:world.appendingPathComponent("player_data"))
  let fixtureDate = Date(timeIntervalSince1970: 1788681600)
  let fixtureTicks = UInt64(621355968000000000) + UInt64(fixtureDate.timeIntervalSince1970)*10000000
  var suffix = Array(repeating: UInt8(77), count: 105)
  for n in 0..<8 { suffix[8+n] = UInt8((fixtureTicks >> (8*(7-n))) & 255) }
  let worldBytes = Data([9] + be(123) + be(0) + be(12345678) + be(4) + Array("TEST".utf8) + suffix)
  try worldBytes.write(to:world.appendingPathComponent("world_data"))
  try Data("chunk".utf8).write(to:world.appendingPathComponent("o.0,0"))
  let library = try Library(root:root.appendingPathComponent("library"))
  let save = try library.importSave(world)
  let original = try library.verify(save)
  let result = try library.editorCopy(save,request:EditorRequest(action:"level",quantity:300),python:"",engine:root)
  precondition(result.id != save.id)
  let after = try library.verify(save)
  precondition(original == after)
  let newBytes = try Data(contentsOf:library.worldFolder(result).appendingPathComponent("player_data"))
  let parsed = try PlayerReader.parse(newBytes)
  precondition(parsed.level == 300)
  precondition(zip(bytes,Array(newBytes)).enumerated().filter { $0.element.0 != $0.element.1 }.count == 2)
  _ = try library.verify(result)
  do { _ = try library.editorCopy(save,request:EditorRequest(action:"level",quantity:2),python:"",engine:root); fatalError("Must reject level decrease") } catch {}
  let entries = try library.entries(); precondition(entries.count == 2)
  let cloned = try library.editorTestCopy(result, occupied:[save.world])
  precondition(cloned.world != save.world && cloned.world != result.world)
  let clonedHashes = try library.verify(cloned)
  let resultHashes = try library.verify(result)
  precondition(clonedHashes.filter { $0.key != "world_data" } == resultHashes.filter { $0.key != "world_data" })
  let identityBytes = try Data(contentsOf: library.worldFolder(cloned).appendingPathComponent("world_data"))
  precondition(Array(identityBytes[5..<13]) == Array(worldBytes[5..<13]))
  precondition(identityBytes.suffix(32) == worldBytes.suffix(32))
  let roundtrip = try EditorWorldIdentity.rewrite(identityBytes,source:cloned.world,target:"123",name:"TEST",savedAt:fixtureDate)
  precondition(roundtrip == worldBytes)
  let nameLength = Array(identityBytes[13..<17]).reduce(0) { ($0 << 8) | Int($1) }
  let exportedTicks = identityBytes[(17+nameLength+8)..<(17+nameLength+16)].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
  let exportDate = Date(timeIntervalSince1970: Double(exportedTicks - 621355968000000000)/10000000)
  precondition(abs(exportDate.timeIntervalSinceNow) < 60)
  do { _ = try EditorWorldIdentity.rewrite(worldBytes,source:"999",target:"456",name:"BAD"); fatalError("Must reject ID mismatch") } catch {}
  do { _ = try EditorWorldIdentity.rewrite(worldBytes,source:"123",target:"123",name:"BAD"); fatalError("Must reject same ID") } catch {}
  let fakeSource = URL(fileURLWithPath:CommandLine.arguments[1])
  let fake = root.appendingPathComponent("adb")
  try fm.copyItem(at:fakeSource,to:fake)
  try fm.setAttributes([.posixPermissions:0o755],ofItemAtPath:fake.path)
  library.adb = fake.path
  let quest = root.appendingPathComponent("quest")
  let local = quest.appendingPathComponent("sdcard/Android/data/" + library.package + "/files/local")
  try fm.createDirectory(at:local,withIntermediateDirectories:true)
  try fm.copyItem(at:library.worldFolder(save),to:local.appendingPathComponent(save.world))
  let protected = try library.localManifest(local.appendingPathComponent(save.world))
  try library.exportEditorTestWorld(cloned,serial:"TEST",expectedPackage:library.package,expectedWorlds:[save.world])
  let exported = try library.localManifest(local.appendingPathComponent(cloned.world))
  precondition(exported == clonedHashes)
  let unchanged = try library.localManifest(local.appendingPathComponent(save.world))
  precondition(protected == unchanged)
  do { try library.exportEditorTestWorld(cloned,serial:"TEST",expectedPackage:library.package,expectedWorlds:[save.world,cloned.world]); fatalError("Must reject occupied target") } catch {}
  let collisionCopy = try library.editorTestCopy(result,occupied:[save.world,cloned.world])
  try Data().write(to:quest.appendingPathComponent("collision"))
  do { try library.exportEditorTestWorld(collisionCopy,serial:"TEST",expectedPackage:library.package,expectedWorlds:[save.world,cloned.world]); fatalError("Must reject activation collision") } catch {}
  let retained = try String(contentsOf:local.appendingPathComponent(collisionCopy.world).appendingPathComponent("untouched"),encoding:.utf8)
  precondition(retained == "keep")
  try Data().write(to:quest.appendingPathComponent("running"))
  do { try library.exportEditorTestWorld(collisionCopy,serial:"TEST",expectedPackage:library.package,expectedWorlds:[save.world,cloned.world]); fatalError("Must reject running game") } catch {}
  for path in CommandLine.arguments.dropFirst(2) {
   let file = URL(fileURLWithPath:path)
   let original = try Data(contentsOf:file)
   let source = file.deletingLastPathComponent().lastPathComponent
   let nameSize = original[13..<17].reduce(0) { ($0 << 8) | Int($1) }
   let oldName = String(data:original[17..<17+nameSize],encoding:.utf8)!
   let oldTicks = original[(17+nameSize+8)..<(17+nameSize+16)].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
   let oldDate = Date(timeIntervalSince1970:Double(oldTicks-621355968000000000)/10000000)
   let new = try EditorWorldIdentity.rewrite(original,source:source,target:"123456789",name:"BETA TEST FORMAT",savedAt:Date())
   let reverted = try EditorWorldIdentity.rewrite(new,source:"123456789",target:source,name:oldName,savedAt:oldDate)
   // Date/Double has sub-microsecond precision loss; compare every non-timestamp byte.
   let offset = 17+nameSize+8
   precondition(reverted.prefix(offset) == original.prefix(offset))
   precondition(reverted.suffix(from:offset+8) == original.suffix(from:offset+8))
   let reloaded = try Data(contentsOf:file)
   precondition(reloaded == original)
   print("Read-only real-world identity regression passed: " + source)
  }
  print("Editor transport double: verified export, original preservation, occupied target, activation race and running-game rejection passed")
  print("Editor identity: ID/name roundtrip, seed and suffix preservation passed")
  print("Editor storage: level patch, original preservation, manifest and rejection passed")
 }
}
