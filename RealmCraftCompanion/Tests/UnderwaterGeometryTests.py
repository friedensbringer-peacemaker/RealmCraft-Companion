from pathlib import Path
import json,collections
import sys
p=Path(sys.argv[1]);d=json.loads(p.read_text());gs={g['id']:g for g in d['guides']}
def vox(g):
 return {(int(x),int(pl['id'][5:]),int(z)):k for pl in g['planes'] if pl['id'].startswith('layer') for z,row in zip(pl['rows'],pl['cells']) for x,k in zip(pl['columns'],row) if k!='.'}
N=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]
def adj(q):return [tuple(q[i]+n[i] for i in range(3)) for n in N]
def reachable(start,allowed):
 seen={start};queue=collections.deque([start])
 while queue:
  for q in adj(queue.popleft()):
   if q in allowed and q not in seen:seen.add(q);queue.append(q)
 return seen
for key in ['uw_dome','uw_pyramid']:
 world=vox(gs[key]);bounds={(x,y,z) for x in range(-1,12) for z in range(-1,12) for y in range(-1,10)};outside=reachable((-1,-1,-1),bounds-set(world));inside=bounds-outside-set(world)
 assert len(inside)==int(gs[key]['materials'][-1]['count']['en']),(key,len(inside))
 assert reachable((5,1,5),inside)==inside,'disconnected interior'
 for part,offset in [('uw_tunnel',(3,0,10)),('uw_shaft',(3,0,18))]:
  for q,v in vox(gs[part]).items():world[tuple(q[i]+offset[i] for i in range(3))]=v
 # Remove shared plugs only, ladder is not full solid for water calculation.
 solids={q for q,k in world.items() if k not in ['uw_plug','uw_ladder_back']}
 bounds={(x,y,z) for x in range(-1,12) for z in range(-1,24) for y in range(-1,7)}
 water=reachable((-1,-1,-1),bounds-solids)
 assert not (inside & water),'flooded habitat'
 assert (5,1,21) not in water,'flooded shaft'
 walk={(x,1,z) for x in range(11) for z in range(23) if (x,0,z) in solids and (x,1,z) not in solids and (x,2,z) not in solids}
 assert (5,1,20) in reachable((5,1,5),walk),'no walkable connection'
 print(key,'sealed shell; connected',len(inside),'interior cells; dry assembled tunnel/shaft; walkable route')
s=vox(gs['uw_shaft'])
for (x,y,z),v in s.items():
 if v=='uw_ladder_back':assert s.get((x,y,z+1))=='uw_stone'
assert s[(2,7,1)]=='uw_stone' and (2,8,1) not in s and (2,9,1) not in s
print('Shaft: 8 supported ladders and two-block-clear upper landing')
for g in d['guides'][-7:]:
 counts=collections.Counter(vox(g).values())
 for k,count in counts.items():
  if k not in ['W','uw_ladder_back']:
   name=d['blocks'][k]['name']['en']; m=next(m for m in g['materials'] if m['name']['en']==name);assert int(m['count']['en'])==count
print('All new permanent material quantities match physical layer grids')
