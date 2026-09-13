#!/usr/bin/env python3
"""Local video cache and serialized yt-dlp acquisition. No network by default."""
import argparse
import fcntl
import hashlib
import json
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

DEFAULT = Path(__file__).resolve().parents[2] / 'video-workspace'

def save(path, data):
    tmp = path.with_suffix(path.suffix + '.tmp')
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    tmp.replace(path)

def digest(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()

def stamp():
    return datetime.now(timezone.utc).isoformat()

def probe(path):
    return json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries',
        'format=duration:stream=codec_type,width,height,avg_frame_rate', '-of', 'json', str(path)]))

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, default=DEFAULT)
    sub = p.add_subparsers(dest='action', required=True)
    sub.add_parser('doctor')
    sub.add_parser('status')
    imp = sub.add_parser('import-local')
    imp.add_argument('video_id'); imp.add_argument('file', type=Path)
    imp.add_argument('--game', choices=['minecraft', 'realmcraft', 'unknown'], required=True)
    imp.add_argument('--kind', choices=['media', 'captions', 'metadata'], required=True)
    imp.add_argument('--language', default='unknown')
    imp.add_argument('--offset', type=float, default=0)
    for name in ['plan', 'fetch']:
        q = sub.add_parser(name)
        q.add_argument('video_id')
        q.add_argument('--kind', choices=['metadata', 'captions', 'media'], required=True)
        q.add_argument('--language', default=None, help='Exactly one caption language, e.g. en-orig')
    a = p.parse_args(); root = a.root.resolve(); root.mkdir(parents=True, exist_ok=True)
    # One writer/network process per workspace, including imports and plans.
    with (root / '.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state_path = root / 'state.json'
        state = json.loads(state_path.read_text()) if state_path.exists() else {
            'network_stopped': True, 'stop_reason': 'Not configured; explicit source authorization required',
            'authorizations': {}, 'last_request_epoch': 0}
        if a.action == 'status':
            print(json.dumps(state, indent=2)); return
        python = root / '.venv/bin/python'
        if a.action == 'doctor':
            report = {'at': stamp(), 'network_requests': 0, 'network_stopped': state['network_stopped']}
            for tool in ['ffmpeg', 'ffprobe', 'deno', 'node']:
                report[tool] = shutil.which(tool)
            r = subprocess.run([str(python), '-c',
                'import importlib.metadata as m,json; print(json.dumps({x:m.version(x) for x in ["yt-dlp","yt-dlp-ejs"]}))'],
                capture_output=True, text=True) if python.exists() else None
            report['packages'] = json.loads(r.stdout) if r and r.returncode == 0 else 'Missing isolated yt-dlp/EJS installation'
            save(root / 'doctor.json', report); print(json.dumps(report, indent=2)); return
        if not re.fullmatch(r'[A-Za-z0-9_-]{11}', a.video_id):
            p.error('Expected a single 11-character video ID, not a URL or playlist')
        folder = root / 'cache' / a.video_id; folder.mkdir(parents=True, exist_ok=True)
        manifest_path = folder / 'manifest.json'
        manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {
            'video_id': a.video_id, 'url': 'https://www.youtube.com/watch?v=' + a.video_id,
            'source_game': 'unknown', 'artifacts': [], 'frames_inspected': 0}
        if a.action == 'import-local':
            if not a.file.is_file(): p.error('Local input file missing')
            if not 0 <= a.offset < float('inf'): p.error('Offset must be finite and nonnegative')
            media = probe(a.file) if a.kind == 'media' else None
            if a.kind == 'captions' and a.file.suffix == '.json3':
                data = json.loads(a.file.read_text())
                if not isinstance(data.get('events'), list): p.error('Invalid JSON3 captions')
            sha = digest(a.file)
            if any(x['sha256'] == sha and x['kind'] == a.kind for x in manifest['artifacts']):
                print('Already cached'); return
            dest = folder / (a.kind + '-' + sha[:16] + a.file.suffix)
            if manifest['source_game'] not in ['unknown', a.game]:
                raise SystemExit('Source game conflict; inspect manifest before importing')
            if not dest.exists(): shutil.copy2(a.file, dest)
            if digest(dest) != sha: raise SystemExit('Copy checksum mismatch')
            manifest['source_game'] = a.game
            manifest['artifacts'].append({'kind': a.kind, 'path': dest.name, 'sha256': sha,
                'imported_at': stamp(), 'language': a.language, 'original_time_offset_seconds': a.offset,
                'source': 'local import; video identity and scene alignment require review',
                'probe': media, 'review_status': 'unreviewed'})
            save(manifest_path, manifest); print(str(dest)); return
        if a.kind == 'captions' and (not a.language or not re.fullmatch(r'[A-Za-z0-9-]+', a.language)):
            p.error('Choose exactly one caption track language; no lists or wildcards')
        common = [str(python), '-m', 'yt_dlp', '--ignore-config', '--no-playlist',
            '--retries', '0', '--extractor-retries', '0', '--fragment-retries', '0',
            '--sleep-requests', '5', '--sleep-subtitles', '5', '--concurrent-fragments', '1',
            '--socket-timeout', '25', '--no-overwrites', '-o', str(folder / '%(id)s.%(ext)s')]
        if a.kind == 'metadata':
            cmd = common + ['--skip-download', '--write-info-json', manifest['url']]
        else:
            metadata = folder / (a.video_id + '.info.json')
            if not metadata.exists():
                p.error('Fetch and persist metadata first. Import files are retained separately and not trusted as executable download metadata.')
            cmd = common + ['--load-info-json', str(metadata)]
            if a.kind == 'captions':
                cmd += ['--skip-download', '--write-subs', '--write-auto-subs', '--sub-langs',
                        a.language, '--sub-format', 'json3']
            else:
                cmd += ['-f', 'bv*[height<=1080]+ba/b[height<=1080]', '--merge-output-format', 'mkv']
        if a.action == 'plan':
            print(json.dumps({'network_stopped': state['network_stopped'], 'command': cmd,
                'note': 'Plan only; no requests made. Inspect source authorization before execution.'}, indent=2)); return
        if state['network_stopped']: raise SystemExit('Network stopped: ' + state['stop_reason'])
        if a.kind not in state.get('authorizations', {}).get(a.video_id, []):
            raise SystemExit('No recorded authorization for this video and artifact kind')
        existing = [x for x in manifest['artifacts'] if x['kind'] == a.kind and
                    (a.kind != 'captions' or x.get('language') == a.language)]
        if existing:
            for artifact in existing:
                path = folder / artifact['path']
                if not path.is_file() or digest(path) != artifact['sha256']:
                    raise SystemExit('Cached artifact missing or changed; inspect before requesting again')
            print('Artifact already cached; no request made'); return
        time.sleep(max(0, 5 - (time.time() - state.get('last_request_epoch', 0))))
        # If interrupted or killed, the next invocation remains stopped until reviewed.
        state.update(network_stopped=True, stop_reason='Acquisition in progress or interrupted', last_request_epoch=time.time())
        save(state_path, state)
        r = subprocess.run(cmd, capture_output=True, text=True)
        log = r.stdout + r.stderr
        blocked = bool(re.search(r'\b(?:403|429)\b|captcha|sign in to confirm', log, re.I))
        files = list(folder.glob(a.video_id + '.*'))
        suffixes = {'metadata': ['.info.json'], 'captions': ['.' + a.language + '.json3'] if a.language else [], 'media': ['.mkv', '.mp4', '.webm']}
        found = [f for f in files if any(f.name.endswith(s) for s in suffixes[a.kind])]
        for f in found:
            sha = digest(f)
            if not any(x['sha256'] == sha for x in manifest['artifacts']):
                manifest['artifacts'].append({'kind': a.kind, 'path': f.name, 'sha256': sha,
                    'language': a.language, 'created_at': stamp(), 'review_status': 'unreviewed'})
        save(manifest_path, manifest)
        state.update(network_stopped=bool(blocked or r.returncode),
            stop_reason='Acquisition failed; inspect before resuming' if blocked or r.returncode else '',
            last_request_epoch=time.time(), last_result={'at': stamp(), 'video_id': a.video_id,
            'kind': a.kind, 'exit_code': r.returncode, 'access_denied': blocked, 'artifacts_saved': len(found)})
        save(state_path, state)
        # Avoid persisting signed URLs or credentials from verbose downloader output.
        print(json.dumps(state['last_result'], indent=2))
        if blocked or r.returncode: raise SystemExit('Stopped; no automatic retries')
        if not found: print('No matching artifact supplied; this is not a completed transcript or video')

if __name__ == '__main__':
    main()
