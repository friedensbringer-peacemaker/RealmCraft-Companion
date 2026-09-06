# Observed format — 2026-09-05

Read-only interoperability implementation for the supplied Realmcraft Quest savegame, version **9**. Not an official Realmcraft specification. Unknown versions are rejected.

## Chunk header and block sections

Big-endian header: version:uint32 at 0, X:int32 at 4, Z:int32 at 8, dimension:uint8 at 12 (0 overworld, 1 Nether), status:uint8 at 13 (observed 8; not interpreted), section count:uint8 at 14 (16). Filenames `o.X,Z` / `n.X,Z` must agree, with X/Z divisible by 16.

Each of sixteen ascending-Y sections begins with a uint32 non-air counter. Zero indicates an omitted all-air section, with no further section header. Otherwise a uint32 payload length follows. The first four payload bytes remain uninterpreted and are **not claimed to be a checksum**.

Four consecutive RLE streams each expand to exactly 4096 byte values. Stream 0 forms bits 0–7 of each packed block, then streams 1, 2 and 3 form the next byte planes. A run consists of zero or more zero bytes, each adding 255 to its length, then a nonzero length byte and one value byte. `00 02 19` therefore means 257 copies of byte 25. All four streams must consume the declared payload exactly.

Block IDs occupy the low 12 bits (`state & 0xfff`). The rest is block state. Air IDs 0 and 639 (`cave_air`) are skipped in top-surface rendering. The saved non-air counter does not always equal the decoded solid-block count; it is used as an allocation hint and range check, not an integrity checksum. For example `o.112,-128`, section 0, differs after excluding cave air.

Memory order is **Y, X, Z**, Z fastest. Map rows are Z, columns X. In a 5×5 adjacent-chunk sample, mean height discontinuity across seams was approximately 0.089 in this orientation versus 2.2 in the transposed alternative. Buildings and fields join continuously in the generated image.

The format supports sixteen 16-block sections, **Y 0–255**. Trailing biome/light/height-map/entity/tile-entity records are not decoded or exported. Maps derive from the actual block contents; absent chunks are not generated from the seed.

## Identifier evidence

The supplied APK's `libNativePlugin.so` exposes `DumpBlockData`, which masks IDs with `0xfff` and indexes a static descriptor table containing identifier strings. Its `UnpackBlockData` confirms the four-byte-plane RLE path for versions above 6. Only the factual ID/name mapping is included in this project. Placeholder entries pointing to air are omitted except ID 0. No native binary or original textures are redistributed.

## Atlas region format 2

A chunk exports 257 little-endian uint32 offsets indexing vertical runs for its 256 columns in Z-major/X-minor order. Run records are `startY:uint8, blockID:uint16le`. Every column starts at zero; a run lasts until the next start or Y 255 inclusive.

Up to 16×16 chunks form one 256×256-block region. Base64 column buffers are stored in a JSON object, gzip-compressed and wrapped in a local JavaScript callback. The browser requests visible regions, caches their compressed form and keeps at most twelve decoded region buffers after rendering. Surface PNG pyramids remain independent.

An exact slice returns the run containing Y. A below-surface view skips air backwards to the preceding solid run and uses its actual top height. This is a horizontal cut, not lighting-based cave detection.

## Limits

Version 9 and overworld/Nether only. Schematic colors, no biome tint or original texture rendering. No live players, entities, inventories, 3D meshes or automatic live-game sync. Transparent materials are represented as map blocks, not physically composited. Large zoomed-out underground views require time to load and render. Export bounds are limited to 64 million columns per dimension; use `--radius` for a smaller area.

Cache identity assumes ordinary modification times. Use a new cache directory after manual edits preserving both size and timestamps. Region data excludes private entity/inventory records; `audit.json` records local source paths and should be treated as part of a personal map export.

UI references: [JourneyMap full-screen map](https://teamjm.github.io/journeymap-docs/latest/client/full-screen-map/) and [BlueMap map configuration](https://bluemap.bluecolored.de/wiki/configs/Maps.html). Neither project is a dependency or code fork.
