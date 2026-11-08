"""把旧 CSV 里「以中文原文为 key」的翻译，接到新的 story.* key 上。

迁移把台词换成了 key，但开场那 48 句原本就有真英译，不能丢。
做法：用 story.json.bak 还原旧原文 → 旧 CSV 里按原文查行 → 取其 zh_TW/en/ja 填到新行。
"""

import csv
import io
import json
import os

ROOT = r"E:\godot_workplace\测试"
STORY = os.path.join(ROOT, "data", "story.json")
STORY_BAK = os.path.join(ROOT, "data", "story.json.bak")
CSV_PATH = os.path.join(ROOT, "data", "i18n", "strings.csv")
CSV_BAK = os.path.join(ROOT, "data", "i18n", "strings.csv.bak")


def read_csv(path):
    with io.open(path, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh))
    return rows[0], rows[1:]


def main():
    old_story = json.load(io.open(STORY_BAK, encoding="utf-8-sig"))
    header, old_rows = read_csv(CSV_BAK)
    old_map = {r[0]: r[1:] for r in old_rows if r}

    _, new_rows = read_csv(CSV_PATH)
    index = {r[0]: r for r in new_rows}

    filled = 0
    for chapter, entry in old_story.items():
        if not isinstance(entry, dict):
            continue
        for idx, page in enumerate(entry.get("pages", [])):
            src = page.get("text", "")
            if not src:
                continue
            hit = old_map.get(src)
            if not hit:
                continue
            key = "story.%s.p%03d" % (chapter, idx)
            row = index.get(key)
            if row is None:
                continue
            # hit = [zh_CN, zh_TW, en, ja]
            if len(hit) >= 4 and hit[2] and hit[2] != row[1]:
                row[2], row[3], row[4] = hit[1], hit[2], hit[3]
                filled += 1

    with io.open(CSV_PATH, "w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, quoting=csv.QUOTE_ALL, lineterminator="\r\n")
        writer.writerow(header)
        writer.writerows(new_rows)

    print("接回旧翻译 %d 条" % filled)
    print("strings.csv 现在 %d 行" % len(new_rows))


if __name__ == "__main__":
    main()
