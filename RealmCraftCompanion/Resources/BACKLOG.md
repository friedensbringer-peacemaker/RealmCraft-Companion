BACKLOG

This is a list of proposed improvements, not a release schedule. Items have no promised delivery date. Completed work is recorded in the Update Log.

PLANNED · PRIORITIZED VIDEO REVIEW
Review the remaining important official tutorials and practical survival/build guides before incidental travel footage. The catalog has 196 videos, with 45 authored contributions and 151 pending. Use conservative, sequential acquisition; pause on YouTube rate limits and reuse already available captions. Do not imply continuous viewing when only image samples were inspected. No scheduled or automatic downloader is configured.

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

Optional item icons: Kenney (49 IDs) and Pixel Perfection Legacy (686 IDs) opt-in downloads, license details and persistent pack/text selection implemented for inventory and chests. Expand coverage only with suitable licensed artwork and verified IDs; consider build-guide materials once they have stable item mappings. See ITEM-ICONS.md. Original RealmCraft artwork still requires documented redistribution permission.

User-managed resource bookmarks, resource favorites and additional independent feature modules. Evaluate future features separately from the savegame transfer engine.

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
- Start with current resource quantities by item type in the parsed player inventory and scanned containers, with inventory, armor and user-confirmed owned storage separated. Display scan coverage and failures, avoid double-counting containers, and do not attribute unowned/generated chest contents to the player. These are current holdings, not lifetime resources gathered.
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
