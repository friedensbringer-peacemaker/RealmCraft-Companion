/* Offline, on-demand height slices with a bounded decoded-region cache. */
(() => {
  'use strict';
  class AtlasLayers {
    constructor(data, changed, status) {
      this.data=data;this.changed=changed;this.status=status;
      this.entries=new Map();this.queue=[];this.active=0;this.rendering=0;
      this.known=new Map(Object.entries(data.dimensions).map(([id,d])=>[id,new Set(d.regions||[])]));
      window.AtlasRegion=(key,payload)=>{const e=this.entries.get(key);if(e){e.compressed=payload;this.inflate(e);}};
    }
    report(){const pending=this.active+this.queue.length+this.rendering;
      const failed=[...this.entries.values()].some(e=>e.error);
      this.status(failed?'Ein Bereich konnte nicht geladen werden. Bitte den vollständigen Kartenordner verwenden.':pending?`Ebenen werden geladen · ${pending} Bereiche`:'');
    }
    has(prefix,x,z){return this.known.get(prefix)?.has(`${x},${z}`);}
    ensure(prefix,x,z){
      const key=`${prefix}:${x},${z}`;let e=this.entries.get(key);
      if(!e){e={key,prefix,x,z,last:0};this.entries.set(key,e);}
      e.last=performance.now();
      if(!e.chunks&&!e.loading&&!e.error){e.loading=true;this.queue.push(e);this.pump();}
      return e;
    }
    pump(){
      while(this.active<4&&this.queue.length){const e=this.queue.shift();this.active++;
        if(e.compressed){this.inflate(e);continue;}
        const script=document.createElement('script');e.script=script;
        script.src=`regions/${e.prefix}/${e.x},${e.z}.js`;
        script.onerror=()=>this.finish(e,new Error('Region missing'));
        script.onload=()=>{if(!e.compressed)this.finish(e,new Error('Invalid region file'));};
        document.head.append(script);
      }
      this.report();
    }
    async inflate(e){
      try{
        if(typeof DecompressionStream==='undefined')throw new Error('Gzip unavailable');
        const bytes=Uint8Array.from(atob(e.compressed),c=>c.charCodeAt(0));
        const stream=new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
        const parsed=JSON.parse(await new Response(stream).text());
        e.chunks=new Map(Object.entries(parsed).map(([key,b64])=>[key,Uint8Array.from(atob(b64),c=>c.charCodeAt(0))]));
        this.finish(e);
      }catch(error){this.finish(e,error);}
    }
    finish(e,error){if(!e.loading)return;e.loading=false;e.error=error||null;e.script?.remove();e.script=null;this.active--;this.pump();this.changed();}
    trim(){const loaded=[...this.entries.values()].filter(e=>e.chunks&&!e.rendering).sort((a,b)=>b.last-a.last);for(const e of loaded.slice(12))e.chunks=null;}
    getTile(prefix,x,z,y,mode,style){
      if(!this.has(prefix,x,z))return null;
      const key=`${mode}:${y}:${style}`,existing=this.entries.get(`${prefix}:${x},${z}`);
      if(existing?.canvasKey===key)return existing.canvas;
      const e=this.ensure(prefix,x,z);e.desired={key,y,mode,style};
      if(e.chunks&&!e.rendering){e.rendering=true;this.rendering++;this.report();
        setTimeout(()=>{try{this.render(e,e.desired);}catch(error){e.error=error;}
          finally{e.rendering=false;this.rendering--;this.trim();this.report();this.changed();}},0);
      }
      return null;
    }
    render(e,{key,y,mode,style}){
      const rgba=new Uint8ClampedArray(256*256*4),heights=new Uint8Array(256*256),present=new Uint8Array(256*256),palette=this.data.palette;
      for(const [position,bytes] of e.chunks){
        const [cx,cz]=position.split(',').map(Number),dx=cx-e.x*256,dz=cz-e.z*256;
        for(let z=0;z<16;z++)for(let x=0;x<16;x++){
          const {id,y:height}=AtlasColumns.readColumn(bytes,z*16+x,y,mode),i=(dz+z)*256+dx+x,o=i*4;
          const air=id===0||id===639;
          let rgb=air?[18,40,49]:(palette[id]||[219,91,192]);
          if(!air&&style==='height'){const t=height/255;rgb=[40+200*t,65+180*t,79+145*t];}
          rgba[o]=rgb[0];rgba[o+1]=rgb[1];rgba[o+2]=rgb[2];rgba[o+3]=255;heights[i]=height;present[i]=air?0:1;
        }
      }
      if(mode==='below')for(let z=0;z<256;z++)for(let x=0;x<256;x++){
        const i=z*256+x;if(!present[i])continue;
        const dx=x&&present[i-1]?heights[i]-heights[i-1]:0,dz=z&&present[i-256]?heights[i]-heights[i-256]:0;
        const light=Math.max(.56,Math.min(1.3,1+dx*.075+dz*.09));for(let c=0;c<3;c++)rgba[i*4+c]*=light;
      }
      const canvas=e.canvas||document.createElement('canvas');canvas.width=canvas.height=256;
      canvas.getContext('2d').putImageData(new ImageData(rgba,256,256),0,0);e.canvas=canvas;e.canvasKey=key;
    }
    lookup(prefix,x,z,y,mode){
      const rx=Math.floor(x/256),rz=Math.floor(z/256);if(!this.has(prefix,rx,rz))return null;
      const e=this.ensure(prefix,rx,rz);if(!e.chunks)return {loading:true};
      const cx=Math.floor(x/16)*16,cz=Math.floor(z/16)*16,bytes=e.chunks.get(`${cx},${cz}`);
      return bytes?AtlasColumns.readColumn(bytes,(z-cz)*16+x-cx,y,mode):null;
    }
  }
  window.AtlasLayers=AtlasLayers;
})();
