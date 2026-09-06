"""Execute the production annotation-copy helper with isolated preferences."""
import pathlib, subprocess, tempfile, unittest
class AnnotationTransferTest(unittest.TestCase):
 def test_copy_is_independent_and_preserves_existing_target(self):
  source=(pathlib.Path(__file__).parents[1]/'Sources/Library.swift').read_text().split('enum AnnotationTransfer {',1)[1]
  program='import Foundation\nenum AnnotationTransfer {'+source+'''
let d = UserDefaults(suiteName: "annotation-test-" + UUID().uuidString)!
let domain = d.volatileDomainNames
for p in AnnotationTransfer.prefixes { assert(d.object(forKey:p+"new") == nil) }
d.set(["o:1,2,3"],forKey:"conversation.ownedChests.old")
d.set(["tag":"Home"],forKey:"atlasPOI.old")
d.set([["name":"Farm","x":1,"z":2,"dimension":"o"]],forKey:"atlasMarkers.old")
d.set(["o:4,5,6"],forKey:"chests.visibility.old.hidden")
AnnotationTransfer.copy(from:"old",to:"new",defaults:d)
assert(d.stringArray(forKey:"conversation.ownedChests.new") == ["o:1,2,3"])
assert(d.array(forKey:"atlasMarkers.new")?.count == 1)
assert(d.stringArray(forKey:"chests.visibility.new.hidden") == ["o:4,5,6"])
d.set(["tag":"Edited"],forKey:"atlasPOI.new")
AnnotationTransfer.copy(from:"old",to:"new",defaults:d)
assert(d.dictionary(forKey:"atlasPOI.new")?["tag"] as? String == "Edited")
assert(d.dictionary(forKey:"atlasPOI.old")?["tag"] as? String == "Home")
assert(d.object(forKey:"atlasPOI.declined") == nil)
for key in d.dictionaryRepresentation().keys where key.contains(".old") || key.contains(".new") { d.removeObject(forKey:key) }
print("Annotation transfer passed")
'''
  with tempfile.TemporaryDirectory() as tmp:
   path=pathlib.Path(tmp)/'test.swift';path.write_text(program)
   subprocess.run(['xcrun','swift','-module-cache-path','/tmp/realmcraft-swift-module-cache',str(path)],check=True)
if __name__=='__main__':unittest.main()
