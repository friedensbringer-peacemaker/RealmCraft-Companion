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
 const elements=new Map(),classes={add(){},remove(){},toggle(){}},scales=[],tiles=[];let drawCallback,screen;
 const ctx=new Proxy({scale:(x,y)=>scales.push([x,y]),drawImage:(...args)=>tiles.push(args)}, {get:(o,k)=>o[k]||(()=>{})});
 const get=id=>{if(!elements.has(id))elements.set(id,{value:'',options:[{value:'o',remove(){}}],classList:classes,style:{},clientWidth:1000,clientHeight:700,append(){},replaceChildren(){},setAttribute(k,v){this[k]=v},addEventListener(){},getContext(){return ctx},getBoundingClientRect(){return{left:0,top:0}},setPointerCapture(){}});return elements.get(id)};
 const context=vm.createContext({document:{documentElement:{lang:'de'},getElementById:get,querySelectorAll:()=>[],body:{classList:classes}},localStorage:{getItem:()=>null},requestAnimationFrame:cb=>{drawCallback=cb;return 1},ResizeObserver:class{observe(){}},AtlasLayers:class{getTile(){return {}}},AtlasBiomes:{label:()=>''},AtlasPoints:class{setDimension(){}draw(ctx,s){screen=s}},Image:class{complete=true;naturalWidth=256},setTimeout});
 context.window=context;context.REALMCRAFT_MAP={title:'test',generatedAt:'2026-09-05',tileSize:256,scope:'complete',errors:[],registry:{},dimensions:{o:{label:'Oberwelt',count:1,bounds:[0,0,16,16],grids:[[1,1]],chunks:{},unknownIds:[]}}};
 for(const file of ['geometry.js','app.js'])vm.runInContext(fs.readFileSync(root+file,'utf8'),context);
 const draw=()=>{const cb=drawCallback;drawCallback=null;cb();};draw();const original=screen(10,12);assert.ok(tiles.length>0);
 get('mirror-x').onchange({target:{checked:true}});get('mirror-z').onchange({target:{checked:true}});draw();const mirrored=screen(10,12);assert.equal(mirrored.x,1000-original.x);assert.equal(mirrored.y,700-original.y);assert.ok(scales.some(s=>s[0]===-1&&s[1]===-1));assert.ok(get('compass-arrow').style.transform.includes('scale(-1,-1)'));
 get('map').onpointermove({clientX:mirrored.x,clientY:mirrored.y,pointerId:1});assert.equal(get('cursor-coords').textContent,'X 10   Z 12');
 get('vertical-mode').onchange({target:{value:'slice'}});draw();assert.ok(scales.some(s=>s[0]===-1&&s[1]===-1));
 get('map').onpointerdown({button:0,clientX:500,clientY:350,pointerId:1});get('map').onpointermove({clientX:540,clientY:370,pointerId:1});draw();assert.equal(screen(10,12).x,mirrored.x+40);assert.equal(screen(10,12).y,mirrored.y+20);
 get('map').onkeydown({key:'ArrowRight',preventDefault(){}});draw();assert.equal(screen(10,12).x,mirrored.x-40);
 get('mirror-reset').onclick();draw();assert.ok(get('compass-arrow').style.transform.includes('scale(1,1)'));
});
