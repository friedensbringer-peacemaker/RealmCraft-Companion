/* Portal plans are Companion/browser metadata. No game writes or guaranteed links. */
(function(root){
 'use strict';
 const limit=30000000;
 function validPoint(p){return p&&['o','n'].includes(p.dimension)&&Number.isInteger(p.x)&&Number.isInteger(p.z)&&Math.abs(p.x)<=limit&&Math.abs(p.z)<=limit;}
 function convert(p){if(!validPoint(p))throw new Error('Invalid portal position');const factor=p.dimension==='o'?1/8:8;return {dimension:p.dimension==='o'?'n':'o',x:p.x*factor,z:p.z*factor};}
 function nearest(n){return n<0?-Math.round(-n):Math.round(n);}
 function markers(portals,plans){return [...portals.filter(validPoint).map(p=>({...p,kind:'saved'})),...plans.filter(p=>validPoint(p)&&typeof p.name==='string').flatMap(p=>[{...p,kind:'plan'},{...convert(p),id:p.id,name:p.name,kind:'target'}])];}
 class Planner {
  constructor(data,{changed,focus,getSelected}){
   this.data=data;this.changed=changed;this.focus=focus;this.getSelected=getSelected;this.dimension='o';this.draft=null;this.pending=false;
   this.t=(de,en)=>document.documentElement.lang==='en'?en:de;
   this.native=root.ATLAS_PORTALS||null;this.portals=this.native?.portals||[];
   this.key='realmcraft-atlas:portal-plans:'+(this.native?.saveID||data.title+':'+data.generatedAt);
   this.plans=[];try{this.plans=this.native?.plans??JSON.parse(localStorage.getItem(this.key)||'[]');if(!Array.isArray(this.plans))this.plans=[];}catch{}
   const section=document.getElementById('portal-layers');this.section=section;
   const el=(tag,text,parent=section)=>{const n=document.createElement(tag);if(text)n.textContent=text;parent.append(n);return n;};
   el('h2',this.t('Netherportale','Nether portals'));
   const check=el('label');check.className='check';this.visible=el('input','',check);this.visible.type='checkbox';this.visible.id='portal-visible';this.visible.checked=true;
   try{this.visible.checked=localStorage.getItem(this.key+':visible')!=='false';}catch{}
   el('span',this.t('Portal-Layer anzeigen','Show portal layer'),check);
   this.visible.onchange=()=>{try{localStorage.setItem(this.key+':visible',String(this.visible.checked));}catch{}changed();};
   el('p',this.t('Violett: gespeichert · Türkis: geplant · Gelb: berechnete Gegenposition. Höhenunabhängige Markierungen.','Purple: saved · Cyan: planned · Yellow: calculated counterpart. Markers are independent of the selected height.')).className='small muted';
   this.count=el('p');this.count.className='small muted';
   this.details=el('details');const summary=el('summary',this.t('Portal planen / ansehen','Plan / inspect a portal'),this.details);
   this.output=el('div','',this.details);this.output.className='small';
   const nameLabel=el('label',this.t('Bezeichnung','Name'),this.details);this.name=el('input','',nameLabel);this.name.id='portal-plan-name';this.name.maxLength=100;
   this.save=el('button',this.t('In Portalpaare übernehmen','Save in Portal pairs'),this.details);this.save.id='portal-plan-save';this.save.type='button';this.save.disabled=true;
   this.save.onclick=()=>this.persist();
   this.jump=el('button',this.t('Gegenposition auf Karte zeigen','Show counterpart on map'),this.details);this.jump.type='button';this.jump.className='text-button';this.jump.hidden=true;
   this.jump.onclick=()=>{if(this.counterpart&&data.dimensions[this.counterpart.dimension])this.focus(this.counterpart);};
   this.open=el('button',this.t('Portalpaare öffnen','Open Portal pairs'),this.details);this.open.type='button';this.open.className='text-button';this.open.hidden=!root.webkit?.messageHandlers?.atlasPortals;
   this.open.onclick=()=>root.webkit.messageHandlers.atlasPortals.postMessage({action:'open',saveID:this.native.saveID,world:this.native.world});
   this.status=el('p','',this.details);this.status.className='small';this.status.setAttribute('role','status');
   if(this.native?.inventoryError)el('p',this.native.inventoryError).className='small warning';
   if(this.native?.plansError)el('p',this.native.plansError).className='small warning';
   if(!this.native)el('p',this.t('Gespeicherte Portale sind im Companion verfügbar. Neue Pläne bleiben in diesem Browser.','Saved portal inventory is available in Companion. New plans stay in this browser.')).className='small muted';
   const action=document.getElementById('plan-portal');action.textContent=this.t('Hier Portal planen','Plan portal here');action.onclick=()=>{const p=getSelected();if(p)this.plan(p);};
   root.addEventListener('atlas-portals-saved',event=>{
    if(!this.pending)return;this.pending=false;
    if(event.detail?.ok&&Array.isArray(event.detail.plans)){this.plans=event.detail.plans;this.draft=null;this.save.disabled=true;this.status.textContent=this.t('Unter Portalpaare gespeichert.','Saved in Portal pairs.');this.visible.checked=true;}
    else {this.save.disabled=false;this.status.textContent=event.detail?.error||this.t('Speichern fehlgeschlagen.','Saving failed.');}
    this.refresh();changed();
   });
   root.addEventListener('atlas-privacy',()=>{this.refresh();changed();});this.refresh();
  }
  dim(d){return d==='o'?this.t('Oberwelt','Overworld'):'Nether';}
  coords(p){return this.dim(p.dimension)+` · X ${p.x} / Z ${p.z}`;}
  line(text){const p=document.createElement('p');p.textContent=text;this.output.append(p);}
  describe(p){
   this.output.replaceChildren();this.counterpart=convert(p);
   this.line(this.coords(p));
   if(Number.isInteger(p.referenceY))this.line(this.t('Referenzhöhe der Karte: Y ','Map reference height: Y ')+p.referenceY);
   this.line(this.t('Berechnet: ','Calculated: ')+this.coords(this.counterpart));
   this.line(this.t('Nächster Block: ','Nearest block: ')+`X ${nearest(this.counterpart.x)} / Z ${nearest(this.counterpart.z)}`);
   this.line(this.t('Annahme 1:8 · X/Z ÷8 oder ×8. Halbe Blockwerte werden von null weg gerundet. Zielhöhe Y und tatsächlicher Ausgang sind unbekannt.','Assumed 8:1 scale · X/Z ÷8 or ×8. Half-block ties round away from zero. Target Y and actual exit are unknown.'));
   const d=this.data.dimensions[this.counterpart.dimension],key=`${Math.floor(this.counterpart.x/16)*16},${Math.floor(this.counterpart.z/16)*16}`;
   if(!d?.chunks?.[key])this.line(this.t('Gegenposition außerhalb der gespeicherten Kartenabdeckung. Bauplatz nicht geprüft.','Counterpart outside saved map coverage. Build site not verified.'));
   this.jump.hidden=!d;
  }
  plan(p){
   if(this.pending||!validPoint(p))return;
   this.draft={dimension:p.dimension,x:p.x,z:p.z};if(Number.isInteger(p.y)&&p.y>=0&&p.y<=255)this.draft.referenceY=p.y;
   this.name.value=this.t('Portalplan','Portal plan')+` ${p.x}, ${p.z}`;this.name.disabled=false;this.name.parentElement.hidden=false;
   this.status.textContent='';this.describe(this.draft);this.save.hidden=false;this.save.disabled=!!this.native?.plansError;
   this.details.open=true;document.body.classList.add('sidebar-open');this.section.scrollIntoView({block:'nearest'});
  }
  persist(){
   if(this.pending||!this.draft)return;const name=this.name.value.trim();if(!name){this.status.textContent=this.t('Bitte eine Bezeichnung eingeben.','Enter a name.');return;}
   if(this.plans.length>=1000){this.status.textContent=this.t('Maximal 1.000 Pläne.','Maximum 1,000 plans.');return;}
   const handler=root.webkit?.messageHandlers?.atlasPortals;
   if(handler&&this.native){this.pending=true;this.save.disabled=true;this.status.textContent=this.t('Wird gespeichert …','Saving…');handler.postMessage({...this.draft,name,action:'add',saveID:this.native.saveID,world:this.native.world});}
   else {
    const plans=[...this.plans,{...this.draft,name,id:root.crypto.randomUUID()}];
    try{localStorage.setItem(this.key,JSON.stringify(plans));this.plans=plans;this.draft=null;this.save.disabled=true;this.visible.checked=true;this.status.textContent=this.t('In diesem Browser gespeichert.','Saved in this browser.');this.refresh();this.changed();}
    catch{this.status.textContent=this.t('Nicht gespeichert: Browserspeicher nicht verfügbar.','Not saved: browser storage unavailable.');}
   }
  }
  items(){return markers(root.AtlasPrivacy?.enabled?[]:this.portals,this.plans).filter(p=>p.dimension===this.dimension);}
  refresh(){this.count.textContent=this.items().length+' '+this.t('Markierungen in dieser Dimension','markers in this dimension');}
  setDimension(d){this.dimension=d;if(!this.pending){this.draft=null;this.save.disabled=true;this.details.open=false;}this.refresh();}
  draw(ctx,screen,width,height){
   if(!this.visible.checked)return;
   for(const m of this.items()){
    const p=screen(m.x+.5,m.z+.5);if(p.x<-20||p.y<-20||p.x>width+20||p.y>height+20)continue;
    ctx.save();ctx.strokeStyle=m.kind==='saved'?'#ce8bff':m.kind==='plan'?'#55e7e7':'#ffda70';ctx.fillStyle='#19162de6';ctx.lineWidth=2.5;ctx.setLineDash(m.kind==='saved'?[]:[4,3]);
    ctx.fillRect(p.x-7,p.y-10,14,20);ctx.strokeRect(p.x-7,p.y-10,14,20);ctx.restore();
   }
  }
  pick(x,y,screen){
   if(!this.visible.checked||this.pending)return false;
   const found=this.items().map(m=>({m,p:screen(m.x+.5,m.z+.5)})).filter(({p})=>Math.hypot(p.x-x,p.y-y)<13).sort((a,b)=>Math.hypot(a.p.x-x,a.p.y-y)-Math.hypot(b.p.x-x,b.p.y-y))[0]?.m;
   if(!found)return false;
   root.dispatchEvent(new CustomEvent('atlas-portal-picked',{detail:found}));
   if(found.kind==='saved'){
    this.plan(found);this.line(this.t('Gespeichertes Portal · ','Saved portal · ')+(found.bounds||''));
   }else{
    const plan=this.plans.find(p=>p.id===found.id);if(!plan)return false;
    this.draft=null;this.describe(plan);this.line(plan.name);this.name.parentElement.hidden=true;this.save.hidden=true;this.status.textContent='';this.details.open=true;this.section.scrollIntoView({block:'nearest'});
   }
   return true;
  }
 }
 root.AtlasPortals={Planner,convert,nearest,markers,validPoint};
 if(typeof module!=='undefined')module.exports=root.AtlasPortals;
})(typeof window!=='undefined'?window:globalThis);
