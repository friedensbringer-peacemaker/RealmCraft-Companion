# Metro and resource analysis implementation status

Checked snapshot: 2026-09-07 19:53 CEST  
Scope: active macOS implementation only; Android and web parity were not claimed.  
Purpose: record an evidence-backed intermediate state while implementation continues. This file does not mark the features released or complete.

## Classification used in this snapshot

| Classification | Meaning |
| --- | --- |
| Verified present | The current source path exists and its relevant automated check passed. This is not a substitute for GUI or game validation. |
| Existing defect | Already implemented or advertised behavior is demonstrably broken or internally inconsistent in the checked snapshot. |
| Incomplete feature | The implementation has not yet supplied the complete intended workflow. Absence is not classified as a regression. |
| Unverified behavior | Code or an assumption exists, but no controlled RealmCraft/GUI evidence establishes the real behavior. |

## Resource analysis

### Verified present

- The Atlas accepts a Shift-drag rectangle in world coordinates, keeps negative bounds inclusive, draws the selection and sends dimension plus X/Z limits through the native `atlasResources` bridge. The bridge validates the main frame, source map, dimension, coordinate range and a maximum of 4,096 chunks before storing the selection for the chosen save and opening Ore frequency. Evidence: `Resources/MapEngine/realmcraft_map/web/app.js` (`resourceBounds`, `sendResource`), `Sources/MapsView.swift` (`Coordinator.userContentController`).
- Ore frequency imports the selected X/Z bounds and expands the map selection to the full stored vertical range Y 0...255. Manual numeric bounds may still select a smaller Y range. Evidence: `Sources/OreResearchView.swift` (`loadMapRegion`, `runScan`).
- The Python decoder counts versioned world-block categories per layer and for the complete selected volume. Current groups include ores plus amethyst, chests, rails, spawners and planks. Inventory and chest contents remain explicitly out of scope. Missing, unreadable and unknown data are retained separately instead of becoming zero counts. Evidence: `Resources/MapEngine/realmcraft_map/ores.py` (`MATERIALS`, `scan`), `Sources/OreModels.swift` (`OreLevel.material`).
- The result view shows the current-layer count, full-volume count and layer share for each observed category, alongside existing ore rates and coverage information. Evidence: `Sources/OreResearchView.swift` (`resourceReport`, `censusResult`).
- Automated evidence for the resource implementation is green: the complete Python discovery suite passed 40/40, including the selected-area material-category test, and the resource-selection Node tests pass. The complete Atlas Node suite currently passes 56/57 because its orientation integration harness has not yet been updated for the new Metro dependency; that separate integration defect is recorded below.

### Existing defects in the final checked snapshot

No remaining resource-analysis defect was reproduced in the final frozen snapshot. During the audit, the **Only interesting layers / Nur interessante Schichten** toggle initially did not control navigation. The active implementation added `navigationLevels`, `stepLayer` and `OreLayerNavigation` plus normal/filter/wrap/empty tests. The corrected behavior was verified by the focused ore-model test. This resolved intermediate finding is not an open error.

### Incomplete, not classified as defects

- The selected analysis Y is not linked back to an exact-layer Atlas rendering with a synchronized cursor.
- The material categories are fixed in source; there is no separately versioned configurable profitability policy.
- The 16-subarea comparison, deterministic child-region aggregates and connected-deposit/cluster analysis are not implemented.
- There is no general persisted `WorldRegion`/`RegionAggregate` contract or aggregate cache shared by further map tools.
- Coverage is shown for the scan overall, but the resource table does not yet provide a per-category/per-child-area coverage drill-down.

### Idea status at this snapshot

| ID | Status | Evidence-based interpretation |
| --- | --- | --- |
| LAYER-001 | Present as an initial bounded-volume workflow | Map rectangle to verified full-height scan is connected and tested; a reusable general region contract is still absent. |
| LAYER-002 | Partially present | Existing Atlas slices and the analysis Y slider are separate views and are not synchronized. |
| LAYER-003 | Present for the current fixed categories | Current-layer and full-volume counts reconcile from the same `OreLevel` rows. |
| LAYER-004 | Partially present | Interesting-layer detection and toggle-controlled previous/next navigation are implemented and model-tested. A separately versioned profitability policy is still absent. |
| LAYER-005 | Missing/incomplete | No adjacent-subarea or deposit-connectivity result was found. |

## Nether Metro

### Verified present

- `CompanionFeature.metro` is in the macOS sidebar and opens `MetroView` as a clearly labelled Beta.
- `MetroNetworkStore.Document` persists versioned stations, lines and directed edges per save UUID outside savegame files. It validates IDs, bounds, referential integrity, dimensions and size limits. Rail/walk edges must remain inside one dimension; portal edges must cross dimensions. Evidence: `Sources/MetroModels.swift` (`MetroNetworkStore.valid`).
- Planned, built and confirmed states are distinct. Routing uses directed confirmed edges with measured durations and requires confirmed start and destination stations. No 8:1 conversion or inferred reverse portal edge is used. The missing validation of intermediate station status is recorded as a defect below. Evidence: `MetroStatus.routable`, `MetroNetworkStore.route`.
- The UI can add, rename and delete stations and lines; add and delete directed rail/portal/walk edges; render a deliberately schematic diagram; calculate a shortest-duration route; and copy a textual briefing. Evidence: `Sources/MetroView.swift`.
- The Atlas now injects the selected save's Metro document into the local map, renders geographic station markers and straight rail/walk connectors, accepts a selected map point or detected portal as a planned station, and persists it through a native bridge. The bridge restricts writes to the main frame, exact map file, selected save UUID, world, supported dimension and bounded integer coordinates. Its handler is removed when the web view is dismantled. Evidence: `Sources/MapsView.swift`, `Resources/MapEngine/realmcraft_map/web/metro.js`, `Resources/MapEngine/realmcraft_map/web/app.js`.
- The Metro bridge uses local JSON serialization and DOM `textContent`; no network transfer, embedded personal data or private path was found in the reviewed implementation. The resource-selection bridge remains a separate Shift-drag path with its own source, world, dimension, coordinate and area validation.
- `Tests/MetroModelsTests.swift` passed for validation, atomic persistence, planned-edge exclusion, directed confirmed routing, measured-duration requirements, cross-dimension safeguards and an A/B/A line-transfer count.
- The complete current Swift source passed `swiftc -typecheck`. A transient invalid multi-variable `@State` declaration observed earlier during concurrent implementation was corrected and is therefore not recorded as an open defect.

### Existing defects in the final checked snapshot

- **P2 – edits can appear saved without a selected savegame.** `MetroView` keeps its mutation controls active when `model.selected` is nil. `save()` then calls the optional store with `try store?.save(network)` and clears the error, so an added station appears in memory but disappears after reload or navigation. This is a persistence error, not missing future scope. Acceptance: disable all mutations without a selected save or fail before mutating state when no store exists.
- **P2 – a route can pass through an unconfirmed intermediate station.** `MetroNetworkStore.route` validates confirmed start and destination stations and confirmed edges, but not every station traversed by those edges. A confirmed A→B→C path is returned when B remains planned. This contradicts the UI's confirmed-route claim. Acceptance: require both endpoints of every usable edge to be confirmed and add a regression test.
- **P2 – the map can persist an invented Y coordinate.** Selecting terrain outside stored chunk coverage creates a point with `y: 64`; the Metro action remains enabled and saves that value as an ordinary planned station. The X/Z point is intentional, but Y=64 has no evidence. Acceptance: disallow station creation without a stored height or model the height explicitly as unknown/user-confirmed.
- **P2 – deleting a station silently cascades into connection deletion.** The station trash button immediately removes the station and every incident edge without confirmation or undo. Acceptance: show the affected edge count in a confirmation step or provide recoverable undo.
- **P2 – the Atlas Node integration suite is red.** `node --test Tests/*.test.cjs` passes 56/57; `orientation.test.cjs` fails with `ReferenceError: AtlasMetro is not defined` because its app harness does not load or stub the new dependency. Acceptance: load `metro.js` or provide a faithful stub and restore a green complete suite.
- **P2 – cached viewer refresh has no Metro version bump.** `MapController.restoreLast` still identifies the viewer as `annotations-2-signs-1-resources-1`. A cached map stamped with that same app/viewer version can skip copying the new `metro.js`, `app.js` and HTML integration. Acceptance: add a `metro-1` viewer-schema component and cover cache refresh.

During the audit, `MetroRoute.transfers` initially counted unique line IDs instead of consecutive transitions. The implementation now compares adjacent non-nil line IDs and the A/B/A regression assertion passes. That resolved intermediate issue is not open.

### Incomplete, not classified as defects

- Stations and lines can be renamed, but their coordinates/status and edge details cannot yet be edited in place; ordering is not user-controlled.
- Metro data is stored per save UUID. Carry-forward behavior and logical-world scope are not yet defined.
- Detected portals, recorded portal pairs and portal plans are not imported into the metro graph; evidence states are still separate.
- The Atlas overlay draws straight connectors between stored stations, not captured rail geometry. It has no shared station/edge editing selection with the schematic planner.
- There is no optimized four-direction/ring network generator, interchange editor or construction-progress workflow.
- Metro routes are not integrated with the existing terrain-aware `NavigationPack`, approach/departure walking legs, map instructions or AI/cloud exports.

### Unverified, not classified as defects

- RealmCraft portal scale, search radius, Y influence, tie-breaking, generated-exit orientation and reverse-link behavior remain unverified.
- Manually entered `confirmed` status records user evidence; the current code does not independently verify that a rail or portal connection exists in a save.
- No GUI interaction, real-world import, Quest validation or in-game route comparison was performed for this snapshot.

### Idea status at this snapshot

| ID | Status | Evidence-based interpretation |
| --- | --- | --- |
| METRO-001 | Partially present/unverified | Directed observations remain the safe basis; RealmCraft mechanics are still not established. |
| METRO-002 | Partially present | A bounded network model, local store and confirmed-edge router now exist; automatic network planning and portal evidence integration do not. |
| METRO-003 | Partially present | Named colored lines, a schematic diagram and a geographic Atlas overlay exist; captured rail geometry and interchange editing do not. |
| METRO-004 | Partially present | Confirmed network segments produce a copied briefing; terrain navigation, walking legs and full export integration remain absent. |

## Existing project issues outside the two active features

- **Still open:** `build.sh` defaults to the project-level `RealmCraft Companion.app` path, which is currently a symlink to the installed `/Applications` app. A plain build can therefore replace the installed bundle and copy resources into an existing destination. This is the pre-existing P1 build-destination defect from `AUDIT-2026-09-07.md`, not unfinished Metro/resource functionality.
- **Resolved since the first audit:** the Atlas orientation harness now loads `portals.js`; the former missing-`AtlasPortals` failure is closed. The newly introduced missing-`AtlasMetro` harness dependency is a separate current P2 defect recorded above.

## Snapshot identity and limitations

The macOS source directory has no Git metadata, and the files were being edited concurrently. Relevant SHA-256 values at 19:53 CEST were:

- `Sources/MetroModels.swift`: `c2dba65836e9994d2b24c375a141d45dc57caec87fd9fefd6f5ea72d10754022`
- `Sources/MetroView.swift`: `381d3a36c074ea74ac9a2e7dd9f4a47bf14f7d793345858b90f7db4ba00cc355`
- `Sources/OreModels.swift`: `50478ffe773803d282b0f103876b86520f3b09a9371235a3dd74ed38cc81e0bf`
- `Sources/OreResearchView.swift`: `2f0332d0f0cf19c7f5134b7d5fb1843f39bac07836fb4c1bacee4f542b3d4985`
- `Resources/MapEngine/realmcraft_map/ores.py`: `da3d58fa5cc944f8662e211641b88111be5a995f8ed8dfd7cbe73c345a0905fd`
- `Resources/MapEngine/realmcraft_map/web/app.js`: `46455d42259a4e79084d8e1dd9fb5c54b137ca7be434fd9cc3a6043f9afed7b4`
- `Resources/MapEngine/realmcraft_map/web/metro.js`: `bf3b24b156bf5571fa8e33d3db3011cdad1e7d05728b3b45b9f2068d89507079`
- `Sources/MapsView.swift`: `d777e5dc98879652e9401663ef4f529e4e445ba99bb64b5e76135dbb57dc1ec1`

Final focused validation: 40/40 Python discovery tests, Metro model test passed, ore model/navigation test passed, and the complete current Swift source passed type checking. The Atlas Node suite passed 56/57; its one reproducible missing-`AtlasMetro` harness failure is an open project defect, not an environment failure. One initial manual ore-test invocation omitted its required `Resources` argument and crashed while indexing `CommandLine.arguments`; rerunning it with the documented argument passed. That invocation error is not a project defect.

This snapshot should be superseded by a post-integration audit after the active implementation task finishes. No central feature map, architecture, backlog or changelog status was changed here, so unfinished work is not accidentally presented as released.
# September 9 Metro follow-up

This September 7 audit is retained as historical evidence. See [Metro workspace — 1.7.38](METRO-WORKSPACE-2026-09-09.md) for the new shared-map workspace, full record editors, captured paths, radial proposals, regression results and unresolved navigation/mechanics boundaries. Do not interpret the historical defect list below as the current implementation status.
