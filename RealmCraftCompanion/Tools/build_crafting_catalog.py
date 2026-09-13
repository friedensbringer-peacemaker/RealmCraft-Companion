#!/usr/bin/env python3
"""Normalize recipe facts from a hash-pinned official reference, never game code/assets.

Usage: python3 Tools/build_crafting_catalog.py CLIENT_JAR OUTPUT_JSON
The catalog's name-based links are comparison mappings, not verified RealmCraft IDs.
No download, savegame access or automatic promotion to RealmCraft evidence occurs.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import zipfile

CLIENT_SHA1 = "37fd3c903861eeff3bc24b71eed48f828b5269c8"
CLIENT_URL = f"https://piston-data.mojang.com/v1/objects/{CLIENT_SHA1}/client.jar"
ROOT = Path(__file__).resolve().parents[1]
ALIASES = {
    "redstone_dust": "redstone", "slimeball": "slime_ball",
    "nether_quartz": "quartz", "leather_cap": "leather_helmet",
    "leather_tunic": "leather_chestplate", "leather_pants": "leather_leggings",
    "carrot_on_stick": "carrot_on_a_stick", "rabbits_foot": "rabbit_foot",
    "raw_chicken": "chicken", "raw_porkchop": "porkchop", "raw_beef": "beef",
    "raw_mutton": "mutton", "raw_rabbit": "rabbit", "raw_cod": "cod", "raw_salmon": "salmon",
}
EXTRA_DE = {
    "blaze_powder": "Lohenstaub", "blaze_rod": "Lohenrute",
    "nether_brick": "Netherziegel (Gegenstand)", "ender_pearl": "Enderperle",
    "ender_eye": "Enderauge", "glass_bottle": "Glasflasche", "honey_bottle": "Honigflasche",
    "popped_chorus_fruit": "Geplatzte Chorusfrucht", "turtle_helmet": "Schildkrötenpanzer",
    "scute": "Hornschuppe", "nautilus_shell": "Nautilusschale", "heart_of_the_sea": "Herz des Meeres",
    "nether_star": "Netherstern", "map": "Leere Karte", "compass": "Kompass",
    "clock": "Uhr", "fermented_spider_eye": "Fermentiertes Spinnenauge",
    "carrot": "Karotte", "potato": "Kartoffel", "cocoa_beans": "Kakaobohnen",
    "golden_horse_armor": "Goldener Rossharnisch", "iron_horse_armor": "Eiserner Rossharnisch",
    "shulker_shell": "Shulkerschale",
}


def key(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def build(archive, names):
    if hashlib.sha1(archive.read_bytes()).hexdigest() != CLIENT_SHA1:
        raise ValueError("Expected the official Minecraft Java 1.16.5 client SHA-1")
    items = {}
    for number, title in names.items():
        slug = ALIASES.get(key(title["en"]), key(title["en"]))
        if slug in items:
            raise ValueError(f"Ambiguous catalog name mapping: {slug}")
        items[slug] = {"id": slug, "itemID": int(number), "title": title}
    known = set(items)
    recipes, skipped = [], []
    with zipfile.ZipFile(archive) as z:
        def tag_values(tag, seen=()):
            tag = tag.removeprefix("minecraft:")
            if tag in seen:
                raise ValueError(f"Cyclic item tag: {tag}")
            data = json.loads(z.read(f"data/minecraft/tags/items/{tag}.json"))
            result = []
            for value in data["values"]:
                if not isinstance(value, str):
                    raise ValueError(f"Unsupported tag value: {value}")
                result.extend(tag_values(value[1:], seen + (tag,)) if value.startswith("#") else [value.removeprefix("minecraft:")])
            return sorted(set(result))

        def choices(value):
            if isinstance(value, list):
                return sorted({v for option in value for v in choices(option)})
            if "item" in value:
                return [value["item"].removeprefix("minecraft:")]
            return tag_values(value["tag"])

        for path in sorted(z.namelist()):
            if not (path.startswith("data/minecraft/recipes/") and path.endswith(".json")):
                continue
            raw = json.loads(z.read(path))
            kind = raw["type"].removeprefix("minecraft:")
            result = raw.get("result")
            output = (result if isinstance(result, str) else (result or {}).get("item", "")).removeprefix("minecraft:")
            if output not in known:
                skipped.append({"file": path, "reason": "dynamic recipe" if not output else "output absent from Companion name catalog"})
                continue
            groups, grid = [], []

            def add(options, amount):
                for index, group in enumerate(groups):
                    if group["options"] == options:
                        group["count"] += amount
                        return index + 1
                groups.append({"options": options, "count": amount})
                return len(groups)

            if kind == "crafting_shaped":
                pattern = raw["pattern"]
                station = "inventory" if len(pattern) <= 2 and max(map(len, pattern)) <= 2 else "table"
                size = 2 if station == "inventory" else 3
                symbols = {}
                for symbol, value in raw["key"].items():
                    symbols[symbol] = add(choices(value), sum(row.count(symbol) for row in pattern))
                grid = [symbols.get(pattern[y][x], 0) if y < len(pattern) and x < len(pattern[y]) else 0 for y in range(size) for x in range(size)]
            elif kind == "crafting_shapeless":
                for ingredient in raw["ingredients"]:
                    add(choices(ingredient), 1)
                station = "inventory" if sum(g["count"] for g in groups) <= 4 else "table"
            elif kind in ["smelting", "blasting", "smoking", "campfire_cooking", "stonecutting"]:
                add(choices(raw["ingredient"]), 1)
                station = {"smelting": "furnace", "blasting": "blastFurnace", "smoking": "smoker", "campfire_cooking": "campfire", "stonecutting": "stonecutter"}[kind]
            elif kind == "smithing":
                add(choices(raw["base"]), 1)
                add(choices(raw["addition"]), 1)
                station = "smithing"
            else:
                raise ValueError(f"Unsupported recipe type with output: {kind}")
            count = raw.get("count", 1) if isinstance(result, str) else result.get("count", 1)
            recipe = {"id": Path(path).stem, "output": output, "count": count, "station": station,
                      "kind": kind, "ingredients": groups, "grid": grid, "sourcePath": path,
                      "sourceSHA256": hashlib.sha256(z.read(path)).hexdigest()}
            # Wiki evidence is deliberately field-scoped; it does not certify the grid or Quest behavior.
            if output == "crafting_table":
                recipe["corroboration"] = {"title": "RealmCraft Game Wiki · Crafting table", "url": "https://realmcraftgame.fandom.com/wiki/Crafting_table",
                    "scope": {"de": "Die Wiki nennt vier Bretter und Herstellung im Inventar. Quest-Version und Bedienung sind nicht geprüft.", "en": "The wiki lists four planks and inventory crafting. Quest version and controls are untested."}}
            elif output == "enchanting_table":
                recipe["corroboration"] = {"title": "RealmCraft Game Wiki · Enchantment Table", "url": "https://realmcraftgame.fandom.com/wiki/Enchantment_Table",
                    "scope": {"de": "Die Wiki nennt 2 Diamanten, 4 Obsidian und 1 Buch. Anordnung, Ausgabemenge und Quest-Version sind nicht geprüft.", "en": "The wiki lists 2 diamonds, 4 obsidian and 1 book. Layout, yield and Quest version are untested."}}
            recipes.append(recipe)
            for group in groups:
                for slug in group["options"]:
                    if slug not in items:
                        en = slug.replace("_", " ").title()
                        items[slug] = {"id": slug, "title": {"en": en, "de": EXTRA_DE.get(slug, en)}}
    return {"schemaVersion": 1, "referenceVersion": "Minecraft Java 1.16.5", "checked": "2026-09-11",
            "sourceURL": CLIENT_URL, "sourceSHA1": CLIENT_SHA1,
            "items": sorted(items.values(), key=lambda i: i["id"]), "recipes": recipes,
            "omittedSourceRecipes": skipped}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("client", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    names = json.loads((ROOT / "Resources/ItemNames.json").read_text())
    catalog = build(args.client, names)
    args.output.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
    print(f"{len(names)} catalog entries; {len(catalog['recipes'])} comparison recipes for {len(set(r['output'] for r in catalog['recipes']))} outputs; {len(catalog['omittedSourceRecipes'])} omitted source recipes")
    print(dict(Counter(r["station"] for r in catalog["recipes"])))
