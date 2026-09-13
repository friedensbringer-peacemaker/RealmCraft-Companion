# Planning, background rendering and incremental transfer tests

These tests use synthetic data and temporary output only. Never substitute a real Quest or personal library. The user deferred GUI acceptance and installation; passing these commands is not interactive acceptance.

Run the following from the Companion source directory. Use an explicit writable module-cache directory.

```sh
xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache Sources/MetroModels.swift Sources/PlanningStore.swift Sources/MetroJourney.swift Sources/OrePreset.swift Sources/ChunkChanges.swift Tests/PlanningIntegrationTests.swift -o /private/tmp/realmcraft-planning-tests
/private/tmp/realmcraft-planning-tests

xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache Sources/Library.swift Sources/IncrementalBackup.swift Sources/MapSnapshotInput.swift Sources/MapRenderJob.swift Sources/MapCacheLease.swift Tests/MapSnapshotInputTests.swift -o /private/tmp/realmcraft-input-tests
/private/tmp/realmcraft-input-tests

xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache Sources/CompanionLifecycle.swift Tests/CompanionLifecycleTests.swift -o /private/tmp/realmcraft-lifecycle-tests -framework SwiftUI -framework AppKit
/private/tmp/realmcraft-lifecycle-tests

node --test Tests/*.test.cjs Tests/PortalMapTests.js Tests/TectonicusAutoFitTests.js
```

Run Python discovery from the parent project folder because the existing video-workspace smoke test resolves its tool relative to that folder:

```sh
python3 -m unittest discover -s RealmCraftCompanion/Tests -p 'test_*.py'
```

For `Tests/integration.py`, explicitly set `REALMCRAFT_TEST_APP` to the newly built executable before execution; otherwise its legacy default points to the project app symlink. The suite launches a generated fake ADB and creates all device/library files under its temporary directory. macOS fixture permissions may require an authorized run outside the filesystem sandbox. It must never invoke real ADB.

New integration cases cover identical follow-up zero-transfer, selective changed/new downloads, nested names, removed files, corrupt transfer rollback, changed remote snapshots, unsafe paths and damaged-base full-transfer fallback. Full verification and existing restore/archive gates remain enabled.

## Interactive acceptance still required

1. In a synthetic library, save a confirmed Metro journey, confirm a leg, leave/reopen the page, restart the app and verify progress. Edit the network and confirm the old journey is retained but cannot resume unchanged. Inspect JSON/Markdown portal and transfer checkpoints.
2. Save/apply an ore preset on another snapshot of the same synthetic world. Verify all settings, no automatic scan and no copied results; reject malformed metadata without overwriting it.
3. Compare synthetic backups with added/changed/missing/identical chunks. Check both dimensions, filtering, list centering, zoom, negative coordinates and exported statuses.
4. Generate an Atlas map, navigate through other Companion pages, switch the selected backup, and verify no unsolicited view/selection change on completion. Use Open map to return to the captured snapshot. Test cancellation/retry, errors, changed language, removed source and quit refusal. Repeat in both UI languages.
5. Complete the earlier 1.7.39 Atlas checklist in `docs/INTEGRATION-2026-09-11.md` before calling the combined candidate fully accepted. Installation, real-device benchmarks and platform parity remain separate authorizations.
