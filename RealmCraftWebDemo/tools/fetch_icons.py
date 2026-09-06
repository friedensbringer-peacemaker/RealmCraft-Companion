"""Fetch only the version-pinned Companion icon archive for the static build."""
from pathlib import Path
import argparse, hashlib, json, urllib.request
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);args=p.parse_args()
config=json.loads((Path(__file__).resolve().parents[1]/'icon-source.json').read_text())
with urllib.request.urlopen(config['url'],timeout=90) as response:
    data=response.read(60_000_001)
if len(data)>60_000_000 or hashlib.sha256(data).hexdigest()!=config['sha256']:
    raise SystemExit('Icon archive failed size or checksum validation')
args.output.write_bytes(data)
print('Pinned icon archive verified.')
