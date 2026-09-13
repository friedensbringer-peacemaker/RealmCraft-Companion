# Crafting and voice retrieval regressions · 1.7.43

## Type-first browsing · 1.7.47

Compile `Sources/CraftingCatalog.swift` with `Tests/CraftingBrowseTests.swift` and run with `Resources/CraftingCatalog.json`. The suite covers type-before-material order, DE/EN family labels, longest-match distinctions, stable collation ties, unchanged filtered membership and unmodified material-specific boat ingredients. It does not establish in-game recipe availability.

Compile `Sources/CompanionFeature.swift`, `Sources/HelpContent.swift` and `Tests/CompanionNavigationTests.swift`; run with `Resources`. It verifies the shared displayed order, coverage of all 20 destinations, preserved shortcut case order and valid help targets.

`RenderCraftingBrowse.swift` captures the production CraftingView in a hidden native host, initially requested at 1080 × 700, with the bundled boat search, both languages/themes and isolated preferences. Native intrinsic sizing can expand the captured height; these are content/ordering checks, not viewport-fit acceptance. Use the CraftingUITestApp dependencies below plus `DraftTransitions`, `CompanionLookup`, `HelpContent`, `BuildMaterialHandoff`, `BuildGuideModels` and `ChestModels`. Pass the catalog path and a new temporary output directory. It does not initialize Model or a save library and does not open or save the material plan. Keyboard selection and all-family scrolling remain separate interactive checks.

Run from the Companion source directory, placing executables in a fresh temporary directory:

```sh
swiftc -parse-as-library Sources/CraftingCatalog.swift Tests/CraftingCatalogTests.swift -o /tmp/crafting-catalog-tests
/tmp/crafting-catalog-tests Resources/CraftingCatalog.json
swiftc -parse-as-library Sources/CraftingCatalog.swift Sources/PlanningStore.swift Sources/CraftingPlan.swift Tests/CraftingPlanTests.swift -o /tmp/crafting-plan-tests
/tmp/crafting-plan-tests Resources/CraftingCatalog.json
swiftc -parse-as-library Sources/CraftingCatalog.swift Sources/PlanningStore.swift Sources/CraftingPlan.swift Sources/CraftingConversation.swift Tests/CraftingConversationTests.swift -o /tmp/crafting-voice-tests
/tmp/crafting-voice-tests Resources/CraftingCatalog.json
swiftc -parse-as-library Sources/BuildGuideModels.swift Sources/ChestModels.swift Sources/CraftingCatalog.swift Sources/CraftingPlan.swift Sources/PlanningStore.swift Sources/CraftingConversation.swift Sources/ConversationKnowledge.swift Tests/ConversationTests.swift -o /tmp/conversation-tests
/tmp/conversation-tests Resources
```

Use the same dependencies with `Tests/CraftingTests.swift` to check the existing owned-stock route. `CraftingPlanTests` creates only temporary synthetic documents; it never initializes the save library. `CraftingUITestApp` is an isolated native QA shell accepting catalog and synthetic plan paths. It needs the crafting model/views, `ItemIcons`, `CompanionStyle` and `AppInfo`, not the application entry point or its `Model`.

Cases include shared-intermediate rounding, target/intermediate overlap, direct vs recursive scope, cycles and supply stops, explicit alternatives, unknown/stale choices, catalog changes, bounded quantities/depth, corruption and concurrent writes, German/English quantity questions and plurals, ID lookup, numbered recipe variants, context clearing and saved-plan scope. Passing these checks does not verify any recipe in RealmCraft.

Android's equivalent pure model and DOM-flow tests run with `node --test tools/crafting.test.cjs` from its repository. Native APK compilation, WebView interception and speech-service lifecycle still require Android build/instrumentation checks. Browser DOM checks do not establish microphone, installed-voice or Quest support.

`CraftingIconTests.swift` uses synthetic one-color PNG fixtures and isolated preferences, with no pack downloads. Compile it with `CraftingCatalog.swift`, `CraftingIcons.swift`, `ItemIcons.swift`, `CompanionStyle.swift` and `AppInfo.swift`; pass the source directory to the executable. It needs macOS graphics access. It compares native rendering for both packs/languages, explicit numeric mappings, neutral fallback, text-only mode and cache invalidation after pack removal. Include `CraftingIcons.swift` when compiling the standalone `CraftingUITestApp`.
