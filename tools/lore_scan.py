"""剧情雷点扫描 v3 —— 文案已经全走 key，正文在 strings.csv 的 zh_CN 列。

原则（用户 11-08 定稿）：
1. 所有女主对玩家都是正面情感，不出现背叛、NTR、第三者
2. 吃醋允许且鼓励，但方式不能越界（示好可以、贬损别人不行）
3. 不出现死亡、血腥、虐待
4. 亲密分表/里：公开场景点到为止，私下场景才放开
"""

import csv
import io
import re

CSV_PATH = r"E:\godot_workplace\测试\data\i18n\strings.csv"

HARD = [
    ("背叛/第三者", r"背叛|出轨|第三者|偷情|抢走|绿帽|ntr|和别人"),
    ("死亡/血腥", r"死|尸|杀|血|断了气|埋葬"),
    ("越界吃醋", r"贱|蠢货|废物|滚开|讨厌你|恶心|不许你|别碰她|离她远点"),
    ("离别/悲剧", r"再也不|永别|回不来了"),
    ("露骨", r"全裸|下体|插入|高潮|舔"),
]

SOFT = [("吃醋/争宠", r"吃醋|抢|不服气|瞪|哼|凭什么|先来|我也要|轮不到")]


def main() -> None:
    rows = []
    with io.open(CSV_PATH, encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            if not row.get("keys", "").startswith("story."):
                continue
            rows.append((row["keys"], row.get("zh_CN", "")))

    hard = {name: [] for name, _ in HARD}
    soft = {name: [] for name, _ in SOFT}
    for key, text in rows:
        for name, pattern in HARD:
            if re.search(pattern, text):
                hard[name].append((key, text))
        for name, pattern in SOFT:
            if re.search(pattern, text):
                soft[name].append((key, text))

    print(f"=== 扫了 {len(rows)} 条剧情台词 ===\n")
    print("【硬禁】")
    for name, _ in HARD:
        hit = hard[name]
        print(f"  {name}: {len(hit)}")
        for key, text in hit[:5]:
            print(f"    {key}  {text}")
    print("\n【软查：吃醋句，人工确认有没有越界】")
    for name, _ in SOFT:
        hit = soft[name]
        print(f"  {name}: {len(hit)}")
        for key, text in hit[:14]:
            print(f"    {key}  {text}")


if __name__ == "__main__":
    main()
