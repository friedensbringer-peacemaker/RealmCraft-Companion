const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),crypto=require('node:crypto');
function setup(){
 const nodes=new Map(),workers=[];
 function element(){return {textContent:'',hidden:false,open:false,value:'',children:[],events:{},files:[],setAttribute(){},after(){},append(...v){this.children.push(...v);},replaceChildren(){this.children=[];},querySelectorAll(){return [];},addEventListener(k,f){this.events[k]=f;},showModal(){this.open=true;},close(){this.open=false;},click(){return this.clicked=this.onclick?.();},firstChild:{textContent:''}};}
 const $=key=>{if(!nodes.has(key))nodes.set(key,element());return nodes.get(key);};
 const bytes=Buffer.from('synthetic test archive'),digest=crypto.createHash('sha256').update(bytes).digest('hex');
 const c={document:{createElement:element,body:element()},window:{addEventListener(){},ImportedMap:{reset(){}}},$: $,I18n:{t:s=>s,html:(ss,...vs)=>ss.reduce((o,s,i)=>o+s+(vs[i]??''),''),pairs:{}},awaitingDemo:true,demoLoadMessage:'',render(){},toast(){},resetDialog:element(),AbortController,Blob,File,crypto:crypto.webcrypto,
 fetch:async url=>url==='demo-source.json'?{ok:true,json:async()=>({sha256:digest,asset:'demo.zip'})}:{ok:true,body:new Blob([bytes]).stream()},
 Worker:class{constructor(){workers.push(this);this.messages=[];}postMessage(v){this.messages.push(v);}terminate(){this.terminated=true;}},
 getData:async()=>({}),C:{fromImport:r=>r},state:{},undo:[],selectedSlot:0,transfer:null,mapFocus:null};
 vm.createContext(c);vm.runInContext(fs.readFileSync(require.resolve('../import-ui.js'),'utf8'),c);return {c,$,workers};
}
test('startup downloads the demo and opens its only world without confirmation',async()=>{
 const {c,$,workers}=setup();await $('#load-demo').clicked;assert.equal(workers.length,1);const w=workers[0];assert.equal(w.messages[0].action,'inspect');
 await w.onmessage({data:{type:'worlds',worlds:[{prefix:'sample/'}]}});assert.equal(w.messages[1].action,'load');assert.equal(w.messages[1].prefix,'sample/');assert.equal($('#confirm-import').hidden,true);
 await w.onmessage({data:{type:'loaded',result:{source:{name:'Sample'},worldMap:{dimensions:{o:{chunks:[]}}},errors:[]}}});assert.equal(c.awaitingDemo,false);assert.equal(c.state.source.name,'Sample');assert.equal($('#import-dialog').open,false);
});
test('cancelled startup rejects stale results and local ZIPs still require world selection',async()=>{
 const {c,$,workers}=setup();await $('#load-demo').clicked;const first=workers[0];$('#cancel-import').click();assert.equal(c.awaitingDemo,true);assert.equal(c.demoLoadMessage,'Laden abgebrochen.');
 await first.onmessage({data:{type:'loaded',result:{source:{name:'Stale'}}}});assert.equal(c.state.source,undefined);
 $('#zip-file').files=[new File(['test'],'local.zip')];$('#zip-file').onchange();const local=workers[1];await local.onmessage({data:{type:'worlds',worlds:[{prefix:'local/',name:'Local',chunks:1,worldID:42}]}});assert.equal(local.messages.length,1);assert.equal($('#confirm-import').hidden,false);
});
