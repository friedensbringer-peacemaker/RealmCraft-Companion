/* Semantic block overlays, using the same visible columns as the base map. */
(function(root){
  'use strict';
  const categories={
    paths:{de:'Wege (Pfadblöcke)',en:'Paths (path blocks)',color:'#ffd166'},
    stairs:{de:'Treppen',en:'Stairs',color:'#f78cdb'},
    rails:{de:'Schienennetze',en:'Rail networks',color:'#54e0ef'},
    ladders:{de:'Leitern',en:'Ladders',color:'#b7f36b'}
  };
  function category(name){
    if(name==='dirt_path'||name==='grass_path')return 'paths';
    if(typeof name==='string'&&name.endsWith('_stairs'))return 'stairs';
    if(['rail','powered_rail','detector_rail','activator_rail'].includes(name))return 'rails';
    if(name==='ladder')return 'ladders';
    return null;
  }
  class Overlay {
    constructor(data,layers,changed){
      this.data=data;this.layers=layers;this.cache=new Map();this.enabled=new Set();
      const english=document.documentElement.lang==='en',section=document.getElementById('transport-layers');
      const title=document.createElement('h2');title.textContent=english?'Transport networks':'Transportnetze';section.append(title);
      this.inputs=[];
      const all=document.createElement('button');all.type='button';all.className='text-button';section.append(all);
      const update=()=>{all.textContent=this.enabled.size===4?(english?'Hide all':'Alle ausblenden'):(english?'Show all':'Alle anzeigen');};
      for(const [id,info] of Object.entries(categories)){
        const label=document.createElement('label');label.className='check';
        const input=document.createElement('input');input.type='checkbox';input.dataset.transport=id;
        const swatch=document.createElement('i');swatch.className='transport-swatch';swatch.style.background=info.color;
        const name=document.createElement('span');name.textContent=info[english?'en':'de'];
        input.onchange=()=>{input.checked?this.enabled.add(id):this.enabled.delete(id);update();changed();};
        label.append(input,swatch,name);section.append(label);this.inputs.push(input);
      }
      all.onclick=()=>{const show=this.enabled.size!==4;this.enabled=new Set(show?Object.keys(categories):[]);this.inputs.forEach(i=>i.checked=show);update();changed();};update();
      const note=document.createElement('p');note.className='small muted';
      note.textContent=english?'Highlights matching blocks on the selected world level. For tunnels, choose a height slice. Decorative stairs also appear; roads made of arbitrary blocks, bridges and waterways cannot be identified reliably.':'Markiert passende Blöcke auf der gewählten Weltebene. Für Tunnel eine Höhenebene wählen. Auch dekorative Treppen erscheinen; Straßen aus beliebigen Blöcken, Brücken und Wasserwege sind nicht eindeutig erkennbar.';
      section.append(note);
      const privacyNote=document.createElement('p');privacyNote.className='small muted';privacyNote.textContent=english?'Hidden in spoiler-light mode.':'Im spoilerarmen Modus ausgeblendet.';section.append(privacyNote);
      const privacy=()=>{const hidden=!!root.AtlasPrivacy?.enabled;all.disabled=hidden;this.inputs.forEach(i=>i.disabled=hidden);privacyNote.hidden=!hidden;changed();};
      root.addEventListener('atlas-privacy',privacy);privacy();
    }
    tile(prefix,rx,rz,y,mode){
      if(!this.enabled.size||root.AtlasPrivacy?.enabled)return null;
      const key=[prefix,rx,rz,mode,mode==='surface'?'':y,[...this.enabled].sort().join(',')].join(':');
      if(this.cache.has(key))return this.cache.get(key);
      const dimension=this.data.dimensions[prefix];let chunks;
      if(mode!=='surface'){
        if(!this.layers.has(prefix,rx,rz))return null;
        chunks=this.layers.ensure(prefix,rx,rz).chunks;if(!chunks)return null;
      }
      const tile=document.createElement('canvas');tile.width=tile.height=256;
      const context=tile.getContext('2d');
      for(let cz=rz*256;cz<(rz+1)*256;cz+=16)for(let cx=rx*256;cx<(rx+1)*256;cx+=16){
        const encoded=mode==='surface'?dimension.chunks[`${cx},${cz}`]:null;
        const bytes=mode==='surface'?(encoded?Uint8Array.from(atob(encoded),c=>c.charCodeAt(0)):null):chunks.get(`${cx},${cz}`);
        if(!bytes)continue;
        for(let i=0;i<256;i++){
          const id=mode==='surface'?(bytes[i*2]|bytes[i*2+1]<<8):root.AtlasColumns.readColumn(bytes,i,y,mode).id;
          const kind=category(this.data.registry[id]);if(!this.enabled.has(kind))continue;
          context.fillStyle=categories[kind].color;context.fillRect(cx-rx*256+i%16,cz-rz*256+Math.floor(i/16),1,1);
        }
      }
      this.cache.set(key,tile);if(this.cache.size>96)this.cache.delete(this.cache.keys().next().value);
      return tile;
    }
  }
  const api={category,categories,Overlay};root.AtlasTransport=api;if(typeof module!=='undefined')module.exports=api;
})(globalThis);
