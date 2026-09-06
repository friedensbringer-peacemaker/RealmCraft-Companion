/* Saved v9 biome grid: four-by-four IDs per chunk, X-major, independent of Y. */
(() => {
 const lookup=(data,dimension,x,z)=>{
  const cx=Math.floor(x/16)*16,cz=Math.floor(z/16)*16,grid=data.dimensions[dimension]?.biomes?.[`${cx},${cz}`];
  if(!grid||grid.length!==16)return null;
  const index=((Math.floor(x)-cx)&12)|(((Math.floor(z)-cz)>>2)&3),id=grid[index];
  return {id,names:data.biomeNames?.[id]};
 };
 const label=(data,dimension,x,z,en)=>{const biome=lookup(data,dimension,x,z);if(!biome)return en?'Saved biome · no data':'Gespeichertes Biom · keine Daten';const name=biome.names?.[en?'en':'de']||(en?'Unknown':'Unbekannt');return `${en?'Biome':'Biom'} · ${name} · ID ${biome.id}`;};
 window.AtlasBiomes={lookup,label};
})();
