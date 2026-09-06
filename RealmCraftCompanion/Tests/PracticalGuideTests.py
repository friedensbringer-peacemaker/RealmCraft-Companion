"""Synthetic geometry checks; no claim of RealmCraft gameplay verification."""
import json,sys
from pathlib import Path
from collections import Counter,deque
d=json.loads(Path(sys.argv[1]).read_text());gs={g['id']:g for g in d['guides']}
def vox(g):return {(int(x),int(p['id'][5:]),int(z)):k for p in g['planes'] if p['id'].startswith('layer') for z,row in zip(p['rows'],p['cells']) for x,k in zip(p['columns'],row) if k!='.'}
def reach(start,allowed):
 seen={start};queue=deque([start])
 while queue:
  x,y,z=queue.popleft()
  for p in [(x+1,y,z),(x-1,y,z),(x,y+1,z),(x,y-1,z),(x,y,z+1),(x,y,z-1)]:
   if p in allowed and p not in seen:seen.add(p);queue.append(p)
 return seen
for key in ['pr_tunnel_corner','pr_tunnel_rise','pr_panorama_gallery']:
 w=vox(gs[key]);domain={(x,y,z) for x in range(-1,17) for y in range(-1,8) for z in range(-1,13)};outside=reach((-1,-1,-1),domain-set(w));inside=domain-outside-set(w)
 assert inside and reach(next(iter(inside)),inside)==inside
 fixtures=sum(v in ['tree_plank','grass','decor_fern','ex_stair_pz'] for v in w.values())
 if key=='pr_tunnel_rise':fixtures+=sum(v=='uw_stone' and y in [1,2] and x in [1,2,3] and z in range(4,10) for (x,y,z),v in w.items())
 assert len(inside)+fixtures==int(gs[key]['materials'][-1]['count']['en']),(key,len(inside),fixtures)
 print('PASS closed, connected dry volume and displacement count:',key)
w=vox(gs['pr_tunnel_corner']);w={p:k for p,k in w.items() if k!='uw_plug'}
walk={(x,1,z) for x in range(11) for z in range(11) if (x,0,z) in w and (x,1,z) not in w and (x,2,z) not in w}
assert (10,1,8) in reach((2,1,0),walk)
w=vox(gs['pr_tunnel_rise']);w={p:k for p,k in w.items() if k!='uw_plug'}
route=[(2,0,z) for z in range(4)]+[(2,1,4),(2,2,5)]+[(2,2,z) for z in range(6,11)]
for x,y,z in route:
 assert w.get((x,y,z)) in ['uw_stone','uw_glass','ex_stair_pz']
 assert (x,y+1,z) not in w and (x,y+2,z) not in w
 assert w.get((x,y-1,z))=='uw_stone' if w[x,y,z]=='ex_stair_pz' else True
print('PASS tunnel corner route and two-level ascending passage')
w=vox(gs['pr_mine_entrance'])
for x in [3,4,5]:
 for z in range(2,8):
  y=2-z;assert w.get((x,y,z))=='ex_stair_nz';assert w.get((x,y-1,z))=='uw_stone'
  assert all((x,y+h,z) not in w for h in [1,2,3])
assert w[(4,0,1)]=='uw_stone' and w[(4,-6,8)]=='uw_stone'
print('PASS supported three-wide descending stair and headroom')
for key,g in gs.items():
 if not key.startswith('pr_'):continue
 w=vox(g)
 for (x,y,z),k in w.items():
  if k=='pr_chest':assert (x,y+1,z) not in w,(key,'blocked chest lid')
  if k=='pr_head':assert w.get((x,y,z-1))=='pr_bed'
  if k=='pr_bed':assert w.get((x,y,z+1))=='pr_head'
  if k.startswith('decor_'):assert w.get((x,y-1,z))=='grass'
 counts=Counter(v for v in w.values() if v not in ['pr_head','build_upper'])
 assert sorted(int(m['count']['en']) for m in g['materials'][:len(counts)])==sorted(counts.values()),key
 assert len(g['instructionStages'])==len(g['steps'])
 # Exterior projects nearest physical block at each coordinate, including automatic halves.
 front=next(p for p in g['planes'] if p['id']=='front')
 for y,row in zip(front['rows'],front['cells']):
  for x,k in zip(front['columns'],row):assert k==next((w[int(x),int(y),z] for z in range(30) if (int(x),int(y),z) in w),'.')
print('PASS materials, bed halves, chest lids, planted soil and exterior views for 16 modules')
# Pen fence network: use occupied boundary cells as barriers in plan.
w=vox(gs['pr_animal_shelters']);plane={(x,z) for x,y,z in w if y==1}
for center in [(2,1,4),(6,1,4),(10,1,4)]:
 walk={(x,1,z) for x in range(-1,14) for z in range(-1,10) if (x,z) not in plane}
 cells=reach(center,walk);assert all(0<x<12 and 3<z<8 for x,y,z in cells)
print('PASS three separately enclosed pen footprints with closed gates')
