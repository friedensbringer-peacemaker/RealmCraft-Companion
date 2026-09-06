const test=require('node:test'),assert=require('node:assert/strict'),O=require('../orientation.js');
test('all rotations and mirrors preserve world picking and screen-directed dragging',()=>{
 for(let turns=0;turns<4;turns++)for(const flipX of [false,true])for(const flipZ of [false,true]){
 const o={turns,flipX,flipZ};
 for(const p of [{x:-31.25,y:18.75},{x:0,y:0},{x:78,y:-92}]){const q=O.forward(p.x,p.y,o),r=O.inverse(q.x,q.y,o);assert.equal(r.x,p.x);assert.equal(r.y,p.y);}
 const d=O.inverse(25,-12,o),screen=O.forward(d.x,d.y,o);assert.equal(screen.x,25);assert.equal(screen.y,-12);
 }
 assert.deepEqual(O.forward(2,3,{turns:1,flipX:false,flipZ:false}),{x:-3,y:2});
});
test('rectangular maps fit after quarter turns and rotated culling keeps visible tiles',()=>{
 const o={turns:1,flipX:true,flipZ:false};assert.equal(O.fit(800,400,100,300,o),800/300);
 assert.equal(O.visible(390,-110,20,800,400,o),true);
 assert.equal(O.visible(390,-900,20,800,400,o),false);
});
test('saved orientation survives reload, normalizes invalid data and tolerates unavailable storage',()=>{
 const values=new Map(),storage={getItem:k=>values.get(k),setItem:(k,v)=>values.set(k,v)};
 assert.equal(O.save(storage,{turns:-1,flipX:true,flipZ:false}),true);assert.deepEqual(O.load(storage),{turns:3,flipX:true,flipZ:false});
 storage.setItem('companion-map-orientation','{"turns":1.5,"flipX":"false"}');assert.deepEqual(O.load(storage),{turns:0,flipX:false,flipZ:false});
 storage.setItem('companion-map-orientation','broken');assert.deepEqual(O.load(storage),O.normalize());assert.equal(O.save(undefined,{}),false);assert.deepEqual(O.load(undefined),O.normalize());
});
