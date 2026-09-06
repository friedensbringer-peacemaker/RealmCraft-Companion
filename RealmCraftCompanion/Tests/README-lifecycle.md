# Companion instance lifecycle

Run the deterministic tests from the project directory:

```sh
xcrun swiftc -swift-version 5 Sources/CompanionLifecycle.swift Tests/CompanionLifecycleTests.swift -o /tmp/companion-lifecycle-tests -framework SwiftUI -framework AppKit
/tmp/companion-lifecycle-tests
```

The test file supplies a minimal Model. Do not compile it alongside the application's main.swift.

The cases cover asynchronous normal termination, refusal, timeout, already-terminated instances, an empty list, cancellation, termination during the request, and malformed helper arguments. No running application is closed by these tests.

Manual integration review should use two disposable GUI instances with their own bundle identifier. Check that restarting leaves one new PID, quitting leaves none, and a simulated busy instance prevents restart. The production implementation only targets its own bundle identifier, uses normal termination, and retains the existing transfer guard.
