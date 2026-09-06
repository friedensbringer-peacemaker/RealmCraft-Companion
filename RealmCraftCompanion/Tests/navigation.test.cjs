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
