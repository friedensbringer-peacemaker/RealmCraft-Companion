'use strict';
const assert=require('node:assert/strict');
const {convert,nearest,markers,validPoint}=require('../Resources/MapEngine/realmcraft_map/web/portals.js');
assert.deepEqual(convert({dimension:'o',x:-804,z:404}),{dimension:'n',x:-100.5,z:50.5});
assert.deepEqual(convert({dimension:'n',x:-101,z:51}),{dimension:'o',x:-808,z:408});
assert.equal(nearest(-100.5),-101);assert.equal(nearest(50.5),51);assert.equal(nearest(-0.125),-0);
for(const x of [-30000000,-804,-8,0,8,804,30000000])assert.equal(convert({dimension:'n',x,z:0}).x,x*8);
for(const p of [{dimension:'end',x:0,z:0},{dimension:'o',x:NaN,z:0},{dimension:'n',x:Infinity,z:0},{dimension:'o',x:1.2,z:0},{dimension:'o',x:30000001,z:0}])assert.equal(validPoint(p),false);
const plans=[{id:'synthetic',name:'Test',dimension:'o',x:800,z:-400}];
const result=markers([{id:'saved',dimension:'n',x:10,z:10,y:50}],plans);
assert.deepEqual(result.map(m=>m.kind),['saved','plan','target']);assert.equal(result[2].dimension,'n');assert.equal(result[2].x,100);assert.equal(result[2].z,-50);
assert.equal(plans.length,1);assert.equal(plans[0].dimension,'o');
const geometry=require('../Resources/MapEngine/realmcraft_map/web/geometry.js');
for(const angle of [0,Math.PI/2,Math.PI,3*Math.PI/2])for(const flipX of [false,true]){
 const view={x:0,z:0,zoom:3,angle,flipX,flipZ:false};const p=geometry.screenAt(-803.5,404.5,view,1000,700);const w=geometry.worldAt(p.x,p.y,view,1000,700);
 assert.deepEqual(convert({dimension:'o',x:Math.floor(w.x),z:Math.floor(w.z)}),{dimension:'n',x:-100.5,z:50.5});
}
console.log('PASS: map conversion, reciprocal planned markers, negative rounding and rotated/mirrored map picking');
