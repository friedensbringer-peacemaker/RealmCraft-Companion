const {test}=require('node:test');
const assert=require('node:assert/strict');
const C=require('../core.js');
test('inventory transfer preserves quantity and never mutates its source',()=>{
 const source=C.initial().inventory,before=structuredClone(source);
 const result=C.editInventory(source,'move',0,{target:35});
 assert.deepEqual(source,before);assert.equal(result[0],null);assert.deepEqual(result[35],source[0]);
 assert.equal(result.filter(Boolean).length,source.filter(Boolean).length);
});
test('occupied targets, invalid slots and invalid stack quantities are rejected',()=>{
 const inventory=C.initial().inventory;
 for(const action of ['move','duplicate'])for(const target of [-1,36,1,1.5])assert.throws(()=>C.editInventory(inventory,action,0,{target}));
 for(const quantity of [0,65,-1,NaN,1.5,Infinity])assert.throws(()=>C.editInventory(inventory,'quantity',0,{quantity}));
 assert.throws(()=>C.editInventory(inventory,'quantity',35,{quantity:2}));
 assert.equal(C.editInventory(inventory,'quantity',0,{quantity:64})[0].quantity,64);
});
test('duplicate is independent and sorting keeps every stack without merging',()=>{
 const source=C.initial().inventory,result=C.editInventory(source,'duplicate',0,{target:20});
 result[20].quantity=1;assert.equal(result[0].quantity,48);assert.equal(source[0].quantity,48);
 const sorted=C.editInventory(result,'sort');assert.equal(sorted.length,36);
 assert.equal(sorted.filter(Boolean).length,9);
 assert.deepEqual(sorted.filter(Boolean).map(s=>JSON.stringify(s)).sort(),result.filter(Boolean).map(s=>JSON.stringify(s)).sort());
});
test('search terms must match within one chest and ownership affects totals',()=>{
 const chests=C.initial().chests;
 assert.equal(C.filterChests(chests,'Diamant').length,1);
 assert.equal(C.filterChests(chests,'Diamant',true).length,0);
 assert.equal(C.filterChests(chests,'Diamant Wolle').length,0);
 assert.equal(C.totals(chests).diamond,undefined);
 assert.equal(C.totals(chests,false).diamond,12);
 chests[2].owned=true;assert.equal(C.totals(chests).diamond,12);
});
test('material checks exclude inventory and unowned storage and show actual shortages',()=>{
 const state=C.initial();const first=C.assessment('bed',state.chests,2);
 assert.equal(first.find(r=>r.item==='wool').missing,3);
 state.chests.find(c=>c.id==='camp').owned=false;
 const second=C.assessment('bed',state.chests,1);
 assert.equal(second.find(r=>r.item==='wool').available,0);
 assert.equal(second.find(r=>r.item==='wool').missing,3);
 assert.throws(()=>C.assessment('bed',state.chests,1.2));
});
test('exports are independent snapshots with ownership-separated totals',()=>{
 const state=C.initial();state.markers.push({name:'<img onerror=alert(1)>',x:1,z:2});
 const snap=C.snapshot(state);state.inventory[0].quantity=3;
 assert.equal(snap.inventory[0].quantity,48);assert.equal(snap.ownedStorageTotals.diamond,undefined);
 assert.equal(snap.markers[0].name,'<img onerror=alert(1)>');assert.match(snap.source,/Synthetic/);
});
test('synthetic map has repeatable bounded terrain over the full selectable extent',()=>{
 const types=new Set();for(let x=-64;x<64;x++)for(let z=-64;z<64;z++){
 const t=C.terrain(x,z);assert.deepEqual(t,C.terrain(x,z));assert(Number.isInteger(t.height));assert(t.height>=0&&t.height<=255);types.add(t.type);
 }assert.equal(types.size,5);
});
