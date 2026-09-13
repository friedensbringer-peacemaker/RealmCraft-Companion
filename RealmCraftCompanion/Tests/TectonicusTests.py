"""Synthetic Tectonicus exporter regression tests; no real savegames or downloads."""
from pathlib import Path
import gzip, hashlib, io, json, struct, sys, tempfile, unittest, zipfile, zlib
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'Resources/Tectonicus'))
sys.path.insert(0, str(ROOT/'Resources/MapEngine'))
from exporter import export_world, block_mapping, build_chunk
from realmcraft_map.chunks import decode, Chunk
import worker

def rle(raw):
    result = bytearray()
    i = 0
    while i < len(raw):
        j = i + 1
        while j < len(raw) and raw[j] == raw[i]: j += 1
        count = j - i
        while count > 255:
            result.append(0)
            count -= 255
        result.extend((count, raw[i]))
        i = j
    return bytes(result)

def synthetic_fixture(destination):
    """Synthetic block-only v9 fixtures, never written to a game installation."""
    destination.mkdir(parents=True, exist_ok=False)
    for cx in (-16, 0):
        for cz in (-16, 0):
            blocks = np.zeros((256, 16, 16), dtype=np.uint32)
            blocks[:61] = 1
            blocks[61:63] = 9
            blocks[63] = 8
            for x in range(16):
                for z in range(16):
                    wx, wz = cx+x, cz+z
                    # Pond, sandy rim, and a platform with a glass-windowed hut.
                    if -13 <= wx <= -5 and -11 <= wz <= -3: blocks[63,x,z] = 28
                    if -12 <= wx <= -6 and -10 <= wz <= -4: blocks[63,x,z] = 26
                    if 2 <= wx <= 12 and 2 <= wz <= 12: blocks[64,x,z] = 12
                    if 3 <= wx <= 11 and 3 <= wz <= 11:
                        if wx in (3,11) or wz in (3,11):
                            blocks[65:69,x,z] = 13
                            if 5 <= wx <= 9 or 5 <= wz <= 9: blocks[66:68,x,z] = 72
                        blocks[69,x,z] = 13
                    if wz == 8 and wx in (-2,-1,0,1): blocks[64+wx+2,x,z] = 152
                    if wx == -3 and wz == 12: blocks[64:76,x,z] = 38
            # Distinct positive-x marker; unknown-state fallback and high-Y geometry.
            if (cx,cz)==(0,-16):
                blocks[64:67,12,4] = 13
                blocks[65,13,4] = 13
                blocks[66,14,4] = 13
                blocks[64,3,3] = 4095
                blocks[65,3,3] = 1 | (7 << 12)
                blocks[90:93,9,9] = 72
            chunks = []
            for y in range(16):
                section = blocks[y*16:(y+1)*16].reshape(-1)
                count = int(np.count_nonzero(section))
                if not count: chunks.append(struct.pack('>I', 0)); continue
                raw = b'\0'*4 + b''.join(rle(((section >> (8*c)) & 255).astype(np.uint8).tobytes()) for c in range(4))
                chunks.append(struct.pack('>II',count,len(raw)) + raw)
            data = struct.pack('>IiiBBB',9,cx,cz,0,8,16) + b''.join(chunks) + bytes([1]*16)
            name = f'o.{cx},{cz}'
            (destination/name).write_bytes(data)
            assert np.array_equal(decode(data,name).blocks, blocks)

def read(stream, fmt):
    return struct.unpack('>'+fmt, stream.read(struct.calcsize('>'+fmt)))[0]

def text(stream):return stream.read(read(stream,'H')).decode('utf-8')

def value(stream, kind):
    if kind in (1,3,4):return read(stream,{1:'b',3:'i',4:'q'}[kind])
    if kind==7:return stream.read(read(stream,'i'))
    if kind==8:return text(stream)
    if kind==9:
        subkind=read(stream,'B');count=read(stream,'i')
        return [value(stream,subkind) for _ in range(count)]
    if kind==10:
        result={}
        while (subkind:=read(stream,'B')):
            name=text(stream);result[name]=value(stream,subkind)
        return result
    if kind in (11,12):return [read(stream,'i' if kind==11 else 'Q') for _ in range(read(stream,'i'))]
    raise ValueError(kind)

def parse(raw):
    stream=io.BytesIO(raw)
    assert read(stream,'B')==10
    text(stream)
    result=value(stream,10)
    assert stream.read()==b''
    return result


class ExportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.source = self.root/'source'
        synthetic_fixture(self.source)
        self.assets = self.root/'client.jar'
        self.names = json.loads((ROOT/'Resources/MapEngine/realmcraft_map/blocks.json').read_text())
        with zipfile.ZipFile(self.assets, 'w') as z:
            for name in set(self.names.values()) | {'magenta_concrete'}:
                if name != 'unknown':
                    z.writestr('assets/minecraft/blockstates/'+name+'.json', '{"variants":{"":{"model":"test"}}}')

    def tearDown(self): self.tmp.cleanup()

    def test_all_cells_region_boundaries_and_hashes(self):
        output = self.root/'world'
        manifest = export_world(self.source, output, self.assets, 0)
        self.assertEqual(manifest['chunks'], 4)
        self.assertEqual(manifest['placeholders'], 1)
        self.assertEqual(parse(gzip.decompress((output/'level.dat').read_bytes()))['Data']['DataVersion'], 2730)
        seen = set(); cells = 0
        for region in (output/'region').glob('*.mca'):
            _,rx,rz,_ = region.name.split('.');rx=int(rx);rz=int(rz)
            raw = region.read_bytes(); used = {0,1}
            for slot in range(1024):
                loc = int.from_bytes(raw[slot*4:slot*4+4], 'big')
                if not loc: continue
                offset, sectors = loc>>8, loc&255
                self.assertGreaterEqual(offset, 2)
                self.assertLessEqual(offset+sectors, len(raw)//4096)
                self.assertFalse(used.intersection(range(offset, offset+sectors)))
                used.update(range(offset, offset+sectors))
                start=offset*4096;size=int.from_bytes(raw[start:start+4], 'big')
                self.assertEqual(raw[start+4], 2)
                self.assertLessEqual(size+4, sectors*4096)
                level = parse(zlib.decompress(raw[start+5:start+4+size]))['Level']
                cx,cz = rx*32+slot%32,rz*32+slot//32
                self.assertEqual((level['xPos'],level['zPos']), (cx,cz))
                name=f'o.{cx*16},{cz*16}';seen.add(name)
                data=(self.source/name).read_bytes()
                self.assertEqual(hashlib.sha256(data).hexdigest(), manifest['source_sha256'][name])
                original=decode(data,name)
                for section in level['Sections']:
                    palette=section['Palette'];bits=max(4,(len(palette)-1).bit_length());per=64//bits
                    indices=np.arange(4096,dtype=np.uint64)
                    packed=np.array(section['BlockStates'],dtype=np.uint64)
                    actual=(packed[indices//per]>>((indices%per)*bits))&((1<<bits)-1)
                    source=original.blocks[section['Y']*16:(section['Y']+1)*16].transpose(0,2,1).reshape(-1)
                    for state in np.unique(source):
                        m=manifest['mappings'][int(state)]
                        for pi in np.unique(actual[source==state]):
                            self.assertEqual(palette[int(pi)]['Name'], 'minecraft:'+m['target'])
                            self.assertEqual(palette[int(pi)].get('Properties',{}), m['properties'])
                    cells+=4096
        self.assertEqual(cells,262144)
        self.assertEqual(seen,set(manifest['source_sha256']))

    def test_guards(self):
        output=self.root/'world';output.mkdir()
        with self.assertRaises(ValueError): export_world(self.source,output,self.assets,0)
        with self.assertRaises(ValueError): export_world(self.source,self.source/'nested',self.assets,0)
        (self.source/'o.0,0').write_bytes(b'bad')
        with self.assertRaises(ValueError): export_world(self.source,self.root/'bad',self.assets,0)
        empty=self.root/'empty';empty.mkdir()
        with self.assertRaises(ValueError): export_world(empty,self.root/'none',self.assets,0)
        self.assertFalse((self.root/'none').exists())

    def test_five_bit_palette_and_sign_entities(self):
        names={str(i):'block_'+str(i) for i in range(30)}
        states={name:{'variants':{'':{}}} for name in names.values()}
        names['31']='spruce_wall_sign';states['spruce_wall_sign']={'variants':{'':{}}}
        mapping={i:block_mapping(i,names,states) for i in range(30)}
        mapping[31]=block_mapping(31,names,states)
        blocks=np.zeros((256,16,16),dtype=np.uint32)
        blocks[0]=np.arange(256).reshape(16,16)%30;blocks[2,3,4]=31
        c=Chunk(-16,32,0,blocks,0)
        level=parse(build_chunk(c,mapping))['Level'];section=level['Sections'][0]
        self.assertEqual(len(section['Palette']),31)
        for i in range(4096):
            pi=(section['BlockStates'][i//12]>>((i%12)*5))&31
            expected=int(blocks[i//256,i%16,(i//16)%16])
            self.assertEqual(section['Palette'][pi]['Name'],'minecraft:'+mapping[expected]['target'])
        sign=level['TileEntities'][0]
        self.assertEqual((sign['x'],sign['y'],sign['z']),(-13,2,36))
        self.assertEqual(sign['Text1'],'{"text":""}')

    def test_special_state_defaults(self):
        for name, props in [('chest',{'facing':'north','type':'single'}),('white_bed',{'part':'foot'}),('water',{'level':'0'})]:
            m=block_mapping(1,{'1':name},{name:{'variants':{'':{}}}})
            for k,v in props.items():self.assertEqual(m['properties'][k],v)

    def test_filtered_area_and_symlink(self):
        outside=self.source/'o.128,0'
        raw=bytearray((self.source/'o.0,0').read_bytes());struct.pack_into('>i',raw,4,128);outside.write_bytes(raw)
        m=export_world(self.source,self.root/'bounded',self.assets,128)
        self.assertEqual(m['chunks'],4)
        self.assertNotIn(outside.name,m['source_sha256'])
        (self.source/'o.16,0').symlink_to(self.source/'o.0,0')
        with self.assertRaises(ValueError):export_world(self.source,self.root/'linked',self.assets,0)

    def test_corrupt_download_preserves_existing_file(self):
        from unittest.mock import patch
        file=self.root/'cached';file.write_bytes(b'previous')
        worker.PROGRESS=self.root/'progress.json'
        def fake_run(args,timeout):
            Path(args[args.index('--output')+1]).write_bytes(b'bad download')
        with patch.object(worker,'run',side_effect=fake_run):
            with self.assertRaises(ValueError):worker.download('https://example.org/file',file,'0'*64)
        self.assertEqual(file.read_bytes(),b'previous')

    def test_setup_consent_and_checksum(self):
        file=self.root/'download';file.write_bytes(b'corrupt')
        self.assertNotEqual(worker.digest(file), '0'*64)
        self.assertRaises(ValueError,worker.download,'http://example.org',file)

if __name__=='__main__': unittest.main()
