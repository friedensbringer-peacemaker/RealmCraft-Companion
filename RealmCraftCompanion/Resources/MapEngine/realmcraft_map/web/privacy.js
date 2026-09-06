/* Display policy only: generated chunks are not evidence of exploration. */
(() => {
 'use strict';
 const normalized=s=>({enabled:s?.enabled===true,owned:[...new Set(s?.owned||[])].sort(),visible:[...new Set(s?.visible||[])].sort(),hidden:[...new Set(s?.hidden||[])].sort(),suspected:s?.suspected===true});
 const policy = {
  state: normalized(window.ATLAS_PRIVACY),
  apply(state) { const next=normalized(state); if (JSON.stringify(this.state) === JSON.stringify(next)) return; this.state = next; window.dispatchEvent(new Event('atlas-privacy')); },
  get enabled() { return this.state.enabled === true; },
  allows(dimension, point, chest) {
   const id = `${dimension}:${point.x},${point.y},${point.z}`;
   if (point.kind !== 'chest') return !this.enabled;
   if ((this.state.hidden || []).includes(id)) return false;
   const known = (this.state.owned || []).includes(id) || (this.state.visible || []).includes(id);
   if (this.enabled) return known;
   if (known || !this.state.suspected || !chest?.readable || dimension !== 'o' || point.y > 50) return true;
   const ids = new Set((chest.items || []).filter(i => i.quantity > 0).map(i => i.itemID));
   return !(ids.has(170) && ids.has(3270) && (ids.has(147) || ids.has(3213)));
  }
 };
 window.AtlasPrivacy = policy;
})();
