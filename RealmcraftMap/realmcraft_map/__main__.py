import argparse
from pathlib import Path
import sys
import webbrowser
from .build import build


def main():
    parser = argparse.ArgumentParser(description='Realmcraft Atlas — local savegame to offline browser map')
    parser.add_argument('source', type=Path, help='World folder containing o.x,z / n.x,z files')
    parser.add_argument('-o', '--output', type=Path, default=Path('output'))
    parser.add_argument('--workers', type=int, default=16)
    parser.add_argument('--radius', type=int, help='Optional region around x=0,z=0 in blocks')
    parser.add_argument('--cache', type=Path)
    parser.add_argument('--cached-only', action='store_true', help='Build an explicitly partial preview from already imported chunks')
    parser.add_argument('--open', action='store_true', help='Open the completed map')
    args = parser.parse_args()
    if not 1 <= args.workers <= 64 or (args.radius is not None and args.radius < 0):
        parser.error('workers must be 1–64; radius must be nonnegative')
    try:
        result = build(args.source, args.output, workers=args.workers, radius=args.radius, cache=args.cache, cached_only=args.cached_only)
    except (OSError, ValueError) as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 1
    if args.open: webbrowser.open((args.output.resolve()/'index.html').as_uri())
    return 2 if result['errors'] or result.get('pending') else 0


if __name__ == '__main__':
    raise SystemExit(main())
