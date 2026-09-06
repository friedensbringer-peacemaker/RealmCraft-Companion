"""Package only source and build inputs; never include saves, credentials or build output."""
from pathlib import Path
import zipfile, sys
base=Path(__file__).resolve().parent
output=Path(sys.argv[1]); output.parent.mkdir(parents=True,exist_ok=True)
files=[]
for folder in ['Sources','Resources','Tests']:
    files.extend(p for p in (base/folder).rglob('*') if p.is_file() and p.suffix in {'.swift','.py','.strings','.json','.rtf','.md','.js','.html','.css','.cjs','.png','.txt','.tsv','.obj'} and '__pycache__' not in p.parts)
for name in ['build.sh','icon.swift','make_icon.py','make_localizations.py','package_source.py','translations.txt','count_source_lines.py','README.md','LIESMICH-README.txt','LICENSE','COMMUNITY.md']:
    files.append(base/name)
for name in ['import_video_channel.py', 'Research/tarantnet-channel-2026-09-06/README.md', 'Research/tarantnet-channel-2026-09-06/titles-de.tsv', 'Research/tarantnet-channel-2026-09-06/inventory.json']:
    files.append(base/name)
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
    for p in sorted(files): archive.write(p,'RealmCraft-Savegame-Library-Source/'+p.relative_to(base).as_posix())
print(f'Community source: {len(files)} files, {output.stat().st_size} bytes')
