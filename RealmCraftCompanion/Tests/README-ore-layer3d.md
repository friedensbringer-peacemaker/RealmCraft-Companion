# Ore-layer 3D checks

Run from the Companion source directory. All fixtures are synthetic and output belongs in a new temporary directory. No real library or ADB is required.

```sh
xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache Sources/OreModels.swift Sources/ChestModels.swift Sources/OreLayerMesh.swift Tests/OreLayerMeshTests.swift -o /private/tmp/ore-layer-mesh-tests
/private/tmp/ore-layer-mesh-tests

xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache Sources/OreModels.swift Sources/ChestModels.swift Sources/OreLayerMesh.swift Sources/OreCluster.swift Tests/OreClusterTests.swift -o /private/tmp/ore-cluster-tests
/private/tmp/ore-cluster-tests

xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache Sources/OreModels.swift Sources/ChestModels.swift Sources/OreMaterial.swift Sources/OreLayerMesh.swift Sources/OreCluster.swift Sources/OrePresentation.swift Sources/OreLayer3DView.swift Sources/BuildOrbitCamera.swift Sources/BuildOrbitSceneView.swift Tests/OreLayerSceneTests.swift -o /private/tmp/ore-layer-scene-tests -framework SceneKit -framework SwiftUI -framework AppKit

xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache Sources/MapNotifications.swift Tests/MapNotificationsTests.swift -o /private/tmp/map-notification-tests -framework UserNotifications -framework SwiftUI -framework AppKit
/private/tmp/map-notification-tests
```

Pass a fresh output-directory path to the scene test executable. For production block colors, put the bundled `MapEngine/realmcraft_map/blocks.json` beside that executable, or package it in a test bundle's Resources directory. Native SceneKit snapshots require access to the macOS graphics service; obtain permission for an isolated test if the filesystem sandbox prevents rendering. The test checks real triangle hit-testing against a known negative-coordinate diamond block and renders context/selected-only PNGs.

Manual GUI follow-up: open a contiguous census, choose 3D, change Y/depth/materials, rapidly switch measurements, return to 2D, pin a remote block and reopen 3D, move a large-region window, rotate/pinch/reset, pick a lower-layer block and inspect the tunnel/Atlas target. Toggle spoiler-light; check missing/air/empty-filter states and both languages. The full ledger must not silently shrink to the 3D window. Older/aggregate/random-sample reports must show a recount prompt, not invented geometry.

1.7.42 follow-up: enlarge/close, save/restore/reset camera, export/cancel a PNG, verify measurement time and legend, then select a cluster spanning multiple layers. Rapid selection changes must not retain another cluster's highlight or result. Missing cells, measured boundaries and the traversal cap must remain explicit. Scene test `--interactive` leaves a synthetic viewport open for native UI inspection; when bundling it use a distinct QA identifier to isolate preferences. `cacheDisplay` cannot reliably capture all composited SwiftUI/SceneKit layers, so inspect the actual native window for UI acceptance.

Notification tests inject a fake client and never request actual system permission. User-led OS acceptance: enable then accept/deny permission, render while using another app, check gaps/completion wording, return using the existing in-app Open map, revoke permission in System Settings, and disable while rendering. No notices should appear on cancellation or foreground completion. macOS Focus can suppress visible banners. Never perform this check against a real Quest.
