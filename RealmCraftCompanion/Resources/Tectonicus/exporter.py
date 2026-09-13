"""Read-only v9 Overworld to Java 1.17.1 rendering intermediate.

Packed RealmCraft states are retained in the audit, not interpreted as Minecraft states.
"""
from pathlib import Path
import collections, gzip, hashlib, json, math, struct, zipfile, zlib
import numpy as np
from realmcraft_map.chunks import decode

def string(value):
    raw = value.encode('utf-8')
    return struct.pack('>H', len(raw)) + raw

def payload(kind, value):
    if kind == 1: return struct.pack('>b', value)
    if kind == 3: return struct.pack('>i', value)
    if kind == 4: return struct.pack('>q', value)
    if kind == 7: return struct.pack('>i', len(value)) + bytes(value)
    if kind == 8: return string(value)
    if kind == 9:
        subkind, values = value
        return bytes([subkind]) + struct.pack('>i', len(values)) + b''.join(payload(subkind, v) for v in values)
    if kind == 10:
        return b''.join(bytes([k]) + string(n) + payload(k, v) for n, k, v in value) + b'\0'
    if kind in (11, 12):
        fmt = '>i' if kind == 11 else '>Q'
        return struct.pack('>i', len(value)) + b''.join(struct.pack(fmt, int(v)) for v in value)
    raise ValueError(kind)

def nbt(compound): return b'\x0a\0\0' + payload(10, compound)

PREFER={'facing':'north','axis':'y','half':'bottom','type':'bottom','shape':'straight','part':'foot','hinge':'left','face':'floor','layers':'1','level':'0','age':'0','distance':'7','persistent':'false','snowy':'false','waterlogged':'false','open':'false','powered':'false','lit':'false','north':'false','south':'false','east':'false','west':'false','up':'true'}

def keyprops(key):return dict(part.split('=',1) for part in key.split(',') if '=' in part)
def default_props(state):
    if 'variants' in state:
        choices=[keyprops(k) for k in state['variants']]
        return max(choices,key=lambda p:sum(v==PREFER.get(k,'false') for k,v in p.items()))
    values=collections.defaultdict(set)
    def walk(condition):
        for k,v in condition.items():
            if k in ('OR','AND'):
                for item in v:walk(item)
            elif isinstance(v,str):values[k].update(v.split('|'))
    for part in state.get('multipart',[]):walk(part.get('when',{}))
    return {k:(PREFER[k] if PREFER.get(k) in v else ('none' if 'none' in v else sorted(v)[0])) for k,v in values.items()}

def build_chunk(chunk, mapping):
    sections=[];tiles=[]
    for state in np.unique(chunk.blocks):
        if mapping[int(state)]['target'].endswith('_sign'):
            for y,x,z in np.argwhere(chunk.blocks==state):
                tiles.append([('id',8,'minecraft:sign'),('x',3,chunk.x+int(x)),('y',3,int(y)),('z',3,chunk.z+int(z)),('Color',8,'black')]+[(f'Text{i}',8,'{"text":""}') for i in range(1,5)])
    for sy in range(16):
        raw=chunk.blocks[sy*16:(sy+1)*16].transpose(0,2,1).reshape(-1)
        unique,inverse=np.unique(raw,return_inverse=True)
        palette=[]
        for value in unique:
            m=mapping[int(value)];entry=[('Name',8,'minecraft:'+m['target'])]
            if m['properties']:entry.append(('Properties',10,[(k,8,v) for k,v in sorted(m['properties'].items())]))
            palette.append(entry)
        bits=max(4,(len(palette)-1).bit_length());per=64//bits
        padded=np.zeros(math.ceil(4096/per)*per,dtype=np.uint64);padded[:4096]=inverse
        packed=np.bitwise_or.reduce(padded.reshape(-1,per)<<np.arange(per,dtype=np.uint64)*bits,axis=1)
        sections.append([('Y',1,sy),('Palette',9,(10,palette)),('BlockStates',12,packed),('SkyLight',7,b'\xff'*2048),('BlockLight',7,b'\0'*2048)])
    level=[('xPos',3,chunk.x//16),('zPos',3,chunk.z//16),('Status',8,'full'),('isLightOn',1,1),('LastUpdate',4,0),('InhabitedTime',4,0),('Sections',9,(10,sections)),('Biomes',11,[1]*1024),('Entities',9,(10,[])),('TileEntities',9,(10,tiles)),('TileTicks',9,(10,[]))]
    return nbt([('DataVersion',3,2730),('Level',10,level)])


LIMITATIONS = [
    'Experimental Overworld geometry only; not a playable Minecraft world.',
    'Block orientation, fluid levels, growth, snow layers and connections use defaults.',
    'Constant plains biome, full skylight, no block light.',
    'No player data, inventories or original entities; signs have blank text.',
    'Unknown blocks use magenta concrete. Home marker is the export center.'
]


def block_mapping(raw, names, states):
    name = names.get(str(raw & 4095), 'unknown')
    target = 'air' if name in ('air', 'cave_air', 'void_air') else name
    quality = 'named-visual-equivalent'
    if target not in states and target != 'air':
        target = 'magenta_concrete'
        quality = 'unsupported-placeholder'
    props = default_props(states[target]) if target in states else {}
    if target in ('chest', 'trapped_chest'):
        props.update(facing='north', type='single', waterlogged='false')
    elif target.endswith('_bed'):
        props.update(facing='north', part='foot', occupied='false')
    elif target.endswith('_wall_sign'):
        props.update(facing='north', waterlogged='false')
    elif target.endswith('_sign'):
        props.update(rotation='0', waterlogged='false')
    elif target in ('water', 'lava'):
        props.update(level='0')
    if quality != 'unsupported-placeholder' and (props or raw >> 12):
        quality = 'default-state-approximation'
    return dict(source_name=name, target=target, properties=props, quality=quality, count=0)


def export_world(source, output, assets, radius, progress=lambda *args: None):
    import re
    source, output = Path(source).resolve(), Path(output).resolve()
    if output == source or source in output.parents or output in source.parents:
        raise ValueError('Export and source must be separate directories.')
    if output.exists():
        raise ValueError('Export destination already exists; no files were overwritten.')
    names = json.loads((Path(__file__).resolve().parent.parent / 'MapEngine/realmcraft_map/blocks.json').read_text())
    with zipfile.ZipFile(assets) as archive:
        states = {Path(p).stem: json.loads(archive.read(p)) for p in archive.namelist()
                  if p.startswith('assets/minecraft/blockstates/') and p.endswith('.json')}
    files = []
    for path in sorted(source.iterdir()):
        match = re.fullmatch(r'o\.(-?\d+),(-?\d+)', path.name)
        if not match:
            continue
        if path.is_symlink() or not path.is_file():
            raise ValueError('Chunk must be a regular file: ' + path.name)
        x, z = map(int, match.groups())
        if x % 16 or z % 16:
            raise ValueError('Chunk coordinate must be aligned to 16 blocks.')
        if radius and (x >= radius or z >= radius or x+15 < -radius or z+15 < -radius):
            continue
        files.append(path)
    if not files:
        raise ValueError('No Overworld chunks in the selected area. Choose all saved chunks or another backup.')
    output.mkdir(parents=True)
    for folder in ('region', 'players', 'playerdata'):
        (output / folder).mkdir()
    mapping, hashes, regions = {}, {}, set()
    bounds = [2**31, 2**31, -2**31, -2**31]
    for index, path in enumerate(files):
        data = path.read_bytes()
        hashes[path.name] = hashlib.sha256(data).hexdigest()
        chunk = decode(data, path.name)
        if chunk.x % 16 or chunk.z % 16:
            raise ValueError('Invalid chunk alignment: ' + path.name)
        unique, counts = np.unique(chunk.blocks, return_counts=True)
        for raw, count in zip(unique, counts):
            raw = int(raw)
            if raw not in mapping:
                mapping[raw] = block_mapping(raw, names, states)
            mapping[raw]['count'] += int(count)
        compressed = zlib.compress(build_chunk(chunk, mapping))
        record = struct.pack('>I', len(compressed)+1) + b'\x02' + compressed
        cx, cz = chunk.x//16, chunk.z//16
        region = output / 'region' / f'r.{cx//32}.{cz//32}.mca'
        if region not in regions:
            region.write_bytes(b'\0'*8192)
            regions.add(region)
        slot = cx % 32 + (cz % 32)*32
        with region.open('r+b') as stream:
            stream.seek(slot*4)
            if stream.read(4) != b'\0'*4:
                raise ValueError('Duplicate chunk coordinates: ' + path.name)
            stream.seek(0, 2)
            offset = stream.tell()//4096
            count = math.ceil(len(record)/4096)
            if count > 255 or offset > 0xffffff:
                raise ValueError('Region record exceeds Anvil bounds.')
            stream.write(record.ljust(count*4096, b'\0'))
            stream.seek(slot*4)
            stream.write((offset << 8 | count).to_bytes(4, 'big'))
            stream.seek(4096+slot*4)
            stream.write(struct.pack('>I', 1))
        bounds = [min(bounds[0], chunk.x), min(bounds[1], chunk.z),
                  max(bounds[2], chunk.x+15), max(bounds[3], chunk.z+15)]
        if (index+1) % 20 == 0 or index+1 == len(files):
            progress('export', f'{index+1}/{len(files)} chunks', (index+1)/len(files))
    # Detect source changes during the export before a render is accepted.
    for path in files:
        if hashlib.sha256(path.read_bytes()).hexdigest() != hashes[path.name]:
            raise ValueError('Source changed during export: ' + path.name)
    cx, cz = (bounds[0]+bounds[2])//2, (bounds[1]+bounds[3])//2
    level = [('DataVersion',3,2730),('version',3,19133),('LevelName',8,'RealmCraft rendering export'),
             ('SpawnX',3,cx),('SpawnY',3,80),('SpawnZ',3,cz),('RandomSeed',4,0),('LastPlayed',4,0),
             ('Version',10,[('Id',3,2730),('Name',8,'1.17.1'),('Snapshot',1,0)])]
    (output/'level.dat').write_bytes(gzip.compress(nbt([('Data',10,level)]), mtime=0))
    result = dict(chunks=len(files), regions=len(regions), bounds=bounds, mappings=mapping,
                  source_sha256=hashes, limitations=LIMITATIONS, target='Minecraft Java 1.17.1 / DataVersion 2730',
                  placeholders=sum(m['count'] for m in mapping.values() if m['quality']=='unsupported-placeholder'))
    (output/'export-manifest.json').write_text(json.dumps(result, indent=2)+'\n')
    return result
