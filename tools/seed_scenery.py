"""生成 data/scenery.json（大洋彼岸的景色）并把文案写进 strings.csv。"""

import csv
import io
import json
import os

ROOT = r"E:\godot_workplace\测试"
OUT = os.path.join(ROOT, "data", "scenery.json")
CSV_PATH = os.path.join(ROOT, "data", "i18n", "strings.csv")

ITEMS = [
    ("statue", "倒下的雕像",
     "res://assets/art/cg/ch2/seattle_statue.webp", 30,
     "金发的总统像被人从基座上掀了下来，头朝下挂在碎石里。没人去扶。"),
    ("protest", "雨里的旗",
     "res://assets/art/cg/ch2/seattle_protest.webp", 30,
     "一排背影，一只手把旗举过肩。雨很大，看不清是谁。"),
    ("trio", "三位先生落水",
     "res://assets/art/cg/ch2/seattle_trio_fall.webp", 25,
     "一个倒立，一个背手仰倒，一个踩空了往前扑。他们说是来考察的。"),
    ("meme", "战至最后一刻",
     "res://assets/art/cg/ch2/meme_dario_laststand.webp", 15,
     "他举着拳头，背后那朵橙色星芒比他人还大。字是自己配的。"),
]


def read_csv():
    with io.open(CSV_PATH, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh))
    return rows[0], [r for r in rows[1:] if r and r[0].strip()]


def main():
    header, rows = read_csv()
    known = {r[0] for r in rows}
    added = 0

    items = []
    for sid, name, art, weight, note in ITEMS:
        name_key = "scene.%s.name" % sid
        note_key = "scene.%s.note" % sid
        for key, text in ((name_key, name), (note_key, note)):
            if key not in known:
                rows.append([key, text, text, text, text])
                known.add(key)
                added += 1
        items.append({
            "id": sid,
            "name": name_key,
            "art": art,
            "weight": weight,
            "note": note_key,
        })

    data = {
        "_doc": "西雅图（大洋彼岸）的景色收藏。进西雅图时由 SceneryDeck.roll() 伪随机抽一张展示，抽到即记账。",
        "collection": "scene.collection",
        "items": items,
    }
    if "scene.collection" not in known:
        rows.append(["scene.collection", "大洋彼岸的景色", "大洋彼岸的景色",
                     "Scenery Across the Ocean", "海の向こうの景色"])
        added += 1

    json.dump(data, io.open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    with io.open(OUT, "a", encoding="utf-8") as fh:
        fh.write("\n")

    with io.open(CSV_PATH, "w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, quoting=csv.QUOTE_ALL, lineterminator="\r\n")
        writer.writerow(header)
        writer.writerows(rows)

    print("景色 %d 条，新增词条 %d 条，strings.csv %d 行" % (len(items), added, len(rows)))


if __name__ == "__main__":
    main()
