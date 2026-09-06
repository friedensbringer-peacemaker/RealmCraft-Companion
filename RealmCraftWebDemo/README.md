# RealmCraft Companion · Web Demo

**100 % mit OpenAI Codex entwickelt / 100% vibe-coded with OpenAI Codex**  
AI contributor: **Codex Astra**

An independently runnable, static browser edition of selected Companion features. The interface is German. It opens directly on an interactive map and works without a backend, account, API key or installation.

## Try it

Open the GitHub Pages link shown in this repository's About section. The deployment publishes only this project's assembled web files.

- **World map:** pan, zoom, height colors, chunk grid, chest markers, coordinate lookup and named places. Keyboard controls: arrows, +/− and F. Coordinate lookup also provides a keyboard-accessible alternative to canvas picking.
- **Chests and resources:** search names, materials or coordinates, mark ownership, filter owned chests, inspect stock totals and locate a chest on the map.
- **Inventory sandbox:** select a slot, change quantities, move or duplicate a stack into an empty slot, sort and undo. These operations only change example data in memory.
- **Build guides:** the Companion's original guide catalog, shopping checklists, step navigation, paired top/side diagrams, evidence notes and source links.
- **Recipes:** searchable reference catalog and direct-ingredient material checks for a bed or crafting table. Counts include only explicitly owned demo chests; inventory and intermediate crafting are excluded.
- **Context export:** download the current demo inventory, chests and places as Markdown or JSON. Nothing is sent to an AI service.

All map terrain, coordinates, chest contents and inventory are **deterministically fabricated examples**. No real world, savegame, screenshot, player export or device data is included. Map terrain is schematic; it does not reproduce RealmCraft world generation. Ownership marks are user annotations, not inferred ownership. The map's surface height and a chest's saved example height may differ, as underground chests are also shown.

Changes last for the current page session. Download a context before reloading if you want to keep a record. Resetting the demo requires confirmation. The web edition cannot import, patch or restore a real savegame. Guide and recipe evidence limitations from the Companion remain visible; a web rendering does not prove in-game compatibility.

## Run locally

Requirements: Python 3.10+ and Node.js 22+ for checks. There are no npm dependencies.

```sh
node --test tests/*.test.cjs
python3 tools/build.py
python3 -m http.server 8080 --directory dist
```

Open `http://localhost:8080`. A local HTTP server is needed for the catalog JSON requests; opening HTML directly as a file is unsupported.

## Provenance and maintenance

`data/BuildGuides.json` and `data/ConversationRecipes.json` are copied from the reviewed public Companion resources and retain their evidence and original reference links. `core.js` defines all synthetic examples and deterministic terrain in plain source; there are no embedded archives or opaque world-data payloads. The source and bundled catalogs use the repository's MIT license, reproduced in `LICENSE`. This unofficial community project is not affiliated with Tellurion Mobile.

The deployment workflow runs the core regression tests and validates catalog topology before building. `tools/build.py` selects six web files explicitly and writes a SHA-256 asset manifest. No files from the surrounding Companion workspace are served. Layout is responsive; no external fonts, textures, trackers, analytics or runtime dependencies are loaded.

## Update log

### 0.1.0 — 2026-09-06

- Added six working browser views: map, chest search and ownership, inventory sandbox, build guides, recipes and context export.
- Added deterministic synthetic data, ownership-separated material totals, immutable inventory edits and undo.
- Matched the native Block World palette, system typography and compact panels; navigation uses a bottom underline for active, hover and keyboard-focus states.
- Added static GitHub Pages packaging, source-backed catalog validation and functional core regression tests.

## Backlog

- Add an English interface using the catalogs' existing English content.
- Consider a separately reviewed optional real demo-world map after selecting its publication snapshot.
- Extend browser automation coverage and add persistent, importable demo annotations.
