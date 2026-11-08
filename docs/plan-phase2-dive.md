# 二期规划：章节化 + 深水钓（`DIVE`）

> 状态：**只有规划，没有代码**。
> 两份东西一起定：**菜单重制成章节**（第一关 / 第二关，中间接剧情），以及**第二关的新玩法**（钩子下水躲障碍）。
> 一期的对局本身不改；改动集中在外壳（菜单、进度、剧情衔接）和新增的一关。

---

## 1. 结构：从「一个模式」变成「两关」

```
主菜单（章节目录）
├── 第一关  浅 湖  ← 现在的抛竿+圆环+上鱼，玩法不动
│     通关 ──> 过渡剧情（gate） ──> 解锁第二关
└── 第二关  深 水  ← 新玩法：钩子下沉躲障碍
       └─ 深水层解锁「其他 AI」角色
```

一期是「一局一局钓，钓完出结局」。二期把它变成**一章**：有一个明确的收束点，收束之后进剧情，剧情之后开新章。这样两个玩法不是并列的两个按钮，而是一条线。

## 2. 菜单重制

现在是「logo + 开始钓鱼 + 四个小按钮」。改成**章节目录**：

```
┌──────────────────────────────────────────┐
│              [ logo ]                     │
│              钓 肥 鱼                      │
│     有限的饵，喂饱这几条鱼                  │
│  ────────────────────────────────────    │
│  ┌────────────────┐  ┌────────────────┐  │
│  │ 第一关 · 浅 湖  │  │ 第二关 · 深 水  │  │
│  │ 抛竿、等咬钩、  │  │ 钩子下沉，躲水草│  │
│  │ 圆环搏斗        │  │ 礁石，够到鱼影  │  │
│  │                │  │                │  │
│  │ 最高 1860       │  │ 🔒 通关第一关后 │  │
│  │ ▶ 进入          │  │    解锁         │  │
│  └────────────────┘  └────────────────┘  │
│  ────────────────────────────────────    │
│  图 鉴   设 置   关 于   退 出            │
└──────────────────────────────────────────┘
```

卡片四态：

| 态 | 表现 | 交互 |
| --- | --- | --- |
| 未解锁 | 灰卡、锁图标、一行解锁条件 | 点击抖一下 + 提示音 |
| 已解锁 | 白卡、章节号、玩法一句话、最高分/最深 | 点击进入 |
| 已通关 | 右上角一个对勾，卡片描边加深 | 可重复进入 |
| 新增 | 第一次解锁时卡片有一次高亮呼吸（2 秒） | — |

其它细节：

- 章节卡用现在的 `UIKit.card` + `Palette`，不引入新视觉语言；
- 卡片宽度沿用 `menu_root` 现在的做法（`430`，窄屏取 `size.x - 64`），不新写一套自适应；
- 移动端两卡竖排（`< 640px` 宽时 `HBox` 换 `VBox`），不做横向滚动；
- 卡片上不写「新玩法」这种自夸词，只写「躲水草、礁石，够到鱼影」这类具体动作。

## 3. 解锁与进度

新增 `scripts/core/progress.gd`（`class_name Progress extends RefCounted`），一份存档 `user://progress.json`：

```json
{
  "version": 1,
  "chapters": {
    "ch1": {"cleared": true,  "cleared_count": 3, "best_score": 1860, "best_depth": 0},
    "ch2": {"cleared": false, "cleared_count": 0, "best_score": 0,    "best_depth": 0}
  },
  "characters": ["small", "mid", "big", "doubao", "claude"]
}
```

规则：

1. **Ch1 通关判定**：任一结局里带 `"gate": true` 的达成一次即可（默认只给 `feast`「齐鱼之福」标记，其余结局不给 —— 让「喂饱三条」成为主线门槛）。写进 `endings.json`，不硬编码在脚本里。
2. **Ch2 解锁**：`ch1.cleared == true` 时解锁；解锁瞬间播一次 `chapter_gate` 剧情（见下）。
3. **重复通关**：只累加 `cleared_count` 与最好成绩，不重复播 gate 剧情。
4. **旧存档迁移**：读不到 `progress.json` 时，若 `gallery.json` 里已有 `feast` 结局，直接视为 `ch1.cleared = true` —— 老玩家不该被锁在新菜单外面。

一期已有的 `record.json`（最高分）与 `gallery.json`（图鉴）都不动。

## 4. 剧情衔接

新增 `data/story.json` 的 `chapter_gate`，12–16 句，几秒钟能读完，作用是**给出下水的理由**，不是长篇。

骨架（示例，正式文案另写）：

```
大肥鱼  浅水这边，我们仨都上岸了。
中肥鱼  桶里挤不下了……
大肥鱼  往下有东西。比我们大的。
你      往下是多深？
大肥鱼  深到看不见底。绳子不够长，得用钩子。
你      ……钩子我倒是会甩。
小肥鱼  鲸！（第一个跳起来）
```

规则：

- 触发点：`ch1` 第一次 `cleared` 时，结算页关闭后播；播完把 `ch2` 标成解锁。
- 播放器复用 `StoryDirector`（已抽层），不新写；
- 文案全部进 `strings.csv`，四语；
- **不打断正在进行的一局**：结算页关掉之后才播，播完回主菜单（不自动开局）。

## 5. 解锁其他 AI

第二关的深水层是「其他 AI」的入口。现在的角色是 DeepSeek 三姐妹 + 豆包 + Claude，二期往里加**其他模型**，但走注册表，不写死分支。

### 5.1 角色注册表

`data/characters.json` 每条加三个可选字段（**现在一条都不加，等名字定了再一次性写入**；老条目缺这三个字段时按缺省值跑）：

```json
{
  "id": "<AI_ID>",
  "name": "<显示名>",
  "form": "……",
  "portrait": "res://assets/portrait_<AI_ID>.webp",
  "personality": "……",
  "quote": "……",
  "chapter": 2,
  "unlock": "fish:<AI_ID>",
  "voice": false
}
```

字段契约（写死在 `ConfigLoader.load_characters()` 里，缺省不报错）：

| 字段 | 类型 | 缺省 | 取值 |
| --- | --- | --- | --- |
| `chapter` | int | `1` | 1 / 2 / 3（未来），图鉴按它分页签 |
| `unlock` | String | `""` | `fish:<id>`（钓到该鱼）、`ending:<key>`（达成结局）、`never`（永不解锁，只作占位）、空＝不受限 |
| `voice` | bool | `false` | 有没有语音；`false` 时不在声音页列出 |

图鉴按 `chapter` 分页签：`第一关` / `第二关`，条目由注册表筛出来的，不再维护第二个清单。**新增一个角色只允许改 `characters.json` + 放一张立绘**，`gallery_root.gd` 里不许出现 `if id == "..."`。

### 5.2 三条位置先留着，名字主人定

二期想往深水层塞 3 条新 AI，名字与外形由主人定。规划只固定「位置」和「概率量级」，不固定名字：

| 位置 | id 占位 | 名字 | 深水出现概率 | 钓到后的解锁 |
| --- | --- | --- | --- | --- |
| 第一条 | `<AI_ID_1>` | 待定 | 约 5% | 角色页 + 一句专属台词 |
| 第二条 | `<AI_ID_2>` | 待定 | 约 4% | 同上 |
| 第三条 | `<AI_ID_3>` | 待定 | 约 3% | 同上 |

定名时要一起给的四样：`id`（小写 ASCII，用作文件名与解锁键）、显示名、一句话人设、外形方向（决定剪影轮廓）。给了之后改三处：`characters.json` 加条目、`fish.json` 加鱼（体力/伤害/张力按档位）、`data/dive.json` 的深水 `fish` 权重表加键。

- 三条只在 900 米以下出现，共用一套「深水影」立绘骨架，先做**剪影 + 高光**，等美术到位再换全身图；
- 钓到第一条新 AI 时播一段 4–6 句的短剧情（复用 `StoryDirector`），之后只进图鉴；
- 不新增结局（二期最多加一个「深水收工」小结局），避免结局从 9 个膨胀到十几个、每个都要 CG。

### 5.3 美术成本

三张立绘是二期唯一的新美术。规划里先按「深水剪影 → 半身 → 全身」三档推进，M4 之前只用剪影，不阻塞玩法验收。名字没定之前，剪影连轮廓都先不做——省得按错方向画三遍。

## 6. 第二关玩法（摘要，详细见下）

钩子入水后自动下沉，玩家左右移动、按住加速；躲水草/礁石/塑料瓶/水母，吃气泡回气，够到鱼影后拖着上浮。撞太多次或气尽脱钩。

**画面口径**：横版、钩子从上方垂下、鱼群在两侧游、左右卷轴——这套骨架照经典钓鱼小游戏；但**不做像素风**，立绘是 anime 的，背景也跟着 anime（三层水景 + 沉船 + 礁石），混风格会更乱。

**水里不全是真货**：有 `mimic` 装成贵的（Kimi / ChatGPT / Grok），靠近会抖，钓上来掉皮。设定见 [plan-phase2-cast.md](plan-phase2-cast.md) §9。

```
[准备] ──> [下沉] ──> [咬钩] ──> [收线] ──> [结算]
 选水域     躲障碍     鱼影靠近    拖着鱼上浮
 蓄力抛钩   攒深度     判定命中    障碍变密
```

操作：键鼠 `A/D` + 按住 `Space`；触屏拖动 + 按住屏幕下半。**只有一个动作加一个方向**，不引入第二个按钮。

### 数值（走 `GameTuning.SCALAR_FIELDS`，不许第二份白名单）

| 字段 | easy | normal | hard |
| --- | --- | --- | --- |
| `dive_sink_speed` | 90 | 130 | 170 |
| `dive_boost_speed` | 260 | 320 | 380 |
| `dive_rise_speed` | 200 | 240 | 280 |
| `dive_lateral_speed` | 260 | 300 | 320 |
| `dive_air_max` | 120 | 100 | 90 |
| `dive_air_drain` | 4 | 6 | 8 |
| `dive_hit_air_loss` | 12 | 18 | 24 |
| `dive_hit_depth_loss` | 40 | 60 | 80 |
| `dive_obstacle_gap` | 240 | 200 | 170 |
| `dive_obstacle_density` | 0.5 | 0.9 | 1.3 |
| `dive_bite_radius` | 46 | 40 | 34 |
| `dive_max_depth` | 1300 | 1300 | 1300 |

**手感参数不分难度**（三档共用一个值，改难度只改上面那张表）。它们是"手"的问题，不是"难度"的问题：

| 字段 | 值 | 说明 |
| --- | --- | --- |
| `dive_accel` | 2600 | px/s²，给的是加速度不是速度 |
| `dive_drag` | 0.82 | 松手后每帧保留的比例（60fps） |
| `dive_max_speed` | 620 | 横向速度上限，防手抖瞬移 |
| `dive_deadzone` | 0.12 | 触屏死区 |
| `dive_smooth` | 0.18 | 触屏输入平滑窗口（秒） |
| `dive_boost_curve` | 0.25 | 按住加速的爬升时间常数 |
| `dive_rise_inertia` | 0.35 | 上浮惯性 |
| `dive_hitstop` | 0.08 | 撞击定帧（秒） |

验收用三条硬指标卡：输入到画面 ≤ 33ms、横穿屏幕 1.6–2.0s、松手滑行 ≤ 40px。详见 [plan-phase2-cast.md](plan-phase2-cast.md) §10。

### 障碍

| 类型 | 行为 | 判定 | 反馈 |
| --- | --- | --- | --- |
| 水草 `weed` | 固定 | 扣气 | 绿碎屑 |
| 礁石 `rock` | 固定硬边 | 扣气 + 倒退 | 火花、短震屏 |
| 塑料瓶 `bottle` | 漂浮摆动 | 扣气 | 「咕咚」 |
| 水母 `jelly` | 漂移带电 | 扣气 ×1.5 | 蓝闪 |
| 气泡 `bubble` | 增益 | 回气 | 气泡串 |
| 鱼影 `shadow` | 目标 | 进感知半径 → 咬钩 | 停顿 + 音效 |

**公平性铁律**：任何时刻必须有可通行缝隙（≥ `dive_obstacle_gap`）。生成器先画通道再贴障碍，单测扫 1000 个种子。

### 计分（独立一份，`dive_score.gd`）

深度分 `floor(max_depth/100)*20`；无伤 `+150`；擦身（12px 内通过）每次 `×5` 并连击；出水奖励 `剩余气量 × 2`。存 `progress.json` 的 `ch2.best_score / best_depth`。

### 数据 schema（`data/dive.json`）

```json
{
  "_note": "深水模式唯一数据源。深度单位：米。1300 米＝西雅图沿海，终点。",
  "goal": {"depth": 1300, "scene": "res://assets/art/cg/ch2/water/seattle.webp", "character": "claude"},
  "layers": [
    {"name": "近岸", "depth_from": 0, "depth_to": 400,
     "obstacles": ["weed", "bottle"], "fish": {"small": 0.8, "mid": 0.2}},
    {"name": "中段", "depth_from": 400, "depth_to": 900,
     "obstacles": ["weed", "rock", "bottle", "jelly"],
     "fish": {"small": 0.3, "mid": 0.6, "doubao": 0.1}},
    {"name": "深水", "depth_from": 900, "depth_to": 1300,
     "obstacles": ["rock", "jelly", "weed"],
     "fish": {"mid": 0.4, "big": 0.45, "<AI_ID_1>": 0.05, "<AI_ID_2>": 0.04, "<AI_ID_3>": 0.03, "claude": 0.03}}
  ],
  "pickups": {"bubble": {"air": 8, "radius": 18}},
  "mimic": {
    "_note": "便宜模型装成贵的。只伪装这三个，不伪装 claude，也不伪装便宜模型。",
    "decoy_of": ["kimi", "chatgpt", "grok"],
    "chance": {"mid": 0.05, "deep": 0.12, "abyss": 0.20},
    "score": 30,
    "reveal_radius": 120,
    "shake_amp": 2.0
  },
  "obstacles": {
    "weed": {"radius": 26, "drift": 0},
    "rock": {"radius": 34, "drift": 0},
    "bottle": {"radius": 20, "drift": 22},
    "jelly": {"radius": 24, "drift": 14}
  }
}
```

## 7. 代码落点

**新增**

| 文件 | 职责 |
| --- | --- |
| `scripts/ui/menu_root.gd`（**重写**） | 章节目录：两张卡片、锁定态、最高分 |
| `scripts/core/progress.gd` | 章节解锁、通关次数、最好成绩、旧档迁移 |
| `scripts/ui/chapter_card.gd` | 单张章节卡（四态、高亮呼吸） |
| `scripts/ui/dive_root.gd` | 第二关根：界面、输入、接 session |
| `scripts/core/dive_session.gd` | 纯逻辑：位置/速度/气量/碰撞/咬钩/状态机 |
| `scripts/core/dive_generator.gd` | 种子化生成通道与障碍 |
| `scripts/core/dive_score.gd` | 深度/擦身/无伤/出水四项 |
| `scripts/ui/dive_view.gd` | 绘制：水层、视差、障碍、钩子、粒子 |
| `scripts/ui/dive_hud.gd` | 深度、气量、擦身连击 |
| `scenes/dive.tscn` | 12 行，挂 `dive_root.gd` |
| `data/dive.json` | 见上 |

**改一期（加法为主）**

| 文件 | 改动 |
| --- | --- |
| `scripts/ui/game_root.gd` | 结束时写 `Progress.mark_cleared("ch1")`（一行）+ 结算关闭后按需播 `chapter_gate` |
| `data/endings.json` | 给 `feast` 加 `"gate": true` |
| `data/story.json` | 新增 `chapter_gate` 段 |
| `data/characters.json` | 加 `chapter` / `unlock` / `voice` 三个可选字段 |
| `scripts/ui/gallery_root.gd` | 按 `chapter` 分页签（筛注册表，不写第二份清单） |
| `data/i18n/strings.csv` | 新键（章节名、解锁条件、gate 台词、深水 HUD） |
| `tests/selftest.gd` | 加用例；既有断言不动 |

`fishing_session.gd`、`qte_overlay.gd`、`fight_session.gd`、`main.tscn` 不改。

### 7.1 每个新文件复用谁（不许新造轮子）

| 新文件 | 直接复用 | 禁止依赖 |
| --- | --- | --- |
| `menu_root.gd`（重写） | `UIKit.flat/card/label/button/spacer`、`Palette`、`LakeBackdrop`、`GameSettings`、`Progress` | 不 import 任何 `dive_*`、不 import `game_root` |
| `chapter_card.gd` | `UIKit.card` + `UIKit.label`（四态只改颜色与文案，不新做 StyleBox） | 不读文件、不碰 `Gallery`，数据由参数传入 |
| `progress.gd` | `ConfigLoader.read_json/write_json` 的写法惯例（唯一的 FileAccess 入口）| 不引用任何 UI、不引用 `Gallery` 与 `ScoreBoard` |
| `dive_root.gd` | `UIKit`、`Palette`、`PauseLayer`（暂停遮罩现成）、`StoryDirector`（短剧情）、`Audio`、`GameSettings` | 不 import `game_root`、不 import `fishing_session` |
| `dive_session.gd` | `GameTuning` 的 `SCALAR_FIELDS` 读取惯例；纯 RefCounted，无 `Node` | 不碰文件、不碰 `Audio`、不碰场景树 |
| `dive_generator.gd` | 只用 `RandomNumberGenerator` + `data/dive.json` 的参数 | 不理解「鱼」，只吐位置 |
| `dive_score.gd` | 参照 `score_board.gd` 的接口形状（`reset/hit/finalize/load_best`） | 不复用 `ScoreBoard` 本体（两关计分规则不同） |
| `dive_view.gd` | `Palette`、`LakeBackdrop` 的渐变画法（抄结构不抄代码） | 不读 json、不算逻辑 |
| `dive_hud.gd` | `UIKit.label/progress`、`ScoreLayer` 的描边做法 | 不读 json |
| `data/dive.json` | 与 `tuning.json` 同一套「数值都在数据里」的约定 | — |

一期的 `SceneFeedback`、`QteOverlay`、`LandingView` 属于第一关的表现层，二期**不引用**。

### 7.2 开发照 skill 走，不重新发明流程

- `C:\Users\doubl\AppData\Roaming\dsh-desktop\harness\skills\godot-dev\SKILL.md`：
  - §13.2 数据外置（演出/数值进 JSON，`ConfigLoader` 唯一入口）
  - §13.5 `SCALAR_FIELDS` + `set(field, value)`（深水 12 个 `dive_*` 必须登记，别再出现「难度档里改了不生效」）
  - §13.6 i18n（新文案进 `strings.csv`，改完 `--import`，列序 `keys,zh_CN,zh_TW,en,ja`）
  - §13.15 省电（导出后确认 `GpuPreference=1;` 生效）
  - §13.16 分层（`dive_root` 只做接线，逻辑在 `dive_session`，能 `new()` 出来跑单测）
  - 收尾：`selftest` 全绿 + 三端导出 + 文档/skill 同步
- `C:\Users\doubl\AppData\Roaming\dsh-desktop\harness\skills\image-forge\SKILL.md`：新 AI 角色剪影出图用 anima-turbo + `DeepSeek_ZipZipPipe_style_anima2b`，参数与负面词照 `private_cg` 那本记的来。

### 7.3 依赖方向（单向，不许回头）

```
data/*.json
   ↓（只读，经 ConfigLoader / GameTuning）
core/progress.gd   core/dive_session.gd   core/dive_score.gd
   ↑                    ↑                     ↑
ui/menu_root.gd     ui/dive_root.gd  ────────┘
   ↑                    ↑
main.tscn           scenes/dive.tscn
```

- `core/*` 不 import `ui/*`；
- `ui/dive_root` 与 `ui/game_root` 互不认识，只共享 `core` 与数据；
- 两个关卡的存档分开（`record.json` / `progress.json`），互不写对方的键；
- 跨关通信只有一条：`Progress.mark_cleared("ch1")` 与 `Progress.is_unlocked("ch2")`。

## 8. 共用与不共用

| 共用（已有，直接用） | 不共用（各写一份，理由） |
| --- | --- |
| `ConfigLoader`（新增 `load_dive()`，仍然唯一文件入口） | 两关的状态机（`fishing_session` 的 Phase 与深水的下沉/咬钩/收线不是一回事） |
| `GameTuning`（新增 dive 段 + `SCALAR_FIELDS` 登记） | 两关的计分器（规则不同，硬合并会长出一堆 if） |
| `GameSettings` / `Audio` / `Palette` / `UIKit` | 两关的存档（`record.json` vs `progress.ch2`） |
| `LakeBackdrop`（菜单、gate 剧情背景照旧用） | 深水场景背景（侧视水柱，另画） |
| `PauseLayer`（第二关直接复用） | 一期的 `escapes.json`（深水另开 `dive_escapes.json`） |
| `StoryDirector`（gate 与短剧情都走它） | 一期的 `opening` 与结局文案 |
| `Gallery`（鱼与图鉴条目，只加字段） | 深水的「擦身/深度」不进 `Gallery`，只进 `progress.json` |
| `SceneFeedback`（第二关的「气不够了」可复用） | 一期的 `QteOverlay` / `LandingView`（第二关不看这两个） |

## 9. 里程碑

| 阶段 | 产出 | 验收 |
| --- | --- | --- |
| M1 章节外壳（2 天） | `progress.gd` + 新菜单 + 两张卡 + 锁定态 | 老档能迁；解锁/锁定切换正确；键盘可操作；**`menu_root` 里没有新 StyleBox、没有第二份背景绘制** |
| M2 剧情衔接（1 天） | `chapter_gate` 12 句 + 结算后播放 + i18n | 首次通关播一次，重复通关不再播；播完回菜单不自动开局 |
| M3 深水骨架（2 天） | `dive_session` + `dive_generator` + 纯色块 | 通道必可过、气尽必结束、种子可复现；**`DiveSession.new()` 不碰场景树就能跑** |
| M4 手感（2 天） | 加速/上浮曲线、碰撞反馈、震屏 | 连玩 10 局不烦；三档数值只改 `dive.json` 不改代码 |
| M5 表现（2–3 天） | 水层渐变、视差、粒子、音效 | 三档各录一局不掉帧；绘制代码里没有数值 |
| M6 角色解锁（2 天） | 三条新 AI 影 + 图鉴分页 + 首次钓到短剧情 | 图鉴不漏条目；剪影可用；**新增角色只改 `characters.json`，不改 `gallery_root` 的分支** |
| M7 收尾（1 天） | 三端导出、文档、skill 更新 | `selftest` 全绿，两关都可玩，`GpuPreference=1;` 生效 |

## 10. 验收标准（可测）

1. 新档：只有第一关可进，第二关显示锁定与条件；
2. 达成 `feast` 一次 → 结算关闭后播 gate → 第二关解锁 → 回菜单能看到高亮；
3. 再通关一次不再播 gate，`cleared_count` 累加；
4. 老档（已达成 `feast`、无 `progress.json`）打开菜单直接是解锁态；
5. 深水任意种子 1000 次生成无「无解通道」；
6. 全程不操作 → 8 秒后必脱钩；
7. 手机竖屏/横屏不挡操作区（≥ 96px 安全区）；
8. **一期回归**：一期 `selftest` 数字不变；
9. **复用验收**：`grep` 不到第二份背景绘制、第二份按钮 StyleBox、第二条难度白名单、`ui/dive_*` 里 `preload("res://scripts/ui/game_root.gd")` 这类跨关 import。

## 11. 风险与对策

| 风险 | 对策 |
| --- | --- |
| 菜单重制把老玩家挡在外面 | 旧档迁移规则 + 首次进入时补一条 `ch1.cleared` |
| 规划里又长出新副本 | §7.1 逐文件写死「复用谁 / 禁止依赖谁」，验收第 9 条用 grep 卡 |
| 第二关把一期的 UI 抄一遍 | 共用表 §8 列明白，`dive_root` 只准用 `UIKit`/`Palette`/`PauseLayer`/`StoryDirector` |
| 章节化让「随便玩玩」变重 | 第一关卡仍可直接进，不强制看剧情 |
| 新 AI 立绘拖慢进度 | 先用深水剪影，M6 之前不阻塞 |
| 两个计分器混淆 | `record.json` 与 `progress.json` 各管一段，结算页各自显示 |
| 触屏横向精度差 | 0.15s 平滑 + 死区 + 自动横向开关 |

## 12. 这一期不做

- 不做第三关（深水之后先收住，留接口）；
- 不做多钩、鱼线物理、水底地形；
- 不做联网排行；
- 不为新关单独开设置页；
- 不改一期的对局逻辑（只加通关标记与 gate 触发）。

---

## 相关文档

- plan-phase2-cast.md：角色、剧情、结局、好感度、特别装束
- plan-phase2-link.md：**两关联动**、仓库与养成、河底打捞、助手技能、完美结局
