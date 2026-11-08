class_name RunSettlement
extends RefCounted
## 一趟出海的收尾：把 session 里的东西落进存档。
##
## 只认 Progress / DiveSession，不碰任何界面。
## 界面只管「收完线要切到哪一屏」。


## 把这一趟的渔获、最深、钓到的角色写进存档，并把鱼按等级塞进背包。
## 返回本次实际入库的鱼（{grade: 数量}），界面要显示的话直接拿去用。
static func settle(progress: Progress, session: DiveSession, seed_text: String) -> Dictionary:
	if progress == null or session == null:
		return {}

	# 1) 鱼按等级计数 —— 不直接换钱，得回码头卖给商人
	var load := {}
	for c in session.all_fish():
		var g := String(session.fish_grade(c))
		load[g] = int(load.get(g, 0)) + 1
	for g in load.keys():
		progress.add_item("fish_" + String(g), int(load[g]))

	# 2) 种子档案：最深取更深的，收集数累加
	var rec: Variant = progress.seeds.get(seed_text)
	if rec is Dictionary:
		var d: Dictionary = rec
		d["deepest"] = maxi(int(d.get("deepest", 0)), session.deepest)
		d["collected"] = int(d.get("collected", 0)) + session.all_fish().size()
		progress.seeds[seed_text] = d

	# 3) 钓到的角色：计数 + 好感
	for c in session.all_fish():
		var id := String((c as Dictionary).get("id", ""))
		if id.is_empty():
			continue
		progress.catch_character(id)
		progress.add_affinity(id, 2)

	# 4) 分数换一点点 token，同时记最高分
	progress.add_money(maxi(1, session.score / 60))
	progress.mark_best(session.score)
	progress.save()
	return load
