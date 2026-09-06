const test=require('node:test'),assert=require('node:assert/strict'),Icons=require('../item-icons.js');
const mapping=require('../data/ItemIcons.json'),catalog=require('../data/WorldCatalog.json');
test('numeric ID mapping keeps tool materials distinct and leaves missing icons as text',()=>{
 assert.match(mapping['3019'],/stone_shovel\.png$/);assert.match(mapping['3022'],/diamond_shovel\.png$/);
 globalThis.CompanionIcons={'3019':'data:image/png;base64,AA=='};
 assert.match(Icons.html('id:3019'),/<img/);assert.match(Icons.html('id:3019',true),/item-icon-detail/);
 assert.equal(Icons.html('id:99999'),'');assert.equal(Icons.html('Stone Shovel'),'');
 globalThis.CompanionIcons={'3019':'https://example.invalid/private?item=3019'};assert.equal(Icons.html('id:3019'),'');
});
test('synthetic IDs use the same catalog meanings as imported items',()=>{
 const expected={stone:'Cobblestone',wood:'Oak Planks',diamond:'Diamond',iron:'Iron Ingot',coal:'Coal',redstone:'Redstone Dust',torch:'Torch',wool:'White Wool'};
 for(const [item,name] of Object.entries(expected))assert.equal(catalog.items[String(Icons.id(item))].en,name,item);
});
