(() => {
  'use strict';
  const $=id=>document.getElementById(id), data=window.REALMCRAFT_MAP;
  if(!data || !Object.keys(data.dimensions||{}).length){$('fatal').hidden=false;return;}
  const {chunkOrigin,clamp,worldAt,screenAt,zoomAt,panBy,viewportBounds,fitView}=AtlasGeometry;
  const canvas=$('map'), area=$('map-area'), ctx=canvas.getContext('2d');
  const english=document.documentElement.lang==='en';
  function showBiome(x,z){$('biome-readout').textContent=AtlasBiomes.label(data,dimension,x,z,english);}
  const format=n=>n.toLocaleString('de-AT');
  const coordinateInput=value=>{let text=String(value||'').trim().replaceAll('−','-');if(/^-?\d{1,2}(?:[.,\s]\d{3})+$/.test(text))text=text.replace(/[.,\s]/g,'');const number=Number(text);return Number.isSafeInteger(number)?number:null;};
  let dimension=data.dimensions.o?'o':Object.keys(data.dimensions)[0], layer='terrain', vertical='surface', yLevel=64;
  let view={x:0,z:0,zoom:1,angle:0}, width=0,height=0, selected=null, frame=0;
  const images=new Map(), decoded=new Map(), pointers=new Map();
  let lastPinch=null, press=null, moved=false, storage=true, markers=[], resourceDrag=null, resourceBox=null, resourceMode=false;
  const orientationKey='realmcraft-atlas:orientation:'+data.title;
  let savedOrientation=null;
  try{const v=Number.isFinite(window.ATLAS_NATIVE_ORIENTATION?.angle)?window.ATLAS_NATIVE_ORIENTATION:JSON.parse(localStorage.getItem(orientationKey)||'null');if(v&&Number.isFinite(v.angle)&&typeof v.angle==='number'&&typeof v.flipX==='boolean'&&typeof v.flipZ==='boolean'){
    savedOrientation={angle:((Math.round(v.angle/(Math.PI/2))%4)+4)%4*(Math.PI/2),flipX:v.flipX,flipZ:v.flipZ};Object.assign(view,savedOrientation);
  }}catch{}
  const key='realmcraft-atlas:places:'+(window.ATLAS_ANNOTATION_SCOPE||data.title);
  try { const stored=window.ATLAS_NATIVE_MARKERS??JSON.parse(localStorage.getItem(key)||'[]');
    if(Array.isArray(stored)) markers=stored.filter(m=>m && typeof m.name==='string' && m.name.length<=60 && Number.isFinite(m.x)&&Number.isFinite(m.z)&&data.dimensions[m.dimension]).slice(0,1000);
  } catch {storage=false;}
  $('storage-note').hidden=storage;
  window.webkit?.messageHandlers?.atlasMarkers?.postMessage({world:data.title,markers});
  $('marker-legend').textContent=english?'◆ Gold: your places · ● Circles: automatic':'◆ Gold: eigene Orte · ● Kreise: automatisch';
  function resourceSelection(active) {
    resourceMode=active;
    $('resource-note').textContent=active?(english?'Draw an area · Esc cancels':'Bereich ziehen · Esc beendet'):(english?'Resource analysis':'Ressourcenanalyse');
    $('resource-note').setAttribute('aria-pressed',String(active));
    canvas.style.cursor=active?'crosshair':'';
  }
  resourceSelection(false);
  const names={air:'Luft',cave_air:'Höhlenluft',grass_block:'Grasblock',dirt:'Erde',water:'Wasser',lava:'Lava',stone:'Stein',sand:'Sand',gravel:'Kies',bedrock:'Grundgestein',cobblestone:'Bruchstein',oak_leaves:'Eichenlaub',birch_leaves:'Birkenlaub',spruce_leaves:'Fichtennadeln',oak_planks:'Eichenbretter',chest:'Truhe',glass:'Glas',netherrack:'Netherrack'};
  const nameFor=id=>names[data.registry[id]] || (data.registry[id]||`Unbekannter Block ${id}`).replaceAll('_',' ').replace(/^./,c=>c.toUpperCase());
  const displayName=AtlasMapPresentation.displayName(window.ATLAS_DISPLAY_NAME,data.title,'Gespeicherte Welt');
  $('world-name').textContent=displayName;
  $('world-name').title=displayName;
  $('map-source-id').textContent=data.title;
  $('saved-date').textContent='Karte erstellt '+new Date(data.generatedAt).toLocaleString('de-AT',{dateStyle:'medium',timeStyle:'short'});
  for(const option of [...$('dimension').options]) if(!data.dimensions[option.value]) option.remove();
  const requestDraw=()=>{if(!frame) frame=requestAnimationFrame(()=>{frame=0;draw();});};
  const layers=new AtlasLayers(data,requestDraw,message=>{ $('level-status').textContent=vertical==='surface'?'':message; });
  const transport=new AtlasTransport.Overlay(data,layers,requestDraw);
  const poi=new AtlasPoints(data,{changed:requestDraw,focus:p=>{showBiome(p.x,p.z);view={...view,x:p.x+.5,z:p.z+.5,zoom:Math.max(view.zoom,4)};selected=null;$('selection').hidden=true;requestDraw();}});
  const signs=new AtlasSigns(data,{changed:requestDraw,focus:s=>{showBiome(s.x,s.z);view={...view,x:s.x+.5,z:s.z+.5,zoom:Math.max(view.zoom,8)};selected=null;$('selection').hidden=true;requestDraw();}});
  const ownership=new AtlasOwnership(data,{changed:requestDraw,activated:()=>{measure.clear();selected=null;$("selection").hidden=true;pointers.clear();lastPinch=null;press=null;resourceDrag=null;resourceBox=null;resourceSelection(false);canvas.classList.remove("dragging");canvas.focus();}});
  const voxel=new AtlasVoxelViewer(data,layers);
  let showOwnPlaces=true;
  AtlasQuickControls.install(visible=>{showOwnPlaces=visible;requestDraw();},visible=>{poi.showLabels=visible;requestDraw();},visible=>{signs.focusOnly=visible;requestDraw();});
  const measure=new AtlasMeasure.Measure(data,{changed:requestDraw,activated:()=>{ownership.cancel();resourceDrag=null;resourceBox=null;resourceSelection(false);selected=null;$('selection').hidden=true;canvas.focus();}});
  AtlasNavigation.install(measure,data,()=>markers);
  const portals=new AtlasPortals.Planner(data,{changed:requestDraw,getSelected:()=>selected,focus:p=>{if(!data.dimensions[p.dimension])return;if(p.dimension!==dimension)changeDimension(p.dimension);view={...view,x:p.x+.5,z:p.z+.5,zoom:Math.max(view.zoom,4)};requestDraw();}});
  const metro=window.AtlasMetro?new AtlasMetro.Overlay(data,{changed:requestDraw,getSelected:()=>selected,focus:p=>{if(!data.dimensions[p.dimension])return;if(p.dimension!==dimension)changeDimension(p.dimension);view={...view,x:p.x+.5,z:p.z+.5,zoom:Math.max(view.zoom,3)};requestDraw();}}):{refresh(){},setDimension(){},draw(){}};
  const resourceTarget=AtlasFocusTarget.install(data,measure,(p,approach)=>{
    if(p.dimension!==dimension)changeDimension(p.dimension);
    setLevel(p.y);view={...view,x:p.x+.5,z:p.z+.5,zoom:Math.max(view.zoom,8)};
    if(approach){vertical='surface';updateLevelLabels();}
    selected={x:p.x,y:p.y,z:p.z,dimension:p.dimension,id:p.blockID};
    $('selected-name').textContent=nameFor(p.blockID);$('selected-coords').textContent=`X ${p.x}   Y ${p.y}   Z ${p.z}`;
    $('selected-biome').textContent=english?'Measured resource target':'Gemessene Fundstelle';$('selection').hidden=false;requestDraw();
  });
  const tools=new MapToolCoordinator(()=>{pointers.clear();press=null;lastPinch=null;canvas.classList.remove('dragging');});
  tools.register('measure',{active:()=>!measure.panel.hidden,cancel:()=>measure.clear()});
  tools.register('ownership',{active:()=>ownership.active,canLeave:()=>!ownership.pending,cancel:()=>ownership.cancel()});
  tools.register('resource',{active:()=>!!(resourceMode||resourceDrag||resourceBox),cancel:()=>{resourceDrag=null;resourceBox=null;resourceSelection(false);requestDraw();}});
  tools.register('portal',{active:()=>!!portals.draft||portals.pending,canLeave:()=>!portals.pending,cancel:()=>{portals.draft=null;portals.details.open=false;portals.save.disabled=true;}});
  tools.register('metro',{active:()=>!!metro.native?.capturing,cancel:()=>{
    if(metro.native?.capturing){metro.native.capturing=false;window.webkit?.messageHandlers?.atlasMetro?.postMessage({action:'cancelCapture',saveID:metro.native.saveID,world:metro.native.world});}
  }});
  const beginMeasure=measure.start?.bind(measure);
  if(beginMeasure)measure.start=()=>{if(tools.activate('measure'))beginMeasure();};
  const beginOwnership=ownership.toggle.bind(ownership);
  ownership.toggle=()=>{if(ownership.active||tools.activate('ownership'))beginOwnership();};
  const beginPortal=portals.plan.bind(portals);
  portals.plan=p=>{if(tools.activate('portal'))beginPortal(p);};
  window.addEventListener('atlas-metro-update',()=>{if(metro.native?.capturing)tools.activate('metro');});
  $('resource-note').onclick=()=>{
    if(!tools.activate('resource'))return;
    if(window.AtlasPrivacy?.enabled)return;
    const active=!resourceMode;ownership.cancel();measure.clear();resourceDrag=null;resourceBox=null;
    pointers.clear();press=null;lastPinch=null;resourceSelection(active);canvas.focus();requestDraw();
  };
  $('open-3d').onclick=()=>voxel.open({x:view.x,z:view.z,dimension});
  $('point-3d').textContent=english?'Explore here in 3D · Beta':'Hier in 3D · Beta';
  $('point-3d').onclick=()=>{if(selected)voxel.open({...selected});};
  function imageFor(url){
    let img=images.get(url);
    if(!img){img=new Image();img.onload=requestDraw;img.onerror=()=>{img.failed=true;};img.src=url;images.set(url,img);
      if(images.size>450) images.delete(images.keys().next().value);}
    return img;
  }
  function screen(x,z){return screenAt(x,z,view,width,height);}
  function draw(){
    const searchFocused=signs.isolate();
    if(searchFocused&&ownership.active&&!ownership.pending)ownership.cancel();
    $('auto-tag-notice').hidden=searchFocused||!poi.visible||!poi.filtered().some(p=>p.kind==='tag');
    const d=data.dimensions[dimension], [xmin,zmin,xmax,zmax]=d.bounds;
    const ratio=window.devicePixelRatio||1;ctx.setTransform(ratio,0,0,ratio,0,0);ctx.clearRect(0,0,width,height);
    const level=clamp(Math.floor(Math.log2(1/view.zoom)),0,d.grids.length-1), step=data.tileSize*2**level;
    const bounds=viewportBounds(view,width,height),top={x:bounds.left,z:bounds.top},bottom={x:bounds.right,z:bounds.bottom},[nx,nz]=d.grids[level];
    ctx.save();ctx.translate(width/2,height/2);ctx.scale(view.flipX?-1:1,view.flipZ?-1:1);ctx.rotate(view.angle);ctx.scale(view.zoom,view.zoom);ctx.translate(-view.x,-view.z);
    ctx.imageSmoothingEnabled=view.zoom<1;
    if(vertical==='surface') for(let tz=Math.max(0,Math.floor((top.z-zmin)/step));tz<Math.min(nz,Math.ceil((bottom.z-zmin)/step));tz++){
      for(let tx=Math.max(0,Math.floor((top.x-xmin)/step));tx<Math.min(nx,Math.ceil((bottom.x-xmin)/step));tx++){
        const img=imageFor(`tiles/${dimension}/${layer}/${level}-${tx}-${tz}.png`), p=screen(xmin+tx*step,zmin+tz*step);
        if(img.complete && img.naturalWidth) ctx.drawImage(img,xmin+tx*step,zmin+tz*step,step,step);
      }
    }
    if(vertical!=='surface'){
      for(let rz=Math.floor(top.z/256);rz<=Math.floor(bottom.z/256);rz++)for(let rx=Math.floor(top.x/256);rx<=Math.floor(bottom.x/256);rx++){
        const tile=layers.getTile(dimension,rx,rz,yLevel,vertical,layer),p=screen(rx*256,rz*256);
        if(tile)ctx.drawImage(tile,rx*256,rz*256,256,256);
      }
    }
    if(!searchFocused && transport.enabled.size && !window.AtlasPrivacy?.enabled){
      ctx.imageSmoothingEnabled=false;
      for(let rz=Math.floor(Math.max(top.z,zmin)/256);rz<=Math.floor(Math.min(bottom.z,zmax-1)/256);rz++)for(let rx=Math.floor(Math.max(top.x,xmin)/256);rx<=Math.floor(Math.min(bottom.x,xmax-1)/256);rx++){
        const tile=transport.tile(dimension,rx,rz,yLevel,vertical);
        if(tile)ctx.drawImage(tile,rx*256,rz*256,256,256);
      }
    }
    if(!searchFocused && $('grid').checked && view.zoom>=.5){
      ctx.strokeStyle='#102b3d66';ctx.lineWidth=1/view.zoom;ctx.beginPath();
      for(let x=chunkOrigin(top.x);x<=bottom.x;x+=16){ctx.moveTo(x,top.z);ctx.lineTo(x,bottom.z);}
      for(let z=chunkOrigin(top.z);z<=bottom.z;z+=16){ctx.moveTo(top.x,z);ctx.lineTo(bottom.x,z);}
      ctx.stroke();
    }
    ctx.restore();
    if(resourceBox){
      const b=resourceBox,corners=[[b.x0,b.z0],[b.x1+1,b.z0],[b.x1+1,b.z1+1],[b.x0,b.z1+1]].map(([x,z])=>screen(x,z));
      ctx.save();ctx.beginPath();corners.forEach((p,i)=>i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y));ctx.closePath();ctx.fillStyle='#f5be4d25';ctx.fill();ctx.strokeStyle='#f5be4d';ctx.lineWidth=2;ctx.setLineDash([6,4]);ctx.stroke();ctx.restore();
    }
    if(!searchFocused)poi.draw(ctx,screen,width,height);
    signs.draw(ctx,screen,width,height);
    for(const m of markers.filter(m=>!searchFocused&&showOwnPlaces&&m.dimension===dimension)){
      const p=screen(m.x+.5,m.z+.5);if(p.x<-100||p.y<-40||p.x>width+100||p.y>height+40) continue;
      ctx.beginPath();ctx.moveTo(p.x,p.y-8);ctx.lineTo(p.x+8,p.y);ctx.lineTo(p.x,p.y+8);ctx.lineTo(p.x-8,p.y);ctx.closePath();ctx.fillStyle='#ffc96b';ctx.fill();ctx.strokeStyle='#21392f';ctx.lineWidth=2;ctx.stroke();
      ctx.font='600 12px -apple-system, sans-serif';const text='◆ '+m.name, w=ctx.measureText(text).width;
      ctx.fillStyle='#112a2eea';ctx.fillRect(p.x-w/2-7,p.y-32,w+14,21);ctx.fillStyle='#ffc96b';ctx.textAlign='center';ctx.fillText(text,p.x,p.y-17);
    }
    if(!searchFocused)ownership.draw(ctx,screen,width,height);
    if(!searchFocused)metro.draw(ctx,screen,width,height);
    if(!searchFocused)portals.draw(ctx,screen,width,height);
    measure.draw(ctx,screen);
    if(!searchFocused && selected && selected.dimension===dimension){const p=screen(selected.x+.5,selected.z+.5),size=Math.max(8,view.zoom);ctx.save();ctx.translate(p.x,p.y);ctx.scale(view.flipX?-1:1,view.flipZ?-1:1);ctx.rotate(view.angle);ctx.strokeStyle='#fff4b0';ctx.lineWidth=2;ctx.strokeRect(-size/2,-size/2,size,size);ctx.restore();}
    $('compass-arrow').style.transform=`scale(${view.flipX?-1:1},${view.flipZ?-1:1}) rotate(${view.angle}rad)`;$('rotation-angle').textContent=`${Math.round(view.angle*180/Math.PI)%360}°`;$('rotation-slider').value=Math.round(view.angle*180/Math.PI)%360;
    const wanted=100/view.zoom, power=10**Math.floor(Math.log10(wanted));
    const units=[1,2,5,10].map(v=>v*power).reduce((a,b)=>Math.abs(a-wanted)<Math.abs(b-wanted)?a:b);
    $('scale-label').textContent=format(units)+(units===1?' Block':' Blöcke');$('scale-line').style.width=(units*view.zoom)+'px';
  }
  function fit(){view=fitView(data.dimensions[dimension].bounds,view,width,height);requestDraw();}
  function rotate(angle){view.angle=((Math.round(angle/(Math.PI/2))%4)+4)%4*(Math.PI/2);requestDraw();}
  function resize(){const oldWidth=width;width=area.clientWidth;height=area.clientHeight;const ratio=window.devicePixelRatio||1;canvas.width=Math.round(width*ratio);canvas.height=Math.round(height*ratio);if(!oldWidth)fit();else requestDraw();}
  function changeDimension(value){tools.cancel('dimension');measure.clear();voxel.close();ownership.setDimension(value);portals.setDimension(value);metro.setDimension(value);resourceDrag=null;resourceBox=null;resourceSelection(false);dimension=value;$('biome-readout').textContent=english?'Saved biome · point at the map':'Gespeichertes Biom · auf Karte zeigen';const d=data.dimensions[dimension];$('dimension').value=dimension;$('map-label').textContent=d.label+(dimension==='n'?' · Y ≤ 90':'');$('slice-note').hidden=dimension!=='n';$('chunk-count').textContent=format(d.count);$('block-count').textContent=(d.count*256/1e6).toLocaleString('de-AT',{maximumFractionDigits:2})+' Mio.';$('selection').hidden=true;selected=null;
    updateLevelLabels();
    $('coverage-note').textContent=(data.scope==='complete'?'Gespeicherte Welt':'Kartenausschnitt')+' · schematische Blockfarben';
    const issues=[];if(data.errors.length)issues.push(`${data.errors.length} Dateien konnten nicht gelesen werden; diese Bereiche fehlen.`);if(d.unknownIds.length)issues.push(`${d.unknownIds.length} unbekannte Blocktypen sind magenta markiert.`);$('error-note').textContent=issues.join(' ');$('error-note').hidden=!issues.length;renderMarkers();poi.setDimension(dimension);signs.setDimension(dimension);fit();}
  function blockAt(x,z){if(vertical!=='surface')return layers.lookup(dimension,x,z,yLevel,vertical);const cx=chunkOrigin(x),cz=chunkOrigin(z),chunkKey=`${cx},${cz}`,encoded=data.dimensions[dimension].chunks[chunkKey];if(!encoded)return null;
    const cacheKey=dimension+':'+chunkKey;let bytes=decoded.get(cacheKey);if(!bytes){bytes=Uint8Array.from(atob(encoded),c=>c.charCodeAt(0));decoded.set(cacheKey,bytes);if(decoded.size>100)decoded.delete(decoded.keys().next().value);}
    const index=(z-cz)*16+x-cx;return {id:bytes[index*2]|bytes[index*2+1]<<8,y:bytes[512+index]};
  }
  function pick(px,py){if(metro.workspace&&metro.pick?.(px,py,screen,()=>{const pos=worldAt(px,py,view,width,height),x=Math.floor(pos.x),z=Math.floor(pos.z),b=blockAt(x,z);return {dimension,x,z,y:b?.loading?undefined:b?.y};})){requestDraw();return;}if(measure.pick(worldAt(px,py,view,width,height),dimension))return;if(!signs.isolate()&&portals.pick(px,py,screen)){selected=null;metro.refresh();$('selection').hidden=true;requestDraw();return;}if(signs.pick(px,py,screen)){selected=null;$('selection').hidden=true;requestDraw();return;}if(!signs.isolate()&&poi.pick(px,py,screen)){$('selection').hidden=true;return;}if(window.AtlasPrivacy?.enabled)return;const pos=worldAt(px,py,view,width,height),x=Math.floor(pos.x),z=Math.floor(pos.z),block=blockAt(x,z);if(!block){selected={x,z,dimension};metro.refresh();$('selected-name').textContent=english?'Unknown terrain':'Unbekanntes Gelände';$('selected-coords').textContent=`X ${x}   Z ${z}`;$('selected-biome').textContent=english?'No saved chunk here. A portal plan does not verify this build site.':'Hier ist kein Chunk gespeichert. Ein Portalplan bestätigt keinen Bauplatz.';$('point-3d').hidden=true;$('marker-name').value='';$('selection').hidden=false;requestDraw();return;}$('point-3d').hidden=false;
    if(block.loading){$('search-message').textContent='Dieser Bereich lädt noch. Bitte kurz warten und erneut klicken.';return;}
    poi.selectChest(x,block.y,z);
    selected={x,z,dimension,...block};metro.refresh();$('selected-name').textContent=nameFor(block.id);$('selected-biome').textContent=AtlasBiomes.label(data,dimension,x,z,english);showBiome(x,z);$('selected-coords').textContent=`X ${x}   Y ${block.y}   Z ${z}`;$('marker-name').value='';$('selection').hidden=false;$('search-message').textContent='';requestDraw();}
  function saveMarkers(){window.webkit?.messageHandlers?.atlasMarkers?.postMessage({world:data.title,markers});try{localStorage.setItem(key,JSON.stringify(markers));}catch{storage=false;$('storage-note').hidden=false;}renderMarkers();requestDraw();}
  function renderMarkers(){const list=$('markers');list.replaceChildren();const visible=markers.filter(m=>m.dimension===dimension);$('marker-count').textContent=visible.length;$('empty-markers').hidden=visible.length>0;$('export-markers').hidden=markers.length===0;
    for(const m of visible){const li=document.createElement('li'),button=document.createElement('button'),name=document.createElement('strong'),coord=document.createElement('span'),del=document.createElement('button');button.className='place';name.textContent=m.name;coord.textContent=`X ${m.x} · Z ${m.z}`;button.append(name,coord);button.onclick=()=>{view={...view,x:m.x+.5,z:m.z+.5,zoom:Math.max(view.zoom,3)};document.body.classList.remove('sidebar-open');requestDraw();};del.className='delete';del.textContent='×';del.setAttribute('aria-label',m.name+' entfernen');del.onclick=()=>{markers.splice(markers.indexOf(m),1);saveMarkers();};li.append(button,del);list.append(li);}}
  function updateLevelLabels(){
    $('level-badge').textContent=`Y ${yLevel}`;$('y-slider').value=yLevel;$('y-value').value=yLevel;$('vertical-mode').value=vertical;
    $('map-label').textContent=data.dimensions[dimension].label+(vertical==='surface'?(dimension==='n'?' · Y ≤ 90':''):vertical==='slice'?` · Ebene Y ${yLevel}`:` · bis Y ${yLevel}`);
    $('slice-note').hidden=dimension!=='n'||vertical!=='surface';
    $('level-note').textContent=vertical==='surface'?'Wähle eine Ebene, um unter die Oberfläche zu schauen.':vertical==='slice'?'Nur Blöcke auf dieser Höhe. Dunkle Flächen sind Luft.':'Oberster sichtbarer Block bis zu dieser Höhe. Höhere Blöcke werden ausgeblendet.';
    if(vertical==='surface')$('level-status').textContent='';
  }
  function setLevel(value){if(window.AtlasPrivacy?.enabled)return;const parsed=Number(value);if(!Number.isFinite(parsed))return;yLevel=clamp(Math.round(parsed),0,255);if(vertical==='surface')vertical='slice';selected=null;$('selection').hidden=true;updateLevelLabels();requestDraw();}
  $('vertical-mode').onchange=e=>{if(window.AtlasPrivacy?.enabled)return;vertical=e.target.value;selected=null;$('selection').hidden=true;updateLevelLabels();requestDraw();};
  $('y-slider').oninput=e=>setLevel(e.target.value);$('y-value').onchange=e=>setLevel(e.target.value);
  document.querySelectorAll('[data-step]').forEach(button=>button.onclick=()=>setLevel(yLevel+Number(button.dataset.step)));
  $('dimension').onchange=e=>changeDimension(e.target.value);
  for(const value of ['terrain','height']) $(value).onclick=()=>{if(window.AtlasPrivacy?.enabled)return;layer=value;for(const v of ['terrain','height']){$(v).classList.toggle('active',v===value);$(v).setAttribute('aria-pressed',v===value?'true':'false');}$('legend').hidden=value==='height';requestDraw();};
  $('grid').onchange=requestDraw;
  $('mirror-title').textContent=english?'Orientation':'Ausrichtung';
  $('rotation-label').textContent=english?'Rotation':'Drehwinkel';$('rotation-slider').setAttribute('aria-label',english?'Rotation in degrees':'Drehwinkel in Grad');
  $('rotation-slider').oninput=e=>rotate(Number(e.target.value)*Math.PI/180);
  $('mirror-x-label').textContent=english?'Left ↔ right':'Links ↔ rechts';
  $('mirror-z-label').textContent=english?'Top ↔ bottom':'Oben ↔ unten';
  $('mirror-x').checked=!!view.flipX;$('mirror-z').checked=!!view.flipZ;
  $('orientation-save').textContent=english?'Save orientation':'Ausrichtung speichern';
  $('orientation-save').onclick=()=>{try{const value={angle:view.angle,flipX:!!view.flipX,flipZ:!!view.flipZ};localStorage.setItem(orientationKey,JSON.stringify(value));window.webkit?.messageHandlers?.atlasOrientation?.postMessage({world:data.title,orientation:value});savedOrientation=value;$('orientation-status').textContent=english?'Saved for next reload.':'Für das nächste Laden gespeichert.';}catch{$('orientation-status').textContent=english?'Saving failed.':'Speichern fehlgeschlagen.';}};
  $('mirror-reset').textContent=english?'Reset orientation':'Ausrichtung zurücksetzen';
  $('mirror-x').onchange=e=>{view.flipX=e.target.checked;requestDraw();};
  $('mirror-z').onchange=e=>{view.flipZ=e.target.checked;requestDraw();};
  $('mirror-reset').onclick=()=>{view.flipX=false;view.flipZ=false;view.angle=0;$('mirror-x').checked=false;$('mirror-z').checked=false;requestDraw();};
  $('zoom-in').onclick=()=>{view=zoomAt(width/2,height/2,1.7,view,width,height);requestDraw();};
  $('zoom-out').onclick=()=>{view=zoomAt(width/2,height/2,1/1.7,view,width,height);requestDraw();};
  $('compass').onclick=e=>rotate(view.angle+(e.shiftKey?-1:1)*Math.PI/2);
  $('compass').oncontextmenu=e=>{e.preventDefault();$('mirror-reset').click();};
  const rotationHelp=english?'Rotate 90° · Shift: reverse · Right-click: north · Option/Alt + scroll: rotate 90° · Q/E: rotate · R: north':'90° drehen · Umschalt: zurück · Rechtsklick: Norden · Option/Alt + Scrollen: 90° drehen · Q/E: drehen · R: Norden';
  $('compass').title=rotationHelp;$('compass').setAttribute('aria-label',rotationHelp);
  $('fit').onclick=fit;$('origin').onclick=()=>{showBiome(0,0);view={...view,x:0,z:0,zoom:3};requestDraw();};
  $('locate').onsubmit=e=>{e.preventDefault();const x=coordinateInput($('x-input').value),z=coordinateInput($('z-input').value);if(x===null||z===null){$('search-message').textContent=english?'Enter whole X and Z coordinates.':'Bitte ganze X- und Z-Koordinaten eingeben.';return;}const block=blockAt(x,z);showBiome(x,z);$('search-message').textContent=block?'': 'Kein gespeicherter Chunk an diesen Koordinaten.';view={...view,x:x+.5,z:z+.5,zoom:Math.max(view.zoom,3)};document.body.classList.remove('sidebar-open');requestDraw();};
  $('close-selection').onclick=()=>{$('selection').hidden=true;selected=null;requestDraw();};
  $('add-marker').onsubmit=e=>{e.preventDefault();const name=$('marker-name').value.trim();if(!selected||!name)return;markers.push({name,x:selected.x,z:selected.z,dimension});saveMarkers();$('selection').hidden=true;};
  $('export-markers').onclick=()=>{const url=URL.createObjectURL(new Blob([JSON.stringify({world:data.title,markers},null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='Realmcraft-Orte.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
  $('expand').onclick=()=>document.body.classList.add('sidebar-open');$('collapse').onclick=()=>document.body.classList.remove('sidebar-open');
  let rotationWheel=0,rotationWheelTime=0;
  canvas.addEventListener('wheel',e=>{e.preventDefault();if(ownership.drag)return;const r=canvas.getBoundingClientRect();if(e.altKey){const now=Date.now();if(now-rotationWheelTime>250)rotationWheel=0;rotationWheelTime=now;rotationWheel+=e.deltaY;if(Math.abs(rotationWheel)>=80){rotate(view.angle+Math.sign(rotationWheel)*Math.PI/2);rotationWheel=0;}}else view=zoomAt(e.clientX-r.left,e.clientY-r.top,Math.exp(-clamp(e.deltaY,-200,200)*.006),view,width,height);requestDraw();},{passive:false});
  const point=e=>{const r=canvas.getBoundingClientRect();return{x:e.clientX-r.left,y:e.clientY-r.top};};
  const resourceBounds=(a,b)=>({x0:Math.floor(Math.min(a.x,b.x)),x1:Math.floor(Math.max(a.x,b.x)),z0:Math.floor(Math.min(a.z,b.z)),z1:Math.floor(Math.max(a.z,b.z))});
  const sendResource=box=>{try{window.webkit?.messageHandlers?.atlasResources?.postMessage({world:data.title,dimension,x0:box.x0,x1:box.x1,z0:box.z0,z1:box.z1});}catch{}};
  canvas.onpointerdown=e=>{if(e.button!==0)return;canvas.focus();if(ownership.active){if(ownership.pending)return;const p=point(e);if(ownership.begin(e.pointerId,worldAt(p.x,p.y,view,width,height))){canvas.setPointerCapture(e.pointerId);requestDraw();}return;}if(!metro.workspace&&(e.shiftKey||resourceMode)&&!window.AtlasPrivacy?.enabled){if(!tools.activate('resource'))return;const p=point(e);resourceDrag={pointer:e.pointerId,start:worldAt(p.x,p.y,view,width,height)};resourceBox=resourceBounds(resourceDrag.start,resourceDrag.start);canvas.setPointerCapture(e.pointerId);requestDraw();return;}canvas.setPointerCapture(e.pointerId);pointers.set(e.pointerId,point(e));press=point(e);moved=false;canvas.classList.add('dragging');};
  canvas.onpointermove=e=>{const p=point(e),world=worldAt(p.x,p.y,view,width,height);$('cursor-coords').textContent=`X ${Math.floor(world.x)}   Z ${Math.floor(world.z)}`;showBiome(Math.floor(world.x),Math.floor(world.z));
    if(ownership.active){ownership.move(e.pointerId,world);return;}
    if(resourceDrag?.pointer===e.pointerId){resourceBox=resourceBounds(resourceDrag.start,world);requestDraw();return;}
    if(!pointers.has(e.pointerId))return;const prev=pointers.get(e.pointerId);pointers.set(e.pointerId,p);
    if(pointers.size===2){moved=true;const[a,b]=[...pointers.values()],distance=Math.hypot(a.x-b.x,a.y-b.y);if(lastPinch)view=zoomAt((a.x+b.x)/2,(a.y+b.y)/2,distance/lastPinch,view,width,height);lastPinch=distance;}
    else{view=panBy(p.x-prev.x,p.y-prev.y,view);if(press&&Math.hypot(p.x-press.x,p.y-press.y)>4)moved=true;}requestDraw();};
  canvas.onpointerup=e=>{const p=point(e);if(ownership.active){ownership.end(e.pointerId,worldAt(p.x,p.y,view,width,height));return;}if(resourceDrag?.pointer===e.pointerId){resourceBox=resourceBounds(resourceDrag.start,worldAt(p.x,p.y,view,width,height));resourceDrag=null;resourceSelection(false);sendResource(resourceBox);return;}if(pointers.has(e.pointerId)&&!moved&&pointers.size===1)pick(p.x,p.y);pointers.delete(e.pointerId);lastPinch=null;if(!pointers.size){canvas.classList.remove('dragging');press=null;}};
  canvas.onpointercancel=e=>{ownership.abort(e.pointerId);if(resourceDrag?.pointer===e.pointerId){resourceDrag=null;resourceBox=null;}pointers.delete(e.pointerId);lastPinch=null;moved=true;canvas.classList.remove('dragging');};
  const mapKey=e=>{if(e.key==='Escape'&&tools.cancel('escape')){requestDraw();e.preventDefault();return;}if(e.key==='Escape'&&(resourceBox||resourceMode)){resourceDrag=null;resourceBox=null;resourceSelection(false);requestDraw();e.preventDefault();return;}if(e.key==='Escape'&&!measure.panel.hidden){measure.clear();e.preventDefault();return;}if(e.key==='Escape'&&ownership.active){ownership.cancel();e.preventDefault();return;}if(ownership.drag)return;const step=80;switch(e.key){case'ArrowLeft':view=panBy(step,0,view);break;case'ArrowRight':view=panBy(-step,0,view);break;case'ArrowUp':view=panBy(0,step,view);break;case'ArrowDown':view=panBy(0,-step,view);break;case'+':case'=':view.zoom=clamp(view.zoom*1.5,.015625,32);break;case'-':view.zoom=clamp(view.zoom/1.5,.015625,32);break;case'f':case'F':fit();break;case'q':case'Q':rotate(view.angle-Math.PI/2);break;case'e':case'E':rotate(view.angle+Math.PI/2);break;case'r':case'R':$('mirror-reset').click();break;case'PageUp':setLevel(yLevel+(e.shiftKey?10:e.altKey?5:1));break;case'PageDown':setLevel(yLevel-(e.shiftKey?10:e.altKey?5:1));break;case'Escape':$('close-selection').click();break;default:return;}e.preventDefault();requestDraw();};
  canvas.onkeydown=mapKey;
  document.addEventListener('keydown',e=>{
    if(e.defaultPrevented||e.metaKey||e.ctrlKey||e.altKey||e.target.closest('input,textarea,select,[contenteditable="true"]'))return;
    if(['q','e','r','escape'].includes(e.key.toLowerCase()))mapKey(e);
  });
  function applyPrivacy() {
    const enabled=!!window.AtlasPrivacy?.enabled;
    if(enabled){tools.cancel('privacy');vertical='surface';layer='height';ownership.cancel();resourceDrag=null;resourceBox=null;resourceSelection(false);}
    selected=null;$('selection').hidden=true;poi.index=-1;
    for(const id of ['vertical-mode','y-slider','y-value','terrain','height','ownership-toggle','open-3d','point-3d'])$(id).disabled=enabled;
    $('resource-note').hidden=enabled;
    document.querySelectorAll('[data-step]').forEach(button=>button.disabled=enabled);
    for(const v of ['terrain','height']){$(v).classList.toggle('active',v===layer);$(v).setAttribute('aria-pressed',String(v===layer));}
    $('legend').hidden=layer==='height';updateLevelLabels();
    if(enabled)$('level-note').textContent=english?'Spoiler-light mode: surface elevation only. Generated terrain may still be unexplored.':'Spoilerarmer Modus: nur Oberflächenhöhe. Generierte Landschaft kann unerforscht sein.';
    poi.refresh();signs.refresh();requestDraw();
  }
  window.addEventListener('atlas-privacy',applyPrivacy);
  applyPrivacy();
  new ResizeObserver(resize).observe(area);resize();changeDimension(dimension);metro.ready?.();resourceTarget.receive(window.ATLAS_FOCUS_TARGET);
})();
