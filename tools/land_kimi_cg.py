"""把 Kimi 的五张 CG 落进 assets/art/cg/ch2/，并按台词定位给 kimi_moon 的页挂 bg。"""

import csv
import io
import json
import os
import shutil

from PIL import Image

ROOT = r"E:\godot_workplace\测试"
RAW = os.path.join(ROOT, "素材", "二期立绘", "_raw3")
CG_DIR = os.path.join(ROOT, "assets", "art", "cg", "ch2")
STORY = os.path.join(ROOT, "data", "story.json")
CSV_PATH = os.path.join(ROOT, "data", "i18n", "strings.csv")

SHOTS = {
    "kimi_henshin": "cg_kimi_henshin_00001_.png",
    "kimi_jump": "_jump_fix2.png",
    "kimi_moon": "cg_kimi_moon_00001_.png",
    "kimi_kick": "cg_kimi_kick_00001_.png",
    "kimi_wreck": "cg_kimi_wreck2_00001_.png",
}

# 用台词片段定位要挂图的页
ANCHORS = {
    "kimi_henshin": "一道光从她背后炸开",
    "kimi_jump": "月亮在她耳朵之间",
    "kimi_moon": "我还以为会有水",
    "kimi_kick": "骑士踢",
    "kimi_wreck": "撞穿墙",
}


def main():
    os.makedirs(CG_DIR, exist_ok=True)
    for name, src in SHOTS.items():
        path = src if os.path.isabs(src) else os.path.join(RAW, src)
        im = Image.open(path).convert("RGB")
        im.save(os.path.join(CG_DIR, name + ".webp"), "WEBP", quality=92, method=6)
        print("落图", name, im.size)

    with io.open(CSV_PATH, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh))[1:]

    def find_key(fragment):
        for r in rows:
            if r and len(r) > 1 and fragment in r[1]:
                return r[0]
        return ""

    data = json.load(io.open(STORY, encoding="utf-8-sig"))
    pages = data["kimi_moon"]["pages"]
    wanted = {}
    for name, frag in ANCHORS.items():
        key = find_key(frag)
        if not key:
            print("找不到锚点:", name, frag)
            continue
        for i, p in enumerate(pages):
            if p.get("text") == key:
                wanted[i] = name
                break

    for i, name in sorted(wanted.items()):
        pages[i]["bg"] = "res://assets/art/cg/ch2/%s.webp" % name
        pages[i]["hide_face"] = True

    # 挂完图之后下一句撤图回立绘
    for i in sorted(wanted):
        nxt = i + 1
        if nxt < len(pages) and nxt not in wanted:
            pages[nxt]["bg"] = "-"

    json.dump(data, io.open(STORY, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    with io.open(STORY, "a", encoding="utf-8") as fh:
        fh.write("\n")
    print("已挂 CG 的页:", sorted(wanted.items()))


if __name__ == "__main__":
    main()
