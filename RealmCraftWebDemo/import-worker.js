'use strict';
importScripts('save-reader.js');
let zip=null;
self.onmessage=async({data})=>{
 try{
 if(data.action==='inspect'){
  if(data.file.size>SaveReader.LIMITS.archive)throw Error('ZIP zu groß (maximal 128 MiB).');
  zip=new SaveReader.Zip(new Uint8Array(await data.file.arrayBuffer()));
  self.postMessage({type:'worlds',worlds:await zip.worlds()});
 }else if(data.action==='load'){
  if(!zip)throw Error('Bitte zuerst eine ZIP auswählen.');
  const result=await zip.load(data.prefix,(done,total)=>self.postMessage({type:'progress',done,total}));
  self.postMessage({type:'loaded',result});zip=null;
 }
 }catch(error){self.postMessage({type:'error',message:error.message||'Import fehlgeschlagen.'});}
};
