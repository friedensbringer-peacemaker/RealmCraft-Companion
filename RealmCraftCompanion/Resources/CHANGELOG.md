# 1.7.54 · Public documentation workflow · 2026-09-13

- Add a bilingual public-documentation skill to Assistant instructions and a project-wiki link. Generate the English wiki from existing help with stable topic links, version/source manifests and a versioned screenshot gallery. Keep screenshot capture isolated to the approved demo; capture provenance and exact image checksums are reviewed separately.
- Include bundled skill texts in the central translation catalog and package the wiki generator and audit launcher with the source. Generation writes a fresh candidate and does not publish automatically.

# 1.7.54 · Recipe Markdown for agents · 2026-09-13

- Add complete single-guide Markdown saving and copying for all recipe variants and obtaining entries. Export the chosen quantity for single recipes and one batch per recipe in combined selections; retain grids, prerequisites, steps, special cases and source limitations.
- Persist independent personal-verification and AI-export checkboxes per recipe variant or obtaining item. Changed bilingual instruction content or provenance invalidates the personal confirmation; shared guide families do not share checkmarks.
- Add a selection overview, bulk addition of currently personally verified guides, a verified-only list filter, and complete Markdown/JSON inclusion in AI export. Missing selected instructions block export; malformed local preferences are preserved for recovery. Update bilingual help and the central translation catalog.

# 1.7.53 · GitHub feedback · 2026-09-13

- Add copy-ready GitHub Markdown for bugs, data corrections and feature requests. Copy the title separately or copy the description and open the project’s blank issue form. Sign-in, review, attachments and submission remain in the browser; no token or automatic issue creation is used.
- Keep report text out of URLs and limit automatic GitHub metadata to app version, operating system and language. Entry context, source links and attachments remain excluded; user-written text still requires review before public sharing. Preserve Mail, ZIP export and unsaved-draft protection.
- Update bilingual feedback help and the central translation catalog.

# 1.7.52 · Tectonicus map space and mirroring · 2026-09-13

- Give the Tectonicus map the main workspace. Keep Backup, Render, Help, a next-render summary, consent and active progress visible; move camera/detail/area controls into Render settings and source/result metadata into the information popover. Reuse the shared header, popup, button and source components with a narrow-width fallback.
- Mirror the tile grid and world projection together by default. Existing renders update on opening, without rerendering or modifying tile files. Support immediate mirror on/off, aligned markers and world-coordinate links, readable controls and a compass drawn from projected world axes. Camera angle/elevation changes still require a new render.
- Update bilingual help and the central translation catalog. Synthetic coverage includes existing-viewer upgrades, projection round trips, tile boundaries, explicit links, mirror opt-out and repeated loading.

# 1.7.51 · Obtaining guides and recipe filters · 2026-09-13

- Add 22 bilingual obtaining guides covering 170 catalog entries, including lava/water/milk/fish buckets, obsidian, concrete, logs, stripped wood, leaves, saplings, potted plants, creature drops and spawn eggs. Show prerequisites, steps, mode/tool differences, reusable containers and scoped sources; link back to existing prerequisite recipes.
- Put recipe filters in a popover beside list search, following the Quick find filter entry point. Keep match/active-filter counts with the list, add obtaining and still-open coverage, and distinguish resetting filters from clearing search as well.
- Reuse obtaining instructions in conversation retrieval and copied guides. Keep collection, conversion and random drops separate from crafting quantities and material-plan arithmetic. Capture changed UI, help, data and release documentation in the central translation catalog.
- Reference coverage is not confirmed RealmCraft VR availability. No Quest test, complete game-content inventory, Android/web synchronization or public release is implied.

# 1.7.50 · List-scoped search · 2026-09-13

- Default new Tectonicus renders to a top-down view with north at the bottom, matching Atlas at 180° (View from: North; Elevation: 90°). Apply the same defaults in the render worker and CLI, retain saved camera choices and legacy result metadata, and update the bilingual help and translation catalog. Existing tile maps require a new render to change perspective.
- Follow the Savegames search placement in Build guides, Videos, Crafting/Recipes, Mobs, Chests, Help, Assistant instructions and Links/Knowledge: search stays above its own result list, outside the scrolling rows, instead of occupying page-header actions.
- Preserve existing queries, filters, selection/draft bindings and lookup routes. Keep search available when Mobs or Chests has no matches. Single-column knowledge sections retain search immediately above their content; global Quick find and map-specific search keep their existing scopes.
- Full native keyboard and VoiceOver acceptance remains open. No savegame changes or platform synchronization are included.

# 1.7.49 · Map and layer controls · 2026-09-13

- Prepare the public universal macOS release from sanitized source. Exclude generated analysis caches from publication and the bundled source archive; keep the approved demo as a separate checksum-pinned download.

- Refreshed bilingual help against current navigation: move specialist topics to More tools, preserve existing IDs, add Metro auto-planning, terminology and translation-contribution guidance, and update map/layer controls and type-first crafting. Synchronize the central translation catalog with the help changes.

- Put Backup and a compact Area selector on one row when space permits. Area shares the Generate map action's width and trailing edge; narrow windows stack the controls. Keep a visible saved/not-live status and move detailed source metadata and rendering caveats into an information popover. Optional completion notifications remain available in the page options menu.
- Show a small, single-line map title using the selected backup's readable name. Keep technical identifiers in Map details without changing map, marker or cache identity.
- Prioritize the selected ore layer with a large editable Y value, equally sized Lower/Higher actions, slider and arrow-key navigation. Keep the layer control as a pinned section header and expose it outside the enlarged 3D viewport's scroll area. Distinguish selected Y from the actual rendered 3D height range.
- Support the mouse wheel and standard two-finger trackpad scrolling over the layer row. Accumulate small trackpad deltas, throttle repeated steps and ignore inertial tails. Respect the measured/interesting-layer filter and stop at the first/last layer; ordinary map zoom and page scrolling outside this control remain unchanged.
- Preserve the normal library, existing saves and the previous 1.7.48 stable baseline. The implementation stage did not include Quest writes or public publication; see the release preparation note above. Component geometry and synthetic navigation checks do not replace physical-device and full keyboard/VoiceOver acceptance.

# 1.7.48 · Stable · 2026-09-13

- Promote the integrated 1.7.47 candidate to the user-approved local stable baseline for Apple Silicon and Intel. Preserve its tested application code, including shared field/action alignment, calmer screen layouts, Ore zoom controls and the Metro network assistant.
- Use the normal Companion profile and existing savegame library, not the isolated audit/demo launcher. No savegame format migration, automatic device transfer or replacement of existing saves is part of this promotion.
- Retain backup/restore confirmations, draft protection and all Beta/unverified-content labels. Stable is the selected local release baseline, not a claim that every feature or native workflow has completed acceptance; full keyboard, VoiceOver and loaded-screen checks remain open.
- Previous candidate notes below describe their historical pre-installation state. This promotion does not publish a GitHub release or synchronize other platforms.

# 1.7.47 · Development candidate · 2026-09-12

## Metro network assistant candidate · 2026-09-13

- Add an automatic planning mode beside manual Metro editing: concentric square rings, Nether/Overworld target pins, or both. Place multiple targets on the existing shared map or enter exact coordinates and height; rename/remove pins before generation.
- Compare three selectable geometric proposals: minimum-length connection tree, symmetric rings/axes with right-angle branches, and rings/axes with nearest-station branches. Preview the chosen network on the existing schematic or Atlas without writing it; apply explicitly through draft protection and optimistic storage checks.
- Propose portal sites at new stops, retain all existing stations/links unchanged, and leave every new directed rail link planned with unknown travel time. Resolve surface destinations only through existing confirmed, measured portal observations; unresolved surface targets stay disconnected. No portal scale, terrain-safe alignment, fastest-route guarantee or game build is implied.
- Report proposed rail length, new stations/portal sites and line-change nodes as construction comparison aids, not a verified materials bill. Automatic rail detection, terrain-aware optimization and game-mechanics verification remain follow-up work. This source/test candidate is not installed or published.

## Screen density candidate · 2026-09-13

- Refine Player alignment: Device and Savegame split the Read player action width equally; backup/world selection ends at that action's right edge, also after header wrapping.
- Apply the action-edge rule to shared source selectors, Maps area and Tectonicus options. Exclude Help/overflow, retain full width when no action exists, and keep equal segments for Ore sections and compact Metro navigation.

- Give all labeled header actions the same 180 × 32 point size, including secondary actions and Help; retain square icon controls and the narrow-window fallback. The action-edge rule above supersedes the earlier full-content-width backup layout.
- Align form selections through a shared label column instead of each label's text width. Apply it to Metro connections and related editors, source/area options, ore references and video filters; stack labels above controls in narrow panes.
- Align shared backup controls to the leading edge, separate Player source rows, top-align Map/Metro/Chest controls and remove Player's empty idle status row.
- Reduce secondary detail-heading size; widen illustrated browsers and Help topics. Give Metro equal coordinate fields and a bounded editor width; keep tab controls on the content grid.
- Show concise video rows and summaries first. Keep original metadata, preview, listening and export controls in named disclosures; preserve visible review/platform warnings and a Stop button during speech.
- Separate optional map notifications, random ore sampling, trial comparison/journal/results and catalog background information. No feature, draft protection, save/restore confirmation or data rule is removed. Trial sections are expandable, not a new validation wizard.
- Update DE/EN help and the central translation catalog. This isolated candidate is not installed or published; full native interaction and accessibility acceptance remain open.

## Library alignment candidate · 2026-09-13

- Align common page-header Help and action controls in one row when space permits; retain the narrow-width fallback and visible page purpose.
- Widen the backup browser, standardize its search/footer insets, reduce detail-title emphasis and place preview and facts together. Narrow detail panes stack; missing previews leave no reserved image column.
- Give detail facts and status labels a stable icon column, use the shared panel inset and equal square refresh/delete controls, and omit the empty idle status footer. Existing backup, restore, deletion and status-check behavior is unchanged.
- This is a source/test candidate, not an installed release. Complete live screen, scrolling, keyboard and VoiceOver acceptance remains open.

## Ore viewport and zoom candidate · 2026-09-13

- Ore 3D has its own close-inspection zoom range; repeated zoom-in clicks no longer stop after the first step. Guide previews retain their original full-build limits. Saved close-up cameras round-trip without losing their zoom.
- Fit the actual slice bounds to both viewport axes. Add Fit to view, explicit zoom-limit states and tooltips; keep Reset view separate from the saved camera. Standard and large views share the same camera state.
- Compact the Ore header without removing Help, backup selection, game-file time or the not-live warning. Technical source/result details remain expandable. Align layer controls, use the available content width, remove the empty idle status lane and show the selected height beside the distribution slider.
- Update the bilingual 3D help and central translation inventory. This is a separate test candidate, not an installed release. Mining-trial redesign, reference simplification, treemap and complete live UI acceptance remain follow-up work.

## Community translation tooling · 2026-09-12

- Add a central DE/EN translation inventory with context, source fingerprints, target-language draft/review states and explicit extraction gaps. Include interface terms, recognized Swift pairs, structured knowledge catalogs and bilingual setup/transfer documents.
- Add offline JSON language-pack export and conflict/placeholder-checked import into a new candidate; retain untranslated, stale and retired content for review. No source code is executed or rewritten by imports.
- Generate existing native `tr()` DE/EN resources from the central catalog, preserving current text and allowing reviewed English overrides. Other catalog entries and additional locales remain preparatory until their runtime adapters are implemented.
- Document community and agent contribution rules, GitHub review/CI commands and the proposed native import/export/share workspace. Include the tool and catalog in the source package; no installation, GitHub publication or locale activation is part of this tooling change.

## Type-first crafting and matching navigation · 1.7.47 (69) · 2026-09-12

- Crafting's item browser groups known item types before sorting material/color variants within each type, using explicit longest-match ID suffixes and DE/EN family headings. Ordinary boats, chest boats, rafts, fence gates, trapdoors, pickaxes and other distinct types remain separate. Unknown/special items keep their full title and independent identity. This changes presentation only: original item IDs, icons, recipe alternatives, filters, material-plan targets and evidence remain unchanged. Global Quick find and other ingredient pickers retain their existing search order.
- The Home explanation “What each section does”, sidebar and Go menu now share `CompanionNavigationGroup`. The overview includes matching group headings and Help, with specialist tools last. All 20 destinations and their original shortcut assignments remain intact. Metadata lives in `Sources/CompanionFeature.swift` so order and help-target regressions can run without the app model.
- No RealmCraft crafting mechanic was verified by this change. The bundled comparison recipes distinguish oak, birch and acacia boats and their corresponding planks; grouping does not make their ingredients interchangeable.

# 1.7.46 · Development candidate · 2026-09-12

## Usability implementation · 1.7.46 (68) · 2026-09-12

Mac source candidate. This implements a first coherent package from UX-008–017, not every proposed screen redesign.

- **UX-015:** Metro connection editing now authorizes the transition inside the shared `editEdge` entry point. Both station and line links use it; Cancel or failed Save does not replace the draft.
- **UX-008/009:** persistent top sidebar search, four real category filters, grouped direct results, keyboard shortcut and explicit no-result/missing-catalog states. Feedback remains bottom-left. All 20 destinations and existing raw IDs/Go shortcuts are retained; five specialist tools use an expandable group that opens on direct navigation. Home leads with four task entries and offline/import/Quest options when no backup exists. Import is also visible in the library header. These new navigation entries start no transfers or rendering.
- **UX-010/012/014 (partial):** shared page-purpose/help row opens stable topic IDs through the draft guard. Source details separate technical IDs from game-file time and not-live status, now including Conversation. Localized world/backup, assistant-instruction and creature labels; actionable AI-export blocked reasons and an empty-network Metro sequence.
- **UX-011/013/016 (partial):** recipe filters collapse while counts/reset and evidence stay visible; unavailable historical metrics move into a labeled disclosure. Reviewed guide materials transition to the plan in the same sheet instead of opening a nested plan sheet. Explicit Save, provenance, bounds and recipe choices remain. Feedback participates in draft protection: successful ZIP export saves report/images, Cancel/errors retain the draft, Discard clears it; the mail recipient is not stored in ZIP and no mail is sent automatically.
- Help retains all 48 bilingual topics and existing IDs. Navigation, search, source, material and feedback workflows were updated; setup and embedded agent copies use the same current menu paths. No savegame schema, game content, world/library data, device write or publication changed.

Remaining: full Atlas/Ore progressive disclosure, portal/chest task flows, broader knowledge-filter harmonization, further dialog/VoiceOver/contrast work, and new-user task observation. The separate Metro/terrain adapter (UX-007) and Android/web parity are not part of this package. Native full-app task acceptance and installation remain separate from compilation, model tests and isolated component renders.

# 1.7.44 · Development candidate · 2026-09-12

## UX integration · 1.7.45 (67) · 2026-09-12

Implemented in the macOS source candidate; installation and native end-to-end acceptance remain separate.

- Shared `SourceContextBar` replaces duplicate backup pickers in Metro, portals, ores, Maps, Tectonicus, Chests, Player (backup mode), Statistics, Editor and AI export. It distinguishes backup time, game-file time and optional dimension/result time using the existing Savegame model.
- A per-model `DraftTransitions` registry guards source/workspace transitions, protected feature selections/reloads, setup opening, main-window close and application termination. Metro, portal and ore-trial drafts and material plans participate. Save failures and Cancel block navigation; Discard restores persisted state. Other editors retain their existing policies. Portal metadata additionally rejects stale concurrent writes.
- Page headers adapt to narrow widths. Metro switches its three panes below 1080 points of workspace width. Ore 3D, Feedback and Build coach use bounded flexible sheets. Travel modes are localized; portal/ore notices share text, icon and severity. This is partial consistency work, not an accessibility certification.
- Quick find (Cmd-Shift-F) reuses four local catalogs and opens exact recipe, build-guide, video or help IDs after clearing destination filters. Searching starts no scan, playback or AI request. Opening a video destination may load its normal online thumbnails.
- Reviewed build-guide materials can be added to the existing crafting plan. Only explicit unambiguous item IDs and exact bilingual quantities are preselected. Users resolve uncertain rows; omitted rows and original values remain in provenance. Existing recipe choices are preserved; explicit Save plan is required. No stock deduction, recipe verification or cross-platform synchronization is implied.
- Help now contains 48 bilingual topics, including Quick find and the new source/draft/material workflows. All previous topic IDs remain valid.

Remaining: native keyboard/focus/window-close and nested-sheet acceptance, minimum-window Metro interaction, long source titles, VoiceOver/contrast, remaining editor/status consistency, and UX-007's separate Metro/terrain navigation adapter. Android/APK/web parity is not claimed.

- Refresh the macOS help around all 20 navigation destinations: 47 DE/EN topics, retaining every existing article ID. Add dedicated portal/Metro journey, ore 3D/preset, background-map, chunk-change, coach, material-plan and data-scope guidance.
- Extract a validated bundled help catalog, add related-topic/back navigation and bilingual token search, and prevent stale articles when searches have no results. Keep setup links on relevant support pages and improve Classic-theme heading/list readability.
- Synchronize setup, manual-transfer and embedded agent instructions; preserve agent safety boundaries and remove obsolete menu paths and machine-specific timing claims.
- Record a whole-navigation UI/UX audit and prioritized source-context, draft-protection, responsive-layout and integration work. Add catalog/search/parser and production-content rendering checks. Non-help feature code, installation and publication remain unchanged.

# 1.7.43 · Development candidate · 2026-09-12

- Show optional item icons throughout recipe lookup, ingredients/alternatives, recipe grids, plan targets, supply totals, production outputs and Conversation search. Reuse installed packs and global text-only preference, expose existing icon settings directly, and use a neutral placeholder for missing mappings without replacing item names or quantities. No automatic asset download.
- Integrate the extended catalog into Conversation · Beta: quick name/ID search, common plurals and joined names, quantity questions, explicit numbered recipe variants, short spoken explanations and saved-material-plan reading. Preserve the separate ten-recipe owned-stock checker and local-only interpretation boundary; no new cloud service.
- Add a local multi-target material plan to Crafting / Recipes. Sum direct ingredients or expand intermediate products, aggregate shared demand before whole-batch rounding, and show production order and surplus.
- Require choices for recipe variants and ingredient alternatives. Allow explicit supply/stop expansion; withhold totals for cycles, unresolved choices, changed catalogs or safety limits. Missing recipes are not treated as proof that an item cannot be crafted.
- Save one companion-only plan with atomic optimistic writes and a separate lock. Copy or explicitly export quantities, chosen ingredients, source hashes and unverified-comparison caveats. No personal stock deduction, fuel estimate, device access or savegame writes.
- Extend synthetic planner/storage regressions and bilingual help. Installation, full interactive acceptance, platform parity and verified RealmCraft recipes remain separate.

# 1.7.42 · Development candidate · 2026-09-12

- Add a larger ore cutaway view, locally saved relative camera presets and PNG export with baked-in height/coordinate bounds, measurement date, material legend and coverage context. Export is explicit and local; no world data is published.
- Inspect six-face material connectivity across the measured spatial volume. Highlight the visible slice, report count and height range, and flag measurement boundaries, missing neighbors and the 65,536-block safety cap. Variants share their existing material group; adjacency is not a natural-generation or safe-access claim.
- Add opt-in macOS map-completion notifications while Companion is in the background. Ask for system permission only on explicit activation, suppress foreground/duplicate notices, preserve coverage-gap wording and keep world names/coordinates out of system messages. Existing in-app completion and Open map survive denied permission or delivery failure. Cancellation and Tectonicus do not trigger these notices.
- Extend synthetic connectivity, camera/export and notification lifecycle tests and bilingual help. Installation and operating-system permission/banner acceptance remain separate from development verification.

# 1.7.41 · Development candidate · 2026-09-12

- Add a native 2D/3D switch to Ore frequency layer exploration. Render the selected layer or a bounded four/eight-layer cutaway directly from existing census data, with shared material colors, selected-only filtering, orbit/zoom/reset and exact block picking for tunnel/Atlas handoff.
- Bound 3D work to movable 64 × 64 sections, build cancellable mesh data off the main thread, retain missing/air/filtered distinctions and hide the view in spoiler-light mode. Reuse the Companion orbit camera; no new savegame decoder, map generation, device access or game-data writes.
- Add bilingual usage guidance and synthetic geometry regressions. Installation and the earlier combined GUI acceptance remain separate steps.

# 1.7.40 · Development candidate · 2026-09-11

- Add an offline Crafting / Recipes workspace with all 1,206 name-catalog entries and 821 Minecraft Java 1.16.5 comparison recipes for 588 outputs. Keep RealmCraft/Quest compatibility explicitly unverified; show field-scoped RealmCraft wiki evidence and missing recipes.
- Add bilingual search and filters, station and yield details, numbered recipe grids, whole-batch quantity calculation, ingredient/back navigation, reverse uses and copyable recipes with source notes. Keep additional fuel separate and preserve the existing ten-recipe conversation scope.

- Save named snapshot-local Metro journeys and manually confirmed progress. Resume only against the recorded network fingerprint; changed networks require replanning.
- Export multi-dimension Metro travel as JSON or Markdown with measured legs, line changes, explicit portal confirmations, recorded geometry and unplanned-access warnings. Keep terrain NavigationPack separate.
- Save and reuse world-scoped ore-analysis presets for inclusive bounds, heights, materials, biome filters and sampling parameters. Applying a preset never copies measurements or starts a scan automatically.
- Compare two verified backups in a north-up chunk-change map with new, changed, missing and identical files, filtering, centering, zoom and JSON export. File changes are not interpreted as block changes.
- Reuse verified unchanged files in follow-up backups and pull only new/changed files. Retain full before/after remote and final local SHA-256 checks; fall back to full transfer for unsuitable bases or broad changes. Record transfer counts separately from world files.
- Render maps on a dedicated background queue using an independently verified temporary input copy. Keep the Companion usable, show a persistent completion/failure notice with Open map, preserve snapshot association across navigation, and block quitting until completion or cancellation. Coordinate shared render-cache access across app instances.
- The prior 1.7.39 interactive acceptance/install step remains deferred by user request. This candidate is not installed or published.

# 1.7.39 · Development candidate · 2026-09-11

- Add map cache size display and confirmed cache cleanup. Generated maps and savegames are retained.
- Add cancellable map rendering with a one-hour timeout, bounded termination, cancellation before result commit and preservation of the previous map. Cancelled runs remove only their own incomplete output.
- Preview and carry forward a Metro network from an older backup of the same world into an empty target network. Recheck source metadata and portal evidence before saving; copy records as planned, retaining names, paths and historical durations.
- Open a measured resource point in Atlas with its snapshot, dimension and exact X/Y/Z. Plan a surface approach using the existing route engine and preserve the resource coordinates and unplanned final access in navigation exports.
- Coordinate resource selection, measurement/navigation, ownership, portal drafts and Metro path capture across activation, Escape, dimension changes and privacy mode.
- Default development builds to fresh temporary bundles; reject existing, symlink and application-installation targets.

# 1.7.38 · 2026-09-09

- Add voxel-derived catalog thumbnails and a focused Build coach with shared 2D/3D previews, local read/repeat/stop, optional speech after Next, and saved viewing checkpoints invalidated when instructions change. Export the full voice-agent briefing with an explicit unconfirmed checkpoint; no microphone, headset observation or automatic progress sync is claimed.
- Add four original modular guides (92–95): timber arch, lit bench, dry light basin and open glass alcove. Each placement action contains at most five identical blocks; quantities, 2D layers and cumulative 3D frames derive from the same geometry. All 95 guides retain untested / AI-generated status.
- Rebuild Nether Metro as an integrated three-pane workspace: searchable stations and line badges, a direction-aware schematic or shared Atlas instance, and contextual station, line, connection and journey editors. Reuse Companion headers, controls and map resources without duplicating terrain tiles.
- Add saved-portal station selection, editable origin-relative name suggestions, a native line color picker, main-portal selection and bounded radial proposals. Show recorded bends in line colors; distinguish captured geometry from provisional straight connectors and planned/built links.
- Add full station/connection editing, explicit station-deletion impact, line removal retaining links, sign-text copying, network JSON export, measured route summaries, line-change counts and manually confirmed journey checkpoints. Keep portal predictions evidence-gated; no 8:1 conversion or automatic link confirmation is used.
- Extend synthetic Metro and Atlas regressions for relative naming, planned radial networks, captured endpoints, missing-height rejection, transformed map picking, stale metadata writes, and transfer counting across unassigned connector legs. Automatic rail tracing and terrain-aware cross-dimension navigation remain follow-up work.

- Rebuild Ore frequency around Explore, Distribution, Reference and Mining trials using the Companion toolbar and section controls. Add a clickable Resource analysis selection mode to the Atlas.
- Explore counted blocks in a north-up layer map with shared multi-material filters, layer/volume totals, coordinate inspection, bounded layer connectivity and direct tunnel-planner handoff. Skip to layers meeting a configurable material threshold.
- Compare multiple materials with unsmoothed lines, a height/material heatmap or per-layer bars; preserve missing-data gaps, explicit denominators, biome filters and Top 3 rankings.
- Compare geographically arranged 16×16 and 64×64 areas, preserve visible gaps and coverage fractions for missing chunks, select a tile for closer measurement, and group the trial planner, evidence and results into one workflow.
- Store bounded spatial data separately from immutable snapshots; keep earlier measurements readable. Extend synthetic tests for binary axis order, clipping, missing cells, material totals, connectivity, area aggregation and Atlas selection/cancellation. Refresh German and English help.

# 1.7.37 · 2026-09-07

- Fix Quest restore failures caused by adbd attempting to create missing directories in scoped game storage. Prepare all payload directories through the authorized shell before push.
- Set and check group-writable save-file permissions in bounded batches before activation, including when local files use read-only deduplicated storage. Preserve the original world on preparation, transfer, or permission failure.
- Add synthetic regression coverage for nested folders, canonical target paths and permission failures.

# 1.7.36 · 2026-09-07

- Replaced free SceneKit camera movement in player and skin previews with a fixed-center orbit. Trackpad gestures can no longer pan the character out of view; tilt and zoom are bounded to keep the whole model visible.
- Added Reset view beside Choose skin and inside the skin editor. Reset restores the default rotation and zoom without changing the selected appearance.
- Player now starts with local savegames when no device is available and falls back on disconnect. Source selection, player device provenance and sidebar connection labels use Device instead of assuming a Quest model.

## 1.7.35 · Ore frequency and mining research

- Added the first comprehensive code audit, central feature map, architecture/data-model documentation and a stable-ID comparison of the layer-analysis, shared-map, Nether-metro and developer-index ideas. This is documentation and backlog alignment, not implementation of the missing features.
- Code size milestone: the current 1.7.35 source snapshot contains 20,491 non-empty source lines: 16,483 application lines, 3,738 test lines and 270 build/tool lines. Counts include comments and embedded text in source files; exclude blank lines, standalone documentation/data, assets, dependencies, backups and app/build copies. Reproduce with `python3 count_source_lines.py`.

- Count ore blocks directly from local v9 chunks, with inclusive region bounds, reproducible random spatial samples and horizontal biome-cell breakdowns. Report missing/corrupt chunks separately; verify backup checksums before and after each run.
- Show per-height counts, explicit all-position/non-air denominators, interactive height inspection and dynamic Top 3 rankings with tie indicators. Save private measurement history separately from snapshot files.
- Add offline, sourced Minecraft Java 1.17.1 and 1.21.1 reference catalogs covering eleven ore/resource groups and their deepslate variants. Height transformations remain explicit hypotheses; attempts and configuration sizes are distinguished from realized ore counts.
- Add tailored mining-trial procedures, fixed-volume before/after comparisons, explicit chest/sign evidence and item deltas. Preserve trial revisions; reject overlapping accepted samples and keep blank observations distinct from zero finds.
- Pool completed compatible trials by height band, biome and game version using summed ore counts and measured denominators. Label rates as empirical and per-run ranges as descriptive, not confidence intervals.

## 1.7.34 · Map-based portal planning

- Added a portal layer to the atlas with distinct saved, planned and calculated counterpart markers. Saved portals are read from the selected snapshot; planned markers remain separate local metadata.
- Select a map point and choose “Plan portal here”, preview the reciprocal X/Z position and save the plan directly in Portal pairs. Either dimension can be the starting point; the map also supports planning outside saved terrain coverage with an explicit unknown-site label.
- Show exact counterpart coordinates and a nearest-block suggestion using an explicitly assumed 8:1 horizontal scale. Target height, actual arrival and portal linking remain unverified. Map orientation does not change the coordinate calculation.
- Preserve plans per snapshot and report persistence failures; existing directed travel records remain separate from planning estimates. Browser-only plans stay in that browser and are not automatically synchronized with Companion.

## 1.7.33 · Portal pairs

- Completed editorial preparation of all 197 registered videos with the final panda short, update 0.8 overview, motion-mining preview and cow joke clip. Added bilingual summaries, ten timestamped entries, relevant links and eight Markdown exports. These four use limited visual samples; music-only captions and tiny storyboard limits are documented. Catalog completion does not imply full video viewing or full transcript availability.
- Added a dedicated Portal pairs area with snapshot selection, saved portal coordinates and active-area bounds from POI records.
- Record named, directional connections with evidence notes in separate local metadata; changed portal data invalidates saved associations. Observed connections remain distinct from inferred destinations, and reverse travel is not automatically confirmed.
- Coordinate conversion and map-based Nether travel planning remain in the backlog; no universal RealmCraft scale or link radius is claimed.

## 1.7.32 — Tectonicus perspective and automatic framing

- Added the 0.8.70 motion-mining short, historical Naruto-style animation bug and pig-riding development preview with bilingual summaries, five timestamped entries and six Markdown exports. The catalog now has 193 reviewed contributions out of 197. No captions are available; two clips expose only tiny storyboard images, so control details and bug reproduction remain unverified. Later-release context is linked.
- Added the Redstone teaser and 0.8.70 boat/pig-riding and lead shorts with bilingual summaries, nine timestamped entries, update-video links and six Markdown exports. The catalog now has 190 reviewed contributions out of 197. All three use visual samples; unrelated entertainment and advertising captions are excluded from gameplay search. Promotional staging and description-only controls are clearly attributed.
- Choose one of eight camera directions and four elevations before rendering. Automatically remember the settings across app restarts, record them with each output and show the perspective used for the displayed map.
- Automatically center and zoom Tectonicus maps to the exported area and available viewer size, with space around the terrain. Applies to existing Companion renderings without rendering again.
- Preserve explicit position/zoom links and manual navigation after opening the map.

## 1.7.31 — Tectonicus rendering workflow

- Added official fishing, mob-takedown and minecart shorts with bilingual summaries, nine timestamped entries, detailed-video links and six Markdown exports. The catalog now has 187 reviewed contributions out of 197. All three have no captions and use clearly limited visual samples. Catch outcomes, combat values and rail-building procedures are not inferred from promotional footage.
- Added the original official promo, 1.0.0 short and fishing announcement with bilingual summaries, nine timestamped entries, tutorial links and six Markdown exports. The catalog now has 184 reviewed contributions out of 197. Fishing uses its full available original transcript plus samples; the other two entries are visual-only. The historical reeling joke is distinguished from current functionality, with links to detailed fishing and world-sharing tutorials.
- Current source snapshot milestone: 18,782 non-empty lines — 15,048 application, 3,464 tests and 270 build/tools lines across 181 files, measured with `count_source_lines.py`. Includes comments and embedded text; excludes documentation, assets, dependencies and build copies.
- Added official mob-visual changes for 0.9.72, panda animations for 0.8 and the updated 2025 promo with bilingual summaries, nine timestamped entries and six Markdown exports. The catalog now has 181 reviewed contributions out of 197. All three use visual samples and official descriptions; available music-only caption tracks are excluded from gameplay search. Animation changes are distinguished from unverified gameplay mechanics.
- Added the first two Dobbi 53 episodes and the official store trailer with bilingual summaries, 13 timestamped entries, cross-links and six Markdown exports. The catalog now has 178 reviewed contributions out of 197. Player episodes use full available German transcripts plus visual samples; the trailer is a visual-only feature overview. Navigation conventions, tool observations and promotional scenes are clearly distinguished.
- Added a dedicated Tectonicus section with savegame and area selection, detail levels, automatic setup, progress, cancellation, an embedded map and browser/Finder actions.
- Download and verify Tectonicus 2.31, Minecraft Java 1.17.1 resources and a signed, notarized Temurin Java 21 installer. Prepare private Python tools when required; keep Java in Companion storage. Resource downloads require the user's Minecraft Java ownership and download confirmation.
- Export observed v9 Overworld chunks to a separate rendering intermediate, preserve each run and verify source savegames before and after rendering. Restore the latest successful map for each selected backup.
- Clearly report approximate block states, lighting and biomes, omitted entity/sign data and magenta unknown-block placeholders. Nether and playable-world conversion are not supported.
- Added bilingual help and synthetic regression tests for block packing, negative coordinates, source hashes, special block defaults and input/output guards.

## 1.7.30 — Help refresh and public release

- Added Dobbi 53 diamond-search parts 5, 2 and 1 with bilingual summaries, 15 timestamped entries, cross-links and six Markdown exports. The catalog now has 175 reviewed contributions out of 197. All three use full available original German transcripts plus visual samples. The glow-squid false lead, torch crafting and inventory management are distinguished from unverified game-mechanic claims.
- Added chicken feeding reactions, mining hub pathways and Dobbi 53 diamond hunt part 6 with bilingual summaries, 13 timestamped entries and six Markdown exports. The catalog now has 172 reviewed contributions out of 197. Two entries use full available original transcripts plus visual samples; the chicken short is visual-only. Chest loot and unverified player speculation are distinguished.
- Added a bilingual, searchable 41-entry Minecraft/RealmCraft VR content checklist under Links & Knowledge, grouped alphabetically by topic. Each entry records its evidence, VR version and review date (7 September 2026); planned, in-progress, partial and unconfirmed features are distinguished from confirmed absence. Added a dated source snapshot and repeatable release-review instructions.
- Added a nighttime cart ride, new-world diamond-search test and jungle walkway conversion with bilingual summaries, nine timestamped entries and six Markdown exports. The catalog now has 169 reviewed contributions out of 197. All three entries use limited visual samples without local transcripts; later reported diamond yield is distinguished from the sampled footage.
- Added two ore-restocking episodes and a short minecart ascent with bilingual summaries, nine timestamped entries and six Markdown exports. The catalog now has 166 reviewed contributions out of 197. All three entries use limited visual samples without local transcripts; no performance, yield or speed measurement is implied.
- Added the first Nether trip, a slime/disc search and snowy-biome rail conversion with bilingual summaries, nine timestamped entries and six Markdown exports. The catalog now has 163 reviewed contributions out of 197. All three entries use limited visual samples without local transcripts; description claims and observed scenes are distinguished.
- Added tunnel construction episodes 1–2 and Nether trip episode 3 with bilingual summaries, 11 timestamped entries and six Markdown exports. The catalog now has 160 reviewed contributions out of 197. Two tunnel episodes have limited visual-sample coverage; historical recording and backup claims are explicitly qualified.
- Added underwater tunnel episode 3, a sand-search trip and a savanna ore trip with bilingual summaries, 11 timestamped entries and six Markdown exports. The catalog now has 157 reviewed contributions out of 197. Two material trips have limited visual-sample coverage without local transcripts; observed scenes are distinguished from metadata claims.
- Refresh German and English in-app help for current Maps, Skills, AI export, video browsing and interactive build guides. Add a dedicated route-planning/navigation chapter in the Maps group and align the AI help order with the sidebar.
- Correct map rotation to 90-degree steps; explain remembered orientation, sign labels, navigation clipboard/iCloud handoff and section-based spoken guidance without claiming live position tracking.
- Document collapsible guide panels, synchronized 2D/3D steps, optional icons, partial legacy models, voice-agent prompts, video sorting and selective context exports.
- Include source-package image assets, reference text and the line-count tool so the bundled source archive retains its build inputs.
- Reconcile completed presentation work and remaining validation/porting tasks in the Backlog, and refresh the public project description and build instructions.

## 1.7.29 — Show sign text with the Signs layer

- Added underwater tunnel episodes 4–6 with bilingual summaries, 11 timestamped entries and six Markdown exports. The catalog now has 154 reviewed contributions out of 197. Episodes 4 and 6 have limited visual-sample coverage without local transcripts; episode 5 distinguishes enclosure, clearing and provisional lighting.
- Added tunnel construction episodes 7–9 with bilingual summaries, 11 timestamped entries and six Markdown exports. The catalog now has 151 reviewed contributions out of 197. Episodes 7 and 9 have limited visual-sample coverage without local transcripts; the reported tunnel connection is attributed to the description.
- Simplified build guides with collapsible materials, audio, display options, legends and test details. Page scrolling no longer changes the 3D camera. Doors use matching upper/lower artwork in both previews; slabs and stairs show occupied side shapes and scaled 3D surfaces, beds form one mattress with one pillow, and fence gates use posts and rails.
- Added underground minecart construction episodes 10–12 covering final track sections, test rides, stair detailing and lowered lanterns. Includes bilingual summaries, 15 timestamped entries and six Markdown exports. The catalog now has 148 reviewed contributions out of 197; historical bugs and recording issues are explicitly qualified.
- Display sign labels immediately when Signs is enabled, without selecting each marker. Keep search filtering, dimension and spoiler visibility rules; clicking still opens the full inscription and coordinates.

## 1.7.28 — Copy and iCloud navigation export

- Show generic solid build supports with the cobblestone texture (catalog ID 12), while explicitly allowing other suitable full blocks and retaining guide-specific material requirements.
- Added two Nether TNT mining episodes and an underwater pod remodeling episode. Includes bilingual summaries, 15 timestamped steps and six Markdown exports. The catalog now has 139 reviewed contributions out of 197; subjective hardware claims, stock counts and unfinished lighting are explicitly qualified.
- Added the first two pyramid construction episodes and a gunpowder/TNT mining episode. Includes bilingual summaries, 15 timestamped steps and six Markdown exports. The catalog now has 136 reviewed contributions out of 197; revised building dimensions, unfinished interiors and reported workarounds are explicitly qualified.
- Constrained build-preview controls to centered orbit and bounded zoom with explicit rotate/tilt/zoom/reset buttons; framing adapts to viewport size and free panning is disabled. Added ten shared build-guide topics and reassigned all 91 guides by primary purpose.
- Added three reviewed videos covering external HTML mapping, diamond mining and wolf/TNT housekeeping with stonecutter bulk crafting. Includes bilingual summaries, 15 timestamped steps and six Markdown exports. The catalog now has 133 reviewed contributions out of 197; external-app controls and old versus new ore discoveries are distinguished.
- Added interactive 3D build previews with shared step controls, orbit/zoom, block picking, camera reset, optional pack textures and a height cutaway. Includes 72 complete, projection-checked construction sequences and 19 explicitly labeled legacy slice models; geometry remains schematic and does not simulate game mechanics.
- Added three reviewed videos covering quartz/glowstone preparation, fishing-lake experiments and a shipwreck journey with black wolves. Includes bilingual summaries, 15 timestamped steps and six Markdown exports. The catalog now has 130 reviewed contributions out of 197; off-camera events, external mapping and inconclusive recording tests are identified.
- Added a persistent Symbols / Block icons switch for build plans, step diagrams and legends. Uses the selected optional icon pack with explicit catalog IDs, retains placement symbols over textures, and falls back to schematic cells for unavailable or unmapped artwork.
- Copy the complete navigation briefing directly to the clipboard or save it to a remembered iCloud folder from Maps. Configure a separate navigation export destination under Settings → Map export, also available in the Maps actions menu. Cancelled folder selection leaves the route intact; every cloud export gets a new file.

## 1.7.27 — Longer spoken navigation sections

- Added twelve architecture and interior guides: modern glass and timber facades, glazed gable roof, pergola, living room, dining room, kitchen, bedroom, library, entrance hall, dry bathroom decor and window planters. Includes precise material quantities, layered construction, exterior elevations and voice-agent exports; decorative furniture is distinguished from functional game blocks.
- Group detailed route manoeuvres into spoken confirmation sections targeting 75 blocks (normally 50–100), or about 25 around critical cues. Preserve all exact turns, coordinates and transport transitions as references; never treat a section endpoint as a straight shortcut. Apply the same cadence to direct Markdown and AI Markdown/JSON exports, including previously saved routes.

## 1.7.26 — Ready-to-use navigation instructions

- Added sixteen separate practical build modules covering the twelve requested additions: storage and workshop rooms, tunnel bend and rise, panorama gallery, bridge junction, four treehouse furnishing modules, rest stop, outpost, mine stairs, animal shelters, moat observation corridor and architectural style samples. All include counted materials, complete layers, exterior views, modular connections and voice-agent handoffs.
- Added ten independent build modules: underwater junction and living room, spiral stair tower, biosphere garden, boathouse, lighthouse, tree-village junction, mountain switchback, irrigated terraces and station hall. Includes counted materials, layered plans, exterior elevations, manual operating limits and bilingual voice-agent handoffs.
- Added three reviewed videos covering the Nether portal corridor and two mining hub fencing phases, with bilingual summaries, 24 timestamped steps and six Markdown exports. The catalog now has 97 reviewed contributions out of 197; off-camera builds, unfinished connections and unverified mechanics are explicitly identified.
- Include an English, step-by-step assistant briefing in direct navigation Markdown and general AI Markdown/JSON exports, including routes saved before this update. Confirm position and facing, wait for arrival, and stop on obstacles or deviations; optional POIs remain grounded in the supplied data.

## 1.7.25 — A shared actions menu on every page

- Added three reviewed RealmCraft videos covering the savanna rail loop, small tree/wheat farm and Nether railway, plus the requested external QuestCraft 6.0 comparison. Includes bilingual summaries, 32 timestamped steps and eight Markdown exports; 94 reviewed contributions out of 197. Incomplete builds and historical compatibility claims are explicitly identified.
- Added three reviewed videos covering Nether magma gathering, Mine 3 construction and Mine 1 tunnel preparation, with bilingual summaries, 24 timestamped instructions and Markdown exports. The catalog now has 90 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Use readable face-adjacent sign text as individual chest names in Chests, maps and conversation stock answers; preserve manual names, keep coordinates visible and omit conflicting inscriptions. Refresh names when rescanning or rebuilding maps.
- Always show the same trailing actions menu in every main-page header, including pages without contextual actions.
- Include the running version, project GitHub link and the shared general settings submenu; preserve contextual actions and their individual availability.
- Keep general menu entries available when page data has not been loaded, and consolidate mob appearance/report actions into the common menu.

## 1.7.24 — Clearer chest controls and visible version

- Add video sorting by upload date, original title, channel and duration. Default to newest uploads first; Reset restores this order.
- Simplify the Chests toolbar to aligned source and search rows; group ownership and material options in the Filters popover, retain visible filter summaries, and align filter/sort controls with page actions.
- Show the running app version below the Companion name in the persistent sidebar.

## 1.7.23 — Consistent page layout

- Added three reviewed videos covering tree/wheat farm expansion, turtle-area minecart access and mountain tunnel excavation, with bilingual summaries, 25 timestamped instructions and Markdown exports. The catalog now has 87 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Show official YouTube thumbnails, original titles, channel, upload date and duration in video browsing; include original titles and thumbnail links in Markdown exports. Thumbnails load as images without video playback.
- Align all main-page headers, including Home and Editor, on the same fixed title baseline and content inset.
- Give primary page actions a stable 180 × 32 pt slot and reserve the same overflow position; keep player appearance in the actions menu.
- Align source selectors and reading columns, stabilize illustrated list widths, and normalize detail headings and panel spacing.
- Keep compact loading status lanes in Chests and Statistics; let longer player and map messages wrap instead of clipping.
- Place the AI-export save selection above its scrolling options and keep Home activity actions equally wide.

## 1.7.22 — Navigation export and mixed journeys · Beta

- Added three reviewed videos covering ice spike railway completion, snowy route construction and dark oak sapling gathering, with bilingual summaries, 22 timestamped instructions and Markdown exports. The catalog now has 84 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Added three reviewed videos covering Nether exploration, an unsuccessful TNT mining experiment and coral/sea-pickle gathering, with bilingual summaries, 19 timestamped instructions and Markdown exports. The catalog now has 81 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Added three reviewed videos covering continued geode mining, Mine 2 ore cleanup and ore consolidation with furnace operation, with bilingual summaries, 21 timestamped instructions and Markdown exports. The catalog now has 78 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Added three reviewed videos covering amethyst exploration, a woodland mansion tour and manual ore-processing setup, with bilingual summaries, 23 timestamped instructions and Markdown exports. The catalog now has 75 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Add candidate surface-route planning with English turns, height steps, coordinates and walking/boat/minecart transfer cues. No live position tracking; ladder routes and transport mechanics require further validation.
- Include route packets in AI-export Markdown and JSON, scoped to the selected backup. Optional nearby POIs use a 250-block radius and heading-relative offsets; small-island suggestions require a saved-water boundary.
- Let local Qwen through LM Studio select useful supplied step/POI references; validate every returned ID and preserve all original coordinates and route steps. No remote inference service is used.
- Replace repeated unavailable travel-time rows with mixed journey sections, transfer points and known-section subtotals. Missing coverage remains explicit; estimates and infrastructure assumptions are labelled.

# 1.7.21 · 2026-09-06

- Move Skills to the third position under AI tools, after AI export and Conversation; keep navigation menus and the Home section guide in the same order.
- Added three reviewed videos covering ice fishing and camp fencing, Nether portal relocation and completing the Mine 1 track, with bilingual summaries, 22 timestamped instructions and Markdown exports. The catalog now has 72 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Added three reviewed videos covering turtle breeding and breathing equipment, a minecart interchange and powered mine access, with bilingual summaries, 24 timestamped instructions and Markdown exports. The catalog now has 69 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Added three reviewed videos covering item dropping, the first Survival shelter and a third-party update overview, with bilingual summaries, 20 timestamped instructions and Markdown exports. The catalog now has 66 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Show item graphics in chest-stock statistics using the existing Item icons setting and selected graphics pack. Text-only mode and unmapped items retain their text labels.

# 1.7.20 · 2026-09-06

- Added three reviewed official update videos covering Architect and difficulty settings, XP and leads, lava and pandas, with bilingual summaries, 22 timestamped instructions and Markdown exports. The catalog now has 63 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Added three reviewed official update videos covering fishing and revised triggers, redstone and transport, swinging and riding, with bilingual summaries, 26 timestamped instructions and Markdown exports. The catalog now has 60 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Added Beta chest-stock statistics with side-by-side quantities and chest counts for all chests and presumed player-owned chests. Reuses verified chest scans and existing ownership assignments; respects spoiler-light mode.
- Added bilingual name/ID search, dimension and theme filters, player-stock filtering, quantity/name/ID sorting, and thematic grouping for resources, wood, stone, food, equipment and other items. Reports unreadable records and partial scans separately from zero stock.

# 1.7.19 · 2026-09-06

- Added three reviewed official update videos covering villagers and world sharing, shields and wolves, hand feeding and new structures, with bilingual summaries, 28 timestamped instructions and Markdown exports. The catalog now has 57 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Added bilingual setup-help timing examples for the reference M3 MacBook Air (16 GB, 8 map workers), distinguishing observed map computation times from estimated USB import allowances, verification overhead and cache effects.

- Added three reviewed official video tutorials covering Architect mode, food, movement and avatar-height recentering, with bilingual summaries, 21 timestamped instructions and Markdown exports. The catalog now has 54 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Added three reviewed official video tutorials covering crafting basics, tool selection and anvil repairs, with bilingual summaries, 23 timestamped instructions and Markdown exports. The catalog now has 51 reviewed contributions out of 196; historical availability claims remain explicitly version-limited.
- Clarified dome and pyramid side views: staged exterior elevations show the nearest glass and metal surfaces; explicitly labeled central cross-sections remain available with complete layer plans. Physical layouts and material quantities are unchanged.
- Added seven modular underwater and transport guides: sealing test, glass dome, glass pyramid, panoramic tunnel, manual ladder shaft, direct walkway and boat canal. Includes counted materials, complete layer grids and voice-agent exports. Automatic elevators and speed bonuses remain unverified.
- Added per-save storage inspection: actual optimization coverage, shared-file counts, linked snapshots and editor provenance. Complete hard-linked snapshots do not require another savegame.
- Added matching-manifest detection for library ZIPs in the configured cloud folder, Finder reveal, refresh and explicit unknown online/upload status. Includes English/German help and regression tests.

# 1.7.18 · 2026-09-06


- Added clearly labeled short video summaries and per-video Markdown exports with authored instructions, review limitations and timestamp links. Full original transcripts and audio are not included.
- Added persistent video selection for AI exports. Video notes stay inline below 100 KB combined size or move into a linked second Markdown file automatically; users can also force separate files. JSON retains all selected notes.
- Local saving, iCloud and AirDrop preserve both files. Reopened AI exports retain the video supplement. Added selection, content parity, split-file, path protection and rollback tests.
- Added a confirmation dialog before storage optimization starts. Users can cancel, optimize without an extra archive, or create an independent ZIP backup first.
- The pre-optimization ZIP uses the same verified full-library export path and defaults to the remembered cloud-backup folder when available.
- Add German and English skill versions, language-specific and bilingual Markdown exports, and optional local Qwen translation drafts through LM Studio. Translation is reviewed before saving; all languages are preserved in version history and JSON packages.
- Expand the central Skills library with persistent version history, previews and restoration as a new version.
- Import and export individual skills or the entire collection with history in a versioned JSON package; matching IDs import as copies. Retain Markdown exchange, editing/renaming, duplication and archiving.
- Add sanitized savegame and help-maintenance skills plus Companion development instructions. Existing libraries receive missing bundled skills without replacing edits or re-adding deleted defaults.
- Document the complete workflow in German and English help. Packages exclude the separate personal profile and include skill-specific notes.

# 1.7.17 · 2026-09-06

- Added bilingual manual-transfer guidance for USB/MTP, conditional headset-side export, and manual restoration, accessible from setup and Help.
- Added a local receiving folder, copyable Quest path, a picker for an already mounted Quest folder, local import and verified ZIP export actions. No automatic third-party transfer or installation is performed.
- ADB remains the recommended tested path. Third-party workflows explicitly carry no correctness, compatibility or success guarantee; local import checksums are not represented as verification against the original Quest files.

# 1.7.16 · 2026-09-06

- Added bilingual voice-agent handoffs for every build guide: copy or save self-contained instructions, materials and coordinate grids, with small spoken actions, explicit confirmation, orientation and resumable checkpoints.
- Added three reviewed official video tutorials: World Sharing, motion-based fishing and motion-based block breaking. Full available original transcripts and selected storyboard images informed bilingual notes and timestamp links; the library now has 48 reviewed contributions out of 196 videos.
- Added three separate, combinable tree-village guides: a suspension-style bridge, a flower and vine terrace, and an open sapling courtyard. Each includes counted materials, staged grids, connection dimensions and explicit VR test limitations.
- Refreshed the complete bilingual help against the current UI and features, with 30 topics and sidebar groups matching Your world, AI tools and Knowledge & help.
- Added help for Statistics, Editor beta and separate Quest test worlds, AI export, Conversation, Videos & tips, Mobs & Animals, appearance/spoilers and feedback.
- Updated player durability/repair/skin guidance, chest search/sorting/sign-based ownership, map 3D/ownership controls, storage deduplication and full-library/cloud ZIP backups.
- Updated first-launch setup navigation and synchronized downloadable agent instructions. Clarified offline dependencies, local AI setup, explicit sharing, beta limits and video review coverage.
- Preserved historical release notes, source context and the Windows-porting explanation.

# 1.7.15 · 2026-09-06

- Added eleven AI-generated, untested builds: entrance vestibule, visual alarm, central lighting, retractable bridge, animal service pen, egg collector, honey station, fruit harvesting, twin furnaces, manual dropper lift and a treehouse with reserved growth space. Treehouse retains mature trees and tests new sapling growth; perpetual mature-tree growth is not promised.
- Read chests now marks chests as player-owned when a decoded sign lies within 30 horizontal blocks and 10 vertical blocks in the same dimension. Added nearby-sign evidence and bilingual help for sign markers, persistent ownership and manual correction.

- Expanded the video library to 196 unique videos across TarantNET Gaming, the RealmCraft VR channel, the Dobbi 53 playlist and Home Daddy VR.
- Added authored German/English notes and timestamp links for 45 reviewed entries: 38 transcript-and-image-sample reviews and 7 explicitly limited visual-only contributions. The remaining 151 entries are clearly pending review.
- Added review-status filters and separate labels for visual-only notes, transcript indexes and pending contributions. Existing 114 transcript indexes remain searchable.
- Prioritized official update explanations for trading, bees, enchanting, Nether behavior and controller mapping. Review samples are not presented as full video viewing or independent gameplay tests.
- Further YouTube acquisition is paused after caption rate limiting; future work prioritizes important tutorials with a conservative request pace.

# 1.7.14 · 2026-09-06

- Added three AI-generated, untested HQ-defense guides: entrance capture pit, lever-operated trapdoor shaft and a dry perimeter moat with removable bridge. Includes measured material counts, staged diagrams, player bypasses and explicit mob-behavior limitations.
- Added six AI-generated, untested minecart guides: button launch, acceleration, controlled braking, passing-cart indicator, experimental T junction and a two-track terminus. Includes staged grids, material counts and separate empty/occupied-cart tests; no fixed speed, braking distance or automatic routing is assumed.
- Fixed shirt placement in the 3D player preview: the shirt atlas now aligns with the torso UV islands instead of leaving the chest and back skin-colored.
- Removed the stretched-edge workaround. Original shirt patterns and transparent sleeve areas remain visible on both character models.

# 1.7.13 · 2026-09-06

- Added a bilingual eight-step first-launch setup guide for beginners, with persistent progress, explicit Later/Next navigation and access to all settings.
- Guide covers Mac requirements, official ADB installation, Meta account preparation, phone-based developer mode, headset USB authorization, device/world checks, library storage and optional analysis tools.
- Clearly identifies Meta Quest as the setup example and explains that other headsets and software versions can differ. Finishing the guide never starts a transfer.

# 1.7.12 · 2026-09-06

- Added deduplicated savegame storage: newly imported backups and manually optimized existing backups keep their normal world-folder layout, while identical file contents are stored once in a SHA-256 object store and linked back into each snapshot.
- Added a manual storage optimization action for the full library. The operation verifies each save before and after linking and keeps existing restore/export paths unchanged.
- Added a verified full-library ZIP export for external backup targets such as iCloud Drive, external disks or manually managed archives. Per-save ZIP export remains available.
- Added a remembered cloud-backup folder action so the full verified library ZIP can be written repeatedly to an iCloud Drive or other sync folder with timestamped filenames.
- Editor copies are materialized before patching so beta edits never modify shared storage objects.

# 1.7.11 · 2026-09-06

- Added four AI-generated, untested door and fence-gate guides with pressure plates on both sides, two-sided buttons and a maintained-lever alternative. Includes material counts, progressive top/section diagrams, reset tests and animal-trigger limitations.
- Grouped the Minecraft comparison by category with visible section headings; categories and entries sort alphabetically using the selected German or English language, including filtered results.
- Expanded Videos & tips to all 148 publicly listed RealmCraft uploads from TarantNET Gaming: 142 regular videos and six Shorts, checked on 6 September 2026. Other games are excluded; three ambiguous titles were confirmed through descriptions.
- Indexed available original/translated captions for 114 videos in 8,638 approximate thirty-second windows, with German topic aliases and timestamp links. The app bundles unordered search terms rather than complete transcripts, audio or video.
- Added German titles, broader topic categories, Shorts/transcript/edited-guide filters and explicit coverage labels. The three edited guides and eighteen steps remain intact. Automatically detected topics are not represented as manually verified instructions.
- Videos without usable or retrieved captions remain discoverable through their titles and topic entries. Caption retrieval stopped on rate limiting; one regular video retains an unknown publication date because metadata retrieval required a sign-in challenge.
- Added a repeatable local import tool, sanitized coverage inventory and expanded catalog/search validation. Channel import is explicit, not a scheduled background monitor.

# 1.7.10 · 2026-09-06

- Added a manually configured player skin with original game models and body, shirt and pants textures, separate selections for both character models, and both VR hand variants.
- Added an interactive 3D preview with rotation, zoom and optional saved armor. Armor colors are approximate; skin selection is local to Companion and never changes Quest files.
- Skin choices persist on this Mac after explicit Apply; Cancel discards edits. Invalid profiles safely fall back to defaults.

# 1.7.9 · 2026-09-06

- Added chest sorting by matching stored quantity (ascending/descending) and 3D straight-line distance from a fixed reference chest. Locations rank by their best matching chest; unknown quantities and cross-dimension distances sort last.
- Integrated Videos & tips as its own Companion navigation section under Knowledge & help, with the three curated pilot videos, bilingual topic/material search and category filters.
- Search results expose matching steps with direct YouTube timestamps, result counts and a reset action. Build guides retain their dedicated offline-plan section.
- Preserved German/English summary reading and explicit playback controls; opening the video library does not load or play online media.
- Main build includes the current AI context export and Statistics sources. Build verification now checks the signed app after removing signing-incompatible Finder metadata.

# 1.7.8 · 2026-09-06

- Added Statistics (Beta) under Your world, reading a selected local backup with focused world_data checksum verification.
- Shows the saved combined build/dig action counter with world name, ID and backup date. Both building and digging increment this value; it is not a mined-block total and cannot be split by material or player.
- Explicitly identifies unavailable historical resource, kill, distance, death and crafting totals. No invented estimates or zero placeholders for missing data.
- Unsupported versions, damaged data and mismatched world identities fail visibly. Changing the selected backup clears the previous result; all reads leave savegames unchanged.

# 1.7.7 · 2026-09-06

- Added an offline video-tip library alongside existing build plans: TarantNET Gaming episodes 74, 73 and 72, the three newest regular videos checked on 6 September 2026.
- Eighteen bilingual, timestamped steps cover bee occupancy and relocation, a cobblestone/stone generator, and minecart access tracks. Each links to the corresponding original YouTube segment.
- Added topic/text search and German/English system-voice reading for entire guides or individual steps, with stop controls. Original video audio is available on YouTube; users select its audio track there. Reading is an edited summary, not a synchronized full-video translation.
- Conversation can retrieve these curated video guides and their time links. PCVR provenance, limited visual sampling, unknown dimensions and untested Quest behavior remain explicit.
- Existing block plans and their test notes remain available under Offline test builds.

AI CONTEXT EXPORT EXPANSION

- Expanded AI context export (schema 2): validated world name/seed, isolated annotation scopes, free map markers, chest labels and visibility annotations, storage groups, durability warnings and repair forecasts.
- Includes complete bundled build plans and per-step grids, global material checklists/test notes, recipe material assessments and mob/reference catalogs with evidence and scope. Reference knowledge does not imply world sightings or working VR builds.
- Markdown and JSON carry the same context. iCloud and AirDrop use the expanded Markdown automatically. No UI filter silently removes records; unsupported data and failed catalog loads stay explicit.

# 1.7.6 · 2026-09-06

- Code size milestone: the current 1.7.6 source snapshot contains 10,568 non-empty source lines: 8,819 application lines, 1,607 test lines and 142 build/tool lines. Counts include comments and embedded text in source files; exclude blank lines, standalone documentation/data, assets, dependencies, backups and app/build copies. Reproduce with `python3 count_source_lines.py`. This is a source snapshot, not a measurement of the compiled binary.

- Optional mob pictures in the register's Appearance menu and macOS View menu. The setting persists and affects list thumbnails and detail previews.
- 24 static previews from original local RealmCraft VR Quest meshes and textures, with provenance. Baby entries explicitly identify adult reference images; absent models show a placeholder. No AI-generated or Minecraft substitute artwork.
- Includes the current chest material search, step-by-step build guides and 3D map beta resources from the shared workspace.

UPDATE LOG

Newest releases appear first. Each section identifies the app version. Feature-build references indicate verified inclusion, not an inferred first main release.

# 1.7.5 · 2026-09-06

- Update Log and Backlog are consistently English. Removed duplicate bilingual descriptions while preserving their details.
- Release entries are ordered newest first and grouped by app version. Historical feature-build references are identified explicitly where the first main-release version is not recorded.

# 1.7.4 · 2026-09-06

AI EXPORT: ICLOUD AND AIRDROP

AI export can save complete Markdown snapshots to a remembered iCloud Drive folder or share them through the native AirDrop dialog. Each export creates a separate file. macOS handles iCloud syncing.

# 1.7.3 · 2026-09-06

ENTIRE DISCLOSURE ROW IS CLICKABLE

The entire disclosure row toggles the section guide, including its label and trailing space.

# 1.7.2 · 2026-09-06

OVERVIEW MOUSE CLICKS

Decorative separators and the world preview no longer intercept mouse events. The overview disclosure and help link respond to direct clicks.

# 1.7.1 · 2026-09-06

- Mob variants now sort under their base name in German and English, e.g. Hoglin (Baby), Zombie (Baby), Piglin (Zombified).
- Added 18 reference-only baby variants: 47 entries total, including 20 baby forms. Only two baby forms have separate VR release evidence; the other 18 remain unconfirmed. All entries are visible by default with explicit evidence labels.
- Added dimension and biome references with separate VR, general RealmCraft wiki and Minecraft evidence. Unestablished VR locations remain clearly marked; location text is searchable.
- Retains the improved multiline bug description field and persistent AI-generated-data notices.

# 1.7.0 · 2026-09-06

- Conversation · Beta: material checks for one execution of each of the ten included reference recipes, using owned chests, missing quantities and material locations. These remain unverified Minecraft references; intermediate products, workstations and player inventory are excluded from the comparison.
- Owned chests can be named; short spoken stock answers still include the save date and uncertainty. Coordinates are available through a follow-up question.
- Optionally review recognized speech in the text field before sending; automatic sending after a 2.5-second pause can be disabled. The current Mac microphone name and input level are visible.
- Unambiguous local queries retain priority over model interpretation. Added a model intent for material checks.

# 1.6.5 · 2026-09-06

- Maps: drag an ownership area, review the count and mark all included chests as owned or remove their ownership marks.
- Selection uses X/Z coordinates across all heights in the current dimension and supports map rotation and mirroring. All discovered chests are included, regardless of the marker filter.
- Green rings indicate owned chests. Marks persist per world and apply to Conversation and AI export. Newly generated AI exports include the updated ownership state.
- Ownership marks apply to chests in the open map; the area is not a permanent automatic claim. Select newly added chests again later. Map coverage and read errors can limit the selection.

# 1.6.4 · 2026-09-06

REPAIR FORECASTS

- Visible orange warning below 50% and red warning below 20%, with numbers, symbols and colored condition bars.
- Repair forecasts for full durability show the material quantity or an identical replacement item and its required remaining durability.
- An anvil and experience levels are listed as prerequisites; suggested materials and level costs that are not forecast are clearly identified.

GRAPHICS PACK SELECTION (VERIFIED IN THE 1.6.4 GRAPHICS-PACK BUILD)

Item icons: choose Kenney (49 mappings, CC0) or Pixel Perfection Legacy (686 mappings, CC BY-SA 4.0 / CC BY 4.0 with source attribution), with separate opt-in downloads, creator/license information, previews, activation and removal. Installed packs coexist, text-only mode remains available, and existing Kenney preferences are retained.

# 1.6.3 · 2026-09-06

AI EXPORT

- Dedicated sidebar section, linked from Conversation.
- Streamlined Conversation section: settings in a dedicated dialog and secondary actions in a menu.
- Complete Markdown/JSON context from a verified backup: inventory, armor, level, durability, enchantments, respawn, named places, chests and separate resource totals.
- Optional fresh chest scan, visible data gaps and clear ownership labels; no automatic transfer to external AI services.
- Size display and preview; exported lists are not truncated.

OPTIONAL ITEM ICONS (VERIFIED IN THE 1.6.3 ICONS BUILD)

Settings → Item icons: opt-in Kenney Voxel Pack download (approx. 1.3 MB, CC0), with persistent Text only / Icons + text choice and removal. Covers 49 mapped items/blocks in inventory and chests; unmatched items retain text. SHA-256 verification and offline use after installation. Independent artwork, not original RealmCraft textures.

# 1.6.2 · 2026-09-06

- Conversation · Beta: a separate, saved language for speech recognition and replies (German/English), independent of the interface language. Default: German.
- Button to open Mac sound settings for microphone input; guidance on where to configure the language and device.
- Changing the language stops any active recording and starts a new conversation context.

# 1.6.1 · 2026-09-06

- Player view: remaining durability for weapons, tools and armor, condition bars and a warning at 20% or below.
- 61 reference maximum values from the game definitions; unknown or differing values remain explicitly labeled.
- Durability and reference maximum included in JSON exports; fully native parsing without Codex.
- Includes the recently integrated local Qwen connection, Mobs and Feedback.

MOBS & ANIMALS / FEEDBACK (INTEGRATED BY 1.6.1)

- New bilingual offline Mobs & Animals register: 24 release-evidenced creatures/variants, 3 in progress and 2 unconfirmed mobile-wiki references; search and status/category filters. Cmd+0 opens this tenth section.
- Persistent AI-generated-data notices; release evidence, publisher-linked general RealmCraft wiki and Minecraft comparison links remain clearly distinguished. No world scan or completeness claim.
- Global report button and entry-specific reports: editable description, reproduction/expected/actual fields, application metadata and preview.
- Hjson-compatible JSON text, ZIP containing report.hjson and up to five screenshots, and native Mail draft with attachments. Recipient chosen by the user; no automatic sending.
- Reports exclude savegame contents, world names, local source paths and device IDs from automatic metadata. Screenshots are user-selected or captured from the app window on request.

# 1.6.0 · 2026-09-06

- Conversation: local Mac speech recognition and spoken replies, text input, optional continuous conversation and Stop/Escape.
- Named map places scoped to the selected world, coordinate answers and followup questions.
- Ten sourced Minecraft crafting references (including bed and chest) (explicitly unverified in RealmCraft VR), plus existing build-guide materials and steps.
- Optional on-device Apple Foundation Models understands natural questions; source-backed answers and counts. No cloud AI or live route.
- Saved respawn coordinates; explicit own-chest selection and inventory totals with coordinates, save/backup dates and uncertainty.
- macOS 26 SpeechAnalyzer with managed language assets; older local recognizer retained as fallback.

# 1.5.1

MORE PRACTICAL BUILD GUIDES

- Six more bilingual offline guides: item collector, switchable storage line, sliding block module, cobblestone generator, cactus harvest and flower station.
- Twelve guides and 24 graph-paper views in total; before/after states and sectional plans where useful.
- Materials, manual work, expected behavior and unverified VR dependencies documented separately for every build.
- The displayed catalog count is derived from the loaded guides.
- Layout tests cover fluid recesses, material totals, piston states and dispenser orientation.

# 1.5.0

PLAYER ENCHANTMENTS & INTEGRATED IMPROVEMENTS

- Native offline enchantment parsing for inventory and equipped armor: verified IDs, German/English names, stored levels, search and JSON export. Unknown IDs and unusual positive levels remain visible.
- Player source, results and search persist across sidebar navigation. Refresh / Cmd+R retains dated prior data on failure with a clear warning.
- Fast local player reads validate only player_data against the recorded SHA-256 manifest; restore/export retain full-world verification.
- Cached translation patterns, fewer redundant automatic connection checks, and version labels from the bundle.
- Includes all recent map/chest, orientation/mirroring, build-guide, layout and character-preview work.

# 1.4.1

INTEGRATED FEATURES & QUIETER CONTROLS

- Unified player, armor preview, build guides, chest contents in maps, rotation and mirroring in the main source and release.
- Cached viewers refresh with the app version and language.
- Map orientation options expand on demand, with a precise rotation slider. Q/E/R also work after using map tools, while text fields retain normal typing. Reset clears rotation and mirroring.
- Build guides use the shared page header; player loading status reserves its space and setup moves to the actions menu.

# 1.4.0

PLAYER INFORMATION & OFFLINE BUILD GUIDES

- Schematic character preview reflects equipped armor materials; personal skin is not reconstructed.
- Player: read level, inventory and equipped armor directly from Quest or verified local backups.
- Native read-only parser, item search, source/read time and JSON export; no Python required.
- Rejects unsupported/truncated records and changing Quest snapshots. Durability/enchantment details remain explicitly unverified.

- Six bilingual test builds grouped into basic circuits, processing/storage and farms.
- Graph-paper block plans with coordinates, layer/section selection, zoom and clickable block details.
- Material lists, construction steps, operating principles, success criteria and source evidence.
- Per-build test results and notes saved locally; kept separate from source verification status.
- All plans are unverified RealmCraft VR adaptations, not claimed working farms.

# 1.3.1

MAP ROTATION

- Click the compass to rotate by 45°; Shift reverses the direction, and right-click resets north-up orientation.
- Option/Alt + scroll rotates freely. On the map, Q/E rotate and R resets north-up orientation.
- Panning, zooming, markers, coordinates and layers account for rotation.
- Previously generated maps receive the updated viewer when opened.

# 1.3.0

CONTENT-FIRST MAC INTERFACE

- Persistent sidebar navigation and keyboard shortcuts (Cmd+1…6).
- Real savegame overview instead of duplicate feature buttons.
- One visible primary action per tool; secondary operations in labeled action menus.
- Source-backed links displayed as text rows, not action cards.
- Fewer map level controls; direct slider and numeric input retained.
- Simplified chest detail navigation and item rows; coordinates available in the action menu.
- ADB management expands on demand in Setup.

# 1.2.1

CALMER LAYOUT AND ACTION HIERARCHY

- Shared page-title baseline and right-aligned primary tools.
- Reduced panel borders and secondary button emphasis.
- Appearance and language grouped in one menu.
- Secondary savegame and map actions grouped under More.
- Scope notes in Links & Knowledge expand on demand.

# 1.2.0

CONSISTENT COMPANION UI

- Fixed app header and navigation; Savegames no longer inserts a native split-view toolbar.
- Shared 260-point sidebars for savegames, storage locations and help.
- Compact six-card home screen with connection status near the top.
- Persistent Block world / Classic skins, including setup, help and existing embedded maps.
- Links & Knowledge has a pinned search and section selector.
- Reserved progress space in Maps and Chests prevents loading-state shifts.
- Savegame and Quest operations are unchanged.

# 1.1.0 · 2026-09-05

RealmCraft Companion replaces the single-purpose app shell with Home, Savegames, Maps, Chests, Resources and Help. The savegame engine and existing library remain available as a feature.

Added verified links to the official VR website, YouTube channel, Meta and Steam listings, Discord, Reddit and Canny. The publisher-linked general community wiki and FAQ are explicitly labelled as not VR-specific. Links open in the browser and do not load external content automatically.

Feature routing and the resource catalog are maintained separately from the transfer engine. Existing app preferences and save locations are preserved.

STORAGE LOCATIONS AND BIOMES
Nearby chests are grouped by six-block links. Browse individual matching chests inside each location instead of a long flat list.

Saved biome names appear at the map pointer, selected block and coordinate searches. Version-9 biome data uses a horizontal four-block grid; unknown IDs and absent coverage are explicit.

LOCAL MAPS AND CHEST SEARCH
Generate offline maps from verified backups. Explore terrain, heights, coordinates and Y levels in the app or browser. Optional Python/NumPy/Pillow setup uses an isolated environment.

Search chest contents in German or English, inspect occupied slots and quantities, copy coordinates and export JSON. The reader validates container framing and distinguishes unreadable records from empty chests. Item IDs are matched to the installed game enum and controlled in-game references.

INTERESTING PLACES
Map overlays highlight chests, beds, glass, crafting tables and furnaces, including underground blocks. Cycle through locations and save custom names across app restarts. Possible buildings are explicitly heuristic groups of multiple nearby indicators.

VALIDATED IN 1.1.0
Read-only indexing of 24,158 chunk files found 782 chest records in the local test backup. Synthetic tests cover item framing, corrupt records, duplicate coordinates and underground place detection. Transfer regressions still pass. Maps use schematic colors; arbitrary future save formats and detailed enchantment data remain outside the verified scope.

LINKS & KNOWLEDGE

Added an offline German/English Minecraft comparison with 14 topics covering blocks, items, mobs, mechanics, dimensions and world sharing. Includes topic filters, bilingual search, wiki links, dated VR update evidence through 1.0.3, and explicit distinctions between included content and unconfirmed parity. Renamed Resources consistently in navigation, Home and Help.

# 1.0.3 · 2026-09-05

FIXED
Device discovery now discards outdated results after you select another headset. Backup, restore and force-stop controls wait for the selected device check. The selected world survives reconnects when it is still available.

Connection status refreshes when a headset disconnects. ADB discovery commands use shorter timeouts so a stalled connection does not block discovery for ten minutes per command.

Library migration validates existing destination metadata and checksums before accepting an entry. An incomplete destination is rejected while the original library stays selected.

ADB setup and opening a different library without migration no longer require the old library to be writable. Searching a different import folder clears the previous import selection.

ADDED
English Update Log and Backlog in offline help and community source. Detailed German/English setup guide, USB-debugging instructions and static agent-assistance Markdown export/copy. Regression coverage for discovery, migration conflicts and process timeouts.

# 1.0.2 · 2026-09-05

Improved the main window and help layout. Moved restore and ZIP actions above the preview. Removed the wrapping language label in help.

Added English as the first-launch default and persisted language, selected save, device, world, help topic and window frames.

Moved the default library to Application Support to avoid automatic Documents access. Existing backups marked hidden are made visible in Finder, including their world files.

Added the development credit for OpenAI Codex and GPT-6 Astra, the complete MIT-licensed source archive and source export from help.

# 1.0.1 · 2026-09-05

Added complete German and English interface translations and bilingual offline help. Documented the originating Discord message and its historical 250 MB upload-limit context.

# 1.0.0 · 2026-09-05

Initial community release: Quest backups and restoration, SHA-256 verification, automatic backup before restore, ZIP import and export, save library, ADB setup and installation, game discovery and force-stop confirmation. Universal macOS app and original icon.

VALIDATION SCOPE
Transfer regression tests use disposable simulated Quest worlds. Device detection was checked on a Quest 3. No real saved world has been overwritten as a release test. Builds target Apple Silicon and Intel; interactive testing has been performed on Apple Silicon.
## Development note · 2026-09-07 · Initial Nether Metro increment

This early implementation note is retained as history and is superseded by the integrated 1.7.38 workspace above.

- Added a snapshot-local Nether Metro planner with named stations, colored lines, directed rail/portal/walking connections and a schematic line diagram. The diagram is deliberately non-geographic; line records, rather than its visual length, supply all distances.
- Planned and built connections are visible but excluded from routes. A station-by-station, copyable travel briefing uses only manually confirmed directed edges with measured durations, so it does not silently treat a reverse portal trip as confirmed.
- Portal coordinate scaling, search radius, height influence and automatic link selection remain unverified for RealmCraft. The planner does not use the existing assumed 8:1 converter for routing and does not modify savegames.
- Added synthetic metro-model tests for validation, snapshot persistence, directed confirmed routing, planned-edge exclusion and cross-dimension safeguards.
