"""Validate and assemble the static demo using only explicitly selected public files."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
FILES = ['index.html', 'style.css', 'core.js', 'app.js',
         'data/BuildGuides.json', 'data/ConversationRecipes.json']

def main():
    guides = json.loads((ROOT/'data/BuildGuides.json').read_text())
    recipes = json.loads((ROOT/'data/ConversationRecipes.json').read_text())
    assert len({g['id'] for g in guides['guides']}) == len(guides['guides'])
    for g in guides['guides']:
        assert g['steps'] and len(g['instructionStages']) == len(g['steps'])
        for key in ('title', 'summary', 'footprint', 'evidence', 'success', 'troubleshooting'):
            assert g[key]['de']
        for stage in g['instructionStages']:
            for side in ('top', 'side'):
                plane = stage[side]
                assert len(plane['cells']) == len(plane['rows'])
                assert all(len(row) == len(plane['columns']) for row in plane['cells'])
                assert all(cell in guides['blocks'] for row in plane['cells'] for cell in row)
                for pos in stage[side+'New']:
                    r, c = map(int, pos.split(':'))
                    assert 0 <= r < len(plane['rows']) and 0 <= c < len(plane['columns'])
        assert all(s['url'].startswith('https://') for s in g['sources'])
    for r in recipes:
        assert r['source']['url'].startswith('https://')
        assert all(r[key]['de'] for key in ('title', 'materials', 'steps', 'evidence'))
    destination = ROOT/'dist'
    destination.mkdir(exist_ok=True)
    unexpected = {p.relative_to(destination).as_posix() for p in destination.rglob('*') if p.is_file()} - set(FILES) - {'asset-manifest.json'}
    if unexpected:
        raise ValueError('Unexpected build output; use a new, clean output directory.')
    for name in FILES:
        target = destination/name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT/name, target)
    manifest = {name: hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in FILES}
    (destination/'asset-manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print(f'Static build ready: {len(FILES)} files; {len(guides["guides"])} guides and {len(recipes)} recipes validated.')

if __name__ == '__main__':
    main()
