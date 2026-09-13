"""Synthetic tests only. No app, profile, device, or GUI access."""
import importlib.util
import json
from pathlib import Path
import stat
import tempfile
import unittest
import zipfile

TOOL = Path(__file__).resolve().parents[1] / "Tools/prepare_ui_audit.py"
spec = importlib.util.spec_from_file_location("audit_tools", TOOL)
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class AuditToolsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="realmcraft-audit-test-")
        self.root = Path(self.temp.name).resolve()

    def tearDown(self):
        # Only this test's generated synthetic fixture directory is removed.
        self.temp.cleanup()

    def archive(self, name="demo/world_data", mode=None):
        path = self.root / "demo.zip"
        with zipfile.ZipFile(path, "w") as target:
            entry = zipfile.ZipInfo(name)
            if mode is not None:
                entry.external_attr = mode << 16
            target.writestr(entry, b"synthetic fixture")
        return path

    def test_new_destination(self):
        self.assertEqual(audit.new_destination(self.root / "new"), self.root / "new")

    def test_existing_destination_is_preserved(self):
        sentinel = self.root / "keep.txt"
        sentinel.write_text("keep")
        with self.assertRaises(ValueError):
            audit.new_destination(self.root)
        self.assertEqual(sentinel.read_text(), "keep")

    def test_symlink_parent_and_dangling_target_rejected(self):
        link = self.root / "link"
        link.symlink_to(self.root, target_is_directory=True)
        with self.assertRaises(ValueError):
            audit.new_destination(link / "new")
        dangling = self.root / "dangling"
        dangling.symlink_to(self.root / "missing")
        with self.assertRaises(ValueError):
            audit.new_destination(dangling)

    def test_archive_hash(self):
        path = self.archive()
        audit.check_demo(path, audit.digest(path))
        with self.assertRaises(ValueError):
            audit.check_demo(path, "0" * 64)

    def test_unsafe_archive_paths(self):
        for name in ("../escape", "/absolute", "demo/../escape", "demo\\escape"):
            with self.subTest(name=name):
                path = self.archive(name)
                with self.assertRaises(ValueError):
                    audit.check_demo(path, audit.digest(path))

    def test_archive_symlink_rejected(self):
        path = self.archive(mode=stat.S_IFLNK | 0o777)
        with self.assertRaises(ValueError):
            audit.check_demo(path, audit.digest(path))

    def test_case_collisions_rejected(self):
        path = self.archive()
        with zipfile.ZipFile(path, "a") as target:
            target.writestr("DEMO/WORLD_DATA", b"collision")
        with self.assertRaises(ValueError):
            audit.check_demo(path, audit.digest(path))

    def test_template_is_open_not_accepted(self):
        record = audit.checklist({"version": "fixture"})
        self.assertEqual(len(record["screens"]), 20)
        self.assertTrue(all(row["status"] == "open" for row in record["screens"]))
        self.assertEqual(audit.coverage_errors(record), [])

    def test_source_inventory_still_matches(self):
        source = TOOL.parents[1] / "Sources/CompanionFeature.swift"
        cases = source.read_text().split("    case ", 1)[1].split("\n", 1)[0]
        self.assertEqual(set(c.strip() for c in cases.split(",")), set(audit.FEATURES))

    def test_false_pass_is_rejected(self):
        record = audit.checklist({})
        record["screens"][0]["status"] = "passed"
        errors = audit.coverage_errors(record)
        for fragment in ("gate", "visual", "pane", "control", "states"):
            self.assertTrue(any(fragment in error for error in errors), errors)

    def test_incomplete_inventory_rejected(self):
        record = audit.checklist({})
        record["screens"].pop()
        self.assertTrue(audit.coverage_errors(record))

    def test_invalid_schema_and_status_rejected(self):
        self.assertTrue(audit.coverage_errors([]))
        self.assertTrue(audit.coverage_errors({"schema": 99}))
        record = audit.checklist({})
        record["screens"][0]["status"] = "perfect"
        self.assertTrue(audit.coverage_errors(record))

    def test_documented_bounded_pass(self):
        record = audit.checklist({})
        record["gate"] = "passed"
        row = record["screens"][0]
        row.update(status="passed", evidence=[{"kind": "visual", "ref": "private-evidence-1"}],
                   states={state: "excluded" for state in audit.STATES},
                   panes=[{"id": "main", "endObserved": True, "evidence": "private-evidence-2"}],
                   controls=[{"id": "navigate", "status": "passed", "evidence": "private-evidence-3"}],
                   exceptions=["Synthetic scope only; state tests excluded. Not full acceptance."])
        self.assertEqual(audit.coverage_errors(record), [])


if __name__ == "__main__":
    unittest.main()
