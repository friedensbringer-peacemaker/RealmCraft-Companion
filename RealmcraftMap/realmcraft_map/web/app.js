(() => {
  'use strict';
  const $=id=>document.getElementById(id), data=window.REALMCRAFT_MAP;
  if(!data || !Object.keys(data.dimensions||{}).length){$('fatal').hidden=false;return;}
  const {chunkOrigin,clamp,worldAt,zoomAt}=AtlasGeometry;
  const canvas=$('map'), area=$('map-area'), ctx=canvas.getContext('2d');
  const format=n=>n.toLocaleString('de-AT');
  let dimension=data.dimensions.o?'o':Object.keys(data.dimensions)[0], layer='terrain', vertical='surface', yLevel=64;
  let view={x:0,z:0,zoom:1}, width=0,height=0, selected=null, frame=0;
  const images=new Map(), decoded=new Map(), pointers=new Map();
  let lastPinch=null, press=null, moved=false, storage=true, markers=[];
  const key='realmcraft-atlas:places:'+data.title;
  try { const stored=JSON.parse(localStorage.getItem(key)||'[]');
    if(Array.isArray(stored)) markers=stored.filter(m=>m && typeof m.name==='string' && m.name.length<=60 && Number.isFinite(m.x)&&Number.isFinite(m.z)&&data.dimensions[m.dimension]).slice(0,1000);
  } catch {storage=false;}
  $('storage-note').hidden=storage;
  const names={air:'Luft',cave_air:'Höhlenluft',grass_block:'Grasblock',dirt:'Erde',water:'Wasser',lava:'Lava',stone:'Stein',sand:'Sand',gravel:'Kies',bedrock:'Grundgestein',cobblestone:'Bruchstein',oak_leaves:'Eichenlaub',birch_leaves:'Birkenlaub',spruce_leaves:'Fichtennadeln',oak_planks:'Eichenbretter',chest:'Truhe',glass:'Glas',netherrack:'Netherrack'};
  const nameFor=id=>names[data.registry[id]] || (data.registry[id]||`Unbekannter Block ${id}`).replaceAll('_',' ').replace(/^./,c=>c.toUpperCase());
  $('world-name').textContent=data.title;
  const imported=Object.values(data.dimensions).reduce((sum,d)=>sum+d.count,0);
  $('import-status').textContent=data.pending?.length?`Teilkarte: ${format(imported)} / ${format(data.sourceFileCount)} Chunks`:`${format(imported)} Chunks eingelesen`;
  $('saved-date').textContent='Karte erstellt '+new Date(data.generatedAt).toLocaleString('de-AT',{dateStyle:'medium',timeStyle:'short'});
  for(const option of [...$('dimension').options]) if(!data.dimensions[option.value]) option.remove();
  const requestDraw=()=>{if(!frame) frame=requestAnimationFrame(()=>{frame=0;draw();});};
  const layers=new AtlasLayers(data,requestDraw,message=>{ $('level-status').textContent=vertical==='surface'?'':message; });
  function imageFor(url){
    let img=images.get(url);
    if(!img){img=new Image();img.onload=requestDraw;img.onerror=()=>{img.failed=true;};img.src=url;images.set(url,img);
      if(images.size>450) images.delete(images.keys().next().value);}
    return img;
  }
  function screen(x,z){return {x:(x-view.x)*view.zoom+width/2,y:(z-view.z)*view.zoom+height/2};}
  function draw(){
    const d=data.dimensions[dimension], [xmin,zmin,xmax,zmax]=d.bounds;
    const ratio=window.devicePixelRatio||1;ctx.setTransform(ratio,0,0,ratio,0,0);ctx.clearRect(0,0,width,height);
    const level=clamp(Math.floor(Math.log2(1/view.zoom)),0,d.grids.length-1), step=data.tileSize*2**level;
    const top=worldAt(0,0,view,width,height), bottom=worldAt(width,height,view,width,height), [nx,nz]=d.grids[level];
    ctx.imageSmoothingEnabled=view.zoom<1;
    if(vertical==='surface') for(let tz=Math.max(0,Math.floor((top.z-zmin)/step));tz<Math.min(nz,Math.ceil((bottom.z-zmin)/step));tz++){
      for(let tx=Math.max(0,Math.floor((top.x-xmin)/step));tx<Math.min(nx,Math.ceil((bottom.x-xmin)/step));tx++){
        const img=imageFor(`tiles/${dimension}/${layer}/${level}-${tx}-${tz}.png`), p=screen(xmin+tx*step,zmin+tz*step);
        if(img.complete && img.naturalWidth) ctx.drawImage(img,p.x,p.y,step*view.zoom,step*view.zoom);
      }
    }
    if(vertical!=='surface'){
      for(let rz=Math.floor(top.z/256);rz<=Math.floor(bottom.z/256);rz++)for(let rx=Math.floor(top.x/256);rx<=Math.floor(bottom.x/256);rx++){
        const tile=layers.getTile(dimension,rx,rz,yLevel,vertical,layer),p=screen(rx*256,rz*256);
        if(tile)ctx.drawImage(tile,p.x,p.y,256*view.zoom,256*view.zoom);
      }
    }
    if($('grid').checked && view.zoom>=.5){
      ctx.strokeStyle='#102b3d66';ctx.lineWidth=1;ctx.beginPath();
      for(let x=chunkOrigin(top.x);x<=bottom.x;x+=16){const px=screen(x,0).x;ctx.moveTo(px,0);ctx.lineTo(px,height);}
      for(let z=chunkOrigin(top.z);z<=bottom.z;z+=16){const py=screen(0,z).y;ctx.moveTo(0,py);ctx.lineTo(width,py);}
      ctx.stroke();
    }
    for(const m of markers.filter(m=>m.dimension===dimension)){
      const p=screen(m.x+.5,m.z+.5);if(p.x<-100||p.y<-40||p.x>width+100||p.y>height+40) continue;
      ctx.beginPath();ctx.arc(p.x,p.y,6,0,Math.PI*2);ctx.fillStyle='#e4edb2';ctx.fill();ctx.strokeStyle='#21392f';ctx.lineWidth=2;ctx.stroke();
      ctx.font='600 12px -apple-system, sans-serif';const text=m.name, w=ctx.measureText(text).width;
      ctx.fillStyle='#112a2eea';ctx.fillRect(p.x-w/2-7,p.y-32,w+14,21);ctx.fillStyle='#eff4e4';ctx.textAlign='center';ctx.fillText(text,p.x,p.y-17);
    }
    if(selected && selected.dimension===dimension){const p=screen(selected.x,selected.z),size=Math.max(8,view.zoom);ctx.strokeStyle='#fff4b0';ctx.lineWidth=2;ctx.strokeRect(p.x,p.y,size,size);}
    const wanted=100/view.zoom, power=10**Math.floor(Math.log10(wanted));
    const units=[1,2,5,10].map(v=>v*power).reduce((a,b)=>Math.abs(a-wanted)<Math.abs(b-wanted)?a:b);
    $('scale-label').textContent=format(units)+(units===1?' Block':' Blöcke');$('scale-line').style.width=(units*view.zoom)+'px';
  }
  function fit(){const [a,b,c,d]=data.dimensions[dimension].fitBounds||data.dimensions[dimension].bounds;view={x:(a+c)/2,z:(b+d)/2,zoom:clamp(Math.min((width-90)/(c-a),(height-110)/(d-b)),.015625,32)};requestDraw();}
  function resize(){const oldWidth=width;width=area.clientWidth;height=area.clientHeight;const ratio=window.devicePixelRatio||1;canvas.width=Math.round(width*ratio);canvas.height=Math.round(height*ratio);if(!oldWidth)fit();else requestDraw();}
  function changeDimension(value){dimension=value;const d=data.dimensions[dimension];$('dimension').value=dimension;$('map-label').textContent=d.label+(dimension==='n'?' · Y ≤ 90':'');$('slice-note').hidden=dimension!=='n';$('chunk-count').textContent=format(d.count);$('block-count').textContent=(d.count*256/1e6).toLocaleString('de-AT',{maximumFractionDigits:2})+' Mio.';$('selection').hidden=true;selected=null;
    updateLevelLabels();
    $('coverage-note').textContent=(data.scope==='complete'?'Gespeicherte Welt':'Kartenausschnitt')+' · schematische Blockfarben';
    const issues=[];if(data.pending?.length)issues.push(`${format(data.pending.length)} Chunks sind noch nicht eingelesen. Dies ist eine Teilkarte.`);if(data.errors.length)issues.push(`${data.errors.length} Dateien konnten nicht gelesen werden; diese Bereiche fehlen.`);if(d.unknownIds.length)issues.push(`${d.unknownIds.length} unbekannte Blocktypen sind magenta markiert.`);$('error-note').textContent=issues.join(' ');$('error-note').hidden=!issues.length;renderMarkers();fit();}
  function blockAt(x,z){if(vertical!=='surface')return layers.lookup(dimension,x,z,yLevel,vertical);const cx=chunkOrigin(x),cz=chunkOrigin(z),chunkKey=`${cx},${cz}`,encoded=data.dimensions[dimension].chunks[chunkKey];if(!encoded)return null;
    const cacheKey=dimension+':'+chunkKey;let bytes=decoded.get(cacheKey);if(!bytes){bytes=Uint8Array.from(atob(encoded),c=>c.charCodeAt(0));decoded.set(cacheKey,bytes);if(decoded.size>100)decoded.delete(decoded.keys().next().value);}
    const index=(z-cz)*16+x-cx;return {id:bytes[index*2]|bytes[index*2+1]<<8,y:bytes[512+index]};
  }
  function pick(px,py){const pos=worldAt(px,py,view,width,height),x=Math.floor(pos.x),z=Math.floor(pos.z),block=blockAt(x,z);if(!block){$('search-message').textContent='An dieser Stelle ist kein Chunk in der Karte gespeichert.';return;}
    if(block.loading){$('search-message').textContent='Dieser Bereich lädt noch. Bitte kurz warten und erneut klicken.';return;}
    selected={x,z,dimension,...block};$('selected-name').textContent=nameFor(block.id);$('selected-coords').textContent=`X ${x}   Y ${block.y}   Z ${z}`;$('marker-name').value='';$('selection').hidden=false;$('search-message').textContent='';requestDraw();}
  function saveMarkers(){try{localStorage.setItem(key,JSON.stringify(markers));}catch{storage=false;$('storage-note').hidden=false;}renderMarkers();requestDraw();}
  function renderMarkers(){const list=$('markers');list.replaceChildren();const visible=markers.filter(m=>m.dimension===dimension);$('marker-count').textContent=visible.length;$('empty-markers').hidden=visible.length>0;$('export-markers').hidden=markers.length===0;
    for(const m of visible){const li=document.createElement('li'),button=document.createElement('button'),name=document.createElement('strong'),coord=document.createElement('span'),del=document.createElement('button');button.className='place';name.textContent=m.name;coord.textContent=`X ${m.x}${Number.isInteger(m.y)?' · Y '+m.y:''} · Z ${m.z}`;button.append(name,coord);button.onclick=()=>{if(Number.isInteger(m.level)){yLevel=clamp(m.level,0,255);vertical=['slice','below'].includes(m.vertical)?m.vertical:'surface';updateLevelLabels();}view={x:m.x+.5,z:m.z+.5,zoom:Math.max(view.zoom,3)};document.body.classList.remove('sidebar-open');requestDraw();};del.className='delete';del.textContent='×';del.setAttribute('aria-label',m.name+' entfernen');del.onclick=()=>{markers.splice(markers.indexOf(m),1);saveMarkers();};li.append(button,del);list.append(li);}}
  function updateLevelLabels(){
    $('level-badge').textContent=`Y ${yLevel}`;$('y-slider').value=yLevel;$('y-value').value=yLevel;$('vertical-mode').value=vertical;
    $('map-label').textContent=data.dimensions[dimension].label+(vertical==='surface'?(dimension==='n'?' · Y ≤ 90':''):vertical==='slice'?` · Ebene Y ${yLevel}`:` · bis Y ${yLevel}`);
    $('slice-note').hidden=dimension!=='n'||vertical!=='surface';
    $('level-note').textContent=vertical==='surface'?'Wähle eine Ebene, um unter die Oberfläche zu schauen.':vertical==='slice'?'Nur Blöcke auf dieser Höhe. Dunkle Flächen sind Luft.':'Oberster sichtbarer Block bis zu dieser Höhe. Höhere Blöcke werden ausgeblendet.';
    if(vertical==='surface')$('level-status').textContent='';
  }
  function setLevel(value){const parsed=Number(value);if(!Number.isFinite(parsed))return;yLevel=clamp(Math.round(parsed),0,255);if(vertical==='surface')vertical='slice';selected=null;$('selection').hidden=true;updateLevelLabels();requestDraw();}
  $('vertical-mode').onchange=e=>{vertical=e.target.value;selected=null;$('selection').hidden=true;updateLevelLabels();requestDraw();};
  $('y-slider').oninput=e=>setLevel(e.target.value);$('y-value').onchange=e=>setLevel(e.target.value);
  document.querySelectorAll('[data-step]').forEach(button=>button.onclick=()=>setLevel(yLevel+Number(button.dataset.step)));
  $('dimension').onchange=e=>changeDimension(e.target.value);
  for(const value of ['terrain','height']) $(value).onclick=()=>{layer=value;for(const v of ['terrain','height']){$(v).classList.toggle('active',v===value);$(v).setAttribute('aria-pressed',v===value?'true':'false');}$('legend').hidden=value==='height';requestDraw();};
  $('grid').onchange=requestDraw;
  $('zoom-in').onclick=()=>{view=zoomAt(width/2,height/2,1.7,view,width,height);requestDraw();};
  $('zoom-out').onclick=()=>{view=zoomAt(width/2,height/2,1/1.7,view,width,height);requestDraw();};
  $('fit').onclick=fit;$('origin').onclick=()=>{view={x:0,z:0,zoom:3};requestDraw();};
  $('locate').onsubmit=e=>{e.preventDefault();const x=Number($('x-input').value),z=Number($('z-input').value);if(!Number.isSafeInteger(x)||!Number.isSafeInteger(z))return;const block=blockAt(x,z);$('search-message').textContent=block?'': 'Kein gespeicherter Chunk an diesen Koordinaten.';view={x:x+.5,z:z+.5,zoom:Math.max(view.zoom,3)};document.body.classList.remove('sidebar-open');requestDraw();};
  $('close-selection').onclick=()=>{$('selection').hidden=true;selected=null;requestDraw();};
  $('add-marker').onsubmit=e=>{e.preventDefault();const name=$('marker-name').value.trim();if(!selected||!name)return;markers.push({name,x:selected.x,y:selected.y,z:selected.z,dimension,level:yLevel,vertical});saveMarkers();$('selection').hidden=true;};
  $('export-markers').onclick=()=>{const url=URL.createObjectURL(new Blob([JSON.stringify({world:data.title,markers},null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='Realmcraft-Orte.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
  $('expand').onclick=()=>document.body.classList.add('sidebar-open');$('collapse').onclick=()=>document.body.classList.remove('sidebar-open');
  canvas.addEventListener('wheel',e=>{e.preventDefault();const r=canvas.getBoundingClientRect();view=zoomAt(e.clientX-r.left,e.clientY-r.top,Math.exp(-clamp(e.deltaY,-200,200)*.006),view,width,height);requestDraw();},{passive:false});
  const point=e=>{const r=canvas.getBoundingClientRect();return{x:e.clientX-r.left,y:e.clientY-r.top};};
  canvas.onpointerdown=e=>{if(e.button!==0)return;canvas.setPointerCapture(e.pointerId);pointers.set(e.pointerId,point(e));press=point(e);moved=false;canvas.classList.add('dragging');};
  canvas.onpointermove=e=>{const p=point(e),world=worldAt(p.x,p.y,view,width,height);$('cursor-coords').textContent=`X ${Math.floor(world.x)}   Z ${Math.floor(world.z)}`;
    if(!pointers.has(e.pointerId))return;const prev=pointers.get(e.pointerId);pointers.set(e.pointerId,p);
    if(pointers.size===2){moved=true;const[a,b]=[...pointers.values()],distance=Math.hypot(a.x-b.x,a.y-b.y);if(lastPinch)view=zoomAt((a.x+b.x)/2,(a.y+b.y)/2,distance/lastPinch,view,width,height);lastPinch=distance;}
    else{view.x-=(p.x-prev.x)/view.zoom;view.z-=(p.y-prev.y)/view.zoom;if(press&&Math.hypot(p.x-press.x,p.y-press.y)>4)moved=true;}requestDraw();};
  canvas.onpointerup=e=>{const p=point(e);if(pointers.has(e.pointerId)&&!moved&&pointers.size===1)pick(p.x,p.y);pointers.delete(e.pointerId);lastPinch=null;if(!pointers.size){canvas.classList.remove('dragging');press=null;}};
  canvas.onpointercancel=e=>{pointers.delete(e.pointerId);lastPinch=null;moved=true;canvas.classList.remove('dragging');};
  canvas.onkeydown=e=>{const step=80/view.zoom;switch(e.key){case'ArrowLeft':view.x-=step;break;case'ArrowRight':view.x+=step;break;case'ArrowUp':view.z-=step;break;case'ArrowDown':view.z+=step;break;case'+':case'=':view.zoom=clamp(view.zoom*1.5,.015625,32);break;case'-':view.zoom=clamp(view.zoom/1.5,.015625,32);break;case'f':case'F':fit();break;case'PageUp':setLevel(yLevel+(e.shiftKey?10:e.altKey?5:1));break;case'PageDown':setLevel(yLevel-(e.shiftKey?10:e.altKey?5:1));break;case'Escape':$('close-selection').click();break;default:return;}e.preventDefault();requestDraw();};
  new ResizeObserver(resize).observe(area);resize();changeDimension(dimension);
})();
