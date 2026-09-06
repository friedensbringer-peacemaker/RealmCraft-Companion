const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs');
const {bounds,select}=require('../Resources/MapEngine/realmcraft_map/web/ownership.js');
const {screenAt,worldAt}=require('../Resources/MapEngine/realmcraft_map/web/geometry.js');
const data={title:'test-world',dimensions:{o:{chests:{'-3,0,5':{readable:true},'-3,255,5':{readable:false},'0,64,7':{},'1,64,7':{},'bad':{},'0,256,7':{}}},n:{chests:{'-3,64,5':{}}}}};
test('reverse drag, inclusive negative boundaries, all heights, unreadable records, dimension isolation',()=>{
 assert.deepEqual(select(data,'o',bounds({x:.9,z:7.9},{x:-3,z:5})),['o:-3,0,5','o:-3,255,5','o:0,64,7']);
 assert.deepEqual(select(data,'n',bounds({x:.9,z:7.9},{x:-3,z:5})),['n:-3,64,5']);
 assert.deepEqual(select(data,'o',bounds({x:100,z:100},{x:101,z:101})),[]);
});
test('selection stays in world coordinates under rotation and mirroring',()=>{
 for(const angle of [0,Math.PI/4,Math.PI/2,2.4])for(const flipX of [false,true])for(const flipZ of [false,true]){
  const v={x:-100,z:57,zoom:3,angle,flipX,flipZ},a=screenAt(-2.5,5.5,v,900,600),b=screenAt(.5,7.5,v,900,600);
  assert.deepEqual(select(data,'o',bounds(worldAt(a.x,a.y,v,900,600),worldAt(b.x,b.y,v,900,600))),['o:-3,0,5','o:-3,255,5','o:0,64,7']);
 }
});
function setup(native=true){
 const elements=new Map(),writes=[];
 const element=id=>{if(!elements.has(id))elements.set(id,{disabled:false,hidden:false,setAttribute(k,v){this[k]=v},classList:{toggle(){}}});return elements.get(id)};
 const context={document:{documentElement:{lang:'en'},getElementById:element},window:{ATLAS_NATIVE_OWNED:['n:-3,64,5'],webkit:native?{messageHandlers:{atlasOwnership:{postMessage:m=>writes.push(m)}}}:undefined},setTimeout:()=>1,clearTimeout(){}};
 vm.createContext(context);vm.runInContext(fs.readFileSync(require.resolve('../Resources/MapEngine/realmcraft_map/web/ownership.js'),'utf8'),context);
 const controller=new context.window.AtlasOwnership(data,{changed(){}});return {controller,element,writes};
}
test('preview requires explicit apply, ack controls owned state, removal and cancellation',()=>{
 const {controller:c,element,writes}=setup();c.toggle();assert.equal(c.begin(1,{x:-3,z:5}),true);c.move(2,{x:10,z:20});assert.equal(c.selected.length,2);c.end(1,{x:.9,z:7.9});
 assert.equal(writes.length,0);assert.equal(c.selected.length,3);c.apply('add');assert.equal(writes.length,1);assert.equal(writes[0].action,'add');assert.equal(c.owned.size,1);assert.equal(c.pending,true);
 c.receive({ownedIDs:['n:-3,64,5',...c.selected],changed:3});assert.equal(c.owned.size,4);assert.equal(element('ownership-add').disabled,true);
 c.apply('remove');assert.equal(writes[1].action,'remove');c.receive({ownedIDs:['n:-3,64,5'],changed:3});c.setDimension('n');assert.equal(c.active,false);assert.equal(c.box,null);
 c.toggle();c.begin(2,{x:10,z:10});c.abort(2);assert.equal(c.box,null);assert.equal(c.selected.length,0);c.cancel();assert.equal(c.active,false);
});
test('standalone map does not pretend to persist Companion ownership',()=>{const s=setup(false);assert.equal(s.element('ownership-toggle').disabled,true);});
test('large selections are complete',()=>{
 const chests=Object.fromEntries(Array.from({length:3000},(_,i)=>[`${i},64,0`,{}]));
 assert.equal(select({dimensions:{o:{chests}}},'o',bounds({x:0,z:0},{x:2999,z:0})).length,3000);
});

test('dimension switch while native acknowledgement is pending clears the old selection',()=>{
 const {controller:c}=setup();c.toggle();c.begin(1,{x:-3,z:5});c.end(1,{x:0,z:7});c.apply('add');c.setDimension('n');
 assert.equal(c.active,false);assert.equal(c.box,null);assert.equal(c.selected.length,0);c.receive({ownedIDs:['o:-3,0,5'],changed:1});
 assert.equal(c.dimension,'n');assert.equal(c.selected.length,0);
});

test('cached maps with only chest markers are supported and do not double-count indexed markers',()=>{
 const points=[{kind:'chest',x:-3,y:0,z:5},{kind:'chest',x:-3,y:255,z:5},{kind:'bed',x:0,y:64,z:7}];
 assert.deepEqual(select({dimensions:{o:{points}}},'o',bounds({x:-3,z:5},{x:0,z:7})),['o:-3,0,5','o:-3,255,5']);
 assert.equal(select({dimensions:{o:{points,chests:{'-3,0,5':{}}}}},'o',bounds({x:-3,z:5},{x:0,z:7})).length,2);
});

test('ownership highlights appear only in edit mode and closing preserves ownership',()=>{
 const {controller:c}=setup();c.setDimension('n');let strokes=0;
 const ctx={beginPath(){},arc(){},stroke(){strokes++}};
 const draw=()=>c.draw(ctx,()=>({x:50,y:50}),100,100);
 draw();assert.equal(strokes,0);c.toggle();draw();assert.equal(strokes,1);
 c.cancel();draw();assert.equal(strokes,1);assert.equal(c.owned.has('n:-3,64,5'),true);
 c.toggle();draw();assert.equal(strokes,2);
});
