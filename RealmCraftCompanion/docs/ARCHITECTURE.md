# RealmCraft Companion architecture

1.7.45 integration contracts: `Model.drafts` owns a live dirty-state registry; guarded source selection and feature routing authorize transitions before mutation. Saves retain existing domain validation and locks. `SourceContextBar` is presentation over existing `Savegame` metadata. `CompanionLookup` carries a typed destination and exact catalog ID with a fresh request identity. `QuickFindCatalog` reuses existing search functions, with no world access. `BuildMaterialHandoff` validates reviewed rows into optional `CraftingPlan.buildSources`; atomic copy-on-add preserves choices and bounded sums, and existing plan storage commits explicitly. Old schema-1 plans without provenance remain readable. No network/schema migration or duplicate feature stores were introduced.

Baseline audit: 2026-09-07; integration contracts updated through 1.7.44 candidate on 2026-09-12.

Active parallel-delivery ownership, shared contracts and integration gates are maintained in [FEATURE-COORDINATION-2026-09-07.md](FEATURE-COORDINATION-2026-09-07.md).

## System shape

The project family has three independent applications. macOS is the leading implementation. Android/Quest and web deliberately duplicate selected readers and workflows because their storage, permission, UI and deployment boundaries differ.

| Layer | macOS implementation | Responsibility |
| --- | --- | --- |
| Application shell | `Sources/main.swift`, `Sources/CompanionView.swift` | App lifecycle, selected save/device/world, grouped navigation and feature composition. |
| Trusted save boundary | `Sources/Library.swift` | ADB execution, immutable staging, manifests, SHA-256 verification, deduplicated objects, import/export and guarded restore. |
| Native feature models | `Sources/*Models.swift`, storage helpers | Conservative parsers and persistent metadata for player, chest, portal, ore, guide, skill and export domains. |
| Native feature UI | SwiftUI `*View.swift` files | Selection, status/error presentation and user-confirmed actions. |
| Map processing | `Resources/MapEngine/realmcraft_map/*.py` | Version-9 chunk decoding, surfaces/columns, POIs, ores, editor patches and render/export preparation. |
| Embedded map runtime | `Resources/MapEngine/realmcraft_map/web/*.js` | Interactive atlas, orientation, layers, measurement, routing, overlays, portal plans and 3D beta. |
| Native/web bridge | `Sources/MapsView.swift` (`LocalMapWebView.Coordinator`) | Validates messages, persists scoped annotations/plans and accepts navigation exports from the local file-backed web view. |
| Static resources | `Resources/*.json`, help and skill folders | Versioned bilingual catalogs, evidence notes and offline documentation. |

## Primary flows

### Community translation workspace (1.7.47 source baseline)

`translation_catalog.py` scans explicit project sources into `Resources/Translations/catalog.json`. Inventory IDs separate contexts; resource object IDs anchor list rows where possible. Source fingerprints prevent stale pack imports, target fingerprints prevent lost updates, and placeholder checks preserve interpolated values. Import creates a separate catalog candidate and marks changed target text as draft. Source refresh retains retired entries and marks changed-source translations for review. The unresolved-literal inventory is a coverage boundary, not a list of automatically translatable code.

`make_localizations.py` validates that catalog and its legacy interface baseline, then compiles the existing DE/EN `.strings` resources. Only reviewed English overrides in the interface subset affect runtime output. Swift branches, structured content, maps and documents retain their existing implementations until migrated. No new runtime language preference, persistence store, network client or personal-data access is introduced. See [format and contribution workflow](../Resources/Translations/README.md) for the source/inventory distinction and planned adapters.

### Help catalog and navigation (1.7.44)

`HelpCatalog` loads schema-1 `Resources/HelpArticles.json`, resolves only whitelisted bundled Markdown resources and validates IDs, language bodies and related links before display. `HelpView` shares this immutable catalog for category lists, diacritic/case-insensitive all-token search across both languages and related-topic navigation. Filtered selection resolves against visible results; no matches displays no article. Existing `lastHelpTopic` and `appLanguage` preferences remain valid. `HelpBlock` is the Foundation-only paragraph/list parser, rendered by `HelpParagraphs`. Export continues using explicit native save panels. Setup and agent instructions are checked for exact embedded-text equality.

No feature data or application model is required to load/render help. [The UI/UX audit](UI-UX-AUDIT-2026-09-12.md) defines proposed shared source/transition components; they are not part of the current architecture yet.

### Crafting material plan (1.7.43)

`CraftingView` opens `CraftingPlanView` with the selected reference recipe and quantity, or the existing local document. `CraftingPlanCalculator` reuses `CraftingIndex`; it resolves explicit recipe/ingredient choices, detects cycles and aggregates consumer demand in topological order before whole-batch rounding. Instructions reverse that order. Direct mode expands only target recipes. Safety bounds: 50 targets, 1–9999 per target, 512 visited items, 64 dependency levels, one billion per derived quantity. Incomplete plans expose choices/issues but no purported final totals.

`CraftingPlanStorage` reuses `PlanningStore` atomic/optimistic writes under a dedicated short nonblocking file lock, not the library or map-cache lock. One explicit-save document lives under Application Support at `RealmCraftLibrary/Crafting/material-plan.json`; it contains catalog IDs and choices, not snapshot/device data. A semantic recipe/source fingerprint blocks recalculation after catalog changes until choices are reset. Corrupt data is never replaced by an empty plan for saving. UI confirms discarding unsaved edits. Text export uses a save dialog and preserves quantities, choices, provenance and uncertainty. No stock reconciliation, fuel amount, station construction, new recipe knowledge or platform parity is inferred.

`CraftingConversation` adds deterministic catalog retrieval to `ConversationKnowledge` after world/stock/guide routing. The existing assistant audio path reads concise source-scoped explanations. Explicit numbered variants and quantity followups retain only the current recipe context; other intents and failed lookups clear it. `ConversationView` reads the saved plan only on an explicit plan request and remembers that answer for Repeat. Qwen/Apple interpretation remains optional; no additional inference endpoint or API credential is introduced. Android uses the same catalog with independent local planner storage and a whitelisted-asset WebView/native speech adapter; cross-platform plan synchronization is not implemented.

### Ore presentation and completion notices (1.7.42)

`OreLayer3DView` reuses its scene in the larger sheet. `OreCameraPreset` stores only validated relative camera parameters; `OreImageExport` captures the active scene and bakes measurement date, bounds, legend and limitations into a user-selected PNG. `SavedOreScan.date` is passed through the workspace; it is not replaced by export time. Export never publishes or reads another snapshot.

`OreCluster` uses the existing `OreSpatial.cell` and shared payload validation for cancellable six-face BFS over the measured volume. It caps connected cells at 65,536, distinguishes missing neighbors from air, and conservatively flags measurement boundaries. Highlight geometry is clipped to the visible cutaway; results are keyed to the active selection to prevent stale highlights. The original single-layer four-neighbor feature is unchanged.

`MapController` owns `MapNotifications`. Only successful committed Atlas output invokes completion; cancellation/errors/Tectonicus do not. A main-actor service checks explicit stored opt-in, current system authorization and foreground status, deduplicates job identifiers and sends generic local UserNotifications content through an injectable client. Permission is requested only by the activation button. No notification service access occurs from unbundled CLI runs. In-app completion and snapshot-scoped Open map remain authoritative.

### Save import and verification

`CompanionView` → `Model` → `Library` → staging directory → manifest/hash validation → optional object-store deduplication → immutable snapshot publication.

Every feature that reads a managed save should enter through `Library.folder`, `Library.worldFolder`, `Library.verify` or a helper that preserves the same boundary. Editor work first materializes linked files and publishes a new snapshot rather than modifying the selected snapshot.

`IncrementalBackup` optimizes transfer only: the most recent same-world base is fully verified, matching files are copied into new staging, and only remaining manifest paths are pulled. Full remote hashing before/after and final local equality remain mandatory. Removed paths are not carried forward. Corrupt bases or at least 75% changed files fall back to a full pull. `backup-transfer.json` is snapshot metadata, not part of the game world.

Crafting display uses `CraftingItemIcon` / `CraftingItemLabel` with the existing optional `ItemIconStore`, explicit numeric catalog IDs and global pack/text preferences. Missing mappings use a neutral placeholder only when icons are enabled. Recipe ingredient alternatives retain their textual grouping; a representative grid icon never selects a planner alternative. Recipe and plan pages open the existing icon settings, with no automatic download or change to the global store's installation behavior.

### Map generation and interaction

`MapsView` → `MapController.generate` → library-locked verified independent `MapSnapshotInput` copy → unlocked utility queue / cancellable Python map command → verified input and committed local output → persistent completion notice / guarded view update → `WKWebView`.

Map generation does not occupy `Model.busy` during rendering. `Model.backgroundMapJobs` guards duplicate jobs and application quit; `MapCacheLease` serializes cache mutation independently of the library. A completion only replaces the visible map when library, selected snapshot and requested map settings still match. Explicit Open map selects the original snapshot. The job owns cleanup of its input and incomplete output, never the original snapshot or a previous map.

The Python side owns authoritative full-chunk decoding. The browser side receives compact surface and vertical-run data. Rotation and mirroring are presentation transforms; selections and persisted coordinates remain world X/Z.

### Ore research

`OreResearchView` → map-tool Python runtime → `ores.scan`/`sample_scan` → JSON `OreScan` → Swift display and `.ore-research` journal persistence.

The census counts bounded world volumes by Y and biome and preserves missing/error/unknown states. The 1.7.38 workspace connects Atlas area selection to a layer map, ledger and distribution comparisons. `OrePresetsView` now stores world-scoped analysis settings via `PlanningStore`; applying one does not start a census or copy prior results.

The 1.7.41 native 3D cutaway consumes the same `OreSpatial` payload without another decoder or full-map render. `OreLayerMesh` clips to at most 64×64×8 cells and emits only exposed cube faces plus flat missing-data markers. Cancellable background work is keyed by height/window/filter; measurement identity resets view state. `OreLayerScene` batches faces per block ID, maps hit-test triangle indices back to exact world XYZ and reuses `BuildOrbitCamera`/`BuildOrbitSceneView`. Material colors moved unchanged into shared `OreMaterial.swift`. A selected-only view hides context without changing census totals; ledger and visible-section counts retain explicit different scopes. No application install or device operation follows from rendering a layer.

### Persistent planning and comparison

`PlanningStore` provides bounded Codable metadata reads, atomic writes and optimistic stale-write rejection. Callers validate their schema/scope and hold the library operation lock for writes. `.metro-journeys/<snapshot-id>.json` is version-1 snapshot-local progress; `.ore-presets/<world-id>.json` is version-1 reusable settings. Invalid metadata is reported rather than silently replaced.

`MetroJourney` pins ordered confirmed edges to a canonical network fingerprint. `MetroJourneyExport` uses its own version-1 `realmcraft.metro-journey` schema because a route can cross dimensions; it shares existing assistant guidance but must not masquerade as a single-dimension terrain `NavigationPack`. Arrival remains manually confirmed.

`ChunkChangesView` uses verified manifests from two same-world snapshots. Its native map consumes canonical 16-block chunk positions and four file-hash statuses without introducing a second chunk decoder. It makes no block-level or terrain-emptiness inference.

### Portal planning

`PortalReader` groups saved adjacent portal blocks. `PortalsView` stores explicitly directed observed pairs. `AtlasPortals.Planner` and `PortalPlanStore` add map-selected plans and an assumed 8:1 horizontal conversion. None of these establishes RealmCraft's actual link-selection rule.

### Cross-platform boundaries

- Android owns an immutable snapshot store and a narrow Shizuku read service. Project rules prohibit restore/editing.
- Web reads bounded ZIP content in a worker and keeps imported state in memory. It has no backend or persistent world library.
- Data formats are reimplemented per platform. Equality must be maintained by versioned fixtures and expected outputs, not by assuming ports remain synchronized.

## Architectural risks and decisions needed

1. The 1.7.39 candidate coordinates map-tool activation and Escape/dimension/privacy cancellation through `MapToolCoordinator`. Tools retain their own geometry and pending-write state. A generalized world-region/volume selection contract remains open.
2. Persistence keys and files are distributed across `UserDefaults`, hidden library subfolders and per-save files. Add a documented registry with owner, scope, schema version and migration policy.
3. Portal plans/pairs are keyed by snapshot ID while other annotations can follow an annotation scope. Decide whether metro plans describe a snapshot, a logical world or both before designing a network graph.
4. Python, Swift, Java and JavaScript readers duplicate binary-format knowledge. Keep platform implementations, but publish common synthetic fixtures and expected neutral JSON for conformance.
5. `build.sh` defaults to a fresh temporary bundle and rejects symlink, existing and `/Applications` destinations. A verified installation is a separate, explicit operation, so development builds cannot replace the installed Companion through the project app symlink.
6. `package_source.py` currently does not include `docs/`. Decide whether these maintained architecture artifacts belong in the distributed community-source ZIP and add the directory explicitly only after the public-content review.

## Dependency guidance for the new ideas

- Layer analysis should reuse `chunks.decode`, the ore census integrity model, `geometry.js`, `AtlasLayers` and the existing map renderer/cache.
- A generic world-volume aggregation service should return coverage, unknown IDs and counts separately from UI. Ore-specific ranking can remain a consumer.
- Metro planning should reuse `PortalReader`, directed `PortalPair`, `PortalPlanStore`, map coordinates, `AtlasNavigation` export models and transport overlays after RealmCraft mechanics are verified.
- Platform ports should consume shared capability specifications and fixtures. They should not copy macOS view structure or introduce write access to Android/web.
