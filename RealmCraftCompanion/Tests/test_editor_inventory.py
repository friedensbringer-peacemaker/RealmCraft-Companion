import unittest,tempfile,struct
from pathlib import Path
from test_chests import item,chunk,record
from realmcraft_map.editor import patch,player_container,container

def player(items=None,armor=None):
 if items is None:items=[item(3157,12,0),item(3004,1,33,bytes.fromhex('001801')+struct.pack('>II',100,2)+bytes.fromhex('003b00')+struct.pack('>IHI',1,7,4))]
 if armor is None:armor=[item(3047,1,0)]
 data=bytearray(bytes([2,0,0,0,1])+b'\0'*133+bytes.fromhex('000d01')+struct.pack('>I',7))
 for capacity,body in [(36,items),(4,armor)]:data+=b'\x01'+struct.pack('>II',capacity,len(body))+b''.join(body)
 data+=bytes.fromhex('002901')+b'\0'*11+struct.pack('<I',501)+bytes.fromhex('00008fbe70')+b'OPAQUE TAIL'
 struct.pack_into('>I',data,5,len(data)-9)
 return bytes(data)

class InventoryEditorTests(unittest.TestCase):
 def test_duplicate_last_slot_preserves_armor_and_suffix(self):
  with tempfile.TemporaryDirectory() as td:
   root=Path(td);p=root/'player_data';before=player();p.write_bytes(before)
   old_end=player_container(before)[1]
   patch(root,dict(action='duplicate',sourceFile='player_data',sourceChest='inventory',sourceSlot=34,targetFile='player_data',targetChest='inventory',targetSlot=36))
   after=p.read_bytes();_,end,items=player_container(after)
   self.assertEqual(set(items),{1,34,36});self.assertEqual(items[34][:-6],items[36][:-6])
   self.assertEqual(after[end:],before[old_end:]);self.assertEqual(struct.unpack_from('>I',after,5)[0],len(after)-9)
 def test_transfer_in_both_directions(self):
  for reverse in (False,True):
   with self.subTest(reverse=reverse),tempfile.TemporaryDirectory() as td:
    root=Path(td);p=root/'player_data';c=root/'o.-64,0'
    p.write_bytes(player());c.write_bytes(chunk()+record(item(3165,4,0)))
    source=('o.-64,0','o:-53,68,10',1) if reverse else ('player_data','inventory',34)
    target=('player_data','inventory',36) if reverse else ('o.-64,0','o:-53,68,10',27)
    patch(root,dict(action='move',sourceFile=source[0],sourceChest=source[1],sourceSlot=source[2],targetFile=target[0],targetChest=target[1],targetSlot=target[2]))
    inventory=player_container(p.read_bytes())[2];chest=container(c.read_bytes(),c.name,'o:-53,68,10')[2]
    self.assertEqual(1 in chest,not reverse);self.assertEqual(34 in inventory,reverse)
    self.assertIn(36,inventory) if reverse else self.assertIn(27,chest)
 def test_rejections_leave_original_unchanged(self):
  with tempfile.TemporaryDirectory() as td:
   root=Path(td);p=root/'player_data';before=player();p.write_bytes(before)
   for target in (1,34,37,0):
    with self.assertRaises(ValueError):patch(root,dict(action='duplicate',sourceFile='player_data',sourceChest='inventory',sourceSlot=1,targetFile='player_data',targetChest='inventory',targetSlot=target))
    self.assertEqual(p.read_bytes(),before)
   damaged=bytearray(before);damaged[5:9]=b'\0'*4
   with self.assertRaises(ValueError):player_container(damaged)
 def test_quantity_sort_and_empty_inventory(self):
  with tempfile.TemporaryDirectory() as td:
   root=Path(td);p=root/'player_data';p.write_bytes(player())
   patch(root,dict(action='quantity',sourceFile='player_data',sourceChest='inventory',sourceSlot=1,quantity=64))
   self.assertEqual(struct.unpack_from('>I',player_container(p.read_bytes())[2][1],32)[0],64)
   patch(root,dict(action='sort',sourceFile='player_data',sourceChest='inventory'))
   self.assertEqual(list(player_container(p.read_bytes())[2]),[1,2])
   self.assertEqual(player_container(player([]))[2],{})
if __name__=='__main__':unittest.main()
