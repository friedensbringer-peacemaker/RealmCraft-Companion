BACKLOG

## Planned · UI consistency across main screens

Static layout audit completed for all 15 main navigation destinations; implementation and runtime acceptance checks are pending. No new screenshots are required while screenshot creation remains paused.

- Standardize the page header, stable primary-action and overflow slots, semantic button roles, title baselines and icon alignment. Bring Home and Editor into the shared page frame.
- Align world-source selectors and collection-search/filter regions. Preserve control geometry during loading, result, warning and error transitions without clipping messages.
- Normalize inner list widths, left-aligned reading columns and panel spacing; prevent mob-image toggles from shifting the detail column.
- Keep workflow-specific controls in context: chat composer, editor confirmation footer and map-canvas tools. Uniform appearance does not mean placing every action in the page header.
- Validate German/English and both appearances at 1080×700, 1280×800, 1440×900 and wider layouts, using synthetic empty/populated/long-text/error states. Track title, action, selector, divider and result-area anchors.


## Skills follow-up (after 1.7.18)

- Support portable skill folders with referenced resources and scripts; current imports handle Markdown instructions and Companion JSON packages.
- Allow selecting multiple skills for one agent handoff and explicit skill selection in Conversation.


This is a list of proposed improvements, not a release schedule. Items have no promised delivery date. Completed work is recorded in the Update Log.

PLANNED · PRIORITIZED VIDEO REVIEW
Review the remaining important official tutorials and practical survival/build guides before incidental travel footage. The catalog has 196 videos, with 84 authored contributions and 112 pending. Use conservative, sequential acquisition; pause on YouTube rate limits and reuse already available captions. Do not imply continuous viewing when only image samples were inspected. No scheduled or automatic downloader is configured.

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

## Android and Quest Companion APK — feasibility idea (2026-09-06)
- Prototype 0.1.0 is now implemented in the separate public project https://github.com/friedensbringer-peacemaker/RealmCraft-Companion-Android . It provides a native 2D panel, synthetic sample, single-world ZIP import, persistent snapshots, metadata/file inspection and an experimental read-only Shizuku import. Physical Quest/phone behavior and direct directory access still require device validation.
- Explore a shared Android implementation for phones and Meta Quest 3, with a resizable 2D panel on Quest for use alongside RealmCraft and a phone workflow that can eventually replace the Mac. The complete port remains under consideration, with no promised delivery date.
- The current SwiftUI/AppKit macOS app requires an Android port rather than an additional APK build target. Assess reusable data, resources and parsing logic, plus replacements for Apple-specific UI, rendering, speech and runtime dependencies.
- Start with a small prototype: offline recipes, materials and build guides, followed by maps, chests and player details from an explicitly imported save snapshot. Clearly distinguish snapshot data from live game state; live position/inventory synchronization requires separate investigation.
- Test Quest window placement, controller/hand input focus, RealmCraft pause/resume behavior and memory/performance while both apps are open. Do not assume uninterrupted gameplay or simultaneous input.
- Investigate authorized ADB access for backup/restore: phone-to-Quest over USB or Wi-Fi, and a possible on-headset connection. Normal Android storage permissions, including all-files access, do not grant access to another app's Android/data directory. Verify setup, reconnect/reboot behavior and supported Horizon OS versions before promising direct save access.
- Keep snapshot browsing available during play, but stop RealmCraft before savegame transfers or edits. Preserve explicit world selection, restorable backups, checksum verification, file permissions and rollback protections; never edit active game files concurrently.
- Concrete import experiment: use an explicitly authorized on-device ADB client or an ADB-backed helper such as Shizuku to read a selected Tellurion world and stream it to the Companion, which writes its own snapshot into its app data directory (not into the APK installation directory). If needed, evaluate an explicit ZIP export/import through a user-selected shared location. Test helper availability, actual source access and restart requirements on Quest; Shizuku is a candidate, not verified Quest support. Reference: https://shizuku.rikka.app/introduction/
- Feasibility references: https://developers.meta.com/horizon/documentation/android-apps/horizon-os-apps/ ; https://developers.meta.com/horizon/resources/vrc-quest-input-4/ ; https://developer.android.com/training/data-storage/manage-all-files ; https://developers.meta.com/horizon/essentials/metavr-devices-and-apps/

Optional item icons: Kenney (49 IDs) and Pixel Perfection Legacy (686 IDs) opt-in downloads, license details and persistent pack/text selection implemented for inventory and chests. Expand coverage only with suitable licensed artwork and verified IDs; consider build-guide materials once they have stable item mappings. See ITEM-ICONS.md. Original RealmCraft artwork still requires documented redistribution permission.

User-managed resource bookmarks, resource favorites and additional independent feature modules. Evaluate future features separately from the savegame transfer engine.

## Atlas navigation and position tracking — remaining work

- Initial implementation in 1.7.22: candidate surface routes, English coordinate-based instructions, optional nearby POIs, mixed travel sections, AI-export handoff and local Qwen reference selection. Actual player position tracking and verified climbing/rail mechanics remain unimplemented.
- Further develop optional turn-by-turn navigation to a selected map point, sign or saved place. Show the route, next turn, remaining distance and estimated arrival time while travelling; consider optional spoken directions.
- Add a POS / current-position indicator with heading and optional map follow mode. Distinguish movement inside the Companion's 3D preview from the actual player's position in RealmCraft VR.
- Investigate a supported, read-only source for timely player position updates before promising in-game navigation. A savegame provides only the last saved position: show its timestamp and stale/unavailable status, and never present it as live tracking. Do not stop the running game or change save files to obtain navigation updates.
- Build traversable routes from verified chunk data, heights, clearance, water and connected rail networks, with separate walking, boat, minecart and llama suitability. The current straight-line terrain profile is not a navigable route. Account for gaps in map coverage, dimension changes and uncertain transport mechanics.
- Recalculate when leaving the route; allow pausing, cancelling and choosing another destination. Clearly label estimated travel times and unverified routes as Beta. Validate position accuracy, update delay, route safety and travel speeds before implementation is treated as reliable.

## Atlas preview
- Broaden block/format coverage using real-world fixtures.
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

## Statistics / Statistiken (Beta) — remaining work
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
