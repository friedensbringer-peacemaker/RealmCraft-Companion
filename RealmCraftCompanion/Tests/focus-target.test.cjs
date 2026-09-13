const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const root=path.join(__dirname,'../Resources/MapEngine/realmcraft_map/web');
test('resource target retains negative XYZ and snapshot scope; missing coverage, privacy and replay are explicit',()=>{
 const created=[],events={},focus=[];
 const context={document:{documentElement:{lang:'en'},createElement:tag=>{const e={tag,children:[],append(...v){this.children.push(...v)}};created.push(e);return e;},getElementById:()=>({append(){}})},ATLAS_PORTALS:{saveID:'synthetic-save',world:'synthetic-world'},addEventListener:(n,f)=>events[n]=f};
 context.globalThis=context;vm.createContext(context);vm.runInContext(fs.readFileSync(path.join(root,'focus-target.js'),'utf8'),context);
 const measure={active:false,start(){this.active=true;}};
 const feature=context.AtlasFocusTarget.install({dimensions:{n:{chunks:{'-32,-16':'data'}}}},measure,p=>focus.push(p));
 const target={id:'one',saveID:'synthetic-save',world:'synthetic-world',dimension:'n',x:-21,y:12,z:-3,blockID:155};
 assert.equal(feature.receive({...target,saveID:'other'}),false);
 assert.equal(feature.receive({...target,y:256}),false);
 assert.equal(feature.receive(target),true);assert.equal(focus[0].y,12);
 const button=created.find(e=>e.tag==='button');button.onclick();assert.equal(measure.pendingResourceTarget,target);
 assert.equal(feature.receive(target),false);
 assert.equal(feature.receive({...target,id:'two',x:1000}),true);assert.equal(button.disabled,true);
 context.AtlasPrivacy={enabled:true};events['atlas-privacy']();assert.equal(created[0].hidden,true);
 assert.equal(feature.receive({...target,id:'three'}),false);
});
test('existing measure accepts a chosen start and resource destination, then clears both on cancellation',()=>{
 const {Measure}=require(path.join(root,'measure.js'));
 const m=Object.create(Measure.prototype);Object.assign(m,{active:true,points:[],pendingResourceTarget:{dimension:'n',x:-21,y:12,z:-3},update(){},changed(){},panel:{},button:{setAttribute(){}}});
 m.pick({x:-8.2,z:-1},'n');assert.deepEqual(m.points,[{x:-9,z:-1},{x:-21,z:-3}]);assert.equal(m.resourceTarget.y,12);assert.equal(m.active,false);
 m.clear();assert.equal(m.resourceTarget,null);assert.deepEqual(m.points,[]);
});
