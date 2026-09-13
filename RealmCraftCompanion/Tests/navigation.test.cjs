const test=require('node:test'),assert=require('node:assert/strict');const nav=require('../Resources/MapEngine/realmcraft_map/web/navigation.js');
const registry={1:'stone',2:'water',3:'lava',4:'rail'};
test('route detours around obstacles and emits actual left/right turns',async()=>{
 const read=(x,z)=>Math.abs(x)>8||Math.abs(z)>8?null:{id:x===2&&z===0?3:1,y:64};
 const r=await nav.route({x:0,z:0},{x:4,z:0},read,registry);assert.ok(r.path.length>5);assert.ok(r.path.every(p=>p.id!==3));const s=nav.cues(r.path);assert.ok(s.some(p=>/Turn (left|right)/.test(p.instruction)));assert.equal(s.at(-1).action,'arrive');
});
test('large unsupported jumps are not invented as climbing',async()=>{
 const read=(x,z)=>z!==0||x<0||x>4?null:{id:1,y:x<2?64:70};assert.ok((await nav.route({x:0,z:0},{x:4,z:0},read,registry)).error);
});
test('walk/boat transitions preserve boarding coordinates',async()=>{
 const read=(x,z)=>z!==0||x<0||x>6?null:{id:x>=2&&x<=4?2:1,y:64};
 assert.ok((await nav.route({x:0,z:0},{x:6,z:0},read,registry)).error);
 const r=await nav.route({x:0,z:0},{x:6,z:0},read,registry,()=>false,'boat');assert.ok(r.path);const s=nav.cues(r.path);assert.ok(s.some(s=>s.instruction.includes('Board your boat')&&s.at.x===1));assert.ok(s.some(s=>s.instruction.includes('Dismount')&&s.at.x===4));assert.ok(r.seconds>=40);
});
test('directions, vertical steps and POI offsets use world heading',()=>{
 const s=nav.cues([{x:0,y:65,z:0},{x:0,y:66,z:-1},{x:1,y:66,z:-1}]);assert.equal(s[0].action,'step up');assert.ok(s[1].instruction.includes('Turn right'));
 const p=nav.nearby(s,[{name:'island note',x:-150,z:0},{name:'too far',x:300,z:0}]);assert.equal(p.length,1);assert.equal(p[0].side,'left');assert.equal(p[0].distance,150);assert.equal(p[0].y,null);
});
test('mixed segment subtotal excludes unknown gap and retains modes',()=>{
 const {segments}=require('../Resources/MapEngine/realmcraft_map/web/measure.js');const s=segments({x:0,z:0},{x:9,z:0},x=>x===5?null:{id:x>=2&&x<=4?2:1,y:64},registry);assert.deepEqual(s.map(s=>s.mode),['walk','boat','gap','walk']);assert.equal(s[2].seconds,null);assert.ok(s[3].seconds>0);
});
test('small island suggestion requires closed saved-water boundary',()=>{
 const steps=[{at:{x:0,z:0}}],read=(x,z)=>({id:Math.abs(x)<=2&&Math.abs(z)<=2?1:2,y:64});
 const found=nav.islands(steps,read,registry);assert.equal(found.length,1);assert.equal(found[0].name,'Possible small island');
 const incomplete=(x,z)=>x===3&&z===0?null:read(x,z);assert.equal(nav.islands(steps,incomplete,registry).length,0);
});
test('saved stairs remain traversable and are named in instructions',async()=>{
 const r=await nav.route({x:0,z:0},{x:2,z:0},(x,z)=>z===0&&x>=0&&x<=2?{id:5,y:64+x}:null,{5:'oak_stairs'});assert.ok(r.path);assert.ok(nav.cues(r.path).some(s=>s.instruction.includes('saved stairs')));
});

test('direct Markdown includes interactive guidance even for an older saved route',()=>{
 const md=nav.markdown({guidance:[],dimension:'o',generatedAt:'synthetic',steps:[],pois:[]});
 assert.ok(md.includes('one route section at a time'));
 assert.ok(md.includes('Wait for my section arrival confirmation'));
 assert.ok(md.includes('Never infer my position from elapsed time'));
});

test('spoken sections preserve every manoeuvre and target longer checkpoints',()=>{
 const steps=Array.from({length:160},(_,i)=>({id:`step-${i+1}`,index:i+1,at:{x:i,y:65,z:0},to:{x:i+1,y:65,z:0},blocks:1,action:'walk',instruction:'Continue straight'}));
 const sections=nav.spokenSections(steps);
 assert.deepEqual(sections.map(s=>s.blocks),[75,75,10]);
 assert.deepEqual(sections.flatMap(s=>s.stepIDs),steps.map(s=>s.id));
 assert.deepEqual(sections.at(-1).to,steps.at(-1).to);
 steps[30].instruction='Board your boat.';
 const critical=nav.spokenSections(steps);
 assert.equal(critical[0].blocks,30);assert.equal(critical[1].blocks,25);
 assert.ok(critical[1].criticalStepIDs.includes('step-31'));
 assert.equal(critical.reduce((n,s)=>n+s.blocks,0),160);
});
test('copy and cloud buttons export the current route and reset with selection',async()=>{
 const vm=require('node:vm'),fs=require('node:fs');const elements=[],messages=[],events={};
 class Element{constructor(tag){this.tag=tag;this.children=[];this.hidden=false;elements.push(this);}append(...v){this.children.push(...v);if(this.tag==='select'&&!this.value)this.value=v[0].value;}prepend(v){this.children.unshift(v);}setAttribute(){}insertBefore(v){this.children.push(v);}}
 const context={document:{documentElement:{lang:'en'},createElement:tag=>new Element(tag)},setTimeout,clearTimeout,console,webkit:{messageHandlers:{atlasNavigationExport:{postMessage:m=>messages.push(m)}}},addEventListener:(name,fn)=>events[name]=fn};
 vm.createContext(context);vm.runInContext(fs.readFileSync(require.resolve('../Resources/MapEngine/realmcraft_map/web/navigation.js'),'utf8'),context);
 const measure={panel:new Element('section'),output:new Element('div'),points:[{x:0,z:0},{x:6,z:0}],dimension:'o',read:(x,z)=>z===0&&x>=0&&x<=6?{id:1,y:64}:null,clear(){},start(){},draw(){},changed(){}};
 context.AtlasNavigation.install(measure,{title:'synthetic',generatedAt:'synthetic',registry:{1:'stone'},dimensions:{o:{}}},()=>[]);
 measure.resourceTarget={saveID:'synthetic-snapshot',dimension:'o',x:6,y:12,z:0};
 const button=text=>elements.find(e=>e.tag==='button'&&e.textContent===text);
 assert.ok(button('Copy navigation').hidden);await button('Plan English navigation').onclick();assert.equal(button('Copy navigation').hidden,false);
 await button('Copy navigation').onclick();assert.equal(messages[0].action,'copy');assert.equal(messages[0].pack.world,'synthetic');
 assert.ok(messages[0].pack.guidance.some(s=>s.includes('X 6, Y 12, Z 0')&&s.includes('unplanned')));
 button('Save to iCloud…').onclick();assert.equal(messages[1].action,'cloud');assert.ok(messages[1].pack.steps.length);
 measure.clear();assert.ok(button('Copy navigation').hidden);assert.ok(button('Save to iCloud…').hidden);
});
