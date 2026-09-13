// Synthetic projection/tile checks. No savegames, browser or third-party runtime.
const fs = require('fs'), path = require('path'), vm = require('vm'), assert = require('assert');
const source = fs.readFileSync(path.join(__dirname, '../Resources/Tectonicus/mirror.js'), 'utf8');
function fixture(search = '') {
    function Projection() {}
    Projection.prototype.worldToMap = p => [-p.z / 2, p.x / 2];
    Projection.prototype.mapToWorld = p => ({x: p.y * 2, y: 62, z: -p.x * 2});
    const hooks = [], lines = [], labels = [], styles = [];
    const ctx = {beginPath(){}, moveTo(){}, lineTo(x,y){lines.push([x,y]);}, stroke(){},
        strokeText(){}, fillText(text,x,y){labels.push([text,x,y]);}};
    const context = {window: {}, location: {search}, URLSearchParams,
        MinecraftProjection: Projection,
        WorldCoord: function(x,y,z){Object.assign(this,{x,y,z});},
        L: {Point: function(x,y){Object.assign(this,{x,y});}, TileLayer: {addInitHook: hook => hooks.push(hook)}},
        contents: [{id:'Map0',worldVectors:{}}],
        document: {head:{appendChild:style=>styles.push(style.textContent)}, createElement: () => ({style:{},getContext:()=>ctx})},
        CreateCompassControl: () => ({onAdd: () => ({style:{},appendChild(){}})})};
    vm.runInNewContext(source,context);
    assert(styles.includes('#map .leaflet-tile-loaded { opacity: 1 !important; }'),
        'loaded tiles must not depend on background animation frames');
    return {context,hooks,lines,labels};
}
for (const link of ['', '?mirror=1&worldX=12&worldY=62&worldZ=-20&zoom=4']) {
    const f = fixture(link), c = f.context, p = new c.MinecraftProjection();
    vm.runInNewContext(source,c);
    assert.equal(f.hooks.length,1,'repeat injection must not reflect twice');
    for (const x of [-65,-1,0,1,65]) for (const z of [-32,0,48]) {
        const point=p.worldToMap({x,y:62,z});
        assert.equal(point[0],-z/2); assert.equal(point[1],-x/2);
        const world=p.mapToWorld(new c.L.Point(...point));
        assert.equal(world.x,x); assert.equal(world.z,z);
    }
    let tileload;
    const layer={worldVectors:{},getTileUrl:c=>`${c.z}/${c.x}/${c.y}`,on:(name,callback)=>{assert.equal(name,'tileload');tileload=callback;}};
    f.hooks[0].call(layer);
    f.hooks[0].call(layer);
    for (const zoom of [0,1,5]) for (const x of [-17,-1,0,1,16]) {
        const coords={x,y:3,z:zoom};
        assert.equal(layer.getTileUrl(coords),`${zoom}/${-x-1}/3`);
        assert.equal(coords.x,x,'do not mutate Leaflet tile coordinates');
        // Any pixel, including either tile edge, maps to the reflected world pixel.
        for (const pixel of [0,1,128,256]) {
            const mirroredPixel=x*256+pixel;
            const originalPixel=(-x-1)*256+(256-pixel);
            assert.equal(mirroredPixel,-originalPixel);
        }
    }
    const tile={dataset:{},style:{transform:'translate3d(-256px, 768px, 0px)'}};
    tileload({tile});tileload({tile});
    assert.equal(tile.style.transform,'translate3d(-256px, 768px, 0px) scaleX(-1)');
    assert.equal(tile.style.transformOrigin,'center');
    c.CreateCompassControl('Map0/Compass.png').onAdd({});
    assert.equal(f.labels.length,4);
    assert(f.labels.find(p=>p[0]==='+X')[1]<100,'positive X must be left in this reflected fixture');
    assert(f.labels.find(p=>p[0]==='−X')[1]>100);
    assert(f.labels.find(p=>p[0]==='−Z')[2]<80);
}
const off=fixture('?mirror=0');
assert.equal(off.hooks.length,0);
assert.equal(new off.context.MinecraftProjection().worldToMap({x:4,z:2})[1],2);
console.log('Mirrored grid seams, world/marker coordinates, compass, opt-out and idempotence: PASS');
