# 当前状态快照（2026-11-08 14:40）

> 一页纸。换会话先读这份，别翻聊天记录。

## 一、两关是什么

| 关卡 | 玩法 | 状态 |
|---|---|---|
| 第一章 · 河 | 抛竿 → 等咬钩 → 圆环打体力 → 上鱼 | 已发布 v1.2.0 |
| 第二章 · 深海 | 港口 → 上船 → 下潜 → 收线 → 结算 | 骨架可玩，能跑通一趟 |

## 二、现在的流程（单向）

```
主菜单（galgame 式）
  ├─ 新游戏 ──────────────→ 岸边
  └─ 读取存档 ─┬─ 未通关第一章 → 岸边
                └─ 已通关第一章 → 港口

岸边 ─「开 始 钓 鱼」→ 打一局 → 结算 ─「回 岸 边」→ 岸边
   └─ 图鉴 / 主菜单

港口 ─「上 船」→ 船头（XY 坐标）→ 下潜 → 结算 → 船头
   ├─ 商人（NPC，开商店）/ 训练 / 回河边
   └─ 回河边 → 岸边
```

**单向**：岸边没有去港口的路；港口有回岸边的路。

## 三、已定的设计

- **没有氧气条**。深度上限=鱼线长度，携带数=钩容量，钓竿只加速度。
- **600m 是明暗线**：不开灯视野 160px，开灯 420px 但刷怪 ×1.3。
- **杂物即障碍**：撞上 −20 分、失控 0.45s、掉最上面一件。
- **1200m 穿透地心**：钩子从另一头冒出来，看到倒置的美国；四张景色先抽没见过的。
- **形态 = 好感度**：chibi / 萝莉 = 好感没到；pro = 够了才解锁；private = 只给主人看。
- **UI 按 icon list**：一级操作一行图标，状态用图标+数字，卡片只给弹层和对话。
- **纯爱后宫**：吃醋只能向男主示好，不许贬损别人；亲密分「表」与「里」。

## 四、存档判据（唯一真相）

`scripts/core/save_schema.gd`：

| 函数 | 回答什么 |
|---|---|
| `chapter1_cleared(p2)` | 第一章通没通关（二期记过 or 任意结局） |
| `opening_done()` | 开场剧情播没播过 |
| `story_done(id)` | 某段剧情播过没有 |
| `unlocked_ending_count()` | 解锁了几个结局 |
| `wipe_all(p2)` | 新游戏清档 |

**界面层不许自己拼通关条件**，一律问它。

## 五、美术

- 规范：`docs/art-style.md`（立绘 768×1344 透明底、chibi 768²、CG 1216×688、图标 128²）
- 审计：`python _audit_cast.py` → `docs/art-audit.md`（四条红线）
- 结构：`assets/art/{cast,cg,anim,props,ui,meta}`，索引 `manifest.json`（140 条）
- 立绘必须带 `_cut.webp`（透明底）+ 脚下软阴影

## 六、还剩的活

1. **港口站位**：中肥鱼还踩在水里、Claude 脚在栈道边缘外、名字标签太淡
2. **训练 UI**：抛竿按钮、白饭 `N / 3` 显示、耗尽回码头结算
3. **图鉴好感度条**：形态按钮按好感亮/灰，标门槛数字
4. **「回 房 间」**：挂 private 形态，好感 90 才出现
5. **313 条台词真翻译**（zh_TW/en/ja 现在是中文占位）
6. **世界图 `world.tscn`** 已停用，文件还在，可删

## 七、跑测试

```bash
godot --headless --path . --script res://tests/selftest.gd   # 1297 条
godot --path . --script res://tests/shot_menu.gd             # 18_menu
godot --path . --script res://tests/shot_shore.gd            # 17_shore
godot --path . --script res://tests/shot_boat.gd             # 19_harbor + 20_boat
godot --path . --script res://tests/shot_dive.gd             # 21_dive
godot --path . --script res://tests/shot_farside.gd          # 22_farside
```

**必须 grep `SCRIPT ERROR`**——不影响退出码，只看 `pass=` 会漏。
改完脚本跑 `python tools/rag_index.py`；改完美术跑 `audit_cast.py`。
