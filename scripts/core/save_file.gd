class_name SaveFile
extends RefCounted
## 全游戏只有一个存档文件：`user://save.json`。
##
## 里面按段放东西，谁也别再自己开一个文件：
##   meta      版本号、最后一次玩的时间
##   ch1       第一章（三条鱼的图鉴、结局、分数记录）
##   ch2       第二章（进度、好感、种子、背包、token）
##   gallery   图鉴解锁与剧情已读
##   settings  音量、语言、显示角色名字
##
## 老版本散着四个文件，第一次读到的时候自动搬进来（旧文件留着当备份，
## 不删——万一搬坏了还能手工救回来）。

const VERSION := 2

## 三个手动槽 + 一个自动槽
const SLOT_COUNT := 3
const AUTO_SLOT := 0
const DIR := "user://saves"

## 老版本的单一存档，只用来往 1 号槽搬家
const LEGACY_SINGLE := "user://save.json"

## 当前在用哪个槽。进游戏前由存档页设好。
static var slot: int = 1


## 槽位 → 文件路径
static func path_of(n: int) -> String:
	if n == AUTO_SLOT:
		return DIR + "/auto.json"
	return DIR + "/slot_%d.json" % n


static func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(DIR):
		DirAccess.make_dir_recursive_absolute(DIR)


## 这个槽有没有东西
static func has_save(n: int) -> bool:
	return FileAccess.file_exists(path_of(n))


## 列三个槽的摘要，给存档页用。没存档的返回 null 项。
static func list_slots() -> Array:
	var out := []
	for i in range(1, SLOT_COUNT + 1):
		out.append(summary_of(i))
	return out


## 一个槽的摘要：{slot, exists, money, endings, deepest, saved_at}
static func summary_of(n: int) -> Dictionary:
	var info := {"slot": n, "exists": false, "money": 0, "endings": 0, "deepest": 0, "saved_at": ""}
	var path := path_of(n)
	if not FileAccess.file_exists(path):
		return info
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return info
	var raw := f.get_as_text()
	f.close()
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		return info

	info["exists"] = true
	var ch2 = data.get("ch2", {})
	if typeof(ch2) == TYPE_DICTIONARY:
		info["money"] = int(ch2.get("money", 0))
		info["deepest"] = int(ch2.get("best_score", 0))
	var meta = data.get("meta", {})
	if typeof(meta) == TYPE_DICTIONARY:
		info["saved_at"] = String(meta.get("saved_at", ""))
	var gallery = data.get("gallery", {})
	if typeof(gallery) == TYPE_DICTIONARY:
		info["endings"] = int(gallery.get("ending_count", 0))
	return info


## 删掉一个槽
static func delete_slot(n: int) -> bool:
	var path := path_of(n)
	if not FileAccess.file_exists(path):
		return false
	DirAccess.remove_absolute(path)
	return true

## 老文件 → 新段名
const LEGACY := {
	"user://phase2.json": "ch2",
	"user://gallery.json": "gallery",
	"user://settings.json": "settings",
	"user://record.json": "ch1",
}


static func _blank() -> Dictionary:
	return {"meta": {"version": VERSION}, "ch1": {}, "ch2": {}, "gallery": {}, "settings": {}}


## 读整个文件；不存在就新建（并把老文件搬进来）。
static func read_all() -> Dictionary:
	var _p := path_of(slot)
	if not FileAccess.file_exists(_p):
		var fresh := _blank()
		_migrate_legacy(fresh)
		write_all(fresh)
		return fresh

	var f := FileAccess.open(_p, FileAccess.READ)
	if f == null:
		return _blank()
	var raw := f.get_as_text()
	f.close()
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("[save] 槽 %d 读不出来，按新档处理" % slot)
		return _blank()

	# 缺的段补上，别让调用方到处判空
	var blank := _blank()
	for key in blank.keys():
		if not data.has(key):
			data[key] = blank[key]
	return data


static func write_all(data: Dictionary) -> bool:
	_ensure_dir()
	if OS.has_feature("web"):
		return false    # 网页版不落盘
	var f := FileAccess.open(path_of(slot), FileAccess.WRITE)
	if f == null:
		push_warning("[save] 写不进去：%s" % path_of(slot))
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true


static func read_section(key: String) -> Dictionary:
	var all := read_all()
	var v = all.get(key, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}


static func write_section(key: String, value: Dictionary) -> bool:
	var all := read_all()
	all[key] = value
	return write_all(all)


## 把老的四个文件搬进新档。已经搬过就不重复搬。
static func _migrate_legacy(target: Dictionary) -> void:
	for old_path in LEGACY.keys():
		var section: String = LEGACY[old_path]
		if not FileAccess.file_exists(old_path):
			continue
		var f := FileAccess.open(old_path, FileAccess.READ)
		if f == null:
			continue
		var raw := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			target[section] = parsed
			print("[save] 迁移 %s → %s" % [old_path, section])
