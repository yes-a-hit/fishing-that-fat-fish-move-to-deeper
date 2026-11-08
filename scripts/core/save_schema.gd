class_name SaveSchema
extends RefCounted
## 存档的唯一查询层。
##
## 底下仍然是两个文件（user://gallery.json 管一期的剧情/结局，user://phase2.json 管二期的进度），
## 但「第一章算不算通关」「开场播没播」这类判断只有一份实现，谁要问都问这里。
## 这样加一个结局、改一条解锁规则，只动这个文件，不用去各个界面里翻条件。

## 一期所有结局的 id（顺序跟 endings.json 的 _order 一致）。
static func ending_ids() -> Array:
	var data := ConfigLoader.load_endings()
	var order: Variant = data.get("_order", [])
	if order is Array and not (order as Array).is_empty():
		return order
	# 兜底：没有 _order 就把非下划线开头的 key 都算上
	var out: Array = []
	for k in data.keys():
		if String(k).begins_with("_"):
			continue
		out.append(String(k))
	return out


## 一期有没有拿到过任何一个结局。
static func any_ending_unlocked() -> bool:
	for id in ending_ids():
		if Gallery.is_unlocked(String(id)):
			return true
	return false


## 第一章算不算「打完了」。判定顺序：
## 1. 二期进度里明确记过 ch1 通关
## 2. 一期拿到过任意结局（不只「齐鱼之福」——私奔、白饭来咯、饿着都算）
static func chapter1_cleared(p2: Progress = null) -> bool:
	var prog: Progress = p2
	if prog == null:
		prog = Progress.load_or_new()
	if prog.chapter_cleared("ch1"):
		return true
	return any_ending_unlocked()


## 开场剧情播过没有。
static func opening_done() -> bool:
	return Gallery.story_done("opening")


## 任意一段剧情播过没有（读的是同一张表）。
static func story_done(id: String) -> bool:
	return Gallery.story_done(id)


## 已经拿到几个结局。
static func unlocked_ending_count() -> int:
	var n := 0
	for id in ending_ids():
		if Gallery.is_unlocked(String(id)):
			n += 1
	return n


## 从头开始：一期的结局/剧情队列、二期的进度，全部清掉。
## 只给「新游戏」用，别的地方不许调。
static func wipe_all(p2: Progress = null) -> void:
	Gallery.clear()
	var prog: Progress = p2
	if prog == null:
		prog = Progress.load_or_new()
	prog.reset()
	prog.save()


## ── 以下给界面用：界面只问「能不能」，不自己拼条件 ──

## 「回 房 间」该不该出现：某个角色有 private 形态、且那条解锁规则满足了。
## 界面不用知道 cast_forms.json 长什么样。
static func room_unlocked(p2: Progress = null) -> bool:
	var table := ConfigLoader.load_cast_forms()
	for cid in table.keys():
		var entry: Dictionary = table[cid]
		for f in entry.get("forms", []):
			if not bool(f.get("private", false)):
				continue
			if ConfigLoader.form_unlocked(f, p2):
				return true
	return false


## 这个角色玩家认识没有（钓到过 / 一期的人开局就在）。
static func character_known(id: String, p2: Progress = null) -> bool:
	if id in ["big", "mid", "small", "doubao", "claude"]:
		return true
	var prog: Progress = p2
	if prog == null:
		prog = Progress.load_or_new()
	return prog.character_caught(id) or int(prog.characters.get(id, 0)) > 0
