"""Synthetic layout checks; furniture shapes do not establish gameplay functions."""
import json,sys
from collections import Counter
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text());gs={g['id']:g for g in d['guides']}
def vox(g):return {(int(x),int(p['id'][5:]),int(z)):k for p in g['planes'] if p['id'].startswith('layer') for z,row in zip(p['rows'],p['cells']) for x,k in zip(p['columns'],row) if k!='.'}
for key,g in gs.items():
 if not key.startswith('arch_'):continue
 w=vox(g)
 for (x,y,z),k in w.items():
  if k=='pr_chest':assert (x,y+1,z) not in w,(key,'blocked chest lid')
  if k=='pr_bed':assert w.get((x,y,z+1))=='pr_head'
  if k=='pr_head':assert w.get((x,y,z-1))=='pr_bed'
  if k=='ar_lantern':assert w.get((x,y-1,z))=='tree_plank',(key,'unsupported standing lantern')
  if k=='ar_hang':assert w.get((x,y+1,z))=='tree_support' and y>=4
  if k=='ar_carpet':assert w.get((x,y-1,z)) in ['tree_plank','ar_quartz']
  if k.startswith('decor_'):assert w.get((x,y-1,z))=='grass'
 counts=Counter(v for v in w.values() if v not in ['pr_head','build_upper'])
 assert sorted(counts.values())==sorted(int(m['count']['en']) for m in g['materials'][:len(counts)]),key
 assert len(g['steps'])==len(g['instructionStages'])
 front=next(p for p in g['planes'] if p['id']=='front')
 for y,row in zip(front['rows'],front['cells']):
  for x,k in zip(front['columns'],row):assert k==next((w[int(x),int(y),z] for z in range(30) if (int(x),int(y),z) in w),'.')
print('PASS materials, chest lids, bed halves, lantern attachments, carpet support, plants and exterior views for 12 modules')
w=vox(gs['arch_gable_roof'])
for x in range(4):
 for z in range(7):assert w[x,4+x,z]=='ar_oak_px' and w[8-x,4+x,z]=='ar_oak_nx'
assert all(w[4,8,z]=='tree_plank' for z in range(7))
assert (4,1,0) not in w and (4,2,0) not in w
print('PASS mirrored roof slopes, continuous ridge and clear front opening')
for key,route in [('arch_living_room',[(x,1,3) for x in range(1,8)]),('arch_kitchen',[(x,1,3) for x in range(1,7)]),('arch_library',[(2,1,z) for z in range(1,8)]+[(6,1,z) for z in range(1,8)]),('arch_entry_hall',[(4,1,z) for z in range(7)])]:
 w=vox(gs[key])
 for x,y,z in route:assert w.get((x,y,z),'.') in ['.','ar_carpet'] and (x,y+1,z) not in w,(key,'blocked aisle')
print('PASS sofa, kitchen, library and entrance circulation')
