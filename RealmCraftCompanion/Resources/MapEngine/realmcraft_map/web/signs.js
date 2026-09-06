/* Saved inscriptions are plain text, never markup. Locations include all Y levels. */
(() => {
 'use strict';
 const en=document.documentElement.lang==='en';
 class AtlasSigns {
  constructor(data,callbacks){
   this.data=data;this.callbacks=callbacks;this.dimension=data.dimensions.o?'o':Object.keys(data.dimensions)[0];
   this.focusOnly=true;this.visible=false;this.query='';this.selected=null;this.$=id=>document.getElementById(id);
   this.$('sign-heading').textContent=en?'Signs':'Schilder';
   this.$('sign-show').textContent=en?'Signs':'Schilder';
   this.$('sign-search').placeholder=en?'Search text or coordinates':'Text oder Koordinaten suchen';
   this.$('sign-search').setAttribute('aria-label',en?'Search signs':'Schilder suchen');
   this.$('sign-prev').setAttribute('aria-label',en?'Previous sign':'Vorheriges Schild');
   this.$('sign-next').setAttribute('aria-label',en?'Next sign':'Nächstes Schild');
   this.$('sign-visible').onchange=e=>{this.visible=e.target.checked;this.selected=null;this.refresh();};
   this.$('sign-search').oninput=e=>{this.query=e.target.value.trim().toLocaleLowerCase();this.selected=null;if(this.query&&this.available()&&!window.AtlasPrivacy?.enabled){this.visible=true;this.$('sign-visible').checked=true;}this.refresh();};
   this.$('sign-prev').onclick=()=>this.step(-1);this.$('sign-next').onclick=()=>this.step(1);
   this.refresh();
  }
  isolate(){return this.focusOnly&&!!this.query&&this.available()&&!window.AtlasPrivacy?.enabled;}
  available(){return this.data.signSchema===1&&Array.isArray(this.data.dimensions[this.dimension]?.signs);}
  filtered(){
   if(!this.available()||window.AtlasPrivacy?.enabled)return [];
   return this.data.dimensions[this.dimension].signs.filter(s=>`${s.readable?s.text:''} ${s.x}, ${s.y}, ${s.z}`.toLocaleLowerCase().includes(this.query));
  }
  setDimension(d){this.dimension=d;this.selected=null;this.refresh();}
  title(s){return s.readable?(s.text.trim().replace(/\s+/g,' ').slice(0,80)||(en?'Empty sign':'Leeres Schild')):(en?'Sign · text unavailable':'Schild · Text nicht lesbar');}
  refresh(){
   const blocked=!!window.AtlasPrivacy?.enabled,available=this.available(),points=this.filtered();
   if(!this.visible||!points.some(s=>s.id===this.selected?.id))this.selected=null;
   for(const id of ['sign-visible','sign-search'])this.$(id).disabled=blocked||!available;
   for(const id of ['sign-prev','sign-next'])this.$(id).disabled=!points.length;
   this.$('sign-count').textContent=`${points.length} ${en?(points.length===1?'sign':'signs'):(points.length===1?'Schild':'Schilder')}`;
   this.$('sign-note').textContent=blocked?(en?'Signs are hidden in spoiler-light mode.':'Schilder sind im spoilerarmen Modus ausgeblendet.'):
    !available?(en?'Generate this map again to read its signs.':'Karte erneut erzeugen, um die Schilder einzulesen.'):
    (en?'Saved signs at all heights, including underground. Search filters the markers.':'Gespeicherte Schilder auf allen Höhen, auch unterirdisch. Die Suche filtert die Markierungen.');
   const focus=this.$('search-focus-control');if(focus)focus.hidden=!this.query||!available||blocked;
   const status=this.$('sign-search-status');if(status){status.hidden=!blocked&&available;status.textContent=(blocked||!available)?this.$('sign-note').textContent:'';}
   this.$('sign-detail').hidden=!this.selected;
   if(this.selected){const s=this.selected;
    this.$('sign-text').textContent=s.readable?(s.text.trim()?s.text:(en?'(Empty sign)':'(Leeres Schild)')):(en?'Text unavailable: missing or unsupported record.':'Text nicht lesbar: Datensatz fehlt oder Format wird nicht unterstützt.');
    this.$('sign-coords').textContent=`X ${s.x} · Y ${s.y} · Z ${s.z}`;
   }else{this.$('sign-text').textContent='';this.$('sign-coords').textContent='';}
   this.callbacks.changed();
  }
  choose(s,focus=false){
   this.visible=true;this.$('sign-visible').checked=true;this.selected=s;this.refresh();
   document.body?.classList.add('sidebar-open');this.$('sign-detail').scrollIntoView?.({block:'nearest'});
   if(focus)this.callbacks.focus(s);
  }
  step(delta){const points=this.filtered();if(!points.length)return;const index=points.findIndex(s=>s.id===this.selected?.id);this.choose(points[index<0?(delta>0?0:points.length-1):(index+delta+points.length)%points.length],true);}
  draw(ctx,screen,width,height){
   if(!this.visible)return;
   for(const s of this.filtered()){
    const p=screen(s.x+.5,s.z+.5);if(p.x<0||p.y<0||p.x>width||p.y>height)continue;
    const active=s.id===this.selected?.id,r=active?8:6;
    ctx.fillStyle='#78e3c8';ctx.strokeStyle=active?'#ffffff':'#143d34';ctx.lineWidth=active?3:1;
    ctx.fillRect(p.x-r,p.y-r,r*2,r*1.4);ctx.strokeRect(p.x-r,p.y-r,r*2,r*1.4);
    ctx.beginPath();ctx.moveTo(p.x,p.y+r*.4);ctx.lineTo(p.x,p.y+r);ctx.stroke();
    if(active){const title=this.title(s);ctx.font='600 12px -apple-system,sans-serif';ctx.textAlign='left';const w=ctx.measureText(title).width;
     ctx.fillStyle='#112a2ef0';ctx.fillRect(p.x+12,p.y-14,w+14,26);ctx.fillStyle='#fff';ctx.fillText(title,p.x+19,p.y+3);}
   }
  }
  pick(x,y,screen){
   if(!this.visible)return false;
   const hits=this.filtered().map(s=>({s,p:screen(s.x+.5,s.z+.5)})).map(h=>({...h,d:Math.hypot(h.p.x-x,h.p.y-y)})).filter(h=>h.d<13).sort((a,b)=>a.d-b.d);
   if(!hits.length)return false;
   // Repeated clicks cycle signs that share one projected location.
   const nearest=hits.filter(h=>Math.abs(h.d-hits[0].d)<.01),index=nearest.findIndex(h=>h.s.id===this.selected?.id);
   this.choose(nearest[(index+1)%nearest.length].s);return true;
  }
 }
 window.AtlasSigns=AtlasSigns;
})();
