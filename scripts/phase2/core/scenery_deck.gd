extends RefCounted
## 西雅图景色的伪随机抽取。
## 不带状态：调用方把上次抽到的 id 传进来，本函数保证「不会连着抽到同一张」。
## 权重来自 data/scenery.json，抽不到（全抽完）时按权重从头来。

class_name SceneryDeck


static func pick(items: Array, rng: RandomNumberGenerator, last_id: String = "") -> String:
	var pool: Array = []
	var total := 0
	for it in items:
		var d: Dictionary = it
		var id := String(d.get("id", ""))
		if id.is_empty() or id == last_id:
			continue
		var w := int(d.get("weight", 1))
		if w <= 0:
			continue
		pool.append({"id": id, "w": w})
		total += w
	if pool.is_empty():
		# 只剩一张（或全被上次挡掉）：直接返回第一张，避免空手
		for it in items:
			var d2: Dictionary = it
			var id2 := String(d2.get("id", ""))
			if not id2.is_empty():
				return id2
		return ""
	var roll := rng.randi_range(1, total)
	for entry in pool:
		roll -= int((entry as Dictionary)["w"])
		if roll <= 0:
			return String((entry as Dictionary)["id"])
	return String((pool[0] as Dictionary)["id"])


static func find(items: Array, id: String) -> Dictionary:
	for it in items:
		var d: Dictionary = it
		if String(d.get("id", "")) == id:
			return d
	return {}
