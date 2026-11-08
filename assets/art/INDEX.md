# 美术资产目录（RAG 检索用）

一句话：**先查 `manifest.json`，再读具体那张图**。别再 `glob assets/**` 了。

- 机器索引：`assets/art/manifest.json`（285 条，每条含 `path` / `group` / `chapter` / `character` / `form` / `bytes`）
- 重建索引：`python tools/art_reorg.py`（顺带处理新丢进来的散图）

## 目录树

```
assets/art/
  cast/                      立绘（人。竖 768×1344 或方 768²）
    ch1/                     第一期
      small/ mid/ big/       三条肥鱼
        default.webp         图鉴 / 对话用的那张
        chibi.webp           二头身
      doubao/                default seed kick escape
      claude/                adult chibi sad hold escape fake_1 fake_2 fake_3
    ch2/                     第二期（八个模型 + 玩家）
      kimi/                  daily  k28  pro  sleep  chibi  full
      glm/ qwen/ ollama/ mistral/ grok/ gemini/ minimax/ chatgpt/ abagpt/ wenxin/
      user/                  full chibi
  cg/                        横构图 1216×688
    ch1/opening/             meal denial heart bank dive summon rod deepseek_escape …
    ch1/ending/              feast feast_after win hungry claude doubao true
    ch2/                     深海结局、码头
      boat/ water/
  anim/                      上鱼动画帧 768²
    small/ mid/ big/         01_pull 02_bowl 03_hop …（序号_动作）
  props/ch2/                 道具、水底杂物
    items/                   phone keyboard gpu usb bottle carrot wool film …
  ui/                        HUD 图标、模型徽章 badge_*
  meta/                      logo、app icon、彩蛋、coming_soon
```

## 命名规则

- **角色**：`cast/{章节}/{角色 id}/{形态}.webp`。角色 id 全小写，跟 `data/characters.json` 的 `id` 对齐。
- **形态**：`default`（图鉴那张）、`chibi`（二头身）、`full`（全身立绘）、以及专属名（`k28`/`pro`/`sleep`/`sealed`/`rococo`…）。
  多形态登记在 `data/phase2/cast_forms.json`，图鉴按表出形态条。
- **CG**：`cg/{章节}/{用途}/{场景}.webp`。用途只有 `opening` / `ending` / `boat` / `water` 四种。
- **动画**：`anim/{角色}/{两位序号}_{动作}.webp`，帧序由文件名决定，代码按目录扫。
- **道具/图标**：扁平放，不加序号、不加角色前缀。

## 查图流程（省 token 的关键）

1. 想知道「有哪些」→ 读 `assets/art/manifest.json`，按 `group` / `chapter` / `character` 过滤，**不要**列目录。
2. 想改某张 → 路径直接由规则拼出来：`res://assets/art/cast/ch2/kimi/pro.webp`。
3. 想确认某角色有几种形态 → 查 `data/phase2/cast_forms.json`，那里才是权威（图比它多不代表能用）。
4. 真要「看」图 → 才 `read_image`，一次一张，先想清楚是哪张再看。

## 新增资产时

- 丢进对应目录，文件名遵守上面的规则；跑一次 `python tools/art_reorg.py` 让它进索引。
- 只有 `assets/art/` 下的图会被打包；`素材/` 是草稿区（候选、raw、未定稿），不进 pck。
- 一个角色多套立绘，**先加 `cast_forms.json`**，再放图，否则图鉴看不见。
