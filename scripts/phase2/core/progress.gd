## Progress —— 二期存档：章节/解锁/好感/仓库/升级/种子历史
## 层：phase2/core（纯逻辑，不碰节点与 autoload）
## 依赖：只允许 ConfigLoader（读数据）、FileAccess（仅本文件）
class_name Progress
extends RefCounted

## 存档路径。测试里可以指到临时文件，别污染真档。
const PATH := "user://phase2.json"
const VERSION := 1

## 章节表：id → 显示名与解锁条件。条件为 "always" 或 "cleared:<chapter>"。
const CHAPTERS := {
	"ch1": {"title": "第一章 · 河", "unlock": "always"},
	"ch2": {"title": "第二章 · 深海", "unlock": "cleared:ch1"},
}

var path: String = PATH
var chapter: Dictionary = {}      # id → {cleared, cleared_count, best_score, best_depth}
var characters: Dictionary = {}   # id → {first_caught, caught_count}
var affinity: Dictionary = {}     # id → 0..100
var seeds: Dictionary = {}        # "3F7A1C09" → {collected, total, deepest, ai_seen, ai_caught}
var upgrades: Dictionary = {}     # hook/rod/line → 0..4
var items: Dictionary = {}        # 道具 id → 数量
var trinkets: Dictionary = {}     # 杂物 id → 累计数量
var trinkets_seen: Array = []     # 触发过支线的杂物 id
var scenery: Array = []           # 抽到过的景色 id（大洋彼岸的景色）
var money: int = 0
var best_score: int = 0          # 全局最高分（训练 / 下潜都记）


static func load_or_new(file_path: String = PATH) -> Progress:
	var p := Progress.new()
	p.path = file_path
	p._read()
	return p


# ---------- 读写 ----------

func _read() -> void:
	var data: Dictionary
	if path == PATH:
		# 正式档：从统一的 save.json 里拿 ch2 这一段
		data = SaveFile.read_section("ch2")
		if data.is_empty():
			return
	else:
		# 测试用临时路径：还是自己一个文件，别碰正式档
		if not FileAccess.file_exists(path):
			return
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			return
		var raw := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(raw)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("[progress] 存档读不出来，按新档处理")
			return
		data = parsed
	chapter = _dict(data.get("chapter", {}))
	characters = _dict(data.get("characters", {}))
	affinity = _dict(data.get("affinity", {}))
	seeds = _dict(data.get("seeds", {}))
	upgrades = _dict(data.get("upgrades", {}))
	items = _dict(data.get("items", {}))
	trinkets = _dict(data.get("trinkets", {}))
	money = int(data.get("money", 0))
	for t in data.get("trinkets_seen", []):
		trinkets_seen.append(String(t))
	for s in data.get("scenery", []):
		scenery.append(String(s))
	best_score = int(data.get("best_score", 0))


func save() -> bool:
	# 网页版不落盘：itch 的 iframe 里存档留不住，别假装能留
	if OS.has_feature("web"):
		return false
	if path == PATH:
		# 正式档：只替换 ch2 这一段，别的段（图鉴/设置/记录）原样留着
		return SaveFile.write_section("ch2", _payload())

	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("[progress] 存档写不进去：%s" % path)
		return false
	f.store_string(JSON.stringify(_payload(), "\t"))
	f.close()
	return true


## 这个对象的全部字段，存盘用。
func _payload() -> Dictionary:
	return {
		"version": VERSION,
		"chapter": chapter,
		"characters": characters,
		"affinity": affinity,
		"seeds": seeds,
		"upgrades": upgrades,
		"items": items,
		"trinkets": trinkets,
		"trinkets_seen": trinkets_seen,
		"scenery": scenery,
		"best_score": best_score,
		"money": money,
	}


func reset() -> void:
	chapter.clear()
	characters.clear()
	affinity.clear()
	seeds.clear()
	upgrades.clear()
	items.clear()
	trinkets.clear()
	trinkets_seen.clear()
	scenery.clear()
	money = 0


# ---------- 章节 ----------

func chapter_cleared(id: String) -> bool:
	return bool(_dict(chapter.get(id, {})).get("cleared", false))


func chapter_unlocked(id: String) -> bool:
	var rule := String(_dict(CHAPTERS.get(id, {})).get("unlock", "always"))
	if rule == "always":
		return true
	if rule.begins_with("cleared:"):
		return chapter_cleared(rule.substr(8))
	return false


## 一期通关（钓满三条）时调一次。通关第一章就解锁第二章。
func mark_cleared(id: String, score: int = 0, depth: int = 0) -> void:
	var c := _dict(chapter.get(id, {}))
	c["cleared"] = true
	c["cleared_count"] = int(c.get("cleared_count", 0)) + 1
	c["best_score"] = maxi(int(c.get("best_score", 0)), score)
	c["best_depth"] = maxi(int(c.get("best_depth", 0)), depth)
	chapter[id] = c


func chapter_list() -> Array:
	## 给菜单用：按 CHAPTERS 的顺序，带上解锁/通关状态。
	var out: Array = []
	for id in CHAPTERS.keys():
		var meta := _dict(CHAPTERS[id])
		out.append({
			"id": id,
			"title": String(meta.get("title", id)),
			"unlocked": chapter_unlocked(id),
			"cleared": chapter_cleared(id),
		})
	return out


# ---------- 角色与好感 ----------

func catch_character(id: String) -> int:
	var c := _dict(characters.get(id, {}))
	c["caught_count"] = int(c.get("caught_count", 0)) + 1
	c["first_caught"] = true
	characters[id] = c
	return int(c["caught_count"])


func character_caught(id: String) -> bool:
	return bool(_dict(characters.get(id, {})).get("first_caught", false))


func affinity_of(id: String) -> int:
	return int(affinity.get(id, 0))


## 加好感，返回新值。上不封顶到 100。
func set_affinity(id: String, value: int) -> void:
	affinity[id] = clampi(value, 0, 100)


func add_affinity(id: String, amount: int) -> int:
	var v := clampi(affinity_of(id) + amount, 0, 100)
	affinity[id] = v
	return v


# ---------- 种子 ----------

func seed_record(text: String) -> Dictionary:
	return _dict(seeds.get(text, {}))


func remember_seed(text: String, collected: int, total: int, deepest: int) -> void:
	var r := seed_record(text)
	r["collected"] = maxi(int(r.get("collected", 0)), collected)
	r["total"] = maxi(int(r.get("total", 0)), total)
	r["deepest"] = maxi(int(r.get("deepest", 0)), deepest)
	seeds[text] = r


func mark_seed_ai(text: String, id: String, caught: bool) -> void:
	var r := seed_record(text)
	var seen: Array = r.get("ai_seen", [])
	if not seen.has(id):
		seen.append(id)
	if caught:
		var got: Array = r.get("ai_caught", [])
		if not got.has(id):
			got.append(id)
		r["ai_caught"] = got
	r["ai_seen"] = seen
	seeds[text] = r


# ---------- 钱与升级 ----------

func add_money(amount: int) -> void:
	money = maxi(money + amount, 0)


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


func set_upgrade_level(id: String, level: int) -> void:
	upgrades[id] = maxi(level, 0)


func add_item(id: String, n: int = 1) -> void:
	items[id] = int(items.get(id, 0)) + n


func take_item(id: String, n: int = 1) -> bool:
	var have := int(items.get(id, 0))
	if have < n:
		return false
	items[id] = have - n
	return true


func add_trinket(id: String) -> int:
	trinkets[id] = int(trinkets.get(id, 0)) + 1
	return int(trinkets[id])


func trinket_count(id: String) -> int:
	return int(trinkets.get(id, 0))


func take_trinket(id: String, n: int = 1) -> bool:
	var have := trinket_count(id)
	if have < n:
		return false
	trinkets[id] = have - n
	return true


func mark_trinket_seen(id: String) -> void:
	if not trinkets_seen.has(id):
		trinkets_seen.append(id)


# ---------- 景色 ----------

## 抽到一张景色就记一笔，重复不追加。返回是否是新的一张。
func mark_scenery_seen(id: String) -> bool:
	if id.is_empty() or scenery.has(id):
		return false
	scenery.append(id)
	return true


func scenery_seen(id: String) -> bool:
	return scenery.has(id)


# ---------- 小工具 ----------

func _dict(v) -> Dictionary:
	return v if typeof(v) == TYPE_DICTIONARY else {}


## 记一笔最高分；刷新了返回 true。
func mark_best(score: int) -> bool:
	if score > best_score:
		best_score = score
		return true
	return false
