#!/usr/bin/env python3
"""Regenerate the model audio that tools/audio_review.py flagged, keeping a take only when the screen
passes it twice.

A recording is one voice saying one line; its slow clip is that recording slowed down, so both speeds
are judged together. For each recording with a flagged clip in reviews/audio-screen-cache.json:

1. The current recording is screened again at both speeds, twice. If every verdict is clean, it stays:
   the flag was the screener's noise.
2. Otherwise new takes are generated (as in gen_audio.py, the checkModel transcript must match the
   line), up to --takes, and each is screened at both speeds. The first that comes out clean twice
   replaces the recording's files.
3. If no take is clean, the one with the fewest flagged verdicts is kept (the current one on a tie) and
   the recording is listed as still suspicious, next to how the other voice did on the same line.

Files keep their names (a hash of voice, speed and text), so Audio/manifest.json and the app don't
change; the new verdicts go into the screening cache. Every decision is logged in
reviews/audio-regen-log.json and listed in reviews/audio-regen.md. Afterwards run
audio_review.py --report-only --week N to refresh its reports.

If the service refuses a request outright (HTTP 401/403/404), the run stops at once; recordings it had
not finished stay as they were. At most MAX_PARALLEL (gen_audio.py) requests are in flight.

Usage (from the repo root):
  python tools/regen_audio.py --dry-run          list the recordings it would work on
  python tools/regen_audio.py                    every recording with a flagged clip, or left suspicious
  python tools/regen_audio.py --only caffè       only recordings whose line contains this (repeatable)

Needs the same keys as gen_audio.py, and ffmpeg.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import difflib
import json
import re
import sys
import tempfile
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path

import audio_review as review
from gen_audio import AUDIO, MANIFEST, MAX_PARALLEL, ROOT, TRIM, ffmpeg, load_env, load_json, normalized, spoken_texts

REPORT = ROOT / "reviews" / "audio-regen.md"
LOG = ROOT / "reviews" / "audio-regen-log.json"
SPEEDS = ("n", "s")
SPEED_NAMES = {"n": "原速", "s": "慢速"}


@dataclass
class Recording:
    voice: str  # profile, e.g. "f1@1"
    text: str
    clips: dict[str, review.Clip]  # speed -> clip

    @property
    def voice_id(self) -> str:
        return self.voice.split("@", 1)[0]


@dataclass
class Outcome:
    recording: Recording
    decision: str  # "kept", "replaced" or "suspicious"
    steps: list[str]
    entries: dict[str, dict] = field(default_factory=dict)  # speed -> verdict to cache
    audio: dict[str, bytes] | None = None  # new files for the recording, if any


def recordings() -> list[Recording]:
    texts = set(spoken_texts())
    grouped: dict[tuple[str, str], dict[str, review.Clip]] = {}
    for key, name in load_json(MANIFEST)["entries"].items():
        voice, speed, text = key.split("|", 2)
        if text in texts:
            grouped.setdefault((voice, text), {})[speed] = review.Clip(key, name, voice, speed, text)
    return [Recording(voice, text, clips) for (voice, text), clips in sorted(grouped.items())
            if all(speed in clips for speed in SPEEDS)]


def flagged(rec: Recording, cache: dict[str, dict]) -> list[str]:
    """The speeds whose current audio the screen flagged."""
    return [speed for speed, clip in rec.clips.items()
            if review.is_fresh(clip, cache.get(clip.file), review.MODEL) and not cache[clip.file]["ok"]]


def clean(pair: dict[str, dict | None]) -> bool:
    return all(entry is not None and entry["ok"] for entry in pair.values())


def describe(pair: dict[str, dict | None]) -> str:
    parts = []
    for speed in SPEEDS:
        entry = pair[speed]
        if entry is None:
            parts.append(f"{SPEED_NAMES[speed]}没筛成")
        elif entry["ok"]:
            parts.append(f"{SPEED_NAMES[speed]}干净")
        else:
            kinds = "、".join(dict.fromkeys(review.ISSUE_TYPES[issue["type"]] for issue in entry["issues"]))
            parts.append(f"{SPEED_NAMES[speed]}被标出（{kinds}）")
    return "，".join(parts)


def latest(tries: list[dict[str, dict | None]]) -> dict[str, dict | None]:
    """Each speed's most recent verdict, so a screen that failed doesn't hide an earlier one."""
    return {speed: next((pair[speed] for pair in reversed(tries) if pair[speed] is not None), None) for speed in SPEEDS}


def one_line(error: Exception) -> str:
    return " ".join(str(error).split())


class Refused(RuntimeError):
    """The service refuses this key or project (HTTP 401/403/404): every other request would fail too."""


def refused(error: Exception) -> bool:
    return isinstance(error, Refused) or bool(re.search(r"HTTP (401|403|404)\b", str(error)))


class Regenerator:
    def __init__(self, reviewer: review.Reviewer, tempo: float, voice_names: dict[str, str], takes: int, workers: int):
        self.reviewer = reviewer
        self.tempo = tempo
        self.voice_names = voice_names
        self.takes = takes
        self.stopped = threading.Event()
        # Screens run in their own pool, so recordings waiting on them don't starve it.
        self.screens = concurrent.futures.ThreadPoolExecutor(max_workers=workers * 2)

    def stop(self, error: Exception) -> Refused:
        self.stopped.set()
        return error if isinstance(error, Refused) else Refused(one_line(error))

    def screen(self, clip: review.Clip, audio: bytes) -> dict | None:
        """A verdict, or None if the screen failed twice (HTTP errors, unusable or malformed answers)."""
        for _ in range(2):
            if self.stopped.is_set():
                raise Refused("stopped after the service refused a request")
            try:
                return self.reviewer.review(clip, review.MODEL, self.tempo, audio=audio)
            except Exception as error:  # noqa: BLE001 - any other failure just means no verdict
                if refused(error):
                    raise self.stop(error) from None
        return None

    def pair(self, rec: Recording, audio: dict[str, bytes]) -> dict[str, dict | None]:
        futures = {speed: self.screens.submit(self.screen, rec.clips[speed], audio[speed]) for speed in SPEEDS}
        return {speed: future.result() for speed, future in futures.items()}

    def new_take(self, rec: Recording) -> dict[str, bytes] | None:
        """Both speeds of a new recording, or None if its transcript doesn't match the line."""
        wav = self.reviewer.speak(rec.text, self.voice_names[rec.voice_id])
        heard = self.reviewer.transcribe(wav)
        if difflib.SequenceMatcher(None, normalized(rec.text), normalized(heard)).ratio() < 0.85:
            return None
        audio = {}
        with tempfile.TemporaryDirectory() as tmp:
            for speed, filters in (("n", TRIM), ("s", f"{TRIM},atempo={self.tempo}")):
                path = Path(tmp) / f"{speed}.m4a"
                ffmpeg(wav, path, filters)
                audio[speed] = path.read_bytes()
        return audio

    def run(self, rec: Recording) -> Outcome:
        if self.stopped.is_set():
            raise Refused("stopped after the service refused a request")
        current = {speed: (AUDIO / rec.clips[speed].file).read_bytes() for speed in SPEEDS}
        steps: list[str] = []
        candidates: list[tuple[str, dict[str, bytes] | None, list[dict[str, dict | None]]]] = []

        pairs = []
        for _ in range(2):
            pairs.append(self.pair(rec, current))
            if not clean(pairs[-1]):
                break
        steps.append("现在的版本复筛：" + "；".join(describe(pair) for pair in pairs))
        if len(pairs) == 2 and clean(pairs[-1]):
            return Outcome(rec, "kept", steps, pairs[-1])
        candidates.append(("现在的版本", None, pairs))

        for number in range(1, self.takes + 1):
            label = f"新版本 {number}"
            try:
                audio = self.new_take(rec)
            except Exception as error:  # noqa: BLE001 - HTTP errors, odd responses, ffmpeg: try the next take
                if refused(error):
                    raise self.stop(error) from None
                steps.append(f"{label}：生成失败（{one_line(error)[:80]}）")
                continue
            if audio is None:
                steps.append(f"{label}：转写和原文对不上，没筛")
                continue
            tries = [self.pair(rec, audio)]
            if clean(tries[0]):
                tries.append(self.pair(rec, audio))
            steps.append(f"{label}：" + "；".join(describe(pair) for pair in tries))
            if len(tries) == 2 and clean(tries[-1]):
                return Outcome(rec, "replaced", steps, tries[-1], audio)
            candidates.append((label, audio, tries))

        def badness(candidate) -> tuple[float, int]:
            _, audio, tries = candidate
            verdicts = [entry for pair in tries for entry in pair.values()]
            bad = sum(1 for entry in verdicts if entry is None or not entry["ok"])
            return (bad / len(verdicts) if verdicts else 1.0, 0 if audio is None else 1)

        label, audio, tries = min(candidates, key=badness)
        steps.append(f"都不干净，留下{label}")
        return Outcome(rec, "suspicious", steps, latest(tries), audio)


def load_log() -> dict[str, dict]:
    """Every decision so far, keyed by "<voice>|<text>"; a rerun overwrites the recording's entry."""
    return load_json(LOG)["recordings"] if LOG.exists() else {}


def save_log(log: dict[str, dict]) -> None:
    body = json.dumps({"version": 1, "recordings": dict(sorted(log.items()))}, ensure_ascii=False, indent=2)
    LOG.write_text(body + "\n", encoding="utf-8", newline="\n")


def write_report(log: dict[str, dict], cache: dict[str, dict], voice_names: dict[str, str]) -> None:
    current = {(rec.voice, rec.text): rec for rec in recordings()}

    def other_voices(voice: str, text: str) -> str:
        notes = []
        for (other_voice, other_text), other in current.items():
            if other_text == text and other_voice != voice:
                screened = all(review.is_fresh(clip, cache.get(clip.file), review.MODEL) for clip in other.clips.values())
                state = "干净" if screened and not flagged(other, cache) else "也有问题或没筛完"
                notes.append(f"{voice_names.get(other.voice_id, other_voice)} {state}")
        return "；".join(notes) or "没有另一个声线"

    rows = [row for row in log.values() if (row["voice"], row["text"]) in current]
    # A recording that is gone was dropped by hand: "lineVoices" in tts_voices.json keeps the other voice.
    gone = sorted((row for row in log.values() if (row["voice"], row["text"]) not in current),
                  key=lambda row: (row["text"], row["voice"]))
    counts = {kind: sum(1 for row in rows if row["decision"] == kind) for kind in ("replaced", "kept", "suspicious")}
    md = ["# 示范音频重新生成", "",
          f"由 `tools/regen_audio.py` 生成，决定记在 `{LOG.name}`。处理过 {len(rows) + len(gone)} 条录音"
          "（一个声线说一句，原速和慢速一起判）；新版本复筛两次都干净才采用。", "",
          f"- 换成了新版本：{counts['replaced']} 条",
          f"- 保留现在的版本（复筛两次都干净，原来的标记是误报）：{counts['kept']} 条",
          f"- 仍可疑（几个版本都不干净，留下最好的一版）：{counts['suspicious']} 条",
          f"- 改为只用另一个声线（这条录音已删）：{len(gone)} 条", ""]
    if gone:
        md += ["## 改为只用另一个声线", "",
               "几个版本都读不对、另一个声线干净的句子，在 `tools/tts_voices.json` 的 `lineVoices` 里只留另一个声线。", ""]
        for row in gone:
            voice_id = row["voice"].split("@", 1)[0]
            md += [f"### {row['text']}", "", f"- 删掉的声线 {row['voice']}（{voice_names.get(voice_id, '')}） · {row['at'][:10]}"]
            md += [f"- {step}" for step in row["steps"]]
            md.append("")
    for kind, title in (("suspicious", "仍可疑"), ("replaced", "换成了新版本"), ("kept", "保留现在的版本")):
        chosen = sorted((row for row in rows if row["decision"] == kind), key=lambda row: (row["text"], row["voice"]))
        if not chosen:
            continue
        md += [f"## {title}", ""]
        for row in chosen:
            voice_id = row["voice"].split("@", 1)[0]
            md += [f"### {row['text']}", "",
                   f"- 声线 {row['voice']}（{voice_names.get(voice_id, '')}） · {row['at'][:10]} · "
                   + " · ".join(f"{SPEED_NAMES[speed]} `{row['files'][speed]}`" for speed in SPEEDS)]
            md += [f"- {step}" for step in row["steps"]]
            if kind == "suspicious":
                md.append(f"- 另一个声线：{other_voices(row['voice'], row['text'])}")
            md.append("")
    REPORT.write_text("\n".join(md), encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true", help="only list the recordings")
    parser.add_argument("--only", action="append", default=[], metavar="TEXT",
                        help="only recordings whose line contains TEXT (repeatable); flagged or not")
    parser.add_argument("--takes", type=int, default=4, help="new takes to try per recording (default 4)")
    parser.add_argument("--workers", type=int, default=4,
                        help=f"recordings worked on at once (at most {MAX_PARALLEL // 2}: each screens two clips at a time)")
    parser.add_argument("--timeout", type=float, default=300, help="seconds per model request")
    args = parser.parse_args()
    args.workers = max(1, min(args.workers, MAX_PARALLEL // 2))

    config = load_json(Path(__file__).resolve().parent / "tts_voices.json")
    voice_names = {voice["id"]: voice["voiceName"] for voice in config["voices"]}
    cache = review.load_cache()
    log = load_log()
    if args.only:
        needles = [needle.lower() for needle in args.only]
        todo = [rec for rec in recordings() if any(needle in rec.text.lower() for needle in needles)]
    else:
        # Flagged now, or left suspicious by an earlier run (whose new take may not be screened yet).
        suspicious = {key for key, row in log.items() if row["decision"] == "suspicious"}
        todo = [rec for rec in recordings() if flagged(rec, cache) or f"{rec.voice}|{rec.text}" in suspicious]
    print(f"{len(todo)} recordings to work on")
    if args.dry_run:
        for rec in todo:
            print(f"  {rec.voice} [{'+'.join(flagged(rec, cache)) or '-'}] {rec.text}")
        return 0
    if not todo:
        return 0

    env = load_env()
    if not env.get("GOOGLE_CLOUD_PROJECT_NUMBER"):
        print("GOOGLE_CLOUD_PROJECT_NUMBER must be set (environment or .env)", file=sys.stderr)
        return 2
    reviewer = review.Reviewer(env.get("GOOGLE_API_KEY", ""), env["GOOGLE_CLOUD_PROJECT_NUMBER"], config)
    reviewer.timeout = args.timeout
    regenerator = Regenerator(reviewer, config["slowTempo"], voice_names, args.takes, args.workers)
    lock = threading.Lock()
    outcomes: list[Outcome] = []
    refusal = ""
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(regenerator.run, rec): rec for rec in todo}
        for done, future in enumerate(concurrent.futures.as_completed(futures), 1):
            rec = futures[future]
            try:
                outcome = future.result()
            except Refused as error:  # left as it is, like every recording not reached
                refusal = refusal or str(error)
                continue
            except Exception as error:  # keep going; the recording stays as it is
                print(f"[{done}/{len(todo)}] FAILED {rec.voice} {rec.text}: {error}")
                continue
            with lock:
                if outcome.audio:
                    for speed in SPEEDS:
                        (AUDIO / rec.clips[speed].file).write_bytes(outcome.audio[speed])
                for speed, entry in outcome.entries.items():
                    if entry is not None:
                        if not entry["ok"]:
                            try:
                                entry["checkHeard"] = reviewer.second_opinion(rec.clips[speed])
                            except Exception:  # noqa: BLE001 - audio_review.py adds it on its next run
                                pass
                        cache[rec.clips[speed].file] = entry
                review.save_cache(cache)
                log[f"{rec.voice}|{rec.text}"] = {
                    "voice": rec.voice,
                    "text": rec.text,
                    "decision": outcome.decision,
                    "steps": outcome.steps,
                    "files": {speed: rec.clips[speed].file for speed in SPEEDS},
                    "at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                }
                save_log(log)
                outcomes.append(outcome)
            print(f"[{done}/{len(todo)}] {outcome.decision} {rec.voice} {rec.text}")
    regenerator.screens.shutdown()
    write_report(log, cache, voice_names)
    counts = {kind: sum(1 for outcome in outcomes if outcome.decision == kind) for kind in ("replaced", "kept", "suspicious")}
    print(f"replaced {counts['replaced']}, kept {counts['kept']}, still suspicious {counts['suspicious']}; "
          f"report: {REPORT.relative_to(ROOT)}")
    if refusal:
        print(f"stopped: the service refused requests ({refusal[:200]}); "
              f"{len(todo) - len(outcomes)} recordings left as they were", file=sys.stderr)
    return 0 if len(outcomes) == len(todo) else 1


if __name__ == "__main__":
    sys.exit(main())
