/* Read-only ports of the Companion's observed v9 chunk and v2 player readers. */
(function(root){
'use strict';
const utf8=new TextDecoder('utf-8',{fatal:true});
const fail=message=>{throw Error(message);};
const need=(ok,message='Nicht unterstützte oder unvollständige Spielstanddaten.')=>{if(!ok)fail(message);};
const view=b=>new DataView(b.buffer,b.byteOffset,b.byteLength);
const matches=(b,p,a)=>p>=0&&p+a.length<=b.length&&a.every((v,i)=>b[p+i]===v);
function world(b){
 need(b.length>=122&&b.length<=1048576&&b[0]===9,'world_data: Nur das beobachtete Format v9 wird unterstützt.');
 const v=view(b),n=v.getUint32(13);need(n>0&&n<=4096&&b.length===17+n+105,'world_data: Unbekannte Struktur.');
 const name=utf8.decode(b.subarray(17,17+n));need(!/[\u0000-\u001f]/.test(name),'Ungültiger Weltname.');
 return {name,worldID:String(v.getUint32(1)),seed:v.getInt32(9)};
}
function player(b){
 need(b.length>=150&&b.length<=4000000&&matches(b,0,[2,0,0,0,1]));const v=view(b);
 const num=(p,little=false)=>{need(p>=0&&p+4<=b.length);return v.getUint32(p,little);};
 need(num(5)===b.length-9);const anchors=[];
 for(let p=0;p<b.length-12;p++)if(matches(b,p,[0,13,1])&&matches(b,p+7,[1,0,0,0,36]))anchors.push(p);
 need(anchors.length===1);let p=anchors[0]+7;
 function container(capacity){
 need(matches(b,p,[1])&&num(p+1)===capacity);const count=num(p+5);need(count<=capacity);p+=9;
 const result=[],seen=new Set();
 for(let i=0;i<count;i++){
 const id=num(p),quantity=num(p+32);need(id>0&&id<=65535&&quantity>0&&quantity<=2147483647&&matches(b,p+4,[0,1,2,0,55])&&matches(b,p+25,[0,8,1])&&num(p+28)===id);
 p+=36;need(matches(b,p,[0,0,0,0]));p+=4;let durability=null;const enchantments=[];
 if(matches(b,p,[0,24,1])){durability=num(p+3);need(durability<=2147483647&&num(p+7)<=2147483647);p+=11;need(matches(b,p,[0,59,0]));const effects=num(p+3);need(effects<=256);p+=7;const ids=new Set();for(let e=0;e<effects;e++){need(p+6<=b.length);const id=v.getUint16(p),level=num(p+2);need(level>0&&level<=2147483647&&!ids.has(id));ids.add(id);enchantments.push({id,level});p+=6;}}
 need(matches(b,p,[0,12,0]));const slot=num(p+3);need(slot<capacity&&!seen.has(slot)&&matches(b,p+7,[255,255]));p+=9;seen.add(slot);result.push({slot,itemID:id,quantity,durability,enchantments});
 }return result;
 }
 const inventory=container(36),armor=container(4),experience=[];let level=null;
 for(let i=p;i+3<=b.length;i++)if(matches(b,i,[0,41,1]))experience.push(i);
 if(experience.length===1&&matches(b,experience[0]+18,[0,0,143,190,112])){const n=num(experience[0]+14,true);if(n<=1000000)level=n;}
 return {inventory,armor,level};
}
function chunk(b,filename){
 need(b.length>=15);const v=view(b),x=v.getInt32(4),z=v.getInt32(8),dim=b[12];
 need(v.getUint32(0)===9&&b[14]===16&&(dim===0||dim===1)&&x%16===0&&z%16===0,'Chunk: Unbekannte Version oder Koordinaten.');
 need(filename===`${'on'[dim]}.${x},${z}`,'Chunkname und gespeicherte Koordinaten stimmen nicht überein.');
 const blocks=new Uint16Array(65536);let p=15;
 for(let section=0;section<16;section++){
 need(p+4<=b.length);const nonair=v.getUint32(p);p+=4;if(!nonair)continue;
 need(nonair<=4096&&p+4<=b.length);const size=v.getUint32(p);p+=4;const end=p+size;need(size>=4&&end<=b.length);p+=4;
 for(let channel=0;channel<4;channel++){
 let out=0;while(out<4096){let run=0;while(p<end&&b[p]===0){run+=255;p++;need(run<4096);}need(p+2<=end);run+=b[p];const value=b[p+1];p+=2;need(run>0&&out+run<=4096);
 if(channel<2)for(let j=0;j<run;j++)blocks[section*4096+out+j]|=value<<(channel*8);out+=run;}
 }need(p===end,'Chunk: Zusätzliche Bytes nach Blockdaten.');
 }
 const end=p,ids=new Uint16Array(256),heights=new Uint8Array(256),ceiling=dim===1?90:255;
 for(let lx=0;lx<16;lx++)for(let lz=0;lz<16;lz++)for(let y=ceiling;y>=0;y--){const id=blocks[y*256+lx*16+lz]&4095;if(id!==0&&id!==639){ids[lz*16+lx]=id;heights[lz*16+lx]=y;break;}}
 return {x,z,dimension:'on'[dim],ids,heights,blocks,end};
}
function chestSlots(body,count){
 const starts=[];
 for(let i=0;i+28<=body.length;i++)if(matches(body,i,[0,0])&&matches(body,i+4,[0,1,2,0,55])&&matches(body,i+25,[0,8,1]))starts.push(i);
 if(!count){need(body.length===0);return [];}
 need(starts.length===count&&starts[0]===0);const result=[],seen=new Set();
 for(let n=0;n<count;n++){
 const b=body.subarray(starts[n],starts[n+1]??body.length),v=view(b);need(b.length>=49&&matches(b,b.length-9,[0,12,0])&&matches(b,b.length-2,[255,255])&&matches(b,28,[0,0]));
 const itemID=v.getUint16(2),quantity=v.getUint32(32),slot=v.getUint32(b.length-6);need(itemID===v.getUint16(30)&&quantity>0&&quantity<=2147483647&&slot<27&&!seen.has(slot));seen.add(slot);result.push({itemID,quantity,slot,extraData:b.length>49});
 }return result;
}
function chests(b,c){
 const v=view(b),result=[],seen=new Map();
 for(let i=c.end;i+19<=b.length;i++){
 if(!(matches(b,i,[0,153])||matches(b,i,[1,86]))||b[i+6]!==1)continue;
 const x=v.getInt32(i+7),y=v.getInt32(i+11),z=v.getInt32(i+15);
 if(x<c.x||x>=c.x+16||z<c.z||z>=c.z+16||y<0||y>255||![153,342].includes(c.blocks[y*256+(x-c.x)*16+z-c.z]&4095))continue;
 const id=`${c.dimension}:${x},${y},${z}`,record={id,x,y,z,dimension:c.dimension,items:[],readable:false,owned:false};
 if(seen.has(id)){Object.assign(seen.get(id),{items:[],readable:false,error:'Doppelte Kistenkoordinaten.'});continue;}
 seen.set(id,record);result.push(record);
 try{const size=v.getUint32(i+2),end=i+6+size;need(i+28<=b.length&&size>=22&&end<=b.length&&matches(b,i+19,[1,0,0,0,27]));const count=v.getUint32(i+24);need(count<=27);record.items=chestSlots(b.subarray(i+28,end),count);record.readable=true;}
 catch{record.error='Kisteninhalt nicht lesbar: unbekanntes oder beschädigtes Format.';}
 }return result;
}

// Block 173 (spruce wall sign) also uses record marker 00 a2 in the reviewed demo.
function signs(b,c){
 const ids=new Set([162,163,164,165,166,167,172,173,174,175,176,177,736,737,738,739]);
 const records=new Map(),v=view(b),footer=[0,15,0,0,0,0,0,15,0];
 for(let y=0;y<256;y++)for(let x=0;x<16;x++)for(let z=0;z<16;z++){
  const blockID=c.blocks[y*256+x*16+z]&4095;if(!ids.has(blockID))continue;
  const wx=c.x+x,wz=c.z+z,key=`${wx},${y},${wz}`;
  records.set(key,{id:`${c.dimension}:sign:${key}`,kind:'sign',dimension:c.dimension,x:wx,y,z:wz,blockID,text:'',readable:false,error:'Beschriftung fehlt oder Format nicht unterstützt.'});
 }
 const seen=new Set();
 for(let i=c.end;i+19<=b.length;i++){
  if(!matches(b,i,[0,162]))continue;
  const key=`${v.getInt32(i+7)},${v.getInt32(i+11)},${v.getInt32(i+15)}`,r=records.get(key);
  if(!r||![162,172,173].includes(r.blockID))continue;
  try{
   need(!seen.has(key));seen.add(key);const size=v.getUint32(i+2),end=i+6+size;
   need(b[i+6]===1&&size>=28&&end<=b.length&&i+25<=end);
   const length=v.getUint32(i+21),textEnd=i+25+length;need(textEnd+footer.length===end&&matches(b,textEnd,footer));
   r.text=utf8.decode(b.subarray(i+25,textEnd));r.readable=true;r.error='';
  }catch{r.text='';r.readable=false;r.error='Beschriftung nicht lesbar: unbekannter oder doppelter Schilddatensatz.';}
 }
 return [...records.values()].sort((a,b)=>a.x-b.x||a.z-b.z||a.y-b.y);
}

const crcTable=Uint32Array.from({length:256},(_,i)=>{let n=i;for(let k=0;k<8;k++)n=n&1?0xedb88320^(n>>>1):n>>>1;return n>>>0;});
function crc32(b){let crc=0xffffffff;for(const n of b)crc=crcTable[(crc^n)&255]^(crc>>>8);return (crc^0xffffffff)>>>0;}
const LIMITS={archive:128*1024*1024,expanded:512*1024*1024,entries:40000,file:8*1024*1024,chunks:16000};
class Zip {
 constructor(bytes){
 const b=bytes;need(b.length>=22&&b.length<=LIMITS.archive,'ZIP zu groß oder ungültig (maximal 128 MiB).');this.b=b;const v=view(b);let end=-1;
 for(let p=b.length-22;p>=Math.max(0,b.length-65557);p--)if(v.getUint32(p,true)===0x06054b50&&p+22+v.getUint16(p+20,true)===b.length){end=p;break;}
 need(end>=0,'ZIP-Verzeichnis fehlt.');need(v.getUint16(end+4,true)===0&&v.getUint16(end+6,true)===0,'Mehrteilige ZIP-Dateien werden nicht unterstützt.');
 const count=v.getUint16(end+10,true),size=v.getUint32(end+12,true),offset=v.getUint32(end+16,true);need(count<=LIMITS.entries&&count===v.getUint16(end+8,true)&&offset+size===end,'ZIP64 oder unbekanntes ZIP-Verzeichnis.');
 this.entries=new Map();let p=offset,total=0;const intervals=[];
 for(let n=0;n<count;n++){
 need(p+46<=end&&v.getUint32(p,true)===0x02014b50);const flags=v.getUint16(p+8,true),method=v.getUint16(p+10,true),crc=v.getUint32(p+16,true),compressed=v.getUint32(p+20,true),length=v.getUint32(p+24,true),nl=v.getUint16(p+28,true),el=v.getUint16(p+30,true),cl=v.getUint16(p+32,true),local=v.getUint32(p+42,true),mode=(v.getUint32(p+38,true)>>>16)&0xf000;
 need(p+46+nl+el+cl<=end&&nl>0&&!(flags&1)&&[0,8].includes(method)&&[0,0x8000,0x4000].includes(mode),'Verschlüsselte Dateien, Verknüpfungen oder ZIP-Kompression nicht unterstützt.');
 const name=utf8.decode(b.subarray(p+46,p+46+nl));need(!name.startsWith('/')&&!name.includes('\\')&&!name.includes('\0')&&!name.includes(':')&&!name.split('/').some(x=>x==='..'||x==='.')&&!this.entries.has(name),'Ungültige oder doppelte ZIP-Pfade.');
 need(length<=LIMITS.file&&(total+=length)<=LIMITS.expanded,'ZIP überschreitet die Entpackgrenze.');
 need(local+30<=offset&&v.getUint32(local,true)===0x04034b50&&v.getUint16(local+6,true)===flags&&v.getUint16(local+8,true)===method);
 const lnl=v.getUint16(local+26,true),lel=v.getUint16(local+28,true),start=local+30+lnl+lel;
 need(start+compressed<=offset&&utf8.decode(b.subarray(local+30,local+30+lnl))===name,'Widersprüchliche ZIP-Dateieinträge.');
 if(!(flags&8))need(v.getUint32(local+14,true)===crc&&v.getUint32(local+18,true)===compressed&&v.getUint32(local+22,true)===length,'ZIP-Prüfsummen oder Größen widersprechen sich.');
 intervals.push([local,start+compressed]);this.entries.set(name,{name,method,crc,length,start,compressed});p+=46+nl+el+cl;
 }
 need(p===end);intervals.sort((a,b)=>a[0]-b[0]);for(let i=1;i<intervals.length;i++)need(intervals[i][0]>=intervals[i-1][1],'Überlappende ZIP-Einträge.');
 }
 async read(name){
 const entry=this.entries.get(name);need(entry,'Datei fehlt in der ZIP.');const raw=this.b.subarray(entry.start,entry.start+entry.compressed);let data;
 if(entry.method===0){need(raw.length===entry.length);data=raw;}
 else{
 let stream;try{stream=new DecompressionStream('deflate-raw');}catch{fail('Dieser Browser unterstützt das ZIP-Entpacken nicht. Bitte einen aktuellen Browser verwenden.');}
 const reader=new Blob([raw]).stream().pipeThrough(stream).getReader();const out=new Uint8Array(entry.length);let pos=0;
 try{while(true){const {value,done}=await reader.read();if(done)break;need(pos+value.length<=entry.length,'ZIP-Datei entpackt größer als angegeben.');out.set(value,pos);pos+=value.length;}}
 catch(e){await reader.cancel().catch(()=>{});throw e;}finally{reader.releaseLock();}
 need(pos===entry.length);data=out;
 }need(crc32(data)===entry.crc,'ZIP-Prüfsumme stimmt nicht.');return data;
 }
 async worlds(){
 const result=[];for(const name of this.entries.keys())if(name==='world_data'||name.endsWith('/world_data')){const prefix=name.slice(0,-10);const metadata=world(await this.read(name));const files=[...this.entries.keys()].filter(n=>n.startsWith(prefix)&&/^[on]\.-?\d+,-?\d+$/.test(n.slice(prefix.length)));if(files.length){need(files.length<=LIMITS.chunks,'Zu viele Chunks für diesen Browserimport.');result.push({...metadata,prefix,chunks:files.length});}}
 need(result.length>0,'Keine unterstützte Welt gefunden. Die ZIP muss world_data und Chunkdateien enthalten.');return result;
 }
 async load(prefix,onProgress=()=>{}){
 const metadata=world(await this.read(prefix+'world_data')),result={metadata,dimensions:{},chests:[],signs:[],player:null,errors:[]};
 const names=[...this.entries.keys()].filter(n=>n.startsWith(prefix)&&/^[on]\.-?\d+,-?\d+$/.test(n.slice(prefix.length)));need(names.length>0&&names.length<=LIMITS.chunks);
 for(let i=0;i<names.length;i++){
 const b=await this.read(names[i]); // Integrity failures reject the entire import; unsupported game layouts remain explicit partial data.
 try{const c=chunk(b,names[i].slice(prefix.length));result.chests.push(...chests(b,c));result.signs.push(...signs(b,c));const d=result.dimensions[c.dimension]??={bounds:[c.x,c.z,c.x+16,c.z+16],chunks:[]};d.bounds=[Math.min(d.bounds[0],c.x),Math.min(d.bounds[1],c.z),Math.max(d.bounds[2],c.x+16),Math.max(d.bounds[3],c.z+16)];d.chunks.push({x:c.x,z:c.z,ids:c.ids,heights:c.heights});}
 catch{result.errors.push('Ein Chunk konnte nicht gelesen werden.');}
 if(i%25===0||i===names.length-1)onProgress(i+1,names.length);
 }
 need(Object.keys(result.dimensions).length,'Keine lesbaren Kartendaten.');
 if(this.entries.has(prefix+'player_data')){const bytes=await this.read(prefix+'player_data');try{result.player=player(bytes);}catch{result.errors.push('Spielerdaten nicht lesbar; Inventar und Level bleiben unbekannt.');}}
 else result.errors.push('player_data fehlt; Inventar und Level bleiben unbekannt.');
 result.errors.push(...result.signs.filter(s=>!s.readable).map(s=>s.error));
 result.errors.push(...result.chests.filter(c=>!c.readable).map(c=>c.error));return result;
 }
}
const api={world,player,chunk,chests,signs,chestSlots,crc32,Zip,LIMITS};root.SaveReader=api;if(typeof module!=='undefined')module.exports=api;
})(globalThis);
