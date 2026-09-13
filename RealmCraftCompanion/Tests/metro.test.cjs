const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs');
const root=require('node:path').join(__dirname,'../Resources/MapEngine/realmcraft_map/web/');
const {geometry,validPoint}=require(root+'metro.js');
const a={id:'a',name:'Central',dimension:'n',x:640,y:32,z:640},b={id:'b',name:'North gate',dimension:'n',x:640,y:32,z:512};
function fixture(workspace=true){
 const events={},messages=[],focus=[],classes=new Set(),nodes=[];
 const element=()=>{const n={children:[],append(child){this.children.push(child)},setAttribute(){},textContent:''};nodes.push(n);return n;};
 const section=element();
 const context=vm.createContext({document:{documentElement:{lang:'en',classList:{toggle(k,on){on?classes.add(k):classes.delete(k)}}},getElementById:()=>section,createElement:element},ATLAS_METRO:{workspace,saveID:'synthetic',world:'synthetic',focusID:'a',stations:[a,b],edges:[],lines:[]},AtlasPrivacy:{enabled:false},webkit:{messageHandlers:{atlasMetro:{postMessage:m=>messages.push(m)}}},addEventListener:(name,fn)=>events[name]=fn});
 context.window=context;vm.runInContext(fs.readFileSync(root+'metro.js','utf8'),context);
 const overlay=new context.AtlasMetro.Overlay({dimensions:{n:{}}},{changed(){},getSelected(){},focus:s=>focus.push(s)});
 overlay.setDimension('n');overlay.ready();
 return {context,overlay,messages,focus,classes,events};
}
test('recorded geometry uses bends; absent geometry remains a connector, never a portal shortcut',()=>{
 const path=[a,{x:680,y:32,z:640},{x:680,y:32,z:512},b];
 assert.equal(geometry({mode:'rail',path},a,b).captured,true);
 assert.equal(geometry({mode:'rail'},a,b).captured,false);
 assert.equal(geometry({mode:'portal',path},a,{...b,dimension:'o'}),null);
 assert.equal(geometry({mode:'rail'},a,{...b,dimension:'o'}),null);
 assert.equal(geometry({mode:'rail',path:[{...a,x:641},b]},a,b).captured,false);
 assert.equal(validPoint({...a,y:undefined}),false);
});
test('only the Metro workspace can select positions and never invents a missing Y',()=>{
 const f=fixture();assert.ok(f.classes.has('metro-workspace'));assert.equal(f.focus[0].id,'a');
 assert.equal(f.overlay.choose({...a,y:undefined}),true);assert.equal(f.messages.length,0);assert.match(f.overlay.status.textContent,/No saved height/);
 f.overlay.choose(a);assert.equal(f.messages[0].action,'pick');assert.equal(f.messages[0].knownHeight,true);assert.equal(f.messages[0].y,32);
 const readOnly=fixture(false);assert.equal(readOnly.overlay.choose(a),false);assert.equal(readOnly.messages.length,0);
 f.context.AtlasPrivacy.enabled=true;assert.equal(f.overlay.choose(a),false);assert.equal(f.messages.length,1);
});
test('live native changes refresh the same overlay; focus changes only on explicit selection',()=>{
 const f=fixture();
 f.overlay.receive({...f.context.ATLAS_METRO,focusID:'b'});assert.equal(f.focus.at(-1).id,'b');
 f.overlay.receive({...f.context.ATLAS_METRO,focusID:'b',lines:[{id:'n',color:'#00FF00'}]});assert.equal(f.focus.length,2);
 assert.equal(f.overlay.lines[0].color,'#00FF00');
});
test('station and saved-portal picks respect the transformed screen coordinates',()=>{
 const f=fixture(),screen=(x,z)=>({x:1000-z*2,y:x*2});
 const s=screen(b.x+.5,b.z+.5);
 f.overlay.pick(s.x,s.y,screen,()=>{throw Error('station should be hit')});assert.equal(f.messages[0].z,512);
 f.context.ATLAS_PORTALS={portals:[{...b,id:'saved',x:720,z:400}]};const p=screen(720.5,400.5);
 f.overlay.pick(p.x,p.y,screen,()=>null);assert.equal(f.messages[1].portalID,'saved');
});
test('drawing distinguishes captured confirmed geometry from planned and missing paths',()=>{
 const f=fixture(),dashes=[];
 f.overlay.edges=[{from:'a',to:'b',mode:'rail',status:'confirmed',path:[a,b]},{from:'a',to:'b',mode:'rail',status:'planned',path:[a,b]},{from:'a',to:'b',mode:'rail',status:'confirmed'}];
 const ctx=new Proxy({setLineDash:v=>dashes.push([...v]),measureText:()=>({width:50})},{get:(o,k)=>o[k]||(()=>{})});
 f.overlay.draw(ctx,(x,z)=>({x:x/2,y:z/2}),900,600);
 assert.deepEqual(dashes.filter(d=>d.length),[[9,6],[2,7]]);
});
test('proposed portal sites receive a glyph without creating a portal route',()=>{
 const f=fixture(),segments=[];
 f.overlay.stations=[{...a,portalCandidate:true},b];f.overlay.edges=[];
 const ctx=new Proxy({moveTo:(x,y)=>segments.push([x,y]),lineTo:(x,y)=>segments.push([x,y]),measureText:()=>({width:50})},{get:(o,k)=>o[k]||(()=>{})});
 f.overlay.draw(ctx,(x,z)=>({x:x/2,y:z/2}),900,600);
 assert.equal(segments.length,4);assert.equal(f.overlay.edges.length,0);
});
