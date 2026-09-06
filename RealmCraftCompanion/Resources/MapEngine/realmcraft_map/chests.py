"""Read-only v9 chest records. Requires bounded records, matching chest blocks,
coordinates, item counts, IDs and slot footers. Unknown layouts are never empty.
"""
from pathlib import Path
import argparse, concurrent.futures, hashlib, json, re, struct
from .chunks import decode, FILENAME
ENTRY=re.compile(rb'\x00\x00..\x00\x01\x02\x00\x37.{16}\x00\x08\x01',re.S)
CHESTS={153,342}
def read_slots(body,count):
    starts=[m.start() for m in ENTRY.finditer(body)]
    if count==0:
        if body:raise ValueError('Unexpected data in empty container')
        return []
    if len(starts)!=count or not starts or starts[0]!=0:raise ValueError('Unsupported item serialization')
    slots=[];seen=set()
    for n,start in enumerate(starts):
        item=body[start:starts[n+1] if n+1<len(starts) else len(body)]
        if len(item)<49 or item[-9:-6]!=b'\x00\x0c\x00' or item[-2:]!=b'\xff\xff':raise ValueError('Unsupported slot footer')
        identity=struct.unpack_from('>H',item,2)[0]
        if item[28:30]!=b'\x00\x00' or identity!=struct.unpack_from('>H',item,30)[0]:raise ValueError('Item IDs disagree')
        quantity=struct.unpack_from('>I',item,32)[0];slot=struct.unpack_from('>I',item,len(item)-6)[0]
        if not 0<quantity<=2147483647 or slot>=27 or slot in seen:raise ValueError('Invalid quantity or slot')
        seen.add(slot);slots.append({'slot':slot+1,'itemID':identity,'quantity':quantity,'extraData':len(item)>49})
    return slots

def scan_data(data, filename, chunk=None):
    """Parse the exact bytes used by the map; optionally reuse its decoded blocks."""
    match=FILENAME.fullmatch(filename)
    if not match:return [],[]
    if len(data)<15 or struct.unpack_from('>I',data)[0]!=9:return [],[filename+': unsupported chunk version/header']
    x,z=int(match[2]),int(match[3]);candidates=[]
    for marker in [b'\x00\x99',b'\x01\x56']:
        pos=0
        while True:
            i=data.find(marker,pos)
            if i<0:break
            pos=i+2
            if i+19>len(data) or data[i+6]!=1:continue
            cx,cy,cz=struct.unpack_from('>iii',data,i+7)
            if x<=cx<x+16 and z<=cz<z+16 and 0<=cy<256:candidates.append((i,cx,cy,cz))
    if not candidates:return [],[]
    try:chunk=chunk if chunk is not None else decode(data,filename)
    except ValueError as e:return [],[filename+': '+str(e)]
    chests=[];errors=[];seen=set()
    for i,cx,cy,cz in candidates:
        if i<chunk.block_data_end or int(chunk.blocks[cy,cx-x,cz-z]&4095) not in CHESTS:continue
        key=(cx,cy,cz);record={'id':f'{match[1]}:{cx},{cy},{cz}','dimension':match[1],'x':cx,'y':cy,'z':cz,'file':filename,'items':[],'readable':False,'error':''}
        try:
            if key in seen:raise ValueError('Duplicate container coordinates')
            size=struct.unpack_from('>I',data,i+2)[0];end=i+6+size
            if i+28>len(data) or size<22 or end>len(data) or data[i+19:i+24]!=b'\x01\x00\x00\x00\x1b':raise ValueError('Unsupported container layout')
            count=struct.unpack_from('>I',data,i+24)[0]
            if count>27:raise ValueError('Unsupported slot count')
            record['items']=read_slots(data[i+28:end],count);record['readable']=True
        except ValueError as e:record['error']=str(e);errors.append(record['id']+': '+str(e))
        if key in seen:
            for previous in chests:
                if previous['id']==record['id']:previous.update(readable=False,items=[],error='Duplicate container coordinates')
        else:chests.append(record)
        seen.add(key)
    return chests,errors

def scan_chunk(path):
    data=path.read_bytes()
    result=scan_data(data,path.name)
    if hashlib.sha256(path.read_bytes()).digest()!=hashlib.sha256(data).digest():raise ValueError(path.name+': file changed during indexing')
    return result

def classify_sign_chests(chests, signs):
    """30-block horizontal radius, at most 10 blocks vertically, same dimension, across chunk boundaries. Text is irrelevant."""
    from collections import defaultdict
    buckets = defaultdict(list)
    for sign in signs:
        dimension = sign['id'].split(':', 1)[0]
        buckets[(dimension, sign['x']//30, sign['y']//10, sign['z']//30)].append(sign)
    for chest in chests:
        chest.pop('nearbySign', None)
        x, y, z = chest['x'], chest['y'], chest['z']
        nearest = None
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    for sign in buckets[(chest['dimension'], x//30+dx, y//10+dy, z//30+dz)]:
                        horizontal = (x-sign['x'])**2 + (z-sign['z'])**2
                        height = abs(y-sign['y'])
                        distance = horizontal + height**2
                        candidate = (distance, sign['id'])
                        if horizontal <= 900 and height <= 10 and (nearest is None or candidate < nearest):
                            nearest = candidate
        if nearest is not None:
            chest['nearbySign'] = nearest[1]
    return chests


def scan_chunk_with_signs(path):
    from .signs import scan_data as scan_signs
    data = path.read_bytes()
    try:
        decoded = decode(data, path.name)
        chests, errors = scan_data(data, path.name, decoded)
        signs, _ = scan_signs(data, path.name, decoded)
    except ValueError as error:
        chests, errors, signs = [], [path.name + ': ' + str(error)], []
    if hashlib.sha256(path.read_bytes()).digest() != hashlib.sha256(data).digest():
        raise ValueError(path.name + ': file changed during indexing')
    return chests, errors, signs

def main():
    p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args()
    if a.output.resolve().is_relative_to(a.source.resolve()):p.error('Output must be outside the savegame')
    files=sorted(f for f in a.source.iterdir() if FILENAME.fullmatch(f.name) and f.is_file() and not f.is_symlink())
    if not files:p.error('No saved chunks found')
    result={'schema':2,'chunksScanned':len(files),'chests':[],'errors':[]}
    signs=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        for count,(chests,errors,chunk_signs) in enumerate(pool.map(scan_chunk_with_signs,files),1):
            signs.extend(chunk_signs)
            result['chests'].extend(chests);result['errors'].extend(errors)
            if count%2000==0:print(f'Indexed {count}/{len(files)} chunks',flush=True)
    classify_sign_chests(result['chests'], signs)
    result['chests'].sort(key=lambda c:(c['dimension'],c['x'],c['z'],c['y']))
    a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,ensure_ascii=False,indent=2))
    print(f"Found {len(result['chests'])} chest records; {len(result['errors'])} issues",flush=True)
    return 0
if __name__=='__main__':raise SystemExit(main())
