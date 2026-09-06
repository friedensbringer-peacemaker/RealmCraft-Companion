"""Package explicitly mapped, unchanged PNGs; never include other archive entries."""
import base64, hashlib, io, json, struct, zipfile

def package(root, destination, archive):
    images={}; credits='Icon archive not supplied. Item IDs remain available.\n'
    if archive:
        data=archive.read_bytes()
        expected=json.loads((root/'icon-source.json').read_text())['sha256']
        if len(data)>60_000_000 or hashlib.sha256(data).hexdigest()!=expected:
            raise ValueError('Only the checksum-pinned icon archive may be packaged')
        mapping=json.loads((root/'data/ItemIcons.json').read_text())
        with zipfile.ZipFile(io.BytesIO(data)) as pack:
            credits=pack.read('pack.txt').decode('utf-8-sig')
            for item,path in mapping.items():
                assert item.isdigit() and path.startswith('assets/minecraft/textures/') and '..' not in path and path.endswith('.png')
                png=pack.read(path)
                assert len(png)<1_000_000 and png[:8]==b'\x89PNG\r\n\x1a\n'
                width,height=struct.unpack('>II',png[16:24]);assert 0<width==height<=512
                images[item]='data:image/png;base64,'+base64.b64encode(png).decode('ascii')
    outputs={'icons-data.js':'globalThis.CompanionIcons='+json.dumps(images,separators=(',',':'))+';\n','icon-pack-credits.txt':credits}
    for name,text in outputs.items():(destination/name).write_text(text)
    return {name:hashlib.sha256((destination/name).read_bytes()).hexdigest() for name in outputs}
