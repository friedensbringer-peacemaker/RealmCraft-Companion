"""Original, deterministic small builds. One placement row (at most five items) per step."""
from pathlib import Path
from collections import Counter
import json
ROOT=Path(__file__).resolve().parents[1]/'Resources'
catalog=json.loads((ROOT/'BuildGuides.json').read_text());models=json.loads((ROOT/'BuildGuideVoxels.json').read_text())
blocks=catalog['blocks']
def text(de,en):return dict(de=de,en=en)
def create(identifier,number,category,title,summary,w,d,world,check):
    height=max(y for x,y,z in world)
    def plane(state,y=None):
        if y is not None:
            rows=list(range(d));axis='z';name=text(f'Draufsicht · y={y}',f'Top view · y={y}');pid=f'layer{y}'
            cells=[[state.get((x,y,z),'.') for x in range(w)] for z in rows]
        else:
            rows=list(range(height,-1,-1));axis='y';name=text('Vorderansicht · Blick nach +z','Front elevation · looking along +z');pid='front'
            cells=[[next((state[(x,y,z)] for z in range(d) if (x,y,z) in state),'.') for x in range(w)] for y in rows]
        return dict(id=pid,title=name,note=text('Lokale Blockpositionen. Die Vorderansicht überlagert Tiefen; für die genaue Platzierung die Schicht verwenden.','Local block positions. The front elevation overlaps depths; use the layer for precise placement.'),columnAxis='x',rowAxis=axis,columns=list(map(str,range(w))),rows=list(map(str,rows)),cells=cells)
    remaining=sorted(world,key=lambda p:(p[1],p[2],p[0])); batches=[]
    while remaining:
        p=remaining.pop(0);batch=[p]
        while remaining and len(batch)<5 and remaining[0]==(batch[-1][0]+1,p[1],p[2]) and world[remaining[0]]==world[p]:batch.append(remaining.pop(0))
        batches.append(batch)
    state={};frames=[];steps=[];stages=[];first={}
    def push(de,en,y):
        steps.append(text(de,en));frames.append([[*p,k] for p,k in sorted(state.items())]);top=plane(state,y);side=plane(state)
        old=stages[-1] if stages else None
        def changed(p,prev):return [f'{ri}:{ci}' for ri,row in enumerate(p['cells']) for ci,k in enumerate(row) if k!='.' and (prev is None or prev['id']!=p['id'] or prev['cells'][ri][ci]!=k)]
        stages.append(dict(top=top,side=side,topNew=changed(top,old['top'] if old else None),sideNew=changed(side,old['side'] if old else None)))
    push(f'Bereite eine freie, ebene Fläche von {w} mal {d} Blöcken vor. Markiere die vordere linke Bodenecke als Nullpunkt: rechts ist x, hinten ist z, der Bodenblock liegt auf Höhe null. Bestätige den festen Baubezug, bevor du etwas setzt.',f'Prepare a clear level area {w} blocks wide and {d} blocks deep. Mark the front-left floor corner as zero: right is x, back is z, and the floor block is height zero. Confirm this fixed reference before placing anything.',0)
    for batch in batches:
        x,y,z=batch[0];k=world[batch[0]];n=len(batch)
        for p in batch:state[p]=k
        first.setdefault(k,len(steps)+1)
        orientation=text('','')
        if k=='ar_oak_pz':orientation=text(' Hohe Seite nach hinten; die Sitzfläche zeigt nach vorne.',' High side toward the back; the seat faces the front.')
        name=blocks[k]['name']
        push(f'Nimm {n} × {name["de"]}. Beginne vom Nullpunkt aus {x} Blöcke rechts und {z} Blöcke hinten, auf Höhe {y}. '+('Setze diesen einen Block.' if n==1 else f'Setze eine Reihe von {n} Blöcken nach rechts; die Startposition zählt mit.')+orientation['de'],f'Take {n} × {name["en"]}. From the origin, start {x} blocks right and {z} blocks back, at height {y}. '+('Place this single block.' if n==1 else f'Place a row of {n} blocks toward the right, including the starting position.')+orientation['en'],y)
    push(check['de']+' Melde dein Ergebnis; die Vorschau bestätigt keinen erfolgreichen Spieltest.',check['en']+' Report what you observe; the preview does not confirm a successful game test.',height)
    counts=Counter(world.values());keys=sorted(counts,key=lambda k:first[k])
    guide=dict(id=identifier,category=category,title=text(f'{number} · {title["de"]}',f'{number} · {title["en"]}'),summary=summary,footprint=text(f'{w} × {d} · Höhe {height+1} Blöcke',f'{w} × {d} · {height+1} blocks high'),
      mechanism=text('Eigenes kombinierbares Dekorationsmodul mit kurzen Ansagen. Keine zusätzliche Spielfunktion wird behauptet. Auf trockenem, tragfähigem Untergrund bauen; vorhandene Böden nur bei gleicher Höhe und gleichem Raster wiederverwenden.','Original combinable decoration module with short spoken actions. No extra game function is claimed. Build on dry supported ground; reuse floors only when height and grid match.'),
      evidence=text('Ungetestet · KI-generiert. Eigener Entwurf; keine übernommene Fremdanleitung. Blocknamen stammen aus dem Companion-Katalog. Mengen und Schichten werden aus derselben Geometrie erzeugt; Platzierung und Lichtwirkung müssen in RealmCraft geprüft werden.','Untested · AI-generated. Original design, not a copied third-party guide. Block names come from the Companion catalog. Counts and layers derive from the same geometry; placement and lighting require testing in RealmCraft.'),
      materials=[dict(count=text(str(counts[k]),str(counts[k])),name=blocks[k]['name']) for k in keys],materialFirstSteps=[first[k] for k in keys],planes=[plane(state,y) for y in range(height+1)]+[plane(state)],steps=steps,instructionStages=stages,success=check,
      troubleshooting=text('Bei verlorener Orientierung anhalten und zum markierten Nullpunkt zurückkehren. Vergleiche zuerst Bodenhöhe und Reihenlänge. Ein bestehendes Teil zählt nicht erneut als Material. Keine Dichtung, Monsterabwehr oder automatische Funktion annehmen.','If orientation is lost, stop and return to the marked origin. Compare floor height and row length first. An existing part is not another material item. Do not assume sealing, monster protection or automation.'),
      sources=[dict(title='RealmCraft VR · Official updates; not validation of this layout',url='https://steamcommunity.com/app/2943620/allnews/'),dict(title='WBuilds · visual step presentation inspiration, not this design',url='https://wbuilds.app/features/')])
    catalog['guides']=[g for g in catalog['guides'] if g['id']!=identifier]+[guide];models[identifier]=dict(complete=True,stages=frames)
def floor(w,d,k):return {(x,0,z):k for x in range(w) for z in range(d)}
a=floor(5,3,'tree_plank')
for x in [0,4]:
 for y in range(1,4):a[x,y,1]='tree_plank'
for x in range(5):a[x,4,1]='tree_plank'
create('coach_garden_arch',92,'decoration',text('Garten · Holzportal','Garden · timber arch'),text('Kleines Portal als Eingang zu Garten, Baumdorf oder Pergola.','Small gateway for a garden, tree village or pergola.'),5,3,a,text('Prüfe den mittleren Durchgang: drei Blöcke breit und drei Blöcke frei über dem Boden. Kombinierbar mit Guide 83 oder 93.','Check the central opening: three blocks wide and three blocks clear above the floor. Combine with guide 83 or 93.'))
a=floor(5,3,'uw_stone')
for x in range(1,4):a[x,1,2]='ar_oak_pz'
for x in [0,4]:a[x,1,2]='uw_stone';a[x,2,2]='ar_lantern'
create('coach_rest_bench',93,'interiors',text('Sitzplatz · Bank mit Seitenlicht','Seating · bench with side lights'),text('Drei dekorative Sitze mit freiem Vorplatz und zwei Leuchten.','Three decorative seats with a clear forecourt and two lights.'),5,3,a,text('Prüfe die Treppenausrichtung und den zwei Reihen tiefen Vorplatz. Die Bank ist Dekoration; Sitzen wird nicht vorausgesetzt.','Check stair direction and the forecourt two rows deep. The bench is decorative; sitting is not assumed.'))
a=floor(5,5,'ar_quartz')
for x in range(5):
 for z in range(5):
  if x in [0,4] or z in [0,4]:a[x,1,z]='ar_quartz'
a[2,1,2]='uw_stone';a[2,2,2]='uw_stone';a[2,3,2]='ar_lantern'
create('coach_light_court',94,'decoration',text('Platz · trockenes Lichtbecken','Courtyard · dry light basin'),text('Helles, symmetrisches Schmuckbecken mit zentraler Leuchte.','Bright symmetrical ornamental basin with a central light.'),5,5,a,text('Prüfe den geschlossenen Rand und acht freie Felder um die Mittelsäule auf Höhe eins. Das Becken bleibt trocken; kein Wasserumlauf wird behauptet.','Check the closed rim and eight empty cells around the central column at height one. Keep the basin dry; no water circulation is claimed.'))
a=floor(5,4,'ar_quartz')
for y in range(1,4):
 for x in range(5):
  for z in range(1,4):
   if x in [0,4] or z==3:a[x,y,z]='uw_glass'
for x in range(5):
 for z in range(4):a[x,4,z]='uw_glass'
create('coach_glass_alcove',95,'architecture',text('Pavillon · offene Glasnische','Pavilion · open glass alcove'),text('Moderne Aussichts-Nische als Anschluss an Wege und Sitzplätze.','Modern viewing alcove adjoining paths and seating modules.'),5,4,a,text('Prüfe die offene Front und den freien Innenraum. Dieser Pavillon ist nicht wasserdicht und kein geschlossenes Monster-Versteck.','Check the open front and clear interior. This pavilion is not watertight or an enclosed monster shelter.'))
(ROOT/'BuildGuides.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n');(ROOT/'BuildGuideVoxels.json').write_text(json.dumps(models,ensure_ascii=False,separators=(',',':'))+'\n')
print('Generated four original modules with exact one-row steps and shared 2D/3D data')
