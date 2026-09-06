(function(root){
'use strict';
const SIZE=128;
const ITEMS={stone:{name:'Bruchstein',symbol:'ST',color:'#9daeb7'},wood:{name:'Holzbretter',symbol:'HO',color:'#d4a56f'},diamond:{name:'Diamant',symbol:'DI',color:'#69dece'},iron:{name:'Eisenbarren',symbol:'FE',color:'#c8d7e1'},coal:{name:'Kohle',symbol:'KO',color:'#87949e'},redstone:{name:'Redstone',symbol:'RE',color:'#ee8983'},torch:{name:'Fackel',symbol:'FA',color:'#f4ce70'},wool:{name:'Weiße Wolle',symbol:'WO',color:'#ece8da'}};
for(const value of Object.values(ITEMS)){const original=value.name;Object.defineProperty(value,'name',{get:()=>globalThis.I18n?.t(original)||original});}
function chestName(c){return c.generatedName?((globalThis.I18n?.language||'de')==='en'?'Chest ':'Kiste ')+c.x+', '+c.y+', '+c.z:c.id&&['workshop','timber','mine','camp'].includes(c.id)?(globalThis.I18n?.t(c.name)||c.name):c.name;}
function terrain(x,z){
 const h=Math.round(64+12*Math.sin(x/19)*Math.cos(z/23)+7*Math.sin((x+z)/15));
 const river=Math.abs(x-12*Math.sin(z/17));
 return {height:river<5?57:h,type:river<5?'water':river<7?'sand':h>76?'stone':h>70?'forest':'grass'};
}
function initial(){return {version:1,markers:[],checks:{},inventory:Array.from({length:36},(_,i)=>i<8?{item:Object.keys(ITEMS)[i],quantity:[48,32,6,12,24,18,16,8][i]}:null),chests:[
 {id:'workshop',name:'Werkstatt',x:24,y:68,z:16,owned:true,items:[{item:'iron',quantity:48},{item:'redstone',quantity:64},{item:'stone',quantity:128}]},
 {id:'timber',name:'Holzlager',x:-36,y:65,z:28,owned:true,items:[{item:'wood',quantity:192},{item:'coal',quantity:32},{item:'torch',quantity:24}]},
 {id:'mine',name:'Bergwerkskiste',x:40,y:42,z:-32,owned:false,items:[{item:'diamond',quantity:12},{item:'iron',quantity:32},{item:'coal',quantity:64}]},
 {id:'camp',name:'Lager am Fluss',x:-16,y:64,z:-24,owned:true,items:[{item:'wool',quantity:3},{item:'wood',quantity:16},{item:'torch',quantity:8}]}
]};}
function filterChests(chests,query='',owned=false){const terms=query.toLocaleLowerCase().trim().split(/\s+/).filter(Boolean);return chests.filter(c=>(!owned||c.owned)&&terms.every(t=>[c.name,chestName(c),`${c.x} ${c.y} ${c.z}`,...c.items.map(s=>ITEMS[s.item].name)].join(' ').toLocaleLowerCase().includes(t)));}
function totals(chests,owned=true){const out={};for(const c of chests){if(c.readable===false||(owned&&!c.owned))continue;for(const s of c.items)out[s.item]=(out[s.item]||0)+s.quantity;}return out;}
function editInventory(input,action,slot,options={}){
 const out=structuredClone(input);
 if(action==='sort')return out.filter(Boolean).sort((a,b)=>ITEMS[a.item].name.localeCompare(ITEMS[b.item].name,'de')).concat(Array(out.filter(x=>!x).length).fill(null));
 if(!Number.isInteger(slot)||slot<0||slot>=36||!out[slot])throw Error('Wähle einen belegten Slot.');
 if(action==='quantity'){
  if(!Number.isInteger(options.quantity)||options.quantity<1||options.quantity>64)throw Error('Die Menge muss eine ganze Zahl von 1 bis 64 sein.');
  out[slot].quantity=options.quantity;
 }else if(action==='move'||action==='duplicate'){
  const target=options.target;
  if(!Number.isInteger(target)||target<0||target>=36||out[target])throw Error('Wähle einen freien Zielslot.');
  out[target]=structuredClone(out[slot]);if(action==='move')out[slot]=null;
 }else throw Error('Unbekannte Aktion.');
 return out;
}
function assessment(recipe,chests,count=1){
 const stock=totals(chests);if(chests.some(c=>c.owned&&c.readable===false))throw Error('Eigener Lagerbestand ist unvollständig; Materialcheck nicht verfügbar.');const recipes={bed:{wood:3,wool:3},table:{wood:4}};
 if(!recipes[recipe]||!Number.isInteger(count)||count<1||count>64)throw Error('Ungültiger Materialcheck.');
 stock.wood=(stock.wood||0)+[13,14,15,16,17,18].reduce((n,id)=>n+(stock['id:'+id]||0),0);stock.wool=(stock.wool||0)+(stock['id:108']||0);
 return Object.entries(recipes[recipe]).map(([item,n])=>({item,needed:n*count,available:stock[item]||0,missing:Math.max(0,n*count-(stock[item]||0))}));
}
function snapshot(state){return {schema:1,source:structuredClone(state.source||{kind:'synthetic',name:'Synthetic browser demonstration. No real savegame data.'}),metadata:structuredClone(state.worldMap?.metadata||null),playerStatus:state.playerStatus||'synthetic',armor:structuredClone(state.armor||[]),level:state.level??null,errors:structuredClone(state.errors||[]),inventory:structuredClone(state.inventory),chests:structuredClone(state.chests),ownedStorageTotals:totals(state.chests),signs:structuredClone(state.signs||[]),markers:structuredClone(state.markers)};}

function fromImport(result,catalog,source){
 const register=s=>{const key='id:'+s.itemID,name=catalog.items[String(s.itemID)]?.de||('Gegenstand #'+s.itemID);ITEMS[key]={get name(){return catalog.items[String(s.itemID)]?.[globalThis.I18n?.language||'de']||name;},symbol:String(s.itemID),color:'#c0d3ad'};return {...s,item:key};};
 const inventory=Array(36).fill(null);for(const s of result.player?.inventory||[])inventory[s.slot]=register(s);
 return {version:2,source:{...source,name:result.metadata.name},worldMap:{metadata:result.metadata,dimensions:result.dimensions,catalog},inventory,armor:(result.player?.armor||[]).map(register),level:result.player?.level??null,playerStatus:result.player?'readable':'unknown',
 chests:result.chests.map(c=>({...c,generatedName:true,name:'Kiste '+c.x+', '+c.y+', '+c.z,items:c.items.map(register)})),signs:result.signs||[],errors:result.errors,markers:[],checks:{}};
}
const api={chestName,fromImport,SIZE,ITEMS,terrain,initial,filterChests,totals,editInventory,assessment,snapshot};
if(typeof module!=='undefined')module.exports=api;root.DemoCore=api;
})(globalThis);
