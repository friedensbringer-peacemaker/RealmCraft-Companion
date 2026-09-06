/* Local, directional terrain-profile estimate. No claim of navigable route finding. */
(function(root){
'use strict';
const defaults={walk:4,boat:6,cart:8,llama:3};
function kind(name){
 if(!name)return 'unknown';
 if(/^(water|flowing_water)$/.test(name))return 'water';
 if(['rail','powered_rail','detector_rail','activator_rail'].includes(name))return 'rail';
 if(/lava|fire|cactus|magma/.test(name))return 'hazard';
 if(/leaves|log|wood|sand|gravel|snow|soul_sand|cobweb/.test(name))return 'rough';
 if(name==='air'||name==='cave_air')return 'unknown';
 return 'land';
}
// Sample each grid crossing (including both side cells of a diagonal corner).
function cells(a,b){
 const out=[{x:a.x,z:a.z,t:0}],dx=b.x-a.x,dz=b.z-a.z,sx=Math.sign(dx),sz=Math.sign(dz);
 let x=a.x,z=a.z,tx=dx?.5/Math.abs(dx):Infinity,tz=dz?.5/Math.abs(dz):Infinity;
 while(x!==b.x||z!==b.z){
  if(Math.abs(tx-tz)<1e-10){const t=tx;out.push({x:x+sx,z,t,side:true},{x,z:z+sz,t,side:true});x+=sx;z+=sz;tx+=1/Math.abs(dx);tz+=1/Math.abs(dz);out.push({x,z,t});}
  else if(tx<tz){x+=sx;out.push({x,z,t:tx});tx+=1/Math.abs(dx);}
  else{z+=sz;out.push({x,z,t:tz});tz+=1/Math.abs(dz);}
 }
 return out;
}
function estimate(a,b,read,registry,speeds=defaults){
 const distance=Math.hypot(b.x-a.x,b.z-a.z);
 if(!Number.isFinite(distance)||distance>20000)return {error:'limit'};
 const points=cells(a,b),counts={water:0,rail:0,land:0,rough:0,hazard:0,unknown:0};
 let prev=null,ascent=0,descent=0,profile=0,walk=0,llama=0,steep=false;
 // Side cells constrain suitability but have no extra horizontal length.
 for(const p of points){
  const block=read(p.x,p.z),type=kind(registry[block?.id]);counts[type]++;
  if(p.side)continue;
  if(!block||!Number.isFinite(block.y)||type==='unknown'){prev=null;continue;}
  if(prev){const length=distance*(p.t-prev.t),dy=block.y-prev.y;
   if(length>0){ascent+=Math.max(0,dy);descent+=Math.max(0,-dy);profile+=Math.hypot(length,dy);steep ||= Math.abs(dy)>1;
    const types=[type,prev.type],water=types.includes('water'),rough=types.includes('rough');
    walk+=length*(water?2.5:rough?1.5:1)+Math.max(0,dy)*2+Math.max(0,-dy)*.5;
    llama+=length*(rough?1.7:1)+Math.max(0,dy)*2.5+Math.max(0,-dy)*.7;
   }
  }
  prev={...p,...block,type};
 }
 // The last sample is at the entry into the final cell; complete its half cell.
 if(prev){const tail=distance*(1-prev.t);profile+=tail;walk+=tail*(prev.type==='water'?2.5:prev.type==='rough'?1.5:1);llama+=tail*(prev.type==='rough'?1.7:1);}
 const complete=counts.unknown===0,blocked=counts.hazard>0;
 const time=(cost,mode,allowed)=>complete&&!blocked&&allowed&&Number.isFinite(speeds[mode])&&speeds[mode]>0?cost/speeds[mode]:null;
 return {distance,profile:complete?profile:null,ascent,descent,counts,total:points.length,steep,
  times:{walk:time(walk,'walk',true),boat:time(distance,'boat',counts.water===points.length&&!steep),cart:time(profile,'cart',counts.rail===points.length&&!steep),llama:time(llama,'llama',counts.water===0)},
  complete,blocked};
}
function segments(a,b,read,registry,speeds=defaults){
 const distance=Math.hypot(b.x-a.x,b.z-a.z),result=[];if(distance>20000)return [];
 const points=cells(a,b).filter(p=>!p.side);let previous=null;
 for(let i=0;i<points.length;i++){
  const p=points[i],block=read(p.x,p.z),type=kind(registry[block?.id]),mode=type==='unknown'?'gap':type==='hazard'?'hazard':type==='water'?'boat':type==='rail'?'cart':'walk';
  const length=distance*((points[i+1]?.t??1)-p.t),dy=previous&&block?block.y-previous.y:0;
  const cost=mode==='walk'?length*(type==='rough'?1.5:1)+Math.max(0,dy)*2+Math.max(0,-dy)*.5:length;
  const seconds=mode==='gap'||mode==='hazard'?null:cost/speeds[mode];
  const at={x:p.x,y:block?.y??null,z:p.z},end={x:points[i+1]?.x??b.x,y:null,z:points[i+1]?.z??b.z};
  let part=result.at(-1);if(!part||part.mode!==mode){part={mode,from:at,to:end,distance:0,seconds:seconds===null?null:0};result.push(part);}part.to=end;part.distance+=length;if(seconds!==null)part.seconds+=seconds;
  previous=block;
 }
 return result;
}
class Measure {
 constructor(data,{changed,activated}){
  this.data=data;this.changed=changed;this.activated=activated;this.points=[];this.speeds={...defaults};
  const en=document.documentElement.lang==='en';this.t=(de,enText)=>en?enText:de;const t=this.t;
  const el=(tag,text)=>{const e=document.createElement(tag);if(text)e.textContent=text;return e;};
  this.button=el('button',t('↔ Messen','↔ Measure'));this.button.type='button';this.button.id='measure-toggle';this.button.setAttribute('aria-expanded','false');document.querySelector('#quick-controls .quick-row').append(this.button);
  this.panel=el('section');this.panel.id='measure-panel';this.panel.hidden=true;this.panel.setAttribute('aria-label',t('Distanz und Reisezeit','Distance and travel time'));document.getElementById('map-area').append(this.panel);
  const header=el('div');header.className='measure-actions';header.append(el('strong',t('Distanz & Reisezeit · Beta','Distance & travel time · Beta')));
  const reset=el('button',t('Neu messen','Measure again')),close=el('button','×');close.setAttribute('aria-label',t('Messung schließen','Close measurement'));for(const b of [reset,close])b.type='button';header.append(reset,close);this.panel.append(header);
  this.output=el('div');this.output.setAttribute('role','status');this.panel.append(this.output);
  const details=el('details');details.append(el('summary',t('Annahmen & Geschwindigkeit','Assumptions & speed')));
  details.append(el('p',t('Profil der gespeicherten Oberfläche entlang der Messlinie, keine Wegsuche. Baumkronen, Dächer, Tunnel und Umwege können abweichen. Zeiten: grobe Spanne −25 % bis +50 %, ohne Pausen. Boot nur bei Wasser, Minecart nur bei Schienen entlang der ganzen Linie; Antrieb und Schienenanschlüsse sind nicht geprüft. Lama setzt ein nutzbares Tier voraus.','Saved surface profile along the measurement line, not route finding. Canopies, roofs, tunnels and detours may differ. Times: rough −25% to +50% range, without stops. Boat requires water, minecart requires rails along the whole line; propulsion and rail connections are not verified. Llama assumes a usable animal.')));
  details.append(el('p',t('Geschwindigkeiten sind Modellannahmen, keine gemessenen RealmCraft-Werte (Blöcke/s):','Speeds are model assumptions, not measured RealmCraft values (blocks/s):')));
  this.labels={walk:t('Zu Fuß','Walking'),boat:t('Boot','Boat'),cart:'Minecart',llama:t('Lama','Llama')};
  for(const [id,label]of Object.entries(this.labels)){const row=el('label',label),input=el('input');input.type='number';input.min='.1';input.max='50';input.step='.1';input.value=this.speeds[id];input.setAttribute('aria-label',label+' '+t('Blöcke pro Sekunde','blocks per second'));input.onchange=()=>{const v=Number(input.value);if(!Number.isFinite(v)||v<.1||v>50){input.value=this.speeds[id];return;}this.speeds[id]=v;this.update();};row.append(input);details.append(row);}
  this.panel.append(details);this.button.onclick=()=>this.panel.hidden?this.start():this.clear();reset.onclick=()=>this.start();close.onclick=()=>this.clear();
  root.addEventListener('atlas-privacy',()=>{this.button.disabled=!!root.AtlasPrivacy?.enabled;if(this.button.disabled)this.clear();});
 }
 start(){if(root.AtlasPrivacy?.enabled)return;this.points=[];this.active=true;this.panel.hidden=false;this.button.setAttribute('aria-expanded','true');this.activated();this.update();this.changed();}
 clear(){this.active=false;this.points=[];this.panel.hidden=true;this.button.setAttribute('aria-expanded','false');this.changed();}
 pick(p,dimension){if(!this.active)return false;this.dimension=dimension;this.points.push({x:Math.floor(p.x),z:Math.floor(p.z)});if(this.points.length===2)this.active=false;this.update();this.changed();return true;}
 read(x,z){const dim=this.data.dimensions[this.dimension],cx=Math.floor(x/16)*16,cz=Math.floor(z/16)*16,key=`${cx},${cz}`;let bytes=this.cache.get(key);if(!bytes){const encoded=dim.chunks[key];if(!encoded)return null;bytes=Uint8Array.from(atob(encoded),c=>c.charCodeAt(0));this.cache.set(key,bytes);}const i=(z-cz)*16+x-cx;return {id:bytes[i*2]|bytes[i*2+1]<<8,y:bytes[512+i]};}
 update(){
  const t=this.t;this.output.replaceChildren();const line=text=>{const p=document.createElement('p');p.textContent=text;this.output.append(p);};
  this.points.forEach((p,i)=>line(`${i?'B':'A'} · X ${p.x} · Z ${p.z}`));
  if(this.points.length<2){line(t(this.points.length?'Ziel B auf der Karte anklicken.':'Start A auf der Karte anklicken.','Click '+(this.points.length?'destination B':'start A')+' on the map.'));return;}
  this.cache=new Map();const r=estimate(...this.points,(x,z)=>this.read(x,z),this.data.registry,this.speeds);this.cache.clear();
  if(r.error){line(t('Maximal 20.000 Blöcke pro Messung.','Maximum 20,000 blocks per measurement.'));return;}
  const num=n=>Math.round(n).toLocaleString();line(t('Luftlinie: ','Straight line: ')+num(r.distance)+t(' Blöcke',' blocks'));
  if(r.complete)line(t('Oberflächenprofil: ','Surface profile: ')+num(r.profile)+t(' Blöcke',' blocks')+` · ↑ ${num(r.ascent)} · ↓ ${num(r.descent)}`);
  else line(t('Datenlücke: ','Missing data: ')+Math.round(r.counts.unknown/r.total*100)+t(' % der geprüften Spalten – keine Gesamtzeit.','% of checked columns — no total time.'));
  line(t('Geprüfte Spalten: ','Checked columns: ')+`${Math.round(r.counts.water/r.total*100)}% `+t('Wasser','water')+` · ${Math.round(r.counts.rail/r.total*100)}% `+t('Schienen','rails'));
  const duration=s=>s<60?Math.max(1,Math.round(s))+t(' s',' s'):s<3600?(s/60).toLocaleString(undefined,{maximumFractionDigits:1})+t(' Min.',' min'):(s/3600).toLocaleString(undefined,{maximumFractionDigits:1})+t(' Std.',' h');
  const modes=document.createElement('details');const summary=document.createElement('summary');summary.textContent=t('Einzelne Verkehrsmittel vergleichen','Compare single transport modes');modes.append(summary);this.output.append(modes);
  for(const [id,label]of Object.entries(this.labels)){
   const sec=r.times[id];let value=sec===null?t('nicht abschätzbar','not estimable'):sec===0?'0 s':`≈ ${duration(sec*.75)} – ${duration(sec*1.5)}`;
   if(r.complete&&!r.blocked&&sec===null)value=id==='boat'?t('kein durchgehendes Wasserprofil','no continuous water profile'):id==='cart'?t('kein durchgehendes Schienenprofil','no continuous rail profile'):t('Wasserquerung erforderlich','water crossing required');
   const item=document.createElement('p');item.textContent=`${label}: ${value}`;modes.append(item);
  }
  const parts=segments(...this.points,(x,z)=>this.read(x,z),this.data.registry,this.speeds);
  const known=parts.reduce((sum,p)=>sum+(p.seconds??0),0),changes=parts.slice(1).filter((p,i)=>p.seconds!==null&&parts[i].seconds!==null).length;
  const heading=document.createElement('h3');heading.textContent=t('Gemischte Reise · entlang der Messlinie','Mixed journey · along the measurement line');this.output.insertBefore(heading,modes);
  const subtotal=document.createElement('p');subtotal.textContent=(r.complete&&!r.blocked?t('Geschätzte Gesamtzeit: ','Estimated total: '):t('Nur bekannte Abschnitte: ','Known sections only: '))+`≈ ${duration((known+changes*20)*.75)} – ${duration((known+changes*20)*1.5)}`;this.output.insertBefore(subtotal,modes);
  const details=document.createElement('details');details.open=parts.length<=8;const title=document.createElement('summary');title.textContent=parts.length+' '+t('Abschnitte & Wechselpunkte','sections & transfer points');details.append(title);
  const list=document.createElement('ol');list.className='journey-segments';
  const names={...this.labels,gap:t('Datenlücke','Data gap'),hazard:t('Gefährlicher Abschnitt','Hazardous section')};
  for(const part of parts){const li=document.createElement('li'),strong=document.createElement('strong');strong.textContent=names[part.mode]+` · ${num(part.distance)} `+t('Blöcke','blocks');const text=document.createElement('div');text.textContent=`X ${part.from.x}, Y ${part.from.y??'?'}, Z ${part.from.z} → X ${part.to.x}, Z ${part.to.z}`+(part.seconds===null?'':` · ≈ ${duration(part.seconds)}`);li.append(strong,text);list.append(li);}details.append(list);this.output.insertBefore(details,modes);
  const note=document.createElement('p');note.className='small muted';note.textContent=t('Modell: zu Fuß an Land, Boot auf Wasser, Minecart auf Schienen; 20 s je Wechsel. Fahrzeuge müssen verfügbar sein. Keine bestätigte Verbindung. Fehlende Abschnitte sind nicht in der Teilzeit enthalten. Für Umwege unten eine Route planen.','Model: walk on land, boat on water, minecart on rails; 20 s per transfer. Vehicles must be available. Connections are unverified. Missing sections are excluded from subtotal. Plan a route below to consider detours.');modes.append(note);
  if(r.steep)line(t('Steile Höhenwechsel: Umweg oder Bauarbeiten können nötig sein; Zeit nur rechnerisch.','Steep height changes: a detour or construction may be needed; time is theoretical.'));
  if(r.blocked)line(t('Gefährliche Blöcke auf der Linie: keine Reisezeit berechnet.','Hazardous blocks on the line: travel time not calculated.'));
 }
 draw(ctx,screen){if(this.panel.hidden||root.AtlasPrivacy?.enabled)return;ctx.save();ctx.strokeStyle='#ffc96b';ctx.fillStyle='#ffc96b';ctx.lineWidth=3;ctx.setLineDash([8,5]);ctx.beginPath();this.points.forEach((p,i)=>{const s=screen(p.x+.5,p.z+.5);i?ctx.lineTo(s.x,s.y):ctx.moveTo(s.x,s.y);});ctx.stroke();ctx.setLineDash([]);this.points.forEach((p,i)=>{const s=screen(p.x+.5,p.z+.5);ctx.beginPath();ctx.arc(s.x,s.y,7,0,Math.PI*2);ctx.fill();ctx.font='bold 14px sans-serif';ctx.textAlign='center';ctx.fillText(i?'B':'A',s.x,s.y-13);});ctx.restore();}
}
const api={defaults,kind,cells,estimate,segments,Measure};root.AtlasMeasure=api;if(typeof module!=='undefined')module.exports=api;
})(globalThis);
