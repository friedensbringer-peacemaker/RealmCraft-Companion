#!/usr/bin/env python3
"""Disposable local transport double; never contacts an Android device."""
import sys,shlex,hashlib,shutil
from pathlib import Path
root=Path(__file__).parent/'quest'
args=sys.argv[3:]
if args==['get-state']:print('device');sys.exit(0)
if args[0]=='push':
 source=Path(args[1]);dest=root/args[2].lstrip('/');dest.mkdir(parents=True,exist_ok=True)
 shutil.copytree(source,dest/source.name);sys.exit(0)
assert args[0]=='shell', args
cmd=args[1];tokens=shlex.split(cmd)
if cmd.startswith('pidof '):sys.exit(0 if (root/'running').exists() else 1)
if cmd=='mv --help':print('-n Never overwrite\n-T Treat destination as file');sys.exit(0)
if cmd.startswith('ls -1 '):
 p=root/tokens[2].lstrip('/')
 if not p.exists():sys.exit(1)
 print('\n'.join(sorted(f.name for f in p.iterdir())));sys.exit(0)
if cmd.startswith('test -f '):
 sys.exit(0 if all((root/tokens[i].lstrip('/')).is_file() for i in (2,6)) else 1)
if cmd.startswith('if test -e '):
 p=root/tokens[3].lstrip('/');sys.exit(42 if p.exists() or p.is_symlink() else 0)
if cmd.startswith('cd '):
 p=root/tokens[1].lstrip('/')
 for f in sorted(p.rglob('*')):
  if f.is_file():print(hashlib.sha256(f.read_bytes()).hexdigest()+'  ./'+str(f.relative_to(p)))
 sys.exit(0)
if tokens[0]=='mkdir':(root/tokens[1].lstrip('/')).mkdir(parents=True);sys.exit(0)
if tokens[0]=='rmdir':(root/tokens[1].lstrip('/')).rmdir();sys.exit(0)
if tokens[:3]==['mv','-T','-n']:
 source=root/tokens[3].lstrip('/');target=root/tokens[4].lstrip('/')
 if (root/'collision').exists():
  target.mkdir(parents=True,exist_ok=True);(target/'untouched').write_text('keep')
 if target.exists():sys.exit(1)
 source.rename(target);sys.exit(0)
raise RuntimeError(cmd)
