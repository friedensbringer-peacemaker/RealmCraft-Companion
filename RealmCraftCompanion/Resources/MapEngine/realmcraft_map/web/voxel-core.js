/* Offline voxel geometry. Coordinates are local to the displayed area. */
(function(root){
'use strict';
const air=id=>id===0||id===639;
function mesh(blocks,n,h,palette){
 const vertices=[],indices=(x,y,z)=>(y*n+z)*n+x;
 const dirs=[[1,0,0,.82],[-1,0,0,.67],[0,1,0,1],[0,-1,0,.45],[0,0,1,.75],[0,0,-1,.6]];
 const corners=[[[1,0,0],[1,1,0],[1,1,1],[1,0,1]],[[0,0,1],[0,1,1],[0,1,0],[0,0,0]],[[0,1,1],[1,1,1],[1,1,0],[0,1,0]],[[0,0,0],[1,0,0],[1,0,1],[0,0,1]],[[1,0,1],[1,1,1],[0,1,1],[0,0,1]],[[0,0,0],[0,1,0],[1,1,0],[1,0,0]]];
 for(let y=0;y<h;y++)for(let z=0;z<n;z++)for(let x=0;x<n;x++){
  const id=blocks[indices(x,y,z)];if(air(id))continue;const rgb=palette[id]||[219,91,192];
  for(let f=0;f<6;f++){const [dx,dy,dz,shade]=dirs[f],a=x+dx,b=y+dy,c=z+dz;
   if(a>=0&&a<n&&b>=0&&b<h&&c>=0&&c<n&&!air(blocks[indices(a,b,c)]))continue;
   for(const i of [0,1,2,0,2,3]){const v=corners[f][i];vertices.push(x+v[0],y+v[1],z+v[2],rgb[0]/255*shade,rgb[1]/255*shade,rgb[2]/255*shade);}
  }
 }
 return new Float32Array(vertices);
}
function multiply(a,b){const r=new Float32Array(16);for(let c=0;c<4;c++)for(let row=0;row<4;row++)for(let k=0;k<4;k++)r[c*4+row]+=a[k*4+row]*b[c*4+k];return r;}
function matrix(eye,target,aspect){
 const unit=v=>{const l=Math.hypot(...v)||1;return v.map(x=>x/l)},cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]],dot=(a,b)=>a.reduce((s,x,i)=>s+x*b[i],0);
 const z=unit(eye.map((x,i)=>x-target[i])),x=unit(cross([0,1,0],z)),y=cross(z,x);
 const v=new Float32Array([x[0],y[0],z[0],0,x[1],y[1],z[1],0,x[2],y[2],z[2],0,-dot(x,eye),-dot(y,eye),-dot(z,eye),1]);
 const f=1/Math.tan(Math.PI/6),near=.08,far=1200;
 return multiply(new Float32Array([f/aspect,0,0,0,0,f,0,0,0,0,(far+near)/(near-far),-1,0,0,2*far*near/(near-far),0]),v);
}
function project(m,p,w,h){const a=[...p,1],v=[0,0,0,0];for(let i=0;i<4;i++)for(let j=0;j<4;j++)v[i]+=m[j*4+i]*a[j];return v[3]<=0?null:{x:(v[0]/v[3]+1)*w/2,y:(1-v[1]/v[3])*h/2,depth:v[2]/v[3]};}
// Grounded movement: one-block steps, body clearance, and safe ledge stops.
function walk(blocks,n,h,camera,dx,dz){
 const solid=(x,y,z)=>x<0||z<0||x>=n||z>=n||(y>=0&&y<h&&!air(blocks[(y*n+z)*n+x]));
 const stand=(x,z,feet)=>{
  if(x<.25||z<.25||x>n-.25||z>n-.25)return null;
  for(let floor=Math.floor(feet+1.01);floor>=Math.ceil(feet-3);floor--){
   let clear=true,support=false;
   for(const a of [Math.floor(x-.24),Math.floor(x+.24)])for(const b of [Math.floor(z-.24),Math.floor(z+.24)]){
    support ||= solid(a,floor-1,b);
    for(let y=floor;y<floor+1.8;y++)if(solid(a,y,b))clear=false;
   }
   if(clear&&support)return floor;
  }
  return null;
 };
 const p=[...camera];
 for(const [ax,az]of [[dx,0],[0,dz]]){const floor=stand(p[0]+ax,p[2]+az,p[1]-1.7);if(floor!==null){p[0]+=ax;p[2]+=az;p[1]=floor+1.7;}}
 return p;
}
const api={air,mesh,matrix,project,walk};if(typeof module!=='undefined')module.exports=api;root.AtlasVoxelCore=api;
})(globalThis);
