#!/usr/bin/env python3
"""Prepare an audit-only app/profile. Does not launch GUI, install, or delete."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import shutil
import stat
import subprocess
import uuid
import zipfile

FEATURES = "home saves player maps ores portals metro chests conversation videos builds crafting mobs resources guide statistics tectonicus editor aiExport skills".split()
STATES = ("empty", "loaded", "no-result", "error", "running", "draft")


def digest(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def new_destination(path):
    path = Path(path).absolute()
    # Reject all symlink components, including dangling destination links.
    if any(p.is_symlink() for p in (path, *path.parents)):
        raise ValueError("Destination must not contain symlinks")
    if path.exists() or not path.parent.is_dir():
        raise ValueError("Destination must be new, with an existing parent")
    return path


def check_demo(path, expected):
    if not re.fullmatch(r"[0-9a-f]{64}", expected) or digest(path) != expected:
        raise ValueError("Demo SHA-256 mismatch")
    with zipfile.ZipFile(path) as archive:
        entries = archive.infolist()
        if not entries or len(entries) > 25000 or sum(e.file_size for e in entries) > 512 * 1024**2:
            raise ValueError("Demo archive exceeds the bounded audit fixture limits")
        seen = set()
        for entry in entries:
            name = entry.filename
            parts = PurePosixPath(name).parts
            mode = entry.external_attr >> 16
            key = name.rstrip("/").casefold()
            if (not parts or name.startswith("/") or "\\" in name or ".." in parts
                    or any(ord(c) < 32 for c in name) or key in seen
                    or stat.S_ISLNK(mode) or entry.flag_bits & 1):
                raise ValueError("Unsafe, duplicate or encrypted demo archive member")
            seen.add(key)
        if archive.testzip() is not None:
            raise ValueError("Corrupt demo archive")


def checklist(baseline):
    return {
        "schema": 1, "baseline": baseline, "gate": "not-run",
        "evidenceKinds": ["visual", "accessibility", "source", "isolated-test", "assisted-visual"],
        "screens": [{"id": feature, "status": "open", "evidence": [],
                     "states": {state: "open" for state in STATES},
                     "panes": [], "controls": [], "exceptions": [],
                     "languageThemeWindowChecks": [], "keyboard": "open", "voiceOver": "open"}
                    for feature in FEATURES],
        "journeys": [{"id": name, "status": "open", "evidence": []} for name in
                     ["search-variant-plan", "guide-step-plan", "demo-map-background",
                      "ore-height-3d", "chest-filter-recovery", "draft-cancel-recovery"]],
    }


def coverage_errors(record):
    errors = []
    if not isinstance(record, dict) or record.get("schema") != 1:
        return ["Expected a schema 1 coverage object"]
    screens = record.get("screens", [])
    if not isinstance(screens, list) or not all(isinstance(row, dict) for row in screens):
        return ["Expected a list of screen records"]
    ids = [row.get("id") for row in screens]
    if len(ids) != len(set(ids)) or set(ids) != set(FEATURES):
        errors.append("Expected every baseline destination exactly once")
    for row in screens:
        if row.get("status") not in ("open", "partial", "passed", "blocked"):
            errors.append(f"{row.get('id', '?')}: unknown status")
        if row.get("status") != "passed":
            continue
        name = row.get("id", "?")
        if record.get("gate") != "passed":
            errors.append(f"{name}: tool stability gate not passed")
        if not any(e.get("kind") in ("visual", "assisted-visual") and e.get("ref") for e in row.get("evidence", [])):
            errors.append(f"{name}: missing visual evidence")
        if not row.get("panes") or any(not p.get("endObserved") or not p.get("evidence") for p in row["panes"]):
            errors.append(f"{name}: every pane needs final-position evidence (use a non-scrollable pane where applicable)")
        if not row.get("controls") or any(c.get("status") not in ("passed", "excluded") or not c.get("evidence") for c in row["controls"]):
            errors.append(f"{name}: every inventoried control needs evidence or an explicit exclusion")
        states = row.get("states", {})
        if set(states) != set(STATES) or any(v not in ("passed", "excluded") for v in states.values()):
            errors.append(f"{name}: required states remain open")
        if (any(v == "excluded" for v in states.values()) or
                any(c.get("status") == "excluded" for c in row.get("controls", []))) and not row.get("exceptions"):
            errors.append(f"{name}: exclusions need documented reasons and approval where required")
    return errors


def run(command, **kwargs):
    # Capture potentially personal tool output; surface only a command name/status.
    result = subprocess.run(command, capture_output=True, text=True, **kwargs)
    if result.returncode:
        raise RuntimeError(f"{Path(command[0]).name} failed ({result.returncode}); partial audit folder retained")
    return result.stdout


def unsigned_digest(source, scratch):
    """Compare Mach-O content after stripping signatures on disposable copies."""
    shutil.copyfile(source, scratch)
    run(["/usr/bin/codesign", "--remove-signature", str(scratch)])
    return digest(scratch)


def prepare(app, destination, demo=None, demo_sha256=None):
    app = Path(app).resolve(strict=True)
    destination = new_destination(destination)
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    executable = info["CFBundleExecutable"]
    if info.get("CFBundleIdentifier") != "at.local.realmcraft.savegames" or not re.fullmatch(r"[A-Za-z0-9_-]+", executable):
        raise ValueError("Expected a production Companion baseline")
    if any(p.is_symlink() for p in app.rglob("*")):
        raise ValueError("Symlink-bearing app bundles require a separate reviewed copy procedure")
    run(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(app)])
    if bool(demo) != bool(demo_sha256):
        raise ValueError("Specify both the approved demo archive and its expected SHA-256")
    if demo:
        check_demo(demo, demo_sha256)
    baseline = {"version": info["CFBundleShortVersionString"], "build": info["CFBundleVersion"],
                "executableSHA256": digest(app / "Contents/MacOS" / executable)}
    destination.mkdir(mode=0o700)
    verification = destination / "Verification"
    verification.mkdir()
    baseline["unsignedExecutableSHA256"] = unsigned_digest(
        app / "Contents/MacOS" / executable, verification / "baseline-unsigned")
    copied = destination / "RealmCraft Audit.app"
    shutil.copytree(app, copied, copy_function=shutil.copyfile)
    # copyfile creates independent inodes and excludes inherited xattrs.
    for original in app.rglob("*"):
        if original.is_file():
            target = copied / original.relative_to(app)
            target.chmod(stat.S_IMODE(original.stat().st_mode))
            if original.samefile(target):
                raise RuntimeError("Unexpected shared inode")
    profile = destination / "Profile"
    library = profile / "Library/Application Support/RealmCraftLibrary/Savegames"
    library.mkdir(parents=True)
    identifier = "at.local.realmcraft.audit." + uuid.uuid4().hex
    environment = {"CFFIXED_USER_HOME": str(profile), "REALMCRAFT_LIBRARY": str(library),
                   "REALMCRAFT_ADB": "/usr/bin/false"}
    info.update(CFBundleIdentifier=identifier, CFBundleName="RealmCraft Audit",
                CFBundleDisplayName="RealmCraft Audit", CFBundleExecutable="AuditLauncher",
                RealmCraftAuditRoot=str(destination), RealmCraftAuditExecutable=executable,
                LSEnvironment=environment)
    (copied / "Contents/Info.plist").write_bytes(plistlib.dumps(info))
    wrapper = copied / "Contents/MacOS/AuditLauncher"
    run(["/usr/bin/xcrun", "swiftc", "-module-cache-path", str(destination / "ModuleCache"),
         str(Path(__file__).with_name("AuditLauncher.swift")), "-o", str(wrapper)])
    wrapper.chmod(0o755)
    # A new bundle identifier requires new signatures. Compare stripped copies
    # below to prove that executable content (apart from signing) did not change.
    run(["/usr/bin/codesign", "--force", "--deep", "--sign", "-", str(copied)])
    run(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(copied)])
    target = copied / "Contents/MacOS" / executable
    if unsigned_digest(target, verification / "audit-unsigned") != baseline["unsignedExecutableSHA256"]:
        raise RuntimeError("Baseline executable content changed beyond code signing")
    child_env = dict(os.environ, **environment)
    run([str(wrapper), "--audit-preflight"], env=child_env)
    if demo:
        # Import/verify only the checked archive into the newly created library.
        # The GUI is never started, and the original archive is read-only.
        run([str(target), "--import", str(Path(demo).resolve())], env=child_env, timeout=120)
        run([str(target), "--verify"], env=child_env, timeout=120)
    manifest = {"schema": 1, "baseline": baseline, "auditBundleID": identifier,
                "demoSHA256": demo_sha256, "profile": "Profile", "securitySandbox": False,
                "auditExecutableSHA256": digest(target),
                "launchServicesGate": "not-run", "helperGate": "not-run",
                "notes": "Executable content verified equal after signature removal on copies. Audit wrapper, bundle metadata and signatures differ. No GUI or device operation performed."}
    (destination / "audit-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (destination / "coverage.json").write_text(json.dumps(checklist(baseline), indent=2) + "\n")
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    create = commands.add_parser("prepare")
    create.add_argument("--app", required=True, type=Path)
    create.add_argument("--output", required=True, type=Path)
    create.add_argument("--approved-demo", type=Path)
    create.add_argument("--demo-sha256")
    validate = commands.add_parser("validate-coverage")
    validate.add_argument("file", type=Path)
    args = parser.parse_args()
    try:
        if args.command == "prepare":
            result = prepare(args.app, args.output, args.approved_demo, args.demo_sha256)
            print(json.dumps(result, indent=2))
        else:
            errors = coverage_errors(json.loads(args.file.read_text()))
            if errors:
                raise ValueError("; ".join(errors))
            print("Coverage record is internally consistent; open entries are NOT accepted screens.")
    except (ValueError, RuntimeError, OSError, subprocess.TimeoutExpired, zipfile.BadZipFile) as error:
        parser.exit(1, f"Audit preparation stopped: {error}\n")


if __name__ == "__main__":
    main()
