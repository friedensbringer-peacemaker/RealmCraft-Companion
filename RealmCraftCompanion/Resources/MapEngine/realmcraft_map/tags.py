"""Explainable local beta suggestions, not AI or verified structure detection.
Each segment spans 32 X × 32 Z × 16 Y blocks. Only positive saved evidence counts.
"""
from collections import Counter, defaultdict
import struct
from .palette import NAMES

GROUPS = {
 'wheat': {'wheat'}, 'crops': {'carrots', 'potatoes', 'beetroots'},
 'farmland': {'farmland'}, 'cane': {'sugar_cane'},
 'rails': {'rail', 'powered_rail', 'detector_rail', 'activator_rail'},
 'torches': {'torch', 'wall_torch', 'soul_torch', 'soul_wall_torch'},
 'bricks': {'nether_bricks', 'cracked_nether_bricks', 'chiseled_nether_bricks'},
 'fortress_details': {'nether_brick_fence', 'nether_brick_stairs', 'nether_brick_slab'},
 'spawners': {'spawner'}, 'chests': {'chest', 'trapped_chest'},
 'tables': {'crafting_table'}, 'furnaces': {'furnace', 'blast_furnace', 'smoker'},
}
IDS = {i: group for i, name in NAMES.items() for group, names in GROUPS.items() if name in names}

def collect(columns, x, z, cells):
    offsets = struct.unpack_from('<257I', columns)
    for column in range(256):
        cx, cz = x + column % 16, z + column // 16
        for run in range(offsets[column], offsets[column + 1]):
            y, identity = struct.unpack_from('<BH', columns, 1028 + run * 3)
            group = IDS.get(identity)
            if not group: continue
            end = columns[1028 + (run + 1) * 3] if run + 1 < offsets[column + 1] else 256
            for cy in range(y // 16, (end - 1) // 16 + 1):
                cells.setdefault((cx // 32, cy, cz // 32), Counter())[group] += min(end, (cy + 1) * 16) - max(y, cy * 16)

def suggest(cells, dimension, chests):
    containers = defaultdict(list)
    for chest in chests.values():
        containers[(chest['x']//32, chest['y']//16, chest['z']//32)].append(chest)
    result = []
    for cell, counts in sorted(cells.items()):
        c = Counter(counts); records = containers[cell]
        readable = [r for r in records if r.get('readable')]
        filled = [r for r in readable if r.get('items')]
        c['filled'] = len(filled)
        c['stacks'] = sum(len(r['items']) for r in filled)
        choices = []
        if c['wheat'] >= 16 and c['farmland'] >= 16:
            choices.append(('wheat_farm', ['wheat', 'farmland'], 'strong' if c['wheat'] >= 64 else 'medium'))
        if c['crops'] >= 16 and c['farmland'] >= 16:
            choices.append(('crop_farm', ['crops', 'farmland'], 'medium'))
        if c['cane'] >= 32: choices.append(('cane_field', ['cane'], 'weak'))
        if c['chests'] >= 4 and c['filled'] >= 3 and c['stacks'] >= 12:
            choices.append(('storage', ['chests', 'filled', 'stacks'], 'strong' if c['filled'] >= 8 else 'medium'))
        if c['tables'] >= 1 and c['furnaces'] >= 3:
            choices.append(('workshop', ['tables', 'furnaces'], 'medium'))
        if cell[1] <= 2 and c['rails'] >= 12 and c['torches'] >= 3:
            choices.append(('mine', ['rails', 'torches'], 'medium'))
        if dimension == 'n' and c['bricks'] >= 96 and (c['fortress_details'] >= 16 or c['spawners'] >= 1):
            evidence = ['bricks'] + [k for k in ['fortress_details', 'spawners'] if c[k]]
            choices.append(('fortress', evidence, 'medium'))
        for tag, evidence, strength in choices:
            x, y, z = cell[0]*32, cell[1]*16, cell[2]*32
            result.append({'id':f'{dimension}:tag:{tag}:{x},{y},{z}', 'kind':'tag', 'tagType':tag,
                'x':x+16, 'y':y+8, 'z':z+16, 'count':1, 'beta':True, 'method':'local-rules-v1',
                'strength':strength, 'bounds':[x,y,z,x+32,y+16,z+32],
                'evidence':{k:c[k] for k in evidence},
                'sourceChests':[f"{r['x']},{r['y']},{r['z']}" for r in records] if tag=='storage' else []})
    return result
