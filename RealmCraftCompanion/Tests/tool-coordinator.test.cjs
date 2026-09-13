const test=require('node:test'),assert=require('node:assert/strict');
const Coordinator=require('../Resources/MapEngine/realmcraft_map/web/tool-coordinator.js');
test('all tool pairs cancel the previous tool; pending writes block switching',()=>{
 for(const from of ['resource','measure','ownership','portal','metro'])for(const to of ['resource','measure','ownership','portal','metro']){
  const state={},c=new Coordinator();
  for(const id of ['resource','measure','ownership','portal','metro']){state[id]={active:id===from,pending:false};c.register(id,{active:()=>state[id].active,canLeave:()=>!state[id].pending,cancel:()=>state[id].active=false});}
  assert.equal(c.activate(to),true);if(from!==to)assert.equal(state[from].active,false);
  state[from].active=true;state[from].pending=true;
  assert.equal(c.activate(to),from===to);
 }
});
test('Escape respects pending acknowledgements; dimension/privacy reset drafts and pointer state',()=>{
 const reasons=[];let pending=true,active=true,resets=0;const c=new Coordinator(()=>resets++);
 c.register('portal',{active:()=>active,canLeave:()=>!pending,cancel:r=>{reasons.push(r);active=false;}});
 assert.equal(c.cancel(),true);assert.deepEqual(reasons,[]);
 c.cancel('dimension');assert.deepEqual(reasons,['dimension']);assert.equal(resets,1);
 active=true;c.cancel('privacy');assert.deepEqual(reasons,['dimension','privacy']);
 active=true;pending=false;c.cancel();assert.equal(reasons.at(-1),'escape');
});
