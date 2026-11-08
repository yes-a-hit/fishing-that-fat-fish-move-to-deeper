"""把 assets/ 下的美术资产重整成 RAG 友好的目录，并同步改掉所有引用。

设计（见 assets/art/INDEX.md）：
  assets/art/cast/{ch}/{角色}/{形态}.webp    立绘 / chibi（人，竖构图或方形）
  assets/art/cg/{ch}/{用途}/{场景}.webp      CG、结局图、演出背景（横 1216×688）
  assets/art/anim/{角色}/{序号_动作}.webp    上鱼动画帧
  assets/art/props/{ch}/*.webp               道具 / 水底杂物 / 水层
  assets/art/ui/*.webp                       HUD 图标、徽章
  assets/art/meta/*                          logo、app icon、彩蛋

用法：
  python tools/art_reorg.py --dry      只看计划
  python tools/art_reorg.py            执行（复制 + 改引用）
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
from pathlib import Path

ROOT = Path(r"E:\godot_workplace\测试")
ASSETS = ROOT / "assets"
ART = ASSETS / "art"

# 角色 id -> (章节, 目录名)
CHARS = {
    # 一期三条鱼
    "portrait_small": ("ch1", "small"),
    "portrait_mid": ("ch1", "mid"),
    "portrait_big": ("ch1", "big"),
    # 二期 cast
    "kimi": ("ch2", "kimi"),
    "glm": ("ch2", "glm"),
    "qwen": ("ch2", "qwen"),
    "ollama": ("ch2", "ollama"),
    "mistral": ("ch2", "mistral"),
    "grok": ("ch2", "grok"),
    "chatgpt": ("ch2", "chatgpt"),
    "abagpt": ("ch2", "abagpt"),
    "gemini": ("ch2", "gemini"),
    "minimax": ("ch2", "minimax"),
    "wenxin": ("ch2", "wenxin"),
    "user": ("ch2", "user"),
    "claude": ("ch1", "claude"),
    "doubao": ("ch1", "doubao"),
}

# 二期 cast 里这些是「形态名」，不是新角色
FORM_SUFFIX = {
    "full": "full",
    "chibi": "chibi",
    "sealed": "sealed",
    "rococo": "rococo",
    "aba": "aba",
    "daily": "daily",
    "k28": "k28",
    "k3": "k3",
    "sleep": "sleep",
    "adult": "adult",
    "sad": "sad",
    "hold": "hold",
    "seed": "seed",
    "kick": "kick",
    "escape": "escape",
}

TEXT_EXT = {".gd", ".json", ".tscn", ".tres", ".csv", ".cfg", ".md", ".godot"}


def plan_for(rel: Path) -> Path | None:
    """给一个旧相对路径（相对 assets/）算出新相对路径（相对 assets/）。"""
    p = rel.as_posix()
    parts = p.split("/")
    stem = Path(parts[-1]).stem
    ext = Path(parts[-1]).suffix.lower()

    if ext not in (".webp", ".png"):
        return None

    # 已经在 art/ 下就不动
    if parts[0] == "art":
        return None

    # ---- 1. cast / phase2.cast：二期角色 ----
    if parts[0] == "cast" and len(parts) == 2:
        if parts[1] == "badges":
            return None
        name, form = split_char_form(stem)
        if name in CHARS:
            ch, folder = CHARS[name]
            return Path("art/cast") / ch / folder / f"{form}{ext}"
        return Path("art/meta") / f"{stem}{ext}"

    if parts[:2] == ["cast", "badges"]:
        return Path("art/ui") / f"badge_{stem}{ext}"

    if parts[0] == "phase2" and len(parts) >= 3 and parts[1] == "cast":
        name, form = split_char_form(stem)
        if name in CHARS:
            ch, folder = CHARS[name]
            return Path("art/cast") / ch / folder / f"{form}{ext}"
        return Path("art/meta") / f"{stem}{ext}"

    # ---- 2. 一期立绘 ----
    if parts[0].startswith("portrait_"):
        key = stem  # portrait_small
        if key in CHARS:
            ch, folder = CHARS[key]
            return Path("art/cast") / ch / folder / f"default{ext}"

    if stem in ("claude_adult", "claude_sad", "claude_hold", "claude_escape",
                "claude_fake_1", "claude_fake_2", "claude_fake_3", "claude_chibi"):
        form = stem.replace("claude_", "")
        return Path("art/cast/ch1/claude") / f"{form}{ext}"

    if parts[0].startswith("doubao"):
        form = stem.replace("doubao_", "") if "_" in stem else "default"
        return Path("art/cast/ch1/doubao") / f"{form}{ext}"

    # ---- 3. 动画帧 ----
    if parts[0] == "anim":
        return Path("art/anim") / Path(*parts[1:])

    # ---- 4. 开场 / 结局 / 脱钩 CG（横图）----
    if parts[0].startswith("opening_"):
        return Path("art/cg/ch1/opening") / f"{stem.replace('opening_', '')}{ext}"
    if parts[0].startswith("ending_"):
        return Path("art/cg/ch1/ending") / f"{stem.replace('ending_', '')}{ext}"
    if stem in ("deepseek_escape", "deepseek_escape_big"):
        return Path("art/cg/ch1/opening") / f"{stem}{ext}"

    # ---- 5. 二期分块 ----
    if parts[0] == "phase2":
        if len(parts) >= 3 and parts[1] == "cg":
            return Path("art/cg/ch2") / f"{stem.replace('cg_dive_', '').replace('dive_', '')}{ext}"
        if len(parts) >= 3 and parts[1] == "dive":
            if parts[2] == "items":
                return Path("art/props/ch2/items") / Path(parts[-1])
            return Path("art/cg/ch2/water") / Path(parts[-1])
        if len(parts) >= 3 and parts[1] == "props":
            return Path("art/props/ch2") / Path(parts[-1])
        if len(parts) >= 3 and parts[1] == "ui":
            return Path("art/ui") / Path(parts[-1])
        if len(parts) >= 3 and parts[1] == "boat":
            return Path("art/cg/ch2/boat") / Path(parts[-1])

    # ---- 6. 道具 / 水层（一期的旧位置）----
    if parts[0] == "dive":
        if len(parts) >= 3 and parts[1] == "items":
            return Path("art/props/ch2/items") / Path(parts[-1])
        return Path("art/cg/ch2/water") / Path(parts[-1])

    # ---- 7. 其它 ----
    if parts[0] in ("easter",):
        return Path("art/meta/easter") / Path(parts[-1])
    if parts[0] in ("coming_soon",):
        return Path("art/meta/coming_soon") / Path(parts[-1])
    if stem.startswith("icon_") or stem == "logo" or stem.startswith("meme_"):
        return Path("art/meta") / Path(parts[-1])

    return None


def split_char_form(stem: str) -> tuple[str, str]:
    """kimi_daily -> (kimi, daily)；kimi_full -> (kimi, full)；user_chibi -> (user, chibi)。"""
    for name in sorted(CHARS, key=len, reverse=True):
        if stem == name:
            return name, "full"
        if stem.startswith(name + "_"):
            tail = stem[len(name) + 1:]
            if tail in FORM_SUFFIX:
                return name, FORM_SUFFIX[tail]
            return name, tail
    return stem.split("_")[0], "full"


def collect_plan() -> dict[Path, Path]:
    out: dict[Path, Path] = {}
    for path in ASSETS.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(ASSETS)
        new = plan_for(rel)
        if new is not None and new != rel:
            out[rel] = new
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry", action="store_true")
    args = ap.parse_args()

    plan = collect_plan()
    print(f"计划迁移 {len(plan)} 个文件")
    for old, new in sorted(plan.items()):
        print(f"  {old.as_posix()}  ->  {new.as_posix()}")

    if args.dry:
        return

    # 1) 复制（保留原件，等引用验证通过再由 --purge 删）
    for old, new in plan.items():
        src = ASSETS / old
        dst = ASSETS / new
        dst.parent.mkdir(parents=True, exist_ok=True)
        if not dst.exists():
            shutil.copy2(src, dst)

    # 2) 改写引用
    subs = {f"res://assets/{o.as_posix()}": f"res://assets/{n.as_posix()}" for o, n in plan.items()}
    changed = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_EXT:
            continue
        if ".godot" in path.parts or "node_modules" in path.parts:
            continue
        try:
            text = path.read_text(encoding="utf-8-sig")
        except Exception:
            continue
        hit = False
        for old, new in subs.items():
            if old in text:
                text = text.replace(old, new)
                hit = True
        if hit:
            path.write_text(text, encoding="utf-8")
            changed.append(path.relative_to(ROOT).as_posix())

    print(f"改写 {len(changed)} 个引用文件")
    for c in changed:
        print("  " + c)

    # 3) 索引
    build_index()


def build_index() -> None:
    entries = []
    for path in sorted(ART.rglob("*")):
        if not path.is_file() or path.suffix in (".import", ".md", ".json"):
            continue
        rel = path.relative_to(ART).as_posix()
        parts = rel.split("/")
        entry = {
            "path": "res://assets/art/" + rel,
            "group": parts[0],
        }
        if parts[0] == "cast" and len(parts) >= 4:
            entry["chapter"] = parts[1]
            entry["character"] = parts[2]
            entry["form"] = Path(parts[3]).stem
        elif parts[0] == "cg" and len(parts) >= 4:
            entry["chapter"] = parts[1]
            entry["usage"] = parts[2]
        entry["bytes"] = path.stat().st_size
        entries.append(entry)
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "manifest.json").write_text(
        json.dumps({"root": "res://assets/art", "count": len(entries), "items": entries},
                   ensure_ascii=False, indent=1),
        encoding="utf-8")
    print(f"索引写好：assets/art/manifest.json（{len(entries)} 条）")


if __name__ == "__main__":
    main()
