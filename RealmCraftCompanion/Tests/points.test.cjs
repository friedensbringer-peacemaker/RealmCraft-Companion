const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const script=fs.readFileSync(path.join(__dirname,'../Resources/MapEngine/realmcraft_map/web/points.js'),'utf8');
function setup(language='en',privacy){
 const elements=new Map(),writes=[],stored={};
 const element=id=>{if(!elements.has(id))elements.set(id,{value:'',checked:true,hidden:false,children:[],replaceChildren(){this.children=[]},setAttribute(k,v){this[k]=v},append(o){this.children.push(o)}});return elements.get(id)};
 const context={document:{documentElement:{lang:language},getElementById:element,createElement:()=>({})},localStorage:{getItem:k=>stored[k],setItem:(k,v)=>stored[k]=v},window:{ATLAS_NATIVE_NAMES:{'o:chest:1,64,2':'Home store'},webkit:{messageHandlers:{atlasPOINames:{postMessage:v=>writes.push(v)}}}}};
 vm.createContext(context);if(privacy){context.window.ATLAS_PRIVACY=privacy;vm.runInContext(fs.readFileSync(path.join(__dirname,'../Resources/MapEngine/realmcraft_map/web/privacy.js'),'utf8'),context);}vm.runInContext(script,context);
 const points=[{id:'o:chest:1,64,2',kind:'chest',x:1,y:64,z:2,count:1},{id:'o:chest:3,64,2',kind:'chest',x:3,y:64,z:2,count:1}];let focused;
 const poi=new context.window.AtlasPoints({title:'world',dimensions:{o:{points},n:{points:[]}}},{changed(){},focus(p){focused=p}});
 return {poi,element,writes,points,focus:()=>focused};
}
test('categories, next/previous wrap and saved names',()=>{const s=setup();s.element('poi-kind').onchange({target:{value:'chest'}});s.poi.step(1);assert.equal(s.element('poi-name').textContent,'Home store');s.poi.step(-1);assert.equal(s.focus().x,3);s.poi.step(1);assert.equal(s.focus().x,1);s.poi.setDimension('n');assert.equal(s.element('poi-count').textContent,'0 places');});
test('rename and reset persist through the native bridge',()=>{const s=setup('de');s.element('poi-kind').onchange({target:{value:'chest'}});s.poi.step(1);s.element('poi-input').value='Lager';s.element('poi-rename').onsubmit({preventDefault(){}});assert.equal(s.writes.at(-1).names[s.points[0].id],'Lager');assert.equal(s.element('poi-heading').textContent,'Interessante Orte');s.element('poi-input').value='';s.element('poi-rename').onsubmit({preventDefault(){}});assert.equal(s.writes.at(-1).names[s.points[0].id],undefined);});

test('spoiler mode removes unknown chests from counts, navigation and direct selection',()=>{
 const s=setup('en',{enabled:true,owned:['o:1,64,2']});
 s.element('poi-kind').onchange({target:{value:'chest'}});
 assert.equal(s.poi.filtered().length,1);assert.equal(s.poi.selectChest(3,64,2),false);
 s.poi.step(1);assert.equal(s.focus().x,1);s.poi.step(1);assert.equal(s.focus().x,1);
});

test('beta tags explain their evidence and respect hidden inventory sources',()=>{
 const s=setup('de',{enabled:false,hidden:['o:1,64,2']});
 const tag={id:'tag',kind:'tag',tagType:'storage',x:16,y:72,z:16,count:1,evidence:{filled:4,stacks:16},strength:'medium',sourceChests:['1,64,2']};
 s.points.push(tag);s.poi.data.dimensions.o.chests={'1,64,2':{x:1,y:64,z:2,readable:true,items:[]}};
 s.element('poi-kind').onchange({target:{value:'tag'}});assert.equal(s.poi.filtered().length,0);
 tag.sourceChests=[];s.poi.step(1);assert.match(s.element('poi-name').textContent,/Mögliches Lager/);assert.match(s.element('poi-clues').textContent,/4 gefüllte lesbare Kisten/);assert.match(s.element('poi-clues').textContent,/lokale Regeln/);assert.doesNotMatch(s.element('poi-name').textContent,/Beta/);assert.equal(s.element('auto-tag-notice').hidden,false);assert.match(s.element('auto-tag-notice').textContent,/Beta/);s.element('poi-visible').onchange({target:{checked:false}});assert.equal(s.element('auto-tag-notice').hidden,true);s.element('poi-visible').onchange({target:{checked:true}});s.poi.setDimension('n');assert.equal(s.element('auto-tag-notice').hidden,true);
});

test('equivalent native privacy refreshes preserve open editing state',()=>{
 let events=0;const context={window:{ATLAS_PRIVACY:{enabled:false,owned:['a','b'],visible:[],hidden:[],suspected:false},dispatchEvent(){events++}},Event:class{}};
 vm.createContext(context);vm.runInContext(fs.readFileSync(path.join(__dirname,'../Resources/MapEngine/realmcraft_map/web/privacy.js'),'utf8'),context);
 context.window.AtlasPrivacy.apply({suspected:false,hidden:[],visible:[],owned:['b','a'],enabled:false});assert.equal(events,0);
 context.window.AtlasPrivacy.apply({enabled:true,owned:['a','b']});assert.equal(events,1);
});

test('adjacent sign name is plain text and manual map name takes precedence',()=>{
 const s=setup();
 s.poi.data.dimensions.o.chests={'1,64,2':{signName:'Tools <img src=x>'}};
 assert.equal(s.poi.title(s.points[0]),'Home store');
 delete s.poi.names[s.points[0].id];
 s.poi.selectChest(1,64,2);
 assert.equal(s.element('poi-name').textContent,'Tools <img src=x>');
 assert.equal(s.element('poi-coords').textContent,'X 1 · Y 64 · Z 2');
 assert.match(s.poi.title(s.points[1]),/3, 64, 2/);
});
