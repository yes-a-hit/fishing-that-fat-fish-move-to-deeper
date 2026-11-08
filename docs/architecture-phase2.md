# 二期架构（`phase2`）—— 分层、依赖规则与增量边界

> 目的：把二期做成**一个能独立测试、独立删除**的子系统。
> 一期（`scripts/core`、`scripts/ui`）在这份文档里叫「一期」，二期（`scripts/phase2/**`）叫「二期」。
> 三条铁律：**core 不碰节点**、**两关只认档案不认彼此**、**一期只允许三处加法**。

---

## 1. 目录结构（唯一合法的形状）

```
测试/
├── scripts/
│   ├── core/                  ← 一期逻辑（不动）
│   ├── ui/                    ← 一期表现（只改 menu_root.gd 一处）
│   └── phase2/
│       ├── core/              ← 二期逻辑：纯 RefCounted，无节点、无场景树
│       │   ├── progress.gd          Progress  唯一写 user://progress.json 的地方
│       │   ├── ledger.gd            Ledger    钱 / 库存 / 已见计数
│       │   ├── dive_seed.gd         DiveSeed  种子 → 参数（纯函数）
│       │   ├── dive_generator.gd    DiveGenerator  参数 → 一局内容
│       │   ├── dive_session.gd      DiveSession    规则状态机
│       │   ├── dive_score.gd        DiveScore      计分
│       │   └── shop.gd              Shop      升级表 / 道具表 / 槽位
│       └── ui/                ← 二期表现：可以 import 一期共用件
│           ├── dive_root.gd         DiveRoot   唯一装配点
│           ├── dive_view.gd         DiveView   水下画面
│           ├── dive_hud.gd          DiveHud    HUD
│           ├── boat_screen.gd       BoatScreen 船（种子）
│           ├── shop_screen.gd       ShopScreen 商人
│           └── assistant_picker.gd  AssistantPicker 助手
├── scenes/
│   └── dive.tscn              ← 二期唯一场景，只挂 DiveRoot
├── data/
│   └── phase2/
│       ├── dive.json          ← 下潜数值（三档）、mimic、goal
│       ├── shop.json          ← 升级价、道具价、槽位规则
│       ├── seeds_banned.json  ← 想排除的种子（可空）
│       └── lore.json          ← 背景三条 _note（不产生玩法）
└── assets/
    └── phase2/
        ├── cast/              ← 立绘 896×1344、chibi 768²
        ├── dive/              ← 水层背景 1216×688
        ├── props/             ← 杂物 / 道具图标 128²
        ├── ui/                ← HUD 图标 96²
        ├── cg/                ← 结局 CG 1216×688
        └── boat/              ← 船与摊位背景
```

- 新增文件必须落在上表里；表外的位置一律先改这份文档，再写代码。
- 二期**不修改** `scripts/core/**`、不修改 `project.godot` 的 autoload 列表。

---

## 2. 依赖规则（可用 grep 卡住的那种）

### 2.1 允许的边

```
phase2/ui/*  ──▶ phase2/core/*        ✅
phase2/ui/*  ──▶ scripts/ui/{ui_kit,palette,lake_backdrop,pause_layer,story_director,scene_feedback}.gd   ✅
phase2/ui/*  ──▶ scripts/core/config_loader.gd   ✅（只读数据）
phase2/core/* ──▶ scripts/core/config_loader.gd  ✅
phase2/core/* ──▶ phase2/core/*                  ✅
```

### 2.2 禁止的边

```
phase2/core/*  ──✗──▶ phase2/ui/*            反了：逻辑不能认识界面
phase2/core/*  ──✗──▶ Node / Control / SceneTree / autoload
phase2/core/*  ──✗──▶ 一期 fishing_session / game_root / landing_view
phase2/ui/*    ──✗──▶ 一期 game_root / fishing_session（只许读 Progress）
scripts/**（一期）──✗──▶ phase2/ui/*        一期不认识二期界面
```

- **一期只允许三处加法**：`scripts/ui/menu_root.gd` 加一张「出 海」卡片、`data/phase2/dive.json` 新文件、`scripts/core/config_loader.gd` 加一个 `load_phase2()`（可选，不加也行——二期自己读 JSON 也可以）。除此之外**一行都不改**。
- 跨关只走两个数据对象：`Progress`（存档）与 `Ledger`（钱/库存）。不传节点、不传信号、不 import 对方的类。

### 2.3 自查命令（每次提交前跑）

```powershell
# core 里出现 ui / Node / autoload，就该报错
Select-String -Path scripts\phase2\core\*.gd -Pattern 'phase2/ui|extends Node|extends Control|get_tree\(\)|Audio\.|Gallery\.'
# 一期有没有偷偷引用二期界面
Select-String -Path scripts\core\*.gd,scripts\ui\*.gd -Pattern 'phase2/ui'
```

---

## 3. 命名与写法约定

| 约定 | 说明 |
|---|---|
| 类名前缀 | 二期逻辑一律 `Dive*` / `Shop` / `Ledger` / `Progress`；界面一律 `*Screen` / `*View` / `*Hud` / `*Picker` / `*Root` |
| 文件 | 与类名同名的蛇形：`DiveSeed` ↔ `dive_seed.gd` |
| 类类型 | `core` 全部 `extends RefCounted` + `class_name`；**不用 static 单例**，靠注入 |
| 数值 | 全部进 `data/phase2/*.json`；代码里只允许出现**下限/上限/默认值**三类常量 |
| 文案 | 全部进 `data/i18n/strings.csv`（四语），代码里不写中文 |
| 随机 | 只用 `DiveSeed` 派生的 `RandomNumberGenerator`；**禁止 `randi()` 裸调用**，否则种子失效 |
| 文件 IO | 只有 `progress.gd` 碰 `user://`；其它文件一律收 Dictionary |

---

## 4. 每个文件干什么（落地顺序 L1→L8 见 `plan-phase2-link.md` §12）

### 4.1 core

| 文件 | 职责 | 关键接口 |
|---|---|---|
| `progress.gd` | 读/写 `user://progress.json`，迁移旧档，事务式保存（写临时文件再改名） | `load_game(path)`, `save()`, `mark_cleared(ch)`, `is_unlocked(ch)`, `add_affinity(id,n)`, `record_seed(seed, dict)` |
| `ledger.gd` | 钱、库存、`trinkets_seen`；所有扣款/入账的唯一入口，负数直接拒绝 | `add_money(n)`, `spend(n)->bool`, `add_item(id,count)`, `sell(id)->int` |
| `dive_seed.gd` | 校验 8 位 `[0-9A-F]`、派生 PRNG、产出参数表（水深/障碍密度/杂物权重/AI 表） | `static derive(text)->Dictionary`, `static is_valid(text)->bool`, `static random_text(rng)->String` |
| `dive_generator.gd` | 用参数生成一局：水层段、障碍序列、杂物点位、AI 出现位；同一 seed 同结果 | `build(params)->Dictionary` |
| `dive_session.gd` | 状态机 `BOAT→DESCEND→HOOK→REEL→RESULT`；只管规则，不碰画面 | `start()`, `tick(dt)`, `hook()`, `reel()`, `summary()` |
| `dive_score.gd` | 计分：深度、杂物、AI、残影、连击；难度系数 | `add(kind, value)`, `finalize(summary, difficulty)` |
| `shop.gd` | 升级表（4 级）、道具表、槽位 = 总等级；报价与购买校验 | `upgrade_price(item, level)`, `buy_upgrade(id)->bool`, `slots(levels)->int` |

### 4.2 ui

| 文件 | 职责 | 依赖 |
|---|---|---|
| `dive_root.gd` | 唯一装配点：建 BoatScreen / DiveView / DiveHud / ShopScreen，接 `Progress`、`Ledger`；不写业务规则 | 上面全部 core + UIKit/Palette |
| `dive_view.gd` | 水层滚动、障碍与杂物绘制、残影半透明；`_draw()` 或贴图精灵 | Palette/UIKit |
| `dive_hud.gd` | 线长刻度（当前深度 / 线上限）、分数、钩容量（已带/上限）、灯状态、道具槽（槽位数读 `Shop.slots`） | UIKit/Palette |
| `boat_screen.gd` | 种子输入框（8 位）、换种子、历史列表（收集率/残影） | Progress |
| `shop_screen.gd` | 三列：升级 / 道具 / 彩蛋回收；买不起时显示「记在账上」 | Shop/Ledger |
| `assistant_picker.gd` | 只列 `progress.characters` 里有的；Claude 固定占一格 | Progress |

---

## 5. 隔离手段（保证「不影响已有内容」）

1. **新场景**：`dive.tscn` 独立，一期任何场景不实例化它；菜单只做 `change_scene_to_file`。
2. **新档案**：`progress.json` 与一期的 `settings.json` / `gallery.json` / `record.json` **完全分开**；二期的钱与库存只存在 progress 里。
3. **新数值**：二期所有数值在 `data/phase2/*.json`，一期的 `tuning.json` 不动。升级对一期的影响走 `GameTuning.apply_upgrades(progress)`——**一期只多一个可选入参**，缺省时行为与现在逐字节一致。
4. **新资产**：全部放 `assets/phase2/`，一期的 `assets/cast`、`assets/dive` 保持原样（二期做起来后可以再决定是否合并，现在不动）。
5. **可删除性**：删掉 `scripts/phase2/`、`scenes/dive.tscn`、`data/phase2/`、`assets/phase2/`，再把 `menu_root.gd` 那张卡片去掉，一期应当**能直接跑、自测数不变**。这条是每次提交的自检项。

---

## 6. 测试边界

| 层 | 能不能单测 | 怎么写 |
|---|---|---|
| `phase2/core/*` | ✅ 直接 `new()` | 纯函数优先：`DiveSeed.derive` 同种子同结果、`Shop.slots` 取最低级、`Ledger.spend` 拒负数 |
| `phase2/ui/*` | ⚠️ 只能 `load(...).new()` | 和一期一样：`--script` 模式下不写静态类型（autoload 不在编译期作用域） |
| 一期回归 | ✅ | 现有 `tests/selftest.gd` 全绿，且**数字不变**（1277 基线） |

- 二期自测单独一个文件：`tests/selftest_phase2.gd`，与一期互不 import。
- 每次二期提交必须同时跑：`selftest.gd`（回归）+ `selftest_phase2.gd`（新码）。

---

## 7. 美术资产清单

### 7.1 已有（`assets/phase2/` 待复制，原件在 `assets/cast`、`assets/dive`）

| 类 | 数量 | 规格 | 状态 |
|---|---|---|---|
| 角色立绘 | 9 + 文心双态 | 768×1344 | ✅ 已出 |
| 二头身 chibi | 9 + 文心阿巴 | 768² | ✅ 已出 |
| 水层背景 | 4（浅/中/深/西雅图） | 1216×688 | ✅ 已出 |
| 杂物图标 | 13 | 128² | ✅ 已出 |

### 7.2 缺口（本轮要补）

| 类 | 清单 | 规格 | 来源 |
|---|---|---|---|
| 道具图标 | `sonar` / `fast_fall` / `oxygen` / `line_guard` / `magnet` / `seed_slot` | 128² | 自跑（anima，平涂图标风） |
| HUD 图标 | `oxygen` / `depth` / `money` | 96² | 自跑 |
| 结局 CG | `dive_true` / `dive_home` / `dive_gold` | 1216×688 | 自跑 |
| 船与摊位 | `boat_deck` / `merchant_stall` | 1216×688 | 自跑 |

### 7.3 免费可商用素材（备用，不下载）

- 音效：`freesound.org`（CC0 筛选）、`opengameart.org`（CC0）。
- UI 装饰：`kenney.nl`（CC0，整套 UI 包）。
- 使用前提：进 `CREDITS.md` 登记来源与许可；**能自跑的图不引外链**，避免许可不一致。

---

## 8. 提交前清单

1. `flutter`/`godot` 不必——本工程只跑 Godot：
   `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path "E:\godot_workplace\测试" --script "res://tests/selftest.gd"` → 数字不变
2. `--script "res://tests/selftest_phase2.gd"` → 全绿
3. `--import`（有新资产时）
4. §2.3 的两条 grep 无命中
5. 删二期目录能跑（手动验一次即可，不必每次）

## 9. 第二关的界面结构

一条线走完，不回头：**菜单章节二 → 船头 → 下潜 → 上钩 → 结算 → 回船头**。

### 9.1 场景与状态

\scenes/dive.tscn          唯一的二期场景，根节点 DiveRoot
└─ DiveRoot (Control)     ui/dive_root.gd，只管状态机与装配
   ├─ BoatScreen          ui/boat_screen.gd    船头（默认状态）
   ├─ DiveView            ui/dive_view.gd      水下层
   ├─ DiveHud             ui/dive_hud.gd       下潜时叠在 DiveView 上
   └─ ResultLayer         ui/dive_result.gd    结算（待建）
\
状态机三态：\BOAT\ ↔ \DIVE\ → \RESULT\ → 回 \BOAT\。切换只走 \DiveRoot._set_state()\，
和一期一样不在各层自己切。

### 9.2 船头（\BoatScreen\）

画面是**船头视角**：玩家的背影在画面下方三分之一，Claude 在船尾掌舵，海面与远处的水层浮标。

- 左下：玩家背影 \ssets/phase2/cast/user_full.webp\（三/四分之三侧，深蓝 T 恤 + 卡其短裤 + 手持钓竿）
- 右下：Claude 立绘（**待补** \ssets/phase2/cast/claude_full.webp\，指舵轮的手、外套被海风吹起）
- 中间：种子输入行 —— Claude 随机报一串 8 位十六进制（如 F7A1C09\），玩家也可以手输
- 下方：三个按钮「用这个坐标」「换一个」「历史坐标」
- 「历史坐标」展开成列表：每行 \种子　收集率　最深　⚠ 有残影
### 9.3 下潜（\DiveView\ + \DiveHud\）

\DiveView\ 只画世界：水层背景（\ssets/phase2/dive/{shallow,mid,deep,seattle}.webp\ 四张按深度切）、
漂浮杂物、可钓的 AI 娘剪影。它不认识 Progress，也不做判定。

\DiveHud\ 是纯显示：左上「线长刻度」（当前深度 / 线上限），中上分数，右上钩容量与道具槽，
底下 600m 以下出现「开灯」提示。所有数值由 \DiveSession\ 推，HUD 不自己算。

### 9.4 结算（\ResultLayer\，待建）

复用一期结算页的排版语言（大号分数 + 统计行 + 三个按钮），但**不 import \ending_overlay.gd\** ——
两关的结算字段不一样（一关是「完美/失手」，二关是「深度/杂物/AI」）。

### 9.5 玩家自己的形象

| 文件 | 用途 | 说明 |
|---|---|---|
| \cast/user_full.webp\ | 船头背影 | 768×1344，三/四分之三侧背影，深蓝 T 恤 + 卡其短裤，和一期 CG 里的「你」一致 |
| \cast/user_chibi.webp\ | 对话气泡 / 图鉴 | 768²，二头身，深蓝 T 恤无印花，短发 |

两条一致性约束：**深蓝 T 恤 + 卡其短裤 + 黑短发**，别加外套、别给正脸特写（玩家永远是「你」）。

## 10. 图鉴的多形态

一个角色可以有好几套立绘 / 差分。数据只有一份，写在 `data/phase2/cast_forms.json`：

```
{ kimi: { name: Kimi, default: daily,
    forms: [ { id: daily, name: 日常, art: res://assets/art/cast/ch2/kimi/daily.webp,
                 unlock: always, note: ... } ] } }
```

- `ConfigLoader.load_cast_forms()` 读表并翻好 `name` / `note`；UI 不碰文件。
- `ConfigLoader.form_unlocked(form, progress)` 判解锁，语法 `always` / `affinity:N` / `item:ID` / `cleared:CH`；
  没有二期存档对象时退一步直接读 `user://phase2.json`，读不到当 0（没出海过就看不见私服）。
- `ConfigLoader.phase2_character_caught(id)` 给图鉴判「这个二期角色露不露面」，
  `data/characters.json` 里写 `unlocked_by: phase2:kimi`。
- 图鉴详情页 `gallery_root._form_strip()` 把未锁的形态排成一行按钮，点击重开预览换图；
  当前形态高亮。锁定形态直接不出现，不给灰按钮 —— 差分本身就是奖励。



## 11. 当前实现状态（2026-11-07）

### 11.1 已经能跑

| 层 | 文件 | 状态 |
|---|---|---|
| core | scripts/phase2/core/progress.gd | 存档全量（章节/角色/好感/种子/升级/道具/杂物/景色/钱） |
| core | scripts/phase2/core/ledger.gd | 花钱不足返回 false，绝不负数 |
| core | scripts/phase2/core/dive_tuning.gd | 等级 0..4 → max_depth / capacity / sink_scale 换算 |
| core | scripts/phase2/core/dive_session.gd | 下沉、刷鱼、上钩、撞杂物、收线 |
| core | scripts/phase2/core/scenery_deck.gd | 景色加权抽取 + 不连抽 |
| ui | scripts/phase2/ui/dive_root.gd | 三态机 BOAT ⇄ DIVE → RESULT |
| ui | scripts/phase2/ui/boat_screen.gd | 甲板 CG + user 背影 + Claude 掌舵 + 种子输入 + 明信片 |
| ui | scripts/phase2/ui/dive_view.gd | 水层循环滚动、钩子、鱼影、600m 变暗 |
| ui | scripts/phase2/ui/dive_hud.gd | 深度 / 钩容量 / 分数 / 操作提示 |

### 11.2 还没做

- 商店（_on_shop() 只弹一句话）
- 杂物实体（DiveSession.bump() 写好了，但还没有触发源）
- 明暗分界的光圈渲染（现在只是整屏压暗）
- 上钩时的演出（现在只有一行 toast）
- 结算数值与「大洋彼岸的景色」联动

### 11.3 数值怎么进代码

**不要**用 upgrade_level() 当数值用。它是 0..4 的等级，真实数值在
data/phase2/shop.json 的 max_depth / capacity / sink_scale 数组里，
一律走 DiveTuning.max_depth(shop, level) 这类函数换算。


### 11.4 穿透地心（1200m）

钩子下到 1200m 之后不再往下钻，而是**从地球另一头的海面冒出来**——
这是「北京穿过地心到西雅图」的古早梗，也是「大洋彼岸的景色」唯一的获取方式。

实现：

- DiveSession.SECRET_DEPTH = 1200，到点只 emit 一次 secret_seen
- DiveView._set_far_side(true)：贴图 lip_v、只留一张、换成
  seattle_statue / seattle_protest / seattle_trio_fall 里随机一张
- 钩子与鱼影的 y 全部镜像
- DiveRoot._on_secret() 随机钩上一处景色，进 progress.scenery

**船头不放任何「海的那边」的明信片**。玩家只能靠一次次穿透，自己拼出对面发生了什么。


## 12. UI 规范：能列表就别堆卡片

用户定的调子：**UI 尽可能按 icon list 来**。

### 12.1 一级操作走 icon list

港口、船头这些"舞台"上，操作不该是一列大白按钮，而是一行/一列
**图标 + 两个字的短词**：

```
[⚓ 下潜]  [🏪 商人]  [🎣 训练]  [📖 图鉴]
```

- 图标 32~48px，词不超过 3 个字
- 横向排一行，居中，间距一致
- 鼠标悬停才展开一句说明，不常驻

### 12.2 状态用图标，不用句子

| 现在 | 改成 |
|---|---|
| `白饭 20 碗` | 🍚 `2 / 3` |
| `钩 0/1 件` | 🪝 `0/1` |
| `得分 0` | ⭐ `0` |
| 好感度数字 | ❤ `72` |

数字永远比句子省地方，也更好扫。

### 12.3 卡片只留给两处

1. **详情**：点开某个东西之后的弹层（商店、结算、图鉴预览）
2. **对话**：文本框

舞台上不放卡片。舞台是给人看的，卡片是给人读的。

### 12.4 已有资产可复用

`assets/art/props/ch2/items/` 里那套道具图标（line / hook / lamp / depth / money）
就是现成的 icon list 素材，直接拿来做 HUD 和快捷键。

## 13. 世界层：关卡是地点，不是列表项

### 13.1 为什么不列关卡

之前的菜单是「第一章」「第二章」两行按钮。这不是关卡结构，是**目录结构**——
玩家看到的是功能清单，不是世界。第二章的卖点是沉浸感，第一屏就先破功了。

现在：

```
menu.tscn          开 始 / 图 鉴 / 设 置 / 关于
   └─ world.tscn   一张世界图，左右两个地点
        ├─ 左：河  → main.tscn（第一章）
        └─ 右：港  → scenes/dive.tscn（第二章）
```

### 13.2 世界图

`assets/art/cg/world/world_split.webp`（1216×688）：
左半是屋里那顿白饭（暖），右半是雨夜码头（冷），中间一条 80px 的渐变压暗缝合。
生成脚本 `_make_world_bg.py`（左右各取一张现有 CG，等比缩放后半宽拼接）。

两个热区各是一个 `VBoxContainer`（大字地名 + 一行小字），底下压一个 `flat Button`：

| 位置 | 大字 | 小字 | 解锁条件 |
|---|---|---|---|
| 0.25 / 0.60 | 河 | 第一 章 · 一碗白饭 | 恒开 |
| 0.75 / 0.60 | 港 | 第二 章 · 深海 / 先回河边，把饭吃完 | `SaveSchema.chapter1_cleared()` |

未解锁时：大字用 `INK_FAINT`、按钮 `disabled`，玩家点到会看到「先回河边」，不会一脸问号。

### 13.3 判定不该散在界面里

`SaveSchema` 是唯一的判据层（见 `docs/plans/2026-11-08-save-schema.md`）：

```gdscript
SaveSchema.chapter1_cleared(p2)   # 二期记过 ch1，或一期拿到任意结局
SaveSchema.opening_done()         # 开场播过没有
SaveSchema.any_ending_unlocked()
```

界面层只消费，不自己拼条件。私奔、白饭来咯、饿着——任何一条结局都算打完第一章。

### 13.4 以后往哪加

世界图是「地点」的容器，不是「关卡」的列表。加东西时先问「它在哪」：

- 商人、图鉴、训练 → 港口里已经有入口，不必回到世界图
- 房间（private 形态）→ 河边小屋，好感 90 才开门
- 新章节 → 世界图再加一个热区，别加一行按钮
