import sys,unittest,numpy as np
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'Resources/MapEngine'))
from realmcraft_map.chunks import Chunk
from realmcraft_map.points import points_for_columns,finalize,KINDS
class PointTests(unittest.TestCase):
 def test_underground_objects_and_glass_groups(self):
  blocks=np.zeros((256,16,16),dtype=np.uint32);blocks[55,2,3]=153;blocks[56,3,3]=58
  # Resolve the actual crafting-table registry ID instead of Minecraft's IDs.
  from realmcraft_map.palette import NAMES
  table=next(i for i,n in NAMES.items()if n=='crafting_table');glass=next(i for i,n in NAMES.items()if n=='glass')
  blocks[56,3,3]=table;blocks[60:64,5,5]=glass
  result=points_for_columns(Chunk(-32,0,0,blocks,0).columns(),-32,0)
  chest=next(p for p in result if p['kind']=='chest');self.assertEqual((chest['x'],chest['y'],chest['z']),(-30,55,3))
  self.assertEqual(next(p['count']for p in result if p['kind']=='glass'),4)
  buildings=[p for p in finalize(result,'o')if p['kind']=='building'];self.assertEqual(len(buildings),1)
 def test_one_indicator_is_not_a_building(self):
  points=[{'kind':'chest','x':0,'y':64,'z':0,'count':1}]
  self.assertFalse(any(p['kind']=='building'for p in finalize(points,'o')))
if __name__=='__main__':unittest.main()
