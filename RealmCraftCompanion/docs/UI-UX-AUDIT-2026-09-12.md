# Companion UI/UX and integration audit · 2026-09-12

## Tectonicus map space and mirroring · 1.7.52 (74) · 2026-09-13

Tectonicus-specific follow-up: the large always-visible form left little space for the actual map, and camera angle alone did not reproduce the requested mirrored Atlas view. The implementation keeps source selection, primary action, Help, consent and progress in view. Render settings and source/result details use accessible popovers following the Maps information pattern. Saved/not-live and next-render state remain visible. Actual rendered perspective stays separate from pending settings.

The viewer mirrors both tiles and projected world positions, while controls and marker glyphs remain upright. World-coordinate links retain their meaning. Existing map files can be served with this enhancement without tile rewrites. The mirror switch restores the original display. Synthetic projection, tile-boundary, idempotence and worker tests cover the implementation; native/browser visual checks are recorded separately in the local acceptance artifacts. Full VoiceOver and physical trackpad acceptance remain open.


## List-scoped search · 1.7.50 (72) · 2026-09-13

UX-012 follow-up: place local search at the top of its result pane, following
Savegames, with 16-point insets and no fixed toolbar search width. Applied to
Builds, Videos, Recipes, Mobs, Chests, Help, Assistant instructions and the comparison
browser. Single-column Links/Checklist search remains directly above its content.
Search remains visible when the result list is empty; original query/filter and
selection bindings are reused. Global Quick find is intentionally app-scoped;
map search already belongs to its local result area. Code-level
placement and build checks do not close native keyboard/VoiceOver acceptance.

## Map and layer controls · 1.7.49 (71) · 2026-09-13

The Maps header now aligns a compact Area selector to Generate map and places
Backup beside it when space permits. Source metadata and rendering caveats are
available through an explicitly labeled information button; saved/not-live remains
visible. Map technical identity is disclosed separately from its readable title.
Ore Y is prominent, editable and accompanied by equally sized directional actions.
A pinned section header and enlarged-3D controls keep navigation close to rendering.
Synthetic checks cover 14 boundary/scroll-accumulation cases and 16 DE/EN,
Classic/Block, repeated-resize component layouts, including actual native popup
edges. Five map-title tests cover technical-name fallback and literal text handling.
Offscreen component renders are limited for native controls; physical trackpad,
loaded-screen pinning, full keyboard and VoiceOver acceptance remain open.

## Screen density implementation · 1.7.47 (69) · 2026-09-13

Cross-screen action alignment supersedes the full-row backup rule below: shared
source selectors end at the actual trailing edge of the header action group,
excluding Help and overflow. Maps area and Tectonicus options use the same edge.
Headers without actions retain the available content width; compact layouts clamp
to their available width. The scope follows page changes rather than persisting
the previous screen's geometry. Ore section tabs and compact Metro navigation
use equal-width segments, retaining their existing selection/draft bindings.
Synthetic production-component checks pass 64 action-layout cases across DE/EN,
Classic/Block, zero/one/two/three actions and repeated wide/narrow resizing with
a sidebar offset. They assert the visible native field edges, segment group edge
and action dimensions; the overflow menu is deliberately excluded. The 32 Player
cases also pass with the shared scope active. Existing form/header regressions
remain separate component evidence, not complete application screen acceptance.
Full native keyboard, VoiceOver and loaded-screen acceptance remains open.

Player refinement: source controls use the actual Read player/Refresh action
bounds as their alignment reference. Device and Savegame occupy equal 90-point
halves of its 180-point width; the backup/world selector ends at the action's
right edge, excluding Help and overflow. This overrides the full-row Player
selector below. The reference follows header
wrapping; narrow source labels stack above the controls. Existing source bindings,
busy/scanning disabling and source-change invalidation remain unchanged.
The isolated production-component test passes 32 cases: DE/EN, Classic/Block,
backup/device, and live resizing of the same hierarchy through 900, 400, 600 and
1300 points. It asserts both source/action edges and the selector's right edge.
This is component geometry evidence, not a complete live Player workflow test.

Header-grid follow-up (UX-010/012): labeled header actions, including Help, share
180 × 32 point dimensions regardless of emphasis or enabled state; explicit
symbol-only controls retain their square dimensions. The existing narrow header
fallback preserves access to actions. Backup selectors fill the available content
row instead of their title's intrinsic width or a 440-point cap. Area options,
Metro counts and auxiliary controls no longer compete with that row. Applies to
Metro, Maps, Player, Ore, Portals, Chests, Conversation, Statistics, Tectonicus,
Editor and AI export. All 20 shared-header call sites were inspected. Selection,
save/draft guards and button actions are unchanged. Component DE/EN wide/narrow
render checks supplement source evidence; live keyboard/popup acceptance is open.

The follow-up form example exposes native labels of different intrinsic widths.
A shared 140-point label column now aligns both control edges for Metro connection,
station, journey and assistant selectors, Player source/world, Maps area,
Tectonicus options, Ore reference/biome/before-backup and video filters. Narrow
panes consistently stack labels above full-width controls. Long labels wrap inside
the fixed column; selected values and native picker bindings are retained.
Menu selections use an explicitly sized native popup because an outer SwiftUI
frame alone leaves the visible menu at its intrinsic width. Duplicate titles keep
distinct identities; rejected guarded changes restore the actual selection;
programmatic synchronization never invokes the selection setter. Segmented
controls retain their existing presentation and guarded bindings.

Verification for this follow-up: 12 production-component form renders cover
DE/EN, Classic/Block and widths of 300, 600 and 1000 points. Each asserts six
matching left/right field edges and two 180 × 32 action frames. Another 16
source/header renders cover wide/narrow layouts and collapsed/expanded detail
sections. Native popup regressions cover duplicate titles, optional selection,
rejected and disabled changes, renamed/reordered options and empty lists.
Draft-transition (13 checks), Metro model and all-20-destination navigation
regressions pass, as do full Swift type checking and 17 translation-catalog tests.
These are isolated component/model checks, not a live full-screen acceptance tour.

Scope: inspect the 20 navigation destinations and improve the supplied dense
screens. Evidence consists of user-operated screenshots plus source review of
entry layouts, shared controls and selected detail panes. No claim of complete
native interaction, scrolling or accessibility coverage is made. The previously
repeated native helper failure is not retried in this pass.

| Destination | Entry/action and implementation assessment | Remaining acceptance |
| --- | --- | --- |
| Home | Task cards and recent activity already lead; shared header retained | All task transitions and empty/busy states |
| Worlds & backups | Prior responsive preview/facts package retained | Complete detail scrolling and confirmations |
| Player | Read player; source rows aligned, idle spacer removed | Loaded armor/inventory and refresh error |
| Maps | Generate map; top-aligned source/area; optional notifications expandable | Loaded viewer, blank-map recovery, consent |
| Ore frequency | Measure region first; random sampling separate; trial sections expandable | All tabs, repeated zoom, drafts, before/after results |
| Portal pairs | Reload/record; bounded reading width and line spacing | Loaded pairs, recorded versus assumed links |
| Nether Metro | Add station; aligned tabs, bounded form, equal XYZ fields | Compact/wide editors, draft transitions and route results |
| Chests | Read/search; source/info control top alignment; filter workflow retained | Loaded rows/icons, empty filters, sorting |
| Conversation | Source aligned with content; model/answer caveats retained | Composer, speech/errors and handoffs |
| Videos & tips | Compact edited-title rows; summary first; metadata/audio/export expandable | Long titles, notes/transcripts and stop/export feedback |
| Build guides | Wider browser, smaller thumbnails, grouped actions and smaller detail title | All steps, 2D/3D and material handoff |
| Crafting / Recipes | Catalog counts expandable; comparison caveat and active filters visible | Long ingredient alternatives, history and material plan |
| Mobs & Animals | Short rows; research detail expandable; AI/platform caveats visible | Evidence filters and full detail sources |
| Links & Knowledge | Existing segmented topics and comparison disclosures retained | All comparison/checklist/links panes |
| Help | Wider wrapping topic labels, calmer headings and paragraph spacing | All topics, related links and keyboard navigation |
| Statistics | Existing unknown-not-zero disclosure retained; shared source alignment | Read counter, chest/chunk results and errors |
| Tectonicus | Source on own row above rendering options; download consent retained | Setup/progress/error and direction controls |
| Editor | Shared source alignment only; risk warning and review workflow retained | Synthetic preview and draft review; no real writes |
| AI export | Reading width bounded; consent/content choices retained | Preview, selection, save/share cancellation |
| Assistant instructions | Existing bounded detail/history retained; shared header | Draft editor, import/export and personal context |

Dialog families remain a separate live matrix: settings/device setup; file
open/save/export panels; destructive backup/editor review; draft guards; large
3D/skin/build coach; conversation/microphone configuration; help/search/popovers.
No new device action, download, microphone permission, backup mutation or sharing
was initiated. Expanding sections is presentation state only. Long source strings,
unknown values and warning semantics remain available; optional details never
silently become verified facts. UX-010/012 and the Help readability part of UX-023
are partial implementations, not closed all-screen findings.

## Library alignment implementation · 1.7.47 (69) · 2026-09-13

The user-provided Worlds & backups screenshot shows competing title weights,
widely dispersed facts, an isolated Help row and inconsistent panel/icon insets.
This bounded presentation change follows UX-010/012 without declaring those
cross-application findings closed. Common headers default to their compact
adaptive layout. The backup list uses a 260-point pane and shared 20-point insets;
detail content keeps its 28-point grid. A 20-point semibold detail heading remains
subordinate to the 22-point page title. Preview and facts share an adaptive row,
stack below the required width, and omit the image column when no preview exists.
Labels reserve a 20-point icon column with an 8-point gap; square symbol buttons
use the shared 32-point action height. An empty idle status footer is omitted.

Evidence scope: source inspection and synthetic DE/EN, Classic/Block, wide/narrow
component renders, including long titles and absent previews. The rendering test
uses no application Model, Library or device. It is not a full-window capture or
a live control/scroll/accessibility test. All original metadata, backup operations,
destructive confirmations and saved data remain intact. Follow-up acceptance:
inspect all library scroll content, header fallbacks in every destination and
keyboard/VoiceOver behavior in the separate Demo environment. Do not exercise
delete, restore or device writes as part of that visual check.

## Ore first implementation package · 1.7.47 (69) · 2026-09-13

The assisted walkthrough exposed a reproducible camera limit: the shared camera
started at 1.15 and clamped at 1.0, so the first 0.15 zoom step reached its limit.
Ore now opts into a 0.15–2.8 relative range and uses box-corner viewport fitting;
guide previews retain their defaults. Fit to view preserves orientation, while
Reset view restores the initial camera. Close-up presets retain their exact zoom.
The Ore header opts into compact layout; Help, game-file time and not-live status
remain visible. Result/source details stay available on expansion. Main content
uses available width and layer controls share the content's leading alignment.

Evidence: pure camera regressions, synthetic native SceneKit render/picking and
DE/EN component snapshots. Native scene rendering requires access to the macOS
graphics service; the sandbox-only process failed before producing evidence.
Component caching does not capture the composited SceneKit surface; dedicated
SceneKit snapshots provide the image evidence instead. No actual Library or Quest
data is read or written by these tests. Repeated live button clicks, window changes
and all four Ore tabs still require acceptance in the separate Demo test app.
Mining-trial redesign and a treemap are not implemented by this package.

## Approved Demo native stability gate · 1.7.47 (69)

The user approved opening the separately signed audit candidate. Launch through
the exact audit bundle path succeeded; the launcher path-check receipt refreshed
at that launch. The UI identified RealmCraft Audit and version 1.7.47, showed one
Demo snapshot (12.5 MB), no prior device-backup record, and no map/export history.
This confirms the bounded startup/profile scenario, not an OS sandbox or a complete
trace of every possible storage operation. The original app was left open.

**Observed in English / Block, 1123 × 768 screenshot:**

- Home: initial view, collapsed content end, expanded “What each section does”,
  all explanation groups and final footer/Demo row. Separate screenshot and AX
  reads succeeded. The Home → step-by-step Help button worked. Other task cards,
  render/export/device controls and the full global sidebar were not exercised.
- Help: initial screenshot succeeded before an explicit AX request. The first
  diff was incomplete; one full non-diff tree read succeeded. Scrolled the Welcome
  article through its final related-topic buttons and the topic list through its
  final Backlog row. UX-023's truncated topic titles and specialist-group mismatch
  remain visible. This does not cover all 48 articles or all Help controls.
- Ore frequency: the sidebar click returned successfully. The **next screenshot
  call** failed with the native pipe closed; no explicit post-navigation AX request
  was made and no Ore viewport was obtained. This narrows the externally observed
  call sequence, but does not establish whether internal click/screenshot work,
  background tree processing or another helper operation triggered the assertion.

The new helper report repeats exactly the previous version/build, Swift assertion,
`Array.remove(at:)`, `EXC_BREAKPOINT` / `SIGTRAP` and helper offset `6572452`.
There are now **10 matching same-day reports**, one added by this gate. A read-only
process check found both the original Companion and audit Companion still running
with their respective original launch times; the helper was absent from that
snapshot. Process continuity is not full application responsiveness acceptance.

**Result:** native launch/startup gate passed; helper stability gate **blocked**.
Home and Help remain partial screen coverage, Ore blocked. The local manifest and
coverage record were updated accordingly. No retries, reset, restart, installation,
device action, deletion, publication or application-code change followed the failure.
Only ordinary audit view state and the test records changed. Screenshots remain
private task evidence, not published project assets.

The UI/UX audit skill's bounded-retry rule stops further automated UI work here.
For a full investigation, agree on either a separately authorized tool-recovery
trial or an assisted screenshot walkthrough; retain source/AX/visual evidence
boundaries and do not mark the existing UI findings fixed.

## Audit preparation implemented · 1.7.47 (69)

The requested follow-up implements the **testing infrastructure**, not the proposed
UI redesigns or a fix inside the Computer Use helper. See the repeatable
[preparation and acceptance runbook](UI-UX-AUDIT-RUNBOOK.md).

- `Tools/prepare_ui_audit.py` creates a new audit-only app/profile, refuses existing
  destinations and unsafe ZIPs, imports only the explicitly selected checksum-verified
  Demo and runs the copied application's integrity check. No GUI, installation,
  device operation, global preference change or personal-library copy is performed.
- `Tools/AuditLauncher.swift` validates the process-scoped Foundation paths before
  starting the target, separates preferences by a unique bundle identifier and sets
  the ordinary ADB path to a non-device executable. This is data-path isolation,
  **not an OS security sandbox**. Launch Services and live profile isolation still
  require the controlled native gate; optional assets/history are deliberately absent.
- The prepared candidate retains version/build 1.7.47 (69). Its executable content
  compares equal after signature removal on disposable copies. A separate bundle
  identifier requires changed signatures: do not describe the audit app as a
  byte-identical signed production bundle. The original app still has SHA-256
  `4a78d31f28bc159cef082a685a920f2a5358304f6c507f352f89f1f2a6e06e1d`
  and passes strict/deep verification. No application source file was changed.
- The local prepared run is `realmcraft-ui-audit-1747-demo-20260912-d` under the
  temporary directory. Its manifest, coverage record and headless path-check receipt
  are retained there. It contains exactly one Demo snapshot, 1,025 files, whose CLI
  integrity verification passed. The approved input archive hash was
  `6b2cfdf2bc678b70f61d223d04ced557e0d9565a7d3ef6fe66112f49ce5cfae1`.
  Earlier partial packaging attempts remain retained; they are not launch candidates.
- The generated coverage record contains all 20 destinations and six cross-feature
  journeys. End-of-pane observations, control evidence, state exclusions, languages,
  themes, window sizes, keyboard and VoiceOver remain explicit. Validation prevents
  unsupported screen-pass claims; it does not infer human observations or overall
  acceptance from an internally consistent open record.
- `Tools/audit_helper_diagnostics.py` produces an allowlisted aggregate without raw
  logs or personal identifiers. Applied to the nine selected existing reports, it
  reproduced one identical assertion/array-removal signature and helper offset.
  No external issue or report was submitted.

Verification: **15 synthetic Python tests passed**; real-package preparation,
signature checks, unsigned-content equality, Demo import/integrity and a successful
headless path preflight passed. Two negative preflights (missing and wrong profile
environment) refused to launch with exit 78. The coverage validator accepted the
all-open record without presenting it as feature acceptance.

**Next gate:** obtain approval to open this separately signed Demo environment,
then test Home → Help → one previously failing destination with separated UI calls.
The current Companion remains open. No Codex restart, permission change or helper
retry loop is authorized by preparation. The helper defect and UX-018–023 remain
open; the full-project analysis follows only after recording the native gate result
or agreeing on an assisted walkthrough fallback.

## UI transport diagnosis and completion plan · 1.7.47 (69)

**Diagnosis requested after the repeated walkthrough failures. No application fix or restart was authorized or performed.** The immediate failure is now confirmed as a crash of the Computer Use helper, rather than merely an unexplained closed pipe. This supplements, rather than erases, the earlier uncertainty notes.

### Confirmed evidence

- Nine available macOS DiagnosticReports for `SkyComputerUseService` on 2026-09-12 share the same signature; eight are from the evening audit period (21:28–21:52), one predates it. Every report identifies helper version `26.902.1000968` / build `1000968`, on macOS 26.7 (25G229), and `EXC_BREAKPOINT` / `SIGTRAP`.
- In all nine reports, the faulting stack begins with Swift `_assertionFailure`, then `Array.remove(at:)`, followed by the same helper image offset `6572452`. The remaining stack contains repeated helper and `Sequence.compactMap` frames. The latest helper launched less than one second before its crash: this is not explained solely by an old long-lived connection.
- The inspected Companion process was still running with its original 21:26:11 launch time, preceding every evening helper crash. No Companion/RealmCraftLibrary crash report dated 2026-09-12 was found in the inspected DiagnosticReports inventory. This establishes process continuity, not a full responsiveness or feature-correctness test.
- The actual Companion executable still matches the previously recorded SHA-256 `4a78d31f28bc159cef082a685a920f2a5358304f6c507f352f89f1f2a6e06e1d`; strict/deep bundle-signature verification passed again.
- Matching fatal/pipe strings were not found in the inspected same-day Codex app logs. The crash reports are the stronger evidence. Local symbolication did not resolve the private helper frames to source functions.

**Interpretation:** the closed pipe is explained by a fatal assertion in the helper's internal collection processing. The observation pattern is consistent with an issue processing native UI/accessibility state, but the exact element, invalid index and triggering algorithm are not established. A native UI tree can trigger a helper defect without the target app crashing. Do not attribute this to a specific SwiftUI view, excessive recipe count, bad save data, missing permissions, memory pressure or concurrent user input without a smaller reproduction. The prior screenshot-only failure happened after the helper had already failed; it does not independently establish a screenshot-rendering bug.

The graph query located CompanionView/StatisticsView relationships but was stale and has no helper internals. Targeted frozen-source inspection confirms that navigation instantiates the feature views and that the top-level statistics read requires its explicit button; it does not identify the helper assertion's origin. No graph regeneration or semantic extraction was run (additional extraction-token cost: none). No private crash reports, process identifiers, device metadata or full logs were copied into this project or sent anywhere.

### Concrete completion sequence

1. **Short, controlled tool-stability gate.** After saving work and with user approval for any disruptive restart/update, check the installed Computer Use/Codex version and try one clean session. Separate navigation, screenshot and accessibility reads into distinct calls, starting with Home/Help, then one previously failing destination. Capture whether the helper dies before or during state retrieval. If the same signature recurs, stop retries; a full Codex restart is a diagnostic trial, not a promised fix. Do not reset permissions, delete caches or reinstall the Companion merely to try something.
2. **Isolate the test data.** Use a separate Demo-only profile and bounded synthetic fixtures, with the original library untouched. Record the exact binary/source baseline. Prepare empty, loaded, no-result and error states without publishing personal profile screenshots. Do not silently include newer working-source changes in this 1.7.47 acceptance run.
3. **Finish the untouched native screens first.** Ore, Crafting/material plan, Mobs, Links & Knowledge, Statistics, Tectonicus, Editor, AI export and Assistant instructions still lack live screen coverage; the library lacks full visual coverage. Then finish missing panes, expanded sections and safe controls on previously visited screens. If the tool remains unstable, use a user-operated walkthrough with overlapping screenshots through every pane end and before/after each tested action. Record that as assisted visual evidence, not automated or keyboard/VoiceOver acceptance. Isolated component renders may supplement but never replace end-to-end checks.
4. **Exercise complete user tasks.** Search → exact result → variant/quantity → reviewed material plan; guide → next/back → 2D/3D → material handoff; Demo read → map/ore result → background completion notice; chest filters → found/no-result → recovery. Save/draft tests use disposable fixtures only after approval. Do not delete data. Device writes, downloads, microphone/model calls, external sharing and unexpected actions require a separate decision.
5. **Consistency and acceptance.** Complete DE/EN, both themes, normal/minimum window, nested scrolling, keyboard focus/shortcuts and actual VoiceOver checks. For every route record V/AX/source/blocked separately and keep a checklist of tested controls and final scroll positions. Review all help chapters for matching navigation and task-first wording. Finish with a prioritized fix package and a small observed newcomer task test; no invented completion rates.

For external escalation, prepare a minimal reproduction and the sanitized signature above, not the original full logs or session. Official [troubleshooting guidance](https://learn.chatgpt.com/docs/reference/troubleshooting) provides feedback/log routes and explicitly requires reviewing logs for sensitive content before sharing. The [Computer Use documentation](https://learn.chatgpt.com/docs/computer-use) distinguishes system permissions from app access; the current evidence does not justify changing either. No feedback or issue was submitted in this diagnosis.

## Community-first walkthrough · 1.7.47 (69) · 2026-09-12

### Scope and evidence boundary

Opened the latest verified local candidate, **1.7.47 (69)**, and confirmed 1.7.47 in the live interface. Its frozen Sources are the reference for this review; newer community-translation tooling in the working directory is not part of that binary. The previous package-verification record below identifies the executable hash. No rebuild, installation, feature implementation or publication was requested or performed in this audit.

Live evidence: English, Block theme, approximately 1123 × 768 captured window. Inspected the library through its accessibility tree, selected the approved Demo backup, visually inspected Home, Player before/after reading that Demo, and Maps before/after Whole world. Home's explanation lists the correct groups in the accessibility tree. The active profile contains other backups: this was **not an isolated demo profile**, and no screenshots from it are approved for public reuse. No screenshots were exported into the repository. Normal Maps opening refreshed cached viewer assets through `MapController.restoreLast`; no savegame content was edited.

On switching to Ore frequency the native UI transport returned “Sky Computer Use native pipe closed before response”. Reconnection by identifier was ambiguous; explicit-path reconnection and a session reset failed with the same transport error. This is not evidence that Companion itself crashed. The user was asked to switch back to Home manually. Consequently the remaining live walkthrough, both-language/theme coverage, dialogs, VoiceOver and keyboard task completion remain **open**, not passed. Source inspection continues to cover all 20 destinations and the principal dialog families. Prior component renders/tests below are historical evidence, not new full-app acceptance.

Graphify located the shell/navigation neighborhood, but its line locations predate the metadata extraction. Current frozen source overrides the graph. No graph rebuild or semantic extraction was run; additional extraction-token cost is not applicable.

A reusable `realmcraft-ui-ux-audit` skill was created and structurally validated. It distinguishes live, accessibility, source, isolated-test and blocked evidence and prioritizes first useful results without removing technical controls. This is a repeatable procedure, not a scheduled monitor or a claim of complete usability certification.

### Resumed live walkthrough and stricter interaction coverage

After the user returned to Home, UI access recovered. The same 1.7.47 candidate was inspected in English/Block. The user explicitly required scrolling through entire content areas and exercising loading, switching and detail controls, while never deleting data and asking before unusual or potentially problematic actions. This is now an acceptance rule for subsequent walkthroughs: an initial viewport is not a completed screen; record each pane's end, expanded sections, exercised actions and remaining exceptions. Do not indiscriminately activate Save, Delete, transfer, download, share, microphone or model controls.

Additional evidence:

| Area | Actually observed / exercised | Remaining limits |
| --- | --- | --- |
| Portal pairs | Initial empty Demo view; detected-portals heading and text-only Maps directions | Reload and nonempty record/planning flows not exercised. The empty heading lacks a clear zero-result explanation/action. |
| Nether Metro | Initial empty network and new-station form; disabled Plan journey, View/Tool selectors and sequence hint | Mode switching, all scroll content and populated network/draft flows remain open. No station was saved. |
| Chests | Read chests completed; selected the single player storage location; inspected the selected chest's entire contents through the final occupied slot using the scrollbar; switched Player → All (30 locations); searched for a deliberately unmatched term; cleared that term and restored Player | Location-list scrolling was partial: although a scrollbar setter temporarily reported 1, a fresh state settled around 0.787 and the final locations were not visually reached. Do not count this list as fully inspected. Filters were inspected through AX; their overlay did not appear in the returned screenshot. Other sort/material/dimension controls and Manage remain open. |
| Conversation | Empty welcome screen, model/source/language status; opened settings, scrolled to its final warning, closed unchanged | No question sent, connection check, microphone, automatic speech or model activation. Independent answer/interface language is explicitly explained in settings; differing languages alone are not a defect. |
| Videos & tips | Selected apiary article inspected in overlapping scroll positions from title through all six steps and the final expanded Evidence & source links | This covers one complete article, not the 209-entry catalog or every content variant. Search/filter/sort, narration, export and external video actions remain open. The first practical steps follow large media, metadata, export and audio panels, confirming UX-013 visually. |
| Build guides | Light-switch guide; Next moved step 1 → 2; switched 3D → 2D; inspected the two grids and default detail-page end; expanded Function, testing & troubleshooting and scrolled through success/failure guidance and the complete test-log panel; expanded Evidence & sources (AX text available) | Final expanded source footer, other collapsed sections, the full 95-build list, coach/resume, block details and material-plan handoff remain open. No materials, test notes or test-result flags were changed. The previously selected 3D preview was not restored before access failed. |

Native scroll commands returned `noWindowsAvailable` even while screenshots and AX remained available. Setting exposed scrollbar values worked in several panes, but settled values and visible content must be rechecked; a requested numeric endpoint alone is not proof. Later, during the build-source/footer inspection and attempted transition to Crafting, the native pipe closed again; one read-only retry failed identically. This is an automation-transport blocker, not proof of an application crash or a recipe-screen failure. Crafting was not visually reached in this resumed pass.

A second manual Home recovery successfully returned the Home accessibility tree. The next direct Crafting selection plus state capture immediately closed the native pipe. A single safe attempt to return to Home was rejected because the automation session was no longer active. The exact point of failure (navigation versus state capture) is not established. Further automated Crafting retries were suspended; the user was asked to open Help manually to continue independent screens. No additional screen was accepted in this recovery attempt, and no restart or application modification was attempted.

### Help recovery: completed observations and next blocker

Opening Help manually recovered access to the same 1.7.47 candidate. In English/Block, the Crafting help article and its related Material plan article were each inspected in overlapping scroll positions through their final Related topics buttons. The material-plan related-topic button opened the correct article at its beginning; Previous topic returned to Crafting. A deliberately unmatched help search showed “No matching topics”, a shorter-term/other-language suggestion and a working Show all topics action, which restored all 48 topics and the prior article. The help topic list was inspected through its final Backlog entry; a settled accessibility state confirmed scrollbar value 1. This is coverage of the full topic list and two article bodies, not all 48 articles or the standalone Help window.

Exposed scrollbar setters again became invalid despite refreshing their IDs. The documented native Scroll Down secondary action on the scroll area succeeded and reached the list end. Prefer that supported action if this specific scrollbar issue recurs; still verify the visible endpoint rather than trusting an action response. The application sidebar was also scrolled to expose More tools. Selecting Statistics and requesting its state then closed the native pipe; one screenshot-only fallback returned the same error. Statistics was not captured or accepted. The repeated transport failure now affects more than the Crafting entry; no application crash or common application root cause is established. Further manual Home/retry loops were stopped. The full audit remains blocked, with no risky test, data deletion, app restart or application-code change performed.

**UX-023 · P2 · Help orientation still differs from the new navigation.** Live Help places Tectonicus, Statistics and Editor under Your world, and AI export plus Assistant instructions under AI tools, while the actual app sidebar places all five under More tools. At the inspected window size, many topic titles are truncated (for example the route, portal, Metro and material-plan topics). The material-plan article begins with several long paragraphs rather than a short first-use sequence. The complete Crafting article does not yet explain the newly introduced type-first family browsing. These are concrete refinements of UX-010/013/014, not evidence that help search or links are broken.

Follow-up: derive feature-topic grouping from the existing navigation metadata while preserving all article IDs, support/about chapters and task-specific subtopics; make topic labels readable through wrapping or an adjustable column; add a short Target → Quantity → Review → Save starter before the existing material-plan reference; explain type family → material variant in Crafting. Preserve scope, unverified comparison warnings, explicit-save behavior and all technical details. Acceptance: all five specialist topics are findable under the matching More tools group; long DE/EN titles remain distinguishable at minimum supported width; old topic IDs/related links/search still work; the two audited articles provide a concise first-use path without removing limitations. Native article editing or help regeneration was not performed by this audit.

No data was deleted, no savegame content changed, and no device, microphone, download, model request or publication was triggered. Loading may update normal indexes/caches; view/step selection may retain normal UI state. The full screen/control matrix is still incomplete. The evidence letters below describe reached states, not all-button or all-scroll acceptance.

**UX-022 · P2 · Chest contents need stable row alignment and more useful density.** Live Demo contents showed roughly four occupied slots in the initial detail viewport. Repeated snowball stacks consumed most of the long scroll. At the final slots, entries without an image (Raw Porkchop, Raw Rabbit, Raw Mutton) placed their names farther left than icon-bearing entries. Preserve every original slot, quantity and raw ID, but offer a compact slot view or a clearly separate grouped stock summary and reserve a consistent icon column even without artwork. Acceptance: the final slot remains reachable, icon-present/absent labels align, quantities and slot identities remain exact, and compact/grouped presentation never silently combines the underlying stored records. This is a presentation finding, not a claim that those item icons are absent from every asset pack.

### Main conclusion (unchanged priorities)

The most useful next release is a **comprehension and reliability pass**, not another feature collection. Existing search, exact catalog routing, material planning, edited video notes and the build coach already support an answer-first product. Improve what appears first, how a user recognizes a reliable result, and what they can do next. Do not make every feature a wizard: keep direct expert access while offering a short default path.

The four Home task cards, permanent search and shared section groups are improvements already present. Build guides already put the coach and material-plan handoff early and collapse deeper plans/audio-export settings. Chest filters already have a popover and an active summary. These must not be reintroduced as supposedly missing features. Their remaining acceptance and refinements are listed below.

### Current coverage and concrete opportunities

Evidence: **V** = live visual/action observation; **AX** = live accessibility tree; **S** = source inspection; **O** = remaining live acceptance open. Every row is indexed; this does not mean every row was clicked successfully. This matrix records the initial pass; the resumed walkthroughs above supersede its live-evidence status for seven additional destinations, including Help. All listed opportunities and remaining acceptance limits still apply.

| Destination | Evidence | Existing useful path | Highest-value refinement / open check |
| --- | --- | --- | --- |
| Home | V, AX, S | Four task cards; offline lookup; correct overview groups | Cards and recent technical jobs occupy almost the full first viewport. Keep task entry compact; avoid suggesting a global latest-map action belongs to the currently selected world. Verify every task-card transition without prior knowledge. `CompanionView.home/homeIntroduction`, `CompanionHomeActivityView`. |
| Worlds & backups | AX, S; visual O | Demo selection, import, explicit device-disabled explanation and backup integrity/storage status | First show world, date and “what can I do with this backup”; put deduplication/cloud methodology in details. Keep restore/delete safeguards. Existing state uses mixed “savegame”/“backup” wording. `main.swift: MainView`, library detail/status views. |
| Player | V, AX, S | Explicit read; no-live-data warning; Demo inventory and equipment successfully decoded | Large avatar/equipment card pushes inventory search and items below the first viewport. Lead with inventory/condition; compact optional avatar. Explain “Level unavailable” without making the whole read look unsuccessful. `PlayerView.body`. |
| Maps | V, AX, S | Saved Demo map, search/layers/measure controls; background generation entry | Only a grid was visible even after Whole world. Diagnose before cosmetic changes (UX-018). Native header + source + notification preference + Atlas sidebar consume most space; move routine render preferences behind an explicit action while keeping source/result freshness visible. `MapsView`, `LocalMapWebView`, web `app.js`. |
| Ore frequency | S; live transport blocked | Area selection, bounded census, distribution, reference, trials, 2D/3D workspace | Default path: select area → count → inspect heights. Keep random sampling, reference mappings and trial methodology secondary. Two census actions use “Count blocks” and “Measure area”; unify wording. Do not imply samples represent a whole world. `OreResearchView.scanPanel`, `OreWorkspaceView`, `OreLayer3DView`. |
| Portal pairs | S, O | Observed directed pairs, detected portals, separate assumed-scale plans | Add an explicit empty state and a direct Maps handoff. Current footer gives textual directions and the recording form follows all existing records. Separate Found / Observed / Planned without hiding uncertainty. `PortalsView.body`. |
| Nether Metro | S, O | Add station and Plan journey; empty-network sequence; compact panes; guarded drafts | Preserve the existing guided entry. Make current station/link and active mode visible across compact panes; explain why a trip is unavailable. Native line-to-link Cancel/Save acceptance is still needed. `MetroView.body`, `inspector`, `journeyEditor`. |
| Chests | S, O | Search first, filter popover, active summary, sorting and read prerequisite | Retain the existing controls rather than rebuilding them. Add a direct next step from no matches/unknown stock to relevant settings or read action; clarify item units, ownership and fixed distance reference. `ChestsView.body`, `filterSummary`, `sortingMenu`. |
| Conversation | S, O | Local lookup, starters, source, text input, explicit microphone and Stop | A typed answer currently renders text and external source links, not an exact native result action. Add “Open recipe/guide/place” using typed existing targets, with brief answer and scope first (UX-021). Do not imply headset voice control or silently enable models/microphone. `ConversationView.body`, `welcome`, `libraryPanel`. |
| Videos & tips | S, O | Edited summary, timestamped steps, transcript matches, optional system narration | Put the useful answer/matching authored steps before export controls and audio configuration. Original title/thumbnail/review metadata should support discovery, not dominate it. Transcript-only and visual-only entries need honest short fallback, not invented instructions. `VideoTipDetail.body`, `VideoCatalogRow`. |
| Build guides | S, O | Coach, material-plan handoff, per-step instructions and collapsed advanced sections already exist | Use as the reference task flow. Promote success checkpoints and prerequisite clarity; keep “Untested” beside action. Verify coach resume, 2D/3D and plan handoff natively; do not call these missing. `BuildGuideDetail`, `BuildCoachView`. |
| Crafting / Recipes | S, O; prior isolated renders | Type families, original variants/ingredients, quantity calculation and plan entry | Keep the new grouping. Distinguish an item with no recipe from an actual reference recipe in every search result (UX-020). Use item type → variant → quantity as the reading order; never merge material-specific recipes. `CraftingView`, `CraftingBrowseGroup`, `QuickFindCatalog`. |
| Mobs & Animals | S, O | Name/category/evidence search, status and optional illustrations | Lead with concise identification and supported practical information; reduce repeated disclaimer prose while retaining visible source-game/platform status. It is a catalog, not a world scan. `MobsView`, `MobDetail`. |
| Links & Knowledge | S, O | Comparison, checklist and community links | Make the selected search scope explicit in the placeholder; distinguish a personal checklist from supported game content. Provide next steps in empty results. `ResourcesView.body`, `MinecraftChecklistView`. |
| Help | S, O; overview AX | 48 bilingual topics, local search, related topics, contextual page entry | Keep the synchronized navigation. Use task answer → prerequisites → short steps → success check before longer explanation; add contextual native handoffs where safe. Do not require reading Help to perform a routine task. `HelpView`, `HelpArticles.json`. |
| Statistics | S, O | Read counter, stored-stock statistics, backup changes; unknown metrics collapsed | Distinguish three tasks visually: activity, stock, changes. Lead with snapshot/result scope and avoid presenting absent history as zero. `StatisticsView`, `ChestStatisticsView`, `ChunkChangesView`. |
| Tectonicus | S, O | Explicit setup consent, render parameters, separate experimental output | Explain when to choose it versus Maps; name the purpose alongside Tectonicus. Retain consent/download/storage costs and Overworld-only warning. Technical camera parameters can be secondary. `TectonicusView.body`. |
| Editor | S, O | Items/level, review and Save copy, separate Quest test transfer | Present Select → Change → Review → Save copy with exact before/after values. Test all narrow-window action footers; never convert this into a one-click device overwrite. `SaveEditor.swift: SaveEditorView`, `reviewSheet`, `EditorTestExportView`. |
| AI export | S, O | Explicit inclusions, blocked reasons, preview, Markdown/JSON/sharing | Offer a clear inclusion summary and Create → Review → Save/share path. Personal/world data remains explicit opt-in/visible according to current settings. Update “Skills” wording to match “Assistant instructions”. `AIContextExportView`. |
| Assistant instructions | S, O | Templates, edit/versions, explicit “Use for AI export” | Clarify what a skill does and that importing does not execute it. Consistent labels for template/instruction/skill; keep history and advanced exchange available. `AgentSkillsView`. |

### Concrete new findings

Dialog coverage is source-only in this follow-up: Setup/manual transfer (offline entry and fixed-size panels); Feedback (required fields, optional reproduction detail, ZIP/mail and draft guard); material review/plan (mapping confirmation, explicit save and same-sheet handoff); Build coach (step, audio, 2D/3D and resume); Editor review/test transfer (copy boundary and explicit confirmation); Conversation settings/chest library (provider/readiness and audio scope); assistant-instruction/profile editors (versions and Save/Cancel); standalone Help (search/back/related topics). Icon packs, appearance/spoiler settings, native import/export/share panels, Ore 3D sheets and Metro carry-forward still need live layout/action verification. No modal was accepted merely because its declaration exists.

**UX-018 · P1 · Map result visible as empty grid; failure feedback incomplete.** Live Demo Maps showed controls, chunk counts and saved map date but no terrain. Whole world did not change the visible result. Read-only inspection of format-2 metadata found all 10 expected terrain/height tile paths present; file presence does not prove decoding or drawing. `MapController.restoreLast` refreshes viewer assets over existing data, and web `app.js:imageFor` only sets `img.failed=true` on an image error; it exposes no user-facing recovery. Root cause remains unknown: do not label it missing files, a general renderer failure or a data-loss bug. Follow-up: reproduce in an isolated copy, inspect browser/runtime/load errors, verify format compatibility, then add a bounded visible error/retry/rebuild route. Acceptance: a valid Demo renders visibly; deliberately unavailable/corrupt assets produce a specific recoverable message, not an apparently healthy blank grid. Original backup and old output remain intact.

**UX-019 · P1 · Eight Go destinations share Cmd-Shift-E.** `CompanionView.swift:CompanionNavigationCommands`, line 377, assigns `e` to every case at index ≥10 except Statistics and Skills. Resources, Builds, Videos, Help, Player, Conversation, Mobs and AI export therefore collide. This is a code-confirmed mapping defect, not a native determination of which command wins. `CompanionNavigationTests` preserves case order but does not test uniqueness. Follow-up: define explicit optional shortcuts centrally; keep established unique shortcuts and remove or deliberately reassign collisions. Acceptance: every assigned key/modifier pair is unique, and visible menu commands and focused-input behavior are checked in the real app.

**UX-020 · P2 · Quick find calls items without recipes “Comparison recipe”.** `QuickFind.swift:QuickFindCatalog.search`, lines 28–30, applies that detail to all Crafting hits. `CraftingIndex.filtered` includes 1,206 mapped items, of which 618 have no output recipe in this bundle (read-only catalog count). Users can follow an apparent recipe result into “Recipe open”. Follow-up: label actual coverage per item and keep the uncertainty qualifier separate. Acceptance: both recipe-bearing and no-recipe fixtures have truthful DE/EN result labels; the destination retains the exact item ID and original filters/routing semantics.

**UX-021 · P2 · Answer-to-action handoff remains incomplete.** `ConversationView.body` displays message text and external `sources` links; its recipe library opens a separate generic Crafting sheet. `QuickFindMatch.target`/`CompanionLookup` already provide exact native routing elsewhere. Follow-up: return a typed optional action with local knowledge answers and reuse guarded routing; keep a compact answer and source scope before details. Acceptance: a supported recipe/build/place answer opens its exact existing screen without retyping, an unsupported answer offers clarification rather than a guessed destination, and existing draft protection remains effective. This is a focused integration opportunity, not permission to introduce a new AI service.

### Existing findings refined, not reopened wholesale

- **UX-009/010/014:** Home now has task entry, but the setup wizard is still eight headset/ADB-oriented steps with “Later” rather than a first-class “Use without headset” branch. Offer Learn offline / Import existing backup / Connect Quest before device instructions. Use “Inventory & equipment”, “Ore distribution” and “Experimental map render (Tectonicus)” as descriptive subtitles or proposed display names; keep stable IDs and searchable old aliases. No rename is implemented by this audit.
- **UX-011/012:** compact the Player avatar and Maps header; separate Explore existing map from Generate/update. Keep a concise source/freshness row and explicit error state. Portal, Ore, Metro and Statistics should share task-first structure, not necessarily identical panes.
- **UX-013:** reuse the existing build-coach pattern for edited video knowledge: short answer, needed materials, small steps, success check, optional explanation, source. Do not obscure unverified RealmCraft compatibility. Keep exact recipes and uncertainty in plans.
- **UX-016:** Feedback already has draft protection and a compact technical preview, but reproduction/expected/actual fields remain always visible even for a suggestion. Reveal only relevant optional fields after the two required fields. Keep no-send-by-default and image review. Build material review already uses one sheet; native close/save/back and changed-review behavior remain acceptance work.
- **UX-017:** test EN/DE, Classic/Block, minimum window sizes, keyboard-only and actual VoiceOver, active/inactive selections, no backup/device, empty results, unavailable assets, background completion and guarded drafts. Current source/geometry tests do not satisfy these gates.

### Ordered implementation packages

| Package | Work and reuse | Acceptance / effort shape |
| --- | --- | --- |
| A · Reliability and truthful navigation | UX-018 diagnosis; UX-019 explicit unique shortcuts; UX-020 coverage labels. Reuse current renderer, metadata and CraftingIndex. | Small shortcut/label changes; map root cause needs a bounded diagnosis before estimation. No blank-success state and no ambiguous assigned shortcut. |
| B · First useful result | Compact Player and Maps top regions; explicit offline setup entry; consistent verbs, source row and disabled-action reasons. Reuse page header, source bar, notices and current task cards. | Medium presentation work, verified in both themes/languages at the actual minimum window. Inventory or a useful map remains visible without scrolling past setup/methodology. |
| C · Learn while doing | Edited video answer first; typed Conversation handoffs; reusable short task/checkpoint presentation using existing coach/help/catalog content. | Medium cross-feature work. Existing content and provenance remain authoritative; no invented game support or automatic audio/network actions. |
| D · Community acceptance | Finish the blocked live matrix and test representative novice tasks with people who have not used Companion. Then apply remaining specialist/dialog/accessibility polish. | Separate acceptance, not another feature batch. Record completion without assistance, wrong turns and explanation needed; do not invent study scores. |

Suggested novice tasks: look up one item and distinguish its material variants; calculate a requested amount and save a material plan; resume one guide and find its success check; open an existing Demo map and identify its saved date; understand no chest results without assuming zero inventory; find a tool under More tools; cancel an edited draft without losing it. Provisional targets such as finding a supported answer within 30 seconds and beginning a guide within two minutes are **design targets to test**, not measured results.

### Validation performed this follow-up

Successful live Demo player read; unchanged blank-map observation after Whole world; read-only tile-path inventory; source-derived shortcut collision enumeration; catalog coverage count; structural skill validation. Prior full build/signature and regression results remain recorded below and were not rerun merely for this documentation change. No UI fixes, help rewrite, device write, speech permission, publication or translation integration was performed. The final all-screen **visual** verdict remains blocked pending working UI access.

At the final comparison, the working `Sources/Library.swift` and `Sources/main.swift` differed from the running candidate. These concurrent changes were not made or reverted by this audit and are not silently included in its runtime findings.

## Type-first recipes and synchronized section overview · 1.7.47 (69)

Two focused corrections to the 1.7.46 macOS candidate:

- The Crafting browser groups explicit item families before material variants, using localized DE/EN headings and deterministic ordering. Boats and chest boats are separate families. Original item IDs, recipes, ingredients, evidence, search filters and plan handoffs remain unchanged. Unrecognized special items retain their full names; global Quick find keeps its existing result ordering.
- Home's “What each section does”, the sidebar and the Go menu now share `CompanionNavigationGroup` and its ordered feature lists, including Help and More tools. The former overview used the old unfiltered groups. All 20 destinations, stored feature IDs and existing keyboard shortcut assignments remain.

Executed: 41 type/variant/order/identity checks, navigation coverage/order/shortcut/help-target checks, 2,888 catalog checks, 32 material-plan checks, 46 search/material-handoff checks and 143 help checks for 48 bilingual topics. Four hidden native-hosted production Crafting renders were generated for the boat filter in DE/EN and Classic/Block themes; representative DE Classic and EN Block renders were visually inspected. The first Classic fixture incorrectly scoped its isolated preferences and was rejected; the corrected harness applies the preference store outside the appearance modifier. Native intrinsic height can exceed the requested host size, so these renders do not establish viewport fit or keyboard/scroll acceptance.

Source and tests were compared with the isolated build copy. No installed app, real library, savegame, device, Android/web implementation or publication was changed. The comparison catalog contains material-specific boats; this does not confirm their availability in RealmCraft.

Final Universal build **1.7.47 (69)** completed for arm64 and x86_64. Strict/deep signature verification passed; executable mode is 0755. The packaged app completed `--list` with an isolated empty library and ADB disabled. Packaged resources passed the 41 browse, navigation, 46 search/material-handoff and 143 help checks. The 602-file CommunitySource archive passed ZIP integrity verification. Executable SHA-256: `4a78d31f28bc159cef082a685a920f2a5358304f6c507f352f89f1f2a6e06e1d`.

Final application Sources match the isolated build copy. A concurrently added `Tests/test_translation_catalog.py` and `Resources/Translations` directory remain untouched and outside this frozen candidate; all other Tests match. The final audit record is maintained here after the build. No GUI restart, installation, full-app interactive acceptance or Intel-hardware runtime test was performed.

## Usability implementation · 1.7.46 (68) · 2026-09-12

Mac source candidate. This implements a first coherent package from UX-008–017, not every proposed screen redesign.

- **UX-015:** Metro connection editing now authorizes the transition inside the shared `editEdge` entry point. Both station and line links use it; Cancel or failed Save does not replace the draft.
- **UX-008/009:** persistent top sidebar search, four real category filters, grouped direct results, keyboard shortcut and explicit no-result/missing-catalog states. Feedback remains bottom-left. All 20 destinations and existing raw IDs/Go shortcuts are retained; five specialist tools use an expandable group that opens on direct navigation. Home leads with four task entries and offline/import/Quest options when no backup exists. Import is also visible in the library header. These new navigation entries start no transfers or rendering.
- **UX-010/012/014 (partial):** shared page-purpose/help row opens stable topic IDs through the draft guard. Source details separate technical IDs from game-file time and not-live status, now including Conversation. Localized world/backup, assistant-instruction and creature labels; actionable AI-export blocked reasons and an empty-network Metro sequence.
- **UX-011/013/016 (partial):** recipe filters collapse while counts/reset and evidence stay visible; unavailable historical metrics move into a labeled disclosure. Reviewed guide materials transition to the plan in the same sheet instead of opening a nested plan sheet. Explicit Save, provenance, bounds and recipe choices remain. Feedback participates in draft protection: successful ZIP export saves report/images, Cancel/errors retain the draft, Discard clears it; the mail recipient is not stored in ZIP and no mail is sent automatically.
- Help retains all 48 bilingual topics and existing IDs. Navigation, search, source, material and feedback workflows were updated; setup and embedded agent copies use the same current menu paths. No savegame schema, game content, world/library data, device write or publication changed.

Remaining: full Atlas/Ore progressive disclosure, portal/chest task flows, broader knowledge-filter harmonization, further dialog/VoiceOver/contrast work, and new-user task observation. The separate Metro/terrain adapter (UX-007) and Android/web parity are not part of this package. Native full-app task acceptance and installation remain separate from compilation, model tests and isolated component renders.


### 1.7.46 verification record

Current-source changes were reviewed against the frozen, previously verified 1.7.45 source. No Git state is implied. The final candidate uses a fresh isolated source/build directory; the first 1.7.46 trial is superseded by the search-contrast correction.

Executed successfully: whole-module type checking; 680 header geometry cases (including contextual guidance at narrow widths); 46 search/material-handoff checks; 143 help-catalog checks for 48 DE/EN topics; 13 draft-transition behavior checks; 32 crafting-plan checks; 144 Conversation checks. Metro connection call sites were inspected, but the unsaved-line transition has not been reproduced through native user input.

Rendered 28 production help-content samples. Twelve native-hosted search/header samples exercise both languages/themes and navigation/results/no-results at 1080 × 700. Their navigation body is deliberately a labeled fixture, not the full application. ImageRenderer's unsupported native-control placeholders were rejected; hidden NSHostingView capture replaced it. A low-contrast result title found in the dark render was corrected with explicit primary foreground styling. Full VoiceOver, keyboard-only task completion, active/inactive selection contrast and every window remain native acceptance work.

Help trace: `companion/start/quickFind` follow shell navigation; `dataScope/conversation` follow SourceContextBar; `materialPlan` follows the single-sheet handoff; `feedback` documents ZIP-save/discard/cancel behavior; `crafting/statistics/aiExport/metro` explain the affected controls and limits. Setup menu paths are synchronized with the standalone DE/EN guides and their agent-preface-preserving embedded copies. Stable topic IDs and storage paths are retained.

Final Universal build **1.7.46 (68)** completed for arm64 and x86_64. Strict/deep code-signature verification passed; the executable mode is 0755. The packaged application completed `--list` with an isolated empty library and ADB disabled. Packaged resources passed the 143 help and 46 search/material checks; the 598-file CommunitySource archive passed its integrity test. The final Sources and Tests match the working source (excluding generated graph/cache directories), and the help/transfer documents match the packaged copies. Metro model regressions also passed persistence, legacy/stale-write checks, directed routing, transfer counts, planned-link exclusion, path geometry and map selection.

Executable SHA-256: `0f348495cf1cb49dbadb116e945743eab50922e6699bdc87a4c22130b47b5cef`. No installation, GUI restart, real-library/device test, Intel-hardware runtime acceptance or publication was performed. The previously installed/running app remains a separate version.

## New-user usability follow-up · 1.7.45 (67)

Scope: repeat source/workflow review of all 20 macOS navigation destinations, the embedded Atlas controls and the principal dialog families. Reference is the verified 1.7.45 source candidate; no application code or settings were changed. This is a heuristic usability review, not a usability study with new users, a full native screenshot/click-through audit or Android/web acceptance. The older Graphify index was used only for orientation; current source overrides its stale locations. The earlier 1.7.44 findings below are historical, not a current missing-feature list.

### Overall finding

The shared header, source display, icons, draft registry and search are useful foundations. The remaining problem is discoverability and decision load: the shell presents 20 destinations, Home prioritizes device backups/maps/AI exports, several pages lead with technical parameters, and important distinctions depend on reading lengthy explanatory text. These are code-supported design risks; no completion-time improvement or observed user failure rate is claimed.

Keep one application and one set of domain models. Prefer progressive disclosure within each page over a global beginner/expert switch that changes the whole navigation unpredictably. Do not hide safety-critical warnings, fabricate defaults, weaken evidence requirements or change immutable-save behavior.

### Whole-navigation review and proposed changes

File paths are relative to `Sources/`. Each row separates an observed composition from a proposed improvement.

| Screen | Current composition / friction for newcomers | Proposed improvement without feature loss |
| --- | --- | --- |
| Home | `CompanionView.home/homeIntroduction`, `CompanionHomeActivityView`: three activity rows for backup, map and AI export; introduction tells users to start with Savegames. Offline knowledge is less prominent. | Lead with “What would you like to do?”: look up something, explore a backup, plan/build, back up a world. Offer “Use without a headset” and “Import an existing backup”. Move recent activity beneath these entries. Keep existing activity/source handoffs. |
| Savegames | `main.swift: MainView`: grouped backups, nested sidebar, import and device/library tools; Savegame/backup/library terminology varies. | Use “Worlds & backups”; distinguish the world from its dated snapshots. One visible backup/import path and an explanation for disabled device actions. Keep restore/delete separate with exact target and recovery confirmation. |
| Player | `PlayerView.body`: Device/Savegame choice; device world picker displays IDs; explicit read/refresh and saved-not-live explanation. | “Inventory & equipment” subtitle, human-readable world label where available, “Last saved device state” vs “Backup on this Mac”. Explain unavailable refresh beside the control. Keep IDs in details and local skin clearly separate from game changes. |
| Maps | `MapsView.body` plus `web/index.html`: app sidebar, source/settings lane and a second Atlas sidebar; layers, levels, coordinates, places and tool controls. | Separate “Create/update map” from “Explore existing map”. Start exploration with dimension, search/place and zoom; group layers and tools into labeled panels. Keep the active tool and Exit/Cancel visible; advanced orientation, chunk grid and diagnostics remain available. |
| Ore frequency | `OreResearchView`, `OreWorkspaceView`: four sections plus XYZ bounds, samples, reference mappings, trials and 2D/3D controls. | Guided entry: choose area → measure → inspect heights/materials. Offer existing map selection and presets before raw XYZ. Put sampling/reference hypotheses and trial methodology under clearly named advanced sections. Distinguish 2D/3D presentation from a new measurement. |
| Portal pairs | `PortalsView.body`: long evidence explanation, plans/observations/portal list, then the recording form. | Separate “Found portals”, “Observed connections” and “Planned portals”; show the main next action near the top. Explain an empty result and the map-planning route. Keep observed direction, unknown arrival height and assumed 8:1 scale visible. |
| Nether Metro | `MetroView`: compact panes, map/network selector and station/line/edge/journey tool selector. Multiple independent modes must be understood. | Task entries “Plan a journey” and “Edit network”; empty-network path “Add stations → connect → confirm measurements → travel”. Keep the selected station/connection visible while changing panes. Add reasons for unroutable networks; never make planned links routable. Fix the guard bypass below first. |
| Tectonicus | `TectonicusView`: separate setup/render flow with radius, detail, angle and elevation; opaque tool name in main navigation. | Place under expandable tools as “Experimental map rendering (Tectonicus)”. Explain why to choose it instead of Maps. Offer a conservative presentation preset plus advanced controls; retain downloads/consent and separate job behavior. |
| Chests | `ChestsView`: search, material combination, group, dimension, visibility, ownership, sorting and distance reference. | Lead with “Find an item”; show active filter chips and a single reset. Keep count scope and ownership explicit. Show coordinates/details after selection; preserve grouping, multi-material AND/OR and distance reference under advanced filters. |
| Statistics | `StatisticsView`, `ChestStatisticsView`, `ChunkChangesView`: activity counter, stock and file changes in one scrolling page, followed by unavailable historical metrics. | Three clearly named sections: “Activity”, “Stored items”, “Changes between backups”. Label units and snapshots beside each result. Put the extended unavailable-metric explanation in “What cannot be measured”; never replace unknown with zero. |
| Editor | `SaveEditorView`: items/level, selection, action and review-copy flow; separate Quest test transfer. | Display a short step sequence “Select → edit → review → save copy” and a before/after summary. Keep “Original backup unchanged” prominent. Technical transfer remains a distinct, explicitly confirmed operation; no one-click overwrite. |
| AI export | `AIContextExportView`: source, skill, profile, chests, navigation and video options, then Markdown/JSON/sharing. | “Prepare data for an assistant” with a compact inclusion summary and reviewed presets. Additional content stays opt-in according to current settings. Make “Create document → review → save/share” explicit; privacy-critical inclusions stay visible even when technical options collapse. |
| Conversation | `ConversationView`: useful starter questions already exist; world selection, provider/language summary, voice state and settings. | Keep the existing starters, add knowledge-only examples when no world is selected and data-dependent examples when available. Use plain “Local lookup” / “Enhanced question understanding” wording with technical provider details in settings. Preserve visible microphone state, Stop and the no-Quest-audio assumption. |
| Skills | `AgentSkillsView`: reusable instructions, personal context, versions and imports; technical naming. | Display “Assistant instructions (Skills)” with “These instructions are included in an export; importing does not run them.” Lead with an existing template and intended use; keep history, language editing and package actions under details. |
| Videos & tips | `VideoTipsView` in `BuildGuidesView.swift`: search plus topic/source-game/coverage/sort and long detail sections. | Search first, active filter summary, further filters on demand. Lead results with a concise topic and actionable timestamp. Keep source game, extracted/transcript-only coverage and external video/thumbnail behavior explicit. |
| Build guides | `OfflineBuildGuidesView/BuildGuideDetail`: steps, 2D/3D, materials, coach, separate agent audio guide and evidence. | Organize into “Prepare”, “Build step by step”, “Check result”. One clear build-start action. Keep Coach distinct from exporting instructions to an external voice agent; retain sources and untested status. |
| Crafting / Recipes | `CraftingView`: catalog counts/disclaimer, three filters, item list, variants, desired output and plan entry. | “Recipes & materials”: search and desired quantity first. Collapse catalog statistics and advanced filters; keep recipe coverage and unresolved variants visible. Explain output rounding next to quantities. Existing icons and calculator remain authoritative. |
| Mobs & Animals | `MobsView`: English title and “Animals” category even in German, evidence-heavy header and optional images. | Localize navigation/category labels (“Tiere & Kreaturen”) while retaining original catalog names/IDs. Show a brief evidence badge plus expandable explanation. Reuse existing no-results/reset behavior. |
| Links & Knowledge | `ResourcesView`: comparison, content checklist and links/community use different content types under one search field. | Name the active sub-area in the search placeholder and empty state. Distinguish comparison information from confirmed RealmCraft content and personal checklist state. Make external-link destinations recognizable. |
| Help | `HelpView`, `HelpCatalog`: 48 bilingual topics, grouped search, related topics and back navigation already exist. | Add “Help for this page” from a shared page header using existing stable topic IDs. Lead relevant articles with a short task checklist. Keep full technical explanations, setup and exports available; do not build a second help catalog. |

### Principal dialogs and cross-cutting presentation

| Family / evidence | Proposal and invariant |
| --- | --- |
| Setup / manual transfer — `SetupView` | The eight-step Quest walkthrough and Later action exist. Add an explicit early branch for “Offline knowledge”, “Import backup” and “Connect Quest”; do not require a headset to discover recipes. Make the remaining fixed 780×680 surfaces usable on short screens. License acceptance stays manual. |
| Quick find — `CompanionView:114`, `QuickFindView` | Move to a persistent field near the top of the sidebar, below compact branding. Cmd-Shift-F focuses that same field. A filter button exposes the four supported content types; do not label it advanced search without extra functionality. Keep exact result routing and draft guards. Current scope excludes Mobs, links, skills, personal worlds and chest contents; do not promise “everything”. |
| Guide material review / plan — `BuildMaterialHandoffView`, `CraftingPlanView` | Replace the nested-sheet experience with one explicit sequence “Review rows → preview plan → save”, reusing the same models/storage. Highlight unresolved rows before confirmation; display which screen is an unsaved draft. Keep omissions, original quantities, existing recipe choices and explicit persistence. |
| Ore 3D / coach — `OreLayer3DView`, `BuildCoachView` | Flexible sizing exists. Make the selected layer/window and camera reset obvious; group export/preset details. Coach keeps step text and Next/Back/Stop reachable independently of the 3D preview. |
| Metro carry-forward / editor review / test export — `MetroCarryForwardView`, `SaveEditor`, `EditorTestExportView` | Use a consistent Source → Target preview and specific action wording. Retain empty-target restriction, stale-write checks, explicit risk confirmations and the separation between local copy and device transfer. |
| Voice/model/skill/profile settings — `ConversationView`, `AgentSkillsView` | Group audio, question interpretation and personal data separately. Explain readiness and denied permissions next to the relevant action. Preserve explicit Save in editors; do not turn it into implicit preference saving. |
| Appearance/spoilers/icons/export destinations — `CompanionStyle`, `CompanionView`, `ItemIcons`, `MapExportSettings` | Group by user purpose in Settings. Distinguish previewed icon pack from active pack and persisted preferences from edited documents. Keep text-only support, licensing, explicit downloads, spoiler scope and separate export destinations. |
| Feedback — `FeedbackView` | Keep a labeled bug icon at the bottom. Use “Report a problem”; start with short title and “What happened?”. Show reproduction/expected/actual details when useful to the selected report type; JSON/Hjson stays advanced. State clearly that composing a mail draft is not sending it. Warn before abandoning entered feedback; current Close dismisses directly. |

### Concrete findings and prioritized work packages

- **UX-015 · P1 · Code-confirmed guard bypass:** `MetroView.lineEditor` line 377 invokes `editEdge(edge)` directly, unlike guarded editor transitions. `editEdge` line 592 changes the active tool and calls `markClean()`. Reproduction to accept natively: edit an existing line name/color without saving, then click one of that line's connections. The line draft ceases to be protected, so later switching away can lose it without the intended prompt. Route this transition through the existing guard; Cancel must preserve the line/tool and Save failure must block the switch. This was found by source inspection, not reproduced interactively. Do not describe the whole draft system as fully accepted.
- **UX-008 · P1 · Navigation/search:** persistent top search, real content-type filters, labeled bottom feedback and expandable specialist navigation. Keep all 20 destinations reachable, stable feature IDs and existing shortcuts; no automatic world scan on typing.
- **UX-009 · P1 · New-user Home:** task-based entries and offline/import/Quest branches. A new user without a headset should reach a recipe or guide directly; a user with a backup should reach its map without reading the full help.
- **UX-010 · P1 · Page/empty-state contract:** title + one-sentence purpose + relevant source + one primary action. Distinguish no source, not read, no matches, missing prerequisite, in progress, failed and stale results. Every blocked main action gets a concise reason and a safe next step; avoid instructions available only as disabled-control tooltips.
- **UX-011 · P2 · Dense workflows:** apply progressive disclosure first to Maps/Ore/Metro, then AI export. Keep the active tool and pending draft evident, and retain all specialist options without new stores or renderers.
- **UX-012 · P2 · Source/status hierarchy:** keep world name, backup time, selected dimension and stale-result warning visible; move IDs/raw paths to Details when not needed to disambiguate. Extend the existing source contract to Conversation and source/target dialogs. Separate app failure, data incompleteness, hypothesis and ordinary information with text/icon/severity.
- **UX-013 · P2 · Knowledge/material flow:** harmonize local filters, badges, result selection and guide-to-plan steps. Preserve unverified recipe/source labels and omitted materials. Do not infer owned stock or platform parity.
- **UX-014 · P2 · Vocabulary/context help:** consistent DE/EN display names, “Sicherung” vs world, “Einlesen/Aktualisieren” vs “Neu berechnen”, descriptive export labels, existing topic-ID help routing. Technical terms remain available in detail/search aliases; persisted IDs do not change.
- **UX-016 · P2 · Dialog and feedback consistency:** predictable Close/Cancel/Save meaning, dirty-feedback confirmation, fit short screens, visible action footer, no unwanted nested navigation. Never remove safety confirmation to reduce clicks.
- **UX-017 · Acceptance gate:** keyboard and VoiceOver/focus checks, theme/contrast and minimum-window review, then task-based tests with actual newcomers. This is verification work, not a new feature.

Recommended order: fix UX-015, then deliver UX-008/009/010 as the first bounded usability package. Follow with UX-011/012/014, then UX-013/016. Apply UX-017 to each package rather than postponing all testing. UX-007 remains independent domain work, not part of a usability cleanup.

### Reuse, ownership and acceptance

The UI coordinator owns shell, shared page composition, vocabulary and documentation. Feature owners retain validation, source scopes, locks and storage. Reuse `CompanionStyle`, `SourceContextBar`, `DraftTransitions`, `CompanionLookup/QuickFindCatalog`, `HelpCatalog`, existing Atlas tool coordinator, crafting calculator and item icons. Do not replace them with competing systems.

For each accepted package test DE/EN, both themes, keyboard-only use, minimum main-window size, long text and these task cases using synthetic or authorized isolated demo data:

1. No headset/library: find a recipe, inspect quantities, open a guide and locate help.
2. Imported backup: identify world/date, open the right map, understand a missing dependency and a background job.
3. Chest search: see active filters, distinguish no match from unread data, show the selected location.
4. Ore: choose area, measure, inspect a layer in 2D/3D, understand missing coverage.
5. Metro: edit an unsaved line, visit its connection, exercise Save/Discard/Cancel, then plan only a confirmed directed journey.
6. Materials: resolve an ambiguous guide row, omit another, preview additions, cancel/save/reopen and confirm provenance/choices.
7. Voice: type without permissions, explicitly start/stop microphone, understand saved-data/model limitations.
8. Feedback: create a report, cancel safely, review attachments, prepare but do not automatically send.

Track success without assistance, wrong-source selections, backtracking and misunderstood labels as future test observations; do not invent a baseline or numerical gain. Current geometry/help regressions and the prior verified build do not establish native task acceptance.

Verification for this review: the existing native shared-header suite passed again (672 cases), and the help catalog suite passed again (143 checks, 48 bilingual topics), including after the backlog documentation update. Application `Sources` match the verified 1.7.45 snapshot, excluding generated Graphify output. No source implementation, new build, installation, live world/device operation or native full-app interaction was performed. Only this audit, the feature-map pointer and the proposed backlog were updated.


## Implementation follow-up · 1.7.45 (67)

The original findings below remain the historical baseline. UX-001, scoped UX-002/003, UX-005 and the reviewed UX-006 adapter are now implemented; UX-004 has localized Metro modes and shared portal/ore notices, but broader accessibility and terminology work remains. The current integration entry records contracts and verification. This is not a claim of full native or cross-platform acceptance. UX-007 remains separate.

Reference: macOS source candidate 1.7.44 (66). This is a source/workflow audit of all 20 navigation destinations and their principal dialogs, plus representative native help-content rendering. It is **not** a claim that every window was clicked through or accepted on hardware. The installed application remains a separate release state. Android and web require separate platform acceptance.

## Conclusion

The app already has a coherent foundation: three navigation groups, one page-header component, two shared themes, common panels/buttons, mostly explicit source selection and conservative evidence warnings. The next useful step is workflow consistency, not another independent feature or a replacement design system.

Prioritize (1) visible source context, (2) protection for unsaved drafts, (3) responsive toolbars/dialogs and consistent terminology, then (4) a shared quick finder and (5) reviewed build-to-material-plan handoff. Keep source scope and confirmation rules intact.

The help gap is addressed in this candidate: 47 bilingual topics instead of 36, all previous IDs retained, related-topic navigation, search over both languages and a genuine no-results state. Setup and its embedded agent copies now match. No non-help feature implementation was modified in this audit.

## Whole-navigation inventory

“Present” means implementation found in source, not full native acceptance. Help IDs refer to `Resources/HelpArticles.json`; detailed feature limitations remain in the feature map and integration register.

| Destination | Present workflow / evidence | UX or integration follow-up | Help |
| --- | --- | --- | --- |
| Home | Three recent-activity lanes and grouped navigation; `CompanionHomeActivityView`, `CompanionView` | Distinguish opening an old result from starting a new operation and show the action's source | `start`, `companion` |
| Savegames | Grouped immutable backups, import/export, verification, deduplication and guarded restore; `MainView`, `Library` | Clearer backup-time versus game-time wording; source context across consumers | `library`, `backup`, `restore`, `zip` |
| Player | Device/backup source, explicit refresh, last-read time, inventory/skin; `PlayerView` | Retain the strong saved-not-live distinction in a shared source component | `player`, `dataScope` |
| Maps | Shared Atlas, picking, layers, POIs, navigation, background render/cancel/open result; `MapsView` | One job/status vocabulary; distinguish preparation from background stage and stale result | `maps`, `backgroundMaps`, `navigation`, `places`, `biomes` |
| Ore frequency | Explore/distribution/reference/trials; bounded 2D/3D, camera/export, presets; `OreResearchView`, `OreWorkspaceView` | Draft guard, dense region controls, large cutaway dialog; preserve incomplete coverage | `ores`, `ore3D`, `orePresets` |
| Portal pairs | Detected portals, manual directed observations and plans; `PortalsView` | Reload/source change clears draft fields; no common dirty guard | `portals` |
| Nether Metro · Beta | Directory/map/inspector, network editing, reviewed carry-forward, saved journeys/export; `MetroView` | Source label lacks date; three minimum-width panes; raw mode values in journey list | `metro`, `metroJourneys` |
| Tectonicus · Beta | Separate setup, consent, render and retained output; `TectonicusView` | Dense options; not part of Atlas's background-notification workflow | `tectonicus` |
| Chests | Read, search, filtering, ownership, grouping, sort/reference and JSON; `ChestsView` | Good status lane; make active spoiler/filter/source state consistent elsewhere | `chests` |
| Statistics · Beta | Saved counters, stock comparison and verified chunk-file change map; `StatisticsView`, `ChunkChangesView` | Counters, owned stock and file changes need visibly distinct units/evidence | `statistics`, `chunkChanges` |
| Editor · Beta | Review and copy-based changes, separate test export; `SaveEditor`, `EditorTestExportView` | Preserve explicit review; share draft/source guard without relaxing save safety | `editor` |
| AI export | Snapshot-bound Markdown/JSON, skill/context inclusion and explicit sharing; `AIContextExportView` | Clear inclusion summary and source stamp; never treat export as backup | `aiExport` |
| Conversation · Beta | Deterministic lookup, optional interpretation, speech, saved-plan reading; `ConversationView` | Several settings sheets; clarify question language versus interface language and model readiness | `conversation` |
| Skills | Search, create/version, archive/import/export and personal context; `AgentSkillsView` | Reuse deliberate save/conflict pattern; fixed editor size and different search semantics | `skills` |
| Videos & tips | Search, filters, provenance, timestamps and export selection; `VideoTipsView` in `BuildGuidesView` | Repeated discovery flow; retain source/evidence distinction and thumbnail network disclosure | `videos` |
| Build guides | Search/category, 2D/3D, checklist, coach and local checkpoint; `BuildGuidesView`, `BuildCoachView` | Material checklist is separate from crafting plan; fixed visual panels and coach sizing | `builds`, `buildCoach` |
| Crafting / Recipes | Bilingual lookup, grids, variants, quantities, icons and local recursive plan; `CraftingView`, `CraftingPlanView` | Crowded header; reviewed stock/guide handoff and named plans remain separate | `crafting`, `materialPlan` |
| Mobs & Animals | Filtered source/evidence catalog, optional images and report action; `MobsView` | Intentionally English title/category labels differ from other DE pages; align terminology deliberately | `mobs` |
| Links & Knowledge | Comparison, content checklist and external references; `ResourcesView` | Search scope changes by subsection; show the active scope and useful empty state | `resources` |
| Help | Grouped searchable reference and support exports; `HelpView`, `HelpContent` | New catalog/search/links implemented; full keyboard/VoiceOver click-through remains open | All topics |

## Principal windows and dialogs

Source paths below are relative to `Sources/`. Width/height findings are code-confirmed constraints, not proof of clipping on a particular screen.

| Surface | Review result / remaining acceptance |
| --- | --- |
| Main shell | `CompanionView`: minimum 1080 × 700, main sidebar 212. Fits a desktop workflow, but does not guarantee every embedded feature fits that width. |
| Separate/embedded help | `HelpView`: separate minimum 900 × 600, internal topic sidebar 220, scrollable content. DE/EN, both themes, long lists/content included in render QA; native list/search/back/export focus still needs interaction tests. |
| Setup and manual transfer | `SetupView`: dedicated first-run steps and full settings, alternative transfer entry, explicit licensing. Check 780 × 680 setup at short screen heights. No license acceptance or device setup performed by this audit. |
| Appearance, exploration, map export, icon packs | Shared Settings entry with specialist dialogs. Keep labels, primary/secondary actions, explicit downloads and missing-icon/text-only behavior uniform. |
| Backup/import/restore/library location | Native panels plus explicit review; retain target/world preview and backup-before-restore boundary. Test Cancel and ambiguous source states with synthetic data. |
| Player skin | Local appearance editor; must remain visually distinct from writing a game skin or save. |
| Ore cutaway/camera/PNG | `OreLayer3DView`: fixed 1000 × 850 sheet can exceed usable height on smaller desktops. Replace fixed size with bounded, resizable/scrollable composition before acceptance. |
| Metro carry-forward | Dedicated source/target review, empty-target requirement and reconfirmed evidence. Reuse source labeling but do not auto-merge networks. |
| Build coach | Minimum 660 × 680, ideal 860 × 880; reading controls and preview compete for height. Native speech/scroll/keyboard QA still required. |
| Material plan | Minimum 800 × 580, explicit save/discard/conflict handling. Reuse the guard pattern, not its global storage scope. |
| Conversation configuration | Fixed-width 620/700/730 settings surfaces. Test denied mic/speech permission, offline models, Stop, focus and text-only operation separately. |
| Skill editor / personal context | 720 × 650 and 660 × 450; explicit save and interactive-dismiss protection. Test long translations and keyboard dismissal. |
| Feedback | Fixed 760 × 740; needs small-screen and attachment/preview tests. Reporting creates a draft, not an automatically sent message. |
| Editor review/test export and export panels | Confirm/cancel/failure paths remain acceptance gates; no real save or export was used in this audit. |

## Prioritized findings and concrete integration orders

| ID / priority | Evidence and effect | Bounded implementation / acceptance |
| --- | --- | --- |
| UX-001 · P1 | Metro's save picker shows only `title`; Maps/Player use backup dates, Portals uses game date, Statistics also shows world ID. Shared `model.selection` affects several features. | Add `SourceContextBar` using existing `Savegame` metadata: world, backup time, source type and optional dimension/result time. Pilot in Metro and Ore, then adopt in readers. Test two synthetic snapshots with the same world title; old result must never appear labeled as a new source. No storage migration. |
| UX-002 · P1 | `PortalsView.read()` clears draft names/endpoints/notes on reload and selection change; Metro load/selection and Ore trial reset paths also replace drafts. Crafting plan already guards unsaved edits. | Shared dirty-transition policy with Save / Discard / Cancel. Cover source, section, selection, reload, language and window-close transitions as applicable. Cancel must preserve draft and original source; failed save must not navigate. Never silently save incomplete evidence. |
| UX-003 · P1 | Metro panes minimum 185 + 350 + 270; global shell leaves little margin. Fixed 1000 × 850 ore sheet and 760 × 740 feedback dialog exceed some usable heights. | Adaptive inspector/overflow actions, bounded flexible sheets and scrollable content, reusing `CompanionLayout`. Test minimum main size, 1280 × 720 usable area and large display, DE/EN, both themes, keyboard focus. Clipping/crowding is a static risk pending those tests. |
| UX-004 · P2 / quick | `MetroView` journey row prints `edge.mode.rawValue`; catalog titles and section search wording vary; Beta/evidence warnings and orange notices serve different meanings. | Localized mode labels; consistent labels for Search this section, Read/Refresh and source dates; a shared status presentation with text/icon/severity, keeping domain evidence separate. Do not translate stored IDs or user names. Help headings/list markers now use primary text in Classic for readability. Extend contrast and VoiceOver checks to all remaining controls. |
| UX-005 · P2 | Separate recipe/video/guide/help searches exist; no universal quick finder. Rebuilding indices would duplicate work. | One keyboard-accessible quick finder over existing local indexes, grouped by destination with exact result handoff. Search never scans a save, downloads assets, starts a model or executes a command. Keep an explicit distinction between global navigation and local filtering. |
| UX-006 · P2 | Build checklist, crafting plan and stock are separate; guide materials can be prose without confirmed item IDs. | First add a review-only guide → material-plan adapter: mapped and unmapped rows, source and quantity preview; explicit Add after confirmation. Reuse `CraftingIndex`, `CraftingPlanCalculator` and icons. Never infer ambiguous IDs, convert unverified quantities or deduct stock silently. |
| UX-007 · P3 | Metro journey JSON and terrain NavigationPack are deliberately different; no complete approach/departure routing across dimensions. | Only after source/draft contracts: a versioned adapter retaining confirmed directed portal evidence, unplanned access and manual progress. This is substantial domain work, not a quick visual fix. |

Suggested first package: UX-001 and UX-004 (small/medium presentation work), followed immediately by UX-002 and UX-003 (state/layout work). Then UX-005 and the preview-only portion of UX-006. Estimates describe relative scope, not promised implementation hours.

## Shared ownership and non-duplication

The coordinator owns this audit, feature-map/backlog updates and help changes. Future presentation work owns `CompanionStyle` plus narrowly reviewed consumers; feature owners retain their persistence and safety decisions. Do not edit Metro, Ore and the shared Atlas bridge concurrently without file-level coordination.

- Reuse `Library`/`Savegame` for source identity; do not create a second snapshot model.
- Keep Metro/portal records snapshot-local, ore presets world-scoped, material plan global and guide checkpoints guide-scoped. Visual consistency does not authorize merging these scopes.
- Reuse `PlanningStore` and existing optimistic-write/lock boundaries, `ItemIconStore`, `CraftingIndex`, the Atlas coordinate transform and the existing orbit view.
- `HelpCatalog` is now the only help-content loader; no parallel Swift article list or separate help search index.

## Help changes and validation

New task-based chapters cover data timing, background maps, ore 3D, analysis presets, portal pairs, Metro networks/journeys, chunk changes, build coach, material plans and platform limits. Existing large ore/crafting/map articles were split; navigation, icons, privacy and troubleshooting were updated. All previous article IDs remain usable.

Both setup guides and their embedded agent copies are synchronized, retaining the independent safety preamble. Old Quest setup menu paths and machine-specific timing/worker claims were removed from current help; historical changelog entries remain historical.

Automated checks cover catalog validity, all navigation topics, category order, bilingual nonempty content, related links, both-language search, no-results/selection fallback, paragraph/list rendering and embedded setup equality. `Tests/README-help.md` records reproduction and remaining interactive cases. Representative render evidence is local, synthetic/help-only and is not a screenshot of a personal world.

Build, packaging and actual acceptance results are recorded in [the integration register](INTEGRATION-2026-09-11.md). No installation, publication, savegame modification, device access or cross-platform redesign is implied.
