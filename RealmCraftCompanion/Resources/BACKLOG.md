BACKLOG

## Public documentation workflow · 1.7.54 (76) · 2026-09-13

Implemented: help-derived English wiki generation, source manifests, bilingual documentation skill and versioned screenshot records. Grow tutorials and screenshots from verified app workflows. Preserve independently written wiki pages; review regenerated files before publishing. Android/Quest and browser parity remain separate work.

## Recipe Markdown for agents · 1.7.54 (76) · 2026-09-13

Implemented: per-variant and per-item local verification, export selection, source-change invalidation, standalone Markdown and combined AI Markdown/JSON. Personal confirmations do not record a platform or game version and do not establish official Quest evidence. Remaining acceptance: physical keyboard/VoiceOver and external-agent file attachment. Android/web parity remains open.

## GitHub feedback · 1.7.53 (75) · 2026-09-13

Implemented: public-issue Markdown preview, title/body copy and browser handoff with a fixed URL. No GitHub authentication or direct submission is embedded. Remaining acceptance: browser sign-in/paste flow, clipboard/browser failures, long reports and narrow-window keyboard/VoiceOver checks. Test with synthetic reports without publishing test issues.

## Tectonicus map space and mirroring · 1.7.52 (74) · 2026-09-13

Implemented: a compact source/settings strip, map-first layout, separate source/result information and optional immediate horizontal mirroring of existing and new previews. Original renders and library data stay intact. Direction/elevation remain render-time settings. Reuse the existing map worker and shared native controls.

Remaining: full VoiceOver and physical trackpad acceptance, original block states/lighting/biomes, Nether support and repeat-render cache reuse.

## Obtaining guides and recipe filters · 1.7.51 (73) · 2026-09-13

Implemented: 22 obtaining guides for 170 catalog entries; 160 previously recipe-less entries now have a documented method. The 821 crafting variants remain unchanged. Of 618 catalog entries without imported recipes, 458 still have no specific obtaining guide; these stay visibly open rather than being declared uncraftable. Modern comparison names and block states do not establish the actual RealmCraft item set.

Next evidence work: test bucket source targeting, controller actions and Creative differences on a known Quest version; confirm RealmCraft-specific content, remaining obtaining routes and special/brewing recipes. Do not infer modern Minecraft mechanics. Android/web parity and full VoiceOver acceptance remain open.


## List-scoped search · 1.7.50 (72) · 2026-09-13

Search placement now follows the Savegames list pattern in Builds, Videos,
Recipes, Mobs, Chests, Help, Assistant instructions and Links/Knowledge. Existing query
and filtering behavior is retained. Follow-up acceptance: native tab order,
VoiceOver, long search hints, zero-result recovery and narrow list panes.

## Map and layer controls · 1.7.49 (71) · 2026-09-13

Compact action-aligned Maps controls, source information popover, readable map
titles and prominent ore Y navigation are implemented. Mouse wheel and standard
two-finger scroll handling is scoped to the layer row, with inertial tails ignored.
Next acceptance: physical mouse/trackpad direction and sensitivity, pinned layer
header in loaded screens, narrow-window keyboard/VoiceOver and long translated
labels. Keep the 1.7.48 stable backup available. Treemap remains a future idea;
no new quantitative visualization or platform synchronization is included here.

## Local stable baseline · 1.7.48 (70) · 2026-09-13

The integrated 1.7.47 candidate is promoted to the user-selected stable baseline
with the normal existing savegame library. Earlier candidate installation notes
are historical. No device transfer or save migration is introduced. The UI/UX,
keyboard/VoiceOver, Metro, translation-runtime and platform-parity acceptance
items below remain open; a stable designation does not close these findings.

## Metro network assistant · 1.7.47 (69) · 2026-09-13

METRO-005: automatic geometric proposals are implemented for concentric square
rings, up to 32 target pins and combined layouts. Three strategies compare a
minimum straight-line connection tree, symmetric construction and nearest-stop
branches. Preview reuses Atlas/MetroDiagram; explicit Apply preserves existing
metadata and creates only planned directed rail links and proposed portal sites.
Surface targets without confirmed measured portal observations remain open.
Limits: 1–8 rings, 16–4096-block spacing, existing network storage caps. Rail
length is geometric construction length, not terrain access, travel time or a
complete bill of materials. Next: terrain/coverage-aware candidate scoring,
verified portal siting, cost profiles, dense-network legibility and native
DE/EN/keyboard acceptance. No game writes, install or platform parity is claimed.

## Screen density · 1.7.47 (69) · 2026-09-13

Player refinement: align the two equal source segments and backup/world right
edge with Read player/Refresh rather than the full content width. Live keyboard
and loaded-state acceptance remains open.

Header-grid follow-up: backup selectors across source-based screens now end at
the actual action-group right edge, excluding Help/overflow. Maps area and
Tectonicus options follow that edge; headers without actions retain full width.
Ore section tabs and compact Metro navigation have equal-width segments.
Uniform 180 × 32 labeled header actions include Help. Symbol-only
controls remain square. UX-010/012 live narrow-window and popup acceptance remains
open; selection and draft protection are unchanged.
Comparable form selectors now share a fixed label column and full-width control
edge, with a stacked fallback for narrow panes. Verify long selected values and
popup keyboard interaction in the live candidate.

Implemented a shared alignment and progressive-disclosure pass after the supplied
screenshots. Video browsing, secondary details, source controls, Help rows, Metro
fields and ore setup/trial sections are lighter. Critical warnings remain visible;
opening a disclosure does not start an operation or save a draft.

UX-010/012/023 remain partially addressed: validate full native scrolling, long
DE/EN controls, both themes, loaded/error/busy states and keyboard/VoiceOver.
The 20-destination source matrix is in the audit. Source/component evidence is not
complete screen acceptance. A full Mining trials wizard and treemap remain future
work; the new expandable trial sections do not implement either.

## Library alignment · 1.7.47 (69) · 2026-09-13

Implemented: compact shared header, wider backup browser, consistent detail-title
hierarchy, responsive preview/facts grouping, aligned icon columns and square
symbol controls. No backup operation or destructive confirmation was changed.
Next: live validation of the complete library scroll area and header fallbacks
across destinations, then the guided Mining trials redesign. Synthetic component
renders do not establish full application or accessibility acceptance.

## Ore UX first package · 1.7.47 (69) · 2026-09-13

Implemented in source: independent close-inspection zoom, bounding-box framing,
Fit to view, zoom-limit feedback, compact Ore header, aligned layer controls and
nearby selected-height readout. Guide-camera defaults remain unchanged.
Camera math and synthetic SceneKit render/picking tests cover repeated zoom and
close-up preset round-trips. A separate test build must still receive live
standard/large-view, narrow-window, DE/EN and both-theme acceptance.
Next: redesign Mining trials as a guided sequence with consistent field columns;
then simplify reference presentation and distribution controls. Treemap remains
an optional later addition, not part of this package.

## Native audit preparation implemented · 1.7.47 (69) · 2026-09-12

Fresh Demo-profile tooling, a guarded audit-only launcher, source-executable content
verification, 20-screen/six-journey coverage records and allowlisted helper diagnostic
summaries are implemented. Fifteen synthetic tests passed. A separately signed
1.7.47 Demo candidate passed headless profile checks, import and integrity validation;
missing/wrong profile environments refused to launch. Original app/source, personal
library and permissions remain unchanged. See `docs/UI-UX-AUDIT-RUNBOOK.md`.

Approved native follow-up: audit app launch and bounded Demo startup passed;
Home/Help views and their inspected scroll areas worked. Switching to Ore was
followed by the same helper crash on screenshot retrieval, before an explicit AX
read. Ten matching reports now exist; both Companion processes continued running.
Retries stopped. Helper stability, full scroll/control coverage and cross-feature
acceptance remain open. This is not a helper
crash fix, an OS sandbox or a UI feature release. UX-018–023 remain proposed.

## Native audit infrastructure blocker · 1.7.47 (69) · 2026-09-12

The repeated closed-pipe error is now backed by nine same-day `SkyComputerUseService` crash reports (eight during the evening audit): helper 26.902.1000968, Swift assertion at `Array.remove(at:)`, identical helper offset. The Companion process continued from before those eight crashes; executable hash and strict signature still match. Exact UI trigger remains unknown. This is a testing-infrastructure defect, not a newly proven Companion feature crash. No fix, restart, permission reset or external report was performed.

Next: one controlled stability/reproduction gate; isolated Demo-only state; finish nine untouched screens and library visuals; finish partial panes/buttons and cross-feature tasks; then DE/EN/themes/keyboard/VoiceOver/newcomer acceptance. If the helper repeats the fault, stop retry loops and use user-operated overlapping screenshots, clearly labeled as assisted evidence. Full evidence and the ordered test plan are at the top of `docs/UI-UX-AUDIT-2026-09-12.md`. Original crash reports remain private.

## Community-first UI/UX audit · 1.7.47 (69) · 2026-09-12

Proposed work, not implemented. Full evidence, per-screen coverage and ordered packages are in `docs/UI-UX-AUDIT-2026-09-12.md`. Initial live inspection reached Home, Player and Maps plus library accessibility. After manual Home recovery, the walkthrough also reached Portal pairs, Metro, loaded Chests, Conversation/settings, one complete video article and parts of a build guide including a step/2D switch. UI transport failed again. These are state-level observations, not full screen acceptance; exact remaining scroll/control coverage is recorded in the audit. Future checks must traverse whole scroll areas and exercise safe load/switch/detail controls; never delete data and ask before unusual or potentially problematic actions.

- **UX-018 · P1 · Map reliability/recovery:** a saved Demo map showed only a grid, including after Whole world. All 10 expected tile paths exist; root cause is unconfirmed. Diagnose in an isolated copy, then provide visible load/render failure and retry/rebuild states. Acceptance: valid Demo terrain is visible and unavailable/corrupt assets cannot look like successful empty terrain; preserve old outputs and original backups.
- **UX-019 · P1 · Unique Go shortcuts:** eight feature commands share Cmd-Shift-E in `CompanionNavigationCommands`. Replace positional fallback assignment with explicit optional unique mappings; preserve unique established shortcuts. Acceptance: mapping uniqueness regression and native menu/focus verification. Existing case-order tests alone are insufficient.
- **UX-020 · P2 · Honest search coverage:** `QuickFindCatalog.search` labels every Crafting hit as a comparison recipe, although 618 of 1,206 browsable entries have no output recipe. Show item/no-recipe versus available-reference status in DE/EN; retain the unverified-game qualifier and exact result IDs. Acceptance: both coverage states produce truthful labels and unchanged target routing.
- **UX-021 · P2 · Answer-to-action handoffs:** add optional typed native actions to supported Conversation answers using existing `CompanionLookup` routing. Acceptance: exact recipe/guide/place opens without retyping, unknown intent requests clarification, draft guards remain, no new service or automatic microphone/network activation.
- **UX-022 · P2 · Chest density and icon fallback alignment:** the loaded Demo chest required long scrolling through repeated stacks, while final iconless rows shifted names left. Offer compact slot presentation or an explicitly separate stock summary and reserve the icon column. Acceptance: preserve exact slots/quantities/IDs, align labels with and without icons, and verify the final slot remains reachable. No content or asset absence is inferred beyond the observed rows.
- **UX-023 · P2 · Help orientation:** live Help still groups the five More tools features under Your world / AI tools; several topic names truncate. Align feature-topic groups with navigation metadata, retain stable IDs and support chapters, improve long-title readability, add a compact material-plan starter and describe type-first recipe browsing. Acceptance: matching specialist grouping, readable DE/EN titles, working old links/search, and retained safety/evidence details. Help's topic list and two complete articles, related-topic/back navigation and no-result recovery were successfully checked; all 48 article bodies were not. Transport failed again on Statistics, including a screenshot-only fallback; full live acceptance remains blocked.
- **UX-009/010/011/012/014 refinement:** explicit offline-first setup branch; compact Player avatar and Maps setup/header; consistent task verbs, source freshness and empty/disabled-state next steps. Keep all technical controls and safety evidence accessible.
- **UX-013/016/017 refinement:** edited video answer/steps before export configuration; reuse existing coach and material-plan flow; feedback fields adapt to report type; finish the blocked native matrix and newcomer acceptance in both languages/themes. Do not rebuild already present search, coach, filter popovers or single-sheet handoff.

Suggested sequence: A reliability/labels → B first useful result → C answer-first knowledge and handoffs → D community/native acceptance. No application implementation, installation, device write, screenshot publication or translation integration was performed by this audit.

## Community translation foundation · 1.7.47 source baseline · 2026-09-12

- **L10N-001 · Foundation implemented, coverage partial:** one versioned `Resources/Translations/catalog.json` inventories existing DE/EN interface text, recognized Swift literal branches/helpers, bilingual structured resources and setup/transfer documents. It includes source context, placeholder identities, target-language review states and a visible unresolved-literal list. `translation_catalog.py` refreshes the inventory, retains retired entries, exports scoped language packs and imports into a new candidate after source/target/placeholder validation. Native `tr()` resource generation now reads the catalog and permits reviewed English overrides. Complete text extraction is not claimed.
- **L10N-002 · Runtime migration · P1:** classify remaining literals, introduce stable semantic keys and explicit parameters, migrate Swift/content/map readers, add plural and locale-aware formatting, then expose additional locales with measured coverage and English/original fallback. Acceptance: one additional locale must work across every advertised screen, messages, help and maps without translating personal world/sign content. Android/web need their own adapters and acceptance.
- **L10N-003 · App translation workspace · P2:** Settings → Language & translations with search, context, completeness/review counts, explicit file export, preview/conflict-aware import, versioned local activation/reset and system sharing. Reuse native panels and draft guards. Acceptance: Cancel/error keeps the active pack and drafts; an invalid/stale import changes nothing; sharing starts only on an explicit action.
- **L10N-004 · GitHub and agent collaboration · P2:** the contribution guide and local CI commands are available; install translation checks into the actual repository workflow and add a focused PR template during a reviewed publication. Add a context-sensitive terminology glossary and an independent language review. No automatic agent self-approval, GitHub upload, PR or public release is implemented by this tooling change.

Validation: synthetic exchange/extraction regressions, complete inventory freshness check and isolated DE/EN resource generation. Installed app, savegames and platform binaries are unchanged. See `Resources/Translations/README.md` for the exact currently active runtime boundary.

## Type-first crafting and matching navigation · 1.7.47 (69) · 2026-09-12

- Crafting's item browser groups known item types before sorting material/color variants within each type, using explicit longest-match ID suffixes and DE/EN family headings. Ordinary boats, chest boats, rafts, fence gates, trapdoors, pickaxes and other distinct types remain separate. Unknown/special items keep their full title and independent identity. This changes presentation only: original item IDs, icons, recipe alternatives, filters, material-plan targets and evidence remain unchanged. Global Quick find and other ingredient pickers retain their existing search order.
- The Home explanation “What each section does”, sidebar and Go menu now share `CompanionNavigationGroup`. The overview includes matching group headings and Help, with specialist tools last. All 20 destinations and their original shortcut assignments remain intact. Metadata lives in `Sources/CompanionFeature.swift` so order and help-target regressions can run without the app model.
- No RealmCraft crafting mechanic was verified by this change. The bundled comparison recipes distinguish oak, birch and acacia boats and their corresponding planks; grouping does not make their ingredients interchangeable.


## Usability implementation · 1.7.46 (68) · 2026-09-12

Mac source candidate. This implements a first coherent package from UX-008–017, not every proposed screen redesign.

- **UX-015:** Metro connection editing now authorizes the transition inside the shared `editEdge` entry point. Both station and line links use it; Cancel or failed Save does not replace the draft.
- **UX-008/009:** persistent top sidebar search, four real category filters, grouped direct results, keyboard shortcut and explicit no-result/missing-catalog states. Feedback remains bottom-left. All 20 destinations and existing raw IDs/Go shortcuts are retained; five specialist tools use an expandable group that opens on direct navigation. Home leads with four task entries and offline/import/Quest options when no backup exists. Import is also visible in the library header. These new navigation entries start no transfers or rendering.
- **UX-010/012/014 (partial):** shared page-purpose/help row opens stable topic IDs through the draft guard. Source details separate technical IDs from game-file time and not-live status, now including Conversation. Localized world/backup, assistant-instruction and creature labels; actionable AI-export blocked reasons and an empty-network Metro sequence.
- **UX-011/013/016 (partial):** recipe filters collapse while counts/reset and evidence stay visible; unavailable historical metrics move into a labeled disclosure. Reviewed guide materials transition to the plan in the same sheet instead of opening a nested plan sheet. Explicit Save, provenance, bounds and recipe choices remain. Feedback participates in draft protection: successful ZIP export saves report/images, Cancel/errors retain the draft, Discard clears it; the mail recipient is not stored in ZIP and no mail is sent automatically.
- Help retains all 48 bilingual topics and existing IDs. Navigation, search, source, material and feedback workflows were updated; setup and embedded agent copies use the same current menu paths. No savegame schema, game content, world/library data, device write or publication changed.

Remaining: full Atlas/Ore progressive disclosure, portal/chest task flows, broader knowledge-filter harmonization, further dialog/VoiceOver/contrast work, and new-user task observation. The separate Metro/terrain adapter (UX-007) and Android/web parity are not part of this package. Native full-app task acceptance and installation remain separate from compilation, model tests and isolated component renders.


## New-user usability review · 1.7.45 baseline · proposed, not implemented

See the new-user follow-up in `docs/UI-UX-AUDIT-2026-09-12.md` for all 20 screens, dialog families, current-source evidence and acceptance tasks.

- **UX-015 · P1:** close the Metro line-to-connection draft-guard bypass before further presentation work; static finding, native reproduction pending.
- **UX-008/009/010 · P1:** persistent top knowledge search with real filters and bottom feedback; task-based Home with offline/import/Quest entry; consistent page purpose, primary action and actionable empty/blocked states.
- **UX-011/012/014 · P2:** progressive disclosure in Maps/Ore/Metro/AI export, concise source/result status, plain DE/EN terminology and context-sensitive help. Keep all technical options and safety-critical evidence.
- **UX-013/016 · P2:** consistent knowledge filters, single guide-material review/plan sequence, understandable dialog save/close states and feedback draft protection.
- **UX-017 · Per-package acceptance:** DE/EN, both themes, keyboard/focus/VoiceOver, short screens and real newcomer task observation. Existing geometry/model checks are not full GUI acceptance.
- No application implementation, installation, savegame changes or platform synchronization is part of this review. Preserve previous UX IDs and historical completion notes below.

## UX integration · 1.7.45 (67) · 2026-09-12

Implemented in the macOS source candidate; installation and native end-to-end acceptance remain separate.

- Shared `SourceContextBar` replaces duplicate backup pickers in Metro, portals, ores, Maps, Tectonicus, Chests, Player (backup mode), Statistics, Editor and AI export. It distinguishes backup time, game-file time and optional dimension/result time using the existing Savegame model.
- A per-model `DraftTransitions` registry guards source/workspace transitions, protected feature selections/reloads, setup opening, main-window close and application termination. Metro, portal and ore-trial drafts and material plans participate. Save failures and Cancel block navigation; Discard restores persisted state. Other editors retain their existing policies. Portal metadata additionally rejects stale concurrent writes.
- Page headers adapt to narrow widths. Metro switches its three panes below 1080 points of workspace width. Ore 3D, Feedback and Build coach use bounded flexible sheets. Travel modes are localized; portal/ore notices share text, icon and severity. This is partial consistency work, not an accessibility certification.
- Quick find (Cmd-Shift-F) reuses four local catalogs and opens exact recipe, build-guide, video or help IDs after clearing destination filters. Searching starts no scan, playback or AI request. Opening a video destination may load its normal online thumbnails.
- Reviewed build-guide materials can be added to the existing crafting plan. Only explicit unambiguous item IDs and exact bilingual quantities are preselected. Users resolve uncertain rows; omitted rows and original values remain in provenance. Existing recipe choices are preserved; explicit Save plan is required. No stock deduction, recipe verification or cross-platform synchronization is implied.
- Help now contains 48 bilingual topics, including Quick find and the new source/draft/material workflows. All previous topic IDs remain valid.

Remaining: native keyboard/focus/window-close and nested-sheet acceptance, minimum-window Metro interaction, long source titles, VoiceOver/contrast, remaining editor/status consistency, and UX-007's separate Metro/terrain navigation adapter. Android/APK/web parity is not claimed.

## UI/UX consistency · 1.7.44 audit · 2026-09-12

Detailed source evidence, all 20 destinations, principal dialogs and acceptance criteria: `docs/UI-UX-AUDIT-2026-09-12.md`.

- **HELP-001 · Implemented:** 47 DE/EN topics, stable IDs, related/back navigation, bilingual search with correct no-results behavior, current menu paths and synchronized setup/agent instructions. Whole-app native acceptance is separate.
- **UX-001 · P1:** shared source-context display, piloted in Metro/Ore, distinguishing backup time, game time and result time.
- **UX-002 · P1:** consistent Save / Discard / Cancel guard for unsaved feature drafts and source/selection transitions; reuse the existing material-plan safety pattern.
- **UX-003 · P1:** adaptive toolbars/inspectors and flexible scrollable dialogs, especially ore 3D, Metro, feedback and coach.
- **UX-004 · P2 / quick:** localized travel modes, consistent search/refresh/source terminology and text-backed status/evidence presentation; extend contrast/keyboard/VoiceOver checks.
- **UX-005 · P2:** global quick finder reusing local indexes, with explicit result handoff and no automatic scan, download or operation.
- **UX-006 · P2:** reviewed build-guide → material-plan handoff, preserving unmapped items and uncertain quantities; no silent stock deduction.
- **UX-007 · P3:** versioned Metro/terrain navigation adapter only after source/transition consistency and confirmed direction/portal evidence.
- Recommended order: UX-001/004, UX-002/003, then UX-005 and preview-only UX-006. This audit does not implement those non-help changes.

## Crafting material planner · 1.7.43 development candidate · 2026-09-12

- **CRAFT-001 · Recursive material plan:** multi-target direct/recursive calculation, explicit production/ingredient choices, shared-batch rounding, cycle/quantity guards, local persistence and provenance-preserving text export implemented.
- **CRAFT-003 · Recipe/plan icons:** macOS recipe ingredients, alternatives, grid slots, plan targets/materials/outputs and Conversation lookup reuse the existing optional icon packs. Direct settings access, text-only preference and neutral missing-icon fallback are implemented; real native click-through remains an acceptance gate.
- **CRAFT-002 · Quick/voice retrieval:** macOS Conversation lookup, quantity/variant followups and saved-plan reading implemented. Android 0.10.0 source candidate carries the same catalog, responsive local lookup/planner and optional on-device speech. APK, native speech and physical Quest acceptance require their own gates; see the cross-platform integration note.
- Remaining: multiple named plans, mixing alternatives within one ingredient group, verified personal-stock reconciliation and confirmed RealmCraft recipe coverage. Fuel and station construction remain explicitly excluded; these are not missing quantities represented as zero. Platform parity and GUI acceptance are separate.

## Ore exploration comfort · 1.7.42 development candidate · 2026-09-12

- **LAYER-007 · Presentation:** large cutaway view, stored relative camera and explicit local PNG with date, bounds and legend implemented. No model/texture export or publication.
- **LAYER-005 · 3D connectivity follow-up:** six-face connected material groups across existing spatial census data, count/Y range and visible-slice highlight implemented. Missing neighbors, measurement boundaries and the 65,536-block cap remain explicit. Arbitrary subdivisions, automatic geological classification and safe underground routing remain open.
- **MAP-007 · System completion notice:** explicit opt-in and permission handling, background-only completion including gaps, duplicate suppression and in-app fallback implemented. Real macOS permission/banner acceptance requires user interaction; Tectonicus remains separate.

## Layer 3D · 1.7.41 development candidate · 2026-09-12

- **LAYER-006 · Native 3D cutaway:** implemented from validated spatial census data, with shared material selection, 1/4/8-layer thickness, bounded movable sections, fixed-target camera, block picking and existing tunnel/Atlas handoff. Missing cells remain explicit; no terrain or ore geometry is inferred from aggregate/sample-only reports.
- Remaining: full-world 3D analysis, original game textures/partial-block shapes, automatic geological vein classification and platform parity. Measured 3D connectivity is covered by 1.7.42 above. GUI acceptance and installation are tracked separately from model/build tests.

## Crafting catalog · 1.7.40 development candidate · 2026-09-11

- Implemented: offline name-catalog coverage, pinned comparison recipes, direct ingredient quantities, stations, grids, variant selection, ingredient navigation and bilingual help. See `CRAFTING-SOURCES.md` for provenance and reproduction.
- Remaining: record exact RealmCraft platform/version and in-game evidence for every recipe, station, yield and item mapping before promoting any recipe to verified. Missing entries are not classified as uncraftable. Complete RealmCraft-exclusive, dynamic and brewing recipes from evidence; add newer comparison versions only as explicitly separate sources.
- Web parity and extending personal-stock checks to this catalog remain separate follow-ups. Recursive material lists and conversation lookup are covered by 1.7.43 above; Android 0.10.0 is a separate source candidate, not a claim of an installed or tested APK.

## Implemented in development candidate · 1.7.40 · 2026-09-11

- **METRO-005 · Persisted journeys:** named snapshot-local routes and manually confirmed progress, guarded by a network fingerprint. Changed networks require replanning.
- **METRO-006 · Structured journey export:** multi-dimension JSON/Markdown with explicit portal checkpoints, transfers, recorded paths and shared assistant safety guidance. Terrain approach/departure routing remains open.
- **ORE-005 · Reusable analysis presets:** world-scoped region/filter/sampling settings, kept separate from measurement results.
- **STAT-004 · Chunk change map:** verified backup hashes shown as new/changed/missing/identical chunk files, with filtering, centering, zoom and JSON export. Block-level difference decoding remains open.
- **LIB-004 · Incremental follow-up transfer:** copy verified unchanged files and download changed/new files; retain full SHA-256 checks and full-transfer fallback. Metadata-assisted remote hash acceleration and real-device timing remain open.
- **MAP-006 · Background rendering:** verified independent temporary input, dedicated queue, continued navigation, persistent completion/failure notice, Open map, cancellation and separate cache lease. Optional system notifications are added by MAP-007 above; background Tectonicus conversion remains open.
- **Acceptance boundary:** the user deferred the previous interactive acceptance/help/install step. This candidate is not installed or published. Complete the isolated GUI checks and installation separately; see `docs/INTEGRATION-2026-09-11.md`.

## First comprehensive code audit · 2026-09-07

Detailed evidence and the complete idea matrix are in `docs/AUDIT-2026-09-07.md` and `docs/IDEAS-2026-09-07.md`. These items are ordered by dependency; they are not promised release dates.

- **DEV-005 · Safe build destination · Completed 2026-09-11:** `build.sh` now defaults to a fresh temporary bundle and rejects symlinks, existing destinations and paths under `/Applications`. Installation remains a separate, verified step, so a development build cannot follow the project app symlink or retain stale resources in a reused bundle.
- **MAP-004 · Restore the Atlas regression gate · Completed 2026-09-11:** the orientation harness loads the portal and Metro modules; the complete Atlas Node suite passes 62/62.
- **DEV-006 · Documentation/version reconciliation · P2:** completed in this audit: aligned the Android 0.9.0 README and backlog with shipped 0.8/0.9 behavior. Remaining: decide after public-content review whether `package_source.py` should include the new `docs/` directory.
- **MAP-001 · Shared map-tool coordinator · Partial in 1.7.39 candidate:** shared activation, Escape, dimension/privacy reset and pending-write protection now cover measurement, ownership, portal plans, resource selection and Metro capture. Remaining: a generalized world-region/volume selection contract; existing coordinate transforms remain shared.
- **LAYER-001/003 · Layer and region aggregates · Present in 1.7.38:** the existing Atlas area handoff now feeds a bounded north-up layer map, material filters and a layer/volume ledger. Remaining: arbitrary user-defined material categories and a generic WorldRegion migration (INT-002). Keep world counts separate from inventory ownership.
- **LAYER-004 · Interesting-layer navigation · Present in 1.7.38:** selected-material count thresholds drive arrow/keyboard/Option-scroll skipping; the slider remains unrestricted. Incomplete coverage is explicitly reported, not interpreted as zero terrain.
- **LAYER-005 · Multi-area and cluster analysis · Partial in 1.7.42 candidate:** adjacent-area comparisons, layer connectivity and snapshot-scoped XYZ handoff to Atlas are implemented; 1.7.42 adds measured six-face 3D connectivity with explicit limits. Existing navigation plans a surface approach and exports the original target plus an explicit unplanned-descent warning. Remaining: arbitrary subdivisions, geological classification and validated underground/final-access routing.
- **METRO-001 · Verify RealmCraft portal mechanics:** complete the existing evidence matrix for scale, search radius, height, orientation and both travel directions before reliable link prediction.
- **METRO-002 · Metro graph and persistence · Partial in 1.7.39 candidate:** snapshot-local editing and reviewed carry-forward to a newer same-world empty network are implemented. Carry-forward rechecks both portal files and source metadata, drops changed portal references and resets all travel evidence to planned. Remaining: reconciliation with directed portal observations; never promote evidence automatically.
- **METRO-003 · Geographic and schematic metro views · Partial in 1.7.38:** one network drives the direction-aware schematic, dedicated shared-Atlas workspace and read-only Metro layer in standard Atlas. Station/portal picking, color picker and manual bend capture are implemented. Remaining: topology-aware automatic rail tracing with coverage evidence, line offsets/label collision management for dense networks, and ring-network optimization.
- **METRO-004 · Route integration · Partial in 1.7.38:** confirmed measured journeys show line changes, checkpoints, manual arrival confirmation and a copied briefing using existing navigation safety instructions. Remaining: validated dimension-aware NavigationPack adapter, terrain-checked approach/departure legs, shared spoken-section/export integration, waiting-time model and journey-progress persistence.
- **DEV-003 · Maintainable change index:** document a reviewed Graphify update command and extend coverage beyond the Swift source corpus before considering automation. Heuristic edges remain non-authoritative.
- **DEV-004 · Cross-platform conformance fixtures:** run the same synthetic world/chunk/player/chest/sign vectors and neutral expected JSON through Python/Swift, Android Java and web JavaScript readers.

## Ore research follow-up

Shipped in 1.7.35: direct chunk census, spatial random sampling, horizontal biome stratification, Top 3 heights, version-pinned Java references and mining-trial journals with before/after and chest/sign evidence.

Shipped in 1.7.38: linked layer inspection, shared multi-material line/heatmap/bar charts, geographic area comparison and consolidated trial workflow. See `docs/RESOURCE-WORKSPACE-2026-09-09.md` for scope and compatibility.

- Validate generation mechanics across multiple RealmCraft VR game versions and pristine independent worlds before promoting a Minecraft height transform to a confirmed rule.
- Add a version-verified Bedrock reference profile; do not silently apply Java counts to Bedrock.
- Consider population-weighted spatial estimates and cluster-based uncertainty intervals after the sampling design and effective independent units have been validated. Current spatial samples and trial rates remain explicitly descriptive.
- Port the new ore research workflow to Android/Quest and the web demo in a separate platform-sync update.

## Planned · Nether Portal & Travel Planner · 2026-09-07

Portal inventory and locally recorded directional pairs shipped in 1.7.33. Version 1.7.34 adds map picking, a portal layer, local plans and an explicitly assumed 8:1 X/Z calculator in both directions. Verified link prediction, route planning and platform parity remain planned. Suggested German UI name: “Nether-Reiseplaner”. Plan portal locations and shorter journeys between settlements, landmarks and biomes in either direction between the Overworld and the Nether.

Nether Metro workspace (1.7.38 development integration): the macOS page now combines a searchable station/line directory, schematic or shared geographic map, contextual editors and a journey inspector. Saved portals can seed stations; names and radial proposals use a user-selected Nether origin, with N = −Z. A native color picker and manually recorded bend geometry drive the map overlay without copying terrain tiles. Stations, lines and connections are editable/removable; line removal retains its connections, while station deletion confirms affected links. Planned and built links remain non-routable; only manually confirmed directed links between confirmed stations with measured durations produce travel instructions. No portal pairing, scale conversion or savegame modification is performed. Remaining work is the evidence workflow below, generic map-tool coordination, dimension-aware navigation/export adaptation, automatic rail topology, snapshot carry-forward and Android/web parity. See `docs/METRO-WORKSPACE-2026-09-09.md` for exact contracts and verification limits.

- **First step — verify RealmCraft mechanics:** inspect existing portal candidates in a selected local snapshot and compare two user-confirmed portal pairs. The reported starting scenario has two portals in each dimension, connecting a main base and a second settlement through the Nether, with one Nether portal near a fortress. These are user-reported connections, not yet verified from save data. Keep actual place names, coordinates and evidence in private local analysis; public documentation and tests use synthetic examples. Establish the horizontal scale, axis conventions, rounding and actual linking behavior for the installed RealmCraft version before claiming accurate predictions. Do not infer confirmed links solely from proximity or a place label.
- **MVP input:** choose the source dimension and click a map location, select a saved place/biome destination, or enter X/Z coordinates with optional Y. Offer “Plan corresponding portal” from the map and allow switching the calculation direction. Use world coordinates regardless of map rotation.
- **MVP result:** show the corresponding target X/Z, a target marker in the other dimension, copyable coordinates and a separately saved planned place. Treat the Minecraft-style 8:1 horizontal scale only as an explicitly labeled, unverified starting hypothesis: Overworld to Nether divides X/Z by 8; Nether to Overworld multiplies X/Z by 8. For a synthetic example, Overworld (800, -400) maps to Nether (100, -50) under that assumption. Preserve the exact result and show the chosen block rounding, including negative coordinates. Y is a separate height/build-site choice, not a value to divide or multiply by eight; safe height and RealmCraft height/linking rules require verification.
- **Existing portals:** show detected or manually recorded portals by dimension and let the user confirm observed travel connections, including each direction separately. Distinguish planned, detected and travel-confirmed portals. Show nearby portal candidates as possible linking conflicts; do not copy Minecraft search radii or guarantee which portal RealmCraft will choose without evidence. Generated exits may differ from the ideal coordinate.
- **Travel planning:** initially compare direct Overworld horizontal distance with the horizontal Nether segment and optional approach/departure legs via existing portals. Label these as geometric estimates, not traversable routes or guaranteed time savings. Later integrate the existing waypoint/transport planner for multi-stop biome trips and a portal-network overview; add travel-time estimates only with justified movement assumptions.
- **Coverage and safety:** display snapshot date, missing map coverage and unknown terrain at the proposed build site. A mathematically corresponding point is not proof of a safe or buildable location. Store plans as Companion metadata; this feature does not construct portals or change savegames. Reuse existing map, saved-place and navigation components, with macOS as the initial reference for subsequent platform parity.
- **Acceptance for the first release:** verify both conversion directions, zero/negative/fractional coordinates, rounding and rotated-map picking with synthetic fixtures; demonstrate map-click and manual-coordinate parity and persistence of planned places. Validate the assumed transform against observed RealmCraft portal pairs, document deviations and preserve uncertainty about untested link selection. If validation remains inconclusive, ship only as an explicitly experimental calculator with a visible assumed scale.

### Minecraft reference and RealmCraft verification matrix · 2026-09-07

User-provided reference: [Netherportal](https://minecraft.fandom.com/de/wiki/Netherportal), especially [portal interaction](https://minecraft.fandom.com/de/wiki/Netherportal#Wechselwirkung_zwischen_Portalen). Direct page retrieval was unavailable during this review; the user supplied excerpts describing a 128-block Overworld spacing, preserved east–west/north–south orientation of generated exits, and an eightfold horizontal distance relationship. These are Minecraft comparison claims, not verified RealmCraft behavior. Record Minecraft edition/version when retrieving the full rules; do not treat a wiki excerpt as a universal minimum-spacing guarantee.

| Comparison hypothesis | RealmCraft verification needed | Current status |
|---|---|---|
| Horizontal 8:1 scale | Compare several independently observed pairs in both directions, positive/negative X/Z, and distinguish ideal coordinates from generated-site displacement. | Existing local pairs are compatible with this hypothesis, not conclusive. |
| 128/1024-block Overworld spacing and shared Nether exits | The longer user-supplied excerpt distinguishes a claimed 1024-block spacing for new exits from a 128-block shared-exit area. Resolve these contexts and edition/version differences; separate coordinate scale, existing-portal search radius and new-exit placement. Test boundary distances in both travel directions with controlled competing portals and heights. | Unverified; neither 128 nor 1024 is a guaranteed RealmCraft linking threshold. |
| Automatically generated exits retain the source orientation | Test generated exits from both portal orientations in both dimensions. Distinguish generated exits from manually built or subsequently rebuilt frames. | Unverified; existing portal geometry alone cannot establish generation behavior. |
| Height and nearest-portal selection | Hold X/Z constant while varying Y; determine whether 2D or 3D distance and tie-breaking affect the chosen exit. | Unverified. |
| Return paths and changed portals | Observe both directions independently, then separately test moved/deactivated/rebuilt portals and reloading. | User-reported forward journeys recorded; reverse behavior not independently tested. |

Additional supplied material describes many-to-one connections, returning through a shared exit to a central portal, a multiplayer deactivate/reactivate procedure, and portals above the Nether ceiling. Keep these as separate unverified comparison cases. The supplied diagram illustrates the claimed 128-to-16 horizontal scale and shared exits; it does not establish a RealmCraft search algorithm. Model portal travel as directed connections rather than assuming exclusive symmetric pairs. Do not promise that every newly placed Nether portal generates a new Overworld exit or that an eightfold coordinate scale guarantees an eightfold time saving. Approach legs, terrain, portal delays and movement speeds must be included. Multiplayer manipulation and ceiling builds are outside the initial planner and require separate platform/version feasibility checks. Do not reproduce the supplied third-party illustration in distributed resources without checking its license.

Maintain evidence per rule: source, platform/game version, controlled setup, before/after portal coordinates and orientation, observed outcome, and confirmed/different/unresolved status. Use local analysis or an isolated test world; do not alter existing portals for these experiments. Only verified rules may drive reliable linking predictions; all others remain visible assumptions.

Related work: Atlas navigation and position tracking, Saved biomes, and Chest explorer and places. Initial scope is coordinate and portal planning; automatic Nether pathfinding is a later extension.

## Completed · 1.7.30 · Help and public documentation

Refreshed bilingual in-app help and added route-planning/navigation guidance. Documented 3D build controls, current video and export options, 90-degree map orientation and sign labels. Public documentation distinguishes snapshot-based navigation from live tracking.

## Completed · 1.7.29 · Guide panels and sign labels

Collapsed secondary build-guide controls, isolated page scrolling from 3D camera motion and improved partial-block previews. Signs can show their labels directly when the layer is enabled.

## Under consideration · Minecraft-tool inspiration · 2026-09-06

These are proposed RealmCraft Companion extensions, not implemented features. Integration version: not assigned; record the actual app version in the Update Log when an item ships. Suggested order favors improvements to existing read-only views and build planning before new world-writing capabilities.

Discovery references: [Programs and editors](https://minecraft.fandom.com/wiki/Tutorials/Programs_and_editors) and [Mapping / Mappers](https://minecraft.fandom.com/wiki/Tutorials/Programs_and_editors/Mapping#Mappers). The mapping subpage could not be retrieved during this review; the tool descriptions below were checked against their own project pages. The proposals are our adaptations of those concepts, not claims that these tools support RealmCraft saves, block IDs, mechanics or seeds. Evaluate format mappings and licenses separately before any integration or reuse.

### Tectonicus-compatible export — user-requested feasibility idea · 2026-09-06

Goal: generate a separate rendering export from a RealmCraft snapshot so that Tectonicus can produce its zoomable maps. Status: integrated as an experimental Overworld workflow in Companion 1.7.31; block-state fidelity remains incomplete. Tectonicus 2.31 rendered four synthetic RealmCraft v9 chunks via a Java 1.16.5 intermediate. Independent read-back verified 262,144 cells against the declared mapping, and the browser map was visually checked. Real-save fidelity, complete block/state mapping, lighting and biomes remain unverified. BlueMap 5.23 also rendered the same synthetic export after license confirmation; four high-resolution mesh tiles and the browser view were verified. Its partial-world setting `ignore-missing-light-data: true` is required for this isolated fixture. Neither prototype establishes full real-save fidelity. The subsequent 1.7.31 integration adds the local Tectonicus workflow described below.

Local demo milestone (2026-09-07): Tectonicus 2.31 rendered 1,020 approved demo chunks through a Java 1.17.1 intermediate. Independent read-back checked 66,846,720 block positions against the declared mapping; 354 base tiles and zoom levels rendered without exceptions and passed browser visual inspection. Block-state defaults, blank sign text, constant biome and simplified lighting remain approximations. No full game-to-render fidelity or playable-world compatibility claim. Companion 1.7.31 adds setup, save selection, separate exports, progress/cancellation and local preview. Next: decode original block states, lighting and biomes; add Nether support and repeat-render cache reuse.

Reference: [Tectonicus project and usage](https://github.com/tectonicus/tectonicus). Tectonicus renders Minecraft Java worlds and accepts an XML configuration. A generic 3D model export or renamed RealmCraft files would not establish compatible world input.

- Investigate a one-way adapter from verified RealmCraft chunk data into a minimal Minecraft Java world layout accepted by a pinned Tectonicus release. Determine the required metadata, chunk/region encoding, data version, block states, lighting, height and dimension conventions before choosing the export format.
- Maintain an explicit mapping from RealmCraft blocks and orientations to renderable target blocks. Report exact mappings, visual substitutions, unsupported blocks and missing coverage separately. Check texture/resource requirements and permitted use; visual resemblance does not imply equivalent game mechanics.
- First milestone: export a small synthetic region containing solid terrain, water, glass, stairs and directional blocks; generate the matching XML configuration and render it with unmodified Tectonicus. Verify geometry, orientation, heights and missing-block reporting against the Companion preview. Record the tested Tectonicus and target world-format versions.
- If a world-format adapter proves impractical, investigate a dedicated RealmCraft reader for Tectonicus as a separate alternative requiring upstream work or a maintained fork. Do not describe that alternative as support in stock Tectonicus.
- Keep exports separate from the source snapshot and label them as rendering intermediates, with a mapping/coverage manifest. Preserve original saves; Minecraft playability, round-trip conversion and writing back to Quest are outside this proposal. Add signs, landmarks and repeat exports only after the basic render succeeds; public examples must use synthetic data or the approved, reviewed demo.

Related work: tiled atlas export below, chunk coverage inspection and selected-building 3D export. This item targets using Tectonicus itself, rather than only borrowing its presentation ideas.

### 1. Tiled atlas export and reusable viewing presets — first candidates

Inspiration: [BlueMap](https://github.com/BlueMap-Minecraft/BlueMap) generates a browser-viewable 3D world surface; [Minecraft Overviewer](https://overviewer.org/) presents high-resolution maps through Leaflet.

Extend the existing atlas with bounded, multi-resolution tile exports for large snapshots, saved camera/layer presets and an exportable offline viewing package. Rebuild only affected tiles when compatible snapshots change. Show snapshot date, dimension, coverage and missing regions. First milestone: one selected region that opens locally with preserved markers and a visible coverage legend. Reuse the current map cache and marker-export work rather than introducing a second viewer. Public examples must use the approved, reviewed demo world; exporting locally must not publish anything automatically.

### 2. Build-plan placement and snapshot verification — first candidates

Inspiration: [Litematica](https://github.com/maruohon/litematica), a schematic mod with placement and area-manipulation workflows.

Place a guide's model at a chosen atlas origin, rotate it and compare its expected blocks with a later imported snapshot. Highlight matching, missing, unexpected and undecodable cells; derive remaining materials from verified mappings and optionally compare against owned chest stock. First milestone: one fully modeled guide, a read-only ghost overlay inside the Companion, and a per-layer mismatch list. This extends the existing interactive previews and material checks; complete guide geometry is a prerequisite. It does not imply an overlay inside RealmCraft VR or live build tracking.

### 3. Chunk coverage and change inspection — first candidates

Inspiration: [MCA Selector](https://github.com/Querz/mcaselector), which selects Minecraft chunks and regions for export or deletion.

Add a read-only chunk grid with filters for decoded, missing, unreadable, new and changed chunks between compatible backups. Let users select a region for a coverage report or a bounded map export. First milestone: compare two snapshots and jump from a changed chunk to its atlas view. Extend the existing Statistics comparison and library diagnostics work; distinguish file-byte changes from verified block changes. Chunk deletion, regeneration and partial restoration remain separate feasibility work, with no assumption that Minecraft region operations transfer to RealmCraft.

### 4. Reusable construction modules and shape planning — later candidate

Inspiration: [WorldEdit](https://worldedit.enginehub.org/en/latest/) offers region selections, clipboard operations, shape generation and history.

Within the build-plan editor, select a module, copy, rotate, mirror and repeat it; generate parameterized walls, cylinders, arches and corridors with material totals. Add undo/redo and show the resulting geometry before accepting an operation. First milestone: duplicate and rotate a room module while keeping steps, connections and quantities consistent. Store results as Companion plans. Writing these plans into a save requires a separately verified writer and an explicit editing workflow.

### 5. Structured save inspector with an edit review — later candidate

Inspiration: [NBT Studio](https://github.com/tryashtar/nbt-studio) provides structured data navigation, search and undo/redo for Minecraft NBT.

Extend the existing RealmCraft editor with a searchable tree of verified fields, types, source offsets and original/current values, plus a concise review of pending changes. First milestone: a read-only field inspector and a before/after summary for already supported edits. Unknown records remain uninterpreted and read-only. RealmCraft data is not assumed to be NBT; reuse the navigation idea, not Minecraft's schema. Preserve materialized editor copies, checksum checks and rollback protections.

### 6. Export a selected building as a 3D model — later candidate

Inspiration: [Mineways](https://www.realtimerendering.com/erich/minecraft/public/mineways/) exports Minecraft creations for rendering, animation and 3D printing.

Export a bounded, decoded RealmCraft region or a complete Companion build plan to a common model format such as OBJ or glTF, with explicit scale, origin and unsupported-block reporting. First milestone: a small synthetic building that round-trips into an independent viewer with correct orientation and dimensions. Start with schematic materials; include textures only when redistribution is permitted. Treat watertight, printable meshes as a subsequent step requiring separate geometry checks.

### 7. Reproducible presentation renders — later candidate

Inspiration: [Chunky](https://chunky-dev.github.io/docs/) provides scene rendering with camera, lighting and material controls.

Add saved presentation scenes for existing build previews: camera, lighting, background, output dimensions and quality settings, followed by local still-image export. First milestone: reproducible front, side and perspective images for one complete guide. Keep illustrations distinguishable from in-game screenshots and retain untested/AI-generated guide labels. Use synthetic plans or the approved demo for public galleries. Higher-quality rendering is an optional follow-up to the current interactive viewer.

### 8. Terrain and landscaping planner — exploratory

Inspiration: [WorldPainter](https://www.worldpainter.net/) uses painting and sculpting tools to create Minecraft landscapes.

Explore a non-destructive planning layer over a selected RealmCraft snapshot: sketch paths, terraces, gardens and excavation volumes, then estimate blocks to remove or place using decoded terrain. First milestone: a small terrace with before/after cross-sections and a material estimate. Save the proposal separately from the world. New-world generation, biome painting and terrain writes require independent RealmCraft format and behavior validation; do not assume Minecraft seed or generator compatibility.

## Completed · 1.7.28 · Practical 3D controls and guide topics

Constrained build-preview controls to centered orbit and bounded zoom with explicit rotate/tilt/zoom/reset buttons; framing adapts to viewport size and free panning is disabled. Added ten shared build-guide topics and reassigned all 91 guides by primary purpose.

## Planned · Bring the 19 oldest build guides to full 3D parity

User-requested follow-up: upgrade guides 01–19 to the same complete, step-resolved geometry and presentation standard as the newer guides. Replace their partial slice previews with explicit x/y/z block states for every construction step, including supports, depth, attachments and temporary or changed cells. Reconcile the new data with the written steps, materials, full layer plans and side views; add missing diagrams where necessary. Validate all projections, quantities, orientation, clearances, step changes, icon textures and height cutaways. Retain Untested / AI-generated labels until tested in RealmCraft VR. Mark this item complete only when all 19 guides have full 3D models.

Scope: lamp, dropper, furnace, compost, flush, cane, collector, feedline, slider, cobble, cactus, flowers, waterline, storageindicator, autocane, transport_path, transport_stairs, transport_rail, transport_ladder.

## Completed · 1.7.28 · Interactive build previews

Added step-controlled 3D geometry, texture reuse, camera controls, picking and height cutaways. The 19 earliest slice-only guides explicitly identify incomplete volume coverage; expand their documented geometry before claiming complete 3D models.

## Completed · 1.7.27 · Build-guide icon display

Optional pack textures now appear in all build-plan grids and their legend, with a saved local display switch, pack settings access, orientation labels and symbol fallback.

## Planned · UI consistency across main screens

Static layout audit completed for all 15 main navigation destinations. Version 1.7.23 implements the shared header/action geometry, Home/Editor frame, stable mob list width, aligned reading columns, common detail typography and compact loading lanes. Synthetic runtime geometry checks cover the shared header at four widths in both appearances, with English/German labels and enabled/disabled states. Full interactive coverage of every page and exceptional state remains pending. The public screenshot gallery uses only an explicitly approved demo in an isolated library. Broader UI validation remains pending.

- Verify the implemented shared headers, action slots and Home/Editor frame across all remaining interactive states.
- Verify aligned selectors and filters during loading, result, warning and error transitions; fix any remaining clipping.
- Validate implemented list widths, reading columns and panel spacing, including mob-image toggles.
- Keep workflow-specific controls in context: chat composer, editor confirmation footer and map-canvas tools. Uniform appearance does not mean placing every action in the page header.
- Validate German/English and both appearances at 1080×700, 1280×800, 1440×900 and wider layouts, using synthetic empty/populated/long-text/error states. Track title, action, selector, divider and result-area anchors.


## Skills follow-up (after 1.7.18)

- Support portable skill folders with referenced resources and scripts; current imports handle Markdown instructions and Companion JSON packages.
- Allow selecting multiple skills for one agent handoff and explicit skill selection in Conversation.


This is a list of proposed improvements, not a release schedule. Items have no promised delivery date. Completed work is recorded in the Update Log.

PLANNED · PRIORITIZED VIDEO REVIEW
Review the remaining important official tutorials and practical survival/build guides before incidental travel footage. The catalog has 197 videos, with 197 authored contributions and 0 pending. Use conservative, sequential acquisition; pause on YouTube rate limits and reuse already available captions. Do not imply continuous viewing when only image samples were inspected. No scheduled or automatic downloader is configured.

HIGH PRIORITY · DISTRIBUTION
Developer ID signing and Apple notarization. Requires an appropriate Apple developer account and signing credentials. Current builds are ad-hoc signed.

HIGH PRIORITY · DEVICE VALIDATION
End-to-end restoration of a disposable world on a real Quest, with an independent backup and owner authorization. Expand coverage to Quest 3S and additional game versions.

HIGH PRIORITY · PLATFORM VALIDATION
Run the complete interface and transfer checks on an Intel Mac and the oldest supported macOS release. Both architectures currently compile, but compilation is not runtime validation.

PLANNED · TRANSFER EXPERIENCE
Show byte-level progress and estimated remaining time. Add cancellation at safe stages while preserving the current world and rollback protections.

PLANNED · STORAGE MANAGEMENT
Show required and available space before transfers. Add a guided review and cleanup of previous-world recovery copies on Quest, with explicit selection and confirmation.

PLANNED · LIBRARY
Backup notes, tags, sorting options and clearer names for library folders. Consider multi-world batch backup, duplicate reporting, object-store cleanup controls and a guided restore flow from external library ZIP archives.

PLANNED · DIAGNOSTICS
Provide a redacted diagnostic export with consistent language and actionable connection errors. Never include save contents or device identifiers without an explicit user choice.

UNDER CONSIDERATION
An update-check mechanism with an authenticated release source; wireless ADB pairing; additional community translations; broader automated GUI and accessibility checks.

CONTRIBUTING
The complete source is available from Help → Development & source. See COMMUNITY.md for build and test instructions. Keep the running-game guard, checksum verification, automatic pre-restore backup and rollback behavior intact when proposing changes.


COMPANION IDEAS

## Android and Quest Companion APK — remaining port and device validation
- An experimental snapshot-inspection app is implemented in the separate public project https://github.com/friedensbringer-peacemaker/RealmCraft-Companion-Android . It provides a native 2D panel, synthetic sample, ZIP import, persistent snapshots, maps, item inspection and an experimental read-only Shizuku import. Physical Quest/phone behavior and direct directory access still require device validation.
- Explore a shared Android implementation for phones and Meta Quest 3, with a resizable 2D panel on Quest for use alongside RealmCraft and a phone workflow that can eventually replace the Mac. The complete port remains under consideration, with no promised delivery date.
- The current SwiftUI/AppKit macOS app requires an Android port rather than an additional APK build target. Assess reusable data, resources and parsing logic, plus replacements for Apple-specific UI, rendering, speech and runtime dependencies.
- Continue feature-by-feature validation of the existing snapshot workflow and assess remaining desktop features separately. Live position/inventory synchronization still requires investigation.
- Test Quest window placement, controller/hand input focus, RealmCraft pause/resume behavior and memory/performance while both apps are open. Do not assume uninterrupted gameplay or simultaneous input.
- Investigate authorized ADB access for backup/restore: phone-to-Quest over USB or Wi-Fi, and a possible on-headset connection. Normal Android storage permissions, including all-files access, do not grant access to another app's Android/data directory. Verify setup, reconnect/reboot behavior and supported Horizon OS versions before promising direct save access.
- Keep snapshot browsing available during play, but stop RealmCraft before savegame transfers or edits. Preserve explicit world selection, restorable backups, checksum verification, file permissions and rollback protections; never edit active game files concurrently.
- Concrete import experiment: use an explicitly authorized on-device ADB client or an ADB-backed helper such as Shizuku to read a selected Tellurion world and stream it to the Companion, which writes its own snapshot into its app data directory (not into the APK installation directory). If needed, evaluate an explicit ZIP export/import through a user-selected shared location. Test helper availability, actual source access and restart requirements on Quest; Shizuku is a candidate, not verified Quest support. Reference: https://shizuku.rikka.app/introduction/
- Feasibility references: https://developers.meta.com/horizon/documentation/android-apps/horizon-os-apps/ ; https://developers.meta.com/horizon/resources/vrc-quest-input-4/ ; https://developer.android.com/training/data-storage/manage-all-files ; https://developers.meta.com/horizon/essentials/metavr-devices-and-apps/

Optional item icons: Kenney (49 IDs) and Pixel Perfection Legacy (686 IDs) opt-in downloads, license details and persistent pack/text selection implemented for inventory and chests. Expand coverage only with suitable licensed artwork and verified IDs; validate and extend the implemented build-guide icon mappings. See ITEM-ICONS.md. Original RealmCraft artwork still requires documented redistribution permission.

User-managed resource bookmarks, resource favorites and additional independent feature modules. Evaluate future features separately from the savegame transfer engine.

## Atlas navigation and position tracking — remaining work

- Plan routes with multiple ordered waypoints instead of only start A and destination B. Allow adding, moving, removing and reordering intermediate stops on the map; calculate each leg and the total distance/time, support transport changes between legs, and include all waypoints in the English turn-by-turn AI export. Identify an unreachable leg explicitly rather than implying that the entire route is traversable.
- Initial implementation in 1.7.22: candidate surface routes, English coordinate-based instructions, optional nearby POIs, mixed travel sections, AI-export handoff and local Qwen reference selection. Actual player position tracking and verified climbing/rail mechanics remain unimplemented.
- Further develop optional turn-by-turn navigation to a selected map point, sign or saved place. Show the route, next turn, remaining distance and estimated arrival time while travelling; consider optional spoken directions.
- Add a POS / current-position indicator with heading and optional map follow mode. Distinguish movement inside the Companion's 3D preview from the actual player's position in RealmCraft VR.
- Investigate a supported, read-only source for timely player position updates before promising in-game navigation. A savegame provides only the last saved position: show its timestamp and stale/unavailable status, and never present it as live tracking. Do not stop the running game or change save files to obtain navigation updates.
- Build traversable routes from verified chunk data, heights, clearance, water and connected rail networks, with separate walking, boat, minecart and llama suitability. The current straight-line terrain profile is not a navigable route. Account for gaps in map coverage, dimension changes and uncertain transport mechanics.
- Recalculate when leaving the route; allow pausing, cancelling and choosing another destination. Clearly label estimated travel times and unverified routes as Beta. Validate position accuracy, update delay, route safety and travel speeds before implementation is treated as reliable.

## Atlas preview
- Broaden block/format coverage using synthetic fixtures and separately authorized local validation; never publish private savegame fixtures.
- Map cache size and cleanup are present: the map menu shows the temporary render-cache size and offers a confirmed cleanup action that preserves generated maps and savegames. Future work may add a configurable size limit.
- Add native marker export. Map-generation cancellation, bounded renderer termination and safe finalization are implemented in the 1.7.39 candidate.
- One-click private Python/NumPy/Pillow installation is implemented. Consider a licensed fully offline bundled runtime for machines without download access.

## Chest explorer and places
- Add Ender inventory, other containers and detailed enchantment/durability decoding with verified fixtures.
- Improve grouping across building boundaries and link chest search results directly to atlas markers.
- Add place-name import/export between the embedded app and external browsers.
- Refine community German item terminology and verify new game versions.

## Saved biomes
- Verify future chunk versions and any separate vertical biome formats.
- Add optional biome color overlays and biome-based filtering.
- Add configurable storage-location grouping radius.

## Statistics (Beta) — remaining work
- Investigation update (2026-09-06): verified a persisted WorldData.ChangedBlocksCount in world_data v9. Native TryBuild and FinishDig both increment the same world counter. Candidate label: “Build/dig actions (Beta)”; never label it as mined blocks alone or split it by material/player. Controlled in-game coverage validation remains pending. No separate saved lifetime mining, resource-by-type, kill-by-type or player-distance counter was found in the examined metadata/serialization paths.
- The first read-only backup statistics view shipped in 1.7.8 with the verified combined build/dig counter. Expand it only with validated additional metrics. Clearly label experimental results as “Estimate / Beta” (DE: “Schätzung / Beta”), with a per-metric method, source backups, coverage period and limitations. Distinguish measured snapshot values, observed changes and estimates; show unavailable values as unavailable, never as zero.
- Chest-stock aggregation shipped in 1.7.20: current item quantities in all scanned chests versus presumed player chests, bilingual search, thematic filters/grouping, sorting and explicit partial-scan coverage. Presumed ownership reuses manual marks and sign-based assignments; it is not confirmed ownership. Personal inventory and armor aggregation remain a possible extension. These are current holdings, not lifetime resources gathered.
- Investigate whether game serialization contains persistent counters for blocks mined, resources collected by type, animals/mobs killed by type, distance travelled, deaths, crafting or playtime. No such historical counters have been established by the existing documented player reader. Confirm field meanings with controlled before/after saves before displaying them; retain unknown fields as unknown.
- Compare compatible, chronologically ordered backups of the same world and dimension to report net resource changes and observed block changes in successfully decoded overlapping regions. Missing, newly generated or unreadable chunks are not mined blocks. Block removal can also result from explosions, environmental changes or editing; item gains can result from transfers, crafting, trading or patches. Do not present either difference as a lifetime activity counter, even under a Beta label.
- Explore sampled position history: show straight-line displacement between recorded positions, explicitly separate from actual distance walked. Exclude dimension transitions and known teleports, respawns, restores or editor changes; unknown discontinuities remain unresolved. A route-distance lower-bound interpretation requires movement-only evidence, and sparse saves cannot reconstruct the travelled route.
- Do not infer animal kills from meat, leather, XP or disappearing entities. Consumption, breeding, despawning, loot sources and save coverage make these ambiguous. Keep kill totals unavailable unless verified counters or attributable events are found.
- Further candidates: saved chunk coverage by dimension, current level/XP, resource distribution, owned storage totals and inventory trends since the first comparable backup. Saved/generated area is not necessarily explored area, and current XP is not lifetime earned XP. Avoid inferring lifetime block mining from tool wear or comparing terrain against an unverified seed generator.
- Track provenance for duplicate imports, restored/forked worlds and Companion edits so repeated backups or patched values do not inflate trends. Validate each metric against controlled fixtures, unsupported layouts, incomplete scans and repeated imports before release. Investigate feasibility before committing to historical totals; no Quest/savegame writes are needed for this feature.

## Video knowledge library
- Continue reviewing the expanded multi-channel catalog. Preserve transcript provenance, creator corrections, known game-version compatibility and separate visual-only/pending labels.
- Reconstruct exact block plans only where video evidence establishes geometry and quantities; validate on Quest separately.
- Consider synchronized full-video translations and additional languages. Current speech reads edited DE/EN summaries; original/available dubbed audio remains on YouTube.
- Extend material comparison only after quantities and item IDs are verified; no inventory claims from video examples.

PLANNED · BUILD GUIDE VALIDATION
Validate door and fence-gate response to pressure plates, buttons and levers in RealmCraft VR, including crossing time, release behavior and animal activation. Record game version and platform; current layouts remain AI-generated and untested.

PLANNED · RAILWAY VALIDATION
Test powered-rail launch and braking, detector output, curve switching and terminal arrival positions in RealmCraft VR before connecting automated routes.

PLANNED · HQ DEFENSE VALIDATION
Test mob pathfinding, pit containment and iron-trapdoor activation in RealmCraft VR. Record enemy type, version and actual escape behavior before presenting a defense as reliable.

PLANNED · BUILD VALIDATION
Validate honey smoke shielding, chicken egg pickup, fruit piston harvest, dropper transfer and sapling clearance in RealmCraft VR. Automatic interlocks, item-lift clocks and perpetual mature-tree growth remain unsupported claims until verified.

- Validate tree-village plant placement, fence connections and sapling clearance in RealmCraft VR.

- Test hands-free build-guide pacing with external voice agents in a headset session.


MANUAL TRANSFER VALIDATION
- Test MTP and headset-side file access on explicitly documented Quest/OS/app combinations using disposable worlds. Until then, keep these alternatives unverified and preserve the ADB recommendation.

## Savegame status follow-ups

- Add provider-backed upload confirmation and supported RealmCraft/Meta online-save discovery if an official integration becomes available. Current status only inspects local cloud-folder archives.
- Offer explicit deep archive-content verification and guided full-library recovery from the status panel.

PLANNED · UNDERWATER AND TRANSPORT VALIDATION
Test glass sealing and solid-fill drainage, module junctions and ladder access in RealmCraft VR. Measure boat and walkway trip times; obtain VR evidence before adding automatic passenger elevators, bubble columns or ice-road acceleration.

PLANNED · MODULAR BUILD PLAYTESTS
Validate the ten expansion guides in RealmCraft VR: water displacement, curved room shell, spiral and switchback traversal, plant persistence and irrigation, boat docking, landmark visibility and station boarding. Keep automatic elevators, speed bonuses and untested railway automation unverified.

PLANNED · PRACTICAL MODULE PLAYTESTS
Validate the sixteen practical modules in RealmCraft VR, including curved/rising tunnel sealing, storage access, bed placement, descending stairs, animal containment and visibility from the HQ observation corridor. Keep untested mechanics explicitly unverified.

PLANNED · ARCHITECTURE AND INTERIOR PLAYTESTS
Test oak stair/slab placement, lantern attachment, carpet clearance, furnishing access and interior plant persistence in RealmCraft VR. Decorative seating, mirrors and sanitary objects remain explicitly nonfunctional designs.
