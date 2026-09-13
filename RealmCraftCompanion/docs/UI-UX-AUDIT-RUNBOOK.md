# Repeatable native audit preparation

This is development tooling, not a Companion feature release. Continue the findings
and IDs in [the current audit](UI-UX-AUDIT-2026-09-12.md). The
`realmcraft-ui-ux-audit` skill supplies the review and consent rules.

## 1. Prepare a fresh, bounded profile

Requires macOS, Python 3.11+ and the Xcode command-line Swift compiler. Use a verified
frozen app, not a concurrently changing source directory. Select **one explicitly
approved Demo ZIP** and its independently recorded SHA-256; a checksum does not
itself authorize using or publishing an arbitrary save.

From the Companion source directory, substitute actual reviewed paths:

```sh
python3 Tools/prepare_ui_audit.py prepare --app /path/to/verified/Companion.app --output /private/tmp/new-audit-directory --approved-demo /path/to/approved-demo.zip --demo-sha256 EXPECTED_SHA256
```

Omit both Demo arguments for a separate empty-library scenario. Always use a new
output directory. Do not empty or delete an existing profile to reset a scenario.
Preparation rejects existing destinations, symlink path components, unverified
bundle signatures, unsafe/duplicate/symlink ZIP members and oversized archives.
Failures retain their partial output for inspection; nothing is installed or cleaned
up automatically. App files are independent copies, not hardlinks to the baseline.

Outputs:

- `RealmCraft Audit.app`: the same application executable content, a separate
  audit-only launcher and unique bundle ID. Bundle metadata and signatures differ.
- `Profile`: new Foundation home, Application Support and caches. No personal
  library, preferences, optional icon pack, map cache or agent-instruction store is
  copied. Consequently an empty cache/missing optional pack is a deliberate state,
  not a regression in the production profile.
- `audit-manifest.json`: baseline version/build, original and audit signed hashes,
  matching unsigned executable hash, approved Demo archive hash and open gates.
- `Verification`: stripped **copies** used to verify unchanged executable content.
  Do not launch them. The original signed bundle is never stripped or modified.
- `coverage.json`: 20 destinations and six cross-feature journeys, initially open.
- `launch-check.json`: a Foundation path-check receipt; preparation creates one in
  a headless preflight. Its mere existence does **not** prove a GUI launch occurred.

The tool invokes only the copied Companion's CLI import and integrity verification
when a Demo was supplied. It does not start the GUI or communicate with a Quest.
ADB is set to `/usr/bin/false` for CLI preparation and ordinary audit GUI startup.

### Isolation boundary

This is **data-path isolation, not an operating-system security sandbox**. The user
still has normal filesystem/network permissions. Do not browse personal folders,
change the audit library/ADB configuration, enable cloud backup, install assets,
download models, use the microphone, share files or perform device operations.
Save/draft test actions still require the agreed scope; Delete remains forbidden.
Do not exercise the app's Restart command in this wrapper; lifecycle/relaunch is a
separate production-binary acceptance test.

The wrapper checks the actual Foundation home/support/cache paths and refuses to
start if they do not match the new profile. It uses the process-scoped
`CFFIXED_USER_HOME` behavior, validated on the current host; this is not a supported
portable sandbox API. Do not change `HOME`, global defaults, permissions or launchd
configuration. A new bundle ID separates app preferences; system-global preferences
and the ordinary macOS temporary directory are not isolated. UUID-scoped temporary
files remain ordinary temporary files, so do not claim whole-OS isolation.

Apple documents that [LSEnvironment applies to launches through Launch
Services](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html).
Open the **audit app bundle** through the approved UI tool, never its inner target
executable. Do not move the generated folder: the launcher intentionally rejects a
moved bundle. After an OS change, rerun preparation/preflight and the native gate.

## 2. Controlled native stability gate

The September 12 failure was a helper assertion, not a proven Companion crash.
Preparation cannot repair that helper. Ask before any Codex restart/update,
permission change, process termination or other disruptive intervention.

1. Obtain approval to launch the separately signed audit environment. Leave the
   current Companion and any drafts untouched. Record the manifest baseline.
2. Open the exact audit bundle path through the approved UI tool. Record launch
   success separately from the headless receipt. Confirm **only the approved Demo**
   appears, no original preferences/history are visible and the real library was
   not selected. Verify the target is the unique audit bundle before proceeding.
3. Inspect Home, Help, then one previously failing screen. Separate action,
   screenshot and accessibility retrieval calls. Automatic initial AX retrieval by
   the tool must be recorded as such; do not call it a screenshot-only trial.
4. On a native-pipe failure, stop this gate, take a read-only helper signature
   summary and compare it with the prior signature. No automatic retry loop.
5. If the same fault recurs, ask for a single clean restart only if appropriate,
   or continue with a user-operated walkthrough. No permission reset, cache
   deletion, reinstall or full-Codex automation workaround.

Optional read-only summary (select exact reports or a bounded date pattern):

```sh
python3 Tools/audit_helper_diagnostics.py /path/to/selected-helper-report.ips
```

This emits aggregate version/build, exception, signal and helper offset plus two
known-stack flags. It omits paths, process/device IDs, raw stack text, account data
and report content. Malformed/unrelated reports are counted, not printed. Review
even this small summary before external sharing; no report is sent automatically.

## 3. Record complete screens, not initial viewports

First inventory the actual panes, expanded sections, dialogs and safe controls of
each destination; the generated rows deliberately do not invent this inventory.
Capture top and overlapping intermediate views through **each pane's visible end**.
Record load, switch, detail, back, filter and no-result-recovery actions before and
after. Re-read accessibility indices after navigation. Use only documented scroll
actions; a requested scrollbar value is not proof the bottom was reached.

Each evidence entry is `{ "kind": "visual", "ref": "private-evidence-id" }` (other
kinds are listed in the generated record). Each pane needs `id`, `endObserved`,
`evidence`; each control needs `id`, `status`, `evidence` and preferably expected/
actual results and its risk classification. An excluded control needs its reason
in `exceptions`. Never press Delete just to cover a button.

`passed` means the documented, bounded screen scope passed, not universal feature
acceptance. `keyboard`, `voiceOver`, language/theme/window combinations and all six
journeys are separate open fields. Record DE/EN, Block/Classic, normal/minimum
window and actual focus/VoiceOver observations explicitly. Source and AX evidence
alone cannot pass a visual screen. No test tool can verify that a human supplied
truthful evidence or inventoried every control; reviewer sign-off remains required.

```sh
python3 Tools/prepare_ui_audit.py validate-coverage /private/tmp/new-audit-directory/coverage.json
```

Validation rejects missing/duplicate destinations and unsupported claims of screen
completion without a gate, visual evidence, end positions, control outcomes and
resolved state exceptions. A valid all-open record is not an accepted application.
Assisted screenshots must be labeled `assisted-visual`, never automated interaction
or keyboard/VoiceOver evidence. Keep screenshots/records local; publication needs a
separate Demo-only content and metadata review.

## 4. Ordered follow-up investigation

1. Finish untouched Ore, Crafting/material plan, Mobs, Links & Knowledge,
   Statistics, Tectonicus, Editor, AI export and Assistant instructions; finish
   library visuals. Observe Editor/transfer states without writing data.
2. Complete remaining panes/buttons on previously visited screens, all Help
   chapters, safe dialogs and no-result/error recovery.
3. Complete the six recorded user journeys with bounded Demo tasks. Rendering,
   error injection and draft writes get their own scope approval where needed.
4. Complete language/theme/window/focus/VoiceOver checks and a small observed
   newcomer task test. Preserve all technical capabilities and safety warnings.
5. Reconcile findings, evidence and status in the existing audit/Feature Map and
   Backlog. Prepare a UI implementation package; do not mark UX-018–023 fixed just
   because these development tools passed.

## Regression checks

```sh
python3 -m unittest discover -s Tests -p 'test_*audit*.py' -v
```

These synthetic tests do not launch apps, read real savegames or call devices.
They clean only their own newly generated synthetic temporary test fixtures.
