"""Read-only ore census and paired fixed-volume mining trials for observed v9 saves."""
from pathlib import Path
import argparse, hashlib, json, re, random, base64
import numpy as np
from .chunks import decode, AIR, ChunkError
from .chests import scan_data as read_chests, classify_sign_chests
from .signs import scan_data as read_signs

GROUPS = {
    'coal': (35,36), 'iron': (33,34), 'copper': (826,827), 'gold': (31,32),
    'lapis': (73,74), 'redstone': (187,188), 'diamond': (155,156),
    'emerald': (281,282), 'quartz': (348,), 'nether_gold': (37,), 'debris': (749,)
}
# Versioned, explicit categories for the selected-area resource report.  These
# count world blocks only; inventories and chest contents are deliberately out
# of scope.  Names and IDs are observed in blocks.json, not inferred from a
# material name at scan time.
MATERIALS = {
    **GROUPS,
    'stone': (1, 871),
    'special_stone': (2, 4, 6, 817, 818),
    'amethyst': (811, 812, 813, 814, 815, 816),
    'chest': (153, 283, 342),
    'rail': (97, 98, 170, 354),
    'spawner': (151,),
    'planks': (13, 14, 15, 16, 17, 18, 718, 719, 900),
}
NAMES = json.loads(Path(__file__).with_name('blocks.json').read_text())
KNOWN = np.array([int(k) for k in NAMES])
AIR_IDS = tuple(int(k) for k,v in NAMES.items() if v in ('air','cave_air','void_air'))


def validate_bounds(bounds):
    x0,x1,y0,y1,z0,z1 = bounds
    if not (-30_000_000 <= x0 <= x1 <= 30_000_000 and
            -30_000_000 <= z0 <= z1 <= 30_000_000 and 0 <= y0 <= y1 <= 255):
        raise ValueError('Invalid bounds / Ungültiger Bereich')
    expected = (x1//16-x0//16+1)*(z1//16-z0//16+1)
    if expected > 4096:
        raise ValueError('Choose at most 4096 chunks / Höchstens 4096 Chunks wählen')
    return expected


def _load(world, name, hashes):
    path = world / name
    if not path.exists():
        return None
    if path.is_symlink() or not path.is_file():
        raise ValueError('Not a regular chunk file: '+name)
    data = path.read_bytes()
    hashes[name] = hashlib.sha256(data).hexdigest()
    return data, decode(data, name)


def _unchanged(world, hashes):
    for name,digest in hashes.items():
        path = world/name
        if path.is_symlink() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise ValueError('Source changed during scan: '+name)


def counts(ids):
    return {key:int(np.isin(ids,values).sum()) for key,values in GROUPS.items()}


def scan(world, dimension, bounds, before=None, spatial=False):
    world = Path(world).resolve(strict=True)
    before = Path(before).resolve(strict=True) if before is not None else None
    expected = validate_bounds(bounds)
    if dimension not in ('o','n'): raise ValueError('Unsupported dimension')
    if before == world: raise ValueError('Select two different snapshots')
    x0,x1,y0,y1,z0,z1 = bounds
    hashes, old_hashes, missing, errors, metadata_errors = {},{},{},[],[]
    ys = [dict(y=y,blocks=0,nonAir=0,unknown=0,ores={k:0 for k in GROUPS},
               materials={k:0 for k in MATERIALS}) for y in range(y0,y1+1)]
    pair = dict(volume=(x1-x0+1)*(y1-y0+1)*(z1-z0+1), compared=0, beforeAir=0,
                removed=0, remaining=0, otherChanges=0, unknown=0, counts={k:0 for k in GROUPS}) if before else None
    chests, old_chests, signs, old_signs = [],[],[],[]
    scanned = 0
    biome_totals = {}
    # Bounded interactive volume. uint16 sentinel distinguishes missing from air.
    volume = (x1-x0+1)*(y1-y0+1)*(z1-z0+1)
    cube = np.full((y1-y0+1,z1-z0+1,x1-x0+1),65535,dtype='<u2') if spatial and volume <= 4_194_304 else None
    areas = []
    for cx in range(x0//16*16,x1//16*16+1,16):
        for cz in range(z0//16*16,z1//16*16+1,16):
            name = f'{dimension}.{cx},{cz}'
            try:
                loaded = _load(world,name,hashes)
                prior = _load(before,name,old_hashes) if before else None
                if loaded is None or (before and prior is None):
                    missing[name] = 'after' if loaded is None else 'before'
                    continue
                data,chunk = loaded
                a = chunk.blocks[y0:y1+1,max(x0-cx,0):min(x1-cx+1,16),max(z0-cz,0):min(z1-cz+1,16)] & 4095
                material_by_y = {key:np.isin(a,values).sum(axis=(1,2)) for key,values in MATERIALS.items()}
                total_by_y = {key:material_by_y[key] for key in GROUPS}
                non_air_by_y = (~np.isin(a,AIR_IDS)).sum(axis=(1,2))
                unknown_by_y = (~np.isin(a,KNOWN)).sum(axis=(1,2))
                for i,row in enumerate(ys):
                    row['blocks'] += int(a.shape[1]*a.shape[2])
                    row['nonAir'] += int(non_air_by_y[i])
                    row['unknown'] += int(unknown_by_y[i])
                    for key,values in total_by_y.items(): row['ores'][key] += int(values[i])
                    for key,values in material_by_y.items(): row['materials'][key] += int(values[i])
                # Observed horizontal 4x4 biome cells; no vertical/cave biome inference.
                lx=np.arange(max(x0-cx,0),min(x1-cx+1,16))[:,None]
                lz=np.arange(max(z0-cz,0),min(z1-cz+1,16))[None,:]
                biome_grid=(np.frombuffer(chunk.biomes,dtype=np.uint8)[(lx&12)|((lz>>2)&3)]
                            if len(chunk.biomes)==16 else np.full(a.shape[1:],-1))
                for bid in np.unique(biome_grid):
                    key=str(int(bid)); mask=biome_grid==bid; voxels=a[:,mask]
                    entry=biome_totals.setdefault(key,dict(id=key,chunks=0,columns=0,levels=[dict(y=y,blocks=0,nonAir=0,unknown=0,ores={k:0 for k in GROUPS},materials={k:0 for k in MATERIALS}) for y in range(y0,y1+1)]))
                    entry['chunks']+=1;entry['columns']+=int(mask.sum())
                    m={k:np.isin(voxels,v).sum(axis=1) for k,v in MATERIALS.items()}
                    c={k:m[k] for k in GROUPS}
                    na=(~np.isin(voxels,AIR_IDS)).sum(axis=1);un=(~np.isin(voxels,KNOWN)).sum(axis=1)
                    for i,row in enumerate(entry['levels']):
                        row['blocks']+=int(voxels.shape[1]);row['nonAir']+=int(na[i]);row['unknown']+=int(un[i])
                        for k in GROUPS:row['ores'][k]+=int(c[k][i])
                        for k in MATERIALS:row['materials'][k]+=int(m[k][i])
                if cube is not None:
                    cube[:,max(cz-z0,0):min(cz+16-z0,z1-z0+1),max(cx-x0,0):min(cx+16-x0,x1-x0+1)] = a.transpose(0,2,1)
                if spatial:
                    areas.append(dict(x0=max(cx,x0),x1=min(cx+15,x1),z0=max(cz,z0),z1=min(cz+15,z1),
                                      blocks=int(a.size),materials={k:int(v.sum()) for k,v in material_by_y.items()}))
                scanned += 1
                # Metadata is ancillary: unreadable signs/chests never invalidate block counts.
                c,ce = read_chests(data,name,chunk); s,se = read_signs(data,name,chunk)
                chests.extend(c); signs.extend(s); metadata_errors.extend(ce+se)
                if before:
                    old_data,old_chunk = prior
                    b = old_chunk.blocks[y0:y1+1,max(x0-cx,0):min(x1-cx+1,16),max(z0-cz,0):min(z1-cz+1,16)] & 4095
                    old_air, new_air = np.isin(b,AIR_IDS), np.isin(a,AIR_IDS)
                    removed = ~old_air & new_air
                    pair['compared'] += int(b.size)
                    pair['beforeAir'] += int(old_air.sum())
                    pair['removed'] += int(removed.sum())
                    pair['remaining'] += int((~old_air & ~new_air).sum())
                    pair['otherChanges'] += int(((a != b) & ~removed & ~(old_air & new_air)).sum())
                    pair['unknown'] += int((~np.isin(b,KNOWN)).sum())
                    for key,n in counts(b[removed]).items(): pair['counts'][key] += n
                    c,ce = read_chests(old_data,name,old_chunk); s,se = read_signs(old_data,name,old_chunk)
                    old_chests.extend(c); old_signs.extend(s); metadata_errors.extend(ce+se)
            except (ValueError,OSError,OverflowError) as exc:
                errors.append(name+': '+str(exc))
    _unchanged(world,hashes)
    if before: _unchanged(before,old_hashes)
    # Detect a missing chunk arriving during a scan as a changed source too.
    for name,side in missing.items():
        if ((world if side=='after' else before)/name).exists():
            raise ValueError('Source chunk set changed during scan')
    for c in chests+old_chests:
        c['items'] = sorted(c['items'],key=lambda i:i['slot'])
    classify_sign_chests(chests,signs); classify_sign_chests(old_chests,old_signs)
    if pair:
        pair['complete'] = (not errors and not missing and pair['compared']==pair['volume']
                            and pair['removed']>0 and pair['remaining']==0 and pair['otherChanges']==0
                            and pair['unknown']==0)
    return dict(schema=1,dimension=dimension,bounds=list(bounds),expected=expected,scanned=scanned,
                missing=missing,errors=errors,metadataErrors=metadata_errors,levels=ys,
                hashes=hashes,beforeHashes=old_hashes,chests=chests,beforeChests=old_chests,
                signs=signs,probe=pair,biomes=list(biome_totals.values()),sampling=None,
                spatial=(dict(encoding='u16le-yzx-v1',data=base64.b64encode(cube.tobytes()).decode('ascii')) if cube is not None else None),
                areas=areas if spatial else None)


def sample_scan(world,dimension,limit,seed):
    world=Path(world).resolve(strict=True)
    if dimension not in ('o','n') or not 1<=limit<=512:raise ValueError('Sample size must be 1–512')
    sectors={}
    for path in sorted(world.iterdir()):
        match=re.fullmatch(re.escape(dimension)+r'\.(-?\d+),(-?\d+)',path.name)
        if not match:continue
        x,z=map(int,match.groups())
        if x%16 or z%16:continue
        sectors.setdefault((x//256,z//256),[]).append((x,z))
    rng=random.Random(seed); keys=sorted(sectors);rng.shuffle(keys)
    eligible=sum(len(v) for v in sectors.values())
    for values in sectors.values():rng.shuffle(values)
    selected=[]
    while len(selected)<limit and any(sectors.values()):
        for key in keys:
            if sectors[key] and len(selected)<limit:selected.append(sectors[key].pop())
    if not selected:raise ValueError('No saved chunks in this dimension / Keine gespeicherten Chunks in dieser Dimension')
    merged=None;biomes={}
    for x,z in selected:
        part=scan(world,dimension,[x,x+15,0,255,z,z+15])
        if merged is None:merged=part;biomes={b['id']:b for b in part['biomes']};continue
        merged['scanned']+=part['scanned'];merged['expected']+=1
        for k in ('missing','hashes'):merged[k].update(part[k])
        for k in ('errors','metadataErrors','chests','signs'):merged[k].extend(part[k])
        def add_levels(target,source):
            for row,other in zip(target,source):
                for k in ('blocks','nonAir','unknown'):row[k]+=other[k]
                for k in GROUPS:row['ores'][k]+=other['ores'][k]
                for k in MATERIALS:row['materials'][k]+=other['materials'][k]
        add_levels(merged['levels'],part['levels'])
        for b in part['biomes']:
            if b['id'] not in biomes:biomes[b['id']]=b
            else:
                target=biomes[b['id']];target['chunks']+=b['chunks'];target['columns']+=b['columns']
                add_levels(target['levels'],b['levels'])
    merged['biomes']=list(biomes.values())
    merged['bounds']=[min(x for x,z in selected),max(x for x,z in selected)+15,0,255,min(z for x,z in selected),max(z for x,z in selected)+15]
    merged['sampling']=dict(seed=seed,requested=limit,eligible=eligible,sectors=len(keys),method='spatial-round-robin-256',selected=[f'{dimension}.{x},{z}' for x,z in selected])
    _unchanged(world,merged['hashes'])
    return merged


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('world',type=Path);p.add_argument('--before',type=Path)
    p.add_argument('--dimension',choices=('o','n'),required=True)
    p.add_argument('--spatial',action='store_true',help='Include bounded slice volume and clipped chunk comparisons')
    p.add_argument('--sample',type=int);p.add_argument('--seed',type=int,default=20260907)
    p.add_argument('--bounds',type=int,nargs=6,required=False,metavar=('X0','X1','Y0','Y1','Z0','Z1'))
    args=p.parse_args()
    if args.sample is not None:
        if args.before or args.bounds:p.error('Sampling cannot be combined with bounds or before')
        result=sample_scan(args.world,args.dimension,args.sample,args.seed)
    else:
        if args.bounds is None:p.error('--bounds or --sample is required')
        result=scan(args.world,args.dimension,args.bounds,args.before,spatial=args.spatial)
    print(json.dumps(result,separators=(',',':'),allow_nan=False))
    return 0

if __name__=='__main__': raise SystemExit(main())
