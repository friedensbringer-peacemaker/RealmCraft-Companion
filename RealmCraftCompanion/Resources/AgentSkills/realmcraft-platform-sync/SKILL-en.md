---
name: realmcraft-platform-sync
description: Compare RealmCraft Companion UI, UX, features and content across macOS, Android/Quest and GitHub Pages, and update requested differences using macOS as the leading reference.
---
# RealmCraft Platform Alignment

The macOS Companion is currently the leading reference for product behavior, features, content and design. Android/Quest and the hosted GitHub web edition follow it. A later explicit user decision may change this priority. Translate user intentions and outcomes into suitable platform conventions; identical pixels or unchecked desktop feature copies are not the goal.

## Scope and baseline

- For an audit request, deliver the comparison. For an update request, resolve the requested differences, including affected navigation, help and tests. Invoking this skill does not authorize publication, device installation or recurring monitoring. Existing authorization remains valid.
- Read applicable AGENTS.md files in the selected workspace and affected projects. Locate `RealmCraftCompanion`, `RealmCraftCompanionAndroid`, `RealmCraftWebDemo`, build scripts and deployment workflows with targeted searches. These are discovery hints, not mandatory paths. Identify independent ongoing changes before editing files.
- Record each platform's source revision/commit, app version, build artifact and, where relevant, installed/deployed version. Obtain the actual hosting URL from project configuration or repository metadata. Inspect it during a requested live comparison; do not infer deployed behavior from local files. Explicitly mark unavailable device, APK or live access as unverified.
- Check README claims against implementation and tests. At the initial baseline, Android is an independent prototype and the web edition is a static demo of selected features. Reassess this classification during each comparison.

## Comparison

Create a compact matrix: area/feature | macOS reference with evidence | Android | web | difference/priority | next action. Use clear states: equivalent, adapted for platform, missing, outdated, intentionally excluded or unverified. Support observations with files, tests or the actual inspected artifact. Intentional exclusion requires a documented product decision; technical obstacles are not evidence of that decision.

Within the requested scope, inspect:

- Navigation, naming, information structure, core workflows and discoverability; map, library, player/inventory, chests, build guides, recipes, AI context and skill management where present.
- Design and UX: hierarchy, colors, icons, readability, adaptive sizing, touch/Quest pointers, mouse/keyboard, focus, accessibility and loading, empty, error and confirmation states. Include back navigation and window/panel sizes.
- Functional behavior: data formats and catalogs, import/export, versioning, persistence, offline behavior, permissions and limits. Distinguish example/sandbox operations, saved copies and actual game access.
- German and English text, help, setup and understandable capability limitations. Missing translations remain explicit differences.

Prioritize data loss, misleading feature claims and blocked core workflows over cosmetic differences. Divide larger ports into verifiable increments. Do not copy known macOS defects; document the reference defect and correct it within the assignment.

## Update and validate

- Reuse catalogs, formats and logic where the architecture allows. Preserve provenance, domain limitations and existing user changes. Compare outcomes using the same synthetic test cases.
- Do not blindly translate desktop file access and ADB into Android permissions or browser code. Preserve import, backup and restore boundaries. Do not add a missing restore capability solely to match macOS.
- Local Qwen/LM Studio is an optional capability of each device. Browser localhost and Android localhost do not automatically address the Mac. Verify transport and model availability; do not invent a cloud fallback. AI translations are reviewable drafts; preserve code, placeholders and formats.
- Validate changed platforms using their existing builds and tests: macOS according to its build script; Android according to Gradle configuration, including relevant unit/lint checks; web according to its test and static build workflow. A successful build does not establish Quest usability, live parity or delivery.
- Creating and publishing additional screenshots is currently paused. Use existing evidence, source inspection and functional/UI checks without new screenshot files; only an explicit lifting of the pause permits new screenshots.
- Maintain affected help in both languages and update logs/backlogs in English with current app versions, newest entries first. Preserve the visible Codex project credit and Codex Astra as AI contributor.
- Publish only when authorized and from the designated reviewed public checkout. Inspect the actual files, archives and metadata under project rules. Real saves, personal exports, device identifiers and private paths do not belong in test cases or parity reports. Special demo permissions cover only the explicitly approved content.

## Deliverable

Report reference versions, key differences, completed changes, checks performed and remaining platform limitations. Distinguish locally changed, built, device-tested and published. For larger comparisons, link a sanitized report containing the matrix and prioritized follow-up work in the existing documentation area. Claim complete parity only within the demonstrably verified scope.
