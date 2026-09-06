# Companion skill library

Bundled starting instructions:

- `realmcraft-world-context`: interpret a saved-world AI export.
- `realmcraft-savegame`: existing savegame workflow, with private historical world IDs and local artifact paths removed.
- `realmcraft-help-refresh`: existing bilingual help-maintenance workflow, with its personal local project path removed.
- `realmcraft-development`: Companion development conventions.
- `realmcraft-platform-sync`: compare and maintain macOS, Android/Quest and hosted web UI, UX and feature alignment, with macOS as the leading reference.

The application installs previously unseen bundled IDs into its shared local library. Existing edits remain intact. Deleted defaults are remembered and are not re-created on the next launch. Every edit or archive operation preserves the preceding state; restoration creates a new state.

Use SKILL.md for agent-readable instructions. Use the versioned RealmCraft JSON package for lossless interchange of current states, notes and history. Import collisions create separate copies. The personal profile is excluded from packages. Markdown imports do not install scripts or referenced resources. Instructions are never executed by the importer.

## Languages

Each default has a German `SKILL.md` and an English `SKILL-en.md`. `LEGACY.md` is migration-only matching content; it is not shown as a skill. Only unchanged bundled text is migrated automatically, and its old state is kept in history. Custom text is preserved.

The editor supports separate German and English text. Local Qwen translation uses the existing LM Studio localhost transport, requires a loaded Qwen3.5-4B model, and produces an editable draft. No cloud fallback, automatic execution or automatic saving occurs. Model availability and translation quality must be checked locally.
