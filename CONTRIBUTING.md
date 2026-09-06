# Contributing

Describe the problem, the resulting behavior and relevant validation in pull requests. Keep changes focused and preserve German and English UI text.

Report bugs with synthetic examples and redacted error messages. Do not attach savegames, device serials, library manifests, AI exports, screenshots of personal worlds or diagnostic archives from a private workspace. Review screenshots and logs before posting them.

Before committing, inspect `git diff --cached` and run `python3 tools/check_publication.py --staged`. This is a conservative automated check, not a substitute for reviewing the selected files. Before publishing releases, inspect the entire archive and its metadata separately; source-code checks do not approve app binaries or archives.

Use a public Git author name and a GitHub noreply email address. Tests must build their own synthetic data and must not access a connected Quest or an actual backup library.

Development and build instructions live in each component's README. Update `RealmCraftCompanion/Resources/CHANGELOG.md` and `BACKLOG.md` in English when appropriate.
