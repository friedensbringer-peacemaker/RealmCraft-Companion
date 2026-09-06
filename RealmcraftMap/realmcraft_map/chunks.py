"""Strict decoder for observed Realmcraft version-9 chunk files.

Only block sections are decoded. Remaining light/entity/map data is left untouched.
See docs/FORMAT.md for evidence, layout and compatibility limits.
"""
from dataclasses import dataclass
import re
import struct
import numpy as np

FILENAME = re.compile(r"([on])\.(-?\d+),(-?\d+)$")
AIR = (0, 639)


class ChunkError(ValueError):
    pass


@dataclass
class Chunk:
    x: int
    z: int
    dimension: int
    blocks: np.ndarray  # [y, x, z], packed uint32 block state
    block_data_end: int

    def columns(self):
        """Compact vertical runs with offsets, in map order [z,x].

        257 little-endian uint32 run offsets, then (start_y:u8, id:u16le).
        This supports arbitrary heights without exposing inventory/entity data.
        """
        columns = (self.blocks & 0xFFF).transpose(2, 1, 0).reshape(256, 256)
        changes = np.ones_like(columns, dtype=bool)
        changes[:, 1:] = columns[:, 1:] != columns[:, :-1]
        offsets = np.r_[0, np.cumsum(changes.sum(axis=1))].astype('<u4')
        col, y = np.nonzero(changes)
        runs = np.empty(len(y), dtype=[('y','u1'),('id','<u2')])
        runs['y'] = y
        runs['id'] = columns[col,y]
        return offsets.tobytes() + runs.tobytes()

    def surface(self, ceiling=None):
        ids = self.blocks & 0xFFF
        if ceiling is not None:
            ids = ids[:ceiling + 1]
        solid = ~np.isin(ids, AIR)
        heights = np.max(np.where(solid, np.arange(len(ids))[:, None, None], -1), axis=0)
        top = np.take_along_axis(ids, np.maximum(heights, 0)[None, :, :], axis=0)[0]
        top[heights < 0] = 0
        return top.T.astype(np.uint16), np.maximum(heights.T, 0).astype(np.uint8)


def decode(data: bytes, filename=None) -> Chunk:
    if len(data) < 15:
        raise ChunkError("Chunk header truncated")
    version, x, z, dimension, status, count = struct.unpack_from(">IiiBBB", data)
    if version != 9:
        raise ChunkError(f"Unsupported save version {version}; supported: 9")
    if count != 16 or dimension not in (0, 1) or x % 16 or z % 16:
        raise ChunkError("Unsupported chunk layout or coordinates")
    if filename is not None:
        match = FILENAME.fullmatch(filename)
        if not match or (int(match[2]), int(match[3]), 'on'.index(match[1])) != (x, z, dimension):
            raise ChunkError("Filename and chunk header disagree")
    result = np.zeros((16, 4096), dtype=np.uint32)
    pos = 15
    for section in range(count):
        if pos + 4 > len(data):
            raise ChunkError(f"Section {section}: missing block count")
        non_air = struct.unpack_from('>I', data, pos)[0]
        pos += 4
        if non_air == 0:
            continue
        if non_air > 4096 or pos + 4 > len(data):
            raise ChunkError(f"Section {section}: invalid block count")
        size = struct.unpack_from('>I', data, pos)[0]
        pos += 4
        end = pos + size
        if size < 4 or end > len(data):
            raise ChunkError(f"Section {section}: invalid payload length")
        # Four-byte native payload prefix; not interpreted as a checksum.
        pos += 4
        for channel in range(4):
            out = bytearray()
            while len(out) < 4096:
                run = 0
                while pos < end and data[pos] == 0:
                    run += 255
                    pos += 1
                    if run >= 4096:
                        raise ChunkError(f"Section {section}: excessive RLE run")
                if pos + 2 > end:
                    raise ChunkError(f"Section {section}: truncated RLE run")
                run += data[pos]
                value = data[pos + 1]
                pos += 2
                if len(out) + run > 4096:
                    raise ChunkError(f"Section {section}: RLE exceeds 4096 blocks")
                out.extend(bytes([value]) * run)
            result[section] |= np.frombuffer(out, dtype=np.uint8).astype(np.uint32) << (channel * 8)
        if pos != end:
            raise ChunkError(f"Section {section}: unexpected bytes after block channels")
        # The saved non-air counter can lag behind block edits / cave-air changes.
        # It is an allocation hint, not an integrity checksum. Payload boundaries
        # and the exact 4096 values of all four channels are validated above.
    return Chunk(x, z, dimension, result.reshape(256, 16, 16), pos)
