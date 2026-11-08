# 工程地图（自动生成，别手改）

生成器：`python tools/rag_index.py`　计划：`docs/plans/2026-11-07-rag.md`

| 类目 | 条数 |
|---|---|
| scripts | 51 |
| data | 13 |
| docs | 22 |
| tests | 12 |
| scenes | 1 |
| art | 141 |

## assets/

- assets/art/manifest.json · 「美术资产索引，按 group/chapter/character/form 过滤」 · ? 行

## data/

- data/about.json · keys: license_short, intro, easter_eggs, sections · 50 行
- data/characters.json · keys: characters · 140 行
- data/endings.json · keys: true_end, feast, full, hungry, claude_fake, claude, claude_sad, doubao_good · 142 行
- data/escapes.json · keys: items · 51 行
- data/fish.json · keys: fish · 74 行
- data/phase2/affinity.json · keys: tiers, start_full · 44 行
- data/phase2/cast_forms.json · keys: kimi · 38 行
- data/phase2/dive.json · keys: difficulty, layers, goal, mimic, score, dive_max_depth, light, hazard · 102 行
- data/phase2/lore.json · keys: codename, hints · 13 行
- data/phase2/shop.json · keys: upgrades, items, slots_from_upgrades, reachable · 115 行
- data/scenery.json · keys: collection, items · 42 行
- data/story.json · keys: opening, doubao_second, claude_after_elope, ending_feast, ending_full, ending_hungry, ending_doubao_good, ending_claude_good · 1588 行
- data/tuning.json · keys: bait_count, full_catch_threshold, fake_claude_chance, charge_full_seconds, cast_jitter, shadow_count, shadow_width, shadow_weaken · 250 行

## docs/

- docs/agents/domain.md · 领域文档 · 65 行
- docs/agents/issue-tracker.md · Issue 跟踪器：本地 Markdown · 31 行
- docs/agents/triage-labels.md · 分诊标签 · 14 行
- docs/animation.md · 动画帧：素材怎么出、怎么接 · 234 行
- docs/architecture-phase2.md · 二期架构（`phase2`）—— 分层、依赖规则与增量边界 · 396 行
- docs/architecture.md · 架构说明 · 519 行
- docs/art-audit.md · 立绘审计 · 62 行
- docs/art-style.md · 立绘规范 · 57 行
- docs/contributing.md · 开发规范 · 336 行
- docs/design.md · 设计文档 · 250 行
- docs/DEVELOPMENT.md · 开发者手册 · 220 行
- docs/landing-animation.md · 上鱼角色动画：目标设计与验收标准 · 334 行
- docs/plan-phase2-cast.md · 二期角色与剧情设计（`DIVE` 篇） · 612 行
- docs/plan-phase2-dive.md · 二期规划：章节化 + 深水钓（`DIVE`） · 398 行
- docs/plan-phase2-link.md · 二期 · 两关联动与后期（设计稿 v2） · 375 行
- docs/plans/2026-11-07-kimi-story.md · 计划：Kimi 登月剧情落地（2026-11-07） · 118 行
- docs/plans/2026-11-07-rag.md · 计划：项目级 RAG 索引（2026-11-07） · 60 行
- docs/plans/2026-11-08-save-schema.md · 存档结构（2026-11-08） · 67 行
- docs/plans/2026-11-08-tech-debt.md · 技术债清单（2026-11-08） · 40 行
- docs/STATE.md · 当前状态快照（2026-11-08 14:40） · 83 行
- docs/TODO.md · 待办 · 183 行
- docs/tuning.md · 调参手册 · 343 行

## scenes/

- scenes/dive.tscn · root Control · 13 行

## scripts/

- scripts/core/audio_director.gd · extends Node · 12 funcs · 「音频总管（autoload 名 Audio）。」 · 158 行
- scripts/core/boot.gd · extends Node · 4 funcs · 「启动时把玩家选的语言套上去，顺带加载玩家自己放的翻译。」 · 114 行
- scripts/core/config_loader.gd · class **ConfigLoader** · extends RefCounted · 21 funcs · 「所有 data/*.json 的唯一入口。」 · 360 行
- scripts/core/fight_session.gd · class **FightSession** · extends RefCounted · 22 funcs · 「一条鱼的搏斗过程 —— 纯逻辑，不碰 Node、不读文件、不碰输入。」 · 240 行
- scripts/core/fish_spec.gd · class **FishSpec** · extends RefCounted · 3 funcs · 「一条鱼的「静态数据」，全部来自 data/fish.json。」 · 48 行
- scripts/core/fishing_session.gd · class **FishingSession** · extends RefCounted · 37 funcs · 「一局钓鱼的全部规则 —— 纯逻辑，不碰 Node、不读文件、不碰输入。」 · 540 行
- scripts/core/gallery.gd · class **Gallery** · extends RefCounted · 24 funcs · 「收集图鉴：记录玩家解锁过哪些内容。」 · 352 行
- scripts/core/game_settings.gd · class **GameSettings** · extends RefCounted · 3 funcs · 「玩家偏好，存 user://settings.json。」 · 87 行
- scripts/core/game_tuning.gd · class **GameTuning** · extends RefCounted · 18 funcs · 「一局的全局规则数值，来自 data/tuning.json。」 · 382 行
- scripts/core/gpu_preference.gd · class **GpuPreference** · extends RefCounted · 2 funcs · 「Windows 允许按程序指定用哪块显卡，落点在注册表：」 · 62 行
- scripts/core/save_schema.gd · class **SaveSchema** · extends RefCounted · 7 funcs · 「存档的唯一查询层。」 · 71 行
- scripts/core/score_board.gd · class **ScoreBoard** · extends RefCounted · 7 funcs · 「一局的分。规则全部收在这一个文件里，UI 只负责把数字弹出来。」 · 154 行
- scripts/phase2/core/dive_generator.gd · class **DiveGenerator** · extends RefCounted · 0 funcs · 「DiveGenerator —— 按种子参数生成一局的水层、障碍、杂物与 AI 出现表」 · 7 行
- scripts/phase2/core/dive_score.gd · class **DiveScore** · extends RefCounted · 0 funcs · 「DiveScore —— 二期计分：深度、杂物、AI、残影」 · 7 行
- scripts/phase2/core/dive_seed.gd · class **DiveSeed** · extends RefCounted · 0 funcs · 「DiveSeed —— 种子 → 地图参数（纯函数、确定性）」 · 7 行
- scripts/phase2/core/dive_session.gd · class **DiveSession** · extends RefCounted · 15 funcs · 「DiveSession —— 一局的规则状态机：下沉、刷鱼、撞杂物、上钩、收线。」 · 239 行
- scripts/phase2/core/dive_tuning.gd · class **DiveTuning** · extends RefCounted · 6 funcs · 「DiveTuning —— 把 dive.json / shop.json 里的表读成「等级 → 数值」。」 · 55 行
- scripts/phase2/core/ledger.gd · class **Ledger** · extends RefCounted · 8 funcs · 「Ledger —— 二期经济账本：钱、杂物库存、已见计数；升级与道具扣款只走这里」 · 55 行
- scripts/phase2/core/progress.gd · class **Progress** · extends RefCounted · 29 funcs · 「Progress —— 二期存档：章节/解锁/好感/仓库/升级/种子历史」 · 272 行
- scripts/phase2/core/scenery_deck.gd · class **SceneryDeck** · extends RefCounted · 2 funcs · 「西雅图景色的伪随机抽取。」 · 43 行
- scripts/phase2/core/shop.gd · class **Shop** · extends RefCounted · 0 funcs · 「Shop —— 商人：钓具升级表、道具表、槽位 = 总等级」 · 7 行
- scripts/phase2/ui/assistant_picker.gd · class **AssistantPicker** · extends Control · 0 funcs · 「AssistantPicker —— 助手选择：只列已解锁的 AI」 · 7 行
- scripts/phase2/ui/boat_screen.gd · class **BoatScreen** · extends Control · 11 funcs · 「BoatScreen —— Claude 的船：船头界面。」 · 279 行
- scripts/phase2/ui/dive_hud.gd · class **DiveHud** · extends Control · 9 funcs · 「下潜时的 HUD —— 卷轴式：所有信息压在顶部一条和右侧一竖，中间留给海。」 · 162 行
- scripts/phase2/ui/dive_root.gd · class **DiveRoot** · extends Control · 24 funcs · 「DiveRoot —— 二期根节点：串起船 → 下潜 → 结算，只做装配。」 · 392 行
- scripts/phase2/ui/dive_view.gd · class **DiveView** · extends Control · 10 funcs · 「DiveView —— 只画世界：水层滚动、钩子、鱼影、明暗。」 · 191 行
- scripts/phase2/ui/harbor_screen.gd · class **HarborScreen** · extends Control · 7 funcs · 「HarborScreen —— 港口：靠点人推进，不用菜单。」 · 216 行
- scripts/phase2/ui/shop_screen.gd · class **ShopScreen** · extends Control · 7 funcs · 「ShopScreen —— 商人的摊子。」 · 133 行
- scripts/ui/about_root.gd · extends Control · 15 funcs · 「关于页。协议、出处、彩蛋。」 · 308 行
- scripts/ui/bowl_icon.gd · class **BowlIcon** · extends Control · 3 funcs · 「一只白饭碗的小图标，纯 _draw() 画。」 · 63 行
- scripts/ui/cast_bar.gd · class **CastBar** · extends Control · 6 funcs · 「抛竿距离指示 —— **只属于抛竿阶段**。」 · 122 行
- scripts/ui/cast_panel.gd · class **CastPanel** · extends PanelContainer · 5 funcs · 「抛竿面板。**蓄力滚动条只出现在这里，搏斗阶段绝不复用。**」 · 81 行
- scripts/ui/ending_overlay.gd · class **EndingOverlay** · extends Control · 11 funcs · 「结算画面。全屏遮罩 + 居中卡片。」 · 323 行
- scripts/ui/gallery_root.gd · extends Control · 35 funcs · 「图鉴。三页：结局、脱钩、声音。」 · 622 行
- scripts/ui/game_root.gd · extends Control · 36 funcs · 「主控：装配界面、接输入、把 FishingSession 的信号翻译成画面变化。」 · 728 行
- scripts/ui/hud_view.gd · class **HudView** · extends PanelContainer · 5 funcs · 「顶部状态栏：白饭余量 / 已钓进度 / 阶段提示。」 · 104 行
- scripts/ui/lake_backdrop.gd · class **LakeBackdrop** · extends Control · 2 funcs · 「菜单/图鉴/设置/关于四页共用的湖面背景。」 · 55 行
- scripts/ui/lake_view.gd · class **LakeView** · extends Control · 17 funcs · 「全屏湖面背景。全部用 _draw() 画，不依赖任何图片素材。」 · 246 行
- scripts/ui/landing_view.gd · class **LandingView** · extends Control · 8 funcs · 「上鱼飞扑动画。」 · 193 行
- scripts/ui/menu_root.gd · extends Control · 13 funcs · 「主菜单。整个游戏唯一的入口。」 · 191 行
- scripts/ui/palette.gd · class **Palette** · extends RefCounted · 1 funcs · 「全局配色与尺寸。所有颜色只在这里定义一次。」 · 73 行
- scripts/ui/pause_layer.gd · class **PauseLayer** · extends Control · 2 funcs · 「暂停遮罩：一层压暗 + 一张三按钮卡片。」 · 59 行
- scripts/ui/qte_overlay.gd · class **QteOverlay** · extends Control · 17 funcs · 「搏斗期的场景内 QTE 显示 —— 没有面板、没有边框卡片。」 · 240 行
- scripts/ui/scene_feedback.gd · class **SceneFeedback** · extends Control · 4 funcs · 「场景内的一次性文字提示，用来替代原来的「结果卡面板」。」 · 55 行
- scripts/ui/score_layer.gd · class **ScoreLayer** · extends Control · 10 funcs · 「分数行 + 命中瞬间的飘字。」 · 124 行
- scripts/ui/settings_root.gd · extends Control · 19 funcs · 「设置页：难度 + 声音。」 · 324 行
- scripts/ui/shore_root.gd · extends Control · 5 funcs · 「第一章的岸边：第一人称站在水里，手里握着竿。」 · 150 行
- scripts/ui/story_director.gd · class **StoryDirector** · extends RefCounted · 5 funcs · 「剧情播放的唯一调度点：取哪一段、什么时候收界面、播完接着做什么。」 · 68 行
- scripts/ui/story_overlay.gd · class **StoryOverlay** · extends Control · 19 funcs · 「剧情播放器。视觉小说那种：底图铺满、左下角站个小人、底下一条对话框，一句一句往下走。」 · 387 行
- scripts/ui/ui_kit.gd · class **UIKit** · extends RefCounted · 13 funcs · 「控件工厂。所有面板都通过这里造控件，样式才不会各写一套。」 · 178 行
- scripts/ui/world_root.gd · extends Control · 5 funcs · 「世界层：菜单不再罗列「第一章 / 第二章」，只给一张世界图。」 · 88 行

## tests/

- tests/input_probe.gd · extends SceneTree · 3 funcs · 「输入链路探针（开发用，不参与游戏）。」 · 75 行
- tests/screenshot.gd · extends SceneTree · 5 funcs · 「视觉快照工具（开发用，不参与游戏）。」 · 195 行
- tests/selftest.gd · extends SceneTree · 76 funcs · 56 用例 · 「无窗口逻辑自测。运行：」 · 2571 行
- tests/shot_boat.gd · extends SceneTree · 2 funcs · 「拍两张：港口（初始态）与船上（点船之后）。」 · 28 行
- tests/shot_dive.gd · extends SceneTree · 2 funcs · 「拍一张下潜界面：看钩子、鱼影、HUD 对不对。」 · 27 行
- tests/shot_farside.gd · extends SceneTree · 2 funcs · 「拍「穿透地心」那一幕：把深度硬推到 1205m，看画面是不是翻过来了。」 · 33 行
- tests/shot_menu.gd · extends SceneTree · 2 funcs · 「拍主菜单。用法：godot --path <proj> --script res://tests/shot_menu.gd」 · 27 行
- tests/shot_shop.gd · extends SceneTree · 2 funcs · 「拍商店：港口 → 点商人 → 卡片浮出来。」 · 30 行
- tests/shot_shore.gd · extends SceneTree · 2 funcs · 「拍岸边。用法：godot --path <proj> --script res://tests/shot_shore.gd」 · 23 行
- tests/smoke_dive.gd · extends SceneTree · 2 funcs · 「DiveRoot 冒烟：能不能实例化、三态能不能切、会不会报错。」 · 41 行
- tests/smoke_scenery.gd · extends SceneTree · 2 funcs · 「验证「大洋彼岸的景色」抽取机制：」 · 43 行
- tests/smoke_train.gd · extends SceneTree · 2 funcs · 「验证训练模式：港口点训练 → 进 DIVE → 收线 → 最高分刷新。」 · 43 行
