"""Read-only sign locations and the observed v9 oak sign text record.

Positions always come from decoded blocks. Missing, duplicate or unsupported
records retain the position but never masquerade as an empty inscription.
"""
import struct
import numpy as np
from .chunks import decode

SIGN_IDS = set(range(162, 168)) | set(range(172, 178)) | set(range(736, 740))
TRAILER = bytes.fromhex('000f00000000000f00')


def scan_data(data, filename, chunk=None):
    chunk = chunk if chunk is not None else decode(data, filename)
    records = {}
    for y, lx, lz in np.argwhere(np.isin(chunk.blocks & 4095, list(SIGN_IDS))):
        x, y, z = int(chunk.x + lx), int(y), int(chunk.z + lz)
        records[x, y, z] = {
            'id': f'{filename[0]}:sign:{x},{y},{z}', 'kind': 'sign',
            'x': x, 'y': y, 'z': z, 'blockID': int(chunk.blocks[y, lx, lz] & 4095),
            'text': '', 'readable': False, 'error': 'Missing or unsupported sign record',
        }
    if not records:
        return [], []

    # Observed oak wall blocks (172) serialize as oak sign records (162).
    # Other wood families remain visible with unavailable text until verified.
    pos = chunk.block_data_end
    seen = set()
    while True:
        i = data.find(b'\x00\xa2', pos)
        if i < 0:
            break
        pos = i + 2
        if i + 19 > len(data):
            continue
        coords = struct.unpack_from('>iii', data, i + 7)
        sign = records.get(coords)
        if sign is None or sign['blockID'] not in (162, 172):
            continue
        try:
            if coords in seen:
                raise ValueError('Duplicate sign records')
            seen.add(coords)
            size = struct.unpack_from('>I', data, i + 2)[0]
            end = i + 6 + size
            if data[i + 6] != 1 or size < 28 or end > len(data):
                raise ValueError('Unsupported sign record layout')
            length = struct.unpack_from('>I', data, i + 21)[0]
            text_end = i + 25 + length
            if text_end + len(TRAILER) != end or data[text_end:end] != TRAILER:
                raise ValueError('Unsupported sign text boundary or footer')
            text = data[i + 25:text_end].decode('utf-8', errors='strict')
            sign.update(text=text, readable=True, error='')
        except (ValueError, UnicodeError) as exc:
            sign.update(text='', readable=False, error=str(exc))

    result = sorted(records.values(), key=lambda s: (s['x'], s['z'], s['y']))
    return result, [f"{s['id']}: {s['error']}" for s in result if not s['readable']]
