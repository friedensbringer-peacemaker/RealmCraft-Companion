# RealmCraft Companion data model

Baseline audit: 2026-09-07; planning/background additions: 1.7.40 candidate, 2026-09-11.

## Managed save data

| Entity | Source and identity | Persistence | Integrity/unknown policy |
| --- | --- | --- | --- |
| `Savegame` | Companion UUID plus RealmCraft world ID | One snapshot directory with `savegame.json`, `manifest.json` and one numeric world folder | `Library.verify` compares the recorded manifest; readers must not turn failures into empty data. |
| World metadata | `world_data`, observed version 9 | Inside each snapshot | Name, ID, seed and date are accepted only through validated layouts. |
| Chunk | `o.X,Z` or `n.X,Z`, header coordinates and dimension | Inside each snapshot; identical files may be hardlinked to `.objects/<prefix>/<sha256>` | Full decoder validates version, coordinates, section lengths and RLE. Missing, unreadable and unknown blocks remain distinct. |
| Player | `player_data`, observed player/item layouts | Inside each snapshot | Inventory, armor, level, durability and enchantments are conservative optional results; ambiguity is an error/unknown, not an empty player. |
| Chest/sign records | Embedded chunk records cross-checked against decoded blocks | Derived scan output/cache | Duplicate or unsupported records are unreadable/unknown; ownership is never inferred. |

## Companion metadata

| Entity | Scope | Storage | Notes |
| --- | --- | --- | --- |
| Annotation scope | save UUID, optionally carried from a previous save | `annotations.scope.<saveID>` and pending-copy keys in `UserDefaults` | Provides continuity for markers, names and ownership. |
| Map markers | annotation scope | `atlasMarkers.<scope>` in `UserDefaults` | Maximum and field validation are enforced by the native bridge. |
| POI names | annotation scope | `atlasPOI.<scope>` in `UserDefaults` | User text is data, not instructions or translated UI. |
| Chest ownership/visibility | annotation scope | `conversation.ownedChests.<scope>` plus `ChestVisibility` keys | Applies to conversation and exports; unknown ownership remains separate. |
| Orientation | logical world ID | `atlasOrientation.<world>` in `UserDefaults` | Presentation only; world coordinates never change. |
| Generated map | save UUID, radius and language | Application Support `Maps/<saveID>/<run>/` plus a `UserDefaults` pointer | Generated output is replaceable; source save stays verified. |
| Portal plan | save UUID | `.portal-plans/<saveID>.json` | Stores planned source point and assumed counterpart. Network scope is not yet defined. |
| Portal pair | save UUID plus portal-file fingerprint | `.portal-pairs/<saveID>.json` | Directed observation only; fingerprint invalidates stale evidence after source portal data changes. |
| Metro network | save UUID | `.metro-networks/<saveID>.json` | Versioned local plan with stations, lines and directed edges. It never proves a portal association; planned/built/confirmed evidence remains separate. |
| Metro journey journal | save UUID and world ID | `.metro-journeys/<saveID>.json`, version 1 | Named ordered edge IDs, canonical network SHA-256, manually completed legs and active journey. Maximum 100 journeys, 2,000 legs each; network changes invalidate resume. |
| Ore analysis presets | world ID | `.ore-presets/<worldID>.json`, version 1 | Up to 100 named inclusive regions, dimension/heights, materials, biome and sampling settings. No measurements or automatic scans. |
| Backup transfer report | backup UUID | `backup-transfer.json` beside the world directory, version 1 | Full/incremental-transfer mode, base snapshot, downloaded/reused file counts and verification method. Not part of game data or a timing benchmark. |
| Ore scan history | save UUID within a logical-world collection | SwiftUI state persisted by the ore research view | Contains levels, coverage, hashes, optional biome rows and sampling metadata. |
| Ore trial journal | hash of logical world ID | `.ore-research/<world-hash>/trial-<UUID>.json` | Revisions supersede older entries; accepted trial volumes cannot overlap. |
| Agent skills | application | Application Support `AgentSkills/library.json` | Versioned state with seeded defaults, archive flag, notes and import/export. |
| Build checklist/test notes | guide ID | `UserDefaults` | Reference-plan state, not world facts. |
| Activity/export records | library root and selected save | `UserDefaults` plus separate export packages | Used for recent activity and handoff; generated files must stay outside managed saves. |

## Analytical result contracts

### Ore census

`OreScan` includes inclusive bounds, expected/scanned chunks, missing/error collections, per-Y `OreLevel` rows, source hashes, chest/sign context, optional biome strata and optional sampling metadata. Counts are world blocks, never inventory holdings. `unknown` records unsupported block IDs; missing chunks do not contribute zeroes.

### Navigation

`NavigationPack` stores world/scope, steps, POIs, modes, known gaps, distances and rendered Markdown. Terrain-derived route candidates remain snapshot-based guidance and may be invalid in live gameplay.

`MetroJourneyExport` instead declares `realmcraft.metro-journey`, schema version 1. Every leg preserves source/target dimensions and XYZ, line/transfer, mode, measured seconds, recorded blocks, optional recorded geometry and manual-confirmation requirement. It includes source snapshot/date, network fingerprint, progress and safety guidance. It is not accepted as a single-dimension terrain route.

### Chunk changes

`ChunkChangeReport` version 1 references two verified same-world snapshot IDs/dates and canonical chunk positions. Status is added, changed, missing or unchanged based solely on file hashes. Missing is not empty terrain, and changed is not a decoded block difference. JSON export stays outside managed saves.

### Portal planning

`SavedPortal` is a connected component of observed portal blocks. `PortalPair` records one reported direction. `PortalPlan` stores the chosen dimension/X/Z, optional reference Y and the mathematically assumed 8:1 counterpart. A future metro graph must preserve `planned`, `detected` and `travel-confirmed` as separate evidence states.

## Required additions for layer and metro work

- `WorldRegion`: dimension, inclusive X/Y/Z bounds, source save, creation method and coverage summary.
- `LayerAggregate`: Y, decoded positions, unknown positions, per-block/per-category counts and interesting-score policy version.
- `RegionAggregate`: totals plus child-area summaries and cache identity derived from save manifest, decoder version and bounds.
- `MetroNode` is now `MetroStation`: snapshot-local name, dimension, X/Y/Z and planned/built/confirmed status.
- `MetroEdge` is now a directed rail, portal or walking edge with a line reference, length and optional measured duration. Only confirmed directed edges with a duration enter a route; portal edges must cross dimensions and all other edges must stay in one dimension.
- `MetroNetworkStore` version 1 provides hard bounds and rejects invalid documents. It intentionally does not inherit the annotation scope until the snapshot-versus-logical-world migration decision is made.
