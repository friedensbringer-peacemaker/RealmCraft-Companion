(function(root){
 'use strict';
 const valid=p=>p&&typeof p.id==='string'&&['o','n'].includes(p.dimension)&&[p.x,p.y,p.z,p.blockID].every(Number.isInteger)&&Math.abs(p.x)<=30000000&&Math.abs(p.z)<=30000000&&p.y>=0&&p.y<=255&&p.blockID>=0&&p.blockID<65535;
 function install(data,measure,focus){
  const en=document.documentElement.lang==='en',card=document.createElement('section');card.className='resource-target-card';
  const text=document.createElement('p'),status=document.createElement('p'),button=document.createElement('button'),close=document.createElement('button');
  button.textContent=en?'Plan surface approach · choose start A':'Oberflächenzugang planen · Start A wählen';
  close.textContent=en?'Close target':'Ziel schließen';card.append(text,status,button,close);card.hidden=true;
  document.getElementById('map-area').append(card);let current=null,lastID=null;
  function receive(p){
   if(!valid(p)||p.id===lastID||root.AtlasPrivacy?.enabled||root.ATLAS_METRO?.workspace)return false;
   const native=root.ATLAS_PORTALS;
   if(!native||p.saveID!==native.saveID||p.world!==native.world)return false;
   lastID=p.id;current=p;card.hidden=false;
   text.textContent=(en?'Resource target':'Ressourcenziel')+` · ${p.dimension} · X ${p.x} / Y ${p.y} / Z ${p.z} · ID ${p.blockID}`;
   const dim=data.dimensions[p.dimension],covered=!!dim?.chunks?.[`${Math.floor(p.x/16)*16},${Math.floor(p.z/16)*16}`];
   button.disabled=!covered;
   status.textContent=covered?(en?'Route planning uses saved surface terrain. Any descent to the deposit remains unplanned.':'Die Route nutzt die gespeicherte Oberfläche. Ein Abstieg zur Fundstelle bleibt ungeplant.'):(en?'Outside map coverage. Generate a larger map for this backup.':'Außerhalb der Kartenabdeckung. Größere Karte für diese Sicherung erzeugen.');
   if(dim)focus(p);return true;
  }
  button.onclick=()=>{
   if(!current||root.AtlasPrivacy?.enabled)return;
   focus(current,true);measure.start();
   if(!measure.active)return;
   measure.pendingResourceTarget=current;
   status.textContent=en?'Choose your start A. B will be the saved surface above the target.':'Start A wählen. B wird die gespeicherte Oberfläche über dem Ziel.';
  };
  close.onclick=()=>{card.hidden=true;current=null;measure.pendingResourceTarget=null;};
  root.addEventListener('atlas-focus-target',e=>receive(e.detail));
  root.addEventListener('atlas-privacy',()=>{if(root.AtlasPrivacy?.enabled){card.hidden=true;current=null;measure.pendingResourceTarget=null;}});
  return {receive};
 }
 root.AtlasFocusTarget={valid,install};if(typeof module!=='undefined')module.exports=root.AtlasFocusTarget;
})(globalThis);
