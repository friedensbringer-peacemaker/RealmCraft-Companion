#!/usr/bin/env python3
"""Integration tests run the production Swift engine against a disposable Quest filesystem."""
import os, pathlib, subprocess, tempfile, json, zipfile, textwrap
BASE = pathlib.Path(__file__).resolve().parents[2]
APP = pathlib.Path(os.environ.get('REALMCRAFT_TEST_APP', str(BASE / 'RealmCraft Companion.app/Contents/MacOS/RealmCraftLibrary')))
FAKE = r'''#!/usr/bin/env python3
import os, sys, pathlib, shutil, hashlib, subprocess
args=sys.argv[1:]
if args[:1]==['-s']: args=args[2:]
root=pathlib.Path(os.environ['FAKE_QUEST'])
remote='/sdcard/Android/data/com.TellurionMobile.RealmCraft/files'
def mapped(s): return s.replace(remote,str(root))
if args[0]=='get-state': print('device'); sys.exit(0)
if args[0]=='shell':
    cmd=' '.join(args[1:])
    if cmd.startswith('pidof '):
        if os.environ.get('FAKE_RUNNING'): print('123'); sys.exit(0)
        sys.exit(1)
    if 'find . -type f' in cmd:
        import shlex
        folder=pathlib.Path(mapped(shlex.split(cmd)[1]))
        if not folder.is_dir(): sys.exit(1)
        for p in sorted(folder.rglob('*')):
            if p.is_file(): print(hashlib.sha256(p.read_bytes()).hexdigest()+'  ./'+p.relative_to(folder).as_posix())
        sys.exit(0)
    if cmd.startswith('mv ') and os.environ.get('FAKE_ACTIVATION_FAIL'):
        for p in root.glob('.library-stage-*'):
            for world in p.iterdir(): shutil.rmtree(world)
    sys.exit(subprocess.run(['/bin/sh','-c',mapped(cmd)]).returncode)
if args[0] in ('pull','push'):
    mode=args.pop(0)
    if args[0]=='-a': args.pop(0)
    source=pathlib.Path(mapped(args[0])); destination=pathlib.Path(mapped(args[1]))
    shutil.copytree(source,destination/source.name)
    if mode=='push' and os.environ.get('FAKE_CORRUPT_PUSH'):
        (destination/source.name/'world_data').write_text('CORRUPTED')
    sys.exit(0)
sys.exit(2)
'''
with tempfile.TemporaryDirectory(prefix='realmcraft-tests-') as tmp:
    tmp=pathlib.Path(tmp); fake=tmp/'adb'; fake.write_text(FAKE); fake.chmod(0o755)
    quest=tmp/'quest'; world=quest/'local/1234567890'; world.mkdir(parents=True)
    for name,data in [('world_data','original world'),('player_data','original player'),('o.0,0','chunk')]: (world/name).write_text(data)
    env=dict(os.environ, REALMCRAFT_LIBRARY=str(tmp/'library'), REALMCRAFT_ADB=str(fake), FAKE_QUEST=str(quest))
    def run(*args, ok=True, extra=None):
        p=subprocess.run([str(APP),*args],env=env| (extra or {}),text=True,capture_output=True)
        assert (p.returncode==0)==ok,(args,p.stdout,p.stderr)
        return p.stdout
    def entries(): return [json.loads(p.read_text()) for p in (tmp/'library').glob('*/savegame.json')]
    def snapshot(): return {p.name:p.read_bytes() for p in world.iterdir()}
    run('--backup','test','1234567890',ok=False,extra={'FAKE_RUNNING':'1'})
    assert not entries()
    run('--backup','test','1234567890')
    save=entries()[0]; saved=snapshot(); save_id=save['id']
    run('--backup','test','1234567890')
    duplicate=next(s for s in entries() if s['id'] != save_id)
    assert (tmp/'library'/save_id/'1234567890/world_data').stat().st_ino == (tmp/'library'/duplicate['id']/'1234567890/world_data').stat().st_ino
    run('--compact')
    print('PASS: repeated backups deduplicate identical file contents')
    import stat
    entry_folder=tmp/'library'/save_id
    for item in [entry_folder, *entry_folder.rglob('*')]: os.chflags(item, item.stat().st_flags | stat.UF_HIDDEN)
    run('--list')
    assert all(not (item.stat().st_flags & stat.UF_HIDDEN) for item in [entry_folder, *entry_folder.rglob('*')])
    print('PASS: previously hidden backup folders and files become visible')
    run('--verify')
    print('PASS: running-game guard, backup, file verification')
    (world/'world_data').write_text('new progress'); (world/'old-only').write_text('stale')
    current=snapshot()
    run('--restore','test',save_id,ok=False,extra={'FAKE_CORRUPT_PUSH':'1'})
    assert snapshot()==current
    print('PASS: corrupt transfer cannot replace current save')
    run('--restore','test',save_id,ok=False,extra={'FAKE_ACTIVATION_FAIL':'1'})
    assert snapshot()==current
    print('PASS: failed activation rolls original world back')
    run('--restore','test',save_id)
    assert snapshot()==saved
    assert any(s['source']=='Automatische Sicherung' for s in entries())
    print('PASS: complete replacement, stale files removed, automatic safety backup')
    zip_path=tmp/'export.zip'; run('--export',save_id,str(zip_path)); run('--import',str(zip_path)); run('--verify')
    print('PASS: ZIP export/import round trip')
    library_zip=tmp/'library-backup.zip'; run('--export-library',str(library_zip)); assert library_zip.exists() and library_zip.stat().st_size > 0
    print('PASS: verified full library ZIP export')
    evil=tmp/'evil.zip'
    with zipfile.ZipFile(evil,'w') as z: z.writestr('../escape','bad')
    run('--import',str(evil),ok=False); assert not (tmp/'escape').exists()
    with zipfile.ZipFile(evil,'w') as z:
        info=zipfile.ZipInfo('link'); info.create_system=3; info.external_attr=(0o120777<<16); z.writestr(info,'/tmp')
    run('--import',str(evil),ok=False)
    print('PASS: traversal and symlink archives rejected')
    (tmp/'library'/save_id/'1234567890/player_data').unlink()
    (tmp/'library'/save_id/'1234567890/player_data').write_text('tampered')
    run('--restore','test',save_id,ok=False); assert snapshot()==saved
    print('PASS: modified local save rejected before device write')
print('ALL INTEGRATION TESTS PASSED')
