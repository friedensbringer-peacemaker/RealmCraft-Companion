"""Local points of interest from decoded vertical columns, including underground.
Building suggestions are 32x32x16 spatial cells with >=2 indicator categories;
they are clues, not proof of a generated village or a user-built house.
"""
from collections import defaultdict
import struct
from .palette import NAMES

def kind(name):
    if name in ('chest','trapped_chest','ender_chest'):return 'chest'
    if name.endswith('_bed'):return 'bed'
    if name in ('crafting_table',):return 'workbench'
    if name in ('furnace','blast_furnace','smoker'):return 'furnace'
    if 'glass' in name:return 'glass'
    return None
KINDS={i:k for i,n in NAMES.items() if (k:=kind(n))}

def points_for_columns(data,x,z):
    offsets=struct.unpack_from('<257I',data);out=[];glass=defaultdict(lambda:[0,0,0,0])
    for column in range(256):
        cx=x+column%16;cz=z+column//16
        for run in range(offsets[column],offsets[column+1]):
            start,identity=struct.unpack_from('<BH',data,1028+run*3);k=KINDS.get(identity)
            if not k:continue
            end=struct.unpack_from('<B',data,1028+(run+1)*3)[0] if run+1<offsets[column+1] else 256
            if k=='glass':
                for cy in range(start,end):
                    g=glass[cy//16];g[0]+=cx;g[1]+=cy;g[2]+=cz;g[3]+=1
            else:
                for cy in range(start,end):out.append({'kind':k,'x':cx,'y':cy,'z':cz,'count':1})
    for g in glass.values():
        n=g[3];out.append({'kind':'glass','x':round(g[0]/n),'y':round(g[1]/n),'z':round(g[2]/n),'count':n})
    return out

def finalize(points,prefix):
    cells=defaultdict(list)
    for p in points:cells[(p['x']//32,p['y']//16,p['z']//32)].append(p)
    buildings=[]
    for cell,entries in cells.items():
        categories={p['kind'] for p in entries}
        if len(categories)<2:continue
        counts={k:sum(p['count']for p in entries if p['kind']==k)for k in sorted(categories)}
        anchors=[p for p in entries if p['kind']!='glass'];n=len(anchors)
        buildings.append({'kind':'building','x':round(sum(p['x']for p in anchors)/n),'y':round(sum(p['y']for p in anchors)/n),'z':round(sum(p['z']for p in anchors)/n),'count':sum(counts.values()),'clues':counts})
    combined=sorted(points+buildings,key=lambda p:(p['kind'],p['x'],p['z'],p['y']))
    for p in combined:p['id']=f"{prefix}:{p['kind']}:{p['x']},{p['y']},{p['z']}"
    return combined
