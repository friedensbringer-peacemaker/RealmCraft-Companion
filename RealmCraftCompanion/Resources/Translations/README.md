# Community translations / Community-Übersetzungen

The central working file is **[catalog.json](catalog.json)**. It contains the existing German and English text, stable inventory IDs, source locations, translator notes and a place for additional languages. It is a translation workspace, not a declaration that the whole app already supports more languages.

100% vibe-coded with OpenAI Codex. AI contributor: Codex Astra.

## Deutsch: so kannst du mitarbeiten

1. Exportiere eine Sprache oder einen kleinen Teilbereich mit den Befehlen unten. Die JSON-Datei lässt sich in einem Texteditor oder mit Agentenunterstützung bearbeiten.
2. Übersetze ausschließlich die Felder `text`. Deutsch und Englisch stehen zum Vergleich in `source`. `context` zeigt, wo der Text verwendet wird. Vollständige Meldungen und Absätze bleiben zusammen, damit Satzbau und Bedeutung erhalten bleiben.
3. Erhalte Platzhalter wie `{0}` und `{1}` exakt. Ihre Reihenfolge darf sich ändern; ihre Anzahl nicht. IDs, Befehle, Links, technische Namen und Unsicherheits-/Sicherheitshinweise müssen erhalten bleiben. Unklare Begriffe separat erläutern.
4. Importiere die Datei zur Prüfung. Es entsteht eine **neue** Katalogdatei; vorhandene Übersetzungen werden nicht automatisch überschrieben. Importierte Änderungen erhalten den Status `draft`.
5. Teile das Sprachpaket oder reiche es über einen GitHub-Pull-Request ein. Eine zweite sprachkundige Person prüft die Bedeutung und den Kontext. Agenten liefern Entwürfe; sie erklären eigene Übersetzungen nicht selbst für geprüft.

Neue Sprachen wie Französisch oder Spanisch können bereits gesammelt werden. In der laufenden App bleiben zunächst Deutsch und Englisch auswählbar. Die vollständige Laufzeitanbindung, ein Übersetzungseditor in den Einstellungen und native Import-/Export-/Teilen-Schaltflächen sind noch geplant. Der aktuelle Import/Export erfolgt über das lokale Werkzeug.

## Commands

Run these commands from the `RealmCraftCompanion` source directory. Python 3.10 or later is sufficient; no service account, API key or network connection is required. Output files must not already exist. Pick another filename for each revision.

```sh
# Validate the catalog against the current source and show coverage.
python3 translation_catalog.py check
python3 translation_catalog.py status

# A small first contribution: the legacy native interface vocabulary.
python3 translation_catalog.py export --language fr --kind interface --output /tmp/companion-fr-interface-v1.json

# The complete language pack, including reference content and source inventory.
python3 translation_catalog.py export --language fr --output /tmp/companion-fr-all-v1.json

# Validate the edited pack and write a new, reviewable catalog.
python3 translation_catalog.py import /tmp/companion-fr-interface-v1.json --output /tmp/companion-catalog-fr-v1.json

# Work from that reviewed candidate without overwriting the original.
python3 translation_catalog.py --catalog /tmp/companion-catalog-fr-v1.json status

# Refresh the inventory after source text changes; inspect the diff before adoption.
python3 translation_catalog.py sync --output /tmp/companion-catalog-refreshed-v1.json

# Build existing native translation resources into a separate directory.
python3 make_localizations.py --output /tmp/companion-localization-preview-v1

# Run the synthetic exchange and extraction regression suite.
python3 -m unittest discover -s Tests -p test_translation_catalog.py
```

Available scopes for `--kind`: `interface`, `swift`, `resource`, `map`, `document`. Repeat the argument to combine scopes. A pack may contain only the rows a contributor wants to translate. Empty `text` means “not translated”; it never deletes an existing translation. Share the exported JSON as an ordinary file; no sharing service is called by the tool.

## Format and review

The master catalog has `schemaVersion: 1`. Every entry has:

| Field | Meaning |
| --- | --- |
| `id` | Unique inventory identity; never translate or renumber it. |
| `kind` | Interface, source-code, map, document or structured-resource scope. |
| `source.de`, `source.en` | Existing source text, captured by `sync`; edit the source implementation to change these baselines. |
| `sourceHash` | Fingerprint of both source languages; blocks imports based on a different source. |
| `references` | Relative file path and line, key or semantic resource location. |
| `translations.fr.text` | Example target translation. Other language codes work the same way. |
| `translations.fr.status` | `draft`, `reviewed`, or `needs-review`. Only a human reviewer promotes a draft. |
| `note` | Translator context or an integration caveat. |

The existing DE/EN texts are captured as baselines, **not certified as linguistically reviewed**. The exchange format adds a `baseHash` for the existing target translation, preventing one contribution from silently replacing another. Unknown/duplicate IDs, duplicate JSON keys, changed source, target conflicts, invalid locale codes, NUL characters and missing/extra numbered placeholders reject the complete import. It writes no code, resource, app preference or world data. The JSON input is never executed. `context` and `note` in an imported pack are informational and do not replace the catalog's trusted references or notes.

When source text changes, resource and interface IDs remain stable through their keys or object IDs. Existing target text is retained as `needs-review`. Swift inventory IDs are based on file and literal pair: changing that pair retires the old entry and introduces a new one. Old entries and their translations remain in `retiredEntries`. A later migration to explicit semantic runtime keys will remove this source-code limitation. Array entries without a unique source object ID use their index and require special care when reordered.

## Current runtime integration and coverage

`make_localizations.py` reads this catalog to generate the existing DE/EN `Localizable.strings` used by `tr()`. Reviewed English overrides for `interface` entries are supported; drafts and stale translations fall back to existing text. It refuses a stale legacy-interface baseline. The legacy `translations.txt` remains the developer input for adding/changing those keys during migration. German lookup strings still serve as runtime keys, so German source wording must be changed in its callers as well.

The remaining entries are collected for translation and review. Importing their text does **not** yet replace Swift branches, Markdown documents, maps or content catalogs. Additional locales are not advertised as selectable until their runtime adapters exist. Do not describe a successful pack import as app-wide language activation.

The extractor covers the legacy interface file, `MapEnglish.json`, paired language fields and lists in top-level resource JSON files, bilingual setup/transfer Markdown documents, and recognized literal Swift language branches/helper calls. It understands the reversed argument order of the Setup helper and keeps interpolated values out of text. Resource arrays use unique item IDs where available. Repeated phrases in distinct contexts remain separate, because “Open”, “Save” and similar terms may need different translations.

`coverage.complete` deliberately remains `false`. `coverage.unclassifiedSwiftLiterals` contains potential remaining prose with source locations. Some rows are technical text rather than UI; they need classification. Computed branches, single-language fields, embedded map scripts/Python, other document forms and Android/web require further extraction/adapters. Multiline/raw Swift strings need layout review. No automatic extraction can certify linguistic or visual completeness. This file contains authored project text; user world names, signs, savegames and other personal content must never be added to a shared language pack.

## GitHub contribution workflow

1. Fork the existing Companion repository and create a translation branch. Export the desired language/scope from its source version.
2. Translate the pack, import it to a new candidate and inspect the diff. Keep unrelated changes out of the contribution. Source baselines, IDs and evidence metadata must not be translated.
3. After review, adopt the candidate as `Resources/Translations/catalog.json` in that branch. Mark only the individually reviewed translations as `reviewed` in the master catalog; imports cannot assign that status.
4. Run `translation_catalog.py check`, the translation tests and isolated resource generation. For eventual runtime changes also test long text, both themes, keyboard/accessibility labels, placeholder rendering and every affected locale.
5. Open a pull request stating language, scopes, entry count, translator/reviewer, unresolved terms, source revision and validation. Publication and merge remain normal repository actions; the translation tool has no GitHub credentials and performs no upload.

Suggested CI commands, executed from the macOS source folder:

```sh
python3 translation_catalog.py check
python3 -m unittest discover -s Tests -p test_translation_catalog.py
python3 make_localizations.py --output /tmp/translation-ci-resources
```

These commands are ready for the repository's existing CI workflow. This source change does not install a GitHub Action, create a pull request or publish a language pack. Maintain the project's normal review of the exact publication contents, including the bundled source archive.

## Agent translation brief

> Translate only `text` in the supplied RealmCraft language pack into the requested locale. Use both source languages and context. Preserve placeholder identity/multiplicity, technical names, commands, links, Markdown structure, safety statements and evidence uncertainty. Do not infer game mechanics from Minecraft or make claims more certain. Keep naming consistent, but distinguish contexts. Leave uncertain text empty and report the entry IDs separately. Do not modify IDs, hashes, source, language, context or schema. Return valid UTF-8 JSON, with no executable content. All suggestions remain drafts for independent human review.

## Planned app experience

Settings → Language & translations should show available languages and reviewed/missing/stale counts. Export should support a whole language or a selected feature. Import should show a diff, conflicts and coverage before applying a versioned local pack; switching language should respect existing draft guards. Share should open the system share sheet only after an explicit click. Provide a local reset to the bundled version and an explicit “Contribute on GitHub” link.

Runtime adapters should use semantic keys, named/typed placeholders, plural rules and locale-aware dates/numbers, with selected locale → English → original fallback. Treat maps and the independently built Android/web apps as separate adapters to the same schema. Right-to-left layout, font coverage and full-screen acceptance must be verified before declaring a locale supported. A glossary of preferred game terms should reference catalog entries and record context/variants; it must not replace complete sentences with word-by-word substitution.
