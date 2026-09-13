const assert = require('node:assert/strict');
const p = require('../Resources/MapEngine/realmcraft_map/web/map-presentation.js');
assert.equal(p.displayName('Demo world','realmcraft-map-input-ABC','Saved world'),'Demo world');
assert.equal(p.displayName('', 'realmcraft-map-input-ABC', 'Saved world'),'Saved world');
assert.equal(p.displayName(null, 'Friendly world', 'Saved world'),'Friendly world');
assert.equal(p.displayName('  ',null,'Saved world'),'Saved world');
assert.equal(p.displayName('<script>literal title</script>',null,'Fallback'),'<script>literal title</script>');
console.log('PASS: map presentation keeps technical identity separate from display title');
