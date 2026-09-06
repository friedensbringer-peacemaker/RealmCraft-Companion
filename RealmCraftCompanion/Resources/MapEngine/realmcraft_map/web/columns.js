(function(root){
  'use strict';
  function readColumn(bytes,index,y,mode){
    const view=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength);
    let first=view.getUint32(index*4,true),end=view.getUint32((index+1)*4,true),lo=first,hi=end;
    while(lo+1<hi){const mid=(lo+hi)>>>1;if(bytes[1028+mid*3]<=y)lo=mid;else hi=mid;}
    let id=view.getUint16(1028+lo*3+1,true),height=y;
    if(mode==='below'){
      while((id===0||id===639)&&lo>first){height=bytes[1028+lo*3]-1;lo--;id=view.getUint16(1028+lo*3+1,true);}
    }
    return {id,y:height};
  }
  const api={readColumn};if(typeof module!=='undefined')module.exports=api;root.AtlasColumns=api;
})(globalThis);
