#!/usr/bin/env python3
"""Read helper IPS reports; emit only an allowlisted aggregate, never raw logs."""
import argparse
from collections import Counter
import json
import re
from pathlib import Path


def read_signature(path):
    if path.stat().st_size > 8 * 1024**2:
        raise ValueError("Report exceeds the diagnostic size limit")
    remaining = path.read_text()
    decoder = json.JSONDecoder()
    report = None
    while remaining.strip():
        value, end = decoder.raw_decode(remaining.lstrip())
        remaining = remaining.lstrip()[end:]
        if isinstance(value, dict) and value.get("procName") == "SkyComputerUseService":
            report = value
    if report is None:
        raise ValueError("Not a Computer Use helper crash report")
    frames = next((thread.get("frames", []) for thread in report.get("threads", []) if thread.get("triggered")), [])
    symbols = [frame.get("symbol", "") for frame in frames]
    # Find the helper's image instead of assuming it is image zero.
    images = report.get("usedImages", [])
    helper_indices = {i for i, item in enumerate(images) if item.get("name") == "SkyComputerUseService"}
    offset = next((frame.get("imageOffset") for frame in frames if frame.get("imageIndex") in helper_indices), None)
    info = report.get("bundleInfo", {})
    exception = report.get("exception", {})
    def safe(value, pattern):
        return value if isinstance(value, str) and re.fullmatch(pattern, value) else None
    return {"version": safe(info.get("CFBundleShortVersionString"), r"[0-9.]{1,40}"),
            "build": safe(info.get("CFBundleVersion"), r"[0-9.]{1,40}"),
            "exception": safe(exception.get("type"), r"EXC_[A-Z_]{1,40}"),
            "signal": safe(exception.get("signal"), r"SIG[A-Z]{1,20}"),
            "swiftAssertion": any("_assertionFailure" in symbol for symbol in symbols),
            "arrayRemoval": any("Array.remove(at:)" in symbol for symbol in symbols),
            "helperOffset": offset if type(offset) is int and offset >= 0 else None}


def summarize(paths):
    counts = Counter()
    rejected = 0
    for path in paths:
        try:
            counts[json.dumps(read_signature(path), sort_keys=True)] += 1
        except (ValueError, OSError, TypeError, AttributeError):
            rejected += 1
    return {"schema": 1, "reports": sum(counts.values()), "unreadableOrUnrelated": rejected,
            "signatures": [{"count": count, **json.loads(key)} for key, count in sorted(counts.items())],
            "limits": "Helper signatures only. No conclusion about Companion correctness or the exact UI trigger."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reports", nargs="+", type=Path)
    args = parser.parse_args()
    print(json.dumps(summarize(args.reports), indent=2))


if __name__ == "__main__":
    main()
