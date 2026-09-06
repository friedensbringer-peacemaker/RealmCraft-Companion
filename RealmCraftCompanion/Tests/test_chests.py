import sys,struct,tempfile,unittest,hashlib
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'Resources/MapEngine'))
from realmcraft_map.chests import read_slots,scan_chunk

def item(id=3165,quantity=12,slot=0,extra=b''):
 return struct.pack('>I',id)+bytes.fromhex('0001020037')+bytes(range(16))+bytes.fromhex('000801')+struct.pack('>II',id,quantity)+b'\0'*4+extra+bytes.fromhex('000c00')+struct.pack('>I',slot)+b'\xff\xff'
def record(body=None,count=1):
 if body is None:body=item()
 return b'\x00\x99'+struct.pack('>I',22+len(body))+b'\x01'+struct.pack('>iii',-53,68,10)+b'\x01'+struct.pack('>II',27,count)+body

def chunk(block=153):
 sections=[]
 for section in range(16):
  if section!=4:sections.append(struct.pack('>I',0));continue
  values=[0]*4096;values[4*256+11*16+10]=block
  payload=b'\0'*4
  for channel in range(4):
   vals=[(v>>(channel*8))&255 for v in values];runs=[];i=0
   while i<len(vals):
    j=i+1
    while j<len(vals) and vals[j]==vals[i]:j+=1
    size=j-i
    while size>255:runs.append(0);size-=255
    runs.extend([size,vals[i]]);i=j
   payload+=bytes(runs)
  sections.append(struct.pack('>II',1,len(payload))+payload)
 return struct.pack('>IiiBBB',9,-64,0,0,8,16)+b''.join(sections)

class ChestTests(unittest.TestCase):
 def test_known_slots_and_extra_data(self):
  items=read_slots(item()+item(3157,44,2,b'\x00\x18\x01'+b'\x00'*15),2)
  self.assertEqual([(i['itemID'],i['quantity'],i['slot'])for i in items],[(3165,12,1),(3157,44,3)])
  self.assertTrue(items[1]['extraData'])
 def test_reject_bad_count_duplicate_and_mismatched_ids(self):
  for data,count in [(item(),2),(item()+item(),2),(item()[:-1],1),(item()+b'garbage',1)]:
   with self.assertRaises(ValueError):read_slots(data,count)
  bad=bytearray(item());bad[31]^=1
  with self.assertRaises(ValueError):read_slots(bytes(bad),1)
 def test_empty_is_only_exact_empty(self):
  self.assertEqual(read_slots(b'',0),[])
  with self.assertRaises(ValueError):read_slots(b'x',0)
 def test_coordinate_and_block_validation_and_read_only(self):
  with tempfile.TemporaryDirectory()as td:
   p=Path(td)/'o.-64,0';p.write_bytes(chunk()+record());before=hashlib.sha256(p.read_bytes()).digest()
   result,errors=scan_chunk(p);self.assertFalse(errors);self.assertTrue(result[0]['readable']);self.assertEqual(result[0]['items'][0]['quantity'],12)
   self.assertEqual(hashlib.sha256(p.read_bytes()).digest(),before)
   p.write_bytes(chunk(1)+record());self.assertEqual(scan_chunk(p),([],[]))
   p.write_bytes(chunk()+record(count=2));result,errors=scan_chunk(p);self.assertTrue(errors);self.assertFalse(result[0]['readable']);self.assertEqual(result[0]['items'],[])
 def test_duplicate_records_are_not_counted_twice(self):
  with tempfile.TemporaryDirectory()as td:
   p=Path(td)/'o.-64,0';p.write_bytes(chunk()+record()+record());rows,errors=scan_chunk(p)
   self.assertEqual(len(rows),1);self.assertFalse(rows[0]['readable']);self.assertTrue(errors)
if __name__=='__main__':unittest.main()
