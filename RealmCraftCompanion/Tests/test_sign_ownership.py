import unittest
from realmcraft_map.chests import classify_sign_chests

class SignOwnershipTests(unittest.TestCase):
    def test_names_require_readable_face_adjacent_signs(self):
        def chest():
            return {'id':'o:15,50,0','dimension':'o','x':15,'y':50,'z':0}
        def sign(dx,dy,dz, text='\n Tools \n and supplies ', readable=True, dim='o'):
            return {'id':f'{dim}:sign:{15+dx},{50+dy},{dz}', 'x':15+dx,'y':50+dy,'z':dz,'text':text,'readable':readable}
        for offset in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]:
            c=chest(); a=sign(*offset)
            classify_sign_chests([c],[a])
            self.assertEqual(c['signName'],'Tools and supplies')
            self.assertEqual(c['nameSign'],a['id'])
            classify_sign_chests([c],[])
            self.assertNotIn('signName',c)
            self.assertNotIn('nameSign',c)
        for a in [sign(1,1,0),sign(0,2,0),sign(0,0,0),sign(1,0,0,readable=False),sign(1,0,0,text='  \n'),sign(1,0,0,dim='n')]:
            c=chest();classify_sign_chests([c],[a]);self.assertNotIn('signName',c)
        a,b=sign(1,0,0),sign(-1,0,0,text='Other stock')
        c=chest();classify_sign_chests([c],[a,b]);self.assertNotIn('signName',c)
        b['text']=a['text']
        classify_sign_chests([c],[a,b]);self.assertEqual(c['signName'],'Tools and supplies')
        source=c['nameSign']
        classify_sign_chests([c],[b,a]);self.assertEqual(c['nameSign'],source)

    def test_combined_chunk_reader_preserves_chests_and_reads_unlabeled_signs(self):
        import tempfile
        from pathlib import Path
        from test_chests import chunk, record
        from realmcraft_map.chests import scan_chunk_with_signs
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'o.-64,0'
            path.write_bytes(chunk() + record())
            chests, errors, signs = scan_chunk_with_signs(path)
            self.assertEqual(len(chests), 1)
            self.assertEqual(errors, [])
            self.assertEqual(signs, [])
            path.write_bytes(chunk(172))
            chests, errors, signs = scan_chunk_with_signs(path)
            self.assertEqual(chests, [])
            self.assertEqual(errors, [])
            self.assertEqual(len(signs), 1)
            self.assertFalse(signs[0]['readable'])

    def test_radius_height_dimensions_and_chunk_boundaries(self):
        sign = {'id': 'o:sign:-16,50,0', 'x': -16, 'y': 50, 'z': 0, 'readable': False, 'text': ''}
        def chest(x,y,z,dim='o'):
            return {'id':f'{dim}:{x},{y},{z}','dimension':dim,'x':x,'y':y,'z':z}
        records = [chest(14,60,0),chest(14,61,0),chest(15,50,0),chest(2,40,24),chest(2,39,24),chest(14,50,1),chest(-16,50,0,'n')]
        classify_sign_chests(records,[sign])
        self.assertEqual([bool(c.get('nearbySign')) for c in records],[True,False,False,True,False,False,False])
        classify_sign_chests(records,[])
        self.assertTrue(all('nearbySign' not in c for c in records))

    def test_nearest_is_deterministic_and_does_not_depend_on_text(self):
        signs=[{'id':'o:sign:1,0,0','x':1,'y':0,'z':0},{'id':'o:sign:-1,0,0','x':-1,'y':0,'z':0}]
        chest={'id':'o:0,0,0','dimension':'o','x':0,'y':0,'z':0}
        classify_sign_chests([chest],signs)
        first=chest['nearbySign']
        classify_sign_chests([chest],list(reversed(signs)))
        self.assertEqual(chest['nearbySign'],first)

if __name__=='__main__':unittest.main()
