const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),test=require('node:test');
const root=require('node:path').join(__dirname,'../Resources/MapEngine/realmcraft_map/web/');
const geometry=require(root+'geometry.js');
test('all orientations preserve coordinate round trips and zoom anchor',()=>{
 for(const flipX of [false,true])for(const flipZ of [false,true]){
  for(const angle of [0,.7,Math.PI/2,3.2]) { const view={x:-53,z:10,zoom:3,flipX,flipZ,angle};
  for(const [x,z] of [[-53.5,10.5],[-64,128],[96,-42]]){
   const p=geometry.screenAt(x,z,view,900,600),w=geometry.worldAt(p.x,p.y,view,900,600);assert.ok(Math.abs(w.x-x)<1e-10);assert.ok(Math.abs(w.z-z)<1e-10);
   const next=geometry.zoomAt(p.x,p.y,1.7,view,900,600),anchor=geometry.worldAt(p.x,p.y,next,900,600);assert.ok(Math.abs(anchor.x-x)<1e-10);assert.ok(Math.abs(anchor.z-z)<1e-10);
  }
 }}
});
test('map toggles reflect terrain, marker positions, cursor and compass together',()=>{
 const elements=new Map(),classes={add(){},remove(){},toggle(){}},scales=[],tiles=[],resourceRequests=[];let drawCallback,screen;const events={};
 const ctx=new Proxy({scale:(x,y)=>scales.push([x,y]),drawImage:(...args)=>tiles.push(args)}, {get:(o,k)=>o[k]||(()=>{})});
 const get=id=>{if(!elements.has(id))elements.set(id,{value:'',options:[{value:'o',remove(){}}],classList:classes,style:{},clientWidth:1000,clientHeight:700,append(){},replaceChildren(){},setAttribute(k,v){this[k]=v},addEventListener(){},getContext(){return ctx},getBoundingClientRect(){return{left:0,top:0}},setPointerCapture(){},focus(){}});return elements.get(id)};
 const element=()=>({style:{},dataset:{},classList:classes,append(){},setAttribute(){},scrollIntoView(){},addEventListener(){}});
 const context=vm.createContext({document:{createElement:element,addEventListener(){},documentElement:{lang:'de',classList:classes},getElementById:get,querySelectorAll:()=>[],body:{classList:classes}},localStorage:{getItem:()=>null,setItem(){}},requestAnimationFrame:cb=>{drawCallback=cb;return 1},ResizeObserver:class{observe(){}},AtlasLayers:class{getTile(){return {}}},AtlasBiomes:{label:()=>''},AtlasQuickControls:{install(){}},AtlasMeasure:{Measure:class{panel={hidden:true};clear(){this.panel.hidden=true;}draw(){}pick(){return false;}}},AtlasNavigation:{install(){}},AtlasVoxelViewer:class{open(){}close(){}},AtlasSigns:class{isolate(){return false;}refresh(){}pick(){return false;}setDimension(){}draw(){}},AtlasPoints:class{refresh(){}pick(){return false;}setDimension(){}draw(ctx,s){screen=s}},Image:class{complete=true;naturalWidth=256},setTimeout});
 context.window=context;context.addEventListener=(name,fn)=>{const previous=events[name];events[name]=e=>{previous?.(e);fn(e);};};context.dispatchEvent=e=>events[e.type]?.(e);context.Event=class{constructor(type){this.type=type;}};context.webkit={messageHandlers:{atlasOwnership:{postMessage(){}},atlasResources:{postMessage:v=>resourceRequests.push(v)}}};context.REALMCRAFT_MAP={title:'test',generatedAt:'2026-09-05',tileSize:256,scope:'complete',errors:[],registry:{},dimensions:{o:{label:'Oberwelt',count:1,bounds:[0,0,16,16],grids:[[1,1]],chunks:{},unknownIds:[],chests:{'2,0,3':{},'8,255,8':{},'9,64,9':{}}}}};
 for(const file of ['geometry.js','map-presentation.js','focus-target.js','tool-coordinator.js','privacy.js','ownership.js','transport.js','portals.js','metro.js','app.js'])vm.runInContext(fs.readFileSync(root+file,'utf8'),context);
 const draw=()=>{const cb=drawCallback;drawCallback=null;cb();};draw();const original=screen(10,12);assert.ok(tiles.length>0);
 get('mirror-x').onchange({target:{checked:true}});get('mirror-z').onchange({target:{checked:true}});draw();const mirrored=screen(10,12);assert.equal(mirrored.x,1000-original.x);assert.equal(mirrored.y,700-original.y);assert.ok(scales.some(s=>s[0]===-1&&s[1]===-1));assert.ok(get('compass-arrow').style.transform.includes('scale(-1,-1)'));
 get('map').onpointermove({clientX:mirrored.x,clientY:mirrored.y,pointerId:1});assert.equal(get('cursor-coords').textContent,'X 10   Z 12');
 get('vertical-mode').onchange({target:{value:'slice'}});draw();assert.ok(scales.some(s=>s[0]===-1&&s[1]===-1));
 get('map').onpointerdown({button:0,clientX:500,clientY:350,pointerId:1});get('map').onpointermove({clientX:540,clientY:370,pointerId:1});draw();assert.equal(screen(10,12).x,mirrored.x+40);assert.equal(screen(10,12).y,mirrored.y+20);
 get('map').onkeydown({key:'ArrowRight',preventDefault(){}});draw();assert.equal(screen(10,12).x,mirrored.x-40);
 get('rotation-slider').oninput({target:{value:'130'}});draw();assert.equal(get('rotation-angle').textContent,'90°');get('map').onkeydown({key:'e',preventDefault(){}});draw();assert.equal(get('rotation-angle').textContent,'180°');get('orientation-save').onclick();assert.match(get('orientation-status').textContent,/gespeichert/);
 get('mirror-reset').onclick();draw();assert.ok(get('compass-arrow').style.transform.includes('scale(1,1)'));
 const first=screen(2.1,3.1),last=screen(7.9,8.9);
 get('map').onpointerdown({button:0,shiftKey:true,clientX:first.x,clientY:first.y,pointerId:9});
 get('map').onpointermove({clientX:last.x,clientY:last.y,pointerId:9});
 get('map').onpointerup({clientX:last.x,clientY:last.y,pointerId:9});
 assert.equal(resourceRequests.length,1);assert.equal(JSON.stringify(resourceRequests[0]),JSON.stringify({world:'test',dimension:'o',x0:2,x1:7,z0:3,z1:8}));
 get('resource-note').onclick();assert.equal(get('resource-note')['aria-pressed'],'true');
 get('map').onpointerdown({button:0,clientX:first.x,clientY:first.y,pointerId:10});
 get('map').onpointermove({clientX:last.x,clientY:last.y,pointerId:10});
 get('map').onpointerup({clientX:last.x,clientY:last.y,pointerId:10});
 assert.equal(resourceRequests.length,2);assert.deepEqual(resourceRequests[1],resourceRequests[0]);
 assert.equal(get('resource-note')['aria-pressed'],'false');
 get('resource-note').onclick();get('map').onkeydown({key:'Escape',preventDefault(){}});
 assert.equal(get('resource-note')['aria-pressed'],'false');assert.equal(resourceRequests.length,2);
 const beforeSelection=screen(10,12),a=screen(2.5,3.5),b=screen(8.5,8.5);
 get('ownership-toggle').onclick();
 get('map').onpointerdown({button:0,clientX:a.x,clientY:a.y,pointerId:4});
 get('map').onpointermove({clientX:b.x,clientY:b.y,pointerId:4});
 get('map').onpointerup({clientX:b.x,clientY:b.y,pointerId:4});draw();
 assert.deepEqual(screen(10,12),beforeSelection,'ownership drag does not pan');
 assert.equal(context.ATLAS_OWNERSHIP.selected.length,2,'integrated drag includes both heights');
 get('map').onkeydown({key:'Escape',preventDefault(){}});assert.equal(context.ATLAS_OWNERSHIP.active,false);
 get('resource-note').onclick();
 context.AtlasPrivacy.apply({enabled:true});draw();
 assert.equal(get('resource-note')['aria-pressed'],'false');get('resource-note').onclick();assert.equal(get('resource-note')['aria-pressed'],'false');
 assert.equal(get('vertical-mode').value,'surface');assert.equal(get('terrain').disabled,true);
 assert.equal(get('ownership-toggle').disabled,true);assert.equal(context.ATLAS_OWNERSHIP.active,false);
 get('map').onkeydown({key:'PageDown',preventDefault(){}});assert.equal(get('vertical-mode').value,'surface');
 get('vertical-mode').onchange({target:{value:'slice'}});assert.equal(get('vertical-mode').value,'surface');
 get('terrain').onclick();assert.equal(get('height')['aria-pressed'],'true');
 context.AtlasPrivacy.apply({enabled:false});draw();assert.equal(get('terrain').disabled,false);

 // The specialized Metro instance reuses panning but must not trigger resource writes.
 events['atlas-metro-update']({detail:{workspace:true,stations:[],lines:[],edges:[]}});
 const requestCount=resourceRequests.length;
 get('map').onpointerdown({button:0,shiftKey:true,clientX:500,clientY:350,pointerId:12});
 get('map').onpointermove({clientX:540,clientY:370,pointerId:12});
 get('map').onpointerup({clientX:540,clientY:370,pointerId:12});
 assert.equal(resourceRequests.length,requestCount,'Metro Shift-drag cannot dispatch a resource region');

});
