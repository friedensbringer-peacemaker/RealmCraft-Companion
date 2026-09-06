BACKLOG

## Completed · 1.7.30 · Help and public documentation

Refreshed bilingual in-app help and added route-planning/navigation guidance. Documented 3D build controls, current video and export options, 90-degree map orientation and sign labels. Public documentation distinguishes snapshot-based navigation from live tracking.

## Completed · 1.7.29 · Guide panels and sign labels

Collapsed secondary build-guide controls, isolated page scrolling from 3D camera motion and improved partial-block previews. Signs can show their labels directly when the layer is enabled.

## Under consideration · Minecraft-tool inspiration · 2026-09-06

These are proposed RealmCraft Companion extensions, not implemented features. Integration version: not assigned; record the actual app version in the Update Log when an item ships. Suggested order favors improvements to existing read-only views and build planning before new world-writing capabilities.

Discovery references: [Programs and editors](https://minecraft.fandom.com/wiki/Tutorials/Programs_and_editors) and [Mapping / Mappers](https://minecraft.fandom.com/wiki/Tutorials/Programs_and_editors/Mapping#Mappers). The mapping subpage could not be retrieved during this review; the tool descriptions below were checked against their own project pages. The proposals are our adaptations of those concepts, not claims that these tools support RealmCraft saves, block IDs, mechanics or seeds. Evaluate format mappings and licenses separately before any integration or reuse.

### Tectonicus-compatible export — user-requested feasibility idea · 2026-09-06

Goal: generate a separate rendering export from a RealmCraft snapshot so that Tectonicus can produce its zoomable maps. Status: exploratory; no working compatibility established and no integration version assigned.

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
Review the remaining important official tutorials and practical survival/build guides before incidental travel footage. The catalog has 197 videos, with 154 authored contributions and 43 pending. Use conservative, sequential acquisition; pause on YouTube rate limits and reuse already available captions. Do not imply continuous viewing when only image samples were inspected. No scheduled or automatic downloader is configured.

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
- Add map cache size controls and cleanup inside the app.
- Add native marker export and map-generation cancellation.
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
