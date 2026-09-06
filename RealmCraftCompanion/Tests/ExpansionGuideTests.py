"""Check synthetic expansion geometry, not RealmCraft gameplay physics."""
import json,sys
from collections import Counter,deque
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text());gs={g['id']:g for g in d['guides']}
def vox(g):return {(int(x),int(p['id'][5:]),int(z)):k for p in g['planes'] if p['id'].startswith('layer') for z,row in zip(p['rows'],p['cells']) for x,k in zip(p['columns'],row) if k!='.'}
N=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]
def reach(start,allowed):
 seen={start};q=deque([start])
 while q:
  a=q.popleft()
  for delta in N:
   b=tuple(a[i]+delta[i] for i in range(3))
   if b in allowed and b not in seen:seen.add(b);q.append(b)
 return seen
for key in ['exp_underwater_hub','exp_panorama_room']:
 w=vox(gs[key]);domain={(x,y,z) for x in range(-1,12) for z in range(-1,10) for y in range(-1,6)};outside=reach((-1,-1,-1),domain-set(w));interior=domain-set(w)-outside
 assert interior and (4,1,4) in interior
 # Furniture is installed after displacement; count it as part of the initial empty cavity.
 furnished=sum(v=='tree_plank' for v in w.values());assert len(interior)+furnished==int(gs[key]['materials'][-1]['count']['en'])
 assert reach((4,1,4),interior)==interior
 print('PASS enclosed, connected habitat:',key,len(interior),'free cells')
w=vox(gs['exp_underwater_hub']);openw={p:v for p,v in w.items() if v!='uw_plug'}
walk={(x,1,z) for x in range(9) for z in range(9) if (x,0,z) in openw and (x,1,z) not in openw and (x,2,z) not in openw}
assert {(4,1,0),(4,1,8),(0,1,4),(8,1,4)}<=reach((4,1,4),walk)
for key in ['exp_spiral_tower','exp_switchback','exp_crop_terraces','exp_station_hall']:
 w=vox(gs[key]);stairs={p:v for p,v in w.items() if v.startswith('ex_stair_')}
 for (x,y,z),v in stairs.items():
  assert w.get((x,y-1,z))=='uw_stone',(key,'missing support',(x,y,z))
  assert all((x,y+h,z) not in w for h in [1,2]),(key,'blocked headroom',(x,y,z))
 print('PASS supported stairs and headroom:',key,len(stairs))
w=vox(gs['exp_spiral_tower'])
route=[(2,0,1),(2,0,2),(3,1,2),(4,2,2),(5,3,2),(6,3,2),(6,4,3),(6,5,4),(6,6,5),(6,6,6),(5,7,6),(4,8,6),(3,9,6),(2,9,6),(2,10,5),(2,11,4),(2,12,3),(2,12,2),(2,12,1)]
for (x,y,z) in route:
 assert w.get((x,y,z)) in ['uw_stone','ex_stair_px','ex_stair_nx','ex_stair_pz','ex_stair_nz']
 assert (x,y+1,z) not in w and (x,y+2,z) not in w
for a,b in zip(route,route[1:]):assert abs(a[0]-b[0])+abs(a[2]-b[2])==1 and abs(a[1]-b[1])<=1
print('PASS continuous spiral route and clear upper exit')
w=vox(gs['exp_lighthouse'])
for (x,y,z),k in w.items():
 if k=='uw_ladder_back':assert w.get((x,y,z+1))=='uw_stone'
assert w.get((3,8,3))=='uw_stone' and (3,9,3) not in w and (3,10,3) not in w
w=vox(gs['exp_biosphere_garden']);dome=vox(gs['uw_dome'])
for (x,y,z),k in w.items():
 if y>0:assert (x+1,y,z+1) not in dome
 if k.startswith('decor_'):assert w.get((x,y-1,z))=='grass'
w=vox(gs['exp_crop_terraces'])
assert Counter(w.values())['ex_seed']==21
for (x,y,z),k in w.items():
 if k=='ex_seed':assert w.get((x,y-1,z))=='ex_soil'
 if k=='W':
  assert w.get((x,y-1,z))=='uw_stone'
  assert all(w.get((x+dx,y,z+dz)) in ['ex_soil','uw_stone'] for dx,dz in [(1,0),(-1,0),(0,1),(0,-1)])
print('PASS ladder backing, planted soil and contained irrigation wells')
for key,g in gs.items():
 if not key.startswith('exp_'):continue
 w=vox(g);front=next(p for p in g['planes'] if p['id']=='front')
 for y,row in zip(front['rows'],front['cells']):
  for x,k in zip(front['columns'],row):
   expected=next((w[int(x),int(y),z] for z in range(30) if (int(x),int(y),z) in w),'.');assert k==expected
 # Permanent material totals precede separately listed tools/reserves.
 counts=Counter(w.values());number_of_material_types=len(counts)
 assert sorted(int(m['count']['en']) for m in g['materials'][:number_of_material_types])==sorted(counts.values()),key
 assert len(g['instructionStages'])==len(g['steps'])
print('PASS all 10 exterior projections and permanent material counts')
