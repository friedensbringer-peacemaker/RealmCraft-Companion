/* One overlay for Atlas and the specialized native Metro workspace. */
(function(root){
 'use strict';
 const validPoint=p=>!!p&&['o','n'].includes(p.dimension)&&[p.x,p.y,p.z].every(Number.isInteger)&&Math.abs(p.x)<=30000000&&Math.abs(p.z)<=30000000&&p.y>=0&&p.y<=255;
 function geometry(edge,a,b){
  if(edge.mode==='portal'||a.dimension!==b.dimension)return null;
  const path=edge.path;
  if(Array.isArray(path)&&path.length>=2&&path.every(p=>validPoint({...p,dimension:a.dimension}))&&
   ['x','y','z'].every(k=>path[0][k]===a[k]&&path[path.length-1][k]===b[k]))return {points:path,captured:true};
  return {points:[a,b],captured:false};
 }
 class Overlay {
  constructor(data,{changed,getSelected,focus}){
   this.data=data;this.changed=changed;this.getSelected=getSelected;this.focus=focus;this.dimension='o';
   this.t=(de,en)=>document.documentElement.lang==='en'?en:de;
   const section=document.getElementById('metro-layers');
   const el=(tag,text,parent=section)=>{const n=document.createElement(tag);if(text)n.textContent=text;parent.append(n);return n;};
   el('h2',this.t('Metronetz','Metro network'));
   const label=el('label');label.className='check';this.visible=el('input','',label);this.visible.type='checkbox';this.visible.checked=true;
   el('span',this.t('Stationen & Linien','Stations & lines'),label);this.visible.onchange=changed;
   this.count=el('p');this.count.className='small muted';
   el('p',this.t('Gestrichelt: geplant · Gepunktet: Verlauf fehlt · Durchgezogen: bestätigter, erfasster Verlauf.','Dashed: planned · Dotted: geometry missing · Solid: confirmed, recorded geometry.')).className='small muted';
   this.status=el('p');this.status.className='small';this.status.setAttribute('role','status');
   root.addEventListener('atlas-metro-update',e=>this.receive(e.detail));
   root.addEventListener('atlas-privacy',()=>{this.status.textContent='';changed();});
   this.receive(root.ATLAS_METRO||{});
  }
  receive(value){
   this.native=value;this.workspace=!!value.workspace;
   this.stations=(value.stations||[]).filter(validPoint);this.lines=value.lines||[];this.edges=value.edges||[];
   document.documentElement.classList.toggle('metro-workspace',this.workspace);
   if(this.workspace){
    document.getElementById('expand').textContent=this.t('☰ Karte','☰ Map');
    document.getElementById('map-area').append(this.status);this.status.className='metro-status pill';
    // Quick controls move transport toggles out of the sidebar; restore them in this instance.
    const transport=document.getElementById('transport-layers');if(transport)document.getElementById('sidebar').append(transport);
   }
   this.refresh();this.changed();
   if(this.lastFocus!==value.focusID){this.lastFocus=value.focusID;const station=this.stations.find(s=>s.id===value.focusID);if(station&&this.readyToFocus)this.focus?.(station);}
  }
  ready(){this.readyToFocus=true;if(this.workspace){const station=this.stations.find(s=>s.id===this.native.focusID)||this.stations.find(s=>s.dimension==='n');if(station)this.focus?.(station);else if(this.data.dimensions.n)this.focus?.({dimension:'n',x:0,z:0});}}
  setDimension(d){this.dimension=d;this.refresh();}
  refresh(){this.count.textContent=this.stations.filter(s=>s.dimension===this.dimension).length+' '+this.t('Stationen','stations');}
  choose(p){
   if(!this.workspace||root.AtlasPrivacy?.enabled)return false;
   if(!validPoint(p)){this.status.textContent=this.t('Keine gespeicherte Höhe. Station mit bewusst gewähltem Y im Detailbereich anlegen.','No saved height. Create the station with an explicit Y in the inspector.');return true;}
   root.webkit?.messageHandlers?.atlasMetro?.postMessage({action:'pick',saveID:this.native.saveID,world:this.native.world,dimension:p.dimension,x:p.x,y:p.y,z:p.z,knownHeight:true,portalID:p.portalID||null});
   this.status.textContent=this.t('Position im Detailbereich ausgewählt.','Position selected in the inspector.');return true;
  }
  pick(px,py,screen,lookup){
   if(!this.workspace||root.AtlasPrivacy?.enabled)return false;
   const candidates=[...this.stations,...(root.ATLAS_PORTALS?.portals||[]).map(p=>({...p,portalID:p.id}))].filter(s=>s.dimension===this.dimension);
   const hit=candidates.find(p=>{const s=screen(p.x+.5,p.z+.5);return Math.hypot(s.x-px,s.y-py)<12;});
   return this.choose(hit||lookup());
  }
  draw(ctx,screen,width,height){
   if(!this.visible.checked||root.AtlasPrivacy?.enabled)return;
   const stations=new Map(this.stations.filter(s=>s.dimension===this.dimension).map(s=>[s.id,s])),lines=new Map(this.lines.map(l=>[l.id,l]));
   for(const edge of this.edges){
    const a=stations.get(edge.from),b=stations.get(edge.to);if(!a||!b)continue;
    const g=geometry(edge,a,b);if(!g)continue;
    const points=g.points.map(p=>screen(p.x+.5,p.z+.5)),line=lines.get(edge.lineID);
    ctx.save();ctx.strokeStyle=/^#[0-9a-f]{6}$/i.test(line?.color||'')?line.color:'#94a3b8';ctx.globalAlpha=edge.status==='confirmed'?1:.55;
    ctx.lineWidth=4;ctx.lineJoin='round';ctx.lineCap='round';ctx.setLineDash(!g.captured?[2,7]:edge.status==='confirmed'?[]:[9,6]);
    ctx.beginPath();points.forEach((p,i)=>i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y));ctx.stroke();
    const a1=points[points.length-2],b1=points[points.length-1],angle=Math.atan2(b1.y-a1.y,b1.x-a1.x),mx=(a1.x+b1.x)/2,my=(a1.y+b1.y)/2;
    ctx.setLineDash([]);ctx.beginPath();ctx.moveTo(mx-7*Math.cos(angle-.5),my-7*Math.sin(angle-.5));ctx.lineTo(mx,my);ctx.lineTo(mx-7*Math.cos(angle+.5),my-7*Math.sin(angle+.5));ctx.stroke();ctx.restore();
   }
   for(const station of stations.values()){
    const p=screen(station.x+.5,station.z+.5);if(p.x<-80||p.y<-50||p.x>width+80||p.y>height+50)continue;
    const ids=new Set(this.edges.filter(e=>e.from===station.id||e.to===station.id).map(e=>e.lineID).filter(Boolean)),selected=station.id===this.native.focusID;
    ctx.save();ctx.fillStyle='#11251e';ctx.strokeStyle=selected?'#b7d879':'#eff6e8';ctx.lineWidth=ids.size>1?4:2;
    ctx.beginPath();ctx.arc(p.x,p.y,selected?10:7,0,Math.PI*2);ctx.fill();ctx.stroke();
    if(station.portalCandidate===true){ctx.beginPath();ctx.moveTo(p.x-3,p.y+4);ctx.lineTo(p.x-3,p.y-4);ctx.lineTo(p.x+3,p.y-4);ctx.lineTo(p.x+3,p.y+4);ctx.stroke();}
    ctx.font='600 12px -apple-system,sans-serif';const label=station.name,w=ctx.measureText(label).width;
    ctx.fillStyle='#11251ef0';ctx.fillRect(p.x-w/2-7,p.y-34,w+14,22);ctx.fillStyle='#f1f5ea';ctx.textAlign='center';ctx.fillText(label,p.x,p.y-19);ctx.restore();
   }
  }
 }
 root.AtlasMetro={Overlay,validPoint,geometry};
 if(typeof module!=='undefined')module.exports=root.AtlasMetro;
})(typeof window!=='undefined'?window:globalThis);
