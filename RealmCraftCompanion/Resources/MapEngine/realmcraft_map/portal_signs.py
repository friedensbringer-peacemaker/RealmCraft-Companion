"""Read nearby sign suggestions without modifying a savegame."""
import json
import struct
import sys
from pathlib import Path
from .signs import scan_data


def suggestions(world):
    world = Path(world)
    portals = []
    chunks = set()
    for dimension, filename in [('o', 'poiOverworld'), ('n', 'poiTheNether')]:
        data = (world / filename).read_bytes()
        if len(data) < 4:
            raise ValueError('Invalid POI data')
        count, = struct.unpack_from('>i', data)
        if count < 0 or len(data) != 4 + count * 18:
            raise ValueError('Invalid POI data')
        for kind, x, y, z, tickets in struct.iter_unpack('>hiiii', data[4:]):
            if kind != 0:
                continue
            portals.append((dimension, x, y, z))
            for cx in range((x-6)//16*16, (x+6)//16*16+1, 16):
                for cz in range((z-6)//16*16, (z+6)//16*16+1, 16):
                    chunks.add(f'{dimension}.{cx},{cz}')
    signs = []
    incomplete = False
    for filename in sorted(chunks):
        file = world / filename
        if not file.is_file():
            incomplete = True
            continue
        try:
            found, errors = scan_data(file.read_bytes(), filename)
            incomplete |= bool(errors)
            signs.extend((filename[0], s) for s in found if s['readable'])
        except (ValueError, IndexError, OSError, struct.error):
            incomplete = True
    names = {}
    for d, x, y, z in portals:
        nearby = sorted(set(' '.join(s['text'].split())[:100] for sd, s in signs
                            if sd == d and (s['x']-x)**2+(s['y']-y)**2+(s['z']-z)**2 <= 36 and s['text'].strip()))
        if nearby:
            names[f'{d}:{x} / {y} / {z}'] = nearby
    return {'names': names, 'incomplete': incomplete}


def main():
    print(json.dumps(suggestions(sys.argv[1]), ensure_ascii=False))


if __name__ == '__main__':
    main()
