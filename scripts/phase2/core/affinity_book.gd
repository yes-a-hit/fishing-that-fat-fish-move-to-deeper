## AffinityBook —— 好感度查询与 buff 汇总
## 层：phase2/core（纯逻辑）
## 数据：data/phase2/buffs.json（每个角色各自的好感档位与 buff）
## 规矩：单角色取自己那一档；同类 buff 相加，但要有封顶，不然满收集会崩。
class_name AffinityBook
extends RefCounted

## 商人的好感其实记在小 GPT（abagpt）身上，这里做一次别名。
const AFFINITY_ALIAS := {"chatgpt": "abagpt"}

## 卖价最多 +80%（商人一个人就占 35%）
const SELL_CAP := 0.8
## 白饭最多多带 4 碗
const BAIT_CAP := 4
## 稀有鱼最多 +30%
const RARE_CAP := 0.3
## 撞杂物减伤最多 60%
const GUARD_CAP := 0.6


## 读 buffs.json。读不到就返回空表（老档也能跑）。
static func load_table(path: String = "res://data/phase2/buffs.json") -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## 某个角色在这个好感值下拿到哪一档（返回 {buff, note}），没到门槛返回 {}。
static func block_of(table: Dictionary, id: String, value: int) -> Dictionary:
	var chars: Dictionary = table.get("characters", {})
	if not chars.has(id):
		return {}
	var best: Dictionary = {}
	for b in chars[id].get("blocks", []):
		if value >= int(b.get("min", 0)):
			best = b
	return best


static func buff_of(table: Dictionary, progress: Progress, id: String) -> Dictionary:
	if progress == null:
		return {}
	var src := String(AFFINITY_ALIAS.get(id, id))
	var v := int(progress.affinity.get(src, 0))
	return block_of(table, id, v).get("buff", {})


## 某一类 buff 的全场总和，带封顶。
static func total(table: Dictionary, progress: Progress, key: String, cap: float) -> float:
	if progress == null:
		return 0.0
	var sum := 0.0
	for id in progress.affinity.keys():
		sum += float(buff_of(table, progress, String(id)).get(key, 0.0))
	return minf(sum, cap)


static func sell_bonus(table: Dictionary, progress: Progress) -> float:
	return total(table, progress, "sell_bonus", SELL_CAP)


static func bait_bonus(table: Dictionary, progress: Progress) -> int:
	return int(total(table, progress, "bait_bonus", float(BAIT_CAP)))


## 一条鱼现在卖多少（含全场卖价加成）。
static func fish_price(base: int, bonus: float) -> int:
	return maxi(1, int(round(base * (1.0 + bonus))))
