"""项目级 RAG 索引生成器（见 docs/plans/2026-11-07-rag.md）。

只做一件事：把 scripts / data / docs / tests / scenes 扫一遍，
抽「够用来定位」的符号与摘要，写成两张表：

  docs/rag/project.json   机器读，{files:[...], stats:{...}}
  docs/rag/MAP.md         人读，目录树 + 每文件一行摘要

不做向量化、不解析语法树、不改业务代码。跑一次几秒，幂等。

用法：
  python tools/rag_index.py
  python tools/rag_index.py --check     只报告缺哪些类目，不写文件
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(r"E:\godot_workplace\测试")
OUT = ROOT / "docs" / "rag"

RE_CLASS = re.compile(r"^class_name\s+(\w+)")
RE_EXTENDS = re.compile(r"^extends\s+(\w+)")
RE_FUNC = re.compile(r"^(?:static\s+)?func\s+(\w+)\s*\(")
RE_CONST = re.compile(r"^const\s+(\w+)")
RE_SIGNAL = re.compile(r"^signal\s+(\w+)")
RE_CASE = re.compile(r"^func\s+(_case_\w+)")
RE_DOC = re.compile(r"^##\s?(.+)")
RE_HEAD = re.compile(r"^(#{1,2})\s+(.+)")
RE_ROOT_NODE = re.compile(r'^\[node name="[^"]*" type="([^"]+)"', re.M)
RE_SCRIPT = re.compile(r'path="res://([^"]+\.gd)"')


def scan_gd(path: Path) -> dict:
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    lines = text.splitlines()
    funcs, consts, signals = [], [], []
    cls = ext = ""
    summary = ""
    for i, line in enumerate(lines, 1):
        if not summary:
            m = RE_DOC.match(line.strip())
            if m and not line.strip().startswith("##!"):
                summary = m.group(1).strip()[:80]
        if m := RE_CLASS.match(line):
            cls = m.group(1)
        elif m := RE_EXTENDS.match(line):
            ext = m.group(1)
        elif m := RE_FUNC.match(line):
            funcs.append({"name": m.group(1), "line": i})
        elif m := RE_CONST.match(line):
            consts.append(m.group(1))
        elif m := RE_SIGNAL.match(line):
            signals.append(m.group(1))
    cases = [f["name"] for f in funcs if f["name"].startswith("_case_")]
    return {
        "kind": "gd",
        "lines": len(lines),
        "class_name": cls,
        "extends": ext,
        "summary": summary,
        "funcs": funcs,
        "consts": consts[:40],
        "signals": signals,
        "cases": cases,
    }


def scan_json(path: Path) -> dict:
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    try:
        data = json.loads(text)
    except Exception as exc:  # 坏 JSON 也要进索引，标出来
        return {"kind": "json", "lines": text.count("\n") + 1, "error": str(exc)[:80]}
    info = {"kind": "json", "lines": text.count("\n") + 1}
    if isinstance(data, dict):
        info["keys"] = [k for k in data.keys() if not str(k).startswith("_")][:30]
        for k, v in data.items():
            if isinstance(v, list) and len(v) > 3:
                ids = [str(it.get("id")) for it in v if isinstance(it, dict) and "id" in it]
                if ids:
                    info.setdefault("ids", {})[k] = ids[:24]
            elif isinstance(v, dict) and len(v) > 3:
                info.setdefault("sections", {})[k] = len(v)
    elif isinstance(data, list):
        info["array_len"] = len(data)
    return info


def scan_md(path: Path) -> dict:
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    heads = []
    for line in text.splitlines():
        if m := RE_HEAD.match(line):
            if len(m.group(1)) == 1:
                heads.append({"t": m.group(2).strip()[:60], "lvl": 1})
            else:
                heads.append({"t": m.group(2).strip()[:60], "lvl": 2})
            if len(heads) >= 20:
                break
    return {"kind": "md", "lines": text.count("\n") + 1, "heads": heads}


def scan_tscn(path: Path) -> dict:
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    m = RE_ROOT_NODE.search(text)
    scripts = RE_SCRIPT.findall(text)
    return {
        "kind": "tscn",
        "lines": text.count("\n") + 1,
        "root": m.group(1) if m else "",
        "scripts": scripts[:6],
    }


SCANNERS = {".gd": scan_gd, ".json": scan_json, ".md": scan_md, ".tscn": scan_tscn}
TARGETS = [
    ("scripts", ".gd"),
    ("data", ".json"),
    ("docs", ".md"),
    ("tests", ".gd"),
    ("scenes", ".tscn"),
]


def collect() -> dict:
    files = []
    stats: dict[str, int] = {}
    for folder, _ext in TARGETS:
        base = ROOT / folder
        if not base.exists():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            scanner = SCANNERS.get(path.suffix.lower())
            if scanner is None:
                continue
            if "rag" in path.parts:  # 别索引自己
                continue
            rel = path.relative_to(ROOT).as_posix()
            entry = {"path": rel}
            entry.update(scanner(path))
            files.append(entry)
            stats[folder] = stats.get(folder, 0) + 1

    art = ROOT / "assets" / "art" / "manifest.json"
    if art.exists():
        data = json.loads(art.read_text(encoding="utf-8-sig"))
        files.append({
            "path": "assets/art/manifest.json",
            "kind": "art",
            "summary": "美术资产索引，按 group/chapter/character/form 过滤",
            "count": data.get("count", 0),
        })
        stats["art"] = data.get("count", 0)

    return {"root": "E:/godot_workplace/测试", "files": files, "stats": stats}


def render_map(data: dict) -> str:
    out = ["# 工程地图（自动生成，别手改）", "",
           "生成器：`python tools/rag_index.py`　计划：`docs/plans/2026-11-07-rag.md`", "",
           "| 类目 | 条数 |", "|---|---|"]
    for k, v in data["stats"].items():
        out.append(f"| {k} | {v} |")
    out.append("")

    groups: dict[str, list[dict]] = {}
    for f in data["files"]:
        top = f["path"].split("/")[0]
        groups.setdefault(top, []).append(f)

    for top in sorted(groups):
        out.append(f"## {top}/")
        out.append("")
        for f in groups[top]:
            bits = [f["path"]]
            if f.get("class_name"):
                bits.append(f"class **{f['class_name']}**")
            if f.get("extends"):
                bits.append(f"extends {f['extends']}")
            if f["kind"] == "gd":
                bits.append(f"{len(f.get('funcs', []))} funcs")
                if f.get("cases"):
                    bits.append(f"{len(f['cases'])} 用例")
            if f["kind"] == "json" and f.get("keys"):
                bits.append("keys: " + ", ".join(f["keys"][:8]))
            if f["kind"] == "md" and f.get("heads"):
                bits.append(f["heads"][0]["t"])
            if f["kind"] == "tscn":
                bits.append(f"root {f.get('root', '?')}")
            if f.get("summary"):
                bits.append(f"「{f['summary']}」")
            bits.append(f"{f.get('lines', '?')} 行")
            out.append("- " + " · ".join(str(b) for b in bits))
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    data = collect()
    print("类目条数:", data["stats"])
    if args.check:
        return

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "project.json").write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    (OUT / "MAP.md").write_text(render_map(data), encoding="utf-8")

    pj = (OUT / "project.json").stat().st_size / 1024
    mp = (OUT / "MAP.md").stat().st_size / 1024
    print(f"docs/rag/project.json  {pj:.0f} KB")
    print(f"docs/rag/MAP.md        {mp:.0f} KB")


if __name__ == "__main__":
    main()
