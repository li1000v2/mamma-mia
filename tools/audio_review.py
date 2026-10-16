#!/usr/bin/env python3
"""Screen the model audio in Audio/ with Gemini and list the clips a person should listen to.

Each clip in Audio/manifest.json for the chosen week is sent with its target text to a Gemini model
(HIGH thinking), which checks the whole line: misread or missing words, extra speech (an English
instruction read aloud), clearly wrong stress, very unnatural intonation or rhythm, noise or a cut-off
ending, and for slow clips distortion from slowing them down. Consonant length (pala / palla) is not
judged: the model gets it confidently wrong, so lines with double consonants are only marked for a
human listen and never flagged because of it.

Results are cached by file name in reviews/audio-screen-cache.json, so a rerun only screens new clips.
Every run rewrites reviews/audio-screen-week<N>.md (suspicious clips and totals) and .html (the same
clips with players; open it from reviews/ so ../Audio/ resolves).

Usage (from the repo root):
  python tools/audio_review.py                 screen week 1 and write the report
  python tools/audio_review.py --limit 10      screen at most 10 new clips
  python tools/audio_review.py --only palla    only clips whose file name or text matches
  python tools/audio_review.py --report-only   rewrite the report from the cache

Needs GOOGLE_API_KEY and GOOGLE_CLOUD_PROJECT_NUMBER (environment or .env), like gen_audio.py.
"""
from __future__ import annotations

import argparse
import base64
import concurrent.futures
import html
import json
import os
import re
import sys
import tempfile
import threading
import time
from dataclasses import dataclass
from pathlib import Path

from gen_audio import AUDIO, CONTENT, MANIFEST, ROOT, Gemini, load_env, load_json

REVIEWS = ROOT / "reviews"
CACHE = REVIEWS / "audio-screen-cache.json"
MODEL = "gemini-4-argon"
# Bump when the prompt or the response format changes, so cached verdicts are screened again.
PROMPT_REV = 1
# Measured: one clip at HIGH thinking is about 7–8 s and US$0.004.
USD_PER_CLIP = 0.004
VOICES = {"f1": "female", "m1": "male"}
SPEEDS = {"n": "原速", "s": "慢速"}
ISSUE_TYPES = {
    "misread": "读错",
    "omission": "漏读",
    "extra_speech": "多出来的话",
    "stress": "重音",
    "prosody": "语调节奏",
    "noise": "杂音",
    "truncation": "截断",
    "slow_distortion": "放慢失真",
    "other": "其他",
}
SEVERITY_RANK = {"high": 0, "medium": 1, "low": 2}
TYPE_RANK = {name: rank for rank, name in enumerate(
    ["extra_speech", "omission", "misread", "truncation", "stress", "noise", "slow_distortion", "prosody", "other"]
)}
# Issues about consonant length are dropped even if the model reports them anyway.
GEMINATION_TALK = re.compile(r"gemina|double consonant|consonant length|双辅音|辅音长|长辅音|短辅音", re.I)
# Doubled consonant letters; "cq" (acqua) is a double consonant too.
DOUBLE = re.compile(r"([bcdfghlmnpqrstvz])\1|cq", re.I)

PROMPT = """You are screening Italian text-to-speech clips for a beginner course. The learner cannot judge \
Italian pronunciation, so you are the first filter: flag only clips a teacher would clearly reject, and \
let a human listen to those.

Target text (the clip should say exactly this, nothing more): {text}
Voice: {voice} TTS voice.
Speed: {speed}

Check the whole line:
1. misread: a word pronounced as a different word, or clearly wrong vowels/consonants (other than consonant length).
2. omission: a word or part of a word missing.
3. extra_speech: anything spoken that is not in the target text, e.g. an English instruction read aloud, a repeated word.
4. stress: stress clearly on the wrong syllable (e.g. NA-po-li said na-PO-li is fine to flag; small variation is not).
5. prosody: intonation or rhythm very unnatural for a native speaker (a question said flat is NOT an issue unless it sounds wrong; pauses in odd places are).
6. noise or truncation: clicks, hum, glitches, or the start or end cut off.
{slow_check}
Do NOT judge consonant length (single vs double consonants such as pala/palla, caffè, mamma). Assume it is \
correct and never mention it. Ordinary TTS smoothness, a single word read in isolation, and normal \
variation between native speakers are fine.

Reply with JSON only, in this shape:
{{"ok": true or false, "heard": "what is actually said, transcribed in Italian", \
"issues": [{{"type": one of {types}, "where": "the word or the moment", "detail": "简体中文，一句话"}}], \
"severity": "high" | "medium" | "low" | "none", "reason": "简体中文，一两句总结", "confidence": 0.0 to 1.0}}
"ok" is false only when there is at least one issue. "confidence" is how sure you are of the verdict."""

SLOW_CHECK = """7. slow_distortion: this clip was slowed to {tempo}x with ffmpeg atempo (pitch kept). A little smearing \
is expected; flag warbling, echo, metallic or robotic artifacts, or words that become hard to make out.
"""


@dataclass
class Clip:
    key: str
    file: str
    voice: str  # profile, e.g. "f1@1"
    speed: str  # "n" or "s"
    text: str

    @property
    def voice_id(self) -> str:
        return self.voice.split("@", 1)[0]


def week_texts(week: int) -> set[str]:
    """The Italian lines the given week's units play. Frame examples count as week 1."""
    course = load_json(CONTENT / "course.json")
    units = {unit["id"] for unit in course["units"] if unit["week"] == week}
    texts = {frame["example"] for frame in course["frames"]} if week == 1 else set()
    for path in sorted((CONTENT / "lessons").glob("*.json")):
        lesson = load_json(path)
        if lesson["unit"] in units:
            texts |= {phrase["it"] for phrase in lesson["phrases"]}
    for path in sorted((CONTENT / "dialogues").glob("*.json")):
        script = load_json(path)
        if script["unit"] in units:
            nodes = script["nodes"] + (script.get("followUps") or {}).get("pool", [])
            texts |= {line["it"] for node in nodes for line in node["npc"]}
    return texts


def clips_for(week: int) -> list[Clip]:
    texts = week_texts(week)
    clips = []
    for key, name in load_json(MANIFEST)["entries"].items():
        voice, speed, text = key.split("|", 2)
        if text in texts:
            clips.append(Clip(key, name, voice, speed, text))
    return sorted(clips, key=lambda clip: (clip.text, clip.voice, clip.speed))


def double_consonant_words(text: str) -> list[str]:
    words = re.findall(r"[^\W\d_]+", text)
    return list(dict.fromkeys(word for word in words if DOUBLE.search(word)))


def parse_verdict(raw: str) -> dict:
    """Normalizes the model's JSON; drops anything about consonant length."""
    text = raw.strip()
    if text.startswith("```"):
        text = re.sub(r"^```\w*\s*|\s*```$", "", text)
    data = json.loads(text)
    if isinstance(data, list) and len(data) == 1:
        data = data[0]
    issues = []
    for issue in data.get("issues") or []:
        kind = str(issue.get("type", "other"))
        issue = {
            "type": kind if kind in ISSUE_TYPES else "other",
            "where": str(issue.get("where", "")),
            "detail": str(issue.get("detail", "")),
        }
        if GEMINATION_TALK.search(issue["where"] + " " + issue["detail"]):
            continue
        issues.append(issue)
    try:
        confidence = max(0.0, min(1.0, float(data.get("confidence", 0))))
    except (TypeError, ValueError):
        confidence = 0.0
    severity = str(data.get("severity", "none")).lower()
    return {
        "ok": not issues,
        "heard": str(data.get("heard", "")),
        "issues": issues,
        "severity": severity if severity in SEVERITY_RANK and issues else ("medium" if issues else "none"),
        "reason": str(data.get("reason", "")) if issues else "",
        "confidence": confidence,
        "modelOk": bool(data.get("ok", True)),
    }


class Reviewer(Gemini):
    def review(self, clip: Clip, model: str, tempo: float) -> dict:
        audio = (AUDIO / clip.file).read_bytes()
        speed = "normal speed" if clip.speed == "n" else f"slow ({tempo}x)"
        prompt = PROMPT.format(
            text=clip.text,
            voice=VOICES.get(clip.voice_id, "a"),
            speed=speed,
            slow_check=SLOW_CHECK.format(tempo=tempo) if clip.speed == "s" else "",
            types=" | ".join(f'"{name}"' for name in ISSUE_TYPES),
        )
        body = {
            "contents": [{"role": "user", "parts": [
                {"inlineData": {"mimeType": "audio/mp4", "data": base64.b64encode(audio).decode("ascii")}},
                {"text": prompt},
            ]}],
            "generationConfig": {
                "thinkingConfig": {"thinkingLevel": "HIGH"},
                "responseMimeType": "application/json",
            },
        }
        data = self._post(model, body)
        parts = data["candidates"][0]["content"]["parts"]
        raw = "".join(part.get("text", "") for part in parts if not part.get("thought"))
        verdict = parse_verdict(raw)
        usage = data.get("usageMetadata", {})
        return {
            "key": clip.key,
            "model": model,
            "promptRev": PROMPT_REV,
            "screenedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "usage": {
                "prompt": usage.get("promptTokenCount", 0),
                "output": usage.get("candidatesTokenCount", 0),
                "thoughts": usage.get("thoughtsTokenCount", 0),
            },
            **verdict,
        }


def load_cache() -> dict[str, dict]:
    if CACHE.exists():
        return load_json(CACHE)["entries"]
    return {}


def save_cache(entries: dict[str, dict]) -> None:
    REVIEWS.mkdir(exist_ok=True)
    tmp = tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=REVIEWS, suffix=".json", delete=False)
    with tmp:
        json.dump({"version": 1, "entries": dict(sorted(entries.items()))}, tmp, ensure_ascii=False, indent=2)
        tmp.write("\n")
    os.replace(tmp.name, CACHE)


def is_fresh(clip: Clip, entry: dict | None, model: str) -> bool:
    return bool(entry) and entry["key"] == clip.key and entry["model"] == model and entry["promptRev"] == PROMPT_REV


def priority(entry: dict) -> tuple:
    types = [issue["type"] for issue in entry["issues"]]
    return (
        SEVERITY_RANK.get(entry["severity"], 1),
        min((TYPE_RANK[kind] for kind in types), default=len(TYPE_RANK)),
        -entry["confidence"],
    )


def describe(clip: Clip, voice_names: dict[str, str]) -> str:
    name = voice_names.get(clip.voice_id)
    return f"{clip.voice}（{name}）" if name else clip.voice


def write_reports(week: int, clips: list[Clip], cache: dict[str, dict], model: str, voice_names: dict[str, str]) -> tuple[Path, Path, list]:
    screened = [(clip, cache[clip.file]) for clip in clips if is_fresh(clip, cache.get(clip.file), model)]
    suspicious = sorted(((clip, entry) for clip, entry in screened if not entry["ok"]), key=lambda pair: priority(pair[1]))
    by_speed = {speed: sum(1 for clip, _ in suspicious if clip.speed == speed) for speed in SPEEDS}
    tokens = {name: sum(entry["usage"][name] for _, entry in screened) for name in ("prompt", "output", "thoughts")}
    cost = len(screened) * USD_PER_CLIP
    gemination = sorted({clip.text for clip in clips if double_consonant_words(clip.text)})
    pending = len(clips) - len(screened)

    md = [f"# 示范音频粗筛：第 {week} 周", ""]
    md.append(f"由 `tools/audio_review.py` 生成。模型 `{model}`（thinkingLevel HIGH）听每段音频并对照原文，"
              "只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，"
              "含双辅音的句子统一备注“双辅音需人工听”。")
    md.append("")
    md.append(f"逐条点听：[audio-screen-week{week}.html](audio-screen-week{week}.html)（在仓库里用浏览器打开）。")
    md.append("")
    md.append("## 可疑片段")
    md.append("")
    if not suspicious:
        md.append("没有。" if screened else "还没有筛过的片段。")
        md.append("")
    for index, (clip, entry) in enumerate(suspicious, 1):
        kinds = "、".join(dict.fromkeys(ISSUE_TYPES[issue["type"]] for issue in entry["issues"]))
        md.append(f"### {index}. {clip.text}")
        md.append("")
        md.append(f"- 声线 {describe(clip, voice_names)} · {SPEEDS[clip.speed]} · `{clip.file}`")
        md.append(f"- 问题：{kinds}（严重度 {entry['severity']}，置信度 {entry['confidence']:.2f}）")
        md.append(f"- 理由：{entry['reason'] or '（无）'}")
        for issue in entry["issues"]:
            where = f"「{issue['where']}」" if issue["where"] else ""
            md.append(f"  - {ISSUE_TYPES[issue['type']]}{where}：{issue['detail']}")
        if entry["heard"]:
            md.append(f"- 模型听到：{entry['heard']}")
        words = double_consonant_words(clip.text)
        if words:
            md.append(f"- 双辅音需人工听：{', '.join(words)}")
        md.append("")
    md.append("## 双辅音需人工听")
    md.append("")
    md.append("这些句子含双辅音，长短要人去听（不计入可疑）：")
    md.append("")
    for text in gemination:
        md.append(f"- {text} — {', '.join(double_consonant_words(text))}")
    md.append("")
    md.append("## 统计")
    md.append("")
    md.append(f"- 本周音频：{len(clips)} 段（原速 {sum(c.speed == 'n' for c in clips)}，慢速 {sum(c.speed == 's' for c in clips)}）")
    md.append(f"- 已筛：{len(screened)} 段" + (f"，未筛 {pending} 段" if pending else ""))
    md.append(f"- 可疑：{len(suspicious)} 段（原速 {by_speed['n']}，慢速 {by_speed['s']}）")
    md.append(f"- 含双辅音的句子：{len(gemination)} 句")
    md.append(f"- token：输入 {tokens['prompt']:,}，输出 {tokens['output']:,}，思考 {tokens['thoughts']:,}")
    md.append(f"- 花费估算：{len(screened)} 次 × ${USD_PER_CLIP} ≈ ${cost:.2f}（按实测单价；只重筛新片段时实际花费更少）")
    md.append("")
    md_path = REVIEWS / f"audio-screen-week{week}.md"
    md_path.write_text("\n".join(md), encoding="utf-8")

    def esc(value: str) -> str:
        return html.escape(value, quote=True)

    cards = []
    for index, (clip, entry) in enumerate(suspicious, 1):
        issues = "".join(
            f"<li><b>{esc(ISSUE_TYPES[issue['type']])}</b>"
            f"{'「' + esc(issue['where']) + '」' if issue['where'] else ''}：{esc(issue['detail'])}</li>"
            for issue in entry["issues"]
        )
        words = double_consonant_words(clip.text)
        cards.append(f"""<section class="card">
  <h2><span class="n">{index}</span>{esc(clip.text)}</h2>
  <p class="meta">{esc(describe(clip, voice_names))} · {SPEEDS[clip.speed]} · <code>{esc(clip.file)}</code> ·
    严重度 {esc(entry['severity'])} · 置信度 {entry['confidence']:.2f}</p>
  <audio controls preload="none" src="../Audio/{esc(clip.file)}"></audio>
  <p>{esc(entry['reason'])}</p>
  <ul>{issues}</ul>
  {f'<p class="meta">模型听到：{esc(entry["heard"])}</p>' if entry['heard'] else ''}
  {f'<p class="meta">双辅音需人工听：{esc(", ".join(words))}</p>' if words else ''}
</section>""")
    by_text: dict[str, dict[tuple[str, str], str]] = {}
    for clip in clips:
        by_text.setdefault(clip.text, {})[(clip.voice, clip.speed)] = clip.file
    gem_rows = []
    for text in gemination:
        players = "".join(
            f'<label>{esc(voice)}<audio controls preload="none" src="../Audio/{esc(name)}"></audio></label>'
            for (voice, speed), name in sorted(by_text[text].items()) if speed == "n"
        )
        gem_rows.append(f"<li><p>{esc(text)} <span class=\"meta\">— {esc(', '.join(double_consonant_words(text)))}</span></p>{players}</li>")

    page = f"""<!doctype html>
<html lang="zh-Hans">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>音频粗筛 第 {week} 周</title>
<style>
:root {{ --bg: #fbfaf7; --fg: #1d1b18; --muted: #6b665e; --card: #fff; --line: #e4e0d8; --accent: #b4442b; }}
@media (prefers-color-scheme: dark) {{
  :root {{ --bg: #171614; --fg: #ece8e1; --muted: #a39d93; --card: #22201d; --line: #36332e; --accent: #e8836b; }}
}}
* {{ box-sizing: border-box; }}
body {{ margin: 0; background: var(--bg); color: var(--fg); font: 16px/1.55 -apple-system, "PingFang SC", system-ui, sans-serif; }}
main {{ max-width: 760px; margin: 0 auto; padding: 24px 16px 64px; }}
h1 {{ font-size: 1.5rem; margin: 0 0 4px; }}
.card {{ background: var(--card); border: 1px solid var(--line); border-radius: 12px; padding: 16px; margin: 16px 0; }}
.card h2 {{ font-size: 1.15rem; margin: 0 0 4px; }}
.n {{ color: var(--accent); margin-right: 8px; }}
.meta {{ color: var(--muted); font-size: 0.875rem; margin: 4px 0; }}
audio {{ width: 100%; margin: 8px 0; }}
ul {{ padding-left: 20px; }}
.gem li {{ margin-bottom: 12px; }}
.gem label {{ display: block; font-size: 0.875rem; color: var(--muted); }}
code {{ font-size: 0.85em; }}
</style>
</head>
<body>
<main>
<h1>示范音频粗筛 · 第 {week} 周</h1>
<p class="meta">已筛 {len(screened)} / {len(clips)} 段，可疑 {len(suspicious)} 段（原速 {by_speed['n']}，慢速 {by_speed['s']}）。
模型 {esc(model)}，花费估算 ${cost:.2f}。按需要听的先后排列。</p>
{''.join(cards) if cards else '<p>没有可疑片段。</p>'}
<details class="gem">
<summary>双辅音需人工听（{len(gemination)} 句，原速）</summary>
<ul>{''.join(gem_rows)}</ul>
</details>
</main>
</body>
</html>
"""
    html_path = REVIEWS / f"audio-screen-week{week}.html"
    html_path.write_text(page, encoding="utf-8")
    return md_path, html_path, suspicious


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--week", type=int, default=1, help="which week's audio to screen (default 1)")
    parser.add_argument("--limit", type=int, default=0, help="screen at most this many new clips")
    parser.add_argument("--only", action="append", default=[], metavar="TEXT",
                        help="only clips whose file name or text contains TEXT (repeatable)")
    parser.add_argument("--redo", action="store_true", help="screen the selected clips again even if cached")
    parser.add_argument("--report-only", action="store_true", help="do not call the model; rewrite the report")
    parser.add_argument("--model", default=MODEL)
    parser.add_argument("--workers", type=int, default=4)
    args = parser.parse_args()

    config = load_json(Path(__file__).resolve().parent / "tts_voices.json")
    voice_names = {voice["id"]: voice["voiceName"] for voice in config["voices"]}
    clips = clips_for(args.week)
    cache = load_cache()

    selected = clips
    if args.only:
        needles = [needle.lower() for needle in args.only]
        selected = [clip for clip in clips if any(n in clip.file.lower() or n in clip.text.lower() for n in needles)]
    todo = [clip for clip in selected if args.redo or not is_fresh(clip, cache.get(clip.file), args.model)]
    missing = [clip for clip in todo if not (AUDIO / clip.file).is_file()]
    todo = [clip for clip in todo if clip not in missing]
    if args.limit:
        todo = todo[: args.limit]
    print(f"week {args.week}: {len(clips)} clips, {len(selected)} selected, {len(todo)} to screen")
    for clip in missing:
        print(f"missing audio file: {clip.file} ({clip.voice} {clip.speed} {clip.text})")

    failures = []
    if todo and not args.report_only:
        env = load_env()
        if not env.get("GOOGLE_CLOUD_PROJECT_NUMBER"):
            print("GOOGLE_CLOUD_PROJECT_NUMBER must be set (environment or .env)", file=sys.stderr)
            return 2
        if not env.get("GOOGLE_API_KEY"):
            print("GOOGLE_API_KEY not set; assuming the environment adds the x-goog-api-key header")
        reviewer = Reviewer(env.get("GOOGLE_API_KEY", ""), env["GOOGLE_CLOUD_PROJECT_NUMBER"], config)
        stop = threading.Event()
        lock = threading.Lock()

        def run(clip: Clip) -> dict:
            if stop.is_set():
                raise RuntimeError("skipped after an authentication error")
            try:
                return reviewer.review(clip, args.model, config["slowTempo"])
            except RuntimeError as error:
                if re.search(r"HTTP (401|403|404)\b", str(error)):
                    stop.set()  # every other request would fail the same way
                raise

        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = {pool.submit(run, clip): clip for clip in todo}
            for done, future in enumerate(concurrent.futures.as_completed(futures), 1):
                clip = futures[future]
                label = f"[{done}/{len(todo)}] {clip.voice} {clip.speed} {clip.text}"
                try:
                    entry = future.result()
                except Exception as error:  # keep going; report at the end
                    failures.append(f"{clip.file} {clip.text!r}: {error}")
                    print(f"{label}: FAILED {error}")
                    continue
                with lock:
                    cache[clip.file] = entry
                    save_cache(cache)  # saved as we go, so an interrupted run keeps its results
                print(f"{label}: {'ok' if entry['ok'] else 'SUSPICIOUS ' + entry['reason']}")

    md_path, html_path, suspicious = write_reports(args.week, clips, cache, args.model, voice_names)
    for line in failures:
        print(f"error: {line}")
    print(f"{len(suspicious)} suspicious; report: {md_path.relative_to(ROOT)}, {html_path.relative_to(ROOT)}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
