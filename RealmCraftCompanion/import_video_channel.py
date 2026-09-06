from pathlib import Path
import json,re,unicodedata,collections,datetime,argparse
parser=argparse.ArgumentParser(description="Build a local RealmCraft video catalog from public metadata and caption files; no network or media playback.")
parser.add_argument('--metadata',type=Path,required=True)
parser.add_argument('--channel',type=Path,required=True)
parser.add_argument('--shorts',type=Path,required=True)
parser.add_argument('--seed',type=Path,required=True)
parser.add_argument('--titles',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args(); root=args.metadata; out=args.output;out.mkdir(parents=True,exist_ok=True)
flat=json.loads(args.channel.read_text())['entries'];shorts=json.loads(args.shorts.read_text())['entries']
seed={x['videoID']:x for x in json.loads(args.seed.read_text()) if x.get('coverage','curated')=='curated'}
titles=dict(line.strip().split('\t',1) for line in args.titles.read_text().splitlines() if line.strip())
# Each dictionary entry maps a source topic to German search vocabulary. These are search aids, not assertions of mechanics.
TOPICS=[
('Reparatur und Erfahrung','Mending & experience','equipment',['mending','repair','xp','experience'],['reparatur','reparieren','erfahrung']),
('Verzauberungen','Enchanting','equipment',['enchant','enchanting','enchantment','fortune','silk touch','respiration'],['verzaubern','verzauberung','verzauberungen']),
('Bienen und Honig','Bees & honey','farms',['bee','bees','hive','hives','apiary','honey','honeycomb'],['bienen','biene','bienenstock','honig','honigwaben','bienennest']),
('Dorfbewohner und Handel','Villagers & trading','farms',['villager','villagers','trader','trading','librarian','librarians'],['dorfbewohner','handel','handeln','bibliothekar','handler']),
('Pflanzenfarmen','Crop & tree farms','farms',['farm','farming','farms','wheat','sugar cane','sugarcane','sapling','saplings','dark oak'],['farm','farmen','baumfarm','weizen','zuckerrohr','setzlinge','schwarzeiche']),
('Schildkröten','Turtles','survival',['turtle','turtles'],['schildkrote','schildkroten','eier','jungtiere']),
('Eisengolems','Iron golems','survival',['golem','golems'],['eisengolem','eisengolems']),
('Schweine reiten','Pig riding','survival',['pig riding','carrot on a stick'],['schweinereiten','schwein','schweine','karottenrute']),
('Loren und Schienen','Minecarts & tracks','transport',['minecart','minecarts','track','railway','rail','rails','railtrack','interchange'],['lore','loren','schienen','schiene','lorenstrecke','bahn']),
('Boote und Flöße','Boats & rafts','transport',['boat','boats','raft','rafts'],['boot','boote','floss','flosse']),
('Erzverarbeitung und Lager','Ore processing & storage','processing',['smelt','smelting','processing','storage'],['ofen','schmelzen','schmelzanlage','erzverarbeitung','lager','lagerung']),
('Steingenerator','Stone generator','processing',['generator','cobblestone'],['steingenerator','bruchstein','pflasterstein']),
('Redstone und Beleuchtung','Redstone & lighting','building',['redstone','light','lights','lighting','daylight','banner'],['redstone','beleuchtung','licht','tageslichtsensor','banner']),
('Unterwasserbau','Underwater builds','building',['underwater','submerged'],['unterwasser','unterwasserbau']),
('Yacht und Rumpf','Yacht & hull','building',['yacht','hull','bow'],['yacht','jacht','rumpf','bug']),
('Große Bauprojekte','Large building projects','building',['pyramid','pyramids','ufo','uap'],['pyramide','pyramiden','ufo']),
('Gelände und Wege','Landscaping & paths','building',['landscaping','terraforming','landscape','path','paths','footbridge','footbridges','walkway','footpaths'],['gelande','landschaft','wege','weg','brucken','terraforming']),
('Sichere Lager und Zäune','Safe camps & fences','building',['fence','fencing','safety','enclosure','enclosed','hut','corridor'],['zaun','zaune','schutz','sicherheit','lager','gehege']),
('Angeln und See','Fishing & lakes','building',['fishing','lake','pool'],['angeln','angelsee','see','teich']),
('Korallen und Wasserpflanzen','Coral & aquatic plants','building',['coral','corals','sea pickles','kelp','vegetation'],['korallen','seegurken','seetang','kelp','wasserpflanzen']),
('Nether','Nether','exploration',['nether','bastion','ghast','fortress','warped','crimson'],['nether','bastion','netherfestung','wirrwald','karmesinwald','ghast']),
('TNT und Antiker Schrott','TNT & ancient debris','exploration',['tnt','ancient debris','gunpowder'],['tnt','antiker','schrott','netherit','schiesspulver']),
('Bergbau und Rohstoffe','Mining & resources','exploration',['diamond','diamonds','ore','ores','mining'],['diamant','diamanten','erze','erz','bergbau','abbau']),
('Amethystgeoden','Amethyst geodes','exploration',['amethyst','geode'],['amethyst','amethystgeode','geode']),
('Biom-Erkundung','Biome exploration','exploration',['biome','savanna','ice spike','woodland mansion','shipwreck','outpost'],['biom','erkundung','savanne','eisstachel','waldanwesen','schiffswrack','aussenposten']),
('Inventar und Gegenstände','Inventory & items','survival',['inventory','hotbar','drop items','item frames','signs'],['inventar','gegenstande','schnellzugriffsleiste','fallenlassen','rahmen','schilder']),
('Überleben und Kreaturen','Survival & creatures','survival',['survival','beginner','beginners','mob','mobs','skeleton','skeletons','slime','wolves','wolf','chicken','chickens','sheep','bunny','witch'],['uberleben','anfanger','kreaturen','mobs','skelette','schleim','wolfe','huhner','schafe']),
('Karten und Technik','Maps & technology','other',['mapping','virtual desktop','recording','pico 4'],['karte','karten','technik','aufzeichnung'])]
EXTRA={'sugarcane':['zuckerrohr'],'mine cart':['lore','loren'],'enchant':['verzaubern'],'enchanting':['verzaubern'],'enchantment':['verzauberung'],'enchantments':['verzauberungen'],'enchanted':['verzaubert'],'frost walker':['eislaufer'],'paper':['papier'],'experience':['erfahrung'],'xp':['erfahrung'],'fortress':['festung','netherfestung'],'breeding':['zucht','zuchten'],'breed':['zuchten'],'bookshelf':['bucherregal'],'bookshelves':['bucherregale'],'book':['buch'],'books':['bucher'],'pickaxe':['spitzhacke'],'axe':['axt'],'sword':['schwert'],'armour':['rustung'],'armor':['rustung'],'helmet':['helm'],'boots':['stiefel'],'leggings':['hose'],'chestplate':['brustpanzer'],'unbreaking':['haltbarkeit'],'water breathing':['wasseratmung'],'ice':['eis'],'ice spike':['eisstachel'],'dirt':['erde'],'stone':['stein'],'woodland mansion':['waldanwesen'],'shipwreck':['schiffswrack'],'seed':['samen','seed'],'seeds':['samen'],'carrot':['karotte'],'carrots':['karotten'],'potato':['kartoffel'],'potatoes':['kartoffeln'],'pumpkin':['kurbis'],'melon':['melone'],'oak':['eiche'],'dark oak':['schwarzeiche'],'spruce':['fichte'],'jungle':['dschungel'],'bamboo':['bambus'],'furnace':['ofen'],'furnaces':['ofen'],'torch':['fackel'],'torches':['fackeln'],'bee':['biene'],'bees':['bienen'],'hive':['bienenstock'],'hives':['bienenstocke'],'apiary':['bienenstand'],'villager':['dorfbewohner'],'villagers':['dorfbewohner'],'trading':['handel','handeln'],'trader':['handler'],'librarian':['bibliothekar'],'librarians':['bibliothekare'],'farm':['farm'],'wheat':['weizen'],'sapling':['setzling'],'saplings':['setzlinge'],'turtle':['schildkrote'],'turtles':['schildkroten'],'golem':['golem','eisengolem'],'minecart':['lore','loren'],'minecarts':['loren'],'railway':['bahn','lorenstrecke'],'smelting':['schmelzen','schmelzanlage'],'storage':['lager','lagerung'],'generator':['generator','steingenerator'],'cobblestone':['bruchstein','pflasterstein'],'daylight':['tageslicht'],'underwater':['unterwasser'],'hull':['rumpf'],'pyramid':['pyramide'],'pyramids':['pyramiden'],'landscaping':['landschaft','gelande'],'path':['weg'],'paths':['wege'],'fence':['zaun'],'fences':['zaune'],'fishing':['angeln'],'lake':['see'],'pool':['teich'],'coral':['korallen'],'sea pickles':['seegurken'],'ancient debris':['antiker','schrott'],'diamond':['diamant'],'diamonds':['diamanten'],'ore':['erz'],'ores':['erze'],'mining':['bergbau','abbau'],'inventory':['inventar'],'hotbar':['schnellzugriffsleiste'],'skeleton':['skelett'],'slime':['schleim'],'wolf':['wolf'],'wolves':['wolfe'],'chicken':['huhn'],'chickens':['huhner'],'sheep':['schaf','schafe'],'silk touch':['behutsamkeit'],'fortune':['gluck'],'respiration':['atmung'],'mending':['reparatur'],'emerald':['smaragd'],'emeralds':['smaragde'],'lava':['lava'],'water':['wasser'],'iron':['eisen'],'gold':['gold'],'quartz':['quarz'],'glowstone':['leuchtstein'],'magma':['magma'],'stairs':['treppe','treppen'],'powered':['antrieb','angetrieben'],'button':['knopf'],'lever':['hebel'],'chest':['truhe','kiste'],'hopper':['trichter'],'sugar cane':['zuckerrohr'],'campfire':['lagerfeuer'],'shears':['schere'],'honeycomb':['honigwaben'],'honey':['honig'],'egg':['ei'],'eggs':['eier'],'cow':['kuh'],'milk':['milch'],'cake':['kuchen'],'pig':['schwein'],'pigs':['schweine'],'sand':['sand'],'glass':['glas'],'wood':['holz'],'bed':['bett'],'beds':['betten'],'spawn':['spawnpunkt'],'boat':['boot'],'rail':['schiene'],'rails':['schienen'],'track':['strecke'],'nest':['nest'],'night':['nacht']}
def words(text):
 text=''.join(c for c in unicodedata.normalize('NFKD',text.lower()) if not unicodedata.combining(c))
 return re.findall(r'[^\W_]+',text,flags=re.UNICODE)
def contains(text,phrase): return ' '+ ' '.join(words(phrase))+' ' in ' '+' '.join(words(text))+' '
def enrich(text):
 terms=set(words(text));normalized=' '+' '.join(words(text))+' '
 for phrase,aliases in EXTRA.items():
  if ' '+phrase+' ' in normalized:terms.update(aliases)
 return sorted(terms)
def index_for(id,duration):
 buckets=collections.defaultdict(list);langs=[]
 for lang in ['en-orig','en','de']:
  p=root/(id+'.'+lang+'.json3')
  if not p.exists():continue
  if lang=='en' and 'en-orig' in langs:continue
  try:data=json.loads(p.read_text())
  except ValueError:continue
  langs.append(lang)
  for event in data.get('events',[]):
   text=re.sub(r'\[[^]]*\]', '', ''.join(s.get('utf8','') for s in event.get('segs',[]))).strip()
   t=int(event.get('tStartMs',0)/1000)
   if text and t<duration:buckets[t//30*30].append(text)
 return [{'seconds':k,'terms':enrich(' '.join(v))} for k,v in sorted(buckets.items()) if enrich(' '.join(v))],langs
all_entries=[];audit=[]
for short,entries in [(False,flat),(True,shorts)]:
 for entry in entries:
  id=entry['id'];title=entry['title'];p=root/(id+'.info.json')
  info=json.loads(p.read_text()) if p.exists() else {}
  description=info.get('description','')
  realm=any(t in title.lower() for t in ['realmcraft','reamlcraft','realm craft']) or any(t in description.lower() for t in ['realmcraft','realmcraftvr'])
  if not realm:
   audit.append({'id':id,'title':title,'included':False,'reason':'Other game or not yet confirmed','hasMetadata':bool(info)});continue
  duration=int(info.get('duration') or entry.get('duration') or 0)
  if not duration:
   audit.append({'id':id,'title':title,'included':False,'reason':'Duration pending','hasMetadata':bool(info)});continue
  index,langs=index_for(id,duration)
  no_speech="no commentary" in title.lower()
  if no_speech:index=[];langs=[]
  topics=[x for x in TOPICS if any(contains(title,t) for t in x[3])]
  category=topics[0][2] if topics else 'other'
  pub=info.get('upload_date'); published=datetime.datetime.strptime(pub,'%Y%m%d').strftime('%Y-%m-%d') if pub else '–'
  if id in seed:
   record=dict(seed[id]);record['duration']=duration;record['coverage']='curated'
  else:
   assert id in titles,(id,title)
   de=titles[id]
   ep=re.search(r'(?:Ep(?:isode)?\.?\s*#?)(\d+)',title,re.I)
   if ep:de+=' · Folge '+ep.group(1)
   subtitle={'de':'Themeneintrag zum Originalvideo: '+(', '.join(x[0] for x in topics) or de)+'.','en':'Topic entry for the original video: '+(', '.join(x[1] for x in topics) or title)+'.'}
   record={'id':'tarant-'+id,'videoID':id,'originalTitle':title,'channel':'TarantNET Gaming','published':published,'duration':duration,'category':category,'title':{'de':de,'en':title},'summary':subtitle,'aliases':[de,title]+[w for w in enrich(title) if len(w)>2 and w not in {'the','this','that','and','with','from','into','for','our','you','more','new','now','first','another','just','complete','completed','video','tutorial','game','how','some','little','one','two','realmcraft','episode','part','pcvr'}],'prerequisites':{'de':'Materialmengen und Voraussetzungen sind für diesen Themeneintrag nicht geprüft.','en':'Material quantities and prerequisites have not been verified for this topic entry.'},'limitations':{'de':'Themeneintrag, keine vollständig ausgearbeitete Bauanleitung. Untertiteltreffer sind automatisch zugeordnet und können Erkennungsfehler enthalten. Maße, Mengen und Funktion auf Quest sind nicht geprüft.','en':'Topic entry, not a fully edited build guide. Caption matches are automatic and may contain recognition errors. Dimensions, quantities and Quest behavior have not been verified.'},'visualReview':{'de':'Für diesen Kanaleintrag wurde keine individuelle Bildprüfung durchgeführt.','en':'No individual visual review was performed for this channel entry.'},'steps':[],'relatedSources':[],'coverage':'transcript' if index else 'metadata'}
   if not index:
    available=bool(info.get('automatic_captions') or info.get('subtitles'))
    message='Untertitel sind gelistet, konnten in diesem Durchlauf aber nicht abgerufen werden.' if available else ('Kein nutzbares englisches Transkript vom Anbieter gelistet.' if info else 'Transkript-Verfügbarkeit noch nicht bestätigt.')
    if langs:message='Die geladenen Untertitel enthalten nur Musikhinweise und keinen durchsuchbaren gesprochenen Inhalt.'
    record['limitations']['de']+=' '+message
    record['limitations']['en']+=' '+('Downloaded captions contain only music labels and no searchable speech.' if langs else 'Captions are listed but could not be retrieved in this run.' if available else ('No usable English transcript listed by the provider.' if info else 'Transcript availability has not been confirmed.'))
  detected=[]
  if index:
   for topic in TOPICS:
    count=sum(any(set(words(trigger)).issubset(set(window['terms'])) for trigger in topic[3]) for window in index)
    if count >= (1 if short else 2): detected.append((count,topic))
   detected.sort(key=lambda pair:pair[0],reverse=True)
   transcript_topics=[topic for _,topic in detected[:6]]
   summary_topics=(topics[:2]+[topic for topic in transcript_topics if topic not in topics[:2]])[:6]
   if id not in seed and transcript_topics:
    record['summary']={'de':'Suchthemen aus Titel und Untertiteln: '+', '.join(x[0] for x in summary_topics)+'. Automatisch zugeordnet; suche nach einem Begriff für passende Videostellen.','en':'Search topics from title and captions: '+', '.join(x[1] for x in summary_topics)+'. Automatically assigned; search a term for matching video moments.'}
   topics=topics+[topic for topic in transcript_topics if topic not in topics]
  if no_speech:
   record['limitations']={'de':'Laut Titel ein Zeitraffer ohne gesprochenen Kommentar. Automatisch erkannte Musikfragmente wurden nicht als Anleitung indexiert. Für den Aufbau bitte das Originalvideo ansehen; Maße und Quest-Funktion sind nicht geprüft.','en':'The title identifies a timelapse without spoken commentary. Automatically recognized music fragments were not indexed as instructions. Watch the original for the build; dimensions and Quest behavior are untested.'}
  record.update({'kind':'short' if short else 'video','transcriptIndex':index,'topics':[{'de':x[0],'en':x[1]} for x in topics]})
  if pub:record['published']=published
  record['sourceScope']={'de':'PCVR / Steam · Quest ungetestet','en':'PCVR / Steam · Quest untested'} if any(t in (description+' '+title).lower() for t in ['pcvr','steam']) else {'de':'Plattform dieses Videos nicht bestätigt · Quest ungetestet','en':'Video platform unconfirmed · Quest untested'}
  all_entries.append(record);audit.append({'id':id,'title':title,'included':True,'coverage':record['coverage'],'kind':record['kind'],'languages':langs,'windows':len(index),'hasMetadata':bool(info),'published':record['published']})
all_entries.sort(key=lambda x:x['published'] if x['published']!='–' else '',reverse=True)
(out/'VideoTips.json').write_text(json.dumps(all_entries,ensure_ascii=False,indent=2)+'\n')
(out/'inventory.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n')
(out/'topics.json').write_text(json.dumps(TOPICS,ensure_ascii=False,indent=2)+'\n')
print('Catalog:',len(all_entries),'regular:',sum(x['kind']=='video' for x in all_entries),'shorts:',sum(x['kind']=='short' for x in all_entries),'transcripts:',sum(bool(x['transcriptIndex']) for x in all_entries),'windows:',sum(len(x['transcriptIndex']) for x in all_entries),'metadata:',sum(bool(x['hasMetadata']) for x in audit),'pending:',[x['id'] for x in audit if not x['included'] and x['reason']=='Duration pending'])
