const assert=require('node:assert/strict'),{readColumn}=require('../realmcraft_map/web/columns.js');
const runs=[[0,0],[10,1],[25,639],[50,72],[51,0]],bytes=new Uint8Array(1028+256*runs.length*3),view=new DataView(bytes.buffer);
for(let c=0;c<=256;c++)view.setUint32(c*4,c*runs.length,true);
for(let c=0;c<256;c++)for(let r=0;r<runs.length;r++){const o=1028+(c*runs.length+r)*3;bytes[o]=runs[r][0];view.setUint16(o+1,runs[r][1],true);}
assert.deepEqual(readColumn(bytes,115,24,'slice'),{id:1,y:24});
assert.deepEqual(readColumn(bytes,115,25,'slice'),{id:639,y:25});
assert.deepEqual(readColumn(bytes,115,49,'below'),{id:1,y:24});
assert.deepEqual(readColumn(bytes,115,50,'below'),{id:72,y:50});
assert.deepEqual(readColumn(bytes,115,255,'below'),{id:72,y:50});
assert.deepEqual(readColumn(bytes,255,255,'slice'),{id:0,y:255});
assert.deepEqual(readColumn(bytes,0,0,'below'),{id:0,y:0});
console.log('Vertical column lookup tests passed.');
