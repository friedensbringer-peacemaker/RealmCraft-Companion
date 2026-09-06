from pathlib import Path
import struct, sys
source, target = map(Path, sys.argv[1:])
entries = [('icp4','16x16'),('icp5','32x32'),('icp6','32x32@2x'),('ic07','128x128'),('ic08','256x256'),('ic09','512x512'),('ic10','512x512@2x')]
body = b''
for tag, name in entries:
    data = (source/f'icon_{name}.png').read_bytes()
    body += tag.encode() + struct.pack('>I',len(data)+8) + data
target.write_bytes(b'icns' + struct.pack('>I',len(body)+8) + body)
