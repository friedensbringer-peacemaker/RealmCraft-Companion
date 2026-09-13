"""Real process cancellation and loopback preview tests with synthetic content."""
from pathlib import Path
import json, os, signal, subprocess, sys, tempfile, time, unittest
import urllib.error, urllib.request
from unittest.mock import patch
import xml.etree.ElementTree as ET

WORKER=Path(__file__).resolve().parents[1]/'Resources/Tectonicus/worker.py'
sys.path.insert(0, str(WORKER.parent))
import worker

class WorkerTests(unittest.TestCase):
    def test_perspective_config_result_and_portable_framing(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);source=root/'source';source.mkdir();output=root/'render'
            manifest=dict(bounds=[-32,-16,31,47],source_sha256={},chunks=24,placeholders=0,limitations=[])
            def export(*args):
                (output/'world').mkdir()
                (output/'world/export-manifest.json').write_text(json.dumps(manifest))
                return manifest
            def render(*args,**kwargs):
                (output/'map').mkdir()
                (output/'map/map.html').write_text('<body>synthetic map</body>')
                return 'Render complete'
            with patch('worker.toolchain',return_value=(root,root/'java')), patch('exporter.export_world',side_effect=export), patch('worker.run',side_effect=render):
                worker.render(root,source,output,0,64,'Synthetic',135,30)
            config=ET.parse(output/'tectonicus.xml').find('map')
            self.assertEqual(config.get('cameraAngle'),'135')
            self.assertEqual(config.get('cameraElevation'),'30')
            result=json.loads((output/'result.json').read_text())
            self.assertEqual((result['camera_angle'],result['camera_elevation']),(135,30))
            page=(output/'map/map.html').read_bytes()
            self.assertIn(b'[-32, -16, 31, 47]',page)
            self.assertEqual(worker.viewer_html(output/'map'),page)

    def test_cancellation_reaps_child(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);pidfile=root/'pid';progress=root/'progress.json'
            child="import os,time;from pathlib import Path;Path("+repr(str(pidfile))+").write_text(str(os.getpid()));time.sleep(60)"
            script="import sys,signal;from pathlib import Path;sys.path.insert(0,"+repr(str(WORKER.parent))+");import worker;worker.PROGRESS=Path("+repr(str(progress))+");signal.signal(signal.SIGTERM,worker.cancel);worker.run([sys.executable,'-c',"+repr(child)+"])"
            p=subprocess.Popen([sys.executable,'-c',script],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            try:
                deadline=time.monotonic()+10
                while not pidfile.exists() and time.monotonic()<deadline:time.sleep(.05)
                self.assertTrue(pidfile.exists())
                childpid=int(pidfile.read_text());p.terminate();p.wait(timeout=10)
                self.assertNotEqual(p.returncode,0)
                with self.assertRaises(ProcessLookupError):os.kill(childpid,0)
            finally:
                if p.poll() is None:p.kill();p.wait()

    def test_preview_scope_and_shutdown(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);site=root/'map';site.mkdir()
            (site/'map.html').write_text('<h1>Synthetic map</h1>')
            (root/'private.txt').write_text('not served')
            (site/'outside.txt').symlink_to(root/'private.txt')
            progress=root/'progress.json'
            p=subprocess.Popen([sys.executable,str(WORKER),'serve','--support',str(root),'--source',str(site),'--progress',str(progress),'--parent',str(os.getpid())],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            try:
                deadline=time.monotonic()+10
                while not progress.exists() and time.monotonic()<deadline:time.sleep(.05)
                state=json.loads(progress.read_text());self.assertEqual(state['phase'],'serving')
                base='http://127.0.0.1:'+state['detail']
                self.assertIn(b'Synthetic map',urllib.request.urlopen(base+'/map.html').read())
                for path in ['/outside.txt','/../private.txt','/']:
                    with self.assertRaises(urllib.error.HTTPError):urllib.request.urlopen(base+path)
                p.terminate();p.wait(timeout=10)
                with self.assertRaises(urllib.error.URLError):urllib.request.urlopen(base+'/map.html',timeout=2)
            finally:
                if p.poll() is None:p.kill();p.wait()

    def test_missing_resource_consent(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);progress=root/'p.json'
            p=subprocess.run([sys.executable,str(WORKER),'setup','--support',str(root/'tools'),'--progress',str(progress)],capture_output=True)
            self.assertNotEqual(p.returncode,0)
            self.assertIn('consent',json.loads(progress.read_text())['detail'])
            self.assertFalse((root/'tools').exists())

if __name__=='__main__':unittest.main()
