# RealmCraft Companion

A community macOS companion for RealmCraft VR on Meta Quest, built with SwiftUI. Manage local world backups, inspect saved worlds and plan builds with bilingual German/English tools.

## Project

- **RealmCraftCompanion/** — current app, sources, build inputs, synthetic tests and offline documentation.
- **SavegameLibrary/** — earlier standalone backup-library project.
- **RealmcraftMap/** — standalone Python world-map renderer.

The Companion includes verified backup/restore workflows, maps, chest and player readers, build guides, local conversation tools and optional save editing. Read the in-app guidance and individual feature documentation for compatibility limits and beta status. This is an independent community project.

## Build

The native app targets macOS 14 or later. Install Xcode Command Line Tools and Python 3, then run:

```sh
cd RealmCraftCompanion
./build.sh
```

The script builds for Apple Silicon and Intel and creates `RealmCraft Companion.app` beside the project folder. The resulting app is ad-hoc signed; this repository does not provide a notarized release. Optional map and local-model features have their own dependencies; see the [app documentation](RealmCraftCompanion/README.md).

## Development

See the [change log](RealmCraftCompanion/Resources/CHANGELOG.md), [backlog](RealmCraftCompanion/Resources/BACKLOG.md) and [community guide](RealmCraftCompanion/COMMUNITY.md). The initial Git commit is a publication snapshot; earlier development is documented in the change log, not reconstructed as Git history.

This project was developed with OpenAI Codex. Contributions should preserve bilingual UI text, explicit compatibility limits and the tested backup safeguards.

## Privacy

This repository contains project files only. Real savegames, backup libraries, personal exports, world screenshots, device identifiers, private notes and personal paths must never be committed or attached to issues or releases. Use synthetic fixtures in tests and examples. See [contribution rules](CONTRIBUTING.md).

The public checkout is separate from private development data. No original game saves or compiled application bundles are included.

A separately reviewed, optional demonstration world is planned. It is not included in this initial source publication. See the [demo proposal](DEMO-WORLD.md).

## License and resources

Project code is MIT licensed; existing component license notices are preserved. Resource origin and scope are documented in the [mob image notes](RealmCraftCompanion/Resources/MobImages/README.md), [mob sources](RealmCraftCompanion/Resources/MOBS-SOURCES.md), [player skin notes](RealmCraftCompanion/Resources/PLAYER-SKIN.md) and [community guide](RealmCraftCompanion/COMMUNITY.md). The code license does not replace third-party resource notices.
