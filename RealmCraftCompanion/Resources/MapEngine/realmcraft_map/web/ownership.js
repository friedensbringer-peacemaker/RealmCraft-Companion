/* Bulk ownership only touches recorded chests in the selected dimension and X/Z bounds. */
(() => {
 'use strict';
 function bounds(a,b){return {xmin:Math.floor(Math.min(a.x,b.x)),xmax:Math.floor(Math.max(a.x,b.x)),zmin:Math.floor(Math.min(a.z,b.z)),zmax:Math.floor(Math.max(a.z,b.z))};}
 function records(data,dimension){const d=data.dimensions[dimension]||{};const keys=new Set([...Object.keys(d.chests||{}),...(d.points||[]).filter(p=>p.kind==='chest').map(p=>`${p.x},${p.y},${p.z}`)]);return [...keys].flatMap(key=>{
  const parts=key.split(',');if(parts.length!==3)return [];
  const [x,y,z]=parts.map(Number);if(![x,y,z].every(Number.isSafeInteger)||Math.abs(x)>30000000||Math.abs(z)>30000000||y<0||y>255)return [];
  return [{id:`${dimension}:${x},${y},${z}`,x,y,z}];
 });}
 function select(data,dimension,box){return records(data,dimension).filter(c=>c.x>=box.xmin&&c.x<=box.xmax&&c.z>=box.zmin&&c.z<=box.zmax).map(c=>c.id).sort();}
 class AtlasOwnership {
  constructor(data,callbacks){
   this.data=data;this.callbacks=callbacks;this.active=false;this.drag=null;this.box=null;this.selected=[];this.pending=false;this.dimension=data.dimensions.o?'o':Object.keys(data.dimensions)[0];
   this.owned=new Set(window.ATLAS_NATIVE_OWNED||[]);this.en=document.documentElement.lang==='en';this.$=id=>document.getElementById(id);
   this.bridge=window.webkit?.messageHandlers?.atlasOwnership;
   this.$('ownership-toggle').textContent=this.t('Besitzbereich ziehen','Select ownership area');
   this.$('ownership-title').textContent=this.t('Kisten als Besitz markieren','Mark chest ownership');
   this.$('ownership-add').textContent=this.t('Als eigen markieren','Mark as owned');
   this.$('ownership-remove').textContent=this.t('Besitzmarkierung entfernen','Remove ownership marks');
   this.$('ownership-close').textContent=this.t('Schließen','Close');
   this.$('ownership-note').textContent=this.t('Zwei Ecken ziehen. X/Z-Rechteck · aktuelle Dimension · alle Höhen (Y 0–255). Nur Kisten dieser Karte werden erfasst, auch bei ausgeblendeten Markierungen. Neue Kisten später erneut auswählen. Grün = eigene Kisten.','Drag between two corners. X/Z rectangle · current dimension · all heights (Y 0–255). Includes only chests recorded in this map, even with markers hidden. Select newly added chests again later. Green = owned chests.');
   if(!Object.values(data.dimensions).some(d=>d.chests))this.$('ownership-note').textContent+=this.t(' Ältere Karte: Kisten aus gespeicherten Markierungen; Inhalte werden beim Export neu gelesen.',' Older map: chests from saved markers; contents are freshly scanned when exporting.');
   if(data.errors?.length||data.chestErrors?.length)this.$('ownership-note').textContent+=this.t(' Die Karte hat Lesefehler; Kisten können fehlen.',' This map has read errors; chests may be missing.');
   if(!this.bridge){this.$('ownership-toggle').disabled=true;this.$('ownership-toggle').title=this.t('Besitz wird in der Companion-App gespeichert.','Ownership is saved in the Companion app.');}
   this.$('ownership-toggle').onclick=()=>this.toggle();this.$('ownership-close').onclick=()=>this.cancel();
   this.$('ownership-add').onclick=()=>this.apply('add');this.$('ownership-remove').onclick=()=>this.apply('remove');
   window.ATLAS_OWNERSHIP=this;this.refresh();
  }
  t(de,en){return this.en?en:de;}
  toggle(){if(window.AtlasPrivacy?.enabled || this.pending)return;if(this.active){this.cancel();return;}this.active=true;this.callbacks.activated?.();this.box=null;this.selected=[];this.message='';this.refresh();this.callbacks.changed();}
  cancel(){if(this.pending)return;this.active=false;this.drag=null;this.box=null;this.selected=[];this.refresh();this.callbacks.changed();}
  setDimension(value){this.dimension=value;this.active=false;this.drag=null;this.box=null;this.selected=[];this.refresh();this.callbacks.changed();}
  begin(pointer,world){if(!this.active||this.pending||this.drag)return false;this.drag={pointer,start:world};this.box=bounds(world,world);this.selected=select(this.data,this.dimension,this.box);this.message='';this.refresh();return true;}
  move(pointer,world){if(this.drag?.pointer!==pointer)return false;this.box=bounds(this.drag.start,world);this.selected=select(this.data,this.dimension,this.box);this.refresh();this.callbacks.changed();return true;}
  end(pointer,world){if(this.drag?.pointer!==pointer)return false;this.move(pointer,world);this.drag=null;this.refresh();return true;}
  abort(pointer){if(this.drag?.pointer!==pointer)return;this.drag=null;this.box=null;this.selected=[];this.refresh();this.callbacks.changed();}
  apply(action){if(this.pending||this.drag||!this.selected.length||!this.bridge)return;
   this.pending=true;this.message=this.t('Speichern …','Saving…');this.refresh();
   this.timer=setTimeout(()=>{this.pending=false;this.message=this.t('Keine Speicherbestätigung. Bitte erneut versuchen.','No save confirmation. Please try again.');this.refresh();},5000);
   try{this.bridge.postMessage({world:this.data.title,action,ids:this.selected});}
   catch{clearTimeout(this.timer);this.pending=false;this.message=this.t('Besitz konnte nicht gespeichert werden.','Could not save ownership.');this.refresh();}
  }
  receive(result){clearTimeout(this.timer);this.pending=false;
   if(Array.isArray(result.ownedIDs)){this.owned=new Set(result.ownedIDs);if(window.AtlasPrivacy)window.AtlasPrivacy.apply({...window.AtlasPrivacy.state,owned:result.ownedIDs});}
   this.message=result.error?this.t('Besitz konnte nicht gespeichert werden.','Could not save ownership.'):
    this.t(`${result.changed} Markierungen geändert. Gespeichert für Gespräch und KI-Export.`,`${result.changed} marks changed. Saved for Conversation and AI export.`);
   this.refresh();this.callbacks.changed();
  }
  refresh(){
   this.$('ownership-panel').hidden=!this.active;this.$('ownership-toggle').setAttribute('aria-pressed',String(this.active));
   this.$('map').classList.toggle('ownership-mode',this.active);
   this.$('ownership-toggle').disabled=!this.bridge||this.pending;this.$('ownership-close').disabled=this.pending;
   const n=this.selected.length,owned=this.selected.filter(id=>this.owned.has(id)).length;
   this.$('ownership-count').textContent=this.box?this.t(`${n} Kisten · ${owned} bereits eigen`,`${n} chests · ${owned} already owned`):this.t('Ziehe ein Rechteck auf der Karte.','Drag a rectangle on the map.');
   this.$('ownership-bounds').textContent=this.box?`${this.dimension}: X ${this.box.xmin}…${this.box.xmax}, Z ${this.box.zmin}…${this.box.zmax} · Y 0–255`:'';
   this.$('ownership-status').textContent=this.message||'';
   this.$('ownership-add').disabled=this.pending||!!this.drag||n===0||n===owned;
   this.$('ownership-remove').disabled=this.pending||!!this.drag||owned===0;
  }
  draw(ctx,screen,width,height){
   if(!this.active)return;
   for(const c of records(this.data,this.dimension)){if(!this.owned.has(c.id) || (window.AtlasPrivacy && !window.AtlasPrivacy.allows(this.dimension,{...c,kind:'chest'})))continue;const p=screen(c.x+.5,c.z+.5);if(p.x<0||p.y<0||p.x>width||p.y>height)continue;
    ctx.beginPath();ctx.arc(p.x,p.y,7,0,2*Math.PI);ctx.lineWidth=2;ctx.strokeStyle='#70f39b';ctx.stroke();}
   if(!this.box)return;
   const b=this.box,corners=[[b.xmin,b.zmin],[b.xmax+1,b.zmin],[b.xmax+1,b.zmax+1],[b.xmin,b.zmax+1]].map(([x,z])=>screen(x,z));
   ctx.save();ctx.beginPath();corners.forEach((p,i)=>i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y));ctx.closePath();ctx.fillStyle='#70f39b30';ctx.fill();ctx.strokeStyle='#70f39b';ctx.lineWidth=2;ctx.setLineDash([7,4]);ctx.stroke();ctx.restore();
  }
 }
 if(typeof module==='object'&&module.exports)module.exports={bounds,records,select};
 if(typeof window!=='undefined')window.AtlasOwnership=AtlasOwnership;
})();
