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
