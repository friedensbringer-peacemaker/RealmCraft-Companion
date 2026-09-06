const {test}=require('node:test');
const assert=require('node:assert/strict');
const {screenAt,worldAt,zoomAt,panBy,viewportBounds,fitView}=require('../Resources/MapEngine/realmcraft_map/web/geometry.js');
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-8,`${a} != ${b}`);
for(const angle of [0,Math.PI/4,Math.PI/2,2.4,Math.PI,5.7]) {
 test(`rotation ${angle}: coordinates, cursor zoom, drag and visible bounds`,()=>{
  const v={x:-23,z:57,zoom:2.3,angle},w=900,h=640;
  const p=screenAt(-100,200,v,w,h),back=worldAt(p.x,p.y,v,w,h);near(back.x,-100);near(back.z,200);
  const anchor=worldAt(173,431,v,w,h),zoomed=zoomAt(173,431,1.8,v,w,h),after=worldAt(173,431,zoomed,w,h);near(anchor.x,after.x);near(anchor.z,after.z);near(zoomed.angle,angle);
  const moved=screenAt(-100,200,panBy(37,-29,v),w,h);near(moved.x,p.x+37);near(moved.y,p.y-29);
  const b=viewportBounds(v,w,h);
  for(const [x,y] of [[0,0],[w,0],[0,h],[w,h]]) {const a=worldAt(x,y,v,w,h);assert.ok(a.x>=b.left&&a.x<=b.right&&a.z>=b.top&&a.z<=b.bottom);}
  const fit=fitView([-200,-50,600,250],v,w,h);
  for(const [x,z] of [[-200,-50],[600,-50],[-200,250],[600,250]]) {const a=screenAt(x,z,fit,w,h);assert.ok(a.x>=44&&a.x<=w-44&&a.y>=54&&a.y<=h-54);}
 });
}
