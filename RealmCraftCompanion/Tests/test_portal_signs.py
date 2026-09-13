import struct
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from realmcraft_map.portal_signs import suggestions

class PortalSignsTests(unittest.TestCase):
    def test_dimension_proximity_whitespace_and_missing_chunks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for d, file in [('o','poiOverworld'), ('n','poiTheNether')]:
                (root/file).write_bytes(struct.pack('>ihiiii', 1, 0, 8, 64, 8, 0))
                (root/f'{d}.0,0').write_bytes(b'synthetic')
            def scan(data, filename):
                return ([{'x':9,'y':64,'z':8,'readable':True,'text': ' Gate\n A ' if filename[0]=='o' else 'Gate B'},
                         {'x':30,'y':64,'z':8,'readable':True,'text':'Far'},
                         {'x':8,'y':64,'z':8,'readable':False,'text':'Unreadable'}], [])
            with patch('realmcraft_map.portal_signs.scan_data', side_effect=scan):
                result = suggestions(root)
            self.assertEqual(result['names'], {'o:8 / 64 / 8':['Gate A'], 'n:8 / 64 / 8':['Gate B']})
            self.assertFalse(result['incomplete'])
            (root/'n.0,0').unlink()
            with patch('realmcraft_map.portal_signs.scan_data', side_effect=scan):
                self.assertTrue(suggestions(root)['incomplete'])

    def test_rejects_truncated_poi(self):
        with tempfile.TemporaryDirectory() as tmp:
            (Path(tmp)/'poiOverworld').write_bytes(b'bad')
            with self.assertRaises(ValueError): suggestions(tmp)
