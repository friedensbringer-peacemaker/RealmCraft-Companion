const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
function setup(lang='de',legacy=false){
 const elements=new Map(),element=id=>{if(!elements.has(id))elements.set(id,{checked:false,setAttribute(k,v){this[k]=v},scrollIntoView(){}});return elements.get(id)};
 const context={document:{documentElement:{lang},getElementById:element,body:{classList:{add(){}}}},window:{AtlasPrivacy:{enabled:false}}};
 vm.createContext(context);vm.runInContext(fs.readFileSync(path.join(__dirname,'../Resources/MapEngine/realmcraft_map/web/signs.js'),'utf8'),context);
 const rows=[{id:'o:a',x:-53,y:68,z:10,text:'\nLeiter\nGrüße <img src=x>',readable:true},{id:'o:b',x:-53,y:20,z:10,text:'',readable:true},{id:'o:c',x:5,y:64,z:5,text:'',readable:false}];
 const data={signSchema:legacy?undefined:1,dimensions:{o:{signs:legacy?undefined:rows},n:{signs:[]}}};let focused;
 const signs=new context.window.AtlasSigns(data,{changed(){},focus(s){focused=s}});
 return {signs,element,context,focus:()=>focused};
}
test('independent toggle, search, wrap navigation, multiline plain text and coordinates',()=>{
 const s=setup();assert.equal(s.signs.visible,false);s.signs.step(1);assert.equal(s.signs.visible,true);
 assert.equal(s.element('sign-text').textContent,'\nLeiter\nGrüße <img src=x>');assert.equal(s.element('sign-text').innerHTML,undefined);
 assert.equal(s.element('sign-coords').textContent,'X -53 · Y 68 · Z 10');assert.equal(s.focus().id,'o:a');
 s.signs.step(-1);assert.equal(s.signs.selected.id,'o:c');assert.match(s.element('sign-text').textContent,/nicht lesbar/);
 s.element('sign-search').oninput({target:{value:'GRÜßE'}});assert.equal(s.signs.filtered().length,1);s.signs.step(1);assert.equal(s.signs.selected.id,'o:a');
 s.element('sign-search').oninput({target:{value:'20'}});s.signs.step(1);assert.equal(s.element('sign-text').textContent,'(Leeres Schild)');
 s.element('sign-visible').onchange({target:{checked:false}});assert.equal(s.signs.pick(0,0,()=>({x:0,y:0})),false);assert.equal(s.element('sign-detail').hidden,true);
});
test('projected sign picking uses map transform and cycles stacked signs',()=>{
 const s=setup();s.element('sign-visible').onchange({target:{checked:true}});
 const screen=(x,z)=>({x:-z*4+200,y:x*4+200});const p=screen(-52.5,10.5);
 assert.equal(s.signs.pick(p.x,p.y,screen),true);assert.equal(s.signs.selected.id,'o:a');
 s.signs.pick(p.x,p.y,screen);assert.equal(s.signs.selected.id,'o:b');
 s.signs.setDimension('n');assert.equal(s.signs.filtered().length,0);assert.equal(s.signs.selected,null);assert.equal(s.element('sign-next').disabled,true);
});
test('legacy maps request regeneration and spoiler mode clears details and suppresses markers',()=>{
 const old=setup('en',true);assert.equal(old.element('sign-visible').disabled,true);assert.match(old.element('sign-note').textContent,/Generate this map again/);
 const s=setup();s.signs.step(1);s.context.window.AtlasPrivacy.enabled=true;s.signs.refresh();
 assert.equal(s.signs.filtered().length,0);assert.equal(s.signs.selected,null);assert.equal(s.element('sign-text').textContent,'');assert.equal(s.element('sign-visible').disabled,true);
 s.signs.draw({},()=>{throw Error('Hidden sign drawn')},100,100);assert.equal(s.signs.pick(0,0,()=>({x:0,y:0})),false);
});

test('search enables signs and isolates results without altering other layer settings',()=>{
 const s=setup();s.element('sign-search').oninput({target:{value:'Leiter'}});assert.equal(s.signs.visible,true);assert.equal(s.signs.isolate(),true);assert.equal(s.element('search-focus-control').hidden,false);
 s.signs.focusOnly=false;assert.equal(s.signs.isolate(),false);s.signs.focusOnly=true;
 s.element('sign-search').oninput({target:{value:''}});assert.equal(s.signs.isolate(),false);assert.equal(s.element('search-focus-control').hidden,true);
 s.element('sign-search').oninput({target:{value:'Leiter'}});s.context.window.AtlasPrivacy.enabled=true;s.signs.refresh();assert.equal(s.signs.isolate(),false);assert.equal(s.element('search-focus-control').hidden,true);
});

test('enabling signs immediately draws text without selection and respects filters',()=>{
 const s=setup('en'),texts=[];
 const ctx={fillRect(){},strokeRect(){},beginPath(){},moveTo(){},lineTo(){},stroke(){},measureText(t){return {width:t.length*7}},fillText(t){texts.push(t)}};
 const draw=()=>s.signs.draw(ctx,()=>({x:50,y:50}),200,200);
 draw();assert.equal(texts.length,0);
 s.element('sign-visible').onchange({target:{checked:true}});assert.equal(s.signs.selected,null);
 draw();assert.equal(texts.length,3);assert.ok(texts.some(t=>t.includes('Leiter')));
 texts.length=0;s.element('sign-search').oninput({target:{value:'Leiter'}});draw();assert.equal(texts.length,1);
 texts.length=0;s.element('sign-visible').onchange({target:{checked:false}});draw();assert.equal(texts.length,0);
});
