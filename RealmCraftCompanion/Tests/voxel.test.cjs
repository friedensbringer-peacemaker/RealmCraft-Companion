const test=require('node:test'),assert=require('node:assert/strict');
const {mesh,matrix,project}=require('../Resources/MapEngine/realmcraft_map/web/voxel-core.js');
test('only exposed faces are emitted; adjacent blocks hide their shared faces',()=>{
 const a=new Uint16Array(8);a[0]=1;let m=mesh(a,2,2,{1:[255,128,0]});assert.equal(m.length,6*6*6);assert.ok([...m].every(Number.isFinite));
 a[1]=1;m=mesh(a,2,2,{1:[255,128,0]});assert.equal(m.length,10*6*6);
 a.fill(1);assert.equal(mesh(a,2,2,{1:[255,128,0]}).length,24*6*6);
});
test('both known air IDs are empty, unknown blocks remain visible',()=>{assert.equal(mesh(new Uint16Array([0,639,0,639]),2,1,{}).length,0);assert.equal(mesh(new Uint16Array([999]),1,1,{}).length,216);});
test('camera targets project to the center in orbit and eye-level views',()=>{
 for(const eye of [[32,100,90],[32,66,32]]){const target=[32,64,0],m=matrix(eye,target,1.5),p=project(m,target,900,600);assert.ok(Math.abs(p.x-450)<.01);assert.ok(Math.abs(p.y-300)<.01);assert.ok(p.depth<1&&p.depth>-1);}
 assert.equal(project(matrix([0,0,0],[0,0,-1],1),[0,0,2],100,100),null);
});
test('walking follows floors and single steps, blocks walls, low ceilings and deep drops',()=>{
 const {walk}=require('../Resources/MapEngine/realmcraft_map/web/voxel-core.js'),n=8,h=12,b=new Uint16Array(n*n*h),set=(x,y,z)=>b[(y*n+z)*n+x]=1;
 for(let z=0;z<n;z++)for(let x=0;x<n;x++)set(x,2,z);
 let p=walk(b,n,h,[2.5,4.7,2.5],.4,0);assert.ok(p[0]>2.5);assert.equal(p[1],4.7);
 set(3,3,2);p=walk(b,n,h,[2.5,4.7,2.5],.4,0);assert.equal(p[1],5.7);
 set(3,4,2);set(3,5,2);p=walk(b,n,h,[2.5,4.7,2.5],.4,0);assert.equal(p[0],2.5);
 b.fill(0);for(let z=0;z<n;z++)for(let x=0;x<3;x++)set(x,7,z);
 p=walk(b,n,h,[2.5,9.7,2.5],1,0);assert.equal(p[0],2.5);
});
test('short movement and look inputs react immediately, without waiting for a held key',()=>{
 const vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');const context={window:{},document:{documentElement:{lang:'de'}},AtlasVoxelCore:require('../Resources/MapEngine/realmcraft_map/web/voxel-core.js')};
 vm.createContext(context);vm.runInContext(fs.readFileSync(path.join(__dirname,'../Resources/MapEngine/realmcraft_map/web/voxel.js'),'utf8'),context);
 const v=Object.create(context.window.AtlasVoxelViewer.prototype);Object.assign(v,{ready:true,mode:'walk',n:8,h:8,camera:[4.5,2.7,4.5],yaw:Math.PI,pitch:0,blocks:new Uint16Array(512)});v.blocks.fill(1,0,64);
 v.nudge('w');assert.ok(v.camera[2]<4.5);assert.equal(v.camera[1],2.7);v.nudge('j');assert.ok(v.yaw>Math.PI);v.nudge('i');assert.ok(v.pitch<0);
});
