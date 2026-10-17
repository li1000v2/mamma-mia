#!/usr/bin/env python3
"""Validate Content/ and Audio/ before they ship in the app.

Checks every JSON file against its schema in Content/schema, that a phrase past draft still has
the text it was checked with (checkedText), that audio-reviewed phrases have audio for every voice
the line is generated for (all of them unless lineVoices in tools/tts_voices.json limits it) at both
speeds, each clip with a current, clean verdict from tools/audio_review.py in
reviews/audio-screen-cache.json (a show-card or pilgrimage-spot line needs one voice: those are said
on the spot, not studied), that the role-play fillers have audio in every voice and each role's voice
has a Gemini voice name, that every manifest entry has its file, and that no real itinerary was
committed. Cross-file id checks live in the MammaCore tests.

Usage: python tools/validate_content.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator

import audio_review as screening

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "Content"
SCHEMAS = CONTENT / "schema"
AUDIO = ROOT / "Audio"
TTS_CONFIG = ROOT / "tools" / "tts_voices.json"

SPEEDS = ("n", "s")


def audio_key(text: str, voice: str, speed: str) -> str:
    """Must match AudioManifest.key in Packages/MammaCore."""
    return f"{voice}|{speed}|{text}"


def load(path: Path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def screening_problem(clip: screening.Clip, cache: dict[str, dict]) -> str | None:
    """Why a clip has no clean screening verdict from tools/audio_review.py, or None."""
    entry = cache.get(clip.file)
    if entry is None:
        return "has not been screened"
    if not screening.is_fresh(clip, entry, screening.MODEL):
        if entry.get("key") != clip.key or entry.get("sha256") != screening.audio_sha256(clip.file):
            return "changed after it was screened"
        return "has no current verdict (an older model or prompt, or an unusable answer)"
    if not entry["ok"]:
        return "was flagged by the screen"
    return None


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
    role_play_path = CONTENT / "roleplay.json"
    spots_path = CONTENT / "spots.json"
    errors += schema_errors("course.schema.json", CONTENT / "course.json")
    errors += schema_errors("trip.schema.json", CONTENT / "trip.example.json")
    errors += schema_errors("audio-manifest.schema.json", manifest_path)
    if show_cards_path.exists():
        errors += schema_errors("showcards.schema.json", show_cards_path)
    else:
        errors.append(f"{rel(show_cards_path)} is missing; the show cards need it")
    if role_play_path.exists():
        errors += schema_errors("roleplay.schema.json", role_play_path)
    if spots_path.exists():
        errors += schema_errors("spots.schema.json", spots_path)
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
    spots = load(spots_path) if spots_path.exists() else {"phrases": [], "spots": []}
    spot_phrases = spots["phrases"]
    first_with_text: dict[str, str] = {}
    for phrase in phrases + card_phrases + spot_phrases:
        text = " ".join(phrase["it"].lower().split())
        if text in first_with_text:
            warnings.append(f"{phrase['id']}: same Italian as {first_with_text[text]}; reuse one phrase or note why both exist")
        else:
            first_with_text[text] = phrase["id"]
    # A spot's Italian name is checked like a phrase.
    for phrase in phrases + card_phrases + spot_phrases + spots["spots"]:
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

    line_voices = load(TTS_CONFIG).get("lineVoices", {})

    def course_voices(text: str) -> list[str]:
        """The voices a course line is generated for: all of them unless lineVoices limits it (gen_audio.py)."""
        allowed = line_voices.get(text)
        return [voice for voice in manifest["voices"] if allowed is None or voice.split("@", 1)[0] in allowed]

    cache = screening.load_cache()
    for phrase in phrases:
        voices = course_voices(phrase["it"])
        missing = missing_audio(phrase["it"], voices)
        if missing:
            # Audio comes after cross-checking, so only an audio-reviewed phrase must have it.
            message = f"{phrase['id']}: no audio for {', '.join(missing)}"
            (errors if phrase["status"] == "audio_ok" else warnings).append(message)
        if phrase["status"] != "audio_ok":
            continue
        # audio_ok rests on the screen: every clip the line has needs a current, clean verdict, so a
        # regenerated clip, or one flagged when screened again, takes the phrase back to checked.
        for voice in voices:
            for speed in SPEEDS:
                key = audio_key(phrase["it"], voice, speed)
                if key not in manifest["entries"]:
                    continue  # reported as missing above
                problem = screening_problem(screening.Clip(key, manifest["entries"][key], voice, speed, phrase["it"]), cache)
                if problem:
                    errors.append(
                        f"{phrase['id']}: status audio_ok but its {voice}/{speed} clip {problem}; "
                        "screen it with tools/audio_review.py, or set status back to checked"
                    )
    # A show-card line is played to people, not studied: one voice with both speeds is enough.
    card_lines = [(phrase["id"], phrase["it"], phrase["status"]) for phrase in card_phrases]
    card_lines += [(f"allergen {item['id']}", item["it"], "draft") for item in show_cards["allergens"]]
    for line_id, text, status in card_lines:
        options = [missing_audio(text, [voice]) for voice in manifest["voices"]] or [missing_audio(text, [])]
        if all(options):
            message = f"showcards {line_id}: no voice has audio at both speeds"
            (errors if status == "audio_ok" else warnings).append(message)
    # So is a spot's line, said at the place: its own sentences and the place names.
    spot_lines = [(phrase["id"], phrase["it"], phrase["status"]) for phrase in spot_phrases]
    spot_lines += [(f"name {spot['id']}", spot["it"], spot["status"]) for spot in spots["spots"]]
    for line_id, text, status in spot_lines:
        options = [missing_audio(text, [voice]) for voice in manifest["voices"]] or [missing_audio(text, [])]
        if all(options):
            message = f"spots {line_id}: no voice has audio at both speeds"
            (errors if status == "audio_ok" else warnings).append(message)

    if role_play_path.exists():
        # The fillers play the moment the learner stops speaking: without audio there's nothing to play.
        role_play = load(role_play_path)
        for filler in role_play["fillers"]:
            missing = [voice for voice in manifest["voices"] if audio_key(filler, voice, "n") not in manifest["entries"]]
            if missing:
                errors.append(f"{rel(role_play_path)}: filler {filler!r} has no audio for {', '.join(missing)}")
        names = manifest.get("voiceNames", {})
        for role in role_play["roles"]:
            if role["voice"] not in names:
                errors.append(f"{rel(role_play_path)}: {role['unit']} speaks as {role['voice']}, which has no voiceNames entry in {rel(manifest_path)}")

    if errors:
        return report(errors, warnings)
    for line in warnings:
        print(f"warning: {line}")
    drafts = sum(1 for phrase in phrases if phrase["status"] == "draft")
    audio_ok = sum(1 for phrase in phrases if phrase["status"] == "audio_ok")
    card_drafts = sum(1 for phrase in card_phrases if phrase["status"] == "draft")
    spot_drafts = sum(1 for item in spot_phrases + spots["spots"] if item["status"] == "draft")
    print(
        f"OK: {len(lesson_files)} lesson files, {len(phrases)} phrases ({drafts} draft, {audio_ok} audio_ok), "
        f"{len(dialogue_files)} dialogues, {len(card_phrases)} show-card phrases ({card_drafts} draft), "
        f"{len(spots['spots'])} spots and {len(spot_phrases)} spot phrases ({spot_drafts} draft), "
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
