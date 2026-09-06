/* Points come from saved blocks. Building groups are explicitly heuristic. */
(() => {
 'use strict';
 const en=document.documentElement.lang==='en';
 const labels=en?{building:'Possible buildings',chest:'Chests',bed:'Beds',glass:'Glass groups',workbench:'Crafting tables',furnace:'Furnaces',all:'All indicators'}:{building:'Mögliche Gebäude',chest:'Kisten',bed:'Betten',glass:'Glasgruppen',workbench:'Werkbänke',furnace:'Öfen',all:'Alle Hinweise'};
 const colors={building:'#ffd56d',chest:'#ffad62',bed:'#ff82a9',glass:'#84e9ff',workbench:'#d8b2ff',furnace:'#bbc8d2'};
 class AtlasPoints {
  constructor(data,callbacks){
   this.data=data;this.callbacks=callbacks;this.dimension=data.dimensions.o?'o':Object.keys(data.dimensions)[0];this.category='building';this.index=-1;this.visible=true;
   this.$=id=>document.getElementById(id);this.storageKey='realmcraft-atlas:poi-names:'+data.title;this.names={};
   try{const stored=window.ATLAS_NATIVE_NAMES||JSON.parse(localStorage.getItem(this.storageKey)||'{}');for(const [key,value]of Object.entries(stored))if(typeof value==='string'&&value.length<=60)this.names[key]=value;}catch{}
   this.$('poi-heading').textContent=en?'Interesting places':'Interessante Orte';this.$('poi-show').textContent=en?'Show markers':'Markierungen anzeigen';
   this.$('poi-kind').setAttribute('aria-label',en?'Place category':'Ortskategorie');
   for(const [value,label]of Object.entries(labels)){const o=document.createElement('option');o.value=value;o.textContent=label;this.$('poi-kind').append(o);}
   this.$('poi-prev').setAttribute('aria-label',en?'Previous place':'Vorheriger Ort');this.$('poi-next').setAttribute('aria-label',en?'Next place':'Nächster Ort');
   this.$('poi-input').setAttribute('aria-label',en?'Name this place':'Diesen Ort benennen');this.$('poi-input').placeholder=en?'e.g. Home storage':'z. B. Lager zu Hause';this.$('poi-save').textContent=en?'Save name':'Namen speichern';
   this.$('poi-note').textContent=en?'Building suggestions combine at least two indicator types in a 32 × 32 × 16 block area. They are clues, not confirmed houses. Underground blocks are included.':'Gebäudevorschläge kombinieren mindestens zwei Hinweisarten in einem Bereich von 32 × 32 × 16 Blöcken. Sie sind Hinweise, keine bestätigten Häuser. Unterirdische Blöcke werden berücksichtigt.';
   this.$('poi-visible').onchange=e=>{this.visible=e.target.checked;this.callbacks.changed();};
   this.$('poi-kind').onchange=e=>{this.category=e.target.value;this.index=-1;this.refresh();};
   this.$('poi-prev').onclick=()=>this.step(-1);this.$('poi-next').onclick=()=>this.step(1);
   this.$('poi-rename').onsubmit=e=>{e.preventDefault();const p=this.filtered()[this.index];if(!p)return;const value=this.$('poi-input').value.trim();if(value)this.names[p.id]=value;else delete this.names[p.id];
    try{localStorage.setItem(this.storageKey,JSON.stringify(this.names));}catch{this.$('poi-storage').hidden=false;this.$('poi-storage').textContent=en?'Browser storage unavailable. Keep this map open or use the app to persist names.':'Browserspeicher nicht verfügbar. Karte offen lassen oder die App zum Speichern der Namen verwenden.';}
    if(window.webkit?.messageHandlers?.atlasPOINames)window.webkit.messageHandlers.atlasPOINames.postMessage({world:data.title,names:this.names});
    this.refresh();};
   this.refresh();
  }
  filtered(){return(this.data.dimensions[this.dimension]?.points||[]).filter(p=>this.category==='all'||p.kind===this.category);}
  selectChest(x,y,z){
   const points=this.data.dimensions[this.dimension]?.points||[];
   if(!points.some(p=>p.kind==='chest'&&p.x===x&&p.y===y&&p.z===z))return false;
   this.category='chest';this.$('poi-kind').value='chest';this.index=this.filtered().findIndex(p=>p.x===x&&p.y===y&&p.z===z);this.refresh();return true;
  }
  setDimension(d){this.dimension=d;this.index=-1;this.refresh();}
  title(p){return this.names[p.id]||`${labels[p.kind]} · ${p.x}, ${p.y}, ${p.z}`;}
  step(delta){const points=this.filtered();if(!points.length)return;this.index=this.index<0?(delta>0?0:points.length-1):(this.index+delta+points.length)%points.length;this.visible=true;this.$('poi-visible').checked=true;this.refresh();this.callbacks.focus(points[this.index]);}
  refresh(){const points=this.filtered(),p=points[this.index];this.$('poi-count').textContent=p?`${this.index+1} / ${points.length}`:`${points.length} ${en?'places':'Orte'}`;this.$('poi-prev').disabled=!points.length;this.$('poi-next').disabled=!points.length;this.$('poi-detail').hidden=!p;
   if(p){this.$('poi-name').textContent=this.title(p);this.$('poi-coords').textContent=`X ${p.x} · Y ${p.y} · Z ${p.z}`;this.$('poi-input').value=this.names[p.id]||'';this.$('poi-clues').textContent=p.clues?Object.entries(p.clues).map(([k,v])=>`${labels[k]}: ${v}`).join(' · '):`${labels[p.kind]}: ${p.count}`;}
   this.preview(p);
   this.callbacks.changed();
  }
  preview(p){
   const panel=this.$("chest-preview");panel.replaceChildren();panel.hidden=p?.kind!=="chest";if(panel.hidden)return;
   const add=(tag,text,cls)=>{const el=document.createElement(tag);el.textContent=text;if(cls)el.className=cls;panel.append(el);return el;};
   document.body?.classList.add("sidebar-open");
   panel.scrollIntoView?.({block:"nearest"});
   add("h3",en?"Chest contents":"Kisteninhalt");
   const chest=this.data.dimensions[this.dimension]?.chests?.[`${p.x},${p.y},${p.z}`];
   if(!chest?.readable){add("p",en?"Contents unavailable. The record is missing or its format is unsupported.":"Inhalt nicht verfügbar. Der Datensatz fehlt oder sein Format wird nicht unterstützt.","small muted");return;}
   const items=chest.items||[];
   add("p",items.length?`${items.length} / 27 ${en?"slots occupied":"Plätze belegt"}`:(en?"This chest is empty.":"Diese Kiste ist leer."),"small muted");
   if(items.length){const list=add("ol","","chest-items");for(const item of [...items].sort((a,b)=>a.slot-b.slot)){const row=document.createElement("li");row.value=item.slot;const name=this.data.itemNames?.[item.itemID]?.[en?"en":"de"]||`Item #${item.itemID}`;row.textContent=`${name} × ${item.quantity}`;row.title=`${en?"Slot":"Platz"} ${item.slot} · ID ${item.itemID}`;if(item.extraData){row.textContent+=en?" · Additional properties":" · Zusatzeigenschaften";}list.append(row);}}
   add("p",en?"Contents at the time of this backup.":"Inhalt zum Zeitpunkt dieser Sicherung.","small muted");
  }
  draw(ctx,screen,width,height){if(!this.visible)return;const points=this.filtered();
   for(let i=0;i<points.length;i++){const p=points[i],s=screen(p.x+.5,p.z+.5);if(s.x<0||s.y<0||s.x>width||s.y>height)continue;const active=i===this.index;ctx.beginPath();ctx.arc(s.x,s.y,active?9:4,0,Math.PI*2);ctx.fillStyle=colors[p.kind]||'#fff';ctx.fill();ctx.lineWidth=active?3:1;ctx.strokeStyle=active?'#fff':'#21342c';ctx.stroke();
    if(active){const title=this.title(p);ctx.font='600 12px -apple-system,sans-serif';ctx.textAlign='left';const w=ctx.measureText(title).width;ctx.fillStyle='#112a2ef0';ctx.fillRect(s.x+12,s.y-14,w+14,26);ctx.fillStyle='#fff';ctx.fillText(title,s.x+19,s.y+3);}
   }
  }
  pick(x,y,screen){if(!this.visible)return false;let chosen=-1,distance=13;const points=this.filtered();for(let i=0;i<points.length;i++){const p=points[i],s=screen(p.x+.5,p.z+.5),d=Math.hypot(s.x-x,s.y-y);if(d<distance){distance=d;chosen=i;}}if(chosen<0)return false;this.index=chosen;this.refresh();return true;}
 }
 window.AtlasPoints=AtlasPoints;
})();
