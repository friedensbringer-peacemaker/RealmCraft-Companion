/* Numeric mappings are shared with the macOS Companion; translated names never choose icons. */
(function(root){
'use strict';
const synthetic={stone:12,wood:13,diamond:3157,iron:3159,coal:3155,redstone:3270,torch:147,wool:108};
function id(item){return /^id:\d+$/.test(item)?item.slice(3):synthetic[item];}
function source(item){const value=root.CompanionIcons?.[id(item)];return typeof value==='string'&&/^data:image\/png;base64,[A-Za-z0-9+/]+=*$/.test(value)?value:null;}
function html(item,detail=false){const src=source(item);return src?`<img class="item-icon${detail?' item-icon-detail':''}" src="${src}" alt="" aria-hidden="true" draggable="false">`:'';}
const api={id,source,html};root.ItemIcons=api;if(typeof module!=='undefined')module.exports=api;
})(globalThis);
