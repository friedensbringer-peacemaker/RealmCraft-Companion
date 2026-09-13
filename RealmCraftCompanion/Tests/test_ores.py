import sys,struct,json,tempfile,unittest,hashlib
from pathlib import Path
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'Resources/MapEngine'))
from realmcraft_map.ores import scan,sample_scan,GROUPS,MATERIALS

def encode(blocks,x=-16,z=0,dim=0,biomes=None):
    result=bytearray(struct.pack('>IiiBBB',9,x,z,dim,8,16))
    for sy in range(16):
        values=blocks[sy*16:(sy+1)*16].reshape(-1)
        if not np.any(values):result.extend(struct.pack('>I',0));continue
        payload=bytearray(4)
        for channel in range(4):
            vals=((values>>(8*channel))&255).tolist();i=0
            while i<4096:
                end=i+1
                while end<4096 and vals[end]==vals[i]:end+=1
                size=end-i
                while size>255:payload.append(0);size-=255
                payload.extend([size,vals[i]]);i=end
        result.extend(struct.pack('>II',int(np.count_nonzero(values)),len(payload)));result.extend(payload)
    return bytes(result)+bytes(biomes if biomes is not None else [4]*16)

class OreTests(unittest.TestCase):
    def test_axis_mask_states_variants_denominators_and_readonly(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);a=np.zeros((256,16,16),dtype=np.uint32)
            a[12,15,2]=31|(7<<12);a[12,14,2]=32;a[12,13,2]=639;a[13,15,2]=155
            data=encode(a);(root/'o.-16,0').write_bytes(data)
            r=scan(root,'o',[-3,-1,12,12,2,2]);row=r['levels'][0]
            self.assertEqual((row['blocks'],row['nonAir'],row['ores']['gold'],row['ores']['diamond']),(3,2,2,0))
            self.assertEqual(r['hashes']['o.-16,0'],hashlib.sha256(data).hexdigest())
            self.assertEqual((root/'o.-16,0').read_bytes(),data)
    def test_missing_corrupt_and_wrong_dimension_are_not_zero_samples(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);(root/'o.0,0').write_bytes(b'broken')
            r=scan(root,'o',[-16,15,0,255,0,15])
            self.assertEqual(r['scanned'],0);self.assertEqual(len(r['errors']),1);self.assertEqual(len(r['missing']),1)
            self.assertEqual(sum(x['blocks'] for x in r['levels']),0)
            a=np.zeros((256,16,16),dtype=np.uint32);(root/'n.0,0').write_bytes(encode(a,0,0,0))
            self.assertEqual(len(scan(root,'n',[0,15,0,255,0,15])['errors']),1)
    def test_pair_only_removed_ore_blocks_not_drops_or_replacements(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);before=root/'before';after=root/'after';before.mkdir();after.mkdir()
            a=np.zeros((256,16,16),dtype=np.uint32);a[10,0:4,0]=[31,32,1,0]
            (before/'o.0,0').write_bytes(encode(a,0));b=a.copy();b[10,0:3,0]=0;(after/'o.0,0').write_bytes(encode(b,0))
            r=scan(after,'o',[0,3,10,10,0,0],before);p=r['probe']
            self.assertTrue(p['complete']);self.assertEqual((p['removed'],p['beforeAir'],p['counts']['gold']),(3,1,2))
            b[10,1,0]=1;(after/'o.0,0').write_bytes(encode(b,0));p=scan(after,'o',[0,3,10,10,0,0],before)['probe']
            self.assertFalse(p['complete']);self.assertEqual((p['remaining'],p['otherChanges'],p['counts']['gold']),(1,1,1))
    def test_unknown_blocks_prevent_completed_probe(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);before=root/'before';after=root/'after';before.mkdir();after.mkdir()
            a=np.zeros((256,16,16),dtype=np.uint32);a[10,0,0]=4095
            (before/'o.0,0').write_bytes(encode(a,0));(after/'o.0,0').write_bytes(encode(np.zeros_like(a),0))
            p=scan(after,'o',[0,0,10,10,0,0],before)['probe'];self.assertFalse(p['complete']);self.assertEqual(p['unknown'],1)
    def test_biome_cells_partition_counts_with_clipped_axes(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);a=np.full((256,16,16),31,dtype=np.uint32)
            (root/'o.0,0').write_bytes(encode(a,0,biomes=list(range(16))))
            r=scan(root,'o',[3,5,10,10,3,5]);biomes={b['id']:b for b in r['biomes']}
            self.assertEqual({k:b['columns'] for k,b in biomes.items()},{'0':1,'1':2,'4':2,'5':4})
            self.assertEqual(sum(b['levels'][0]['ores']['gold'] for b in biomes.values()),9)
    def test_selected_area_material_report_has_explicit_world_block_categories(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);a=np.zeros((256,16,16),dtype=np.uint32)
            a[9,0:6,0]=[31,811,153,170,151,13]
            (root/'o.0,0').write_bytes(encode(a,0))
            row=scan(root,'o',[0,5,9,9,0,0])['levels'][0]
            self.assertEqual(row['materials']['gold'],1)
            self.assertEqual({key:row['materials'][key] for key in ('amethyst','chest','rail','spawner','planks')},
                             {'amethyst':1,'chest':1,'rail':1,'spawner':1,'planks':1})
            self.assertEqual(set(MATERIALS['amethyst']),{811,812,813,814,815,816})
    def test_sampling_reproducible_unique_and_not_dimension_mixed(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);a=np.zeros((256,16,16),dtype=np.uint32);a[10,0,0]=155
            for x in [-512,-496,0,16,512,528]:(root/f'o.{x},0').write_bytes(encode(a,x))
            (root/'n.0,0').write_bytes(encode(a,0,dim=1))
            first=sample_scan(root,'o',3,42);second=sample_scan(root,'o',3,42)
            self.assertEqual(first['sampling'],second['sampling']);self.assertEqual(first['scanned'],3)
            self.assertEqual(len(set(first['sampling']['selected'])),3)
            self.assertEqual(sum(x['ores']['diamond'] for x in first['levels']),3)
            self.assertEqual(sum(x['blocks'] for x in first['levels']),3*65536)
            self.assertEqual(sample_scan(root,'o',20,42)['scanned'],6)
    def test_limits_and_symlinks(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);(root/'o.0,0').symlink_to('/dev/null')
            self.assertEqual(len(scan(root,'o',[0,15,0,255,0,15])['errors']),1)
            for bounds in [[0,15,-1,20,0,15],[16,0,0,255,0,15],[0,100000,0,255,0,100000]]:
                with self.assertRaises(ValueError):scan(root,'o',bounds)
            with self.assertRaises(ValueError):sample_scan(root,'o',513,0)
            with self.assertRaises(ValueError):scan(root,'o',[0,15,0,255,0,15],root)
    def test_catalog_ids_are_explicit_and_match_decoder(self):
        resources=Path(__file__).resolve().parents[1]/'Resources'
        for file in ['OreReference.json','OreReferenceLegacy.json']:
            c=json.loads((resources/file).read_text());self.assertEqual(len(c['entries']),11)
            for ore in c['entries']:
                self.assertEqual(set(ore['blockIDs']),set(GROUPS[ore['id']]))
                for b in ore['batches']:
                    self.assertLessEqual(b['low'],b['high']);self.assertGreater(b['attempts'],0)
                    self.assertTrue(all(u.startswith('https://') for u in b['sources']))
        gold=next(o for o in json.loads((resources/'OreReference.json').read_text())['entries'] if o['id']=='gold')
        lower=next(b for b in gold['batches'] if b['id']=='ore_gold_lower')
        self.assertEqual((lower['low'],lower['high'],lower['attempts']),(-64,-48,.5))


class SpatialOreTests(unittest.TestCase):
    def test_spatial_coordinates_coverage_and_area_totals(self):
        import base64
        with tempfile.TemporaryDirectory() as td:
            root=Path(td)
            a=np.zeros((256,16,16),dtype=np.uint32)
            a[12,15,2]=31|(9<<12);a[13,14,3]=155
            (root/'o.-16,0').write_bytes(encode(a))
            r=scan(root,'o',[-2,1,12,13,2,3],spatial=True)
            v=np.frombuffer(base64.b64decode(r['spatial']['data']),dtype='<u2').reshape(2,2,4)
            self.assertEqual(v[0,0,1],31)
            self.assertEqual(v[1,1,0],155)
            self.assertTrue(np.all(v[:,:,2:]==65535))
            self.assertEqual(v[0,1,0],0)
            self.assertEqual(r['areas'][0]['materials']['gold'],1)
            self.assertEqual(sum(x['blocks'] for x in r['areas']),r['levels'][0]['blocks']+r['levels'][1]['blocks'])
            self.assertEqual(r['spatial']['encoding'],'u16le-yzx-v1')
    def test_spatial_memory_limit_and_sample_compatibility(self):
        with tempfile.TemporaryDirectory() as td:
            r=scan(Path(td),'o',[0,255,0,255,0,255],spatial=True)
            self.assertIsNone(r['spatial']);self.assertEqual(r['areas'],[])
            self.assertEqual(len(r['missing']),256)
            r=scan(Path(td),'o',[0,0,0,0,0,0])
            self.assertIsNone(r['spatial']);self.assertIsNone(r['areas'])

if __name__=='__main__':unittest.main()
