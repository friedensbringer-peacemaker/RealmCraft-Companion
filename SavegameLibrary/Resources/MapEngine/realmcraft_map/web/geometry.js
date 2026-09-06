(function(root){
  const chunkOrigin = v => Math.floor(v / 16) * 16;
  const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
  const screenAt = (x,z,view,width,height) => {
    const c=Math.cos(view.angle||0),s=Math.sin(view.angle||0),dx=(x-view.x)*view.zoom,dz=(z-view.z)*view.zoom;
    return {x:width/2+(c*dx-s*dz)*(view.flipX?-1:1),y:height/2+(s*dx+c*dz)*(view.flipZ?-1:1)};
  };
  const worldAt = (px,py,view,width,height) => {
    const c=Math.cos(view.angle||0),s=Math.sin(view.angle||0),dx=(px-width/2)/view.zoom*(view.flipX?-1:1),dy=(py-height/2)/view.zoom*(view.flipZ?-1:1);
    return {x:view.x+c*dx+s*dy,z:view.z-s*dx+c*dy};
  };
  const zoomAt = (px,py,factor,view,width,height) => {
    const before=worldAt(px,py,view,width,height),next={...view,zoom:clamp(view.zoom*factor,.015625,32)},after=worldAt(px,py,next,width,height);
    return {...next,x:next.x+before.x-after.x,z:next.z+before.z-after.z};
  };
  const panBy = (dx,dy,view) => {
    const delta=worldAt(dx,dy,{...view,x:0,z:0},0,0);
    return {...view,x:view.x-delta.x,z:view.z-delta.z};
  };
  const viewportBounds = (view,width,height) => {
    const corners=[[0,0],[width,0],[0,height],[width,height]].map(([x,y])=>worldAt(x,y,view,width,height));
    return {left:Math.min(...corners.map(p=>p.x)),right:Math.max(...corners.map(p=>p.x)),top:Math.min(...corners.map(p=>p.z)),bottom:Math.max(...corners.map(p=>p.z))};
  };
  const fitView = (bounds,view,width,height) => {
    const [a,b,c,d]=bounds,cos=Math.abs(Math.cos(view.angle||0)),sin=Math.abs(Math.sin(view.angle||0));
    return {...view,x:(a+c)/2,z:(b+d)/2,zoom:clamp(Math.min(Math.max(1,width-90)/((c-a)*cos+(d-b)*sin),Math.max(1,height-110)/((c-a)*sin+(d-b)*cos)),.015625,32)};
  };
  const api={chunkOrigin,clamp,worldAt,screenAt,zoomAt,panBy,viewportBounds,fitView};
  if(typeof module!=='undefined') module.exports=api;
  root.AtlasGeometry=api;
})(globalThis);
