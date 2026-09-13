# RealmCraft Companion feature map

Audit tooling is now implemented separately from application features: fresh
Demo-only profile preparation, guarded audit launcher, executable-content/signature
verification, a 20-destination/six-journey evidence record and sanitized helper
diagnostics. Fifteen synthetic tests and the Demo CLI preparation passed. The
approved native audit launch and bounded Demo startup check now passed; Home and
Help visual/AX reads and scrolling succeeded. The Ore transition was followed by
another identical helper crash during screenshot retrieval, so the stability gate
is blocked (10 matching reports). Both Companion processes remain running. No Companion UI
finding is marked fixed. See the [audit runbook](UI-UX-AUDIT-RUNBOOK.md) and the
implementation record at the top of the existing audit.

Audit transport diagnosis: macOS reports confirm repeated crashes of the Computer Use helper at the same Swift array-removal assertion. The 1.7.47 Companion process continued running; its recorded hash and signature were verified again. Exact UI trigger and remaining feature acceptance are still open. See the [diagnosis and completion plan](UI-UX-AUDIT-2026-09-12.md) before resuming native acceptance. No application fix or external issue was made.

Community-first audit of the running **1.7.47 (69)** candidate: all 20 destinations are indexed with evidence and next steps in [the UI/UX audit](UI-UX-AUDIT-2026-09-12.md). Initial live coverage reached Home, Player and Maps; library selection was checked through accessibility. A resumed pass reached Portal pairs, Metro, loaded Chests, Conversation/settings, one complete video article and partial build-guide interaction. Native UI transport failed again. Complete scrolling, remaining controls/dialogs, languages/themes and VoiceOver acceptance are still open; reached screens are not automatically passed. Findings UX-018–022 cover blank-map recovery, Go shortcut collisions, truthful recipe-search coverage, typed answer-to-screen handoffs and chest density/icon alignment. This is an audit, not a new feature release or a claim of full native acceptance.

Translation foundation on the 1.7.47 source baseline: `Resources/Translations/catalog.json` and `translation_catalog.py` provide a shared DE/EN inventory, target-language drafts/review states, source locations, scoped JSON export and all-or-nothing validated import into a new candidate. `make_localizations.py` consumes the native interface subset. Recognized Swift/content/document entries are an inventory for migration; additional selectable app languages, full extraction, native import/share controls and Android/web adapters remain open under L10N-001–004 in `Resources/BACKLOG.md`. See the [contribution guide](../Resources/Translations/README.md).

Additional live Help check: full topic-list scrolling, complete Crafting and Material plan articles, related-topic/back navigation and no-result recovery succeeded. UX-023 records remaining help-grouping/title/readability and type-first-browsing explanations. The subsequent Statistics transition and screenshot-only fallback failed at the automation transport; Statistics and the remaining live matrix are not accepted. This does not establish an application crash.

## Type-first crafting and matching navigation · 1.7.47 (69) · 2026-09-12

- Crafting's item browser groups known item types before sorting material/color variants within each type, using explicit longest-match ID suffixes and DE/EN family headings. Ordinary boats, chest boats, rafts, fence gates, trapdoors, pickaxes and other distinct types remain separate. Unknown/special items keep their full title and independent identity. This changes presentation only: original item IDs, icons, recipe alternatives, filters, material-plan targets and evidence remain unchanged. Global Quick find and other ingredient pickers retain their existing search order.
- The Home explanation “What each section does”, sidebar and Go menu now share `CompanionNavigationGroup`. The overview includes matching group headings and Help, with specialist tools last. All 20 destinations and their original shortcut assignments remain intact. Metadata lives in `Sources/CompanionFeature.swift` so order and help-target regressions can run without the app model.
- No RealmCraft crafting mechanic was verified by this change. The bundled comparison recipes distinguish oak, birch and acacia boats and their corresponding planks; grouping does not make their ingredients interchangeable.


1.7.46 usability package: top persistent knowledge search and category filters, four task-based Home entries, expandable specialist navigation (all 20 stable destinations), page-purpose/context-help rows, source details including Conversation, visible backup import, localized labels, collapsed recipe filters/statistical limitations, single-sheet guide-to-plan review, feedback draft protection and the Metro line-to-connection guard repair. Source evidence and remaining UX-008–017 work are recorded at the top of `UI-UX-AUDIT-2026-09-12.md`; older review notes below are historical. No installation, full native acceptance or cross-platform parity is implied.

New-user review against 1.7.45: all 20 macOS destinations and principal dialog families are indexed in `UI-UX-AUDIT-2026-09-12.md`. UX-008–017 are proposed follow-up work, including a source-confirmed Metro line-to-connection draft-guard gap (UX-015). This does not change implemented feature status or establish native acceptance.

1.7.45 follow-up: shared backup context, guarded Metro/portal/trial/material-plan drafts, adaptive headers/Metro panes, local four-catalog Quick find and reviewed guide-to-plan material import are implemented. Help has 48 DE/EN topics. These source features do not establish native acceptance, installation or Android/web parity; see `INTEGRATION-2026-09-11.md`.

Baseline audit: 2026-09-07; resource/Metro follow-up: 2026-09-09; inventory reconciliation: 2026-09-11  
Reference implementation: macOS source through 1.7.44 development candidate; other platform rows retain the baseline audit  
Related audit: [AUDIT-2026-09-07.md](AUDIT-2026-09-07.md)  
Idea comparison: [IDEAS-2026-09-07.md](IDEAS-2026-09-07.md)

This map records implemented behavior found in source. “Partial” means that a narrower workflow exists; it does not imply full cross-platform parity. Android and web remain independent, read-only adaptations unless stated otherwise.

| Area | macOS | Android/Quest 0.9.0 | Web 0.4.1 | Primary evidence and direct dependencies |
| --- | --- | --- | --- | --- |
| Home and navigation | Present: Home plus 19 destinations in three groups | Present: map-focused native activity and compact navigation | Present: six responsive routes | `Sources/CompanionView.swift` (`CompanionFeature`, `CompanionView`); Android `MainActivity`, `SnapshotActivity`; web `index.html`, `app.js` |
| Savegame library | Present: import, backup, verification, deduplication, export, restore and organization | Present: immutable local snapshots, ZIP/Shizuku import, deletion and ZIP export; no restore | Partial: session-only ZIP reader; no persistent library or restore | `Sources/Library.swift`, `Sources/SavegameOrganization.swift`; Android `SnapshotStore`, `WorldAccessService`; web `save-reader.js` |
| Player, inventory and equipment | Present: native bounded player reader, durability and enchantments | Present: read-only player/equipment/inventory | Partial: imported inventory and level feed the sandbox/export; no full player page | `Sources/PlayerModels.swift`, `Sources/PlayerStorage.swift`, `Sources/PlayerView.swift`; Android `PlayerReader`; web `save-reader.js`, `core.js` |
| Maps and coordinates | Present: local Python renderer, embedded atlas, rotation/mirroring, height slices, POIs and 3D beta | Present: bounded streamed maps, slices, cache, POIs and bookmarks | Present: bounded local ZIP map with orientation and POIs | `Sources/MapsView.swift`, `Resources/MapEngine/realmcraft_map/`; Android `SurfaceMapView`, `SnapshotAnalysis`; web `imported-map.js`, `orientation.js`, `points.js` |
| Ore research | Present: bounded census, linked layer map and ledger, multi-material line/heatmap/bar charts, adjacent-area comparison, height/biome results, sampling and trial workflow | Absent | Absent | `Sources/OreModels.swift`, `Sources/OreResearchView.swift`, `Sources/OreWorkspaceView.swift`, `Sources/OreDistributionView.swift`, `Resources/MapEngine/realmcraft_map/ores.py`; [2026-09-09 integration](RESOURCE-WORKSPACE-2026-09-09.md) |
| Portal records and planning | Present: detected portal groups, directed observed pairs, map plans and explicitly assumed 8:1 conversion | Absent | Absent | `Sources/PortalModels.swift`, `Sources/PortalPlans.swift`, `Sources/PortalsView.swift`, map `portals.js` |
| Nether Metro | Partial: integrated station/line/link/trip workspace, origin-relative radial proposals, shared Atlas picking, editable captured paths, schematic interchanges and measured confirmed-edge journeys | Absent | Absent | `Sources/MetroModels.swift`, `Sources/MetroView.swift`, `Sources/MetroDiagram.swift`, shared `LocalMapWebView` and `web/metro.js`; no automatic rail tracing or portal prediction |
| Tectonicus rendering | Present, experimental Overworld adapter and local preview | Absent | Absent | `Sources/TectonicusView.swift`, bundled Tectonicus tools and tests |
| Chest explorer | Present: scan, search, ownership, labels, sorting, statistics and export | Present: bounded read-only contents, search and stock calculations | Present: read-only contents, ownership annotation and totals | `Sources/ChestModels.swift`, `Sources/ChestsView.swift`, `Sources/ChestStatistics*`; Android `ChestReader`, `ChestStock`; web `save-reader.js`, `core.js` |
| World statistics | Partial: verified build/dig counter and selected comparisons; unavailable metrics remain explicit | Partial: snapshot differences and coverage summaries | Absent as a dedicated area | `Sources/StatisticsModels.swift`, `Sources/StatisticsView.swift`; Android `SnapshotDiff` |
| Savegame editor | Present as beta: new-copy item/level patches and separately confirmed test-world transfer | Intentionally absent/read-only | Intentionally absent/read-only; inventory changes are sandbox-only | `Sources/SaveEditor.swift`, `Sources/SaveEditorStorage.swift`, Python `editor.py` |
| Distance and route planning | Present: distance/profile estimates, movement assumptions, obstacle-aware candidate route, turn cues and export | Partial: straight-line collection ordering and manual-reference distances | Absent | Map `measure.js`, `navigation.js`, `transport.js`; `Sources/NavigationExport.swift`; Android `CollectionRoute` |
| AI context export | Present: Markdown/JSON, world data, selected skills, optional video knowledge and navigation | Partial: snapshot and notebook transfer are different formats/purposes | Present: session context Markdown/JSON without skills | `Sources/AIContextExport*.swift`, `Sources/AIExportSharing.swift`; Android `NotebookTransfer`; web `app.js` |
| Local conversation and speech | Present: deterministic local knowledge plus optional local models and on-device speech | Absent | Absent | `Sources/Conversation*.swift`, `Sources/ConversationKnowledge.swift` |
| Agent skills | Present: seeded skills, editing, version-safe persistence, import/export and export handoff | Absent | Absent | `Sources/AgentSkills.swift`, `Sources/AgentSkillsView.swift`, `Resources/AgentSkills/` |
| Build guides and recipes | Present: 95 guides, 3D/step views, material checklists, ten conversation references and a standalone crafting workspace (1.7.40 candidate): 821 explicitly unverified comparison recipes / 588 outputs, all 1,206 name entries browsable | Absent | Partial: 46 guides and ten recipes in the last documented parity audit | `Sources/BuildGuide*.swift`, `Resources/BuildGuides.json`, `Resources/ConversationRecipes.json`, `Sources/CraftingCatalog.swift`, `Sources/CraftingView.swift`, `Resources/CraftingCatalog.json`; web `app.js`, `data/` |
| Videos and knowledge | Present: indexed videos, timestamped tips, speech and exports | Absent | Absent | `Sources/BuildGuidesView.swift` (`VideoTipsView`), `Sources/VideoKnowledgeExport.swift` |
| Mobs and resources | Present: sourced catalog, optional artwork, comparison knowledge and links | Absent beyond map/player catalogs | Absent beyond guide/recipe/item catalogs | `Sources/MobModels.swift`, `Sources/MobsView.swift`, `Sources/ResourcesView.swift` |
| Help, setup and feedback | Present: 47 bilingual topics, related navigation/search, synchronized device/map setup and feedback package | Partial: bilingual setup/map guide and test documentation | Partial: inline ZIP/orientation help | `Sources/HelpContent.swift`, `Sources/HelpView.swift`, `Resources/HelpArticles.json`, `Sources/Setup*.swift`, `Sources/Feedback*.swift`; Android docs/UI; web `README.md` and route help |

## Shared capabilities worth reusing

### 1.7.44 addition: help and whole-navigation audit

`HelpContent` loads and validates `Resources/HelpArticles.json` with 47 bilingual topics and existing document resources. `HelpView` provides related-topic/back navigation, bilingual token search and matching selection/no-results behavior. Setup and embedded agent instructions are synchronized. The [UI/UX audit](UI-UX-AUDIT-2026-09-12.md) records all 20 destinations, principal dialogs and bounded integration orders; those non-help redesigns remain recommendations, not implemented changes.

### 1.7.43 addition: recipe material plan

`CraftingPlan`, `CraftingPlanCalculator`, `CraftingPlanStorage` and `CraftingPlanView` add a saved multi-target direct/recursive ingredient plan to the existing recipe catalog. Shared demand is rounded once per chosen production route. Explicit alternatives, supply stops, cycles, changed-catalog and quantity guards preserve uncertainty; copy/text export retains provenance. `PlanningStore` is reused with a separate lock. `CraftingConversation` adds extended local recipe lookup, numbered variants and quantity followups; the saved plan can be read aloud. `CraftingIcons` reuses optional packs by explicit item ID across recipes, plan lists and Conversation search, with persistent text-only preference and neutral fallback. No personal-stock adapter, fuel estimate or newly confirmed RealmCraft recipes. Android 0.10.0 has source-level lookup/planner/on-device speech integration using the same catalog, but APK/device acceptance remains pending; web is unchanged. Tests: `Tests/CraftingPlanTests.swift`, `Tests/CraftingConversationTests.swift`, `Tests/CraftingIconTests.swift`; integration/acceptance: [current candidate](INTEGRATION-2026-09-11.md). The platform table above describes the earlier documented build baseline; this paragraph records the newer development candidate.

### 1.7.42 additions: presentation, connectivity and local notifications

- `OrePresentation` provides relative camera persistence and local PNG annotation; the existing cutaway can open in a larger sheet without a second renderer.
- `OreCluster` provides measured six-face material connectivity, count/height range, visible-slice highlighting and explicit boundary/missing/cap warnings. This is not geological classification or excavation safety.
- `MapNotifications` provides optional background-only macOS completion notices through an injectable system client; permission denial and delivery failure retain the existing in-app result.
- See [integration register](INTEGRATION-2026-09-11.md) for actual verification and remaining operating-system/full-app acceptance.

### 1.7.41 addition: native ore-layer cutaway

Ore frequency now offers 2D/3D layer exploration directly from validated contiguous census data. The selected Y is the ceiling of a 1/4/8-layer slice. Reusable material colors, optional selected-only rendering, bounded 64×64 window movement, orbit/zoom/reset and exact XYZ block picking feed existing tunnel/Atlas callbacks. Missing data uses flat violet markers; air, hidden cells and unknown block IDs stay distinct. There is no second binary decoder or inferred geometry for aggregate-only/random-sample reports. `OreLayerMesh`, `OreLayer3DView` and the extracted shared `BuildOrbitSceneView` are the implementation boundaries. See [resource integration](RESOURCE-WORKSPACE-2026-09-09.md) for verification and remaining acceptance.

### 1.7.40 additions (development candidate, not installed)

- Maps: independent verified background input, continued app navigation, persistent in-app completion/Open map, cancellation and separate cache locking. Experimental Tectonicus is unchanged.
- Metro: named snapshot-local saved journeys, manual progress, network-fingerprint invalidation and dimension-aware JSON/Markdown export. No live tracking or terrain-aware cross-dimension routing.
- Ore research: named world-scoped analysis presets, separate from measurements and results.
- Statistics: verified file-level chunk-change map, filtering, centering, zoom and JSON export. Missing is not empty; file changes are not block-change counts.
- Savegame library: verified unchanged-file reuse with selective ADB transfer and full-transfer fallback. Full before/after remote hashing is retained.

Evidence, ownership and outstanding GUI acceptance: [Integration register](INTEGRATION-2026-09-11.md). Primary new models: `MetroJourney.swift`, `PlanningStore.swift`, `OrePreset.swift`, `ChunkChanges.swift`, `IncrementalBackup.swift`, `MapSnapshotInput.swift` and `MapCacheLease.swift`.

| Capability | Current owner | Consumers | Reuse note |
| --- | --- | --- | --- |
| Verified snapshot access | `Library` and `Savegame` | player, maps, ores, portals, chests, statistics, editor, AI export | Keep integrity checks and immutable-copy rules at this boundary. |
| Full block decoder | Python `chunks.decode` | maps, ore census, chests, signs, editor and Tectonicus conversion | New layer analysis should use this decoder or a versioned neutral output, not add a fourth macOS decoder. |
| Compact map columns | Python `Chunk.columns` plus JS `AtlasColumns`/`AtlasLayers` | surface map, height slices, transport overlays, block lookup and 3D | Suitable for display and point lookup; volume counting still needs full decoded chunks or a new aggregate cache. |
| Map coordinate transform | JS `geometry.js` | map drawing, picking, rotation, mirroring, markers and navigation | All new selection tools must remain in world coordinates and use this transform only for display. |
| World annotations | `Savegame.annotationScope` and scoped `UserDefaults` keys | markers, names, ownership, conversation and exports | Portal plans currently use save IDs instead; decide whether metro plans should follow the world annotation scope. |
| Map tool state machines | `MapToolCoordinator`, existing tool-specific models | measurement, ownership, portal plans, resource selection and Metro capture | Shared activation and Escape/dimension/privacy cancellation; pending writes block ordinary tool switching. Generalized region/volume selection remains open. |
| Metro network model | `MetroNetworkStore`, `MetroCarryForward` | Metro workspace, schematic, Atlas overlay, copy preview and travel briefing | Carry-forward requires an older same-world source and empty target, revalidates portal evidence and resets all stations/links to planned. Only confirmed measured directed links are routable. |
| Resource target handoff | `MapFocusTarget`, `AtlasFocusTarget` | Ore workspace, Atlas, existing navigation/export | Snapshot, dimension and exact XYZ are preserved. Surface approach only; descent remains explicitly unplanned. |
| Cross-platform fixtures | Separate Swift/Python/Java/JS tests | save/chunk/player/chest readers | Consolidate canonical fixture vectors and expected JSON to reduce parser drift without forcing shared UI code. |

## Known documentation boundaries

- macOS is the product reference; platform parity must be stated per capability, not as a percentage.
- A compiled menu entry is not sufficient evidence of runtime behavior. Device-only and GUI-only paths remain unverified unless the audit says otherwise.
- Minecraft rules, names and formulas are comparison material until verified against a named RealmCraft version and controlled evidence.
