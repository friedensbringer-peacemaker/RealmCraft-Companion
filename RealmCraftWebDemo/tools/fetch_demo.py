"""Fetch only the explicitly reviewed demo asset and verify its pinned checksum."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--owner', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    source = json.loads((ROOT/'demo-source.json').read_text())
    for value in (args.owner, source['repository'], source['release'], source['asset']):
        if not re.fullmatch(r'[A-Za-z0-9_.-]+', value):
            raise ValueError('Invalid demo source component')
    url = f"https://github.com/{args.owner}/{source['repository']}/releases/download/{source['release']}/{source['asset']}"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['curl', '--fail', '--location', '--silent', '--show-error', '--max-time', '120',
                    '--max-filesize', str(128*1024*1024), '--output', str(args.output), url], check=True)
    if hashlib.sha256(args.output.read_bytes()).hexdigest() != source['sha256']:
        raise ValueError('Demo asset changed. Review the new archive and update demo-source.json before publication.')
    with zipfile.ZipFile(args.output) as archive:
        if archive.testzip() is not None:
            raise ValueError('Demo ZIP integrity failed')
    print('Previously reviewed demo downloaded; pinned SHA-256 and ZIP integrity verified.')

if __name__ == '__main__':
    main()
