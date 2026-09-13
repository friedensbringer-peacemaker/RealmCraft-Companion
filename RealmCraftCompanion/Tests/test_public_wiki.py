import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

BASE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('public_wiki', BASE/'Tools/build_public_wiki.py')
wiki = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wiki)

class WikiTests(unittest.TestCase):
    def test_deterministic_generation_and_preserved_candidate(self):
        with tempfile.TemporaryDirectory() as tmp:
            a, b = Path(tmp)/'a', Path(tmp)/'b'
            first = wiki.build(BASE, a)
            second = wiki.build(BASE, b)
            self.assertEqual(first, second)
            self.assertGreater(len(first['pages']), 10)
            for name in first['pages']:
                self.assertEqual((a/name).read_bytes(), (b/name).read_bytes())
            before = (a/'Home.md').read_bytes()
            with self.assertRaises(ValueError): wiki.build(BASE, a)
            self.assertEqual(before, (a/'Home.md').read_bytes())
            self.assertIn('Source version', (a/'Home.md').read_text())

    def test_missing_related_topic_rejected_without_partial_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)/'source'; (base/'Resources').mkdir(parents=True)
            (base/'Resources/PublicDocumentation.json').write_bytes((BASE/'Resources/PublicDocumentation.json').read_bytes())
            (base/'Resources/HelpArticles.json').write_text(json.dumps({'articles':[{'id':'start','related':['missing']}]}))
            out = Path(tmp)/'output'
            with self.assertRaises(ValueError): wiki.build(base, out)
            self.assertFalse(out.exists())

if __name__ == '__main__': unittest.main()
