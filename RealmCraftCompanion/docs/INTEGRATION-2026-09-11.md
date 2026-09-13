# Integration candidates — 2026-09-11

## UX integration · 1.7.45 (67) · 2026-09-12

Final build verified: optimized universal arm64/x86_64 candidate 1.7.45 (67) compiled successfully. Strict deep signature verification, executable mode 0755 and the 596-file CommunitySource archive integrity check passed. The archive contains all new integration sources and regression guides. Both the arm64 executable and final universal bundle passed `--list` with an isolated empty library and ADB disabled. Packaged help (143 checks) and Quick find/material handoff (35 checks) passed. Final executable SHA-256: `010fa8fde362ab4c2a41458e5d12686500822f4b0dbab8fd995cf79adb1815c3`. No installation or publication was performed. Generated caches are excluded from the source/test comparison; application sources and tests match the integrated workspace.

Verification before packaging: 13 draft-transition decisions, 35 quick-find/handoff checks, 672 native header geometry cases, 143 help checks (48 bilingual topics), 32 existing crafting-plan checks, 19 crafting voice checks and 144 Conversation checks passed. Metro and ore model suites passed. Twenty-eight help-content PNGs were generated; the new German Quick find/Classic and English material-plan/Block samples were visually reviewed for wrapping and complete content. These are representative content checks, not a click-through of every window. Full-source typecheck passed; the optimized build subsequently found a missing failure return in `saveTrial`, which was fixed before the final build. The compact action row also has an explicit horizontal layout and same-row geometry assertions.

The concrete next acceptance order is recorded in `Tests/README-ux-integration.md`. Native Computer Use is not treated as available evidence after the earlier timeout; no personal world or headset was accessed. The installed application was read back as 1.7.38 and has not been replaced.

Implemented in the macOS source candidate; installation and native end-to-end acceptance remain separate.

- Shared `SourceContextBar` replaces duplicate backup pickers in Metro, portals, ores, Maps, Tectonicus, Chests, Player (backup mode), Statistics, Editor and AI export. It distinguishes backup time, game-file time and optional dimension/result time using the existing Savegame model.
- A per-model `DraftTransitions` registry guards source/workspace transitions, protected feature selections/reloads, setup opening, main-window close and application termination. Metro, portal and ore-trial drafts and material plans participate. Save failures and Cancel block navigation; Discard restores persisted state. Other editors retain their existing policies. Portal metadata additionally rejects stale concurrent writes.
- Page headers adapt to narrow widths. Metro switches its three panes below 1080 points of workspace width. Ore 3D, Feedback and Build coach use bounded flexible sheets. Travel modes are localized; portal/ore notices share text, icon and severity. This is partial consistency work, not an accessibility certification.
- Quick find (Cmd-Shift-F) reuses four local catalogs and opens exact recipe, build-guide, video or help IDs after clearing destination filters. Searching starts no scan, playback or AI request. Opening a video destination may load its normal online thumbnails.
- Reviewed build-guide materials can be added to the existing crafting plan. Only explicit unambiguous item IDs and exact bilingual quantities are preselected. Users resolve uncertain rows; omitted rows and original values remain in provenance. Existing recipe choices are preserved; explicit Save plan is required. No stock deduction, recipe verification or cross-platform synchronization is implied.
- Help now contains 48 bilingual topics, including Quick find and the new source/draft/material workflows. All previous topic IDs remain valid.

Remaining: native keyboard/focus/window-close and nested-sheet acceptance, minimum-window Metro interaction, long source titles, VoiceOver/contrast, remaining editor/status consistency, and UX-007's separate Metro/terrain navigation adapter. Android/APK/web parity is not claimed.

## Follow-up: 1.7.44 (66) · 2026-09-12

Scope: source/workflow review of all 20 macOS navigation destinations and principal dialogs, plus a complete help refresh. The coordinator owns `HelpContent`, `HelpView`, `HelpArticles.json`, setup/agent/transfer documents, help tests and the documentation/version changes. Non-help application code, device access, savegames, installation and publication are unchanged.

Implemented: 47 bilingual help topics retaining all 36 previous IDs, explicit categories, task-based chapters and related/back navigation. Search matches all query tokens across both languages and resolves detail only from visible results. Invalid/missing catalog resources fail visibly. Setup paths and embedded agent documents are synchronized without removing the agent safety preamble. Classic help headings/list markers use primary text for readability.

Evidence and next work: [whole-navigation UI/UX audit](UI-UX-AUDIT-2026-09-12.md). UX-001/004 (source context/terminology) should precede or accompany UX-002/003 (draft guards/responsive layout), then quick finding and reviewed guide-to-plan handoff. Different feature data scopes and existing locks remain authoritative; none of those non-help changes is claimed implemented.

Checks: 141 catalog/search/parser/document checks passed against both source and packaged resources. Twenty production help-content samples rendered in DE/EN and both themes using isolated preferences; representative entry, Metro, ore 3D and material-plan pages were visually inspected. The initial ImageRenderer-only dark image lacked an explicit color-scheme environment; the corrected harness renders readable dark text roles and is documented. Content renders are not native list/search/panel interaction or whole-app accessibility acceptance.

Final 1.7.44 (66) universal build passed for arm64 and x86_64 without compiler diagnostics. Strict deep signature verification, executable mode 0755, CommunitySource ZIP integrity and packaged help checks passed. The exact universal executable passed `--list` against an isolated empty library with ADB disabled. SHA-256: `0d2345b80ce6182f5742e8469bcc387b4d54e92a675850550acd29bc1035ed7c`. Sources and tests match the build snapshot, excluding generated Graphify/cache folders; the packaged help JSON matches current source. The archive includes the help model, catalog, tests, reproduction guide and synchronized setup resources. The existing source packager still excludes `docs/` (DEV-006); this audit remains in project documentation, not silently added to public packaging.

Native acceptance limit: an isolated Help-only app was built and launch requested. Computer Use could not select its bundle ID and its path request timed out. No native list/search/keyboard/export click-through is claimed. A later process check found no remaining Help QA process. Do not repeat unavailable UI automation indefinitely; complete `Tests/README-help.md` on a working native test surface before calling this fully accepted.

Installed version was read again and remains 1.7.38. Build/package/native acceptance must not be confused with installation or Android/Web parity.

## Follow-up: 1.7.43 (65) · 2026-09-12

Scope: multi-target recipe material planning, quick local Conversation lookup and optional icon display; Android source-level lookup/planning/on-device speech integration requested as a follow-up. Owner: current integration task. Dependencies: existing `CraftingIndex`/pinned catalog, `PlanningStore`, `ItemIconStore` and Conversation audio; new `CraftingPlan`, `CraftingConversation`, `CraftingIcons` and planner UI. Android retains its existing worktree and uses independent local storage. No recipe-data replacement, Metro/ore rewrites, personal-stock deduction, device access, installation or publication.

Implemented: direct/recursive demand, aggregate-before-rounding, recipe and ingredient choices, explicit supply boundaries, cycles and bounded arithmetic, one local explicit-save plan, conflict/corruption protection and source-preserving copy/text export. Quick DE/EN lookup handles names/IDs, quantity and numbered-variant followups; saved plans can be read aloud. Recipe ingredients/grids, plan targets/materials/outputs and Conversation search reuse optional item packs with text-only preference and neutral fallback. Existing crafting/Conversation help is extended in German and English. Android shares the catalog but does not synchronize plans or claim macOS feature completeness; see its `docs/ANDROID-0100-CRAFTING.md`.

Passing current-source checks: 2,888 catalog checks, 32 synthetic planner/storage checks, 19 crafting voice checks, 144 existing Conversation checks plus extended-catalog routing assertions, 20 existing owned-stock checks, eight Android Node calculation/DOM-flow tests and nine native icon-render comparisons for both packs/languages, missing mappings, text-only and pack removal. Icon tests use synthetic PNGs and isolated preferences; the sandbox-only first render attempt failed, and the corrected test passed with authorized graphics access. Full-source typecheck passed after the core icon hooks.

Final frozen-source universal build 1.7.43 (65), including the assistant and icons, passed for arm64 and x86_64 with no compiler diagnostics. Strict deep signature verification, executable mode 0755 and CommunitySource archive integrity passed. Packaged sources include the new planner, Conversation adapter, icon components and tests. Source comparison against the working application's `Sources` passed. Both arm64 and the final universal executable passed `--list` against an explicitly isolated empty library with ADB disabled. Executable SHA-256: `c988d1d597d8479b2d191d4e00b5c8febd58a9cb8f211f759a2c8e203bef90c6`. No installed bundle was replaced.

Real desktop-browser evidence for Android assets: DE 65-torch lookup, coal choice, 17 coal + 17 sticks / 68 output, explicit save/reload, 375-pixel layout without horizontal overflow. This is not APK, Android WebView or voice-service acceptance. APK build remains blocked by the unavailable SDK and pending SDK-license approval; a temporary JDK has been prepared, without system installation.

Interactive acceptance remains a separate gate: add and save two targets, reopen/reload, resolve alternative and cycle states, compare DE/EN labels, cancel/complete export, verify discard/save confirmation and conflict recovery, switch packs and text-only from both pages. The isolated native QA app launched, but Computer Use access failed; its owned process was closed. No full click-through acceptance is claimed. The installed application remains 1.7.38.

Concrete next integration order: complete the above native Mac acceptance against an isolated plan/library, then separately authorize installing the verified bundle. For Android, obtain SDK-license approval, build unit/lint/debug/instrumentation targets, run the synthetic WebView test on a disposable emulator, then accept offline speech, permission denial, Stop/pause and document export on the actual target device. Do not infer APK availability or Quest voice support from the desktop-browser checks. The temporary browser server and QA process have been closed; the browser viewport override was reset.

## Follow-up: 1.7.42 (64) · 2026-09-12

Approved scope: recommended items 1 and 4 followed by 2 — ore presentation, optional macOS completion notices and measured 3D connectivity. Recursive crafting lists and build-plan verification are not part of this package. No installation, publication, device access or real-save mutation.

| Responsibility | Implementation / reuse | Acceptance boundary |
| --- | --- | --- |
| Ore presentation | `OreLayer3DView`, `OrePresentation`; same SceneKit viewport and shared camera, `SavedOreScan.date` passed through `OreWorkspaceView` | Local PNG contains private data; export only by explicit save dialog. Camera persistence contains no world coordinates. |
| Measured 3D groups | `OreCluster`, shared `OreLayerMesh.validate` / `OreSpatial.cell` | Six-face neighbors and existing material variants; full measured payload, capped at 65,536 connected cells. Visible geometry remains bounded. Boundary, missing and capped results are not asserted complete. |
| System notification | `MapNotifications` plus a narrow successful-commit hook in `MapController` | Off by default; explicit authorization; generic background-only message. In-app result survives failures. Real OS permission/banner behavior must be accepted by the user. |
| Help and regressions | Existing `ores`/`maps` articles, `OreClusterTests`, `MapNotificationsTests`, extended `OreLayerSceneTests` | Synthetic native rendering and automated behavior are separate from whole-application acceptance. |

Verification completed for the frozen 1.7.42 (64) source: optimized universal arm64/x86_64 build passed with no diagnostics; strict deep signature verification and executable mode 0755 passed. The bundled CommunitySource archive includes the new sources, tests and reproduction guide. Source comparison against the integrated project passed (generated Graphify output excluded). Both the arm64 binary and final universal bundle passed a CLI read against an isolated empty library with ADB disabled. Executable SHA-256: `6ff8eb0ebeae84dcf93701b1408399a4751e6b2a0e8853f6f1159a81c4ea6f5d`.

Passing tests: six-face connectivity/limits, notification opt-in/denial/revocation/deduplication/failure/foreground/disable-race policy, existing ore mesh and models, bounded camera, native page-scroll regression, independent map-input/locking/cancellation regression, 68 Atlas Node cases and 42 Python cases plus offline video assertions. Native synthetic SceneKit context/filtered rendering, exact negative-coordinate picking, wireframe highlight, camera preset round trip/rejection and annotated PNG generation passed. The synthetic annotated export was visually reviewed.

Acceptance limitations: composited SwiftUI `cacheDisplay` captures were incomplete and are not accepted as UI proof. The isolated interactive test app launched, but Computer Use timed out on both path and bundle-ID access; no click-through acceptance is claimed. The owned QA process was closed afterwards. Real macOS permission prompts/banner delivery, enlarged-sheet/export-dialog interaction, full DE/EN help rendering and earlier combined app workflows remain manual acceptance items. No OS notification permission was requested. The installed app remains 1.7.38; the project app symlink still points to that installation.

Notification API reference: [Apple UserNotifications](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter). The system client uses alert-only permission and local notification requests, not APNs.

September 12: the [1.7.41 ore-layer 3D follow-up](RESOURCE-WORKSPACE-2026-09-09.md) adds a bounded native cutaway, shared orbit controls/materials, block picking and bilingual help. The original 1.7.40 checklist below remains open; no installation is implied by this later implementation.

## Current candidate: 1.7.40 (62)

User-approved scope: implement recommendation items 2–6, plus background Atlas rendering. Item 1 (the prior interactive acceptance/help/install pass) remains explicitly deferred. No installation, publication, Quest access or real-save changes are authorized by this delivery.

| Work package | Owner / shared boundary | Implemented behavior | Remaining boundary |
| --- | --- | --- | --- |
| Saved Metro journeys (2) | `MetroJourney`, `MetroView`, shared `PlanningStore` | Named snapshot-local journeys retain ordered directed legs and manually confirmed progress. Resume revalidates the entire network fingerprint and scope. Metadata writes use the library lock and optimistic comparison. | Any network change conservatively invalidates the journey. No live tracking or inferred arrival. |
| Ore presets (3) | `OrePreset`, `OrePresetsView`, existing ore setup | World-scoped named presets restore bounds, dimension, heights, materials, biome filter and sampling settings. | Applying settings never copies results or starts a scan. A matching world ID alone does not prove playthrough continuity. |
| Metro export (4) | `MetroJourneyExport`, existing shared assistant guidance | JSON/Markdown preserves checkpoint XYZ/dimensions, recorded geometry, measured timing, transfers and explicit portal confirmation. | Versioned `realmcraft.metro-journey` is separate from single-dimension terrain `NavigationPack`. No automatic terrain approach, descent, reverse route or portal prediction. |
| Backup change map (5) | `ChunkChangesView`, `ChunkChange`, `Library.verify`, Statistics | Verified hashes classify added, changed, missing and identical chunk files. North-up native map, filters, list centering, zoom and JSON export. | File-level evidence only; changed files do not prove changed blocks, and missing chunks are not empty terrain. |
| Incremental transfer (6) | `IncrementalBackup`, existing `Library.backup` transaction | Reuse independently verified source files by copy; pull new/changed files only; removed paths stay absent. Full-transfer fallback for corrupt/unusable bases or widespread changes. | Full remote checksums before/after and final local verification remain. No real-device performance claim or metadata-only fast path. |
| Background Atlas rendering | `MapController`, `MapSnapshotInput`, `MapCacheLease`, shell/lifecycle | Dedicated utility queue and up to four renderer workers use a verified independent input copy. Library access is released after preparation. Persistent in-app completion/failure notice, Open map, cancellation, source-selection guard and quit protection. Shared cache has a separate cross-instance lock. | Temporary input needs additional disk space; initial copy briefly takes the library lock. This is an in-app notice, not an operating-system push notification. Experimental Tectonicus keeps its separate workflow. |

### 1.7.40 verification and handoff

- Synthetic planning integration tests passed: persisted progress, stale-network/scope rejection, optimistic writes, corrupt metadata rejection, dimension-aware export/transfer geometry, ore-preset round trips and four-way chunk classification.
- Synthetic map-input tests passed: independent verified input, released library lock during rendering, source replacement isolation, cancellation, invalid source rejection, safe relative paths and exclusive cache lease/release.
- Lifecycle regressions passed, including refusal to perform application-wide quit while a background map job is active.
- Full Swift source typecheck and optimized universal arm64/x86_64 application build passed. Final version: 1.7.40 (62); strict deep signature verification passed and executable mode is 0755. The packaged command-line entry point ran successfully against an explicitly isolated empty library with ADB disabled.
- Complete Atlas suite passed 68/68 (66 existing Atlas cases plus portal-map and Tectonicus auto-fit tests).
- Python map/chunk/resource suite passed 42/42. The separate offline video-workspace smoke assertions also passed. Its existing relative path requires invoking discovery from the parent project folder; the initial invocation from the app source folder failed that import and the corrected invocation passed.
- Production arm64 binary passed the full simulated-ADB backup/restore integration suite, including unchanged-file zero-transfer, changed/new-only transfer, removed paths, nested filenames, immutable source, corrupt transfer, changing remote manifest, path traversal and damaged-base full fallback. Restore rollback, permissions, archive round trips and hostile archives retained their passing results. Only disposable synthetic data was used.
- The same complete integration suite passed again against the final universal application executable. The bundled community-source archive was then refreshed to include the test reproduction guide and the bundle was re-signed and strictly verified; executable logic was unchanged.
- Existing Metro model and cancellable renderer job regressions passed again. Reproduction commands: `Tests/README-planning-background.md`.
- Native interactive acceptance, including navigating away during a real render and reopening its completion result, is still outstanding. Automated checks are not a claim of complete GUI acceptance.

Final 1.7.40 executable SHA-256: `c6e5ec90c94eb03a6315c9458f747336173d6e08ef08dd0838aeda01a54a4104`. The installed application remains 1.7.38. The build used a frozen copy of this delivery's source; an unrelated `CraftingCatalog.swift` appeared in the shared workspace afterwards and is intentionally not part of this verified candidate. That concurrent work was neither edited nor rolled back.

Concrete next integration order: complete the deferred 1.7.39 checklist below and the new journey/preset/change-map/background-notice GUI checks in an isolated synthetic library; verify both UI languages, cancellation/retry and switching backups during rendering; confirm that exports contain only the selected snapshot's data; then separately authorize installation of the verified 1.7.40 bundle. Real Quest transfer benchmarking and Android/web parity remain separate work.

## Previous candidate: 1.7.39

Scope: the user-approved macOS integration follow-up. No Quest writes, real-save changes, publication or replacement of the installed application.

## Responsibility and integration register

| Work package | Owner / shared boundary | Implemented behavior | Remaining boundary |
| --- | --- | --- | --- |
| Map generation | `MapRenderJob`, `MapController`, `Model.work` | Cancel before launch, active cancellation, one-hour timeout, bounded SIGTERM/SIGKILL escalation, cleanup after exit, atomic commit boundary, completion even after library-lock failure. Earlier map survives cancellation. | Native GUI acceptance is recorded separately from executable job tests. |
| Safe build | `build.sh` | Fresh temporary destination by default; refuses existing bundles, symlinks and application-installation destinations. | Installation is a separate deliberate operation. |
| Metro carry-forward | `MetroCarryForward`, `MetroCarryForwardView`, `MetroNetworkStore` | Preview older same-world network into empty target; revalidate source and both portal fingerprints under library lock; changed/missing portal references removed; stations/edges reset to planned. | World ID alone does not prove the same playthrough. Travel observations must be reconfirmed; no automatic portal linking. |
| Resource handoff | `MapFocusTarget`, ore workspace, shared webview, `focus-target.js`, existing navigation | Exact snapshot/dimension/XYZ and block ID; coverage/privacy checks; surface approach with original target and unplanned-descent warning in exported guidance. | No underground routing or proof of safe excavation/final access. |
| Map tools | `tool-coordinator.js`, existing JS tools, Metro native bridge | Exclusive activation; pending-write veto; Escape, dimension and privacy cleanup; Metro capture cancellation returns to native state. | Generalized volume selection remains separate work. |

## Verification

Only synthetic fixtures and disposable outputs are used. Test/build results are appended after execution; this is a development candidate, not a shipped release or an assertion of Android/web parity.

- Complete Atlas Node regression suite: 66/66 passed.
- Python map/chunk/resource regression suite: 42/42 passed.
- Standalone Swift `MapRenderJobTests`: success, nonzero failure, early/active/final cancellation, timeout with forced termination and atomic commit boundary passed.
- Standalone Swift `MetroCarryForwardTests`: copy, portal changes, incompatible scopes, source preservation and stale-write rejection passed.
- Existing Swift `MetroModelsTests`: persistence, legacy decoding, directed routing, transfers, relative naming, radial proposals, captured geometry and selection validation passed.
- Full production-binary integration suite passed against simulated ADB and temporary synthetic files: backup/deduplication, verification, failed-transfer rollback, permissions, complete replacement, ZIP round trips and hostile-archive rejection. The initial sandbox run could not change fixture directory modes; the authorized isolated rerun outside that sandbox passed all cases.
- Optimized universal application build succeeded for arm64 and x86_64. Strict deep signature verification passed; executable permissions are 0755. Final version is 1.7.39 (61).
- Final binary `--list` returned only the two explicitly supplied synthetic snapshots.
- Native GUI acceptance in a separately identified QA app with a disposable profile/library and disabled ADB: older-backup selection, preview, confirmation, schematic/list refresh and persisted planned statuses passed. Original confirmed stations/edge and historical timing remained unchanged. Layout visually inspected.
- Repeating carry-forward is disabled once the target network is populated. The QA instance was closed after verification.
- Browser file-URL policy blocked the additional Atlas visual check. It was not bypassed. The final resource-target card, all map-tool combinations and native map-cancel/retry flow therefore still need complete interactive acceptance; unit/regression success is not a substitute.
- The installed application was not replaced. The first UI selection resolved to the regular app; only its setup sheet was dismissed with Later, then testing moved to the distinctly named isolated QA app. No real-world feature actions or savegame writes were performed there.

Final executable SHA-256: `c831ccc53906dadb68cc1601eb7a4455f896b427372babfd38b60690a16dc9f7`. A final resource-only correction places the resource card above the lower controls and uses the existing light/dark theme colors; it was repackaged and re-signed, but remains part of the outstanding Atlas visual acceptance.

## Handoff

The candidate must not be represented as fully accepted or already installed. Complete the remaining Atlas GUI checklist in an authorized isolated environment, then install the verified bundle as a separate action. Do not change or merge the original real-world networks automatically. Android/Quest and public web parity are outside this delivery.

## Manual acceptance checklist

1. Generate a map in a disposable library, cancel it, confirm no error alert and no replacement of the earlier map; retry successfully.
2. Select a newer synthetic backup, preview/copy an older Metro network, confirm planned status and intact source. Change portal evidence between preview and apply and verify rejection.
3. Select a known resource cell, open it in Atlas, verify exact XYZ and snapshot; choose surface-approach start and inspect exported warning. Test uncovered terrain and privacy mode.
4. Switch measurement, ownership, portal plan, resource rectangle and Metro capture; test Escape and dimension changes. Pending metadata writes must block ordinary switching.
