"""Synthetic translation exchange, scanner and native-resource regressions."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import translation_catalog as tc


def fixture():
    item = tc.entry("interface", "saved", {"de": "{0} Dateien gespeichert.", "en": "Saved {0} files."},
                    {"path": "translations.txt", "key": "{0} Dateien gespeichert."})
    return {"schemaVersion": 1, "sourceLanguage": "en", "entries": [item]}


class ExchangeTests(unittest.TestCase):
    def test_round_trip_preserves_source_and_sets_draft(self):
        catalog = fixture()
        pack = tc.export_pack(catalog, "fr")
        pack["entries"][0]["text"] = "{0} fichiers enregistrés."
        merged, count = tc.import_pack(catalog, pack)
        self.assertEqual(count, 1)
        self.assertEqual(catalog["entries"][0]["translations"], {})
        self.assertEqual(merged["entries"][0]["source"], catalog["entries"][0]["source"])
        self.assertEqual(merged["entries"][0]["translations"]["fr"]["status"], "draft")
        again, count = tc.import_pack(merged, tc.export_pack(merged, "fr"))
        self.assertEqual((again, count), (merged, 0))

    def test_all_or_nothing_when_later_entry_is_invalid(self):
        catalog = fixture()
        before = copy.deepcopy(catalog)
        pack = tc.export_pack(catalog, "fr")
        pack["entries"][0]["text"] = "{0} fichiers."
        pack["entries"].append(dict(pack["entries"][0], id="unknown"))
        with self.assertRaisesRegex(ValueError, "unknown"):
            tc.import_pack(catalog, pack)
        self.assertEqual(catalog, before)

    def test_conflicts_duplicates_and_injected_fields_rejected(self):
        for mutation in (lambda p: p["entries"].append(p["entries"][0]),
                         lambda p: p["entries"][0].update(sourceHash="old"),
                         lambda p: p["entries"][0].update(baseHash="old"),
                         lambda p: p["entries"][0].update(status="reviewed"),
                         lambda p: p.update(language="../../fr")):
            with self.subTest(mutation=mutation):
                pack = tc.export_pack(fixture(), "fr")
                mutation(pack)
                with self.assertRaises(ValueError):
                    tc.import_pack(fixture(), pack)

    def test_placeholder_identity_multiplicity_and_reordering(self):
        tc.check_translation("{0} / {1}", "{1} puis {0}")
        for text in ("aucun", "{1}", "{0} {0}"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                tc.check_translation("Saved {0}", text)

    def test_empty_does_not_erase_and_partial_packs_are_allowed(self):
        catalog = fixture()
        catalog["entries"][0]["translations"]["fr"] = {"text": "{0} fichiers", "status": "reviewed"}
        pack = tc.export_pack(catalog, "fr")
        pack["entries"][0]["text"] = ""
        self.assertEqual(tc.import_pack(catalog, pack), (catalog, 0))
        pack["entries"] = []
        self.assertEqual(tc.import_pack(catalog, pack), (catalog, 0))

    def test_duplicate_json_and_output_overwrite_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "example.json"
            path.write_text('{"language":"fr","language":"de"}')
            with self.assertRaisesRegex(ValueError, "Duplicate"):
                tc.read_json(path)
            with self.assertRaises(FileExistsError):
                tc.write_json(path, {})
            self.assertIn('"fr"', path.read_text())

    def test_source_edits_require_resync(self):
        catalog = fixture()
        catalog["entries"][0]["source"]["en"] = "Changed"
        with self.assertRaisesRegex(ValueError, "Source changed"):
            tc.validate(catalog)

    def test_native_build_uses_only_reviewed_english(self):
        catalog = fixture()
        item = catalog["entries"][0]
        item["translations"]["en"] = {"text": "Stored {0} files.", "status": "draft"}
        self.assertIn("Saved {0}", tc.render_interface(catalog)["en"])
        item["translations"]["en"]["status"] = "reviewed"
        self.assertIn("Stored {0}", tc.render_interface(catalog)["en"])
        item["translations"]["en"]["status"] = "needs-review"
        self.assertIn("Saved {0}", tc.render_interface(catalog)["en"])


class ExtractionTests(unittest.TestCase):
    def test_stable_sections_exclude_unrelated_history(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            (base / "Resources").mkdir()
            (base / "Sources").mkdir()
            (base / "translations.txt").write_text("")
            for name, heading in (
                ("CHANGELOG.md", "# 1.7.48 · Stable · 2026-09-13"),
                ("BACKLOG.md", "## Local stable baseline · 1.7.48 (70) · 2026-09-13"),
            ):
                (base / "Resources" / name).write_text(heading + "\n\nExisting saves stay unchanged.\n\n# Private history\nSynthetic private label.\n")
            entries, pending = tc.discover(base)
            self.assertEqual(len(entries), 2)
            self.assertFalse(pending)
            for item in entries:
                self.assertIn("Existing saves stay unchanged.", item["source"]["en"])
                self.assertNotIn("Synthetic private", item["source"]["en"])
                self.assertEqual(item["source"]["de"], "")

    def test_metro_assistant_sections_and_ui_are_inventoried(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            (base / "Resources").mkdir(); (base / "Sources").mkdir(); (base / "docs").mkdir()
            (base / "translations.txt").write_text("")
            (base / "Resources/CHANGELOG.md").write_text("## Metro network assistant candidate · 2026-09-13\n\nCompare three proposals.\n\n## Private history\nSynthetic private content.\n")
            (base / "Sources/MetroAutoPlanner.swift").write_text('func t(_ de: String, _ en: String) -> String { de }\nlet note = t("Gelände ungeprüft.", "Terrain unverified.")')
            entries, pending = tc.discover(base)
            self.assertEqual(len(entries), 2)
            self.assertFalse(pending)
            self.assertTrue(any(item["source"]["en"] == "Terrain unverified." for item in entries))
            self.assertTrue(any("Compare three proposals." in item["source"]["en"] for item in entries))
            self.assertTrue(all("Synthetic private" not in item["source"]["en"] for item in entries))

    def test_alignment_sections_keep_existing_document_identity(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            (base / "Resources").mkdir()
            (base / "Sources").mkdir()
            (base / "translations.txt").write_text("")
            path = base / "Resources/BACKLOG.md"
            ore = "## Ore UX first package · 1.7.47 (69) · 2026-09-13\n\nFit and zoom.\n\n"
            path.write_text(ore)
            original, _ = tc.discover(base)
            path.write_text("## Library alignment · 1.7.47 (69) · 2026-09-13\n\nAlign controls.\n\n" + ore + "## Private history\nSynthetic private label.\n")
            updated, _ = tc.discover(base)
            self.assertEqual(len(updated), 2)
            prior = next(item for item in updated if item["id"] == original[0]["id"])
            self.assertEqual(prior["source"], original[0]["source"])
            self.assertEqual(prior["sourceHash"], original[0]["sourceHash"])
            self.assertTrue(any("Align controls." in item["source"]["en"] for item in updated))
            self.assertTrue(all("Synthetic private" not in item["source"]["en"] for item in updated))
            path.write_text("## Screen density · 1.7.47 (69) · 2026-09-13\n\nReadable details.\n\n" + path.read_text())
            density, _ = tc.discover(base)
            self.assertEqual(len(density), 3)
            self.assertTrue(any("Readable details." in item["source"]["en"] for item in density))
            for prior in updated:
                current = next(item for item in density if item["id"] == prior["id"])
                self.assertEqual(prior["sourceHash"], current["sourceHash"])
            self.assertTrue(all("Synthetic private" not in item["source"]["en"] for item in density))

    def test_ore_document_sections_exclude_historical_private_notes(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            (base / "Resources").mkdir()
            (base / "Sources").mkdir()
            (base / "translations.txt").write_text("")
            (base / "Resources/BACKLOG.md").write_text(
                "BACKLOG\n\n## Ore UX first package · 1.7.47 (69) · 2026-09-13\n\nFit and zoom.\n\n"
                "## Older private notes\nPrivate synthetic world label.\n")
            entries, _ = tc.discover(base)
            self.assertEqual(len(entries), 1)
            self.assertIn("Fit and zoom.", entries[0]["source"]["en"])
            self.assertNotIn("Private synthetic", entries[0]["source"]["en"])
            self.assertEqual(entries[0]["source"]["de"], "")

    def scan(self, text):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "Example.swift"
            path.write_text(text)
            return tc.scan_swift(path, Path(folder))

    def test_swift_comments_nested_interpolation_and_raw_strings(self):
        text = r'''// english ? "Ignored" : "Ignoriert"
        /* nested /* "ignore" */ comment */
        let title = english ? "From \(a) to \(b)" : "Nach \(b) von \(a)"
        let detail = english ? "Value: \(choose("x", nested(1)))" : "Wert: \(choose("x", nested(1)))"
        let raw = english ? #"Say "hello""# : #"Sag "hallo""#
        Text("Library")
        '''
        items, pending = self.scan(text)
        self.assertEqual(len(items), 3)
        self.assertEqual(items[0]["source"], {"en": "From {0} to {1}", "de": "Nach {1} von {0}"})
        self.assertEqual(items[1]["source"]["en"], "Value: {0}")
        self.assertEqual(items[2]["source"]["en"], 'Say "hello"')
        self.assertIn("Library", [item["text"] for item in pending])

    def test_helper_argument_order_is_read_from_definition(self):
        for order, expected in (("de", {"de": "First", "en": "Second"}),
                                ("en", {"en": "First", "de": "Second"})):
            items, _ = self.scan(f'func t(_ {order}: String, _ other: String) -> String {{ "" }}\nt("First", "Second")')
            self.assertEqual(items[0]["source"], expected)

    def test_stable_resource_ids_survive_reordering_and_text_changes(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            path = base / "Items.json"
            data = [{"id": "stone", "title": {"de": "Stein", "en": "Stone"}},
                    {"id": "wood", "title": {"de": "Holz", "en": "Wood"}}]
            path.write_text(json.dumps(data))
            before = tc.scan_json(path, base)
            data[0]["title"]["en"] = "Rock"
            path.write_text(json.dumps(list(reversed(data))))
            after = tc.scan_json(path, base)
            self.assertEqual(before[0]["id"], after[1]["id"])
            self.assertNotEqual(before[0]["sourceHash"], after[1]["sourceHash"])

    def test_bilingual_lists_prefixes_suffixes_and_empty_side(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            path = base / "Help.json"
            path.write_text(json.dumps({"deTitle": "Hilfe", "enTitle": "Help", "notesDE": "Hinweis", "notesEN": "Note",
                                        "steps": {"de": ["Eins", "Zwei"], "en": ["One"]}}))
            items = tc.scan_json(path, base)
            self.assertEqual(len(items), 4)
            self.assertIn({"de": "Zwei", "en": ""}, [e["source"] for e in items])

    def test_source_refresh_preserves_and_invalidates_translations(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            (base / "Resources").mkdir()
            (base / "Sources").mkdir()
            legacy = base / "translations.txt"
            legacy.write_text("Hallo|||Hello\n")
            first = tc.sync(base)
            first["entries"][0]["translations"]["fr"] = {"text": "Bonjour", "status": "reviewed"}
            self.assertEqual(tc.sync(base, first), first)
            legacy.write_text("Hallo|||Welcome\n")
            updated = tc.sync(base, first)
            self.assertEqual(updated["entries"][0]["translations"]["fr"], {"text": "Bonjour", "status": "needs-review"})
            legacy.write_text("")
            retired = tc.sync(base, updated)
            self.assertEqual(len(retired["retiredEntries"]), 1)
            self.assertEqual(tc.sync(base, retired), retired)
            legacy.write_text("Hallo|||Welcome {0}\n")
            revived = tc.sync(base, retired)
            tc.validate(revived)
            self.assertEqual(revived["retiredEntries"], [])
            self.assertEqual(revived["entries"][0]["translations"]["fr"]["text"], "Bonjour")
            self.assertEqual(revived["entries"][0]["translations"]["fr"]["status"], "needs-review")
            # Unchanged stale translations can be exchanged, but never promoted.
            self.assertEqual(tc.import_pack(revived, tc.export_pack(revived, "fr")), (revived, 0))


class ProjectResourceTests(unittest.TestCase):
    def test_existing_native_translations_are_semantically_unchanged(self):
        base = Path(__file__).resolve().parents[1]
        catalog = tc.validate(tc.read_json(base / tc.CATALOG))
        tc.check_interface_sources(catalog, base)
        for code, content in tc.render_interface(catalog).items():
            def parse(text):
                result = {}
                for line in text.splitlines():
                    key, value = line.rstrip(";").split(" = ", 1)
                    result[json.loads(key)] = json.loads(value)
                return result
            existing = (base / "Resources" / f"{code}.lproj/Localizable.strings").read_text()
            self.assertEqual(parse(content), parse(existing))


if __name__ == "__main__":
    unittest.main()
