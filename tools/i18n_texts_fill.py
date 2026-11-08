"""把旧 CSV 里以中文原文为 key 的翻译，接到 char.* / ending.* 新 key 上。"""

import csv
import io
import json
import os

ROOT = r"E:\godot_workplace\测试"
CSV_PATH = os.path.join(ROOT, "data", "i18n", "strings.csv")
CSV_BAK = os.path.join(ROOT, "data", "i18n", "strings.csv.bak")
CHARS = os.path.join(ROOT, "data", "characters.json")
CHARS_BAK = os.path.join(ROOT, "data", "characters.json.bak")
ENDINGS = os.path.join(ROOT, "data", "endings.json")
ENDINGS_BAK = os.path.join(ROOT, "data", "endings.json.bak")


def read_csv(path):
    with io.open(path, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh))
    return rows[0], [r for r in rows[1:] if r and r[0].strip()]


def main():
    _, old_rows = read_csv(CSV_BAK)
    old_map = {r[0]: r[1:] for r in old_rows}
    header, rows = read_csv(CSV_PATH)
    index = {r[0]: r for r in rows}
    filled = 0

    def fill(key, src):
        nonlocal filled
        if not src:
            return
        hit = old_map.get(src)
        row = index.get(key)
        if not hit or row is None or len(hit) < 4:
            return
        if hit[2] and hit[2] != row[1]:
            row[2], row[3], row[4] = hit[1], hit[2], hit[3]
            filled += 1

    old_chars = json.load(io.open(CHARS_BAK, encoding="utf-8-sig"))
    for c in old_chars.get("characters", []):
        cid = c["id"]
        for field in ("name", "form", "personality", "quote"):
            fill("char.%s.%s" % (cid, field), c.get(field, ""))

    old_ends = json.load(io.open(ENDINGS_BAK, encoding="utf-8-sig"))
    for eid, e in old_ends.items():
        if not isinstance(e, dict) or "title" not in e:
            continue
        fill("ending.%s.title" % eid, e["title"])
        fill("ending.%s.sub" % eid, e.get("sub", ""))
        for i, line in enumerate(e.get("lines", [])):
            fill("ending.%s.line%d" % (eid, i), line)

    with io.open(CSV_PATH, "w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, quoting=csv.QUOTE_ALL, lineterminator="\r\n")
        writer.writerow(header)
        writer.writerows(rows)

    print("接回旧翻译 %d 条" % filled)
    print("strings.csv 现在 %d 行" % len(rows))


if __name__ == "__main__":
    main()
