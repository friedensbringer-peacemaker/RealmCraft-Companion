"""Experimental chest patches. Called only on a verified, disposable world copy."""
import json, struct, sys
from pathlib import Path
from .chests import ENTRY, scan_data, read_slots
from .chunks import FILENAME

def container(data, filename, identity):
    records, errors = scan_data(data, filename)
    selected = [r for r in records if r['id'] == identity and r['readable']]
    if errors or len(selected) != 1:
        raise ValueError('Unsupported or ambiguous chest / Nicht unterstützte Kiste')
    r = selected[0]
    matches = []
    for i in range(len(data)-27):
        if data[i:i+2] not in (b'\x00\x99', b'\x01\x56'): continue
        if data[i+6] != 1 or struct.unpack_from('>iii', data, i+7) != (r['x'],r['y'],r['z']): continue
        end = i+6+struct.unpack_from('>I',data,i+2)[0]
        if end > len(data) or data[i+19:i+24] != b'\x01\x00\x00\x00\x1b': continue
        body = data[i+28:end]
        try: read_slots(body, struct.unpack_from('>I',data,i+24)[0])
        except ValueError: continue
        starts = [m.start() for m in ENTRY.finditer(body)]+[len(body)]
        items = {struct.unpack_from('>I',body,starts[n+1]-6)[0]+1: body[start:starts[n+1]] for n,start in enumerate(starts[:-1])}
        matches.append((i,end,items))
    if len(matches) != 1: raise ValueError('Ambiguous container bounds')
    return matches[0]


def player_container(data):
    """Strict observed player v2 inventory; armor and opaque suffix remain intact."""
    def need(ok):
        if not ok: raise ValueError('Unsupported player inventory / Nicht unterstütztes Spielerinventar')
    def number(p):
        need(0 <= p <= len(data)-4)
        return struct.unpack_from('>I',data,p)[0]
    need(150 <= len(data) <= 4_000_000 and data[:5] == bytes([2,0,0,0,1]))
    need(number(5) == len(data)-9)
    anchors=[i for i in range(len(data)-12) if data[i:i+3]==bytes([0,13,1]) and data[i+7:i+12]==bytes([1,0,0,0,36])]
    need(len(anchors)==1)
    p=anchors[0]+7
    inventory_start=p
    inventory_end=None
    inventory={}
    for capacity in (36,4):
        need(data[p:p+1]==b'\x01' and number(p+1)==capacity)
        count=number(p+5);need(count<=capacity);p+=9
        seen=set()
        for _ in range(count):
            start=p;identity=number(p)
            need(0<identity<=65535 and data[p+4:p+9]==bytes([0,1,2,0,55]) and data[p+25:p+28]==bytes([0,8,1]))
            need(number(p+28)==identity and 0<number(p+32)<=2147483647)
            p+=36;need(data[p:p+4]==b'\0'*4);p+=4
            if data[p:p+3]==bytes([0,24,1]):
                need(number(p+3)<=2147483647 and number(p+7)<=2147483647);p+=11
                need(data[p:p+3]==bytes([0,59,0]));effects=number(p+3);need(effects<=256);p+=7
                effect_ids=set()
                for _ in range(effects):
                    need(p+6<=len(data));effect=struct.unpack_from('>H',data,p)[0]
                    need(effect not in effect_ids and 0<number(p+2)<=2147483647);effect_ids.add(effect);p+=6
            need(data[p:p+3]==bytes([0,12,0]));slot=number(p+3)+1
            need(1<=slot<=capacity and slot not in seen and data[p+7:p+9]==b'\xff\xff');seen.add(slot);p+=9
            if capacity==36:inventory[slot]=data[start:p]
        if capacity==36:inventory_end=p
    return inventory_start,inventory_end,inventory

def get_container(data, filename, identity):
    if filename=='player_data':
        if identity!='inventory':raise ValueError('Unsupported player container')
        return player_container(data)
    return container(data,filename,identity)

def replace_player(data, items):
    start,end,_=player_container(data)
    body=b''
    for slot,raw in sorted(items.items()):
        if not 1<=slot<=36:raise ValueError('Inventory slot must be 1–36')
        raw=bytearray(raw);struct.pack_into('>I',raw,len(raw)-6,slot-1);body+=raw
    header=bytearray(data[start:start+9]);struct.pack_into('>I',header,5,len(items))
    result=bytearray(data[:start]+header+body+data[end:])
    struct.pack_into('>I',result,5,len(result)-9)
    player_container(result)
    return bytes(result)

def replace(data, filename, identity, items):
    if filename == "player_data": return replace_player(data, items)
    start,end,_ = container(data,filename,identity)
    body = b''
    for slot, raw in sorted(items.items()):
        if not 1 <= slot <= 27: raise ValueError('Slot must be 1–27')
        raw = bytearray(raw); struct.pack_into('>I',raw,len(raw)-6,slot-1); body += raw
    read_slots(body,len(items))
    header = bytearray(data[start:start+28])
    struct.pack_into('>I',header,2,22+len(body)); struct.pack_into('>I',header,24,len(items))
    result = data[:start]+header+body+data[end:]
    container(result,filename,identity)
    return result

def patch(world, request):
    def path(key):
        name = request[key]
        if name != 'player_data' and not FILENAME.fullmatch(name): raise ValueError('Invalid chunk filename')
        p = world/name
        if p.is_symlink() or not p.is_file(): raise ValueError('Invalid chunk file')
        return p
    src = path('sourceFile'); original = src.read_bytes()
    _,_,items = get_container(original,src.name,request['sourceChest'])
    action = request['action']
    if action == 'sort':
        ordered = sorted(items.values(),key=lambda b:(struct.unpack_from('>H',b,2)[0],-struct.unpack_from('>I',b,32)[0]))
        src.write_bytes(replace(original,src.name,request['sourceChest'],dict(enumerate(ordered,1))))
        return
    if action not in ('duplicate','move','quantity'): raise ValueError('Unknown action')
    slot = request['sourceSlot']
    if slot not in items: raise ValueError('Source slot is empty / Quellslot ist leer')
    raw = items[slot]
    if action == 'quantity':
        quantity = request['quantity']
        if not 1 <= quantity <= 2147483647: raise ValueError('Invalid quantity')
        raw = bytearray(raw); struct.pack_into('>I',raw,32,quantity); items[slot] = bytes(raw)
        src.write_bytes(replace(original,src.name,request['sourceChest'],items)); return
    dst = path('targetFile'); target = dst.read_bytes()
    _,_,dest = get_container(target,dst.name,request['targetChest'])
    target_slot = request['targetSlot']
    if not 1 <= target_slot <= (36 if dst.name=='player_data' else 27) or target_slot in dest: raise ValueError('Target slot must be valid and empty / Zielslot muss gültig und leer sein')
    same = src == dst and request['sourceChest'] == request['targetChest']
    if same: dest = items
    dest[target_slot] = raw
    if action == 'move': del items[slot]
    if same:
        src.write_bytes(replace(original,src.name,request['sourceChest'],dest))
    elif src == dst:
        updated = replace(original,src.name,request['sourceChest'],items)
        src.write_bytes(replace(updated,src.name,request['targetChest'],dest))
    else:
        updated = replace(target,dst.name,request['targetChest'],dest)
        source_updated = replace(original,src.name,request['sourceChest'],items)
        dst.write_bytes(updated); src.write_bytes(source_updated)

def main():
    patch(Path(sys.argv[1]),json.loads(Path(sys.argv[2]).read_text()))
if __name__ == '__main__': main()
