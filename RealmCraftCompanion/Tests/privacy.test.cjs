const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
function setup(state){const context={window:{ATLAS_PRIVACY:state,dispatchEvent(){}},Event:class {}};vm.createContext(context);vm.runInContext(fs.readFileSync(path.join(__dirname,'../Resources/MapEngine/realmcraft_map/web/privacy.js'),'utf8'),context);return context.window.AtlasPrivacy;}
const chest={kind:'chest',x:1,y:25,z:2};
test('strict mode exposes only explicit knowledge and preserves manual hiding',()=>{
 const p=setup({enabled:true,owned:['o:1,25,2'],visible:['n:1,25,2']});
 assert.equal(p.allows('o',chest),true);assert.equal(p.allows('n',chest),true);
 assert.equal(p.allows('o',{...chest,x:2}),false);assert.equal(p.allows('o',{...chest,kind:'building'}),false);
 p.apply({...p.state,hidden:['o:1,25,2']});assert.equal(p.allows('o',chest),false);
});
test('opt-in estimate matches Swift policy and never hides owned or unreadable records',()=>{
 const loot={readable:true,items:[170,3270,147].map(itemID=>({itemID,quantity:1}))};const p=setup({suspected:true});
 assert.equal(p.allows('o',chest,loot),false);assert.equal(p.allows('n',chest,loot),true);
 assert.equal(p.allows('o',{...chest,y:51},loot),true);assert.equal(p.allows('o',chest,{...loot,readable:false}),true);
 p.apply({suspected:true,owned:['o:1,25,2']});assert.equal(p.allows('o',chest,loot),true);
 p.apply({});assert.equal(p.allows('o',chest,loot),true);
});
