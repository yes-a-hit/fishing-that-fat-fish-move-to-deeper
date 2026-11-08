# 检索协议（怎么用这两张表省 token）

配套：`docs/plans/2026-11-07-rag.md`（为什么这么设计）、`tools/rag_index.py`（生成器）。

## 三张表

| 表 | 大小 | 查什么 |
|---|---|---|
| `docs/rag/MAP.md` | ~10 KB | 「这个功能大概在哪个文件」——一行一个文件，带摘要 |
| `docs/rag/project.json` | ~42 KB | 「这个函数在第几行」——`funcs[].name/line` |
| `assets/art/manifest.json` | ~40 KB | 「这张立绘在哪」——按 `character`/`form`/`group` 过滤 |

## 五条规则

1. **先 MAP 后代码**。找功能先 `grep docs/rag/MAP.md 关键词`，命中行就带路径，别直接全仓 grep。
2. **要行号查 json**。`project.json` 里 `files[].path == "scripts/ui/game_root.gd"` 的 `funcs` 有每个函数起始行。
3. **读局部**。`read(path, offset=行号-8, limit=60)`。整文件读完通常没必要 —— `game_root.gd` 727 行、`story.json` 853 行。
4. **美术不搜索**。路径按规则拼：`res://assets/art/cast/ch2/kimi/pro.webp`；形态权威在 `data/phase2/cast_forms.json`。
5. **数值不猜**。`MAP.md` 的 data 行已经列出顶层 key（如 `dive.json` 有 `light`/`hazard`），直接读那个文件。

## 什么时候允许全仓搜索

- MAP 里没有的关键词（新概念、报错原文、`SCRIPT ERROR` 文本）；
- grep 结果 >3 个文件 → **先补索引**（加摘要/加字段），再继续读；
- 找调用关系（`project.json` 不记 callers）——那是 `grep -n "函数名("` 的事。

## 维护

改了 `scripts/` / `data/` / `docs/` / `tests/` / `scenes/` 之后：

```
python tools/rag_index.py
```

几秒。提交前跑一次，别让索引落后于代码 —— 落后的索引比没有更糟。
