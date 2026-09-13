# Tectonicus validation

From the Companion directory:

```sh
python3 Tests/TectonicusTests.py
python3 Tests/TectonicusWorkerTests.py
node Tests/TectonicusAutoFitTests.js
```

The eleven Python tests use only synthetic data. They cover all 262,144 fixture block positions, negative regions, five-bit palettes, blank sign entities, special block defaults, source hashes, area selection, symlink and overwrite guards, corrupt downloads, resource-download consent, child-process cancellation, HTTP directory/symlink boundaries and server shutdown. Perspective tests verify non-default camera angles/elevations in both renderer configuration and result metadata, plus portable, idempotent auto-framing. The second command needs permission to create child processes and listen on loopback.

Manual acceptance on macOS:

1. Run worker setup with an empty support directory and explicit resource consent; verify the downloaded JDK passes pkgutil signature and spctl installation assessment.
2. Render a synthetic or separately approved demo snapshot. Require both a successful exit and the renderer completion marker, without exceptions. Check source hashes before and after.
3. In a disposable Companion app/library, choose Tectonicus, start a render, cancel one attempt and complete another. Confirm embedded zoom, browser/Finder actions and latest-success restoration after navigation/relaunch.
4. Choose a different camera direction and elevation; restart the disposable app and verify both choices persist. Verify the displayed result retains its actual rendering perspective. Open an existing demo map without a link position and confirm automatic framing; position/zoom links must preserve their requested view.
5. Use a new temporary app bundle for universal builds. Check arm64/x86_64 output, executable mode 0755, bundle signature and actual launch. Intel runtime rendering needs separate hardware verification.

Do not use or publish personal saves, paths, screenshots or tool binaries in tests. No test writes to Quest. The local approved-demo acceptance artifacts are kept outside the source package.
