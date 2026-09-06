# RealmCraft Companion · Web Demo

**100 % mit OpenAI Codex entwickelt / 100% vibe-coded with OpenAI Codex**  
AI contributor: **Codex Astra**

An independently runnable, static browser edition of selected Companion features. English is the default interface language; the header switch offers English and German and remembers the choice locally. It opens directly on an interactive map and works without a backend, account, API key or installation.

## Try it

Open the GitHub Pages link shown in this repository's About section. The deployment publishes only this project's assembled web files.

- **World map:** pan, zoom, height colors, chunk grid, chest markers, coordinate lookup and named places. Keyboard controls: arrows, +/− and F. Coordinate lookup also provides a keyboard-accessible alternative to canvas picking.
- **Chests and resources:** search names, materials or coordinates, mark ownership, filter owned chests, inspect stock totals and locate a chest on the map.
- **Inventory sandbox:** select a slot, change quantities, move or duplicate a stack into an empty slot, sort and undo. These operations only change example data in memory.
- **Build guides:** the Companion's original guide catalog, shopping checklists, step navigation, paired top/side diagrams, evidence notes and source links.
- **Recipes:** searchable reference catalog and direct-ingredient material checks for a bed or crafting table. Counts include only explicitly owned demo chests; inventory and intermediate crafting are excluded.
- **Context export:** download the current demo inventory, chests and places as Markdown or JSON. Nothing is sent to an AI service.

The initial map, chests and inventory are **deterministically fabricated examples**. The **Demo-ZIP laden** button loads the previously reviewed public demo world, shared with the Android Companion. **Eigene ZIP öffnen …** reads a selected local savegame entirely in a Web Worker in the browser; it never uploads the file. Map terrain is schematic; it does not reproduce RealmCraft world generation. Ownership marks are user annotations, not inferred ownership. The map's surface height and a chest's saved example height may differ, as underground chests are also shown.

Changes last for the current page session. Download a context before reloading if you want to keep a record. Resetting the demo requires confirmation. The web edition can read supported ZIP savegames, but cannot patch or restore them. Sandbox edits change only the in-memory view and context exports; they do not produce a playable savegame ZIP. Guide and recipe evidence limitations from the Companion remain visible; a web rendering does not prove in-game compatibility.

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

The deployment workflow runs core and ZIP-reader regression tests and validates catalog topology before building. `tools/build.py` selects web files explicitly and writes a SHA-256 asset manifest. The pipeline downloads only the previously reviewed demo release asset, verifies the checksum pinned in `demo-source.json`, and packages it separately as `demo.zip` in the Pages artifact. Raw save files are not committed to Git. No files from the surrounding Companion workspace are served. Layout is responsive; no external fonts, textures, trackers, analytics or runtime dependencies are loaded.

## Update log

### 0.3.0 — 2026-09-06

- Added English by default and a persistent English/German switch across navigation, controls, catalogs, imports and map details. Switching language preserves the in-memory world, inventory edits, annotations and checklists.
- Added searchable points of interest with cyclic previous/next navigation for signs, chests and saved markers, scoped to the selected dimension.
- Added a sign overlay and read-only sign inscriptions. Empty and unreadable inscriptions remain distinct; world names, marker labels and sign text are never translated as UI text or interpreted as HTML.
- Verified the published demo contains two readable wall signs. Its block-173 records use the same bounded 00-a2 text serialization as the previously supported block-162/172 records. This is a narrow web-reader extension; other unverified sign variants retain locations with text unavailable.

### 0.2.0 — 2026-09-06

- Added local ZIP opening and a checksum-verified shared public demo download.
- Added strict read-only ZIP, v9 terrain/chest and v2 player decoders, with world selection, cancellation, bounded extraction, CRC checks and atomic data replacement.
- Connected loaded terrain, dimensions, chest searches, ownership, inventory, material checks and context exports to the same imported snapshot.
- Preserved missing/unreadable inventory and chest states explicitly; source files remain untouched.

### 0.1.0 — 2026-09-06

- Added six working browser views: map, chest search and ownership, inventory sandbox, build guides, recipes and context export.
- Added deterministic synthetic data, ownership-separated material totals, immutable inventory edits and undo.
- Matched the native Block World palette, system typography and compact panels; navigation uses a bottom underline for active, hover and keyboard-focus states.
- Added static GitHub Pages packaging, source-backed catalog validation and functional core regression tests.

## Backlog

- Extend browser automation coverage and add persistent, importable demo annotations.

## ZIP help / ZIP-Hilfe

**Deutsch:** Oben „Demo-ZIP laden“ oder „Eigene ZIP öffnen …“ wählen. Die Demo wird zuerst heruntergeladen und gegen die veröffentlichte Prüfsumme geprüft. Bei mehreren Welten die gewünschte Welt auswählen und „Ausgewählte Welt öffnen“ bestätigen. Erst der fertige Import ersetzt den bisherigen Datenstand einschließlich Sitzungsänderungen. Eine neue ZIP mit neuen Daten kann jederzeit genauso geöffnet werden; ein Neubau der Website ist dafür nicht nötig. Dateien bleiben lokal, werden nicht auf GitHub hochgeladen und nicht verändert. Ein Fehler oder Abbruch lässt den bisherigen Stand stehen. Eigentum ist anfangs unbekannt; eigene Kisten bewusst markieren. Fehlende Spielerdaten sind unbekannt, nicht leer. „Demo zurücksetzen“ kehrt zu den synthetischen Beispielen zurück. Bauanleitungen und Rezepte sind feste Referenzkataloge und kein Bestandteil eines Savegames.

**English:** Choose “Demo-ZIP laden” to fetch the reviewed public demo or “Eigene ZIP öffnen …” to open a local ZIP. Select the desired world and confirm “Ausgewählte Welt öffnen”. A completed import replaces the current snapshot and session edits together. Opening a new ZIP immediately uses its updated data without rebuilding the website. No local file is uploaded or modified. Failure or cancellation preserves the previous snapshot. Ownership starts unknown; mark owned chests explicitly. Missing player data remains unknown rather than empty. Reset returns to the synthetic examples. Build guides and recipes are reference catalogs rather than savegame contents.

Supported ZIPs contain `world_data` and `o.X,Z` / `n.X,Z` files at one level, optionally inside a world folder. Multiple such folders are selectable. The observed v9 world/chunk and v2 player layouts are supported; unsupported chunks are reported, and completely unreadable terrain is rejected. Nether shows the highest block up to Y 90. The map uses saved surface blocks, not textures or visited-area history. ZIP Store and Deflate are accepted, with a current browser supporting `DecompressionStream("deflate-raw")`. ZIP64, multipart/encrypted archives and links are rejected. Limits: 128 MiB compressed, 512 MiB declared expanded, 8 MiB per entry, 40,000 ZIP entries and 16,000 chunks per world. Extraction is bounded and verifies CRCs; no archive path is written to disk. Uploaded ZIPs are not restored to the Quest.

### Updating the shared public demo

The hosted demo is deliberately checksum-pinned. Replacing a release attachment alone does **not** silently publish unreviewed game data. After reviewing a newly uploaded demo ZIP, update its release/asset and SHA-256 in `demo-source.json` and push the reviewed change, or run the Pages workflow again once its configuration matches. The workflow fetches and verifies the selected archive; all visitors then load the new data. Only the explicitly approved demo world may be published through this route. Local ZIP opening requires neither publication nor a configuration change.

For a local preview that includes the hosted-demo button, pass the reviewed archive to the build:

```sh
python3 tools/build.py --demo-zip /path/to/reviewed-demo.zip
```

The `WorldCatalog.json` item names, block names and original schematic colors derive from the reviewed Companion catalog and map palette under the same license. Parser tests use fabricated data; the existing public demo ZIP is used only as a separate integration check.

## Language and points of interest / Sprache und interessante Punkte

**English:** Choose English or Deutsch in the header. English is used on first visit; only your language choice is stored in browser storage. Imported save data stays in the current session. Build guides, recipes and item names use the Companion's existing bilingual catalogs. Sign inscriptions and custom names stay in their original language. In Maps, use Points of interest to filter Signs, Chests or Saved markers. Search by inscription, label or coordinates, then use the arrow buttons to move between matches. Signs are shown at their saved positions regardless of surface height. Switch dimension to browse that dimension's points. The overlay checkbox controls the sign symbols; point navigation and details remain available independently.

**Deutsch:** Oben English oder Deutsch wählen. Beim ersten Besuch startet die Seite auf Englisch; nur die Sprachauswahl wird im Browser gespeichert. Geladene Spielstände bleiben in der laufenden Sitzung. Bauanleitungen, Rezepte und Gegenstände verwenden die vorhandenen zweisprachigen Companion-Kataloge. Schildtexte und eigene Namen bleiben im Original. Unter Karten → Interessante Punkte nach Schildern, Kisten oder eigenen Markierungen filtern. Beschriftungen, Namen oder Koordinaten suchen und mit den Pfeilen durch die Treffer wechseln. Schilder erscheinen an ihren gespeicherten Positionen, auch unter der Oberfläche. Die Dimensionsauswahl begrenzt die Treffer. Die Schild-Ebene steuert die Symbole unabhängig von der Punktnavigation.
