# 存档结构（2026-11-08）

## 为什么写这份

开场剧情会重复播、私奔结局不解锁第二章 —— 这两个 bug 都不是「某行写错了」，
而是**同一个状态散在好几处**：

- 「第一章打完了吗」：`Progress.chapter` 里有 `chapter_cleared("ch1")`，
  `Gallery.unlocked` 里有结局 key，菜单又自己写了一句「只认 feast」。
- 「这段剧情播过吗」：`story_done` 列表、`story_queue` 队列、`_story_playing` 内存标记，三处都在说话。

补 cache、加内存标记只会让第四个真相源出现。所以要收口。

## 现在的文件与职责

| 文件 | 谁写 | 装什么 |
|---|---|---|
| `user://gallery.json` | `Gallery` | `unlocked`（结局/图鉴 key）、`claude_stage`、`doubao_seen`、`story_queue`、`story_done` |
| `user://phase2.json` | `Progress` | 章节、角色、好感、种子、升级、道具、杂物、景色、钱、最高分 |
| `user://record.json` | `ScoreBoard` | 一期的最高分与连击 |
| `user://settings.json` | `GameSettings` | 难度、语言、音量 |
| `user://gpu_pref_v1.txt` | `GpuPreference` | 只是个标记文件 |

物理上仍然是四个文件，**不合并**——合并要写迁移，收益不如先把判据收干净。

## 判据层：`scripts/core/save_schema.gd`

```gdscript
SaveSchema.chapter1_cleared(p2)   # 二期记过 ch1 → true；否则一期拿到任意结局 → true
SaveSchema.any_ending_unlocked()  # endings.json 的 _order 里任意一个在 unlocked 里
SaveSchema.ending_ids()           # 从 data/endings.json._order 取，不写死
SaveSchema.opening_done()         # Gallery.story_done("opening")
SaveSchema.story_done(id)
```

**规矩：界面层不许自己拼「通关条件」**，一律问 SaveSchema。
加一个结局、改一条解锁规则，只动这一个文件。

## 这次的三个修法

### 1. 开场重复播

- `game_root.gd` 的 `_ready()` 在排队前先问 `SaveSchema.opening_done()`；
- `Gallery.queue_story()` 本来就幂等（`story_done` 或 `story_queue` 里有就返回 false）；
- **两道闸，但判据只有一份**（`story_done`）。

### 2. 私奔不加解锁

- `menu_root._chapter_one_done()` 从「只认 `Gallery.is_unlocked("feast")`」
  改成 `SaveSchema.chapter1_cleared(p2)`；
- 现在私奔（elopement）、白饭来咯、饿着 都算打完第一章，任何一条路都能开第二章。

### 3. 菜单不再罗列关卡

见 `docs/architecture-phase2.md §13`。

## 以后要合并成单文件的话

迁移路径（现在**不做**）：

1. `SaveSchema.migrate()`：读四个老文件 → 写 `user://save.json`（带 `schema: 2`）
2. 老文件改名成 `*.bak`，不回删
3. `Gallery` / `Progress` / `ScoreBoard` / `GameSettings` 的读写改成走 `SaveStore`（单文件、单入口）
4. `SaveSchema` 变成 `SaveStore` 的只读视图

判据层先做，是因为它不依赖物理文件长什么样 —— 先收语义，再收文件。
