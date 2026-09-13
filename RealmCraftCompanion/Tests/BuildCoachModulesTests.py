import json
from pathlib import Path
from collections import Counter
r=Path(__file__).resolve().parents[1]/'Resources'
c=json.loads((r/'BuildGuides.json').read_text());m=json.loads((r/'BuildGuideVoxels.json').read_text())
new=[g for g in c['guides'] if g['id'].startswith('coach_')]
assert len(new)==4
for g in new:
 frames=m[g['id']]['stages'];assert frames[0]==[] and frames[-1]==frames[-2]
 old=set()
 for i,frame in enumerate(frames):
  now={tuple(v) for v in frame};added=now-old
  assert old <= now
  if i not in (0,len(frames)-1):
   assert 1<=len(added)<=5
   assert len({(y,z,k) for x,y,z,k in added})==1
   xs=sorted(v[0] for v in added);assert xs==list(range(xs[0],xs[-1]+1))
   assert f'Take {len(added)} ×' in g['steps'][i]['en']
  old=now
 counts=Counter(v[3] for v in frames[-1])
 actual={c['blocks'][k]['name']['en']:n for k,n in counts.items()}
 listed={entry['name']['en']:int(entry['count']['en']) for entry in g['materials']}
 assert actual==listed
 for x,y,z,k in frames[-1]:
  if y>0: assert any((x+dx,y+dy,z+dz) in {tuple(v[:3]) for v in frames[-1]} for dx,dy,dz in [(0,-1,0),(1,0,0),(-1,0,0),(0,0,1),(0,0,-1)])
print('PASS four original modules: <=5-block contiguous actions, quantities and connected geometry')
