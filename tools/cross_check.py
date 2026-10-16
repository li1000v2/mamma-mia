#!/usr/bin/env python3
"""Cross-check lesson and challenge content with Gemini, the second step of the review pipeline.

Each unit is sent to the model in batches: for a lesson its intro and every phrase (Italian,
Chinese, note), for a challenge every line the other person says and every reply choice with its
feedback. The model checks grammar, Lei towards strangers, naturalness and regional usage, the
Chinese translation, the kana / pinyin pronunciation hints, and whether each wrong choice is really
wrong and each right one really right. Its structured answer becomes reviews/cross-check-<unit>.md.

The tool never edits Content/. After reading a report, fix the content by hand; a phrase whose
review is OK may then be marked "checked" with "checkedText" set to its exact Italian text.

Usage (from the repo root):
  python tools/cross_check.py --week 1          every unit of week 1
  python tools/cross_check.py L03 C01           just these units
  python tools/cross_check.py --dry-run L01     print the request instead of sending it

Needs GOOGLE_CLOUD_PROJECT_NUMBER (environment or .env), and GOOGLE_API_KEY when the environment
does not add the x-goog-api-key header itself.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import datetime
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

from gen_audio import load_env, post

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "Content"
REVIEWS = ROOT / "reviews"
MODEL = "gemini-4-argon"

INSTRUCTIONS = """\
你是意大利语教学内容的审校。学习者是母语为中文、会日语假名的成年人，12 月去意大利旅行（威尼斯、佛罗伦萨、罗马等），
用一个自学 app 学旅行意大利语。app 的讲解和翻译都是简体中文，发音提示用日语假名近似，有时用拼音。

内容的固定约定（不符合就算问题）：
- 对陌生人（店员、服务员、路人、司机）一律用 Lei：Scusi、Può…?、Mi dica，不用 tu 的形式。
- 学习者说自己的句子用阳性：Sono arrivato、Sono stanco。
- 只教“怎么问”，不把票价、营业时间这类会变的事实写成定论；挑战剧本里店员报的价格只是练习用的数字，不算问题。

逐条审查给你的每个条目（用条目的 id 回答，每个 id 回答一次，不要漏）：
1. 语法：拼写、重音符号（è、più、può、caffè）、性数配合、动词变位、介词和冠词。
2. 语域：对陌生人是否用 Lei，礼貌程度是否合适。
3. 地道：意大利人在这个场景下真的会这么说吗？有没有更常见的说法？有地区差异就说明（比如北方 brioche、中南部 cornetto）。
4. 中文：翻译是否准确、自然，有没有漏译或多译；讲解（note、intro、feedback）里关于意大利语的说法是否正确。
5. 发音提示：note 和 intro 里的假名、拼音是否对得上意大利语的实际读音（重音位置、双辅音、清浊、gli／gn／sc 等）。
   假名本来就只是近似，只指出会误导学习者的地方，不要为了更精确而改写。
   你只审文字，听不到音频：不要评判示范音频，也不要对双辅音实际读多长下结论；
   双辅音只核对提示文字和拼写是否一致（拼写有双辅音，提示里就该有ッ、ン或长音这类标记）。
6. 剧本选项：correct 为 true 的选项在这个情境下是否真的对、自然；correct 为 false 的选项是否真的不合适（
   如果其实也说得通，就是问题），以及 feedback 对错误原因的解释是否准确。
7. 剧本台词：店员等角色的台词是否符合真实场景，中文翻译是否准确；带 answer／distractors 的台词，答案和干扰项是否和意大利语一致、干扰项是否确实错。

判定：没有需要改的地方就 verdict 填 "ok"、issues 留空。只要有一处建议修改就填 "revise"，每个问题写一条 issue：
- field：问题所在的字段。
- severity："error" 是错误，必须改；"suggestion" 是可改可不改的改进。
- problem：用中文说明问题和理由，简洁具体。
- suggestion：建议的写法，直接给出可替换原字段的完整文本（意大利语字段给意大利语，中文字段给中文）。
不要为了凑数挑刺：真没问题就是 ok。审 intro、note 这类讲解时，只在说法错误、会误导或明显不清楚时提出。
comment 可以留空；有值得学习者知道、但不需要改内容的补充（比如地区差异、另一种说法）时写一两句中文。
"""

FIELDS = ["it", "zh", "note", "intro", "npc", "answer", "distractors", "choice", "correct", "feedback", "intent", "question"]

RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "verdict": {"type": "string", "enum": ["ok", "revise"]},
                    "issues": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "field": {"type": "string", "enum": FIELDS},
                                "severity": {"type": "string", "enum": ["error", "suggestion"]},
                                "problem": {"type": "string"},
                                "suggestion": {"type": "string"},
                            },
                            "required": ["field", "severity", "problem", "suggestion"],
                        },
                    },
                    "comment": {"type": "string"},
                },
                "required": ["id", "verdict", "issues"],
            },
        },
    },
    "required": ["items"],
}


@dataclass
class Item:
    """One thing to review, with what the model needs to see and what the report shows."""
    id: str
    kind: str  # "intro", "phrase", "npc" or "choice"
    data: dict
    shown: list[tuple[str, str]]  # (label, text) pairs quoted in the report


@dataclass
class Unit:
    id: str
    kind: str  # "lesson" or "challenge"
    title: str
    context: dict
    items: list[Item] = field(default_factory=list)


@dataclass
class Review:
    verdict: str
    issues: list[dict]
    comment: str = ""


def load_json(path: Path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def lesson_unit(path: Path, titles: dict[str, str]) -> Unit:
    lesson = load_json(path)
    unit = Unit(lesson["unit"], "lesson", titles.get(lesson["unit"], ""), {"unit": lesson["unit"], "title": titles.get(lesson["unit"], "")})
    if lesson.get("intro"):
        unit.items.append(Item(f"{unit.id}/intro", "intro", {"intro": lesson["intro"]}, [("intro", lesson["intro"])]))
    for phrase in lesson["phrases"]:
        data = {key: phrase[key] for key in ("it", "zh", "note") if phrase.get(key)}
        shown = [("it", phrase["it"]), ("zh", phrase["zh"])] + ([("note", phrase["note"])] if phrase.get("note") else [])
        unit.items.append(Item(phrase["id"], "phrase", data, shown))
    return unit


def dialogue_unit(path: Path) -> Unit:
    script = load_json(path)
    unit = Unit(script["unit"], "challenge", script["title"], {
        "unit": script["unit"], "title": script["title"], "goal": script["goal"], "speaker": script["speaker"],
    })
    follow_ups = script.get("followUps") or {}
    nodes = [(node, False) for node in script["nodes"]] + [(node, True) for node in follow_ups.get("pool", [])]
    for node, is_follow_up in nodes:
        where = f"{unit.id}/{node['id']}"
        npc_lines = [{"it": line["it"], "zh": line["zh"]} for line in node["npc"]]
        for index, line in enumerate(node["npc"], 1):
            data = {"speaker": script["speaker"], "it": line["it"], "zh": line["zh"]}
            situation = []
            if is_follow_up:
                situation.append(f"随机插在 {follow_ups['after']} 之后的追问")
            if len(node["npc"]) > 1:
                situation.append("这一步随机抽一句来说，几句是互相替换的版本")
            if situation:
                data["situation"] = "；".join(situation)
            for key in ("answer", "distractors"):
                if key in line:
                    data[key] = line[key]
            if "question" in node:
                data["question"] = node["question"]
            shown = [("it", line["it"]), ("zh", line["zh"])]
            if "answer" in line:
                shown.append(("answer", f"{line['answer']}（干扰项：{'、'.join(line.get('distractors', []))}）"))
            unit.items.append(Item(f"{where}/npc{index}", "npc", data, shown))
        reply = node.get("reply")
        if not reply:
            continue
        for index, choice in enumerate(reply["choices"], 1):
            data = {
                "after": npc_lines,
                "intent": reply["intent"],
                "it": choice["it"],
                "correct": choice["correct"],
                "otherChoices": [{"it": other["it"], "correct": other["correct"]} for other in reply["choices"] if other is not choice],
            }
            if "feedback" in choice:
                data["feedback"] = choice["feedback"]
            label = "✔ 正确选项" if choice["correct"] else "✘ 错误选项"
            shown = [(label, choice["it"])] + ([("feedback", choice["feedback"])] if "feedback" in choice else [])
            unit.items.append(Item(f"{where}/choice{index}", "choice", data, shown))
    return unit


def load_units(wanted: list[str], week: int | None) -> list[Unit]:
    course = load_json(CONTENT / "course.json")
    titles = {unit["id"]: unit["title"] for unit in course["units"]}
    if week is not None:
        wanted = wanted + [unit["id"] for unit in course["units"] if unit["week"] == week]
    files = {path.stem: path for folder in ("lessons", "dialogues") for path in (CONTENT / folder).glob("*.json")}
    order = [unit["id"] for unit in course["units"]]
    ids = sorted(set(wanted) or set(files), key=lambda unit: (order.index(unit) if unit in order else len(order), unit))
    units = []
    for unit_id in ids:
        if unit_id not in files:
            raise SystemExit(f"no content file for {unit_id}")
        path = files[unit_id]
        units.append(lesson_unit(path, titles) if path.parent.name == "lessons" else dialogue_unit(path))
    return units


def batches(unit: Unit, size: int) -> list[list[Item]]:
    """Chunks of at most `size` items. A challenge keeps each node's lines and choices together."""
    groups: list[list[Item]] = []
    for item in unit.items:
        node = item.id.rsplit("/", 1)[0] if unit.kind == "challenge" else item.id
        if groups and unit.kind == "challenge" and groups[-1][0].id.rsplit("/", 1)[0] == node:
            groups[-1].append(item)
        else:
            groups.append([item])
    chunks: list[list[Item]] = []
    for group in groups:
        if chunks and len(chunks[-1]) + len(group) <= size:
            chunks[-1].extend(group)
        else:
            chunks.append(list(group))
    return chunks


def request_body(unit: Unit, items: list[Item], thinking: str) -> dict:
    payload = {
        "unit": unit.context,
        "items": [{"id": item.id, "kind": item.kind, **item.data} for item in items],
    }
    if unit.kind == "lesson":
        intro = next((item.data["intro"] for item in unit.items if item.kind == "intro"), None)
        if intro and not any(item.kind == "intro" for item in items):
            payload["unit"] = {**unit.context, "intro": intro}  # context only; reviewed in another batch
    prompt = (
        "下面是一个单元的内容（JSON）。按说明逐条审查 items 里的每个条目。"
        + ("这是课程单元：kind 为 intro 的是本课的讲解，phrase 是要教的句子。" if unit.kind == "lesson" else
           "这是挑战剧本：npc 是对方说的台词，choice 是学习者在 intent 情境下可选的回答，correct 标明对错；"
           "choice 的 after 是对方刚说的话，有多句时是随机抽一句的不同版本。")
        + "\n\n" + json.dumps(payload, ensure_ascii=False, indent=2)
    )
    return {
        "systemInstruction": {"parts": [{"text": INSTRUCTIONS}]},
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseMimeType": "application/json",
            "responseSchema": RESPONSE_SCHEMA,
            "thinkingConfig": {"thinkingLevel": thinking},
        },
    }


def parse_reviews(data: dict, items: list[Item]) -> tuple[dict[str, Review], list[str]]:
    """Reviews by item id, and the ids the model skipped."""
    candidate = data["candidates"][0]
    text = "".join(part.get("text", "") for part in candidate.get("content", {}).get("parts", []) if not part.get("thought"))
    if not text:
        raise RuntimeError(f"empty response (finishReason {candidate.get('finishReason')})")
    answers = json.loads(text)["items"]
    wanted = {item.id for item in items}
    reviews: dict[str, Review] = {}
    for answer in answers:
        if answer["id"] not in wanted:
            continue
        issues = answer.get("issues") or []
        verdict = "revise" if issues else "ok"  # an issue always means revise, whatever the label said
        reviews[answer["id"]] = Review(verdict, issues, (answer.get("comment") or "").strip())
    return reviews, [item.id for item in items if item.id not in reviews]


def review_unit(unit: Unit, key: str, project: str, thinking: str, batch_size: int) -> dict[str, Review]:
    reviews: dict[str, Review] = {}
    for chunk in batches(unit, batch_size):
        pending, problem = chunk, ""
        for _ in range(3):  # ask again for anything the model skipped or garbled
            data = post(key, project, MODEL, request_body(unit, pending, thinking), timeout=600)
            try:
                got, skipped = parse_reviews(data, pending)
            except (json.JSONDecodeError, KeyError, IndexError, TypeError, RuntimeError) as error:
                problem = f" (unreadable answer: {error})"
                continue
            reviews.update(got)
            pending = [item for item in pending if item.id in skipped]
            if not pending:
                break
            problem = " (the model skipped them)"
        if pending:
            raise RuntimeError(f"no review for {', '.join(item.id for item in pending)}{problem}")
    return reviews


DOUBLE = re.compile(r"([bcdfglmnpqrstvz])\1")


def minimal_pairs(texts: list[str]) -> list[str]:
    """Pairs like pala/palla that differ only by a double consonant, e.g. in L02's intro."""
    words = {word.lower() for text in texts for word in re.findall(r"[A-Za-zÀ-ÿ]+", text)}
    pairs = []
    for word in sorted(words):
        single = DOUBLE.sub(r"\1", word)
        if single != word and single in words and re.search(r"[aeiouàèéìòù]", single):
            pairs.append(f"{single}/{word}")
    return pairs


def quote(text: str) -> str:
    return "\n".join(f"> {line}" if line else ">" for line in text.splitlines())


def inline(text: str) -> str:
    return text.replace("|", "\\|").replace("\n", "<br>")


SEVERITY = {"error": "错误", "suggestion": "建议"}


def render(unit: Unit, reviews: dict[str, Review], thinking: str) -> str:
    ok = sum(1 for item in unit.items if reviews[item.id].verdict == "ok")
    errors = sum(1 for item in unit.items for issue in reviews[item.id].issues if issue["severity"] == "error")
    lines = [
        f"# 交叉校对：{unit.id} {unit.title}",
        "",
        f"- 模型：{MODEL}（思考级别 {thinking}），{datetime.date.today().isoformat()}",
        f"- {len(unit.items)} 条：{ok} 条 OK，{len(unit.items) - ok} 条建议修改（其中 {errors} 处标为错误）",
        "- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。"
        "改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。",
        "",
    ]
    revise = [item for item in unit.items if reviews[item.id].verdict == "revise"]
    if revise:
        lines += ["## 需要看的条目", ""]
        for item in revise:
            first = reviews[item.id].issues[0]
            more = f"（另有 {len(reviews[item.id].issues) - 1} 处）" if len(reviews[item.id].issues) > 1 else ""
            lines.append(f"- **{item.id}**：{SEVERITY[first['severity']]}，{inline(first['problem'].strip().splitlines()[0])}{more}")
        lines.append("")
    lines += ["## 逐条结果", ""]
    for item in unit.items:
        review = reviews[item.id]
        mark = "✅ OK" if review.verdict == "ok" else "✏️ 建议修改"
        lines += [f"### {item.id} — {mark}", ""]
        for label, text in item.shown:
            if label == "intro":
                lines += ["<details><summary>intro 原文</summary>", "", quote(text), "", "</details>", ""]
            else:
                lines.append(f"- **{label}**：{inline(text)}")
        if item.kind != "intro":
            lines.append("")
        if review.issues:
            lines += ["| 字段 | 级别 | 问题 | 建议写法 |", "| --- | --- | --- | --- |"]
            for issue in review.issues:
                lines.append(
                    f"| {issue['field']} | {SEVERITY[issue['severity']]} | {inline(issue['problem'])} | {inline(issue['suggestion'])} |"
                )
            lines.append("")
        if review.comment:
            lines += [f"补充：{review.comment}", ""]
        pairs = minimal_pairs([text for _, text in item.shown])
        if pairs:
            lines += [f"⚠️ 最小对立词 {'、'.join(pairs)}：TTS 单独念词时双辅音可能不够长，音频需要人工听。", ""]
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("units", nargs="*", help="unit ids such as L01 or C02 (default: all content)")
    parser.add_argument("--week", type=int, help="add every unit of this course week")
    parser.add_argument("--thinking", choices=["LOW", "MEDIUM", "HIGH"], default="HIGH")
    parser.add_argument("--batch-size", type=int, default=12, help="most items per request")
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--dry-run", action="store_true", help="print the requests instead of sending them")
    args = parser.parse_args()

    units = load_units(args.units, args.week)
    if args.dry_run:
        for unit in units:
            for chunk in batches(unit, args.batch_size):
                print(request_body(unit, chunk, args.thinking)["contents"][0]["parts"][0]["text"])
                print()
        print(f"{len(units)} units, {sum(len(unit.items) for unit in units)} items", file=sys.stderr)
        return 0

    env = load_env()
    if not env.get("GOOGLE_CLOUD_PROJECT_NUMBER"):
        print("GOOGLE_CLOUD_PROJECT_NUMBER must be set (environment or .env)", file=sys.stderr)
        return 2
    if not env.get("GOOGLE_API_KEY"):
        print("GOOGLE_API_KEY not set; assuming the environment adds the x-goog-api-key header")
    REVIEWS.mkdir(exist_ok=True)
    failures = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(review_unit, unit, env.get("GOOGLE_API_KEY", ""), env["GOOGLE_CLOUD_PROJECT_NUMBER"], args.thinking, args.batch_size): unit
            for unit in units
        }
        for future in concurrent.futures.as_completed(futures):
            unit = futures[future]
            try:
                reviews = future.result()
            except Exception as error:  # keep going; report at the end
                failures.append(f"{unit.id}: {error}")
                print(f"{unit.id}: FAILED {error}")
                continue
            path = REVIEWS / f"cross-check-{unit.id}.md"
            path.write_text(render(unit, reviews, args.thinking), encoding="utf-8", newline="\n")
            revise = sum(1 for review in reviews.values() if review.verdict == "revise")
            print(f"{unit.id}: {len(reviews) - revise} OK, {revise} to revise → {path.relative_to(ROOT)}")
    for line in failures:
        print(f"error: {line}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
