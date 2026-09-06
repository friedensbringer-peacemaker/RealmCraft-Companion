# Community source / Community-Quellcode

**Dieses Programm wurde vollständig mit OpenAI Codex und GPT-6 Astra entwickelt.**

**This program was developed entirely with OpenAI Codex and GPT-6 Astra.**

The app's Swift source, user interface, transfer logic, tests, German/English resources, documentation and original icon-generation code are included. It uses Apple's system frameworks and Google's ADB as external components; those components were not created for this project and retain their own licenses.

## Build / Erstellen

On a Mac with Xcode Command Line Tools and Python 3:

```sh
chmod +x build.sh
./build.sh
```

The build produces a universal app for Apple Silicon and Intel under `/private/tmp/realmcraft-distribution-build/RealmCraft Companion.app`. The app runs on macOS 14 or newer. Python and the developer tools are only needed to build it, not to run the app.

The build generates the app icon and translations, bundles this source ZIP, and signs the app ad-hoc. Release signing with a Developer ID and Apple notarization must be performed separately by a distributor with the appropriate Apple account.

## Tests

```sh
python3 Tests/integration.py
```

These tests use a disposable simulated Quest filesystem, never a real savegame. For the setup tests:

```sh
xcrun swiftc -swift-version 5 -O Sources/Library.swift Sources/Setup.swift Tests/SetupTests.swift -o /tmp/realmcraft-setup-tests
/tmp/realmcraft-setup-tests /tmp/realmcraft-setup-fixture
```

Use a new fixture folder for each run. Adding `--download` performs a real official Google Platform Tools download into the test folder and validates the installation without changing the existing ADB installation or app preferences.

## Contributing / Mitwirken

Improvements, translations and bug fixes are welcome. Preserve checksum verification, the automatic backup before restoration, the running-game guard, and rollback behavior. Never test a restore change against a valuable world without an independent backup.

The project code and original icon are provided under the MIT license in `LICENSE`. The source package contains no personal savegames, developer certificates, API keys or Google Platform Tools binaries.

Der Quellcode und das selbst erstellte Icon stehen unter der MIT-Lizenz. Das Paket enthält keine persönlichen Spielstände, Entwicklerzertifikate, API-Schlüssel oder Google-Platform-Tools-Binärdateien.


## Extending the companion

`CompanionFeature` and `CompanionView` define feature routing and the home cards in `Sources/CompanionView.swift`. Add a case, localized metadata and its destination view to add a feature. Keep transfer logic in Library.swift. `Resources/CommunityLinks.json` contains bilingual resource descriptions, HTTPS destinations and source URLs; ResourcesView renders the catalog and search. Bundle ID and existing library paths intentionally remain compatible with previous versions.

## Atlas, chest index and places
The frozen renderer snapshot lives in Resources/MapEngine. It is independent of the concurrently developed RealmcraftMap working tree. Extend points.py for block indicators and chests.py only with validated framing/fixtures. Tests/test_chests.py and Tests/test_points.py use synthetic data. ItemNames.json contains factual IDs and community labels; game binaries and personal worlds are excluded. Python is an optional external runtime, not bundled.
