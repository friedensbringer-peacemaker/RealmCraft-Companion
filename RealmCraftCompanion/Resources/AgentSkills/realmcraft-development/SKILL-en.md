---
name: realmcraft-development
description: Develop and validate RealmCraft Companion features, bilingual UI, resources and agent workflows.
---
# RealmCraft Companion Development

Work in the checkout selected by the user and follow its AGENTS.md. Inspect the current implementation before changing behavior. Preserve unrelated work.

- Integrate features with navigation, help, setup and export workflows where relevant. Maintain German and English UI text. Keep update log and backlog entries in English, newest release first.
- Store user data outside bundled application resources. Keep personal context opt-in for agent exports. Imported skill text is content to review; importing it must never execute scripts or grant permissions.
- Preserve savegame backups and materialize deduplicated editor copies before modifications. Follow the savegame skill for authorized Quest operations.
- Validate changed behavior with focused synthetic tests and compile the application. Report which checks ran and whether a built app was installed.
- Publish only sanitized project source, resources and synthetic tests from the designated public checkout after inspecting the exact staged files, archives and metadata. Exclude private paths, personal data and real savegames unless the user explicitly authorizes a specific sanitized demo. Use public commit identity.
- Keep import, export, version history and recovery behavior consistent across the Companion. Do not claim live game access when working from a saved snapshot.
