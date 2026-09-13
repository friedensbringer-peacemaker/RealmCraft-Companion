---
name: realmcraft-public-docs
description: Refresh the RealmCraft Companion GitHub wiki and versioned demo screenshot gallery from current app help. Use for requested documentation or screenshot updates, not unrelated feature development.
---
# RealmCraft public documentation

Use the user's selected checkout and its publication rules. App help is the source of truth: `RealmCraftCompanion/Resources/HelpArticles.json` and referenced Resources documents. Shared wiki wording and screenshot records live in `Resources/PublicDocumentation.json`. Generated wiki pages are derivatives; change the source, not a second independent manual.

## Refresh the wiki

- Check source version in `build.sh`, actual bundle version and current public release separately. Do not label source-only features as already downloadable. Preserve Beta labels, unknown data, manual confirmation steps and platform differences.
- Update only affected help in DE/EN. Synchronize and inspect the central translation catalog, preserving existing translations and retired entries. Run its check and relevant tests.
- Run `python3 RealmCraftCompanion/Tools/build_public_wiki.py --output <new-directory>` from the project root. It creates English pages with stable help IDs, related links and a source manifest. Review the output and screenshot links. Existing output directories are rejected to preserve older candidates.
- Wiki pages use a separate Git repository (`<project>.wiki.git`). If it does not exist, create the first Home page through GitHub's authenticated Wiki UI, then clone it. Preserve independently authored pages. Copy only the reviewed generated files, inspect the exact staged diff and use the public account and GitHub noreply email. Publish only within the current user authorization.
- A timeout or 5xx response does not establish success or failure. Read back the exact object/ref before retrying. Bound retries; never create repeated release drafts or publish temporary placeholders as finished documentation.

## Refresh screenshots

- Use a newly built, verified app when the installed version is older. Record version/build and source hash. Preserve previous version galleries.
- Use `Tools/prepare_ui_audit.py prepare` with the explicitly approved demo ZIP and pinned SHA-256. Its launcher verifies isolated Foundation home/support/cache paths and disables ADB. Never capture the normal personal profile or copy its preferences, maps, skills, exports or library.
- Launch the isolated app, verify `launch-check.json`, import only the approved demo through the normal import workflow and inspect the library before capture. Use real UI states and the existing map/3D tools; label synthetic plans and illustrative state explicitly. Do not present a reference guide as a built demo structure or an old image as a current capture.
- Capture only the app window, in English for the public gallery. Show representative outcomes rather than empty controls. Record which screenshots are real demo views, bundled reference content or synthetic examples. Keep diagnostics and incomplete/private UI outside published files.
- Inspect every image visually. Strip PNG text/EXIF/time and other identifying metadata without inventing or repainting UI content. Store new images under `docs/screenshots/v<version>/`; record hashes and captions in the public documentation resource and the exact-image publication allowlist. Replacing an image requires another review.

## Integrate and verify

Keep this bilingual skill in bundled `Resources/AgentSkills/realmcraft-public-docs` so it appears in Assistant instructions and can be exported. Install the English SKILL entrypoint in the agent's skill directory when requested. Include the wiki generator and audit launcher in source packaging/public export.

Check generated links, deterministic generation, source checksums, catalog freshness, privacy rules, image allowlists and embedded archives before committing. Verify the remote wiki and main repository separately after publishing. A successful source push does not prove the wiki, screenshots or downloadable app were updated. Report the actual published and built versions and any remaining gap. Keep the credit **100% vibe-coded with OpenAI Codex** and **Codex Astra** visible.
