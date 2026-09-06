BACKLOG

This is a list of proposed improvements, not a release schedule. Items have no promised delivery date. Completed work is recorded in the Update Log.

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
Backup notes, tags, sorting options and clearer names for library folders. Consider multi-world batch backup and optional duplicate detection.

PLANNED · DIAGNOSTICS
Provide a redacted diagnostic export with consistent language and actionable connection errors. Never include save contents or device identifiers without an explicit user choice.

UNDER CONSIDERATION
An update-check mechanism with an authenticated release source; wireless ADB pairing; additional community translations; broader automated GUI and accessibility checks.

CONTRIBUTING
The complete source is available from Help → Development & source. See COMMUNITY.md for build and test instructions. Keep the running-game guard, checksum verification, automatic pre-restore backup and rollback behavior intact when proposing changes.


COMPANION IDEAS

User-managed resource bookmarks, resource favorites and additional independent feature modules. Evaluate future features separately from the savegame transfer engine.

## Atlas preview
- Broaden block/format coverage using real-world fixtures.
- Add map cache size controls and cleanup inside the app.
- Add native marker export and map-generation cancellation.
- Consider bundling a licensed Python runtime for simpler first-time setup.

## Chest explorer and places
- Add Ender inventory, other containers and detailed enchantment/durability decoding with verified fixtures.
- Improve grouping across building boundaries and link chest search results directly to atlas markers.
- Add place-name import/export between the embedded app and external browsers.
- Refine community German item terminology and verify new game versions.
