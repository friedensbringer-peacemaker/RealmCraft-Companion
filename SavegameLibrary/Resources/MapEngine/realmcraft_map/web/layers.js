/* Height slices load only requested map regions. No game process or server API. */
(() => {
  'use strict';
  class AtlasLayers {
    constructor(data, changed, status) {
      this.data=data;this.changed=changed;this.status=status;
      this.entries=new Map();this.queue=[];this.active=0;this.rendering=0;
      this.known=new Map(Object.entries(data.dimensions).map(([id,d])=>[id,new Set(d.regions||[])]));
      window.AtlasRegion=(key,payload)=>{
        const entry=this.entries.get(key);if(!entry)return;
        entry.compressed=payload;this.inflate(entry);
      };
    }
    report(){const pending=this.active+this.queue.length+this.rendering;
      const failed=[...this.entries.values()].some(e=>e.error);
      this.status(failed?'Ein Bereich konnte nicht geladen werden. Bitte den vollständigen Kartenordner verwenden.':pending?`Ebenen werden geladen · ${pending} Bereiche`:'');
    }
    has(prefix,x,z){return this.known.get(prefix)?.has(`${x},${z}`);}
    ensure(prefix,x,z){
      const key=`${prefix}:${x},${z}`;let entry=this.entries.get(key);
      if(!entry){entry={key,prefix,x,z,last:0};this.entries.set(key,entry);}
      entry.last=performance.now();
      if(!entry.chunks&&!entry.loading&&!entry.error){entry.loading=true;this.queue.push(entry);this.pump();}
      return entry;
    }
    pump(){
      while(this.active<4&&this.queue.length){const entry=this.queue.shift();this.active++;
        if(entry.compressed){this.inflate(entry);continue;}
        const script=document.createElement('script');entry.script=script;
        script.src=`regions/${entry.prefix}/${entry.x},${entry.z}.js`;
        script.onerror=()=>this.finish(entry,new Error('Region missing'));
        document.head.append(script);
      }
      this.report();
    }
    async inflate(entry){
      try{
        if(typeof DecompressionStream==='undefined')throw new Error('Gzip unavailable');
        const bytes=Uint8Array.from(atob(entry.compressed),c=>c.charCodeAt(0));
        const stream=new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
        const parsed=JSON.parse(await new Response(stream).text());
        entry.chunks=new Map(Object.entries(parsed).map(([key,b64])=>[key,Uint8Array.from(atob(b64),c=>c.charCodeAt(0))]));
        this.finish(entry);
      }catch(error){this.finish(entry,error);}
    }
    finish(entry,error){entry.loading=false;entry.error=error||null;entry.script?.remove();entry.script=null;this.active--;this.pump();this.changed();}
    trim(){
      const loaded=[...this.entries.values()].filter(e=>e.chunks&&!e.rendering).sort((a,b)=>b.last-a.last);
      for(const entry of loaded.slice(12))entry.chunks=null;
    }
    getTile(prefix,x,z,y,mode,style){
      if(!this.has(prefix,x,z))return null;
      const key=`${mode}:${y}:${style}`,existing=this.entries.get(`${prefix}:${x},${z}`);
      if(existing?.canvasKey===key)return existing.canvas;
      const entry=this.ensure(prefix,x,z);entry.desired={key,y,mode,style};
      if(entry.chunks&&!entry.rendering){entry.rendering=true;this.rendering++;this.report();
        setTimeout(()=>{try{const target=entry.desired;this.render(entry,target);}
          catch(error){entry.error=error;}finally{entry.rendering=false;this.rendering--;this.trim();this.report();this.changed();}},0);
      }
      return null;
    }
    render(entry,{key,y,mode,style}){
      const rgba=new Uint8ClampedArray(256*256*4),heights=new Uint8Array(256*256),present=new Uint8Array(256*256);
      const palette=this.data.palette;
      for(const [position,bytes] of entry.chunks){
        const [cx,cz]=position.split(',').map(Number),dx=cx-entry.x*256,dz=cz-entry.z*256;
        for(let z=0;z<16;z++)for(let x=0;x<16;x++){
          const {id,y:height}=AtlasColumns.readColumn(bytes,z*16+x,y,mode),i=(dz+z)*256+dx+x,o=i*4;
          const air=id===0||id===639;color: {
            if(air){rgba[o]=18;rgba[o+1]=40;rgba[o+2]=49;break color;}
            const rgb=palette[id]||[219,91,192];rgba[o]=rgb[0];rgba[o+1]=rgb[1];rgba[o+2]=rgb[2];
            if(style==='height'){const t=height/255;rgba[o]=40+200*t;rgba[o+1]=65+180*t;rgba[o+2]=79+145*t;}
          }
          rgba[o+3]=255;heights[i]=height;present[i]=air?0:1;
        }
      }
      if(mode==='below')for(let z=0;z<256;z++)for(let x=0;x<256;x++){
        const i=z*256+x;if(!present[i])continue;
        const dx=x&&present[i-1]?heights[i]-heights[i-1]:0,dz=z&&present[i-256]?heights[i]-heights[i-256]:0;
        const light=Math.max(.56,Math.min(1.3,1+dx*.075+dz*.09));for(let c=0;c<3;c++)rgba[i*4+c]*=light;
      }
      const canvas=entry.canvas||document.createElement('canvas');canvas.width=canvas.height=256;
      canvas.getContext('2d').putImageData(new ImageData(rgba,256,256),0,0);entry.canvas=canvas;entry.canvasKey=key;
    }
    lookup(prefix,x,z,y,mode){
      const rx=Math.floor(x/256),rz=Math.floor(z/256);if(!this.has(prefix,rx,rz))return null;
      const entry=this.ensure(prefix,rx,rz);if(!entry.chunks)return {loading:true};
      const cx=Math.floor(x/16)*16,cz=Math.floor(z/16)*16,bytes=entry.chunks.get(`${cx},${cz}`);
      return bytes?AtlasColumns.readColumn(bytes,(z-cz)*16+x-cx,y,mode):null;
    }
  }
  window.AtlasLayers=AtlasLayers;
})();
