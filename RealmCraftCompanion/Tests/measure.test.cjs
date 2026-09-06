const test=require('node:test'),assert=require('node:assert/strict');
const {estimate,cells}=require('../Resources/MapEngine/realmcraft_map/web/measure.js');
const registry={1:'grass_block',2:'water',3:'rail',4:'lava',5:'sand'};
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-8);
const a={x:0,z:0},b={x:100,z:0},flat=(id=1)=>(()=>({id,y:64}));
test('flat distance and configurable travel speed',()=>{
 const r=estimate(a,b,flat(),registry);assert.equal(r.distance,100);near(r.profile,100);near(r.times.walk,25);near(r.times.llama,100/3);assert.equal(r.times.boat,null);assert.equal(r.times.cart,null);
 near(estimate(a,b,flat(),registry,{walk:2}).times.walk,50);
});
test('water and rail times require a continuous suitable profile',()=>{
 assert.equal(estimate(a,b,flat(2),registry).times.boat,100/6);
 near(estimate(a,b,flat(3),registry).times.cart,12.5);
 for(const id of [2,3]){const r=estimate(a,b,x=>({id:x===50?1:id,y:64}),registry);assert.equal(r.times[id===2?'boat':'cart'],null);}
});
test('missing chunks, unknown block IDs and hazards do not imply a usable route',()=>{
 for(const read of [x=>x===50?null:{id:1,y:64},flat(999),flat(4)]){const r=estimate(a,b,read,registry);assert.ok(Object.values(r.times).every(v=>v===null));}
});
test('hills and rough ground increase the walking estimate; direction affects climbs',()=>{
 const up=estimate(a,b,x=>({id:1,y:64+Math.floor(x/5)}),registry),down=estimate(b,a,x=>({id:1,y:64+Math.floor(x/5)}),registry);
 assert.equal(up.ascent,20);assert.equal(down.descent,20);assert.ok(up.profile>100);assert.ok(up.times.walk>down.times.walk);assert.ok(estimate(a,b,flat(5),registry).times.walk>25);
});
test('negative and diagonal lines cover endpoints and corner neighbours',()=>{
 const pts=cells({x:-2,z:-2},{x:0,z:0});assert.equal(pts.length,7);assert.ok(pts.some(p=>p.x===-1&&p.z===-2));
 assert.ok(Math.abs(estimate({x:-2,z:-2},{x:0,z:0},flat(),registry).profile-Math.sqrt(8))<1e-8);
 const same=estimate(a,a,flat(),registry);assert.equal(same.distance,0);assert.equal(same.times.walk,0);
 assert.equal(estimate(a,{x:20001,z:0},flat(),registry).error,'limit');
});
