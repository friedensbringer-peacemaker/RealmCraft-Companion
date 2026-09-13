"""Local translation inventory and reviewable language-pack exchange. Standard library only.

Source extraction is deliberately conservative: unclassified Swift literals are reported,
never guessed to be translations. No imported text is evaluated or written into code.
"""
from __future__ import annotations

import argparse
from collections import Counter
import copy
import hashlib
import json
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
CATALOG = Path("Resources/Translations/catalog.json")
LANGUAGE = re.compile(r"[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*\Z")
PLACEHOLDER = re.compile(r"\{[0-9]+\}")
MAX_BYTES = 64 * 1024 * 1024


def fingerprint(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path):
    if path.stat().st_size > MAX_BYTES:
        raise ValueError("JSON exceeds the 64 MiB limit")
    return json.loads(path.read_text(encoding="utf-8-sig"), object_pairs_hook=unique_object)


def write_json(path, value, *, replace=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    # New output files are exclusive; imports never overwrite their input catalog.
    with path.open("w" if replace else "x", encoding="utf-8") as out:
        json.dump(value, out, ensure_ascii=False, indent=2)
        out.write("\n")


def language_code(value):
    if not isinstance(value, str) or not LANGUAGE.fullmatch(value):
        raise ValueError(f"Invalid language code: {value!r}")
    return value


def placeholders(text):
    return Counter(PLACEHOLDER.findall(text))


def check_translation(source, text):
    if not isinstance(text, str) or len(text) > 250_000 or "\0" in text:
        raise ValueError("Translation must be text without NUL (maximum 250,000 characters)")
    if text and placeholders(source) != placeholders(text):
        raise ValueError("Numbered placeholders must occur exactly as often as in the source")


def entry(kind, identity, source, reference):
    return {"id": kind + "." + fingerprint(identity)[:20], "kind": kind,
            "source": source, "sourceHash": fingerprint(source),
            "references": [reference], "translations": {}, "note": ""}


def swift_string(text, start):
    """Read a Swift literal, preserving interpolation as inert numbered placeholders."""
    marker = re.match(r'(#+)?("""|")', text[start:])
    if not marker:
        raise ValueError("Expected Swift string")
    hashes, quote = marker.group(1) or "", marker.group(2)
    end_marker = quote + hashes
    escape = "\\" + hashes
    pos = start + len(marker.group())
    parts, arguments = [], []
    while pos < len(text):
        if text.startswith(end_marker, pos):
            return pos + len(end_marker), "".join(parts), arguments
        if text.startswith(escape + "(", pos):
            begin = pos + len(escape) + 1
            cursor, depth = begin, 1
            while cursor < len(text) and depth:
                if re.match(r'(?:#+)?"', text[cursor:]):
                    cursor = swift_string(text, cursor)[0]
                    continue
                if text[cursor] == "(":
                    depth += 1
                elif text[cursor] == ")":
                    depth -= 1
                cursor += 1
            if depth:
                raise ValueError("Unterminated Swift interpolation")
            argument = text[begin:cursor - 1]
            if argument not in arguments:
                arguments.append(argument)
            parts.append("{" + str(arguments.index(argument)) + "}")
            pos = cursor
        elif text.startswith(escape, pos):
            cursor = pos + len(escape)
            if cursor >= len(text):
                break
            char = text[cursor]
            unicode_escape = re.match(r"u\{([0-9a-fA-F]+)\}", text[cursor:])
            if unicode_escape:
                parts.append(chr(int(unicode_escape.group(1), 16)))
                pos = cursor + len(unicode_escape.group())
            else:
                parts.append({"n": "\n", "r": "\r", "t": "\t", "0": "\0"}.get(char, char))
                pos = cursor + 1
        else:
            parts.append(text[pos])
            pos += 1
    raise ValueError("Unterminated Swift string")


def swift_literals(text):
    pos, result = 0, []
    while pos < len(text):
        if text.startswith("//", pos):
            newline = text.find("\n", pos)
            pos = len(text) if newline < 0 else newline
        elif text.startswith("/*", pos):
            depth, pos = 1, pos + 2
            while depth and pos < len(text):
                if text.startswith("/*", pos):
                    depth, pos = depth + 1, pos + 2
                elif text.startswith("*/", pos):
                    depth, pos = depth - 1, pos + 2
                else:
                    pos += 1
        elif re.match(r'(?:#+)?"', text[pos:]):
            end, value, args = swift_string(text, pos)
            result.append((pos, end, value, args))
            pos = end
        else:
            pos += 1
    return result


def scan_swift(path, base):
    text = path.read_text(encoding="utf-8")
    tokens = swift_literals(text)
    used, entries = set(), []
    relative = path.relative_to(base).as_posix()
    orders = set(re.findall(r"func\s+t\s*\(\s*_\s+(de|en)\s*:", text))
    t_order = next(iter(orders)) if len(orders) == 1 else None
    for index in range(len(tokens) - 1):
        a, b = tokens[index:index + 2]
        if index in used:
            continue
        before, between = text[max(0, a[0] - 180):a[0]], text[a[1]:b[0]]
        order = None
        if between.strip() == ":":
            if re.search(r'\b(?:english|en)\s*\?\s*$', before) or re.search(r'\b(?:language|code)\s*==\s*"en"\s*\?\s*$', before):
                order = "en"
            elif re.search(r'\b(?:language|code)\s*==\s*"de"\s*\?\s*$', before):
                order = "de"
        elif between.strip() == "," and re.search(r"\bt\(\s*$", before):
            order = t_order
        elif re.search(r"\bde\s*:\s*$", before) and re.fullmatch(r"\s*,\s*en\s*:\s*", between):
            order = "de"
        elif re.search(r"\ben\s*:\s*$", before) and re.fullmatch(r"\s*,\s*de\s*:\s*", between):
            order = "en"
        if not order:
            continue
        de, en = (a, b) if order == "de" else (b, a)
        # Shared interpolation expressions keep their identity when languages reorder them.
        args = en[3] + [arg for arg in de[3] if arg not in en[3]]
        def normalized(token):
            return PLACEHOLDER.sub(lambda m: "{" + str(args.index(token[3][int(m[0][1:-1])])) + "}" if int(m[0][1:-1]) < len(token[3]) else m[0], token[2])
        source = {"de": normalized(de), "en": normalized(en)}
        ref = {"path": relative, "line": text.count("\n", 0, a[0]) + 1}
        item = entry("swift", [relative, source], source, ref)
        item["note"] = "Inventory only; move this text to a runtime localization key before activating another language."
        if placeholders(source["de"]) != placeholders(source["en"]):
            item["note"] += " Existing DE/EN interpolation differs; human review required."
        entries.append(item)
        used.update((index, index + 1))
    unclassified = []
    for i, token in enumerate(tokens):
        if i in used:
            continue
        value = token[2]
        # Potential prose, including single-word UI literals; retain location for review.
        prefix = text[max(0, token[0] - 100):token[0]]
        ui_literal = re.search(r"\b(?:Text|Button|Label|Picker|Toggle|tr|help|accessibilityLabel|navigationTitle)\s*\(\s*$", prefix)
        if re.search(r"[A-Za-zÄÖÜäöüß]{3}", value) and (ui_literal or not re.fullmatch(r"[a-zA-Z0-9_./:#-]+", value)):
            unclassified.append({"path": relative, "line": text.count("\n", 0, token[0]) + 1,
                                 "text": value, "reason": "Unpaired literal; language and UI relevance need review."})
    return entries, unclassified


def paired_keys(node):
    for key in node:
        candidates = []
        if key == "de":
            candidates.append("en")
        if key.startswith("de") and len(key) > 2 and key[2].isupper():
            candidates.append("en" + key[2:])
        for suffix, target in (("DE", "EN"), ("De", "En"), ("_de", "_en")):
            if key.endswith(suffix):
                candidates.append(key[:-len(suffix)] + target)
        for other in candidates:
            if other in node:
                yield key, other


def scan_json(path, base):
    relative, entries = path.relative_to(base).as_posix(), []
    def pair(de, en, location):
        if isinstance(de, str) and isinstance(en, str):
            entries.append(entry("resource", [relative, location], {"de": de, "en": en},
                                 {"path": relative, "location": location}))
        elif isinstance(de, list) and isinstance(en, list):
            for i in range(max(len(de), len(en))):
                pair(de[i] if i < len(de) else "", en[i] if i < len(en) else "", location + [i])
        elif isinstance(de, dict) and isinstance(en, dict):
            for key in sorted(de.keys() | en.keys()):
                pair(de.get(key, ""), en.get(key, ""), location + [key])
    def walk(node, location):
        if isinstance(node, dict):
            paired = set()
            for de_key, en_key in paired_keys(node):
                pair(node[de_key], node[en_key], location + [de_key + "|" + en_key])
                paired.update((de_key, en_key))
            for key, value in node.items():
                if key not in paired:
                    walk(value, location + [key])
        elif isinstance(node, list):
            ids = [str(value.get("id")) if isinstance(value, dict) and "id" in value else None for value in node]
            for i, value in enumerate(node):
                anchor = "id=" + ids[i] if ids[i] is not None and ids.count(ids[i]) == 1 else i
                walk(value, location + [anchor])
    walk(read_json(path), [])
    return entries


def discover(base):
    entries, unclassified = [], []
    pairs = {}
    for line in (base / "translations.txt").read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        de, en = line.split("|||", 1)
        de, en = de.replace("\\n", "\n"), en.replace("\\n", "\n")
        if de in pairs:
            raise ValueError(f"Duplicate legacy translation: {de}")
        pairs[de] = en
        entries.append(entry("interface", de, {"de": de, "en": en}, {"path": "translations.txt", "key": de}))
    for path in sorted((base / "Resources").glob("*.json")):
        if path.name == "MapEnglish.json":
            for de, en in read_json(path).items():
                entries.append(entry("map", de, {"de": de, "en": en}, {"path": "Resources/MapEnglish.json", "key": de}))
        else:
            entries.extend(scan_json(path, base))
    for path in sorted((base / "Sources").glob("*.swift")):
        found, pending = scan_swift(path, base)
        entries.extend(found)
        unclassified.extend(pending)
    # Whole bilingual setup/transfer documents stay intact; paragraphs are not realigned by guess.
    for path in sorted((base / "Resources").glob("*-de.md")):
        other = path.with_name(path.name.replace("-de.md", "-en.md"))
        if other.exists():
            ref = {"path": path.relative_to(base).as_posix(), "englishPath": other.relative_to(base).as_posix()}
            item = entry("document", ref["path"], {"de": path.read_text(), "en": other.read_text()}, ref)
            item["note"] = "Whole document; preserve Markdown, commands, links and safety statements."
            entries.append(item)
    # Scope new authored sections explicitly: historical local notes may contain user data.
    for relative, heading, identity in (
        ("Resources/CHANGELOG.md", "# 1.7.49 · Map and layer controls · 2026-09-13", "map-layer-1.7.49"),
        ("Resources/BACKLOG.md", "## Map and layer controls · 1.7.49 (71) · 2026-09-13", "map-layer-1.7.49"),
        ("docs/UI-UX-AUDIT-2026-09-12.md", "## Map and layer controls · 1.7.49 (71) · 2026-09-13", "map-layer-1.7.49"),
        ("Resources/CHANGELOG.md", "# 1.7.48 · Stable · 2026-09-13", "stable-1.7.48"),
        ("Resources/BACKLOG.md", "## Local stable baseline · 1.7.48 (70) · 2026-09-13", "stable-1.7.48"),
        ("Resources/CHANGELOG.md", "## Metro network assistant candidate · 2026-09-13", "metro-network-assistant"),
        ("Resources/BACKLOG.md", "## Metro network assistant · 1.7.47 (69) · 2026-09-13", "metro-network-assistant"),
        ("docs/METRO-WORKSPACE-2026-09-09.md", "## Network assistant implementation · 1.7.47 (69) · 2026-09-13", "metro-network-assistant"),
        ("Resources/CHANGELOG.md", "## Ore viewport and zoom candidate · 2026-09-13", "ore-viewport-ux"),
        ("Resources/BACKLOG.md", "## Ore UX first package · 1.7.47 (69) · 2026-09-13", "ore-viewport-ux"),
        ("docs/UI-UX-AUDIT-2026-09-12.md", "## Ore first implementation package · 1.7.47 (69) · 2026-09-13", "ore-viewport-ux"),
        ("Resources/CHANGELOG.md", "## Library alignment candidate · 2026-09-13", "library-alignment-ux"),
        ("Resources/BACKLOG.md", "## Library alignment · 1.7.47 (69) · 2026-09-13", "library-alignment-ux"),
        ("docs/UI-UX-AUDIT-2026-09-12.md", "## Library alignment implementation · 1.7.47 (69) · 2026-09-13", "library-alignment-ux"),
        ("Resources/CHANGELOG.md", "## Screen density candidate · 2026-09-13", "screen-density-ux"),
        ("Resources/BACKLOG.md", "## Screen density · 1.7.47 (69) · 2026-09-13", "screen-density-ux"),
        ("docs/UI-UX-AUDIT-2026-09-12.md", "## Screen density implementation · 1.7.47 (69) · 2026-09-13", "screen-density-ux"),
    ):
        path = base / relative
        if path.is_file():
            text = path.read_text(encoding="utf-8")
            if heading not in text.splitlines():
                continue
            section = text.split(heading, 1)[1]
            section = re.split(r"(?m)^#{1,2} ", section, maxsplit=1)[0]
            item = entry("document", [relative, identity], {"de": "", "en": heading + section.rstrip() + "\n"}, {"path": relative, "heading": heading})
            item["note"] = "English source section; German remains open. Preserve Markdown and evidence limitations. Other sections are not imported."
            entries.append(item)
    merged = {}
    for item in entries:
        if item["id"] in merged:
            old = merged[item["id"]]
            if old["source"] != item["source"]:
                raise ValueError("Catalog ID collision")
            old["references"].extend(item["references"])
        else:
            merged[item["id"]] = item
    return sorted(merged.values(), key=lambda x: (x["kind"], x["references"][0]["path"], x["id"])), unclassified


def sync(base, previous=None):
    entries, pending = discover(base)
    prior = previous or {}
    old = {e["id"]: e for e in prior.get("retiredEntries", []) + prior.get("entries", [])}
    for item in entries:
        if item["id"] in old:
            before = old.pop(item["id"])
            item["translations"] = copy.deepcopy(before["translations"])
            if item["sourceHash"] != before["sourceHash"]:
                for translation in item["translations"].values():
                    translation["status"] = "needs-review"
            item["note"] = before["note"] or item["note"]
    return {"schemaVersion": 1, "project": "RealmCraft Companion", "sourceLanguage": "en",
            "scope": "macOS source and bundled bilingual resources; Android/web need independent adapters",
            "entries": entries, "retiredEntries": sorted(old.values(), key=lambda item: item["id"]),
            "coverage": {"complete": False, "unclassifiedSwiftLiterals": pending,
                         "remaining": ["Review unclassified Swift literals and language branches with computed values.",
                                       "Extract embedded map JavaScript/Python prose beyond MapEnglish.json.",
                                       "Add Android and web adapters and runtime locale selection.",
                                       "Review monolingual resource fields, raw strings and multiline indentation."]}}


def validate(catalog):
    if not isinstance(catalog, dict) or catalog.get("schemaVersion") != 1 or catalog.get("sourceLanguage") != "en":
        raise ValueError("Unsupported translation catalog")
    if not isinstance(catalog.get("entries"), list) or len(catalog["entries"]) > 100_000:
        raise ValueError("Invalid catalog entry list")
    ids = set()
    for item in catalog["entries"]:
        if not isinstance(item, dict) or not isinstance(item.get("id"), str) or not isinstance(item.get("translations"), dict):
            raise ValueError("Invalid catalog entry")
        if item["id"] in ids:
            raise ValueError("Duplicate entry ID: " + item["id"])
        ids.add(item["id"])
        source = item["source"]
        if not isinstance(source, dict) or set(source) != {"de", "en"} or not all(isinstance(v, str) for v in source.values()):
            raise ValueError("Source must have DE and EN text")
        if item["sourceHash"] != fingerprint(source):
            raise ValueError("Source changed without sync: " + item["id"])
        for code, translation in item["translations"].items():
            language_code(code)
            if not isinstance(translation, dict) or set(translation) != {"text", "status"} or translation["status"] not in {"draft", "reviewed", "needs-review"}:
                raise ValueError("Invalid translation state")
            # Keep an older translation for review even when the new source has
            # different placeholders. It cannot enter generated runtime resources.
            check_translation(translation["text"] if translation["status"] == "needs-review" else source["en"], translation["text"])
    return catalog


def export_pack(catalog, code, kinds=None):
    language_code(code)
    entries = []
    for item in catalog["entries"]:
        if kinds and item["kind"] not in kinds:
            continue
        current = item["translations"].get(code)
        entries.append({"id": item["id"], "sourceHash": item["sourceHash"], "source": item["source"],
                        "baseHash": fingerprint(current), "text": current["text"] if current else "",
                        "context": item["references"], "note": item["note"]})
    return {"schemaVersion": 1, "type": "realmcraft-language-pack", "language": code, "entries": entries}


def import_pack(catalog, pack):
    if set(pack) != {"schemaVersion", "type", "language", "entries"} or pack["schemaVersion"] != 1 or pack["type"] != "realmcraft-language-pack":
        raise ValueError("Unsupported language pack")
    code = language_code(pack["language"])
    result = copy.deepcopy(catalog)
    by_id = {item["id"]: item for item in result["entries"]}
    seen, changed = set(), 0
    if not isinstance(pack["entries"], list) or len(pack["entries"]) > 100_000:
        raise ValueError("Invalid entry list")
    for change in pack["entries"]:
        if set(change) != {"id", "sourceHash", "source", "baseHash", "text", "context", "note"}:
            raise ValueError("Unexpected language-pack fields")
        key = change["id"]
        if key in seen or key not in by_id:
            raise ValueError("Duplicate or unknown ID: " + str(key))
        seen.add(key)
        item = by_id[key]
        if change["sourceHash"] != item["sourceHash"] or change["source"] != item["source"]:
            raise ValueError("Source conflict: " + key)
        current = item["translations"].get(code)
        if change["baseHash"] != fingerprint(current):
            raise ValueError("Concurrent translation conflict: " + key)
        if change["text"] == "":
            continue  # Empty means untranslated, never delete an existing translation.
        if current and current["text"] == change["text"]:
            continue
        check_translation(item["source"]["en"], change["text"])
        item["translations"][code] = {"text": change["text"], "status": "draft"}
        changed += 1
    validate(result)
    return result, changed


def render_interface(catalog):
    """Compile existing tr() bundle resources, using reviewed EN overrides only."""
    result = {}
    for code in ("de", "en"):
        lines = []
        for item in catalog["entries"]:
            if item["kind"] != "interface":
                continue
            key, value = item["source"]["de"], item["source"][code]
            override = item["translations"].get(code)
            if code == "en" and override and override["status"] == "reviewed" and override["text"]:
                value = override["text"]
            lines.append(json.dumps(key, ensure_ascii=False) + " = " + json.dumps(value, ensure_ascii=False) + ";")
        result[code] = "\n".join(lines) + "\n"
    return result


def check_interface_sources(catalog, base):
    actual = {}
    for line in (base / "translations.txt").read_text(encoding="utf-8").splitlines():
        if line.strip():
            de, en = line.split("|||", 1)
            actual[de.replace("\\n", "\n")] = en.replace("\\n", "\n")
    known = {item["source"]["de"]: item["source"]["en"] for item in catalog["entries"] if item["kind"] == "interface"}
    if actual != known:
        raise ValueError("translations.txt changed; refresh the central catalog with translation_catalog.py sync before building")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=Path, default=BASE)
    parser.add_argument("--catalog", type=Path)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("check", help="Validate and detect stale source inventory")
    sub.add_parser("status")
    refresh = sub.add_parser("sync", help="Rescan source; write a NEW catalog for review")
    refresh.add_argument("--output", required=True, type=Path)
    export = sub.add_parser("export")
    export.add_argument("--language", required=True)
    export.add_argument("--kind", action="append", choices=["interface", "resource", "swift", "map", "document"])
    export.add_argument("--output", required=True, type=Path)
    imp = sub.add_parser("import", help="Validate a pack and write a NEW merged catalog")
    imp.add_argument("pack", type=Path)
    imp.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    path = args.catalog or args.base / CATALOG
    catalog = validate(read_json(path)) if path.exists() else None
    if args.command == "sync":
        updated = sync(args.base, catalog)
        validate(updated)
        write_json(args.output, updated)
        print(f"Wrote {len(updated['entries'])} entries; review {len(updated['coverage']['unclassifiedSwiftLiterals'])} unclassified literals.")
        return
    if catalog is None:
        raise ValueError("Catalog missing; run sync first")
    if args.command == "check":
        fresh = sync(args.base, catalog)
        if fresh != catalog:
            raise ValueError("Catalog inventory is stale; sync to a new file and review the diff")
        print(f"Validated {len(catalog['entries'])} entries; source inventory is current (coverage remains partial).")
    elif args.command == "status":
        print(json.dumps({"entries": len(catalog["entries"]), "byKind": dict(Counter(e["kind"] for e in catalog["entries"])),
                          "unclassifiedSwiftLiterals": len(catalog["coverage"]["unclassifiedSwiftLiterals"]),
                          "coverageComplete": catalog["coverage"]["complete"],
                          "translations": dict(Counter(code + ":" + value["status"] for e in catalog["entries"] for code, value in e["translations"].items()))}, indent=2))
    elif args.command == "export":
        write_json(args.output, export_pack(catalog, args.language, args.kind))
        print("Language pack exported; edit text fields and share the JSON file for review.")
    elif args.command == "import":
        merged, count = import_pack(catalog, read_json(args.pack))
        write_json(args.output, merged)
        print(f"Validated {count} changes into a NEW catalog. Imported translations are drafts; runtime activation is separate.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, TypeError, OSError) as error:
        print(f"Translation error: {error}", file=sys.stderr)
        raise SystemExit(1)
