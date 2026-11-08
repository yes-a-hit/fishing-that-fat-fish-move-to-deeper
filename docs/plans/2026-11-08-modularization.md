# 模块拆分方案（2026-11-08）

目标：**每个模块只认识自己的上游**，改一处不牵连三处。

## 一、现状的问题

| 症状 | 位置 | 后果 |
|---|---|---|
| UI 自己拼业务条件 | `harbor_screen` 读 `cast_forms.json` 判房间；`contacts_root` 自己判认识不认识 | 规则散在界面里，改门槛要翻五个文件 |
| 一个文件扛太多事 | `dive_root.gd` 同时管状态机、明信片、商店、结算、回房间 | 三十多个 `_on_*`，加一个功能要动一大片 |
| 存档四个文件职责重叠 | `save.json` / `phase2.json` / `settings.json` / `record.json` | 「通关没通关」两边都记，出现第二种真相 |

## 二、目标分层

```
┌─────────────────────────────────────────────┐
│ ui/            只画和收输入，不做判断        │
│  harbor / boat / dive / result / contacts   │
└───────────────────┬─────────────────────────┘
                    │ 只调用（单向）
┌───────────────────▼─────────────────────────┐
│ app/           流程编排：谁该跳到哪          │
│  chapter_router / trip_flow                  │
└───────────────────┬─────────────────────────┘
                    │ 只调用
┌───────────────────▼─────────────────────────┐
│ core/          纯逻辑，不碰 Node             │
│  progress / ledger / tuning / session        │
│  save_schema / affinity_book / gpt_stage     │
└─────────────────────────────────────────────┘
```

**三条铁律**

1. `core/` 不许 `import` 任何 UI 或 `Node`。
2. `ui/` 不许自己判断「能不能」「通没通关」「解锁没有」——一律问 `core/`。
3. 跳场景只在一处发生（`app/chapter_router.gd`），UI 只发信号。

## 三、拆分步骤（按风险从低到高）

### 第 1 步：把界面里的判断搬进 core（低风险）

| 现在在哪 | 应该在哪 |
|---|---|
| `harbor_screen._room_form()` 读 `cast_forms.json` | `SaveSchema.room_unlocked(p2)` |
| `contacts_root._is_known()` 自己判断 | `SaveSchema.character_known(id, p2)` |
| `gallery_root._lock_hint()` 拼门槛文案 | 保留（只是文案，不涉及判断） |

### 第 2 步：拆 `dive_root.gd`（中风险）

按「一次访问」的生命周期切成四段，各自一个类：

```
trip_flow.gd       一次出海的流程：进港 → 上船 → 下潜 → 收线
harbor_controller  港口的点击分发（点谁、说什么、跳哪）
dive_controller    下潜过程中的键盘/计时/上钩
result_controller  结算卡的数据与按钮
```

`dive_root.gd` 只留：`_set_state()` + 把四个 controller 装起来。

### 第 3 步：合并存档（高风险，最后做）

四个文件合成一个 `save.json`，带 `version` 与迁移表：

```
1. 读旧文件 → 组装成新结构
2. 写新文件（含 version）
3. 旧文件改名 .bak
4. 下一版删 .bak
```

`SaveSchema` 作为唯一门面，合并后界面一行不用改。

## 四、验收标准

- `rg "cast_forms|affinity|chapter_cleared" scripts/ui/` 结果为空（除注释）
- `dive_root.gd` 行数 < 200
- 新增一个"能不能做某事"的规则时，只改 `core/` 里一个文件
- `selftest` 保持全绿，`shot_*.gd` 截图与改动前一致
