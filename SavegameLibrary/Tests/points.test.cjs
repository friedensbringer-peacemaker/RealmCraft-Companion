const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const script=fs.readFileSync(path.join(__dirname,'../Resources/MapEngine/realmcraft_map/web/points.js'),'utf8');
function setup(language='en'){
 const elements=new Map(),writes=[],stored={};
 const element=id=>{if(!elements.has(id))elements.set(id,{value:'',checked:true,hidden:false,children:[],setAttribute(k,v){this[k]=v},append(o){this.children.push(o)},replaceChildren(){this.children=[]}});return elements.get(id)};
 const context={document:{documentElement:{lang:language},getElementById:element,createElement:()=>({children:[],append(o){this.children.push(o)}})},localStorage:{getItem:k=>stored[k],setItem:(k,v)=>stored[k]=v},window:{ATLAS_NATIVE_NAMES:{'o:chest:1,64,2':'Home store'},webkit:{messageHandlers:{atlasPOINames:{postMessage:v=>writes.push(v)}}}}};
 vm.createContext(context);vm.runInContext(script,context);
 const points=[{id:'o:chest:1,64,2',kind:'chest',x:1,y:64,z:2,count:1},{id:'o:chest:3,64,2',kind:'chest',x:3,y:64,z:2,count:1}];let focused;
 const poi=new context.window.AtlasPoints({title:'world',dimensions:{o:{points},n:{points:[]}}},{changed(){},focus(p){focused=p}});
 return {poi,element,writes,points,focus:()=>focused};
}
test('categories, next/previous wrap and saved names',()=>{const s=setup();s.element('poi-kind').onchange({target:{value:'chest'}});s.poi.step(1);assert.equal(s.element('poi-name').textContent,'Home store');s.poi.step(-1);assert.equal(s.focus().x,3);s.poi.step(1);assert.equal(s.focus().x,1);s.poi.setDimension('n');assert.equal(s.element('poi-count').textContent,'0 places');});
test('rename and reset persist through the native bridge',()=>{const s=setup('de');s.element('poi-kind').onchange({target:{value:'chest'}});s.poi.step(1);s.element('poi-input').value='Lager';s.element('poi-rename').onsubmit({preventDefault(){}});assert.equal(s.writes.at(-1).names[s.points[0].id],'Lager');assert.equal(s.element('poi-heading').textContent,'Interessante Orte');s.element('poi-input').value='';s.element('poi-rename').onsubmit({preventDefault(){}});assert.equal(s.writes.at(-1).names[s.points[0].id],undefined);});

test('chest preview shows slots, quantities, empty and unavailable states',()=>{
 const s=setup('de');s.poi.data.itemNames={'3157':{de:'Diamant'}};
 s.poi.data.dimensions.o.chests={'1,64,2':{readable:true,items:[{slot:3,itemID:3157,quantity:44},{slot:1,itemID:9999,quantity:2}]}};
 assert.equal(s.poi.selectChest(1,64,2),true);
 let panel=s.element('chest-preview');assert.equal(panel.hidden,false);
 let list=panel.children.find(e=>e.className==='chest-items');assert.equal(list.children[0].value,1);assert.equal(list.children[0].textContent,'Item #9999 × 2');assert.equal(list.children[1].textContent,'Diamant × 44');
 s.poi.step(1);assert.ok(panel.children.some(e=>e.textContent.startsWith('Inhalt nicht verfügbar')));
 s.poi.data.dimensions.o.chests['3,64,2']={readable:true,items:[]};s.poi.refresh();assert.ok(panel.children.some(e=>e.textContent==='Diese Kiste ist leer.'));
 s.poi.setDimension('n');assert.equal(panel.hidden,true);
});
