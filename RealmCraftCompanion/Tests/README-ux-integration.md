# UX integration regressions · 1.7.45

## 1.7.46 additions

The quick-find model suite now has 46 checks, including empty/single/combined category filters and result identity/order in both languages. Header geometry has 680 cases including contextual guidance at narrow widths. Draft-registry tests remain 13 behavioral checks; Metro call-site review additionally confirms that both connection links use the guarded `editEdge`. This is not a native reproduction of the Metro bug.

`RenderUsability.swift` uses a hidden native hosting view for the production search/sidebar and guided header at 1080 × 700 in DE/EN and both themes. Its navigation body is explicitly a fixture, not a screenshot of the whole Companion. Compile with `CraftingCatalog`, `BuildGuideModels`, `ChestModels`, `HelpContent`, `CompanionLookup`, `QuickFind`, `CompanionStyle`, `AppInfo` and `CompanionSearchSidebar`. Pass the Resources directory and a fresh temporary output directory. ImageRenderer alone cannot render AppKit-backed List/TextField/Menu and must not be used to claim their acceptance.

Native acceptance additions: type in the persistent top field, change all four categories, clear with Escape, test blocked draft navigation, select every collapsed tool via Go, use Home with no library, follow contextual help from each destination, close incomplete feedback with Save/Discard/Cancel and test a canceled/failed/successful ZIP save. Review guide rows and finish the plan in the same sheet; closing ends this import, and a fresh import adds quantities again. The old nested-sheet scenario below applies only to the previous release.

Run from the Companion source directory. All data is bundled reference content or synthetic temporary state; these tests do not initialize the application model, real library or device.

```sh
xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache Sources/DraftTransitions.swift Tests/DraftTransitionsTests.swift -o /private/tmp/realmcraft-draft-tests
/private/tmp/realmcraft-draft-tests
xcrun swiftc -module-cache-path /private/tmp/realmcraft-swift-module-cache Sources/CraftingCatalog.swift Sources/BuildGuideModels.swift Sources/ChestModels.swift Sources/HelpContent.swift Sources/CompanionLookup.swift Sources/QuickFind.swift Sources/PlanningStore.swift Sources/CraftingPlan.swift Sources/BuildMaterialHandoff.swift Tests/UXIntegrationTests.swift -o /private/tmp/realmcraft-ux-tests
/private/tmp/realmcraft-ux-tests Resources
```

The draft registry tests cover clean/live dirty state, Cancel, failed/successful Save, Discard, multiple registrations, nested save operations and prompt reentrancy. They inject decisions and do not show a modal alert.

Quick-find tests cover all four catalogs, both languages, no matches, unavailable catalogs and exact/fresh target identity. Handoff tests cover explicit numeric mapping, ambiguous materials, range rejection, bilingual agreement, included/omitted provenance, aggregation, preservation of recipe choices, old-plan decoding, round trips and bounded/atomic failure.

Run the existing crafting/Conversation and help suites as documented in their READMEs. The layout suite now exercises 620–1588-point content widths, both themes, translated actions, search and overflow; wide headers retain 64-point height, compact search/actions wrap and primary actions remain within the page.

Native acceptance remains required in an isolated demo environment:

1. Enter incomplete Metro, portal and ore-trial drafts. Test source, sidebar, in-feature selection, reload, setup, window close and Quit with Save / Discard / Cancel. Focus a text field before switching. Failed saves must keep the draft and original source.
2. Open two windows and cause stale portal/network/plan metadata writes. Ensure conflicts preserve both persisted state and the local draft; no silent overwrite.
3. Exercise compact Metro panes at minimum main-window size; all editing, map and journey actions must remain reachable. Resize ore 3D, Feedback and Build coach and use keyboard navigation.
4. Use Cmd-Shift-F, keyboard selection, Return and Escape in DE/EN. Open an exact result with destination filters already active; re-open the same result, then leave and return normally. Test no-result and missing-catalog messages.
5. Review a guide with unmapped materials and uncertain quantities. Change a row after confirmation (confirmation must reset), omit a row, open the nested plan, then cancel/save/reopen. Verify targets, unchanged recipe choices and provenance; do not interpret import history as current inventory.
6. Review long source titles, focus order, VoiceOver and contrast in both themes. Geometry/model tests and help-content renders do not substitute for this gate.

No install, publication, real-save modification, APK availability or Quest voice support is established by this suite.
