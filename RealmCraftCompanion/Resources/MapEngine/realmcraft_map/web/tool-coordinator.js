(function(root){
 'use strict';
 class MapToolCoordinator {
  constructor(resetPointers=()=>{}){this.tools=new Map();this.resetPointers=resetPointers;}
  register(name,tool){this.tools.set(name,tool);}
  activate(name){
   if(!this.tools.has(name))return false;
   if([...this.tools].some(([id,t])=>id!==name&&t.canLeave?.()===false))return false;
   for(const [id,t]of this.tools)if(id!==name&&t.active())t.cancel('switch');
   this.resetPointers();return true;
  }
  cancel(reason='escape'){
   const active=[...this.tools.values()].filter(t=>t.active());
   if(reason==='escape'&&active.some(t=>t.canLeave?.()===false))return true;
   for(const t of active)t.cancel(reason);
   this.resetPointers();return active.length>0;
  }
 }
 root.MapToolCoordinator=MapToolCoordinator;if(typeof module!=='undefined')module.exports=MapToolCoordinator;
})(globalThis);
