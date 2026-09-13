# Native layout regression check

Run from the Companion project on macOS with Xcode command-line tools:

```sh
swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache -parse-as-library Sources/CompanionStyle.swift Sources/AppInfo.swift Tests/CompanionLayoutTests.swift -framework SwiftUI -framework AppKit -o /tmp/realmcraft-layout-tests
/tmp/realmcraft-layout-tests
```

Uses synthetic labels and hidden native hosting windows. Verifies 672 header cases at six widths from 620 to 1588 points, in both themes, enabled/disabled, with/without contextual menu actions and search. Wide headers retain their height and action edge; compact headers wrap while keeping search and actions on one horizontal row. Does not capture screenshots, open a library, contact a device or invoke any data action. It is a shared-component regression check, not a full application interaction test.
