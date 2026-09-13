# Nether Metro workspace — 1.7.38 development integration

## Network assistant implementation · 1.7.47 (69) · 2026-09-13

The current macOS candidate adds manual and automatic planning side by side.
`MetroAutoPlanner.proposals` takes the current validated network, its Nether
origin, layout, ring count/spacing and local `MetroPlanPin` values. It returns
three independent proposals without persisting: a Prim minimum geometric tree,
square rings with radial axes and right-angle target branches, or rings/axes
with nearest-stop branches. Symmetry concerns the generated ground plan, not
terrain or existing construction. Ring stops and target stops propose portal
sites via optional station `portalCandidate`; this flag never confirms a portal.

Map clicks while the assistant is active collect pins with the existing validated
stored-height bridge. Manual coordinates permit unsaved areas without inventing
height. Pins can be renamed/removed; changed inputs invalidate previews. The
selected proposal drives `MetroDiagram` and `LocalMapWebView` using the same
tiles. Apply is explicit and participates in existing draft/stale-write guards;
source changes/discard clear proposals and pins. Existing stations, lines and
edges are retained unchanged; all added links are planned, directed and have
unknown time. Existing measured confirmed portal observations can anchor surface
targets; otherwise surface pins remain disconnected and unconverted.

Changed files: new `Sources/MetroAutoPlanner.swift` and its synthetic tests,
`Sources/MetroModels.swift` (backward-compatible optional flag),
`Sources/MetroView.swift`, narrow station-payload change in `Sources/MapsView.swift`
and portal-site glyphs in `Sources/MetroDiagram.swift` and `web/metro.js`. The
viewer refresh stamp advances only the Metro component, preserving resource/tool
versions. English Backlog/Changelog and this section
are inventoried with the new UI/notes in the central translation catalog.
No savegame, portal store, terrain decoder or installed app is changed.

Remaining: verified portal mechanics, terrain/coverage and material-cost scoring,
automatic rail tracing, native full-window acceptance and Android/web parity.
Geometric shortest construction is not shortest travel time. Directed portal
evidence is not promoted into an assumed reverse route.

Verification for this assistant increment: final full native Swift executable
build passed; the binary's `--list` smoke test against an isolated empty temporary
library exited successfully. `MetroAutoPlannerTests` and existing
`MetroModelsTests` passed, including ring geometry, strategy comparison,
confirmed/ambiguous/unmeasured portal evidence, bounds, candidate persistence and
stale-proposal rejection. Atlas Node suite: 67/67; Python discovery from the
project root: 74/74 (including 17 translation-catalog regressions). Central
catalog validation and separate DE/EN native-resource generation passed.
Fixtures are synthetic. Full native click/keyboard/DE/EN acceptance and a signed
universal application bundle are not claimed for this increment; nothing was
installed or published. Inventory does not activate additional runtime locales.

## Goal and reviewed decisions

The original Nether Metro idea and subsequent user feedback require an actual planning workspace, not a long form below a decorative graph. The reference remains macOS. Review inputs were the feature-idea document and its index, `AUDIT-2026-09-07.md`, `IMPLEMENTATION-STATUS-2026-09-07.md`, `FEATURE-COORDINATION-2026-09-07.md`, the feature map/backlog and current map, portal, navigation and transport sources. Graphify's existing Swift graph was queried for MapsView, NavigationPack and PortalReader as secondary orientation; source code, not heuristic graph relationships, determines these contracts.

The implementation uses a directory → workspace → inspector layout. The center switches between a schematic graph and a specialized instance of the existing Atlas. Its map controls open as an overlay, preserving map space on narrow windows. The standard Atlas exposes Metro as a display layer; metadata editing belongs to the Metro workspace.

## Implemented

- Searchable station and destination directory, line filters and badges; native shared page header, action styles, segmented navigation and theme colors.
- Full station coordinates/status/name/destination editing; saved portals seed built stations without confirming travel. A selected Nether station is the main-portal origin. Removing a station requires confirmation including affected connections; removing a line preserves its stations/links and clears only the assignment.
- Editable N/S/E/W station-name and line-ID suggestions relative to the main portal. Canonical axes are N = −Z, S = +Z, E = +X, W = −X, independent of rotation/mirroring. Station and line names are separate; copied sign text does not add a dimension label.
- Bounded radial proposals: 1–16 stations, configurable 1–4096-block spacing, origin height and selected line. All new stations/links remain planned. No counterpart coordinates or assumed reverse links are generated.
- Native line ColorPicker. A direction-preserving, rank-compressed schematic shows actual graph edges, line colors, status dashes, main portal and interchanges; its visual lengths never enter routing. Dimensions occupy separate diagram panels.
- Shared geographic station/portal picking with explicit stored-height validation. Record rail/walk bend points on the same map, preview without persisting, then finish at the destination and save. Geometry must match the link endpoints and remain within one dimension; it is user-recorded evidence, not automatic rail detection.
- Geographic overlay: captured confirmed paths are solid, captured planned/built paths dashed, missing geometry dotted. Cross-dimension portal legs are not drawn as geographic shortcuts. The existing transport layer remains available for inspecting saved rail blocks at the selected height.
- Directed connection editing, independently planned reverse journeys, measured time fields and evidence notes. Routing requires confirmed start/intermediate/end stations and confirmed links with measured durations. Travel time is the sum of observations, not an assumed cart speed; unknown waiting time is excluded. Changes between assigned lines count even across an unassigned walk/portal connector.
- Journey leg cards, schematic highlighting, manual arrival checkpoints, navigation briefing copy and local network JSON export. The briefing reuses `NavigationPack.assistantInstructions` and its text sanitization, but is not a serialized NavigationPack or live in-game navigation.

## Shared interfaces and storage

| Interface | Contract / reuse boundary |
| --- | --- |
| `MapController` | Existing cache/generation/restore flow and map output. No second decoder, copied world or Metro-specific tile tree. Viewer signature adds `metro-2` to refresh old HTML/JS/CSS. |
| `LocalMapWebView` | Optional `metroWorkspace`, `metroDocument`, `metroFocus`, `metroPick` parameters; other consumers keep their defaults. Existing style/privacy injection and portal inventory are reused. |
| Native → web | `ATLAS_METRO` plus `atlas-metro-update`: snapshot/world, workspace flag, stations, lines, edges with optional xyz path, optional focus ID. Updates redraw the existing instance; only an explicit changed station focus recenters it. |
| Web → native | `atlasMetro` action `pick`, exact snapshot/world identity, dimension, integral X/Y/Z, `knownHeight: true`, optional saved portal ID. Main-frame and map-URL checks precede `MetroMapSelection.read`. The bridge selects a draft; it never persists it. Missing terrain height cannot silently become Y=64. |
| Shared selection | Metro instance intercepts station/path clicks before general map pickers; Shift-drag resource selection is disabled only in that instance. Standard Atlas behavior remains unchanged. General MapToolCoordinator migration is still open. |
| Portal evidence | `PortalReader` inventory is read-only. Saved portal IDs describe observed blocks, not a destination or safe arrival point. Existing directional pairs and assumed calculator plans are not automatically promoted into Metro links. |
| Network store | `.metro-networks/<save UUID>.json`, version 1. New optional fields `originID`, station `portalID`/`destination`, edge `path` preserve legacy decoding. Reads validate bounds/references. UI commits reject a changed on-disk document before replacing it and update in-memory state only after success. This is optimistic stale-state detection, not a cross-process transaction lock. |
| Navigation | Confirmed Metro legs and measured durations remain the source of truth. The current NavigationPack v1 is single-dimension; multi-dimension journeys must not be forced into it. |

## Changed files and concurrent work

Metro-owned: `Sources/MetroModels.swift`, `Sources/MetroView.swift`, new `Sources/MetroDiagram.swift`, `Tests/MetroModelsTests.swift`, new `Tests/metro.test.cjs`, `web/metro.js`, new `web/metro.css`.

Shared, narrowly changed: `Sources/CompanionView.swift` passes the existing MapController; `Sources/MapsView.swift` shares the webview/selection contract and refresh stamp; `web/app.js` adds Metro focus/picking and a workspace-only resource-selection guard, without replacing the concurrently developed resource mode; `web/index.html` loads Metro CSS and labels compass north; `Tests/orientation.test.cjs` loads the real Metro module; `Tests/test_maps.py` checks Metro viewer assets are packaged. Web paths are relative to `Resources/MapEngine/realmcraft_map/`.

Documentation: English `Resources/BACKLOG.md` and the existing 1.7.38 `Resources/CHANGELOG.md` entry, `docs/FEATURE-MAP.md`, this note and links from the historical coordination/status records. Concurrent ore/resource release notes are retained. No ore decoder, resource model, portal store, navigation engine, savegame or installed application is modified by this Metro work.

## Open dependencies and acceptance boundaries

- **INT-001 / METRO-001:** portal scale, search, height, generated exit and reverse-link mechanics remain unverified. Controlled game-version-specific tests are required; no 8:1 claim is introduced.
- **INT-002:** unify map-tool cancellation/activation across all tools in a later migration. Current specialization is an isolated instance; path capture is ended in its inspector. Standard Atlas resource selection is preserved.
- **INT-003:** persistence is explicitly snapshot-local. Carry-forward, portal-evidence reconciliation and cross-process locking remain open. Do not silently mix worlds or confirm reused records.
- **INT-004 / METRO-004:** terrain-validated approaches/departures, multi-dimension NavigationPack/export and spoken-section adapter remain open. Current manual checkpoint progression is not live tracking or terrain pathfinding.
- **METRO-003:** automatic rail topology with branch/height/coverage evidence, ring optimization, dense-network label management and geographic line-offset rendering remain open. User destination/biome notes are supported; automatic biome destination optimization is not.
- **INT-006:** Android/Quest/web-app parity and shared cross-platform fixtures remain open. The Atlas module is shared locally, not a claim that the web demo ships Metro editing.

## Verification

All fixtures and screenshots are synthetic; no personal portal coordinates, names or real save data are included.

- Full arm64/macOS 14 Swift source typecheck: passed for the Metro-final frozen source. A later combined recheck was deliberately stopped when the parallel resource work requested exclusive compiler capacity after changing its own `HelpView.swift`, `OreModels.swift` and `OreWorkspaceView.swift`; that workstream owns the final combined recheck/build.
- `MetroModelsTests`: passed for legacy decoding, bounded persistence, stale-write rejection, confirmed directed routing, transfer counting, relative naming, radial proposals, recorded path validation and missing-height rejection.
- Complete Atlas Node suite: 62/62 passed. The real Metro module is loaded by the orientation harness; focused cases cover transformed station/portal picking, live updates, privacy/read-only behavior, line styles and suppression of resource-region writes in the Metro instance.
- Python discovery suite: 42/42 passed, including generated-map packaging of `metro.js` and `metro.css`.
- Native production-view rendering: passed in English at 1200 × 820 and German at 1020 × 820 with a synthetic two-dimension interchange network. The narrower render verified stacked dimension panels and complete station-editor access. Review images are in `outputs/metro-workspace-2026-09-09/` outside the application source directory.
- Real WebKit map render: passed against a generated 64-chunk synthetic Nether. The base tiles, confirmed/planned colored paths, direction arrows, labels, compact controls, north compass and map drawer rendered without JavaScript errors. A real center click dispatched the native Metro message with the stored Y value; missing-Y rejection is separately tested.
- Frozen universal 1.7.38/60 Metro application build: passed for arm64 and x86_64. The temporary bundle is ad-hoc signed, passes deep signature verification, has executable mode 0755, reports the expected bundle/build versions, and its shared-source archive contains the new Metro Swift and web assets. A CLI `--list` smoke test against an empty temporary library exited successfully. This bundle predates later resource-workstream edits and is therefore a Metro verification artifact, not the final combined installation.

The temporary QA application and synthetic library were not installed. The project application symlink and `/Applications/RealmCraft Companion.app` were not changed.
