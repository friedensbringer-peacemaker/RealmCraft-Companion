(function(root){
  const chunkOrigin = v => Math.floor(v / 16) * 16;
  const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
  const worldAt = (px, py, view, width, height) => ({x:view.x+(px-width/2)/view.zoom,z:view.z+(py-height/2)/view.zoom});
  const zoomAt = (px, py, factor, view, width, height) => {
    const before = worldAt(px,py,view,width,height), zoom=clamp(view.zoom*factor,.015625,32);
    return {x:before.x-(px-width/2)/zoom,z:before.z-(py-height/2)/zoom,zoom};
  };
  const api={chunkOrigin,clamp,worldAt,zoomAt};
  if(typeof module!=='undefined') module.exports=api;
  root.AtlasGeometry=api;
})(globalThis);
