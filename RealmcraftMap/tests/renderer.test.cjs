const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=process.argv[2];if(!root)throw new Error('Pass synthetic export directory');
let context;
const document={createElement(tag){if(tag==='canvas')return{width:0,height:0,getContext(){return{putImageData:image=>{this.image=image;}};}};return{remove(){},src:''};},head:{append(script){setImmediate(()=>{try{vm.runInContext(fs.readFileSync(path.join(root,script.src),'utf8'),context);script.onload?.();}catch(e){script.onerror?.(e);}});}}};
context=vm.createContext({document,console,setTimeout,performance,Blob,Response,DecompressionStream,atob,Uint8Array,Uint8ClampedArray,DataView,Map,Set,ImageData:class{constructor(data,w,h){this.data=data;this.width=w;this.height=h;}}});context.window=context;
for(const file of ['map.data.js','columns.js','layers.js'])vm.runInContext(fs.readFileSync(path.join(root,file),'utf8'),context);
let changes=0;const loader=new context.AtlasLayers(context.REALMCRAFT_MAP,()=>changes++,()=>{});
async function tile(y,mode){for(let i=0;i<400;i++){const result=loader.getTile('o',-1,0,y,mode,'terrain');if(result)return result;await new Promise(r=>setTimeout(r,5));}throw new Error('Renderer timeout');}
(async()=>{const exact=await tile(50,'slice'),pixel=(39*256+243)*4;
assert.deepEqual([...exact.image.data.slice(pixel,pixel+3)],[...context.REALMCRAFT_MAP.palette[72]]);
const lookup=loader.lookup('o',-13,39,49,'below');assert.equal(lookup.id,1);assert.equal(lookup.y,24);
const below=await tile(49,'below');assert.deepEqual([...below.image.data.slice(pixel,pixel+3)],[...context.REALMCRAFT_MAP.palette[1]]);
const sky=await tile(255,'slice');assert.deepEqual([...sky.image.data.slice(pixel,pixel+4)],[18,40,49,255]);
assert.equal(loader.lookup('o',-100,5,50,'slice'),null);assert.ok(changes>=3);
console.log('Offline gzip loader, renderer pixels, layer changes and lookup passed.');
})().catch(e=>{console.error(e);process.exitCode=1;});
