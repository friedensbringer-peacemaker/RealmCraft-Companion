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
    if '-exec chmod' in cmd: print('Unbounded chmod rejected',file=sys.stderr); sys.exit(1)
    if 'chmod ' in cmd and os.environ.get('FAKE_CHMOD_FAIL'): sys.exit(1)
    if 'chmod 2770' in cmd:
        # macOS temp folders inherit wheel; simulate shell's membership in ext_data_rw.
        for directory in root.rglob('*'):
            if directory.is_dir(): os.chown(directory,-1,os.getgid())
    if cmd.startswith('pidof '):
        if os.environ.get('FAKE_RUNNING'): print('123'); sys.exit(0)
        sys.exit(1)
    if 'find . -type f' in cmd and 'sha256sum' in cmd:
        import shlex
        folder=pathlib.Path(mapped(shlex.split(cmd)[1]))
        if not folder.is_dir(): sys.exit(1)
        if os.environ.get('FAKE_TRAVERSAL'):
            print('a'*64+'  ./../escaped');sys.exit(0)
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
    if mode=='push':
        assert '/../' not in args[1], 'Restore target must use a canonical path'
        for file in source.rglob('*'):
            if file.is_file():
                parent=(destination/source.name/file.relative_to(source)).parent
                if not parent.is_dir():
                    print('remote secure_mkdirs failed: Operation not permitted',file=sys.stderr);sys.exit(1)
    if mode=='pull' and os.environ.get('FAKE_PULL_LOG'):
        with open(os.environ['FAKE_PULL_LOG'],'a') as log: log.write(source.relative_to(root).as_posix()+'\n')
    if source.is_file():
        shutil.copy2(source,destination)
        if mode=='pull' and os.environ.get('FAKE_CORRUPT_PULL'): destination.write_text('CORRUPT')
        if mode=='pull' and os.environ.get('FAKE_MUTATE_AFTER_PULL'): source.write_text('changed while copying')
    else: shutil.copytree(source,destination/source.name,dirs_exist_ok=True)
    if mode=='push' and os.environ.get('FAKE_CORRUPT_PUSH'):
        (destination/source.name/'world_data').write_text('CORRUPTED')
    sys.exit(0)
sys.exit(2)
'''
with tempfile.TemporaryDirectory(prefix='realmcraft-tests-') as tmp:
    tmp=pathlib.Path(tmp); fake=tmp/'adb'; fake.write_text(FAKE); fake.chmod(0o755)
    quest=tmp/'quest'; world=quest/'local/424242'; world.mkdir(parents=True)
    for name,data in [('world_data','original world'),('player_data','original player'),('o.0,0','chunk'),('nested/sub/chunk','nested chunk')]:
        (world/name).parent.mkdir(parents=True,exist_ok=True); (world/name).write_text(data)
    env=dict(os.environ, REALMCRAFT_LIBRARY=str(tmp/'library'), REALMCRAFT_ADB=str(fake), FAKE_QUEST=str(quest))
    def run(*args, ok=True, extra=None):
        p=subprocess.run([str(APP),*args],env=env| (extra or {}),text=True,capture_output=True)
        assert (p.returncode==0)==ok,(args,p.stdout,p.stderr)
        return p.stdout
    def entries(): return [json.loads(p.read_text()) for p in (tmp/'library').glob('*/savegame.json')]
    def snapshot(): return {str(p.relative_to(world)):p.read_bytes() for p in world.rglob('*') if p.is_file()}
    run('--backup','test','424242',ok=False,extra={'FAKE_RUNNING':'1'})
    assert not entries()
    run('--backup','test','424242')
    save=entries()[0]; saved=snapshot(); save_id=save['id']
    pull_log=tmp/'pulls.log'; pull_log.write_text('')
    run('--backup','test','424242',extra={'FAKE_PULL_LOG':str(pull_log)})
    assert pull_log.read_text() == '', 'Identical follow-up must not pull files'
    duplicate=next(s for s in entries() if s['id'] != save_id)
    assert (tmp/'library'/save_id/'424242/world_data').stat().st_ino == (tmp/'library'/duplicate['id']/'424242/world_data').stat().st_ino
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
    run('--restore','test',save_id,ok=False,extra={'FAKE_CHMOD_FAIL':'1'})
    assert snapshot()==current
    print('PASS: permission failure cannot replace current save')
    run('--restore','test',save_id)
    assert snapshot()==saved
    assert all(p.stat().st_mode & 0o7777 == (0o2770 if p.is_dir() else 0o660) for p in [world,*world.rglob('*')])
    print('PASS: nested directories prepared before push; file/directory write modes verified')
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
    (tmp/'library'/save_id/'424242/player_data').unlink()
    (tmp/'library'/save_id/'424242/player_data').write_text('tampered')
    run('--restore','test',save_id,ok=False); assert snapshot()==saved
    print('PASS: modified local save rejected before device write')
    # An isolated second world exercises transfer optimization without touching the restore fixtures.
    other=quest/'local/515151'; other.mkdir()
    for name in ['world_data','player_data','o.-16,0','o.0,0','o.16,0','old-chunk']:
        (other/name).write_text('synthetic '+name)
    def latest_other(): return max((s for s in entries() if s['world']=='515151'),key=lambda s:s['date'])
    run('--backup','test','515151')
    original=latest_other(); original_dir=tmp/'library'/original['id']/'515151'
    original_bytes={p.name:p.read_bytes() for p in original_dir.iterdir()}
    (other/'o.0,0').write_text('CHANGED')
    (other/'new folder').mkdir();(other/'new folder/new file').write_text('NEW')
    (other/'old-chunk').unlink(); pull_log.write_text('')
    run('--backup','test','515151',extra={'FAKE_PULL_LOG':str(pull_log)})
    assert set(pull_log.read_text().splitlines())=={'local/515151/o.0,0','local/515151/new folder/new file'}
    incremental=latest_other(); target=tmp/'library'/incremental['id']
    report=json.loads((target/'backup-transfer.json').read_text())
    assert report['mode']=='incremental-transfer' and report['downloadedFiles']==2 and report['reusedFiles']==4
    assert not (target/'515151/old-chunk').exists()
    assert {p.name:p.read_bytes() for p in original_dir.iterdir()}==original_bytes
    print('PASS: only changed/new files pulled; nested names and removals respected; source unchanged')
    (other/'player_data').write_text('next change'); count=len(entries())
    run('--backup','test','515151',ok=False,extra={'FAKE_CORRUPT_PULL':'1'})
    assert len(entries())==count
    run('--backup','test','515151',ok=False,extra={'FAKE_MUTATE_AFTER_PULL':'1'})
    assert len(entries())==count
    run('--backup','test','515151',ok=False,extra={'FAKE_TRAVERSAL':'1'})
    assert len(entries())==count and not (tmp/'escaped').exists()
    print('PASS: corrupt pull, changing remote snapshot and traversal rejected without committing backup')
    # A damaged reusable base falls back to full transfer, never trusts matching metadata alone.
    damaged=target/'515151/o.16,0';damaged.unlink();damaged.write_text('LOCAL CORRUPTION');pull_log.write_text('')
    run('--backup','test','515151',extra={'FAKE_PULL_LOG':str(pull_log)})
    assert pull_log.read_text().strip()=='local/515151'
    assert json.loads((tmp/'library'/latest_other()['id']/'backup-transfer.json').read_text())['mode']=='full'
    print('PASS: damaged prior backup forces a verified full transfer')
print('ALL INTEGRATION TESTS PASSED')
