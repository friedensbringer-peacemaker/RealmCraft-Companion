/* Simplified local 3D preview; no external libraries or network services. */
(() => {
'use strict';
const en=document.documentElement.lang==='en',t=(de,english)=>en?english:de;
class AtlasVoxelViewer {
 constructor(data,layers){
  this.data=data;this.layers=layers;this.keys=new Set();this.n=128;this.h=256;this.ticket=0;
  const el=(tag,text,cls)=>{const e=document.createElement(tag);if(text)e.textContent=text;if(cls)e.className=cls;return e;};
  this.panel=el('section','','voxel-panel');this.panel.hidden=true;this.panel.setAttribute('aria-label','3D · Beta');
  const bar=el('div','','voxel-bar');bar.append(el('strong','3D · Beta'));
  this.orbit=el('button',t('Übersicht','Overview'));this.eye=el('button',t('Umhergehen','Walk'));this.fly=el('button',t('Fliegen','Fly'));this.recenter=el('button',t('Umgebung hier laden','Load area here'));const close=el('button',t('Zurück zur Karte','Back to map'));
  for(const b of [this.orbit,this.eye,this.fly,this.recenter,close]){b.type='button';bar.append(b);}
  const areaLabel=el('label',t('Bereich ', 'Area '));this.area=el('select');this.area.setAttribute('aria-label',t('3D-Bereich','3D area'));
  for(const size of [64,128,256]){const option=el('option',`${size} × ${size}`);option.value=size;this.area.append(option);}this.area.value=this.n;areaLabel.append(this.area);bar.insertBefore(areaLabel,this.recenter);
  this.area.onchange=()=>{this.n=Number(this.area.value);this.recenter.click();};
  this.status=el('p','','voxel-status');this.status.setAttribute('role','status');this.canvas=el('canvas','','voxel-canvas');this.canvas.tabIndex=0;this.canvas.setAttribute('aria-label',t('3D-Welt. Ziehen zum Umschauen. WASD oder Pfeiltasten zum Gehen, Leertaste zum Springen, C zum Kriechen; im Flugmodus Q und E für die Höhe. Escape zum Schließen.','3D world. Drag to look around. WASD or arrows to walk, Space to jump, C to crawl; Q and E for altitude in flight mode. Escape to close.'));
  this.hint=el('p',t('Vereinfachte Blöcke · Wasser und Glas sind undurchsichtig · Keine Spielfiguren','Simplified cubes · Water and glass are opaque · No characters'),'voxel-hint');
  this.controls=el('div','','voxel-controls');
  for(const [key,label]of [['w',t('↑ Vorwärts','↑ Forward')],['s',t('↓ Zurück','↓ Back')],['a',t('← Links','← Left')],['d',t('Rechts →','Right →')],['j','↶'],['l','↷'],['i',t('Blick ↑','Look ↑')],['k',t('Blick ↓','Look ↓')],[' ',t('Springen ␣','Jump ␣')],['c',t('Kriechen C','Crawl C')]]){
   const b=el('button',label);b.type='button';b.setAttribute('aria-label',({j:t('Nach links schauen','Look left'),l:t('Nach rechts schauen','Look right')})[key]||label);
   b.onpointerdown=e=>{e.preventDefault();if(this.mode==='orbit')this.setMode('walk');this.canvas.focus();b.setPointerCapture(e.pointerId);this.keys.add(key);this.nudge(key);};
   b.onpointerup=b.onpointercancel=b.onlostpointercapture=()=>this.keys.delete(key);this.controls.append(b);
  }
  this.panel.append(bar,this.status,this.canvas,this.controls,this.hint);document.getElementById('map-area').append(this.panel);
  close.onclick=()=>this.close();this.orbit.onclick=()=>this.setMode('orbit');this.eye.onclick=()=>this.setMode('walk');this.fly.onclick=()=>this.setMode('fly');this.recenter.onclick=()=>this.open({x:this.originX+this.camera[0],z:this.originZ+this.camera[2],eyeY:this.camera[1]+(this.motion?.crawl?1.15:0),dimension:this.dimension,mode:this.mode});
  this.canvas.onpointerdown=e=>{if(e.button!==0)return;this.canvas.focus();this.drag=[e.clientX,e.clientY];this.canvas.setPointerCapture(e.pointerId);};
  this.canvas.onpointermove=e=>{if(!this.drag)return;this.yaw-=(e.clientX-this.drag[0])*.008;this.pitch=Math.max(-1.45,Math.min(1.45,this.pitch+(e.clientY-this.drag[1])*.008));this.drag=[e.clientX,e.clientY];};
  this.canvas.onpointerup=this.canvas.onpointercancel=()=>this.drag=null;
  this.canvas.addEventListener('wheel',e=>{e.preventDefault();if(this.mode==='orbit')this.distance=Math.max(8,Math.min(this.n*4,this.distance*Math.exp(e.deltaY*.002)));},{passive:false});
  const keyFor=e=>({ArrowUp:'w',ArrowDown:'s',ArrowLeft:'a',ArrowRight:'d'})[e.key]||e.key.toLowerCase();
  this.panel.addEventListener('keydown',e=>{e.stopPropagation();if(e.target===this.area)return;if(e.key==='Escape'){this.close();return;}const key=keyFor(e);if(['w','a','s','d','q','e','shift','i','j','k','l',' ','c'].includes(key)){e.preventDefault();if(this.mode==='orbit')this.setMode('walk');this.keys.add(key);if(!e.repeat)this.nudge(key);}});
  this.panel.addEventListener('keyup',e=>{e.stopPropagation();this.keys.delete(keyFor(e));});this.canvas.onblur=()=>this.keys.clear();
  window.addEventListener('blur',()=>this.keys.clear());
  window.addEventListener('atlas-privacy',()=>{if(window.AtlasPrivacy?.enabled)this.close();});
 }
 initGL(){
  if(this.gl)return;const gl=this.canvas.getContext('webgl',{antialias:true,alpha:false});if(!gl)throw new Error(t('3D wird auf diesem Gerät nicht unterstützt. Die 2D-Karte bleibt verfügbar.','3D is unavailable on this device. The 2D map is still available.'));this.gl=gl;
  const shader=(type,src)=>{const s=gl.createShader(type);gl.shaderSource(s,src);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw new Error(gl.getShaderInfoLog(s));return s;};
  const p=gl.createProgram();gl.attachShader(p,shader(gl.VERTEX_SHADER,'attribute vec3 pos;attribute vec3 color;uniform mat4 mvp;varying vec3 rgb;void main(){gl_Position=mvp*vec4(pos,1.);rgb=color;}'));gl.attachShader(p,shader(gl.FRAGMENT_SHADER,'precision mediump float;varying vec3 rgb;void main(){gl_FragColor=vec4(rgb,1.);}'));gl.linkProgram(p);if(!gl.getProgramParameter(p,gl.LINK_STATUS))throw new Error('3D shader link failed');gl.useProgram(p);this.program=p;this.buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,this.buffer);
  for(const [name,offset]of [['pos',0],['color',12]]){const a=gl.getAttribLocation(p,name);gl.enableVertexAttribArray(a);gl.vertexAttribPointer(a,3,gl.FLOAT,false,24,offset);}
  gl.enable(gl.DEPTH_TEST);gl.clearColor(.15,.23,.28,1);this.uniform=gl.getUniformLocation(p,'mvp');
  this.canvas.addEventListener('webglcontextlost',e=>{e.preventDefault();this.status.textContent=t('3D-Grafik unterbrochen. Karte erneut öffnen.','3D graphics interrupted. Reopen the map.');cancelAnimationFrame(this.frame);});
 }
 open(point){
  if(window.AtlasPrivacy?.enabled)return;
  this.returnFocus=document.activeElement;this.panel.hidden=false;this.panel.setAttribute('aria-busy','true');this.dimension=point.dimension;this.point=point;
  this.originX=Math.floor(point.x)-this.n/2;this.originZ=Math.floor(point.z)-this.n/2;this.camera=[this.n/2,80,this.n/2];this.motion={vy:0,crawl:false};this.crawling=false;this.jumpPending=false;this.ready=false;this.count=0;this.keys.clear();this.ticket++;
  try{this.initGL();}catch(e){this.status.textContent=e.message;return;}
  this.status.textContent=t('Gespeicherte Umgebung wird geladen …','Loading saved surroundings …');
  this.setMode(point.mode||'orbit');this.canvas.focus();this.last=performance.now();cancelAnimationFrame(this.frame);this.tick(this.last);const ticket=this.ticket;this.load(ticket).catch(()=>{if(ticket===this.ticket){this.panel.setAttribute('aria-busy','false');this.status.textContent=t('Dieser Ausschnitt konnte nicht aufgebaut werden. Bitte einen kleineren 3D-Bereich wählen.','Could not build this area. Try a smaller 3D area.');}});
 }
 async load(ticket){
  const entries=[];for(let rz=Math.floor(this.originZ/256);rz<=Math.floor((this.originZ+this.n-1)/256);rz++)for(let rx=Math.floor(this.originX/256);rx<=Math.floor((this.originX+this.n-1)/256);rx++)if(this.layers.has(this.dimension,rx,rz))entries.push(this.layers.ensure(this.dimension,rx,rz));
  const start=performance.now();while(entries.some(e=>!e.chunks&&!e.error)){
   await new Promise(resolve=>setTimeout(resolve,60));if(ticket!==this.ticket||this.panel.hidden)return;
   if(performance.now()-start>20000){this.status.textContent=t('Laden dauert zu lange. Zur Karte zurückkehren und erneut versuchen.','Loading timed out. Return to the map and try again.');return;}
  }
  if(ticket!==this.ticket)return;
  const n=this.n,blocks=new Uint16Array(n*n*this.h);let columns=0;
  for(let z=0;z<n;z++){if(z%8===0){await new Promise(r=>setTimeout(r,0));if(ticket!==this.ticket||this.panel.hidden)return;}for(let x=0;x<n;x++){
   const wx=this.originX+x,wz=this.originZ+z,cx=Math.floor(wx/16)*16,cz=Math.floor(wz/16)*16;
   const e=this.layers.entries.get(`${this.dimension}:${Math.floor(wx/256)},${Math.floor(wz/256)}`),bytes=e?.chunks?.get(`${cx},${cz}`);if(!bytes)continue;columns++;
   const dv=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength),i=(wz-cz)*16+wx-cx,first=dv.getUint32(i*4,true),end=dv.getUint32((i+1)*4,true);
   for(let run=first;run<end;run++){const y=bytes[1028+run*3],until=run+1<end?bytes[1028+(run+1)*3]:256,id=dv.getUint16(1028+run*3+1,true);for(let h=y;h<until;h++)blocks[(h*n+z)*n+x]=id;}
  }
  }
  this.blocks=blocks;this.clearBuffers();let total=0;
  for(let z=0;z<n;z+=4){
   await new Promise(r=>setTimeout(r,0));if(ticket!==this.ticket||this.panel.hidden)return;
   this.status.textContent=t('3D wird aufgebaut','Building 3D')+` · ${n} × ${n} · ${Math.round(z/n*100)}%`;
   const mesh=AtlasVoxelCore.mesh(blocks,n,this.h,this.data.palette,z,Math.min(n,z+4));total+=mesh.byteLength;
   if(total>192*1024*1024){this.clearBuffers();throw new Error('geometry budget');}
   const buffer=this.gl.createBuffer();this.gl.bindBuffer(this.gl.ARRAY_BUFFER,buffer);this.gl.bufferData(this.gl.ARRAY_BUFFER,mesh,this.gl.STATIC_DRAW);this.buffers.push({buffer,count:mesh.length/6});
  }
  let y=255;while(y>0&&AtlasVoxelCore.air(blocks[(y*n+n/2)*n+n/2]))y--;
  this.ground=Number.isFinite(this.point.eyeY)?this.point.eyeY-1.7:Number.isFinite(this.point.y)?this.point.y+1:y+1;this.camera=[n/2+.5,this.ground+1.7,n/2+.5];this.target=[n/2+.5,this.ground,n/2+.5];this.ready=true;this.panel.setAttribute('aria-busy','false');
  this.warning=columns===0?t('Hier sind keine Chunks gespeichert.','No saved chunks here.'):entries.some(e=>e.error)?t('Einige Bereiche konnten nicht geladen werden.','Some areas could not be loaded.'):columns<n*n?t('Nicht gespeicherte Bereiche fehlen.','Unsaved areas are missing.') : '';
 }
 clearBuffers(){for(const item of this.buffers||[])this.gl.deleteBuffer(item.buffer);this.buffers=[];}
 nudge(key){
  if(!this.ready)return;
  if(key===' '){this.jumpPending=true;return;}if(key==='c'){this.crawling=!this.crawling;return;}
  if(key==='j'||key==='l')this.yaw+=(key==='j'?1:-1)*.12;
  if(key==='i'||key==='k')this.pitch=Math.max(-1.45,Math.min(1.45,this.pitch+(key==='i'?-1:1)*.1));
  const f=Number(key==='w')-Number(key==='s'),side=Number(key==='d')-Number(key==='a'),dx=.3*(Math.sin(this.yaw)*f-Math.cos(this.yaw)*side),dz=.3*(Math.cos(this.yaw)*f+Math.sin(this.yaw)*side);
  if(this.mode==='walk')this.camera=AtlasVoxelCore.move(this.blocks,this.n,this.h,this.camera,this.motion||(this.motion={}),dx,dz,0,this.crawling);
  else if(this.mode==='fly'){this.camera[0]+=dx;this.camera[2]+=dz;this.camera[1]+=.3*(Number(key==='e')-Number(key==='q'));}
 }
 setMode(mode){if(this.mode!==mode&&this.motion){if(this.motion.crawl)this.camera[1]+=1.15;this.motion={vy:0,crawl:false};this.crawling=false;this.jumpPending=false;}this.mode=mode;this.yaw=Math.PI;this.pitch=mode==='orbit'?.6:0;this.distance=this.n*1.3;this.keys.clear();this.orbit.setAttribute('aria-pressed',String(mode==='orbit'));this.eye.setAttribute('aria-pressed',String(mode==='walk'));this.fly.setAttribute('aria-pressed',String(mode==='fly'));this.controls.hidden=mode==='orbit';this.canvas.focus();}
 tick(now){
  if(this.panel.hidden)return;this.frame=requestAnimationFrame(t=>this.tick(t));const dt=Math.min(.05,(now-this.last)/1000);this.last=now;
  const w=this.canvas.clientWidth,h=this.canvas.clientHeight;if(!w||!h)return;const ratio=Math.min(2,window.devicePixelRatio||1);if(this.canvas.width!==Math.round(w*ratio)||this.canvas.height!==Math.round(h*ratio)){this.canvas.width=Math.round(w*ratio);this.canvas.height=Math.round(h*ratio);this.gl.viewport(0,0,this.canvas.width,this.canvas.height);}
  this.gl.clear(this.gl.COLOR_BUFFER_BIT|this.gl.DEPTH_BUFFER_BIT);if(!this.ready)return;
  this.yaw+=dt*1.6*(Number(this.keys.has('j'))-Number(this.keys.has('l')));this.pitch=Math.max(-1.45,Math.min(1.45,this.pitch+dt*(Number(this.keys.has('k'))-Number(this.keys.has('i')))));
  const dir=[Math.sin(this.yaw)*Math.cos(this.pitch),-Math.sin(this.pitch),Math.cos(this.yaw)*Math.cos(this.pitch)];let eye,target;
  if(this.mode==='orbit'){target=this.target;eye=target.map((v,i)=>v-dir[i]*this.distance);}else{
   const speed=dt*(this.mode==='walk'?(this.motion?.crawl?1.3:this.keys.has('shift')?7:4):(this.keys.has('shift')?20:7)),forward=Number(this.keys.has('w'))-Number(this.keys.has('s')),side=Number(this.keys.has('d'))-Number(this.keys.has('a'));
   const length=Math.max(1,Math.hypot(forward,side)),dx=speed*(Math.sin(this.yaw)*forward-Math.cos(this.yaw)*side)/length,dz=speed*(Math.cos(this.yaw)*forward+Math.sin(this.yaw)*side)/length;
   if(this.mode==='walk'){this.camera=AtlasVoxelCore.move(this.blocks,this.n,this.h,this.camera,this.motion,dx,dz,dt,this.crawling,this.jumpPending);this.jumpPending=false;}
   else{this.camera[0]+=dx;this.camera[2]+=dz;this.camera[1]+=speed*(Number(this.keys.has('e'))-Number(this.keys.has('q')));}
   this.camera[0]=Math.max(.25,Math.min(this.n-.25,this.camera[0]));this.camera[2]=Math.max(.25,Math.min(this.n-.25,this.camera[2]));this.camera[1]=Math.max(.2,Math.min(290,this.camera[1]));eye=this.camera;target=eye.map((v,i)=>v+dir[i]);
  }
  this.gl.uniformMatrix4fv(this.uniform,false,AtlasVoxelCore.matrix(eye,target,w/h));for(const item of this.buffers||[]){this.gl.bindBuffer(this.gl.ARRAY_BUFFER,item.buffer);for(const [name,offset]of [['pos',0],['color',12]])this.gl.vertexAttribPointer(this.gl.getAttribLocation(this.program,name),3,this.gl.FLOAT,false,24,offset);this.gl.drawArrays(this.gl.TRIANGLES,0,item.count);}
  const status=(this.mode==='orbit'?t('Ziehen: drehen · Scrollen: Abstand','Drag: rotate · Scroll: distance'):this.mode==='walk'?t('Maus ziehen: umsehen · WASD / Pfeiltasten: gehen · Leertaste: springen · C: kriechen/aufstehen · Umschalt: schneller','Drag mouse: look · WASD / arrows: walk · Space: jump · C: crawl/stand · Shift: faster'):t('Ziehen: umsehen · WASD: frei fliegen · Q/E: Höhe · Ohne Kollision','Drag: look · WASD: fly freely · Q/E: altitude · No collision'))+` · ${this.n} × ${this.n}${this.motion?.crawl?t(" · Kriechen"," · Crawling"):""} · X ${Math.floor(this.originX+this.camera[0])} Y ${Math.floor(this.camera[1])} Z ${Math.floor(this.originZ+this.camera[2])} · ${this.warning||''}`;if(this.status.textContent!==status)this.status.textContent=status;
 }
 close(){this.clearBuffers();this.blocks=null;this.panel.hidden=true;this.ticket++;this.keys.clear();cancelAnimationFrame(this.frame);this.returnFocus?.focus();}
}
window.AtlasVoxelViewer=AtlasVoxelViewer;
})();
