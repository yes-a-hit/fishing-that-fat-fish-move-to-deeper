"""把 characters.json / endings.json 里硬编码的中文也搬进 strings.csv。

key 约定：
  char.<id>.name / .form / .personality / .quote
  ending.<id>.title / .sub / .line<N>
"""

import csv
import io
import json
import os

ROOT = r"E:\godot_workplace\测试"
CSV_PATH = os.path.join(ROOT, "data", "i18n", "strings.csv")
CHARS = os.path.join(ROOT, "data", "characters.json")
ENDINGS = os.path.join(ROOT, "data", "endings.json")


def read_csv():
    with io.open(CSV_PATH, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh))
    return rows[0], [r for r in rows[1:] if r and r[0].strip()]


def add(rows, known, added, key, text):
    if not text or text.startswith(("char.", "ending.")):
        return text
    if key not in known:
        known.add(key)
        rows.append([key, text, text, text, text])
        added.append(key)
    return key


def main():
    header, rows = read_csv()
    known = {r[0] for r in rows}
    added = []

    chars = json.load(io.open(CHARS, encoding="utf-8-sig"))
    for c in chars.get("characters", []):
        cid = c["id"]
        for field in ("name", "form", "personality", "quote"):
            if field in c:
                c[field] = add(rows, known, added, "char.%s.%s" % (cid, field), c[field])
    io.open(CHARS, "w", encoding="utf-8").write(
        json.dumps(chars, ensure_ascii=False, indent=2) + "\n")

    ends = json.load(io.open(ENDINGS, encoding="utf-8-sig"))
    for eid, e in ends.items():
        if not isinstance(e, dict) or "title" not in e:
            continue
        e["title"] = add(rows, known, added, "ending.%s.title" % eid, e["title"])
        if "sub" in e:
            e["sub"] = add(rows, known, added, "ending.%s.sub" % eid, e["sub"])
        lines = e.get("lines")
        if isinstance(lines, list):
            for i, line in enumerate(lines):
                lines[i] = add(rows, known, added, "ending.%s.line%d" % (eid, i), line)
    io.open(ENDINGS, "w", encoding="utf-8").write(
        json.dumps(ends, ensure_ascii=False, indent=2) + "\n")

    with io.open(CSV_PATH, "w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, quoting=csv.QUOTE_ALL, lineterminator="\r\n")
        writer.writerow(header)
        writer.writerows(rows)

    print("新增 %d 条" % len(added))
    print("strings.csv 现在 %d 行" % len(rows))


if __name__ == "__main__":
    main()
