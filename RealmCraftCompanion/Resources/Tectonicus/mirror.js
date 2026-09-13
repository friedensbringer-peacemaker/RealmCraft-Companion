// Reflect the tile grid and world projection together; Leaflet keeps normal input,
// upright controls/markers and world-coordinate links. Tile files stay unchanged.
(() => {
    // WebKit may pause animation frames while a replacement view is offscreen.
    // Show loaded tiles immediately instead of leaving their fade at opacity zero.
    const loadedTiles = document.createElement('style');
    loadedTiles.textContent = '#map .leaflet-tile-loaded { opacity: 1 !important; }';
    document.head.appendChild(loadedTiles);
    if (window.realmcraftHorizontalMirror || new URLSearchParams(location.search).get('mirror') === '0') return;
    if (typeof MinecraftProjection !== 'function' || typeof L === 'undefined') return;
    window.realmcraftHorizontalMirror = true;

    const worldToMap = MinecraftProjection.prototype.worldToMap;
    const mapToWorld = MinecraftProjection.prototype.mapToWorld;
    MinecraftProjection.prototype.worldToMap = function (world) {
        const point = worldToMap.call(this, world);
        return [point[0], -point[1]];
    };
    MinecraftProjection.prototype.mapToWorld = function (point) {
        return mapToWorld.call(this, new L.Point(point.x, -point.y));
    };

    L.TileLayer.addInitHook(function () {
        if (!this.worldVectors || this.realmcraftMirrored) return;
        this.realmcraftMirrored = true;
        const getTileUrl = this.getTileUrl;
        this.getTileUrl = function (coords) {
            // Reflection maps the interval [x, x+1] to [-x-1, -x].
            return getTileUrl.call(this, {x: -coords.x - 1, y: coords.y, z: coords.z});
        };
        this.on('tileload', ({tile}) => {
            // Leaflet has positioned the image before tileload. Append the local
            // reflection so its translation and all parent zoom transforms survive.
            if (!tile.dataset.realmcraftMirrored) {
                tile.style.transformOrigin = 'center';
                tile.style.transform += ' scaleX(-1)';
                tile.dataset.realmcraftMirrored = 'true';
            }
        });
    });

    // Redraw the compass from world axes: reflecting the original compass PNG
    // would also reverse its lettering. Axis labels are language-independent.
    const createCompass = CreateCompassControl;
    CreateCompassControl = function (image) {
        const control = createCompass(image);
        const onAdd = control.onAdd;
        control.onAdd = function (map) {
            const container = onAdd.call(this, map);
            const entry = contents.find(item => item.id + '/Compass.png' === image);
            if (!entry) return container;
            container.style.backgroundImage = 'none';
            const canvas = document.createElement('canvas');
            canvas.width = 200; canvas.height = 160;
            canvas.style.width = '100px'; canvas.style.height = '80px';
            container.appendChild(canvas);
            const ctx = canvas.getContext('2d');
            const projection = new MinecraftProjection(entry.worldVectors);
            const origin = projection.worldToMap(new WorldCoord(0, 64, 0));
            ctx.lineWidth = 3; ctx.font = 'bold 19px sans-serif';
            ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
            for (const [x, z, label] of [[0,-1,'−Z'], [1,0,'+X'], [0,1,'+Z'], [-1,0,'−X']]) {
                const p = projection.worldToMap(new WorldCoord(x, 64, z));
                const dx = p[1] - origin[1], dy = origin[0] - p[0];
                const length = Math.hypot(dx, dy);
                if (!length) continue;
                const ux = dx / length, uy = dy / length;
                ctx.strokeStyle = z === -1 ? '#b34221' : '#334138';
                ctx.beginPath(); ctx.moveTo(100, 80); ctx.lineTo(100 + ux*42, 80 + uy*42); ctx.stroke();
                ctx.strokeStyle = '#ffffff'; ctx.lineWidth = 4;
                ctx.strokeText(label, 100 + ux*63, 80 + uy*63);
                ctx.fillStyle = '#17261c'; ctx.fillText(label, 100 + ux*63, 80 + uy*63);
                ctx.lineWidth = 3;
            }
            return container;
        };
        return control;
    };
})();
