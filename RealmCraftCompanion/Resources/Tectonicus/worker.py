"""Companion-owned Tectonicus setup, rendering and loopback preview worker."""
from pathlib import Path
import argparse, contextlib, fcntl, hashlib, http.server, json, os, platform, re
import io, shutil, signal, subprocess, sys, threading, time, uuid, zipfile
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent/'MapEngine'))
TECTONICUS = 'https://github.com/tectonicus/tectonicus/releases/download/v2.31/Tectonicus-2.31.zip'
TECTONICUS_HASH = '7a00437319d8eb0c049f8528fe3aaba21c966f31564e6c3a0af0c5697ecb1ba3'
MINECRAFT_HASH = '8d9b65467c7913fcf6f5b2e729d44a1e00fde150'
MINECRAFT = f'https://piston-data.mojang.com/v1/objects/{MINECRAFT_HASH}/client.jar'
CHILD = None
PROGRESS = None
# 270°/90° gives south (+Z) up and north (−Z) down. The viewer also
# reflects left/right to match the requested mirrored Atlas view.
DEFAULT_CAMERA_ANGLE = 270
DEFAULT_CAMERA_ELEVATION = 90

class CancelledError(Exception):
    pass


def write_json(path, data):
    tmp = path.with_name(path.name+'.tmp')
    tmp.write_text(json.dumps(data, indent=2)+'\n')
    tmp.replace(path)


def progress(phase, detail='', fraction=None):
    if PROGRESS:
        write_json(PROGRESS, dict(phase=phase, detail=detail, fraction=fraction))


def terminate_child():
    global CHILD
    if CHILD and CHILD.poll() is None:
        with contextlib.suppress(ProcessLookupError): os.killpg(CHILD.pid, signal.SIGTERM)
        try: CHILD.wait(timeout=3)
        except subprocess.TimeoutExpired:
            with contextlib.suppress(ProcessLookupError): os.killpg(CHILD.pid, signal.SIGKILL)
            CHILD.wait()


def cancel(signum, frame):
    terminate_child()
    raise CancelledError('Cancelled. Original savegame was not modified.')


def run(args, timeout=600, cwd=None, render_log=None):
    global CHILD
    log = render_log or PROGRESS.with_suffix('.command.log')
    with log.open('w') as stream:
        CHILD = subprocess.Popen([str(a) for a in args], cwd=cwd, stdout=stream,
                                 stderr=subprocess.STDOUT, start_new_session=True)
        started = time.monotonic()
        try:
            while CHILD.poll() is None:
                if time.monotonic()-started > timeout:
                    terminate_child()
                    raise TimeoutError('Operation timed out; retry or select a smaller area.')
                if render_log:
                    with log.open('rb') as reader:
                        reader.seek(max(0, log.stat().st_size-1600))
                        tail = reader.read().decode('utf-8', errors='replace')
                    tiles = re.findall(r'tile (\d+) of (\d+)', tail)
                    if tiles:
                        done, total = map(int, tiles[-1])
                        progress('render', f'{done}/{total} tiles', done/total)
                    elif 'Downsampling' in tail:
                        progress('zoom', 'Zoom levels')
                time.sleep(0.25)
            code = CHILD.wait()
        finally:
            terminate_child()
            CHILD = None
    output = log.read_text(errors='replace')
    if code:
        raise RuntimeError(f'{Path(str(args[0])).name} exited {code}:\n'+output[-3000:])
    return output


def digest(path, algorithm='sha256'):
    h = hashlib.new(algorithm)
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024*1024), b''): h.update(chunk)
    return h.hexdigest()


def download(url, path, checksum=None, algorithm='sha256'):
    if not url.startswith('https://'):
        raise ValueError('Only HTTPS downloads are supported.')
    if checksum and path.is_file() and digest(path, algorithm) == checksum:
        return
    partial = path.with_name(path.name+'.partial')
    run(['/usr/bin/curl','--fail','--location','--silent','--show-error','--proto','=https',
         '--proto-redir','=https','--connect-timeout','30','--max-time','900','--retry','2',
         '--output',partial,url], timeout=2800)
    if checksum and digest(partial, algorithm) != checksum:
        raise ValueError('Download checksum mismatch: '+path.name)
    partial.replace(path)


def toolchain(support, probe=False):
    marker = json.loads((support/'active.json').read_text())
    folder = support/'toolchains'/str(uuid.UUID(marker['id']))
    for name, expected in marker['hashes'].items():
        file = (folder/name).resolve()
        if folder.resolve() not in file.parents or digest(file) != expected:
            raise ValueError('Installed tool checksum mismatch; run setup again.')
    java = (folder/marker['java']).resolve()
    if folder.resolve() not in java.parents or not os.access(java, os.X_OK):
        raise ValueError('Java is unavailable; run setup again.')
    if probe: run([java, '-version'], timeout=30)
    return folder, java


def setup(support):
    support.mkdir(parents=True, exist_ok=True)
    with (support/'.setup.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        try:
            toolchain(support, probe=True)
            progress('ready', 'Tectonicus 2.31 · Java 21 · Minecraft 1.17.1')
            return
        except (OSError, ValueError, KeyError, RuntimeError): pass
        cache = support/'downloads'; cache.mkdir(exist_ok=True)
        identifier = str(uuid.uuid4())
        folder = support/'toolchains'/identifier; folder.mkdir(parents=True)
        progress('download', 'Tectonicus 2.31')
        archive = cache/'Tectonicus-2.31.zip'
        download(TECTONICUS, archive, TECTONICUS_HASH)
        with zipfile.ZipFile(archive) as z:
            members = [n for n in z.namelist() if n.endswith('/lib/Tectonicus-2.31.jar')]
            if len(members) != 1: raise ValueError('Unexpected Tectonicus archive.')
            (folder/'tectonicus.jar').write_bytes(z.read(members[0]))
        progress('download', 'Minecraft Java 1.17.1 resources')
        client = cache/'minecraft-1.17.1.jar'
        download(MINECRAFT, client, MINECRAFT_HASH, 'sha1')
        shutil.copyfile(client, folder/'minecraft.jar')
        progress('download', 'Temurin Java 21 installer metadata')
        arch = {'arm64':'aarch64','x86_64':'x64'}.get(platform.machine())
        if not arch: raise ValueError('Unsupported Mac architecture.')
        metadata = cache/f'java21-{arch}.json'
        download(f'https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture={arch}&image_type=jdk&os=mac&vendor=eclipse', metadata)
        binaries = json.loads(metadata.read_text())
        installer = binaries[0]['binary']['installer']
        if not installer['link'].startswith('https://github.com/adoptium/temurin21-binaries/releases/download/'):
            raise ValueError('Unexpected Java download origin.')
        package = cache/(installer['checksum']+'.pkg')
        progress('download', 'Temurin Java 21 · '+str(round(installer['size']/1_000_000))+' MB')
        download(installer['link'], package, installer['checksum'])
        progress('java', 'Verifying signed and notarized Java installer')
        signature = run(['/usr/sbin/pkgutil','--check-signature',package], timeout=60)
        if 'Developer ID Installer: Eclipse Foundation' not in signature:
            raise ValueError('Unexpected Java installer signer.')
        run(['/usr/sbin/spctl','--assess','--type','install',package], timeout=120)
        expanded = folder/'jdk'
        run(['/usr/sbin/pkgutil','--expand-full',package,expanded], timeout=180)
        candidates = list(expanded.glob('*/Payload/Library/Java/JavaVirtualMachines/*/Contents/Home/bin/java'))
        if len(candidates) != 1: raise ValueError('Unexpected Java package layout.')
        java = candidates[0]
        run([java,'-version'], timeout=30)
        hashes = {n:digest(folder/n) for n in ('tectonicus.jar','minecraft.jar')}
        hashes[str(java.relative_to(folder))] = digest(java)
        write_json(support/'active.json', dict(id=identifier, java=str(java.relative_to(folder)),
                   hashes=hashes, renderer='2.31', minecraft='1.17.1', java_release=binaries[0]['release_name']))
        progress('ready', 'Tectonicus 2.31 · Java 21 · Minecraft 1.17.1')


def render(support, source, output, radius, detail, title,
           camera_angle=DEFAULT_CAMERA_ANGLE, camera_elevation=DEFAULT_CAMERA_ELEVATION):
    from exporter import export_world
    folder, java = toolchain(support, probe=True)
    output = output.resolve(); source = source.resolve()
    if output.exists() or output == source or source in output.parents or output in source.parents:
        raise ValueError('A fresh destination outside the savegame is required.')
    output.mkdir(parents=True)
    progress('verify', 'Preparing read-only export')
    manifest = export_world(source, output/'world', folder/'minecraft.jar', radius, progress)
    x1,z1,x2,z2 = manifest['bounds']
    root = ET.Element('tectonicus', version='2')
    ET.SubElement(root,'config',outputDir=str(output/'map'),cacheDir=str(output/'cache'),
                  minecraftJar=str(folder/'minecraft.jar'),numZoomLevels='5',numDownsampleThreads='2')
    ET.SubElement(root,'rasteriser',type='lwjgl',numSamples='0',tileSize='512')
    model = ET.SubElement(root,'map',name=title,worldDir=str(output/'world'),closestZoomSize=str(detail),
                          cameraAngle=str(camera_angle),cameraElevation=str(camera_elevation),origin=f'{(x1+x2)//2},{(z1+z2)//2}',useSmoothLighting='false')
    for name in ('signs','players','portals','chests','views','beacons'):
        ET.SubElement(model,name,filter='none')
    ET.SubElement(model,'layer',name='Experimental Overworld export',lighting='day',renderStyle='normal',imageFormat='png')
    config = output/'tectonicus.xml'; ET.ElementTree(root).write(config)
    progress('render', 'Starting Tectonicus')
    # Tectonicus uses glfw_async on macOS: do not pass -XstartOnFirstThread.
    log = run([java,'-Xmx3G','-jar',folder/'tectonicus.jar','-c',config],
              timeout=14400,cwd=output,render_log=output/'render.log')
    if 'Exception' in log or 'Render complete' not in log or not (output/'map/map.html').is_file():
        raise RuntimeError('Tectonicus did not finish. See render.log in the output folder.\n'+log[-2000:])
    progress('verify', 'Checking source hashes after rendering')
    for name, expected in manifest['source_sha256'].items():
        if digest(source/name) != expected: raise ValueError('Source changed during rendering: '+name)
    page = output/'map/map.html'
    page.write_bytes(viewer_html(output/'map'))
    result = dict(status='complete', title=title, date=time.time(), chunks=manifest['chunks'],
                  placeholders=manifest['placeholders'], radius=radius, detail=detail,
                  camera_angle=camera_angle, camera_elevation=camera_elevation,
                  renderer='2.31', minecraft='1.17.1', limitations=manifest['limitations'])
    write_json(output/'result.json', result)
    progress('complete', str(manifest['chunks'])+' chunks', 1)


def viewer_html(directory):
    """Enhance new and existing renderings without changing their tile images."""
    page = (directory/'map.html').read_bytes()
    mirror_marker = b'<!-- RealmCraft horizontal mirror v1 -->'
    if mirror_marker not in page:
        mirror = (HERE/'mirror.js').read_bytes()
        page = page.replace(b'</body>', mirror_marker+b'<script>'+mirror+b'</script></body>')
    marker = b'<!-- RealmCraft auto-fit -->'
    if marker in page: return page
    try:
        bounds = json.loads((directory.parent/'world/export-manifest.json').read_text())['bounds']
        if (len(bounds) != 4 or any(type(v) is not int or abs(v) > 30000000 for v in bounds)
                or bounds[0] > bounds[2] or bounds[1] > bounds[3]): return page
    except (OSError, ValueError, KeyError, TypeError):
        return page
    script = (HERE/'auto-fit.js').read_text().replace('__REALMCRAFT_BOUNDS__', json.dumps(bounds))
    return page.replace(b'</body>', marker+b'<script>'+script.encode()+b'</script></body>')


def serve(directory, parent):
    directory = directory.resolve()
    if not (directory/'map.html').is_file(): raise ValueError('Map is missing.')
    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self,*args,**kwargs): super().__init__(*args,directory=str(directory),**kwargs)
        def log_message(self,*args): pass
        def list_directory(self,path): self.send_error(403); return None
        def send_head(self):
            if self.path.split('?', 1)[0] == '/map.html' and not (directory/'map.html').is_symlink():
                page = viewer_html(directory)
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.send_header('Content-Length', str(len(page)))
                self.send_header('Cache-Control', 'no-store')
                self.end_headers()
                return io.BytesIO(page)
            return super().send_head()
        def translate_path(self,path):
            candidate = Path(super().translate_path(path)).resolve()
            return str(candidate if directory in candidate.parents else directory/'__denied__')
    server = http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler)
    progress('serving', str(server.server_port))
    def monitor():
        while True:
            time.sleep(2)
            if os.getppid() != parent: os._exit(0)
    threading.Thread(target=monitor,daemon=True).start()
    server.serve_forever()


def main():
    global PROGRESS
    p=argparse.ArgumentParser()
    p.add_argument('command',choices=['setup','status','render','serve'])
    p.add_argument('--support',type=Path,required=True)
    p.add_argument('--progress',type=Path,required=True)
    p.add_argument('--source',type=Path);p.add_argument('--output',type=Path)
    p.add_argument('--radius',type=int,choices=[0,128,256,512,1024],default=0)
    p.add_argument('--detail',type=int,choices=[16,32,64],default=32)
    p.add_argument('--camera-angle',type=int,choices=range(0,360,45),default=DEFAULT_CAMERA_ANGLE)
    p.add_argument('--camera-elevation',type=int,choices=[30,45,60,90],default=DEFAULT_CAMERA_ELEVATION)
    p.add_argument('--title',default='RealmCraft render')
    p.add_argument('--accept-minecraft-resources',action='store_true')
    p.add_argument('--parent',type=int,default=0)
    args=p.parse_args();PROGRESS=args.progress
    PROGRESS.parent.mkdir(parents=True,exist_ok=True)
    signal.signal(signal.SIGTERM,cancel);signal.signal(signal.SIGINT,cancel)
    try:
        if args.command=='setup':
            if not args.accept_minecraft_resources: raise ValueError('Minecraft resource download consent is required.')
            setup(args.support)
        elif args.command=='status':
            toolchain(args.support,probe=True);progress('ready','Tectonicus 2.31 · Java 21 · Minecraft 1.17.1')
        elif args.command=='render':
            if not args.source or not args.output: raise ValueError('Source and output are required.')
            render(args.support,args.source,args.output,args.radius,args.detail,args.title,args.camera_angle,args.camera_elevation)
        else:
            if not args.source or not args.parent: raise ValueError('Map and parent process required.')
            serve(args.source,args.parent)
        return 0
    except Exception as error:
        progress('cancelled' if isinstance(error,CancelledError) else 'error',str(error))
        print(str(error),file=sys.stderr)
        return 1

if __name__=='__main__': raise SystemExit(main())
