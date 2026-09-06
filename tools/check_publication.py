"""Inspect Git-selected files before publication; never print matched private content."""
import argparse
import hashlib
from pathlib import PurePosixPath
import re
import struct
import subprocess
import sys

DENIED_PARTS = {'backups', 'restore-candidates', 'AI-Exports', '.objects', '.env', '.cache', '__pycache__'}
DENIED_NAMES = {'player_data', 'world_data', 'screenshot.jpg', 'poiOverworld', 'poiTheNether'}
TEXT_EXTENSIONS = {'.swift', '.py', '.md', '.txt', '.json', '.strings', '.rtf', '.js', '.cjs', '.html', '.css', '.sh', '.toml', '.command', '.tsv', '.obj', '.yml', '.yaml'}
TEXT_NAMES = {'LICENSE', '.gitignore', '.gitattributes'}
PATTERNS = {
    'personal local path': re.compile(r'/(?:Users|home)/[\w.-]+/|[A-Za-z]:\\Users\\[\w.-]+\\'),
    'private key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'credential': re.compile(r'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-proj-[A-Za-z0-9_-]{20,}'),
    'personal email': re.compile(r'[A-Za-z0-9._%+-]+@(?:gmail|icloud|gmx|hotmail|outlook|yahoo)\.[A-Za-z]+', re.I),
}

# Explicitly reviewed demo-only captures. Replacements require a fresh visual review.
REVIEWED_SCREENSHOTS = {
    "docs/screenshots/01-companion-overview.png": "be073787d8714e3c893428dfe6fe9865d2b300f763a90d39a98fbc4860b4fa3e",
    "docs/screenshots/02-demo-map.png": "80524ecad52eeb1fa1ab269ad4337e87827295fd0a15d13ae887eb77f7848aa4",
    "docs/screenshots/03-player-inventory.png": "8aa9c9b581051b5780abaffa595db753c1ebc178141e1d442cf3b8c7fda517f2",
    "docs/screenshots/04-demo-chests.png": "54ee3e50e649f87d88908ffba8025a02fcd3b500d8f11aa9537ced680ff346e7",
    "docs/screenshots/05-build-guides.png": "9e89070e7fba0f680e50ae9b5701fc745fdb8a7eb714facd87ed2b679c55f47a",
    "docs/screenshots/06-demo-3d.png": "7d23b7c8099b116debe1671bb2d287fbea48fa45c99d7e2daadad4e2545ca773",
    "docs/screenshots/07-ai-export.png": "96b31a780b7549fb7e57724630d10b50846836d4003c7afadea5561c31a46fbd"
}

def inspect(path, data, mode='100644'):
    p = PurePosixPath(path)
    errors = []
    if mode not in {'100644', '100755'}: errors.append('symlink or unsupported Git mode')
    if set(p.parts) & DENIED_PARTS or p.name in DENIED_NAMES or re.fullmatch(r'[on]\.-?\d+,-?\d+', p.name):
        errors.append('private or generated data path')
    if len(data) >= 50*1024*1024: errors.append('oversized file requires separate review')
    if path == 'docs/project-overview.svg':
        # Only this reviewed, code-authored project illustration is allowed.
        import xml.etree.ElementTree as ET
        try:
            text = data.decode('utf-8')
            root = ET.fromstring(text)
            allowed = {'svg', 'title', 'desc', 'defs', 'linearGradient', 'stop', 'g', 'rect', 'path', 'text', 'circle'}
            for element in root.iter():
                if element.tag.split('}')[-1] not in allowed: errors.append('unsupported SVG element')
                for key, value in element.attrib.items():
                    if key.lower().startswith('on') or key.split('}')[-1] in {'href', 'src'}: errors.append('active or external SVG content')
                    if 'url(' in value and not re.fullmatch(r'url\(#[A-Za-z0-9_-]+\)', value): errors.append('external SVG reference')
            for label, pattern in PATTERNS.items():
                if pattern.search(text): errors.append(label)
        except (UnicodeDecodeError, ET.ParseError): errors.append('invalid SVG')
    elif p.suffix == '.png':
        if path in REVIEWED_SCREENSHOTS:
            if hashlib.sha256(data).hexdigest() != REVIEWED_SCREENSHOTS[path]: errors.append('screenshot changed; fresh review required')
        elif not {'MobImages', 'PlayerSkins'}.intersection(p.parts): errors.append('unapproved image location')
        if not data.startswith(b'\x89PNG\r\n\x1a\n'): return errors + ['invalid PNG']
        offset = 8
        try:
            ended = False
            while offset < len(data):
                length = struct.unpack('>I', data[offset:offset+4])[0]
                kind = data[offset+4:offset+8]
                offset += length + 12
                if offset > len(data): raise ValueError()
                if kind in {b'tEXt', b'zTXt', b'iTXt', b'eXIf', b'tIME'}: errors.append('image metadata requires review')
                if kind == b'IEND':
                    ended = True
                    if offset != len(data): errors.append('trailing PNG data')
                    break
            if not ended: errors.append('missing PNG end')
        except (ValueError, struct.error): errors.append('malformed PNG')
    elif p.suffix in TEXT_EXTENSIONS or p.name in TEXT_NAMES:
        try: text = data.decode('utf-8')
        except UnicodeDecodeError: return errors + ['non-UTF-8 text requires review']
        for label, pattern in PATTERNS.items():
            if pattern.search(text): errors.append(label)
    else: errors.append('unapproved file type; archives and binary data are not allowed')
    return errors

def git(*args):
    return subprocess.check_output(['git', *args])

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--staged', action='store_true', help='Read index bytes instead of working-tree bytes')
    args = parser.parse_args()
    records = git('ls-files', '--stage', '-z').split(b'\0')
    blobs = {}
    if args.staged:
        ids = [record.split(b'\t', 1)[0].split()[1] for record in records if record]
        packed = subprocess.check_output(['git', 'cat-file', '--batch'], input=b'\n'.join(ids)+b'\n')
        offset = 0
        for oid in ids:
            end = packed.index(b'\n', offset)
            header = packed[offset:end].split()
            if len(header) != 3 or header[1] != b'blob': raise ValueError('Unexpected Git object')
            size = int(header[2]); offset = end + 1
            blobs[oid.decode()] = packed[offset:offset+size]
            offset += size + 1
    failures = 0; count = 0
    for record in records:
        if not record: continue
        header, path_bytes = record.split(b'\t', 1)
        mode, oid, stage = header.decode().split()
        path = path_bytes.decode('utf-8')
        if stage != '0':
            print(f'{path}: unresolved merge'); failures += 1; continue
        if args.staged:
            data = blobs[oid]
        else:
            from pathlib import Path
            if Path(path).is_symlink():
                print(f'{path}: symlink'); failures += 1; continue
            data = Path(path).read_bytes()
        errors = inspect(path, data, mode)
        if errors: print(f'{path}: {", ".join(errors)}'); failures += 1
        count += 1
    if not count: print('No Git-selected files to check.'); return 1
    print(f'Publication check: {count} files, {failures} failures. Manual content review is still required.')
    return bool(failures)

if __name__ == '__main__': sys.exit(main())
