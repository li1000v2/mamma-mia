#!/usr/bin/env python3
"""Generate the model audio in Audio/ with Gemini TTS on Agent Platform.

Every Italian line the app plays (lesson phrases, frame examples, what the other person says in
challenges) gets one clip per voice at normal speed. The slow clip is that same recording slowed
with ffmpeg: style instructions sent with the text are sometimes read aloud, so none are sent.
Each new clip is transcribed back with Gemini and regenerated when it doesn't match the text.
Files are named by a hash of "<voice>|<speed>|<text>", so only missing audio is generated.

Usage (from the repo root):
  python tools/gen_audio.py --dry-run     list what is missing
  python tools/gen_audio.py               generate it
  python tools/gen_audio.py --prune       also delete audio no line uses any more

Needs GOOGLE_API_KEY and GOOGLE_CLOUD_PROJECT_NUMBER (environment or .env) and ffmpeg on PATH.
Voices and models are set in tools/tts_voices.json; bump a voice's "rev" to regenerate it.
"""
from __future__ import annotations

import argparse
import base64
import concurrent.futures
import difflib
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import unicodedata
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "Content"
AUDIO = ROOT / "Audio"
MANIFEST = AUDIO / "manifest.json"
CONFIG = Path(__file__).resolve().parent / "tts_voices.json"
ENDPOINT = "https://aiplatform.googleapis.com/v1/projects/{project}/locations/global/publishers/google/models/{model}:generateContent"


def audio_key(text: str, voice: str, speed: str) -> str:
    """Must match AudioManifest.key in Packages/MammaCore."""
    return f"{voice}|{speed}|{text}"


def file_name(key: str) -> str:
    return hashlib.sha256(key.encode("utf-8")).hexdigest()[:16] + ".m4a"


def load_json(path: Path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def load_env() -> dict[str, str]:
    values = {}
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                name, value = line.split("=", 1)
                values[name.strip()] = value.strip().strip('"').strip("'")
    for name in ("GOOGLE_API_KEY", "GOOGLE_CLOUD_PROJECT_NUMBER"):
        if os.environ.get(name):
            values[name] = os.environ[name]
    return values


def spoken_texts() -> list[str]:
    """Every Italian line the app can play, in course order, without duplicates."""
    texts: list[str] = []
    course = load_json(CONTENT / "course.json")
    texts += [frame["example"] for frame in course["frames"]]
    for path in sorted((CONTENT / "lessons").glob("*.json")):
        texts += [phrase["it"] for phrase in load_json(path)["phrases"]]
    for path in sorted((CONTENT / "dialogues").glob("*.json")):
        script = load_json(path)
        nodes = script["nodes"] + (script.get("followUps") or {}).get("pool", [])
        texts += [line["it"] for node in nodes for line in node["npc"]]
    return list(dict.fromkeys(texts))


def normalized(text: str) -> str:
    text = unicodedata.normalize("NFKD", text.lower())
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = re.sub(r"[^\w\s]", " ", text)
    return " ".join(text.split())


@dataclass
class Job:
    text: str
    voice_id: str
    voice_name: str


class Gemini:
    def __init__(self, key: str, project: str, config: dict):
        self.key = key
        self.project = project
        self.config = config

    def _post(self, model: str, body: dict) -> dict:
        url = ENDPOINT.format(project=self.project, model=model)
        headers = {"Content-Type": "application/json"}
        if self.key:
            headers["x-goog-api-key"] = self.key
        request = urllib.request.Request(url, data=json.dumps(body).encode("utf-8"), headers=headers)
        for attempt in range(5):
            try:
                with urllib.request.urlopen(request, timeout=120) as response:
                    return json.load(response)
            except urllib.error.HTTPError as error:
                detail = error.read().decode("utf-8", "replace")
                if self.key:
                    detail = detail.replace(self.key, "<key>")
                if error.code in (429, 500, 502, 503, 504) and attempt < 4:
                    time.sleep(2 ** (attempt + 1))
                    continue
                raise RuntimeError(f"{model} HTTP {error.code}: {detail[:300]}") from None
            except (urllib.error.URLError, TimeoutError, ConnectionError) as error:
                if attempt < 4:
                    time.sleep(2 ** (attempt + 1))
                    continue
                raise RuntimeError(f"{model}: {getattr(error, 'reason', error)}") from None
        raise RuntimeError(f"{model}: gave up after retries")

    def speak(self, text: str, voice_name: str) -> bytes:
        body = {
            "contents": [{"role": "user", "parts": [{"text": text}]}],
            "generationConfig": {
                "responseModalities": ["AUDIO"],
                "speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice_name}}},
            },
        }
        data = self._post(self.config["ttsModel"], body)
        for part in data["candidates"][0]["content"]["parts"]:
            if "inlineData" in part:
                return base64.b64decode(part["inlineData"]["data"])
        raise RuntimeError("no audio in the TTS response")

    def transcribe(self, wav: bytes) -> str:
        body = {
            "contents": [{"role": "user", "parts": [
                {"inlineData": {"mimeType": "audio/wav", "data": base64.b64encode(wav).decode("ascii")}},
                {"text": "Transcribe exactly every word spoken in this audio, in whatever language it is. Output only the transcript."},
            ]}],
            "generationConfig": {"temperature": 0},
        }
        data = self._post(self.config["checkModel"], body)
        return "".join(part.get("text", "") for part in data["candidates"][0]["content"]["parts"]).strip()


def ffmpeg(input_bytes: bytes, output: Path, filters: str) -> None:
    command = [
        "ffmpeg", "-v", "error", "-y", "-i", "pipe:0", "-af", filters,
        "-ac", "1", "-c:a", "aac", "-b:a", "48k", "-movflags", "+faststart", str(output),
    ]
    subprocess.run(command, input=input_bytes, check=True)


TRIM = (
    "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,"
    "areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.1,areverse"
)


def generate(job: Job, gemini: Gemini, profile: str, tempo: float) -> tuple[dict[str, str], str | None]:
    """Returns the new manifest entries, and a warning when the clip never matched its text."""
    best_wav, best_score, heard = b"", -1.0, ""
    for _ in range(3):
        wav = gemini.speak(job.text, job.voice_name)
        transcript = gemini.transcribe(wav)
        score = difflib.SequenceMatcher(None, normalized(job.text), normalized(transcript)).ratio()
        if score > best_score:
            best_wav, best_score, heard = wav, score, transcript
        if score >= 0.85:
            break
    entries = {}
    for speed, filters in (("n", TRIM), ("s", f"{TRIM},atempo={tempo}")):
        key = audio_key(job.text, profile, speed)
        name = file_name(key)
        ffmpeg(best_wav, AUDIO / name, filters)
        entries[key] = name
    warning = None if best_score >= 0.85 else f"{profile} {job.text!r}: heard {heard!r} (match {best_score:.2f})"
    return entries, warning


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true", help="only list the missing audio")
    parser.add_argument("--prune", action="store_true", help="delete audio that no line uses any more")
    parser.add_argument("--limit", type=int, default=0, help="generate at most this many clips")
    parser.add_argument("--workers", type=int, default=4)
    args = parser.parse_args()

    config = load_json(CONFIG)
    manifest = load_json(MANIFEST)
    profiles = {voice["id"]: f"{voice['id']}@{voice['rev']}" for voice in config["voices"]}
    texts = spoken_texts()

    entries: dict[str, str] = dict(manifest["entries"])
    wanted: set[str] = set()
    jobs: list[Job] = []
    for voice in config["voices"]:
        profile = profiles[voice["id"]]
        for text in texts:
            keys = [audio_key(text, profile, speed) for speed in ("n", "s")]
            wanted.update(keys)
            if not all(key in entries and (AUDIO / entries[key]).is_file() for key in keys):
                jobs.append(Job(text, voice["id"], voice["voiceName"]))
    if args.limit:
        jobs = jobs[: args.limit]

    print(f"{len(texts)} lines × {len(profiles)} voices; {len(jobs)} clips to generate")
    if args.dry_run:
        for job in jobs:
            print(f"  {profiles[job.voice_id]}  {job.text}")
        return 0

    failures, warnings = [], []
    if jobs:
        env = load_env()
        if not env.get("GOOGLE_CLOUD_PROJECT_NUMBER"):
            print("GOOGLE_CLOUD_PROJECT_NUMBER must be set (environment or .env)", file=sys.stderr)
            return 2
        if not env.get("GOOGLE_API_KEY"):
            # Claude Code cloud environments can inject the key as an API credential header.
            print("GOOGLE_API_KEY not set; assuming the environment adds the x-goog-api-key header")
        gemini = Gemini(env.get("GOOGLE_API_KEY", ""), env["GOOGLE_CLOUD_PROJECT_NUMBER"], config)
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = {
                pool.submit(generate, job, gemini, profiles[job.voice_id], config["slowTempo"]): job
                for job in jobs
            }
            for done, future in enumerate(concurrent.futures.as_completed(futures), 1):
                job = futures[future]
                try:
                    new_entries, warning = future.result()
                    entries.update(new_entries)
                    if warning:
                        warnings.append(warning)
                    print(f"[{done}/{len(jobs)}] {profiles[job.voice_id]} {job.text}")
                except Exception as error:  # keep going; report at the end
                    failures.append(f"{profiles[job.voice_id]} {job.text!r}: {error}")
                    print(f"[{done}/{len(jobs)}] FAILED {profiles[job.voice_id]} {job.text}: {error}")

    if args.prune:
        for key in [key for key in entries if key not in wanted]:
            del entries[key]
        used = set(entries.values())
        for path in AUDIO.glob("*.m4a"):
            if path.name not in used:
                path.unlink()

    manifest = {"version": manifest["version"], "voices": list(profiles.values()), "entries": dict(sorted(entries.items()))}
    tmp = tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=AUDIO, suffix=".json", delete=False)
    with tmp:
        json.dump(manifest, tmp, ensure_ascii=False, indent=2)
        tmp.write("\n")
    os.replace(tmp.name, MANIFEST)

    for line in warnings:
        print(f"warning: {line}")
    for line in failures:
        print(f"error: {line}")
    print(f"manifest: {len(entries)} entries, {len(failures)} failed, {len(warnings)} need a listen")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
