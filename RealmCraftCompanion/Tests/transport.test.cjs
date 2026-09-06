const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const root=__dirname+'/../Resources/MapEngine/realmcraft_map/web/';
const {category}=require(root+'transport.js');
test('semantic registry classification includes rail and stair variants without natural paving guesses',()=>{
 const registry=JSON.parse(fs.readFileSync(root+'../blocks.json','utf8'));
 assert.equal(category(registry[512]),'paths');assert.equal(category(registry[885]),'stairs');
 for(const id of [97,98,170,354])assert.equal(category(registry[id]),'rails');
 assert.equal(category(registry[169]),'ladders');
 for(const id of [0,12,30,257,639])assert.equal(category(registry[id]),null);
 assert.equal(category(undefined),null);
});
function setup(){
 let strokes=[];const events={},elements=[];
 const make=()=>{const e={style:{},dataset:{},append(){},getContext:()=>({set fillStyle(c){this.color=c},fillRect(x,z,w,h){strokes.push({x,z,w,h,color:this.color})}})};elements.push(e);return e;};
 const surface=new Uint8Array(768);surface[0]=170;surface[2]=152;
 const bytes=Buffer.from(surface).toString('base64');
 const data={registry:{170:'rail',152:'oak_stairs',512:'dirt_path'},dimensions:{o:{chunks:{'-16,-16':bytes}},n:{chunks:{}}}};
 const context={document:{documentElement:{lang:'en'},createElement:make,getElementById:make},addEventListener:(name,cb)=>events[name]=cb,atob:s=>Buffer.from(s,'base64').toString('binary'),AtlasPrivacy:{enabled:false},AtlasColumns:{readColumn:(b,i,y,m)=>({id:i===0?(y===40?170:512):0})}};
 vm.createContext(context);vm.runInContext(fs.readFileSync(root+'transport.js','utf8'),context);
 let ready=false;const layers={has:()=>true,ensure:()=>({chunks:ready?new Map([['-16,-16',new Uint8Array()]]):null})};
 const overlay=new context.AtlasTransport.Overlay(data,layers,()=>{});
 return {overlay,context,events,elements,ready:()=>ready=true,strokes:()=>strokes,clear:()=>strokes=[]};
}
test('independent toggles, surface coordinates, dimension and cache isolation',()=>{
 const s=setup(),o=s.overlay;assert.equal(o.tile('o',-1,-1,64,'surface'),null);
 o.inputs.find(i=>i.dataset.transport==='rails').checked=true;o.inputs.find(i=>i.dataset.transport==='rails').onchange();
 const tile=o.tile('o',-1,-1,64,'surface');assert.equal(s.strokes().length,1);assert.equal(s.strokes()[0].x,240);assert.equal(s.strokes()[0].z,240);
 assert.equal(o.tile('o',-1,-1,1,'surface'),tile);s.clear();o.tile('n',-1,-1,64,'surface');assert.equal(s.strokes().length,0);
 o.inputs.find(i=>i.dataset.transport==='stairs').checked=true;o.inputs.find(i=>i.dataset.transport==='stairs').onchange();o.tile('o',-1,-1,64,'surface');assert.equal(s.strokes().length,2);
});
test('unloaded slices retry, height changes invalidate, privacy blocks cached overlays',()=>{
 const s=setup(),o=s.overlay;o.enabled.add('rails');
 assert.equal(o.tile('o',-1,-1,40,'slice'),null);s.ready();assert.ok(o.tile('o',-1,-1,40,'slice'));assert.equal(s.strokes().length,1);
 s.clear();o.tile('o',-1,-1,41,'slice');assert.equal(s.strokes().length,0);
 s.context.AtlasPrivacy.enabled=true;s.events['atlas-privacy']();assert.equal(o.tile('o',-1,-1,40,'slice'),null);assert.ok(o.inputs.every(i=>i.disabled));
 s.context.AtlasPrivacy.enabled=false;s.events['atlas-privacy']();assert.ok(o.tile('o',-1,-1,40,'slice'));
});
