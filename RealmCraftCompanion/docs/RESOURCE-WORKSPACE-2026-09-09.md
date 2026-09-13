# Resource workspace integration — 2026-09-09

## Follow-up: 1.7.41 candidate · 2026-09-12

User request: render the selected ore-frequency layer in 3D, similar to the overall map. Implemented a native 2D/3D switch under Explore layers using existing spatial census data. Y is the top layer; 1/4/8-layer depth clips at the original measured floor. A movable 64×64 window bounds work for larger regions and can start at the pinned 2D block. Material colors, selected-only filtering, fixed-target orbit controls and precise block picking are shared with existing workflows. The tunnel/Atlas callbacks receive the actual picked XYZ, including lower slice levels.

Ownership: `OreLayerMesh.swift` owns bounded geometry and coverage accounting; `OreLayer3DView.swift` owns asynchronous view state and SceneKit batching/picking. `OreWorkspaceView` owns the mode switch, while `OreResearchView` resets it on measurement identity changes. `OreMaterial` and `BuildOrbitSceneView` moved unchanged into reusable files; guide rendering and Atlas JavaScript are otherwise untouched. Bilingual help stays in the existing ores article.

Safety/limits: no savegame access or mutation, new map job, texture download or inferred terrain. Missing cells are violet sheets, unknown IDs remain cubes, and known air/filtered blocks are counted separately. The 3D view honors spoiler-light mode. Displayed section counts are separate from the original full-layer/volume ledger. Cubes are schematic, including fluids and partial blocks. This does not implement 3D vein detection or live navigation.

Verification so far: full Swift typecheck passed; synthetic `OreLayerMeshTests` passed axes, clipping, negative positions, exposure culling, face winding, coverage/filter distinctions, malformed payload rejection, cancellation and unchanged input. Existing ore-model suite, 42 Python cases and 68 Atlas/portal/Tectonicus Node tests passed. Synthetic native SceneKit context and selected-only renders were produced and visually inspected; real triangle hit-testing recovered exact negative world XYZ. The existing fixed-camera and pixel/wheel page-scroll regressions also passed after extracting the shared view. Visual inspection prompted camera-facing direction labels. Final universal build checks are recorded below after completion. The initial broad typecheck overlapped the mechanical extraction of shared files and was rerun successfully after that move; no dependency failure remains.

Final candidate verification: version 1.7.41 (63) built successfully for arm64 and x86_64. Strict deep code-signature verification passed, the executable mode is 0755, and the bundled CommunitySource archive contains the new implementation, tests and test instructions. The candidate executable SHA-256 is `0801a643d674905280b51c3bfefe6a1142b9ded6b098afa917c589d059e318cf`. Source comparison against the integrated project passed. An arm64 production CLI read against an isolated empty library passed with ADB disabled.

The implementation was prepared in an isolated temporary source copy because the workspace's current permissions are read-only. An authorized scoped patch integrated the source, tests and documentation after checking original files for concurrent changes; unrelated crafting work was preserved. No installation is requested; the installed app remains 1.7.38. Earlier combined 1.7.39/1.7.40 GUI acceptance remains open; a rendered fixture is not full interactive app acceptance.

## Historical 1.7.38 implementation

Follow-up codecheck and implementation for Companion 1.7.38 (build 60). This is a local source audit without a Git commit identifier. The build uses a frozen source snapshot; unrelated accumulated changes are preserved. Original scope: the resource-analysis handoff of 2026-09-07 and the user's requests for deeper integration, consistent controls and selectable multi-ore diagrams.

## Findings and implemented behavior

The earlier census and trial backend already decoded full chunks, validated snapshot hashes, counted by height/biome, retained missing coverage and recorded before/after and chest/sign evidence. The principal gap was the working interface: no linked block view, independent single-ore charts, little spatial comparison and weak transition from exploration into trial planning. These existing readers and journal rules are reused.

| Requirement | Result and evidence |
| --- | --- |
| LAYER-001, bounded region | Atlas Resource analysis button and existing Shift-drag use the same `atlasResources` bridge; canonical inclusive coordinates survive mirroring/rotation. The saved map request is consumed once. `OreResearchView.loadMapRegion` and `ores.scan`. |
| LAYER-002, height inspection | `OreWorkspaceView` draws a north-up layer, chunk boundaries and missing/air/material distinctions. Slider, exact Y field, arrows, focused keyboard and Option-scroll change height; hover/pin gives exact block coordinates and ID. |
| LAYER-003, linked quantities | Material selection drives the map, layer/volume ledger and charts. Eighteen configured groups include eleven ore groups plus amethyst, chests, rails, spawners, planks and rock groups. A name does not establish natural generation. |
| LAYER-004, interesting layers | Threshold is the count of selected materials in a measured layer. Arrows filter and wrap; free Y inspection remains possible. Missing coverage stays visible. |
| LAYER-005, nearby areas | Geographic 16/64 tile comparison uses the same height interval, exact clipped extents and actual decoded denominators. Only decoded chunk rectangles are colored; missing space remains violet and each grouped tile reports coverage. Clicking prepares a smaller census. Pinning counts four-neighbor same-material blocks in one bounded layer; it does not claim a three-dimensional vein. |
| Multi-ore visualization | Linear unsmoothed lines for profiles, a common-scale heatmap for many materials, and horizontal bars for one height. No treemap: ordered heights and geographic relationships must remain apparent. Unknown legacy categories leave gaps, not artificial zero values. |
| Trial integration | A pinned block can populate a tunnel start; setup, before/after evidence, findings/journal and pooled results are grouped under Mining trials. Existing completeness, overlap, blank/zero and chest-item distinctions remain. Biased prospecting locations are explicitly distinguished from independently preselected trials. |

## Shared contracts and compatibility

- `ores.py --spatial` optionally adds `spatial` and `areas` to a region report. Existing decoder and material/state-bit interpretation remain authoritative. No snapshot writes occur.
- `spatial.encoding = u16le-yzx-v1`: base64 bytes decode to little-endian UInt16, ordered Y then Z then X over inclusive report bounds. 65535 denotes unavailable cells, separate from known air IDs. Allocation is capped at 4,194,304 cells (8 MiB raw); larger regions retain aggregate results. Random samples intentionally have no contiguous spatial payload.
- `areas` stores successfully decoded clipped chunk rectangles, actual block-position denominators and material totals. Missing/corrupt chunks are omitted and reported separately. Grouping uses floor division for negative coordinates.
- Swift optional fields preserve older histories. `validateDisplay` checks geometry, layer denominators and spatial byte length. New-layer data requires recounting older records. Measurements remain private metadata under the existing snapshot-specific research journal.
- `ore.region.<saveID>` keeps the existing dimension/X/Z dictionary contract; the consumer now removes it after applying it, preventing stale selection replay. Map viewer cache stamp increments only the resource revision; Metro revision is retained.
- `OreWorkspaceView` callbacks carry a pinned X/Y/Z to the existing `OrePlan`, or an `OreArea` to the current measurement controls. No duplicated navigation or portal model is introduced.

## Changed files

Feature files: `Sources/OreModels.swift`, `Sources/OreResearchView.swift`, new `Sources/OreWorkspaceView.swift`, new `Sources/OreDistributionView.swift`, `Resources/MapEngine/realmcraft_map/ores.py`.

Shared integration: `Sources/MapsView.swift` (resource viewer cache revision only), `Resources/MapEngine/realmcraft_map/web/app.js` and `web/index.html` (existing resource selection activation/cancellation), `Sources/HelpView.swift` (DE/EN resource chapter), `build.sh` (version/build), `Resources/CHANGELOG.md` (new English release entry), `Resources/BACKLOG.md` (resource rows only, preserving parallel Metro edits).

Verification/documentation: `Tests/test_ores.py`, `Tests/OreModelsTests.swift`, `Tests/orientation.test.cjs`, `docs/FEATURE-MAP.md`, `docs/IDEAS-2026-09-07.md`, this report. Portal, Metro, navigation/export, player and restore implementation files were not edited by this workstream.

## Validation

- Python discovery: 42/42 passed, including clipped negative-coordinate cube axes/state masking, missing-vs-air cells, aggregate conservation and spatial allocation cap.
- Atlas Node suite: 62/62 passed on the accumulated source, including existing navigation/Metro checks and new resource-button, Shift-drag, Escape and privacy assertions.
- Swift Ore model executable: passed references, geometry, journal revisions, overlap/weighted rates, signed chest deltas, binary addressing, bounded connectivity and negative tile grouping.
- Native NSHostingView render checks use synthetic blocks only; layer-map/ledger and line-chart layouts reviewed at 1050 px. Heatmap and per-layer bars were also rendered and reviewed; the height axis was explicitly bounded after the first visual pass. A final zero-only heatmap check led to a fixed 0...1 fallback scale, so absent finds remain dark instead of receiving a misleading accent color.

## Open dependencies

INT-002 remains: generalized map-tool coordination/`WorldRegion` is broader than this narrow existing resource bridge. INT-004 remains for resource-location to full navigation/route-export adaptation; the implemented handoff is to the tunnel planner. LAYER-005 remains partial for 3D clusters and arbitrary subdivision editing. INT-006 remains for Android/Quest/web parity; this delivery is macOS. Minecraft generation transfer remains an unconfirmed reference hypothesis. No cross-world probability or 3D deposit geometry is inferred from the sample.

Release wording is consolidated here for the resource workstream; the historical 2026-09-07 handoff and unrelated feature entries remain intact. No publication, Quest operation or live save modification was performed.

## Parallel delivery coordination

The parallel Metro and Build Coach workstreams were preserved and included in the final frozen source snapshot. Shared edits to `CompanionView`, help, changelog, backlog and build metadata were consolidated only after both workstreams reported stable inputs. No resource-only candidate overwrote their changes.

### Release-candidate checks

The initial optimized application launched as an isolated QA bundle using a separate copy of the authorized demo snapshot. After the external computer-use service recovered, the complete resource workspace, Distribution view and all three diagram modes were inspected natively. A Sol/medium release audit found that the 64-column comparison outline could visually cover missing interior chunks even though its denominator was correct. The final implementation paints only decoded chunk rectangles, preserves violet missing areas, adds an explicit coverage percentage and includes a sparse-grouping regression test. The audit also removed two stale completed backlog rows.

The final frozen snapshot is `/private/tmp/realmcraft-final-1738-sol-legend`; its manifest is `/private/tmp/realmcraft-final-1738-sol-legend.sha256`. The universal x86_64/arm64 release passed strict deep signature verification, bundle version checks, executable-mode checks, CommunitySource archive verification and an isolated demo-library CLI read. It contains 95 Build Coach guides with 95 matching voxel plans. The accumulated suites passed with 42 Python tests, 62 Atlas Node tests, the OreModels executable and the Build Coach Python/Swift checks.

Version 1.7.38 (build 60) is installed at `/Applications/RealmCraft Companion.app`. The project app link resolves to that installation. The replaced installation was retained as a local backup. A post-install native launch confirmed version 1.7.38 and the new Explore workspace in the installed bundle. No savegame, Quest file or measurement journal was modified during this UI check.
