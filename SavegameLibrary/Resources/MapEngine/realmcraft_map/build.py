"""Generate a portable, offline browser map without modifying the source world."""
import base64
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import gzip
import json
import math
from pathlib import Path
import shutil
import tempfile
import time

import numpy as np
from PIL import Image

from .chunks import ChunkError, FILENAME, decode
from .palette import NAMES, PALETTE
from .chests import scan_data
from .points import points_for_columns, finalize

ROOT = Path(__file__).resolve().parent.parent
TILE = 256
CACHE_VERSION = 'v4-columns-biomes-chests'


def read_surface(path, cache):
    before = path.stat()
    key = hashlib.sha256(f'{CACHE_VERSION}:{path.resolve()}:{before.st_size}:{before.st_mtime_ns}'.encode()).hexdigest()
    cached = cache / (key + '.npz')
    if cached.exists():
        try:
            with np.load(cached, allow_pickle=False) as a:
                return a['ids'], a['heights'], str(a['sha256']), a['columns'].tobytes(), a['biomes'].tobytes(), json.loads(str(a['chests'])), True
        except (ValueError, OSError, KeyError):
            pass
    data = path.read_bytes()
    after = path.stat()
    if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
        # Cloud-file hydration may restore the original mtime during first read.
        # Require a second stable read, rather than accepting an actively edited file.
        before = after
        data = path.read_bytes()
        after = path.stat()
        if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
            raise ChunkError('File changed repeatedly while reading; use a completed backup')
        key = hashlib.sha256(f'{CACHE_VERSION}:{path.resolve()}:{after.st_size}:{after.st_mtime_ns}'.encode()).hexdigest()
        cached = cache / (key + '.npz')
    chunk = decode(data, path.name)
    ids, heights = chunk.surface(90 if chunk.dimension == 1 else None)
    digest = hashlib.sha256(data).hexdigest()
    columns = chunk.columns()
    chest_records, chest_errors = scan_data(data, path.name, chunk)
    chest_data = {'records': chest_records, 'errors': chest_errors}
    np.savez_compressed(cached, ids=ids, heights=heights, sha256=np.array(digest), columns=np.frombuffer(columns,dtype=np.uint8), biomes=np.frombuffer(chunk.biomes,dtype=np.uint8), chests=np.array(json.dumps(chest_data)))
    return ids, heights, digest, columns, chunk.biomes, chest_data, False


def tile_pyramid(image, destination):
    destination.mkdir(parents=True, exist_ok=True)
    level = 0
    grids = []
    while True:
        width, height = image.size
        nx, nz = math.ceil(width / TILE), math.ceil(height / TILE)
        grids.append([nx, nz])
        for z in range(nz):
            for x in range(nx):
                tile = image.crop((x*TILE, z*TILE, (x+1)*TILE, (z+1)*TILE))
                tile.save(destination / f'{level}-{x}-{z}.png')
        if max(width, height) <= TILE:
            break
        image = image.resize((math.ceil(width/2), math.ceil(height/2)), Image.Resampling.BOX)
        level += 1
    return grids


def build(source, output, *, workers=16, radius=None, cache=None):
    source, output = Path(source).resolve(), Path(output).resolve()
    if not source.is_dir():
        raise ValueError('Savegame folder does not exist')
    if source == output or source in output.parents or output in source.parents:
        raise ValueError('Output and savegame folders must not overlap')
    if output.exists() and not (output / '.realmcraft-map').is_file():
        raise ValueError('Output folder exists and is not a generated Realmcraft map')
    cache = Path(cache or output.parent / '.cache').resolve()
    if source == cache or source in cache.parents or cache in source.parents:
        raise ValueError('Cache and savegame folders must not overlap')
    cache.mkdir(parents=True, exist_ok=True)
    files = []
    for path in source.iterdir():
        match = FILENAME.fullmatch(path.name)
        if match and path.is_file() and not path.is_symlink():
            x, z = int(match[2]), int(match[3])
            if radius is None or (abs(x) <= radius and abs(z) <= radius):
                files.append(path)
    files.sort(key=lambda p: (p.name[0], sum(abs(int(v)) for v in p.name[2:].split(','))))
    if not files:
        raise ValueError('No o.x,z or n.x,z chunk files found in this folder')
    output.parent.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix='.realmcraft-map-', dir=output.parent))
    manifest = {'format': 2, 'title': source.name, 'generatedAt': datetime.now(timezone.utc).isoformat(),
                'tileSize': TILE, 'itemNames': json.loads((Path(__file__).parent/'item_names.json').read_text()), 'chestErrors': [], 'biomeNames': json.loads((Path(__file__).parent/'biomes.json').read_text()), 'registry': NAMES, 'palette': PALETTE.tolist(), 'dimensions': {}, 'errors': [],
                'scope': 'complete' if radius is None else f'radius:{radius}', 'sourceFileCount': len(files)}
    audit = []
    started = time.monotonic()
    try:
        for prefix, label in [('o', 'Oberwelt'), ('n', 'Nether')]:
            selected = [p for p in files if p.name.startswith(prefix + '.')]
            if not selected:
                continue
            positions = [tuple(map(int, p.name[2:].split(','))) for p in selected]
            xmin, zmin = min(x for x,z in positions), min(z for x,z in positions)
            xmax, zmax = max(x for x,z in positions)+16, max(z for x,z in positions)+16
            width, height = xmax-xmin, zmax-zmin
            if width * height > 64_000_000:
                raise ValueError('World bounds exceed 64 million columns; use --radius to select a region')
            ids = np.zeros((height, width), dtype=np.uint16)
            heights = np.zeros((height, width), dtype=np.uint8)
            present = np.zeros((height, width), dtype=bool)
            chunks = {}
            regions = {}
            points = []
            biomes = {}
            chests = {}
            hits = 0
            def read(path):
                try:
                    return path, read_surface(path, cache), None
                except (OSError, ValueError) as exc:
                    return path, None, str(exc)
            print(f'{label}: reading {len(selected):,} chunks…', flush=True)
            with ThreadPoolExecutor(max_workers=workers) as executor:
                for i, (path, result, error) in enumerate(executor.map(read, selected), 1):
                    if error:
                        manifest['errors'].append({'file': path.name, 'reason': error})
                    else:
                        top, h, digest, columns, biome_data, chest_data, cached = result
                        x, z = map(int, path.name[2:].split(','))
                        if len(biome_data)==16: biomes[f"{x},{z}"] = list(biome_data)
                        points.extend(points_for_columns(columns,x,z))
                        for chest in chest_data['records']:
                            chests[f"{chest['x']},{chest['y']},{chest['z']}"] = chest
                        manifest['chestErrors'].extend(chest_data['errors'])
                        row, col = z-zmin, x-xmin
                        ids[row:row+16, col:col+16] = top
                        heights[row:row+16, col:col+16] = h
                        present[row:row+16, col:col+16] = True
                        packed = top.astype('<u2').tobytes() + h.tobytes()
                        chunks[f'{x},{z}'] = base64.b64encode(packed).decode('ascii')
                        region_key = f'{x//256},{z//256}'
                        regions.setdefault(region_key, {})[f'{x},{z}'] = base64.b64encode(columns).decode('ascii')
                        audit.append({'file': path.name, 'sha256': digest})
                        hits += cached
                    if i % 250 == 0 or i == len(selected):
                        print(f'  {i:,}/{len(selected):,} • {hits:,} cached • {len(manifest["errors"])} errors', flush=True)
            if not chunks:
                continue
            (stage/'regions'/prefix).mkdir(parents=True,exist_ok=True)
            for region_key, entries in regions.items():
                compressed = gzip.compress(json.dumps(entries,separators=(',',':')).encode(),mtime=0)
                payload = base64.b64encode(compressed).decode('ascii')
                (stage/'regions'/prefix/(region_key+'.js')).write_text(
                    'AtlasRegion('+json.dumps(prefix+':'+region_key)+','+json.dumps(payload)+');\n')
            region_keys = list(regions)
            del regions
            # Neighbor-aware height shading. Unknown columns do not cast artificial shadows.
            center = heights.astype(np.int16)
            left = np.roll(center, 1, axis=1)
            up = np.roll(center, 1, axis=0)
            valid_left = present & np.roll(present, 1, axis=1)
            valid_up = present & np.roll(present, 1, axis=0)
            valid_left[:, 0] = False
            valid_up[0, :] = False
            slope = np.where(valid_left, center-left, 0)*0.075 + np.where(valid_up, center-up, 0)*0.09
            shade = np.clip(1 + slope, 0.56, 1.3)
            rgba = np.zeros((height, width, 4), dtype=np.uint8)
            rgba[:,:,:3] = np.clip(PALETTE[ids]*shade[:,:,None], 0, 255).astype(np.uint8)
            rgba[:,:,3] = np.where(present, 255, 0)
            grids = tile_pyramid(Image.fromarray(rgba), stage / 'tiles' / prefix / 'terrain')
            # Height palette: slate lowlands, sea green midlands, pale mountain tops.
            stops = np.array([[40,59,78], [68,126,135], [149,187,144], [229,224,188], [252,250,241]])
            t = np.clip(center/255*4, 0, 4)
            lo = np.minimum(t.astype(int), 3)
            f = (t-lo)[:,:,None]
            rgba[:,:,:3] = np.clip((stops[lo]*(1-f)+stops[lo+1]*f)*shade[:,:,None], 0,255).astype(np.uint8)
            tile_pyramid(Image.fromarray(rgba), stage / 'tiles' / prefix / 'height')
            values = np.unique(ids[present])
            manifest['dimensions'][prefix] = {'label': label, 'bounds':[xmin,zmin,xmax,zmax],
                'chests':chests, 'biomes':biomes, 'points':finalize(points,prefix), 'chunks':chunks, 'count':len(chunks), 'grids':grids, 'regions':region_keys,
                'heightRange':[int(heights[present].min()),int(heights[present].max())],
                'unknownIds':[int(v) for v in values if int(v) not in NAMES],
                'ceiling':90 if prefix == 'n' else 255}
        if not manifest['dimensions']:
            raise ValueError('No readable chunks; first error: ' + str(manifest['errors'][:1]))
        manifest['elapsedSeconds'] = round(time.monotonic()-started, 1)
        for path in (Path(__file__).parent/'web').iterdir():
            if path.is_file(): shutil.copy2(path, stage/path.name)
        (stage/'map.data.js').write_text('window.REALMCRAFT_MAP = '+json.dumps(manifest, separators=(',',':'))+';\n')
        (stage/'audit.json').write_text(json.dumps({'source':str(source), 'generatedAt':manifest['generatedAt'],
            'files':audit, 'errors':manifest['errors'], 'chestErrors':manifest['chestErrors']}, indent=2)+'\n')
        (stage/'.realmcraft-map').write_text('1\n')
        # Preserve the previous successful export until the new one is fully written.
        previous = None
        if output.exists():
            previous = Path(tempfile.mkdtemp(prefix='.previous-map-', dir=output.parent))
            previous.rmdir()
            output.rename(previous)
        try:
            stage.rename(output)
        except OSError:
            if previous: previous.rename(output)
            raise
        if previous: shutil.rmtree(previous)
    finally:
        if stage.exists(): shutil.rmtree(stage)
    print(f'Complete: {output / "index.html"} ({manifest["elapsedSeconds"]} s)', flush=True)
    return manifest
