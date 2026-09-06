const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),test=require('node:test');
const root=process.env.ATLAS_WEB||require('node:path').join(__dirname,'../Resources/MapEngine/realmcraft_map/web/');
function setup(stored={},title='world',fail=false){
 const elements=new Map(),classes={add(){},remove(){},toggle(){}};let frame;
 const get=id=>{if(!elements.has(id))elements.set(id,{value:'',options:[{value:'o',remove(){}}],classList:classes,style:{},clientWidth:1000,clientHeight:700,append(){},replaceChildren(){},setAttribute(k,v){this[k]=v},addEventListener(){},getContext(){return new Proxy({},{get:()=>()=>{}})}});return elements.get(id)};
 const context=vm.createContext({document:{documentElement:{lang:'de'},getElementById:get,querySelectorAll:()=>[],body:{classList:classes},addEventListener(){}},localStorage:{getItem:k=>stored[k]||null,setItem(k,v){if(fail)throw Error('blocked');stored[k]=v;}},requestAnimationFrame:cb=>{frame=cb;return 1},ResizeObserver:class{observe(){}},AtlasLayers:class{},AtlasBiomes:{label:()=>''},AtlasPoints:class{setDimension(){}draw(){}},Image:class{},setTimeout});
 context.window=context;context.addEventListener=()=>{};context.REALMCRAFT_MAP={title,generatedAt:'2026-09-05',tileSize:256,scope:'complete',errors:[],registry:{},dimensions:{o:{label:'Oberwelt',count:1,bounds:[0,0,16,16],grids:[[1,1]],chunks:{},unknownIds:[]}}};
 for(const f of ['geometry.js','app.js'])vm.runInContext(fs.readFileSync(root+f,'utf8'),context);
 const draw=()=>{frame();};draw();return{get,draw};
}
test('save restores rotation and both mirrors on a fresh reload; isolates worlds',()=>{
 const store={},s=setup(store);s.get('rotation-slider').oninput({target:{value:'135'}});s.get('mirror-x').onchange({target:{checked:true}});s.get('mirror-z').onchange({target:{checked:true}});s.get('orientation-save').onclick();
 assert.match(s.get('orientation-status').textContent,/gespeichert/);
 const next=setup(store);assert.equal(Number(next.get('rotation-slider').value),135);assert.equal(next.get('mirror-x').checked,true);assert.equal(next.get('mirror-z').checked,true);
 next.get('mirror-reset').onclick();next.draw();assert.match(next.get('orientation-status').textContent,/Nicht gespeichert/);assert.equal(Number(setup(store).get('rotation-slider').value),135);
 next.get('orientation-save').onclick();assert.equal(Number(setup(store).get('rotation-slider').value),0);
 assert.equal(Number(setup(store,'another-world').get('rotation-slider').value),0);
});
test('bad storage and failed saves do not claim success',()=>{
 for(const bad of ['bad json','{"angle":1,"flipX":"yes","flipZ":false}','{"angle":null,"flipX":true,"flipZ":true}'])assert.equal(Number(setup({'realmcraft-atlas:orientation:world':bad}).get('rotation-slider').value),0);
 const s=setup({},'world',true);s.get('orientation-save').onclick();assert.match(s.get('orientation-status').textContent,/fehlgeschlagen/);
});
