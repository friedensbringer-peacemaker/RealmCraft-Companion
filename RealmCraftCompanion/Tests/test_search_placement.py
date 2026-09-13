"""Source-contract checks for list-local search; not a native interaction test."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1] / "Sources"


class SearchPlacementTests(unittest.TestCase):
    def test_local_search_is_not_in_page_header(self):
        for name in ["BuildGuidesView", "CraftingView", "HelpView", "AgentSkillsView", "ResourcesView", "MobsView"]:
            text = (ROOT / (name + ".swift")).read_text()
            headers = re.findall(r"CompanionPageHeader\(.*?\n            \}", text, re.S)
            self.assertTrue(headers, name)
            for header in headers:
                self.assertNotRegex(header, r"TextField\([^\n]*(?:\$query|\$search)", name)

    def test_original_query_bindings_remain(self):
        for name, count in [("BuildGuidesView", 2), ("CraftingView", 1), ("AgentSkillsView", 1), ("MobsView", 1), ("ResourcesView", 2)]:
            text = (ROOT / (name + ".swift")).read_text()
            self.assertEqual(len(re.findall(r"TextField\([^\n]*text: \$query\)", text)), count, name)

    def test_help_keeps_accessible_search_and_clear(self):
        text = (ROOT / "HelpView.swift").read_text()
        self.assertIn('.accessibilityIdentifier("help.search")', text)
        self.assertIn('Button { search = "" }', text)

    def test_mob_empty_state_does_not_replace_search_pane(self):
        text = (ROOT / "MobsView.swift").read_text()
        search = text.index('TextField(english ? "Search name')
        empty = text.index("if entries.isEmpty")
        self.assertLess(search, empty)
        self.assertNotIn("else if entries.isEmpty", text)

    def test_comparison_shares_parent_query(self):
        text = (ROOT / "ResourcesView.swift").read_text()
        self.assertIn("MinecraftComparisonView(english: english, query: $query)", text)
        self.assertIn("@Binding var query: String", text)

    def test_chest_search_precedes_locations(self):
        text = (ROOT / "ChestsView.swift").read_text()
        self.assertIn("searchField.padding(16)\n                    List(locations", text)


if __name__ == "__main__":
    unittest.main()
