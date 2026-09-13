// Fit once on opening; subsequent panning and zooming remain under user control.
(() => {
    const bounds = __REALMCRAFT_BOUNDS__;
    const explicitView = /(?:^|[?&#])(zoom|worldX|worldY|worldZ)=/.test(location.search + location.hash);
    const initialize = window.onload;
    window.onload = async function (event) {
        await initialize.call(this, event);
        if (explicitView || !activeBaseLayer) return;
        const points = [];
        // Include the complete exported height range, including cliffs and tall builds.
        for (const x of [bounds[0], bounds[2] + 1]) {
            for (const z of [bounds[1], bounds[3] + 1]) {
                for (const y of [0, 256]) {
                    points.push(activeBaseLayer.projection.worldToMap(new WorldCoord(x, y, z)));
                }
            }
        }
        mymap.invalidateSize({pan: false});
        mymap.options.zoomSnap = 0.25;
        mymap.fitBounds(L.latLngBounds(points), {padding: [40, 40], maxZoom: mymap.getMaxZoom(), animate: false});
    };
})();
