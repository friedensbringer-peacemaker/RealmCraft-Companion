"""Validate synthetic preview geometry against the authoritative 2D guide catalog."""
import json
import re
import sys
from pathlib import Path
root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / 'Resources'
catalog = json.loads((root / 'BuildGuides.json').read_text())
models = json.loads((root / 'BuildGuideVoxels.json').read_text())
assert set(models) == {g['id'] for g in catalog['guides']}
def value(world, plane, row, column):
    axes = [plane['columnAxis'].lower(), plane['rowAxis'].lower()]
    q = {axes[0]: int(column), axes[1]: int(row)}
    missing = next(a for a in 'xyz' if a not in axes)
    if plane['id'] == 'front':
        candidates = [(z, k) for (x, y, z), k in world.items() if x == q['x'] and y == q['y'] and k != '.']
        return min(candidates)[1] if candidates else '.'
    match = re.search(r'\b' + missing + r'\s*=\s*([−-]?\d+)', plane['title']['en'], re.I)
    assert match, plane['title']
    q[missing] = int(match.group(1).replace('−', '-'))
    return world.get((q['x'], q['y'], q['z']), '.')
for guide in catalog['guides']:
    model = models[guide['id']]
    assert len(model['stages']) == len(guide['steps'])
    for i, frame in enumerate(model['stages']):
        assert len(frame) <= 30_000
        assert len({tuple(v[:3]) for v in frame}) == len(frame)
        assert all(v[3] in catalog['blocks'] and all(isinstance(c, int) and abs(c) <= 128 for c in v[:3]) for v in frame)
        if not model['complete']:
            continue
        world = {tuple(v[:3]): v[3] for v in frame}
        planes = [guide['instructionStages'][i][k] for k in ['top', 'side']]
        if i == len(model['stages']) - 1:
            planes += [p for p in guide['planes'] if re.fullmatch(r'layer-?\d+', p['id'])]
        for plane in planes:
            for ri, row in enumerate(plane['rows']):
                for ci, col in enumerate(plane['columns']):
                    expected = plane['cells'][ri][ci]
                    assert value(world, plane, row, col) == expected, (guide['id'], i, plane['id'], row, col, expected)
print('PASS all preview IDs, stage counts, coordinates and unique cells')
print('PASS complete previews match every staged top/side projection and final physical layer')
