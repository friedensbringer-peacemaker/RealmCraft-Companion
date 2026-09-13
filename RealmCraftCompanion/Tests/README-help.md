# Bilingual help regression checks

Run from the Companion source directory. Tests use bundled public help and isolated temporary preferences/files, never a library or headset.

```sh
xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache -swift-version 5 Sources/HelpContent.swift Tests/HelpContentTests.swift -o /private/tmp/realmcraft-help-tests
/private/tmp/realmcraft-help-tests Resources
xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache -swift-version 5 Sources/HelpContent.swift Sources/CompanionLookup.swift Sources/HelpView.swift Sources/CompanionStyle.swift Sources/AppInfo.swift Tests/RenderHelp.swift -o /private/tmp/realmcraft-render-help
/private/tmp/realmcraft-render-help Resources /private/tmp/realmcraft-help-render
```

The graphics test needs native macOS graphics access. It renders 28 production-content samples at 640 points: DE/EN, Classic/Block world, entry page, Metro journey, ore 3D, material plan, setup, Quick find and build guides. Explicit color-scheme injection is required because `ImageRenderer` does not host a real window to apply `preferredColorScheme`. A black-on-dark initial harness image is not evidence of production-window behavior.

Inspect the PNGs for wrapping, headings, long numbered/bulleted lists and complete related-topic labels. Content rendering is not proof of native List or system-panel interaction.

Remaining isolated interactive acceptance:

1. Open embedded and separate Help; test DE/EN, both themes and 900 × 600 separate window.
2. Search a German term with English UI and vice versa. Use multiple tokens, no matches, and Clear. Sidebar selection and detail must agree.
3. Follow Related topics from a filtered result, use Previous topic, switch language and reopen a saved topic. Check scroll reset and keyboard/VoiceOver labels.
4. Scroll long ore, setup and material-plan articles; no horizontal clipping or unreachable footer.
5. Confirm setup links appear only in setup/transfer/troubleshooting; test source and agent export Cancel/success/missing-resource errors without sharing files.
6. Check focus, contrast and large text needs on real screens. No full accessibility certification or all-window acceptance is claimed by these automated tests.
