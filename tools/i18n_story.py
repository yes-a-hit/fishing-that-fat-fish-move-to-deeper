"""把 story.json 里硬编码的中文台词搬进 strings.csv，json 只留 key。

约定：
  台词  story.<chapter>.p<三位序号>
  说话人 speaker.<slug>

迁移后 ConfigLoader.load_story() 会走 _loc() → TranslationServer.translate()，
zh_TW / en / ja 暂时先填中文（等同于「还没翻」），后续人工替换即可。
"""

import csv
import io
import json
import os

ROOT = r"E:\godot_workplace\测试"
STORY = os.path.join(ROOT, "data", "story.json")
CSV_PATH = os.path.join(ROOT, "data", "i18n", "strings.csv")

SPEAKERS = {
    "": "",
    "你": "speaker.you",
    "大肥鱼": "speaker.big",
    "中肥鱼": "speaker.mid",
    "小肥鱼": "speaker.small",
    "豆包": "speaker.doubao",
    "Kimi": "speaker.kimi",
    "GLM": "speaker.glm",
    "千问": "speaker.qwen",
    "Ollama": "speaker.ollama",
    "Mistral": "speaker.mistral",
    "Grok": "speaker.grok",
    "Gemini": "speaker.gemini",
    "文心": "speaker.wenxin",
    "ChatGPT": "speaker.chatgpt",
    "克劳德": "speaker.claude",
    "Claude": "speaker.claude",
    "商人": "speaker.merchant",
}


def load_rows(path):
    with io.open(path, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh))
    header = rows[0]
    return header, [r for r in rows[1:] if r and r[0].strip()]


def main():
    data = json.load(io.open(STORY, encoding="utf-8-sig"))
    header, rows = load_rows(CSV_PATH)
    known = {r[0] for r in rows}
    added = []
    unknown_speakers = set()

    for chapter, entry in data.items():
        if not isinstance(entry, dict):
            continue
        pages = entry.get("pages")
        if not isinstance(pages, list):
            continue
        for idx, page in enumerate(pages):
            who = page.get("who", "")
            if who and not who.startswith("speaker."):
                if who in SPEAKERS:
                    page["who"] = SPEAKERS[who]
                else:
                    unknown_speakers.add(who)

            text = page.get("text", "")
            if not text or text.startswith("story."):
                continue
            key = "story.%s.p%03d" % (chapter, idx)
            page["text"] = key
            if key in known:
                continue
            known.add(key)
            added.append([key, text, text, text, text])

    rows.extend(added)

    # 说话人也要有词条，否则 json 里只剩 "speaker.kimi" 这种裸 key
    for zh, key in SPEAKERS.items():
        if not key or key in known:
            continue
        known.add(key)
        rows.append([key, zh, zh, zh, zh])
        added.append([key, zh, zh, zh, zh])
    with io.open(CSV_PATH, "w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, quoting=csv.QUOTE_ALL, lineterminator="\r\n")
        writer.writerow(header)
        writer.writerows(rows)

    json.dump(data, io.open(STORY, "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)
    with io.open(STORY, "a", encoding="utf-8") as fh:
        fh.write("\n")

    print("新增 %d 条台词" % len(added))
    print("strings.csv 现在 %d 行" % len(rows))
    if unknown_speakers:
        print("未登记的说话人：", sorted(unknown_speakers))


if __name__ == "__main__":
    main()
