import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import numpy as np
from realmcraft_map.build import build
from test_chunks import fixture


class ExportTests(unittest.TestCase):
    def test_cached_preview_does_not_read_unimported_chunks(self):
        with tempfile.TemporaryDirectory() as root:
            root=Path(root);source=root/'world';source.mkdir()
            (source/'o.-16,32').write_bytes(fixture())
            build(source,root/'map',cache=root/'cache')
            (source/'o.0,0').write_bytes(b'not read in cached-only mode')
            result=build(source,root/'map',cache=root/'cache',cached_only=True)
            self.assertEqual(result['pending'],['o.0,0'])
            self.assertEqual(result['errors'],[])
            self.assertEqual(result['scope'],'partial')
            self.assertFalse(list((root/'cache').glob('*.tmp')))

    def test_offline_export_cache_and_readonly_source(self):
        with tempfile.TemporaryDirectory() as root:
            root=Path(root);source=root/'world';source.mkdir()
            blocks=np.zeros((256,16,16),dtype=np.uint32);blocks[64,:,:]=8
            raw=fixture(blocks);path=source/'o.-16,32';path.write_bytes(raw)
            digest=hashlib.sha256(raw).hexdigest()
            result=build(source,root/'map',cache=root/'cache',workers=2)
            self.assertEqual(result['dimensions']['o']['count'],1)
            self.assertEqual(result['dimensions']['o']['bounds'],[-16,32,0,48])
            self.assertFalse(result['errors'])
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),digest)
            self.assertEqual(list(source.iterdir()),[path])
            for name in ['index.html','app.js','geometry.js','columns.js','layers.js','style.css','map.data.js','audit.json','tiles/o/terrain/0-0-0.png']:
                self.assertTrue((root/'map'/name).is_file(),name)
            result2=build(source,root/'map',cache=root/'cache',workers=2)
            self.assertEqual(result2['dimensions']['o']['chunks'],result['dimensions']['o']['chunks'])
            audit=json.loads((root/'map/audit.json').read_text())
            self.assertEqual(audit['files'][0]['sha256'],digest)

    def test_partial_corrupt_export_is_explicit(self):
        with tempfile.TemporaryDirectory() as root:
            root=Path(root);source=root/'world';source.mkdir()
            (source/'o.-16,32').write_bytes(fixture())
            (source/'o.0,0').write_bytes(b'broken')
            result=build(source,root/'map',cache=root/'cache')
            self.assertEqual(result['errors'][0]['file'],'o.0,0')
            self.assertEqual(result['sourceFileCount'],2)

    def test_output_cannot_touch_save_or_unrelated_folder(self):
        with tempfile.TemporaryDirectory() as root:
            root=Path(root);source=root/'world';source.mkdir()
            (source/'o.-16,32').write_bytes(fixture())
            for out in [source,source/'map',root]:
                with self.assertRaises(ValueError):build(source,out,cache=root/'cache')
            out=root/'unrelated';out.mkdir();(out/'keep.txt').write_text('keep')
            with self.assertRaises(ValueError):build(source,out,cache=root/'cache')
            self.assertEqual((out/'keep.txt').read_text(),'keep')


if __name__=='__main__':unittest.main()
