# Native layout regression check

Run from the Companion project on macOS with Xcode command-line tools:

```sh
swiftc -parse-as-library Sources/CompanionStyle.swift Sources/AppInfo.swift Tests/CompanionLayoutTests.swift -framework SwiftUI -framework AppKit -o /tmp/realmcraft-layout-tests
/tmp/realmcraft-layout-tests
```

Uses synthetic labels and hidden native hosting windows. Verifies header height, primary-action size and trailing position at four widths, in both themes, enabled/disabled, with/without contextual menu actions and search. Does not capture screenshots, open a library, contact a device or invoke any data action. It is a shared-component regression check, not a full application interaction test.
