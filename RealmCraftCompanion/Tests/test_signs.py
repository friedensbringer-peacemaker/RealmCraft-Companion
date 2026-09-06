import hashlib
import struct
import tempfile
import unittest
from pathlib import Path
from test_chests import chunk
from realmcraft_map.signs import scan_data, TRAILER
from realmcraft_map.build import build, read_surface


def sign_record(text='\nLeiter\nGrüße 🪧', version=1, coords=(-53, 68, 10)):
    encoded = text.encode('utf-8')
    body = bytes([version]) + struct.pack('>iii', *coords) + b'\0\3' + struct.pack('>I', len(encoded)) + encoded + TRAILER
    return b'\0\xa2' + struct.pack('>I', len(body)) + body


class SignTests(unittest.TestCase):
    def test_wall_sign_matches_standing_record_and_preserves_unicode(self):
        signs, errors = scan_data(chunk(172) + sign_record(), 'o.-64,0')
        self.assertEqual(errors, [])
        self.assertEqual(len(signs), 1)
        self.assertEqual(signs[0]['text'], '\nLeiter\nGrüße 🪧')
        self.assertEqual((signs[0]['x'], signs[0]['y'], signs[0]['z']), (-53, 68, 10))

    def test_empty_and_unavailable_are_distinct(self):
        signs, errors = scan_data(chunk(162) + sign_record(''), 'o.-64,0')
        self.assertTrue(signs[0]['readable'])
        self.assertEqual(signs[0]['text'], '')
        self.assertFalse(errors)
        for block in [162, 172, 173, 738]:
            signs, errors = scan_data(chunk(block), 'o.-64,0')
            self.assertEqual(len(signs), 1)
            self.assertFalse(signs[0]['readable'])
            self.assertTrue(errors)

    def test_rejects_truncation_duplicates_bad_utf8_and_wrong_coordinates(self):
        valid = sign_record('Test')
        corrupt = bytearray(valid)
        corrupt[25] = 255
        wrong_length = bytearray(valid)
        struct.pack_into('>I', wrong_length, 21, 0xffffffff)
        for record in [valid[:i] for i in range(len(valid))] + [valid + valid, valid + valid + valid, sign_record(version=2), bytes(corrupt), bytes(wrong_length), sign_record(coords=(-52, 68, 10)), valid[:-1] + b'\1']:
            signs, errors = scan_data(chunk(172) + record, 'o.-64,0')
            self.assertFalse(signs[0]['readable'])
            self.assertEqual(signs[0]['text'], '')
            self.assertTrue(errors)
        self.assertEqual(scan_data(chunk(1) + valid, 'o.-64,0'), ([], []))

    def test_build_cache_dimension_and_source_unchanged(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            world = root / 'world'
            world.mkdir()
            data = chunk(172) + bytes([4] * 16) + sign_record('</script><img src=x>')
            nether = bytearray(data)
            nether[12] = 1
            (world / 'o.-64,0').write_bytes(data)
            (world / 'n.-64,0').write_bytes(nether)
            hashes = {p.name: hashlib.sha256(p.read_bytes()).digest() for p in world.iterdir()}
            first = build(world, root / 'map', cache=root / 'cache', workers=1)
            self.assertEqual(first['signSchema'], 1)
            self.assertFalse(first['signErrors'])
            for dim in ['o', 'n']:
                self.assertEqual(first['dimensions'][dim]['signs'][0]['id'], f'{dim}:sign:-53,68,10')
            self.assertTrue(read_surface(world / 'o.-64,0', root / 'cache')[-1])
            second = build(world, root / 'map', cache=root / 'cache', workers=1)
            self.assertEqual(first['dimensions']['o']['signs'], second['dimensions']['o']['signs'])
            self.assertTrue((root / 'map/signs.js').exists())
            self.assertEqual(hashes, {p.name: hashlib.sha256(p.read_bytes()).digest() for p in world.iterdir()})


if __name__ == '__main__':
    unittest.main()
