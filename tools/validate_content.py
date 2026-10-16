#!/usr/bin/env python3
"""Validate Content/ and Audio/ before they ship in the app.

Checks every JSON file against its schema in Content/schema, that audio-reviewed phrases have
audio for every voice and speed, that every manifest entry has its file, and that no real
itinerary was committed. Cross-file id checks live in the MammaCore tests.

Usage: python tools/validate_content.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "Content"
SCHEMAS = CONTENT / "schema"
AUDIO = ROOT / "Audio"

SPEEDS = ("n", "s")


def audio_key(text: str, voice: str, speed: str) -> str:
    """Must match AudioManifest.key in Packages/MammaCore."""
    return f"{voice}|{speed}|{text}"


def load(path: Path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def schema_errors(schema_name: str, path: Path) -> list[str]:
    validator = Draft202012Validator(load(SCHEMAS / schema_name))
    errors = []
    for error in sorted(validator.iter_errors(load(path)), key=lambda e: [str(p) for p in e.absolute_path]):
        where = "/".join(str(p) for p in error.absolute_path) or "(root)"
        errors.append(f"{rel(path)}: {where}: {error.message}")
    return errors


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    if (CONTENT / "trip.json").exists():
        errors.append("Content/trip.json is personal data and must not be committed; import it on the phone")

    lesson_files = sorted((CONTENT / "lessons").glob("*.json"))
    dialogue_files = sorted((CONTENT / "dialogues").glob("*.json"))
    manifest_path = AUDIO / "manifest.json"
    errors += schema_errors("course.schema.json", CONTENT / "course.json")
    errors += schema_errors("trip.schema.json", CONTENT / "trip.example.json")
    errors += schema_errors("audio-manifest.schema.json", manifest_path)
    for path in lesson_files:
        errors += schema_errors("lesson.schema.json", path)
    for path in dialogue_files:
        errors += schema_errors("dialogue.schema.json", path)
    if errors:  # the checks below assume well-formed files
        return report(errors, warnings)

    for path in lesson_files + dialogue_files:
        unit = load(path)["unit"]
        if path.stem != unit:
            errors.append(f"{rel(path)}: file should be named {unit}.json")

    manifest = load(manifest_path)
    for key, name in manifest["entries"].items():
        if not (AUDIO / name).is_file():
            errors.append(f"{rel(manifest_path)}: {name} (for {key!r}) is missing from Audio/")

    phrases = [phrase for path in lesson_files for phrase in load(path)["phrases"]]
    for phrase in phrases:
        if phrase["status"] == "draft":
            continue
        missing = [
            f"{voice}/{speed}"
            for voice in manifest["voices"]
            for speed in SPEEDS
            if audio_key(phrase["it"], voice, speed) not in manifest["entries"]
        ]
        if not manifest["voices"]:
            missing = ["(no voices configured)"]
        if missing:
            # Audio comes after cross-checking, so only an audio-reviewed phrase must have it.
            message = f"{phrase['id']}: no audio for {', '.join(missing)}"
            (errors if phrase["status"] == "audio_ok" else warnings).append(message)

    if errors:
        return report(errors, warnings)
    for line in warnings:
        print(f"warning: {line}")
    drafts = sum(1 for phrase in phrases if phrase["status"] == "draft")
    print(
        f"OK: {len(lesson_files)} lesson files, {len(phrases)} phrases ({drafts} draft), "
        f"{len(dialogue_files)} dialogues, {len(manifest['entries'])} audio files"
    )
    return 0


def report(errors: list[str], warnings: list[str]) -> int:
    for line in warnings:
        print(f"warning: {line}")
    for line in errors:
        print(f"error: {line}")
    print(f"{len(errors)} problem(s) found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
