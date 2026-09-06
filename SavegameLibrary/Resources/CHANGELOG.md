UPDATE LOG

MAP ORIENTATION · 5 SEPTEMBER 2026
Maps can be mirrored left/right and top/bottom independently, with a reset button. Terrain, Y slices, markers, picking, dragging, zoom anchors and compass labels share the same orientation. Labels remain readable and world coordinates are unchanged. DE/EN supported.


MAP CHEST PREVIEW · 5 SEPTEMBER 2026
Select a chest marker (or a visible chest block) to inspect saved item names, quantities and slot numbers directly on the map. Empty and unreadable containers have distinct states. Inventory data shares the chunk cache and source snapshot used by the renderer. Regenerate existing maps to include inventories. DE/EN supported.


1.1.0 · 5 SEPTEMBER 2026

RealmCraft Companion replaces the single-purpose app shell with Home, Savegames, Maps, Chests, Resources and Help. The savegame engine and existing library remain available as a feature.

Added verified links to the official VR website, YouTube channel, Meta and Steam listings, Discord, Reddit and Canny. The publisher-linked general community wiki and FAQ are explicitly labelled as not VR-specific. Links open in the browser and do not load external content automatically.

Feature routing and the resource catalog are maintained separately from the transfer engine. Existing app preferences and save locations are preserved.

LOCAL MAPS AND CHEST SEARCH
Generate offline maps from verified backups. Explore terrain, heights, coordinates and Y levels in the app or browser. Optional Python/NumPy/Pillow setup uses an isolated environment.

Search chest contents in German or English, inspect occupied slots and quantities, copy coordinates and export JSON. The reader validates container framing and distinguishes unreadable records from empty chests. Item IDs are matched to the installed game enum and controlled in-game references.

INTERESTING PLACES
Map overlays highlight chests, beds, glass, crafting tables and furnaces, including underground blocks. Cycle through locations and save custom names across app restarts. Possible buildings are explicitly heuristic groups of multiple nearby indicators.

VALIDATED IN 1.1.0
Read-only indexing of 24,158 chunk files found 782 chest records in the local test backup. Synthetic tests cover item framing, corrupt records, duplicate coordinates and underground place detection. Transfer regressions still pass. Maps use schematic colors; arbitrary future save formats and detailed enchantment data remain outside the verified scope.

1.0.3 · 5 SEPTEMBER 2026

FIXED
Device discovery now discards outdated results after you select another headset. Backup, restore and force-stop controls wait for the selected device check. The selected world survives reconnects when it is still available.

Connection status refreshes when a headset disconnects. ADB discovery commands use shorter timeouts so a stalled connection does not block discovery for ten minutes per command.

Library migration validates existing destination metadata and checksums before accepting an entry. An incomplete destination is rejected while the original library stays selected.

ADB setup and opening a different library without migration no longer require the old library to be writable. Searching a different import folder clears the previous import selection.

ADDED
English Update Log and Backlog in offline help and community source. Detailed German/English setup guide, USB-debugging instructions and static agent-assistance Markdown export/copy. Regression coverage for discovery, migration conflicts and process timeouts.

1.0.2 · 5 SEPTEMBER 2026

Improved the main window and help layout. Moved restore and ZIP actions above the preview. Removed the wrapping language label in help.

Added English as the first-launch default and persisted language, selected save, device, world, help topic and window frames.

Moved the default library to Application Support to avoid automatic Documents access. Existing backups marked hidden are made visible in Finder, including their world files.

Added the development credit for OpenAI Codex and GPT-6 Astra, the complete MIT-licensed source archive and source export from help.

1.0.1 · 5 SEPTEMBER 2026

Added complete German and English interface translations and bilingual offline help. Documented the originating Discord message and its historical 250 MB upload-limit context.

1.0.0 · 5 SEPTEMBER 2026

Initial community release: Quest backups and restoration, SHA-256 verification, automatic backup before restore, ZIP import and export, save library, ADB setup and installation, game discovery and force-stop confirmation. Universal macOS app and original icon.

VALIDATION SCOPE
Transfer regression tests use disposable simulated Quest worlds. Device detection was checked on a Quest 3. No real saved world has been overwritten as a release test. Builds target Apple Silicon and Intel; interactive testing has been performed on Apple Silicon.
