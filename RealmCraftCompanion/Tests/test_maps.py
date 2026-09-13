import hashlib,json,tempfile,unittest
from pathlib import Path
from test_chests import chunk
from realmcraft_map.build import build
class MapTests(unittest.TestCase):
 def test_offline_map_points_biomes_cache_and_read_only_source(self):
  with tempfile.TemporaryDirectory()as td:
   root=Path(td);world=root/'world';world.mkdir();p=world/'o.-64,0';p.write_bytes(chunk()+bytes([4]*16));digest=hashlib.sha256(p.read_bytes()).digest()
   result=build(world,root/'map',cache=root/'cache',workers=1)
   dim=result['dimensions']['o'];self.assertEqual(dim['biomes']['-64,0'],[4]*16)
   self.assertTrue(any(p['kind']=='chest' for p in dim['points']));self.assertEqual(result['biomeNames']['4']['en'],'Forest')
   for name in ['index.html','points.js','biomes.js','metro.js','metro.css','focus-target.js','tool-coordinator.js','tiles/o/terrain/0-0-0.png']:self.assertTrue((root/'map'/name).exists())
   second=build(world,root/'map',cache=root/'cache',workers=1)
   self.assertEqual(second['dimensions']['o']['biomes'],dim['biomes']);self.assertEqual(hashlib.sha256(p.read_bytes()).digest(),digest)
   with self.assertRaises(ValueError):build(world,world/'bad')
if __name__=='__main__':unittest.main()
