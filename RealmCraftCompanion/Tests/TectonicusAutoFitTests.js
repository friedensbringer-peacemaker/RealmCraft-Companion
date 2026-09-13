// Run with node Tests/TectonicusAutoFitTests.js; no browser or private map required.
const fs = require('fs'), vm = require('vm'), assert = require('assert');
const source = fs.readFileSync(require('path').join(__dirname, '../Resources/Tectonicus/auto-fit.js'), 'utf8')
    .replace('__REALMCRAFT_BOUNDS__', '[-32,-16,31,47]');
(async () => {
    for (const link of ['', '?zoom=2', '#worldX=10&worldY=64&worldZ=20']) {
        let initialized = false, fits = 0;
        const context = {
            location: {search: link, hash: ''},
            window: {onload: async () => { initialized = true; }},
            WorldCoord: function (x, y, z) { Object.assign(this, {x, y, z}); },
            activeBaseLayer: {projection: {worldToMap: point => point}},
            L: {latLngBounds: points => points},
            mymap: {
                options: {}, invalidateSize: () => assert(initialized), getMaxZoom: () => 4,
                fitBounds: (points, options) => {
                    fits++;
                    assert.equal(points.length, 8);
                    assert.deepEqual([...new Set(points.map(p => p.x))], [-32, 32]);
                    assert.deepEqual([...new Set(points.map(p => p.y))], [0, 256]);
                    assert.equal(options.maxZoom, 4);
                    assert.equal(options.animate, false);
                }
            }
        };
        vm.runInNewContext(source, context);
        await context.window.onload();
        assert.equal(fits, link ? 0 : 1);
    }
    console.log('Auto-fit initialization, extent and explicit links: PASS');
})();
