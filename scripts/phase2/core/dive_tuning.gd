## DiveTuning —— 把 dive.json / shop.json 里的表读成「等级 → 数值」。
##
## 层：phase2/core（纯数据，不碰 Node）
## 依赖：无
##
## 为什么单独拿出来：line / hook / rod 的等级是 0..4，
## 但真正要用的是 max_depth / capacity / sink_scale，
## 这两种东西以前混在一起写过一次，导致「线 0 级 = 深度 0」的坑。
class_name DiveTuning
extends RefCounted

const DIVE_PATH := "res://data/phase2/dive.json"
const SHOP_PATH := "res://data/phase2/shop.json"


static func read_json(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## 等级 → 表里那一项。越界就夹到首/尾，绝不返回负数。
static func value_at(table: Array, level: int, fallback: float) -> float:
	if table.is_empty():
		return fallback
	var i := clampi(level, 0, table.size() - 1)
	return float(table[i])


static func max_depth(shop: Dictionary, line_level: int) -> float:
	var line: Dictionary = shop.get("upgrades", {}).get("line", {})
	return value_at(line.get("max_depth", []), line_level, 300.0)


static func capacity(shop: Dictionary, hook_level: int) -> int:
	var hook: Dictionary = shop.get("upgrades", {}).get("hook", {})
	return maxi(1, int(value_at(hook.get("capacity", []), hook_level, 1.0)))


static func sink_scale(shop: Dictionary, rod_level: int) -> float:
	var rod: Dictionary = shop.get("upgrades", {}).get("rod", {})
	return value_at(rod.get("sink_scale", []), rod_level, 1.0)


## 升到下一级要多少饭钱，满级返回 -1。
static func next_price(shop: Dictionary, key: String, level: int) -> int:
	var up: Dictionary = shop.get("upgrades", {}).get(key, {})
	var levels: Array = up.get("levels", [])
	if level + 1 >= levels.size():
		return -1
	return int(levels[level + 1])
