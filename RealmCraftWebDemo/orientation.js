/* Shared map orientation. Screen-axis mirrors follow rotation, matching the native map. */
(function(root){
'use strict';
const KEY='companion-map-orientation';
function normalize(value){return {turns:Number.isInteger(value?.turns)?((value.turns%4)+4)%4:0,flipX:value?.flipX===true,flipZ:value?.flipZ===true};}
function load(storage){try{return normalize(JSON.parse(storage.getItem(KEY)));}catch{return normalize();}}
function save(storage,value){try{storage.setItem(KEY,JSON.stringify(normalize(value)));return true;}catch{return false;}}
function forward(x,y,o){const c=[1,0,-1,0][o.turns],s=[0,1,0,-1][o.turns];return {x:(c*x-s*y)*(o.flipX?-1:1),y:(s*x+c*y)*(o.flipZ?-1:1)};}
function inverse(x,y,o){x*=o.flipX?-1:1;y*=o.flipZ?-1:1;const c=[1,0,-1,0][o.turns],s=[0,1,0,-1][o.turns];return {x:c*x+s*y,y:-s*x+c*y};}
function fit(width,height,spanX,spanZ,o){return o.turns%2?Math.min(width/spanZ,height/spanX):Math.min(width/spanX,height/spanZ);}
function begin(ctx,width,height,o){const a=forward(1,0,o),b=forward(0,1,o);ctx.save();ctx.translate(width/2,height/2);ctx.transform(a.x,a.y,b.x,b.y,0,0);ctx.translate(-width/2,-height/2);}
function visible(x,y,size,width,height,o){const p=forward(x+size/2-width/2,y+size/2-height/2,o);return p.x+size/2>=-width/2&&p.x-size/2<=width/2&&p.y+size/2>=-height/2&&p.y-size/2<=height/2;}
let storage;try{storage=root.localStorage;}catch{}
let current=load(storage);
function mount(container,onChange){
 const o=current;
 container.innerHTML=I18n.html`<strong>Ausrichtung</strong><button type="button" data-turn="-1" aria-label="90° nach links drehen">↶ 90°</button><output aria-live="polite"></output><button type="button" data-turn="1" aria-label="90° nach rechts drehen">↷ 90°</button><label><input type="checkbox" data-flip="flipX"> Links ↔ rechts</label><label><input type="checkbox" data-flip="flipZ"> Oben ↔ unten</label><button type="button" data-reset>Ausrichtung zurücksetzen</button><span class="small" role="status"></span>`;
 const status=container.querySelector('[role="status"]');
 function refresh(){container.querySelector('output').textContent=o.turns*90+'°';for(const e of container.querySelectorAll('[data-flip]'))e.checked=o[e.dataset.flip];}
 function changed(){Object.assign(o,normalize(o));const stored=save(storage,o);status.textContent=I18n.t(stored?'Automatisch in diesem Browser gespeichert.':'Speichern nicht möglich; gilt nur für diese Sitzung.');refresh();onChange();}
 for(const e of container.querySelectorAll('[data-turn]'))e.onclick=()=>{o.turns+=Number(e.dataset.turn);changed();};
 for(const e of container.querySelectorAll('[data-flip]'))e.onchange=()=>{o[e.dataset.flip]=e.checked;changed();};
 container.querySelector('[data-reset]').onclick=()=>{Object.assign(o,normalize());changed();};
 status.textContent=I18n.t('Ausrichtung wird für beide Kartenansichten gespeichert.');refresh();return o;
}
const api={normalize,load,save,forward,inverse,fit,begin,visible,mount,get current(){return current;}};
root.MapOrientation=api;if(typeof module!=='undefined')module.exports=api;
})(globalThis);
