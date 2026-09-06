import unittest,tempfile,struct
from pathlib import Path
from test_chests import chunk,record,item
from realmcraft_map.editor import patch,container

class EditorTests(unittest.TestCase):
 def run_patch(self, action, same=True):
  with tempfile.TemporaryDirectory() as folder:
   world=Path(folder); source=world/'o.-64,0'
   extra=bytes.fromhex('001801')+b'\0'*15
   source.write_bytes(chunk()+record(item(3165,12,0,extra))+b'TRAILER')
   target=source if same else world/'n.-64,0'
   if not same:target.write_bytes(chunk()[:12]+b'\x01'+chunk()[13:]+record(b'',0)+b'OTHER')
   original=source.read_bytes()
   req=dict(action=action,sourceFile=source.name,sourceChest='o:-53,68,10',sourceSlot=1,targetFile=target.name,targetChest=('o' if same else 'n')+':-53,68,10',targetSlot=4,quantity=99)
   patch(world,req)
   data=source.read_bytes(); _,_,src=container(data,source.name,'o:-53,68,10')
   _,_,dst=container(target.read_bytes(),target.name,req['targetChest'])
   self.assertTrue(data.startswith(chunk()));self.assertTrue(data.endswith(b'TRAILER'))
   if action=='quantity':self.assertEqual(struct.unpack_from('>I',src[1],32)[0],99)
   else:
    self.assertEqual(dst[4][:-6],item(3165,12,0,extra)[:-6])
    self.assertEqual(1 in src,action=='duplicate')
   if not same and action=='duplicate':self.assertEqual(source.read_bytes(),original)
 def test_duplicate_same(self):self.run_patch('duplicate')
 def test_duplicate_cross(self):self.run_patch('duplicate',False)
 def test_move_same(self):self.run_patch('move')
 def test_move_cross(self):self.run_patch('move',False)
 def test_quantity(self):self.run_patch('quantity')
 def test_rejection_and_sort(self):
  with tempfile.TemporaryDirectory() as folder:
   world=Path(folder);p=world/'o.-64,0';p.write_bytes(chunk()+record(item(3165,3,4)+item(3157,2,8),2))
   original=p.read_bytes()
   req=dict(action='duplicate',sourceFile=p.name,sourceChest='o:-53,68,10',sourceSlot=5,targetFile=p.name,targetChest='o:-53,68,10',targetSlot=9)
   with self.assertRaises(ValueError):patch(world,req)
   self.assertEqual(original,p.read_bytes())
   req['action']='sort';patch(world,req)
   _,_,items=container(p.read_bytes(),p.name,req['sourceChest'])
   self.assertEqual(list(items),[1,2]);self.assertEqual(struct.unpack_from('>H',items[1],2)[0],3157)
 def test_ambiguous_records_rejected(self):
  with tempfile.TemporaryDirectory() as folder:
   world=Path(folder);p=world/'o.-64,0'
   p.write_bytes(chunk()+record()+record())
   original=p.read_bytes()
   with self.assertRaises(ValueError):patch(world,dict(action='sort',sourceFile=p.name,sourceChest='o:-53,68,10'))
   self.assertEqual(original,p.read_bytes())
 def test_move_between_chests_in_same_chunk(self):
  from itertools import groupby
  sections=[]
  for section in range(16):
   if section!=4:sections.append(struct.pack('>I',0));continue
   values=[0]*4096
   for x in (11,12):values[4*256+x*16+10]=153
   payload=b'\0'*4
   for channel in range(4):
    runs=[]
    for value, group in groupby((v>>(channel*8))&255 for v in values):
     size=sum(1 for _ in group)
     while size>255:runs.append(0);size-=255
     runs.extend([size,value])
    payload+=bytes(runs)
   sections.append(struct.pack('>II',2,len(payload))+payload)
  prefix=struct.pack('>IiiBBB',9,-64,0,0,8,16)+b''.join(sections)
  second=bytearray(record(b'',0));struct.pack_into('>i',second,7,-52)
  with tempfile.TemporaryDirectory() as folder:
   world=Path(folder);p=world/'o.-64,0';p.write_bytes(prefix+record()+second+b'TAIL')
   patch(world,dict(action='move',sourceFile=p.name,sourceChest='o:-53,68,10',sourceSlot=1,targetFile=p.name,targetChest='o:-52,68,10',targetSlot=7))
   data=p.read_bytes()
   self.assertEqual(container(data,p.name,'o:-53,68,10')[2],{})
   self.assertEqual(list(container(data,p.name,'o:-52,68,10')[2]),[7])
   self.assertTrue(data.startswith(prefix));self.assertTrue(data.endswith(b'TAIL'))
if __name__=='__main__':unittest.main()
