# Feature coordination — 2026-09-07

September 12 UX implementation: the coordinator now owns the five approved work packages in 1.7.45: shared source display, draft guards, responsive presentation, local quick find and reviewed guide-to-plan handoff. Common contracts are `DraftTransitions`, `SourceContextBar`, `CompanionLookup` and optional `CraftingPlan.buildSources`. Feature stores and source scopes remain authoritative; no second catalog, map renderer or inventory model was added. See the current integration entry for verification and remaining gates. Earlier entries below describe historical scope.

September 12 UI/UX follow-up: the coordinator owns [the whole-navigation audit](UI-UX-AUDIT-2026-09-12.md), help catalog/view/tests, synchronized setup documents and the 1.7.44 release notes. All 20 macOS destinations and principal dialog constraints were reviewed in source; full native acceptance is separate. Non-help feature code is unchanged. Future shared source bars, draft guards and responsive layouts have explicit UX-001–007 dependencies; do not duplicate feature stores or merge their different data scopes.

September 12 crafting follow-up: [1.7.43 integration](INTEGRATION-2026-09-11.md) owns the multi-target material plan, extended local Conversation lookup and recipe/plan icon display. It reuses `CraftingIndex`, `PlanningStore` with a dedicated plan lock and existing optional `ItemIconStore` packs/preferences. Android 0.10.0 source shares the catalog with independent local planning and native on-device speech; no automatic plan synchronization is claimed. Existing Android 0.9.0 changes are preserved. Metro, ore, device transfer and savegame data remain unchanged. APK/device and full native UI acceptance remain distinct gates; no installation or publication is implied.

September 12 comfort follow-up: [1.7.42 integration](INTEGRATION-2026-09-11.md) owns ore presentation/3D connectivity and optional map-completion notifications. Reuses the existing scene, material groups, spatial decoder and successful map-commit boundary. Crafting, Metro routing, device transfer and platform parity remain unchanged in that package. Installation stays separate.

September 12 follow-up: [Ore-layer 3D · 1.7.41 candidate](RESOURCE-WORKSPACE-2026-09-09.md) records the native cutaway, shared camera/material extraction and test boundaries. Existing crafting changes were preserved; Atlas/Metro/backup implementation was not forked or rewritten. The earlier combined interactive acceptance and installation remain separate work.

September 11 follow-up: [Integration candidates 1.7.39–1.7.40](INTEGRATION-2026-09-11.md) is the current responsibility/dependency register. It records map-job safety, Metro snapshot carry-forward, resource-target handoff, shared tool coordination, saved journeys/export, ore presets, chunk changes, incremental transfer and background rendering. The original assignments and acceptance boundaries below remain historical context. The user deferred the earlier interactive acceptance/install step; do not present these candidates as installed or fully accepted.

September 9 follow-up: the user requested deeper Metro integration. The narrow shared-webview/picking changes now implemented, concurrent-file boundaries and still-open INT dependencies are documented in [Metro workspace — 1.7.38](METRO-WORKSPACE-2026-09-09.md). The ownership assignments below describe the original September 7 delivery, not a prohibition on this later integration.

This is the single integration register for the concurrently delivered Nether metro, ore-frequency research and codecheck work. It complements the architecture, feature map and backlog; it does not change their implementation-status claims.

## Ownership and delivery boundaries

| Workstream | Owner and scope | Files/components owned during the current delivery | Must not duplicate or change without integration review |
| --- | --- | --- | --- |
| Nether metro | Metro network model, station/edge UI, travel estimate and confirmed-edge route handoff. Portal mechanics remain evidence-gated. | New `Sources/MetroModels.swift`, `Sources/MetroView.swift`; a minimal `Sources/CompanionView.swift` entry only if required. | `PortalModels.swift`, `PortalPlans.swift`, `MapsView.swift`, `NavigationExport.swift`, Atlas `navigation.js` and `transport.js`; ore models, census and bridge. |
| Ore-frequency research | Bounded resource census, sample/trial recording, research UI and RealmCraft-vs-reference evidence labels. | `OreModels.swift`, `OreResearchView.swift`, `ResourcesView.swift`, `Resources/MapEngine/realmcraft_map/ores.py`, existing `atlasResources` bridge. | Portal and metro models; navigation/export; general map-tool state; shared map coordinate transforms. |
| Codecheck | Evidence-led audit, feature map, architecture/data-model and prioritized defect/idea register. | Audit and review artifacts already completed before this register. | Further changes to central documentation, `Resources/BACKLOG.md` or `Resources/CHANGELOG.md` until feature deliveries are reconciled. |

## Shared components and contracts

| Component / contract | Current role | Consumers | Integration rule |
| --- | --- | --- | --- |
| Verified snapshot boundary | `Library` and snapshot identity scope resource, portal and map reads. | Metro, resources, existing portal tools. | New persistent data must name its scope: immutable snapshot versus logical annotation/world scope. Do not silently conflate them. |
| World coordinates and display transforms | World X/Z are canonical; `geometry.js` applies rotation/mirroring only for display. | Atlas, resource selection, portal planning, metro. | Store and exchange world coordinates only. Keep negative-coordinate floor chunking covered by tests. |
| Atlas selection / tool state | Existing independent measure, ownership, portal and resource interactions. `atlasResources` accepts inclusive `{ dimension, x0, x1, z0, z1 }`. | Resources now; metro may need it later. | Do not add a second generic drag-selection protocol. A future `WorldRegion` plus `MapToolCoordinator` must subsume the narrow resource bridge after both current features are stable. |
| Portal evidence | Detected portals, directed observed pairs and assumed 8:1 plans are distinct records. | Existing portal planner, metro. | Metro routes may use only explicit confirmed directed edges. The 8:1 relation, link radius, Y effect and reverse behavior remain unverified and must not drive a reliable route. |
| Navigation handoff | `NavigationExport.swift`, Atlas navigation and transport overlays carry route instructions. | Existing navigation, later metro. | Metro supplies a neutral confirmed route/leg model first. Adapting it to the existing export is a dedicated integration change; do not fork turn-by-turn logic. |
| Chunk decoder and coverage | Python `chunks.decode`/`ores.py` is authoritative for full-volume census; coverage may be incomplete. | Resource census, map, future layer analysis. | Never infer resource absence from unknown/corrupt chunks. Metro uses coordinates only and must not copy decoder logic. |

## Dependencies and open integration points

| ID | Dependency / decision | Blocks or affects | Acceptance criterion for integration |
| --- | --- | --- | --- |
| INT-001 | RealmCraft portal mechanics evidence matrix: scale, search radius, height, tie-breaking and both directions. | Reliable Metro routing/prediction. | Controlled, versioned observations are stored; route UI distinguishes every confirmed edge from planned or assumed data. |
| INT-002 | Shared map-tool coordinator and `WorldRegion` contract. | Future metro map editing and generalized layer analysis. | One activation/cancellation model covers Escape, dimension changes, rotation/mirroring and inclusive world-coordinate rectangles; the existing resource bridge migrates without behavior loss. |
| INT-003 | Metro persistence scope. | Station/edge data and their relation to portal pairs. | Design chooses snapshot-only or logical-world annotations, states schema/version and migration behavior, and preserves the evidence status of every edge. |
| INT-004 | Metro-to-navigation adapter. | Turn-by-turn output and export. | A confirmed multi-leg metro journey is represented once, then passes existing navigation/export validation without duplicating route instruction generation. |
| INT-005 | Central release notes reconciliation. | `Resources/BACKLOG.md`, `Resources/CHANGELOG.md`. | One editor incorporates both completed features after tests/builds pass; entries are English, latest first, retain IDs and do not claim unverified RealmCraft mechanics. |
| INT-006 | Regression coverage across duplicate readers. | Resource correctness and future platform parity. | Synthetic fixture vectors and expected neutral results exist for any changed binary-format interpretation; no personal saves or identifiers are used. |

## Completion checklist for each implementer

1. Report the exact changed file list and whether any central/shared file was touched.
2. State tests/builds actually run and their results; distinguish unavailable validation.
3. Identify persisted schema/scope and any compatibility implications.
4. List unresolved assumptions and handoff requirements using the `INT-*` identifiers above.
5. Do not amend central release documentation after this register; submit proposed wording to the integrator.

## Integration order

1. Preserve and inspect the accumulated worktree; validate each feature in its owned area.
2. Reconcile any minimal `CompanionView.swift` navigation changes and compile the combined macOS target.
3. Validate the resource census and metro model tests together, then run the existing atlas/navigation suite.
4. Review the combined diff for private save data, duplicated map selection/routing logic and unsupported mechanics claims.
5. Apply one consolidated update to the feature map, architecture, backlog and changelog, then rerun the relevant build/tests.

## Verified handoff snapshot

Verified against an isolated frozen source snapshot on 2026-09-07 18:59 CEST:

- Swift full-source typecheck for arm64/macOS 14: passed.
- Python discovery suite: 40/40 passed.
- Atlas Node suite: 57/57 passed.
- Metro model regression suite: passed, including A → B → A transfer counting.
- Ore model regression suite: passed, including the `interestingOnly` navigation behavior.

The previously observed Metro `@State` declaration and transfer-count defects, plus the resource-filter behavior gap, were corrected in their owning workstreams. An earlier ore-model `Index out of range` report was caused by an incomplete audit invocation and is not a product defect. The remaining build-script risk is an existing issue outside these feature deliveries: the default target can follow the project application symlink.

## Ready integration assignment

**Owner:** one integrator, after preserving the current worktree and without changing savegame data or installed applications.

1. Review the combined feature diff and retain only the owned Metro and resource changes, their regression tests and required localized/resource data. Reject unrelated worktree edits.
2. Reconcile the two `CompanionView.swift` navigation additions once; retain one destination per feature and verify stable feature identifiers and ordering.
3. Reconcile proposed English entries into `FEATURE-MAP.md`, `ARCHITECTURE.md`, `Resources/BACKLOG.md` and `Resources/CHANGELOG.md`. State that Metro routing accepts only confirmed directed edges; state that Minecraft ore material is reference evidence, not RealmCraft generation fact.
4. Run the frozen-suite equivalent after reconciliation: Swift full-source typecheck, Python discovery, Atlas Node tests, Metro model tests and Ore model tests.
5. Add a release-review note for INT-001 through INT-006. Do not mark them complete without their stated acceptance criteria. In particular, preserve the portal-mechanics evidence gate and defer generic map-tool coordination, Metro-to-`NavigationPack` adaptation and cross-platform fixtures to follow-up work.

**Completion criterion:** the combined suite remains green, no personal-save identifiers or private measurement artifacts enter tracked deliverables, and all open integrations remain explicitly represented by `INT-*` IDs rather than implicit assumptions.
