## GptStage —— 商人的四阶段与解锁判定
## 层：phase2/core（纯逻辑）
## 规矩：只看 Progress，不碰界面；界面问它「现在第几阶段」，然后换立绘、换倍率。
class_name GptStage
extends RefCounted

## 0 兜帽 / 1 放下兜帽 / 2 脱斗篷 / 3 关灯（能带回家）
const STAGE_NAMES := ["hooded", "hood_down", "cloak_off", "home"]

## 首次「张斗篷」那段漫画看过了没有
const SEEN_KEY := "gpt_reveal"


static func seen_reveal(p: Progress) -> bool:
	return p != null and int(p.items.get(SEEN_KEY, 0)) > 0


static func mark_reveal(p: Progress) -> void:
	if p == null:
		return
	p.items[SEEN_KEY] = 1
	p.save()


## 彩蛋拿到了几个（trinkets 里 gpt_ 开头的）
static func eggs(p: Progress) -> int:
	if p == null:
		return 0
	var n := 0
	for id in p.trinkets:
		if String(id).begins_with("gpt_"):
			n += 1
	return n


## 地球另一边看到几张
static func far_views(p: Progress) -> int:
	return p.scenery.size() if p != null else 0


## 钓上几只 gpt
static func caught(p: Progress) -> int:
	return int(p.characters.get("gpt", 0)) if p != null else 0


## 小 GPT 的好感（商人的好感记在她身上）
static func affection(p: Progress) -> int:
	return int(p.affinity.get("abagpt", 0)) if p != null else 0


## 现在第几阶段。
##   1：好感 ≥35 + 钓上 1 只
##   2：好感 ≥70 + 钓上 2 只 + 彩蛋 ≥2
##   3：好感 ≥90 + 彩蛋 4 件齐 + 远景色 ≥2
static func stage_of(p: Progress) -> int:
	if p == null:
		return 0
	var aff := affection(p)
	var got := caught(p)
	var e := eggs(p)
	if aff >= 90 and e >= 4 and far_views(p) >= 2:
		return 3
	if aff >= 70 and got >= 2 and e >= 2:
		return 2
	if aff >= 35 and got >= 1:
		return 1
	return 0


## 收购倍率：阶段越深，她给得越多。
static func buy_rate(p: Progress) -> float:
	match stage_of(p):
		1:
			return 1.15
		2:
			return 1.35
		3:
			return 1.6
		_:
			return 1.0


## 这一阶段她卖什么（商品 id 列表，空 = 只有基础三档升级）
static func extra_goods(p: Progress) -> Array:
	match stage_of(p):
		1:
			return ["sonar", "line_guard"]
		2:
			return ["sonar", "line_guard", "magnet", "double_hook"]
		3:
			return ["sonar", "line_guard", "magnet", "double_hook", "seed_slot", "lamp"]
		_:
			return []


## 下一阶段还差什么（给界面写「再差……就能看见她放下兜帽」）
static func next_hint(p: Progress) -> String:
	var st := stage_of(p)
	if st >= 3:
		return ""
	var aff := affection(p)
	var got := caught(p)
	var e := eggs(p)
	match st:
		0:
			return "好感 %d/35 · 钓到 %d/1" % [aff, got]
		1:
			return "好感 %d/70 · 钓到 %d/2 · 彩蛋 %d/2" % [aff, got, e]
		_:
			return "好感 %d/90 · 彩蛋 %d/4 · 景色 %d/2" % [aff, e, far_views(p)]
