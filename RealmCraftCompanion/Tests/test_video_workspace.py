import subprocess,sys,tempfile,json
from pathlib import Path
script=Path(__file__).resolve().parents[1] / 'Tools/video_workspace.py'
with tempfile.TemporaryDirectory() as td:
 root=Path(td);state=root/'state.json'
 def run(*args):return subprocess.run([sys.executable,str(script),'--root',str(root),*args],capture_output=True,text=True)
 state.write_text(json.dumps({'network_stopped':True,'stop_reason':'test 429','authorizations':{},'last_request_epoch':0}))
 assert run('fetch','abcdefghijk','--kind','metadata').returncode!=0
 assert run('plan','abcdefghijk','--kind','metadata').returncode==0
 raw=root/'input.json3';raw.write_text('{"events":[]}')
 args=['import-local','abcdefghijk',str(raw),'--kind','captions','--game','minecraft','--language','en-orig']
 assert run(*args).returncode==0
 assert 'Already cached' in run(*args).stdout
 manifest=json.loads((root/'cache/abcdefghijk/manifest.json').read_text());assert len(manifest['artifacts'])==1 and manifest['frames_inspected']==0
 assert run('plan','abcdefghijk','--kind','captions','--language','en,de').returncode!=0
 fake=root/'.venv/bin/python';fake.parent.mkdir(parents=True)
 fake.write_text('#!'+sys.executable+'\nimport sys\nprint("ERROR: HTTP Error 429 Too Many Requests",file=sys.stderr)\nsys.exit(1)\n');fake.chmod(0o755)
 state.write_text(json.dumps({'network_stopped':False,'stop_reason':'','authorizations':{'abcdefghijk':['metadata']},'last_request_epoch':0}))
 assert run('fetch','abcdefghijk','--kind','metadata').returncode!=0
 result=json.loads(state.read_text());assert result['network_stopped'] and result['last_result']['access_denied']
 assert 'Network stopped' in run('fetch','abcdefghijk','--kind','metadata').stderr
 print('PASS: stopped fetch, offline planning, verified import, deduplication, single language, simulated 429 stops subsequent requests')
