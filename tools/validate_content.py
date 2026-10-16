#!/usr/bin/env python3
"""Validate Content/ and Audio/ before they ship in the app.

Checks every JSON file against its schema in Content/schema, that a phrase past draft still has
the text it was checked with (checkedText), that audio-reviewed phrases have audio for every voice
and speed (a show-card line for one voice: it is played to people, not studied), that every manifest
entry has its file, and that no real itinerary was committed. Cross-file id checks live in the
MammaCore tests.

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
        errors.append("Content/trip.json is personal data and must not be committed; enter the trip in the app")

    lesson_files = sorted((CONTENT / "lessons").glob("*.json"))
    dialogue_files = sorted((CONTENT / "dialogues").glob("*.json"))
    manifest_path = AUDIO / "manifest.json"
    show_cards_path = CONTENT / "showcards.json"
    errors += schema_errors("course.schema.json", CONTENT / "course.json")
    errors += schema_errors("trip.schema.json", CONTENT / "trip.example.json")
    errors += schema_errors("audio-manifest.schema.json", manifest_path)
    if show_cards_path.exists():
        errors += schema_errors("showcards.schema.json", show_cards_path)
    else:
        errors.append(f"{rel(show_cards_path)} is missing; the show cards need it")
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
    show_cards = load(show_cards_path)
    card_phrases = show_cards["phrases"]
    first_with_text: dict[str, str] = {}
    for phrase in phrases + card_phrases:
        text = " ".join(phrase["it"].lower().split())
        if text in first_with_text:
            warnings.append(f"{phrase['id']}: same Italian as {first_with_text[text]}; reuse one phrase or note why both exist")
        else:
            first_with_text[text] = phrase["id"]
    for phrase in phrases + card_phrases:
        if phrase["status"] == "draft":
            continue
        checked_text = phrase.get("checkedText")
        if checked_text != phrase["it"]:
            # A review holds only for the text that was reviewed.
            found = "has no checkedText" if checked_text is None else f"was checked as {checked_text!r}"
            errors.append(
                f"{phrase['id']}: status {phrase['status']} but {found}, not {phrase['it']!r}; "
                "cross-check it again, or set status back to draft"
            )

    def missing_audio(text: str, voices: list[str]) -> list[str]:
        if not voices:
            return ["(no voices configured)"]
        return [f"{voice}/{speed}" for voice in voices for speed in SPEEDS
                if audio_key(text, voice, speed) not in manifest["entries"]]

    for phrase in phrases:
        missing = missing_audio(phrase["it"], manifest["voices"])
        if missing:
            # Audio comes after cross-checking, so only an audio-reviewed phrase must have it.
            message = f"{phrase['id']}: no audio for {', '.join(missing)}"
            (errors if phrase["status"] == "audio_ok" else warnings).append(message)
    # A show-card line is played to people, not studied: one voice with both speeds is enough.
    card_lines = [(phrase["id"], phrase["it"], phrase["status"]) for phrase in card_phrases]
    card_lines += [(f"allergen {item['id']}", item["it"], "draft") for item in show_cards["allergens"]]
    for line_id, text, status in card_lines:
        options = [missing_audio(text, [voice]) for voice in manifest["voices"]] or [missing_audio(text, [])]
        if all(options):
            message = f"showcards {line_id}: no voice has audio at both speeds"
            (errors if status == "audio_ok" else warnings).append(message)

    if errors:
        return report(errors, warnings)
    for line in warnings:
        print(f"warning: {line}")
    drafts = sum(1 for phrase in phrases if phrase["status"] == "draft")
    card_drafts = sum(1 for phrase in card_phrases if phrase["status"] == "draft")
    print(
        f"OK: {len(lesson_files)} lesson files, {len(phrases)} phrases ({drafts} draft), "
        f"{len(dialogue_files)} dialogues, {len(card_phrases)} show-card phrases ({card_drafts} draft), "
        f"{len(manifest['entries'])} audio files"
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
