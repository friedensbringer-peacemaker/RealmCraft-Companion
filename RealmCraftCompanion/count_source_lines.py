"""Count non-empty source lines (including comments) for release milestones."""
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parent
extensions = {'.swift', '.py', '.js', '.cjs', '.mjs', '.html', '.css', '.sh'}
excluded = {'vendor', 'node_modules', '__pycache__', '.build'}
groups = {'application': [], 'tests': [], 'build_and_tools': []}
for folder, group in [('Sources', 'application'), ('Resources', 'application'), ('Tests', 'tests')]:
    groups[group].extend(
        path for path in (root / folder).rglob('*')
        if path.is_file() and path.suffix in extensions
        and not excluded.intersection(path.relative_to(root).parts)
    )
groups['build_and_tools'] = [
    path for path in root.iterdir() if path.is_file() and path.suffix in extensions
]
version = re.search(
    r'<key>CFBundleShortVersionString</key><string>([^<]+)</string>',
    (root / 'build.sh').read_text()
).group(1)
counts = {}
for group, paths in groups.items():
    counts[group] = {
        'files': len(paths),
        'nonempty_lines': sum(
            sum(bool(line.strip()) for line in path.read_text().splitlines())
            for path in paths
        ),
    }
print(json.dumps({
    'version': version,
    'scope': 'Current source snapshot; non-empty lines including comments, not logical statements.',
    'groups': counts,
    'total_nonempty_lines': sum(value['nonempty_lines'] for value in counts.values()),
}, indent=2))
