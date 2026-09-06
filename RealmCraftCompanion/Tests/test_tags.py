import sys, unittest
from pathlib import Path
from collections import Counter
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'Resources/MapEngine'))
from realmcraft_map.tags import collect,suggest
from realmcraft_map.chunks import Chunk

class TagTests(unittest.TestCase):
 def test_columns_count_negative_chunks_and_vertical_segments(self):
  blocks=np.zeros((256,16,16),dtype=np.uint32);blocks[63,0:8,0:8]=160;blocks[64,0:8,0:8]=159
  cells={};collect(Chunk(-16,-16,0,blocks,0).columns(),-16,-16,cells)
  self.assertEqual(cells[(-1,3,-1)]['farmland'],64);self.assertEqual(cells[(-1,4,-1)]['wheat'],64)
  self.assertEqual(suggest(cells,'o',{}),[]) # no cross-floor contamination
 def test_thresholds_and_dimension(self):
  cells={(0,4,0):Counter(wheat=32,farmland=32),(2,2,0):Counter(rails=12,torches=3),(4,4,0):Counter(bricks=100,fortress_details=16)}
  self.assertEqual({p['tagType']for p in suggest(cells,'o',{})},{'wheat_farm','mine'})
  self.assertIn('fortress',{p['tagType']for p in suggest(cells,'n',{})})
  self.assertEqual(suggest({(0,4,0):Counter(bricks=1000,rails=30)},'n',{}),[])
 def test_storage_needs_readable_inventory_and_records_privacy_sources(self):
  cells={(0,4,0):Counter(chests=4)}
  chests={str(i):dict(x=i,y=68,z=0,readable=True,items=[{'slot':j,'itemID':1,'quantity':64}for j in range(4)])for i in range(4)}
  tag=suggest(cells,'o',chests)[0];self.assertEqual(tag['tagType'],'storage');self.assertEqual(tag['evidence']['stacks'],16);self.assertEqual(len(tag['sourceChests']),4)
  for c in chests.values():c['readable']=False
  self.assertEqual(suggest(cells,'o',chests),[])
if __name__=='__main__':unittest.main()
