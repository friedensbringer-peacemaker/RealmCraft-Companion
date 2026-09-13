"""Generate native tr() resources from the central translation catalog."""
import argparse
from pathlib import Path

from translation_catalog import CATALOG, check_interface_sources, read_json, render_interface, validate


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="Alternate resource directory for isolated verification")
    args = parser.parse_args()
    base = Path(__file__).resolve().parent
    catalog = validate(read_json(base / CATALOG))
    check_interface_sources(catalog, base)
    for language, content in render_interface(catalog).items():
        folder = (args.output or base / "Resources") / f"{language}.lproj"
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "Localizable.strings").write_text(content, encoding="utf-8")
    count = sum(item["kind"] == "interface" for item in catalog["entries"])
    print(f"Localized {count} native interface strings from the central catalog (DE/EN)")


if __name__ == "__main__":
    main()
