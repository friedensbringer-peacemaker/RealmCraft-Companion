import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("helper_diagnostics", Path(__file__).resolve().parents[1] / "Tools/audit_helper_diagnostics.py")
diagnostics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diagnostics)


class DiagnosticTests(unittest.TestCase):
    def test_allowlisted_aggregate_and_dynamic_image_index(self):
        with tempfile.TemporaryDirectory(prefix="audit-diagnostic-test-") as directory:
            path = Path(directory) / "synthetic.ips"
            report = {"procName": "SkyComputerUseService", "procPath": "/PRIVATE/DO-NOT-EXPORT",
                      "crashReporterKey": "PRIVATE-KEY", "bundleInfo": {"CFBundleShortVersionString": "fixture"},
                      "exception": {"type": "EXC_BREAKPOINT", "signal": "SIGTRAP"},
                      "usedImages": [{"name": "other"}, {"name": "SkyComputerUseService"}],
                      "threads": [{"triggered": True, "frames": [
                          {"symbol": "_assertionFailure(_:)", "imageIndex": 0},
                          {"symbol": "Array.remove(at:)", "imageIndex": 0},
                          {"imageIndex": 1, "imageOffset": 123}]}]}
            path.write_text(json.dumps({"header": "PRIVATE"}) + "\n" + json.dumps(report))
            result = diagnostics.summarize([path, path])
            self.assertEqual(result["reports"], 2)
            self.assertEqual(result["signatures"][0]["helperOffset"], 123)
            self.assertTrue(result["signatures"][0]["arrayRemoval"])
            self.assertNotIn("PRIVATE", json.dumps(result))

    def test_invalid_report_is_counted_without_content(self):
        with tempfile.TemporaryDirectory(prefix="audit-diagnostic-test-") as directory:
            path = Path(directory) / "bad.ips"
            path.write_text("private broken report")
            result = diagnostics.summarize([path])
            self.assertEqual(result["unreadableOrUnrelated"], 1)
            self.assertEqual(result["reports"], 0)
            self.assertNotIn("private broken", json.dumps(result))


if __name__ == "__main__":
    unittest.main()
