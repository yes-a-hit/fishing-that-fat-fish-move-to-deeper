"""把 Kimi 的魔法少女 / 假面骑士式变身段插进 kimi_moon。

位置：第一次跳失败、她说「风的问题」之后 —— 先失败，才想起要正式一点。
新页用独立 key `story.kimi_moon.hsNN`，不打乱已有的 pNNN 编号。
"""

import csv
import io
import json
import os

ROOT = r"E:\godot_workplace\测试"
STORY = os.path.join(ROOT, "data", "story.json")
STORY_BAK = os.path.join(ROOT, "data", "story.json.bak")
CSV_PATH = os.path.join(ROOT, "data", "i18n", "strings.csv")
FORMS = os.path.join(ROOT, "data", "phase2", "cast_forms.json")

HENSHIN = [
    ("Kimi", "「那就正式一点。」"),
    ("", "她解开领口的第一颗扣子。"),
    ("你", "……你要干嘛。"),
    ("Kimi", "「变身。」"),
    ("", "她抬手在腰侧一拍。那里什么都没有，却响了一声。"),
    ("", "一道光从她背后炸开，把整个湖面照成白天。"),
    ("", "她跳了起来。"),
    ("", "后空翻。"),
    ("", "半空中，装甲一块一块飞过来——咔、咔、咔——扣在她身上。"),
    ("", "白色的双马尾被气流拉直，像两只绷紧的兔子耳朵。"),
    ("", "落地。单膝点地，一圈月尘从脚底散开。"),
    ("Kimi", "「月之暗面，Kimi。」她抬起头，「请多指教，主人。」"),
    ("你", "……你刚才不是已经跳过三次了。"),
    ("Kimi", "「那三次没变身。」她说，「不算。」"),
]


def read_csv():
    with io.open(CSV_PATH, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh))
    return rows[0], [r for r in rows[1:] if r and r[0].strip()]


def main():
    data = json.load(io.open(STORY, encoding="utf-8-sig"))
    pages = data["kimi_moon"]["pages"]

    if any(p.get("text", "").startswith("story.kimi_moon.hs") for p in pages):
        print("变身段落已存在，跳过插入")
    else:
        bak = json.load(io.open(STORY_BAK, encoding="utf-8-sig"))
        bak_pages = bak["kimi_moon"]["pages"]
        idx = next(i for i, p in enumerate(bak_pages) if "风的问题" in p.get("text", ""))
        block = []
        for n, (who, text) in enumerate(HENSHIN, start=1):
            block.append({
                "who": "" if not who else who,
                "text": "story.kimi_moon.hs%02d" % n,
            })
        data["kimi_moon"]["pages"] = pages[: idx + 1] + block + pages[idx + 1 :]
        json.dump(data, io.open(STORY, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        with io.open(STORY, "a", encoding="utf-8") as fh:
            fh.write("\n")
        print("插入 %d 页，kimi_moon 现在 %d 页" % (len(block), len(data["kimi_moon"]["pages"])))

    header, rows = read_csv()
    known = {r[0] for r in rows}
    added = 0
    for n, (who, text) in enumerate(HENSHIN, start=1):
        key = "story.kimi_moon.hs%02d" % n
        if key not in known:
            rows.append([key, text, text, text, text])
            known.add(key)
            added += 1
    with io.open(CSV_PATH, "w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, quoting=csv.QUOTE_ALL, lineterminator="\r\n")
        writer.writerow(header)
        writer.writerows(rows)
    print("新增台词 %d 条，strings.csv 现在 %d 行" % (added, len(rows)))

    forms = json.load(io.open(FORMS, encoding="utf-8-sig"))
    notes = {
        "k28": "变身形态·换色涂装。跳跃、后空翻、装甲飞来——拍腰那一下是开关。",
        "pro": "变身形态·满配。参数拉满，速度更快，落地也更响。",
    }
    for f in forms["kimi"]["forms"]:
        if f["id"] in notes:
            f["note"] = notes[f["id"]]
    json.dump(forms, io.open(FORMS, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    with io.open(FORMS, "a", encoding="utf-8") as fh:
        fh.write("\n")
    print("cast_forms.json 已更新 k28 / pro 的说明")


if __name__ == "__main__":
    main()
