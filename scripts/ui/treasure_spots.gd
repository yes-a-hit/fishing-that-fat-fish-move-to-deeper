class_name TreasureSpots
extends Control
## 场景里那些「藏起来的小玩意儿」：按 treasures.json 的坐标摆透明热区，点中就收进背包。
##
## 用法：
##   var spots := TreasureSpots.new()
##   spots.setup("harbor", progress)
##   spots.picked.connect(func(id, name): ...)
##   add_child(spots)        # 自己铺满父级
##
## 它只认 scene 字段，不认识港口/船头是谁。

signal picked(id: String, name: String)

const PATH := "res://data/phase2/treasures.json"

var _scene_id: String = ""
var _progress: Progress = null
var _spots: Array = []


func setup(scene_id: String, progress: Progress) -> void:
	_scene_id = scene_id
	_progress = progress
	_build()
	resized.connect(_layout)


func _table() -> Dictionary:
	if not ResourceLoader.exists(PATH):
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


func _build() -> void:
	for it in _table().get("items", []):
		if String(it.get("scene", "")) != _scene_id:
			continue
		var tid := String(it.get("id", ""))
		if tid.is_empty():
			continue
		if _progress != null and _progress.trinkets.has(tid):
			continue

		var spot: Array = it.get("spot", [0.5, 0.5])
		var sz: Array = it.get("size", [0.05, 0.05])
		var btn := Button.new()
		btn.name = "Treasure_" + tid
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = String(it.get("hint", ""))
		btn.pressed.connect(_on_pressed.bind(it))
		add_child(btn)
		_spots.append({
			"node": btn,
			"spot": Vector2(float(spot[0]), float(spot[1])),
			"size": Vector2(float(sz[0]), float(sz[1])),
		})


func _on_pressed(it: Dictionary) -> void:
	var tid := String(it.get("id", ""))
	if _progress == null or tid.is_empty():
		return
	if _progress.trinkets.has(tid):
		return
	_progress.add_trinket(tid)
	_progress.mark_trinket_seen(tid)
	_progress.save()
	picked.emit(tid, String(it.get("name", "什么")))


func _layout() -> void:
	for t in _spots:
		var node: Control = t["node"]
		var spot: Vector2 = t["spot"]
		var sz: Vector2 = t["size"]
		node.size = Vector2(sz.x * size.x, sz.y * size.y)
		node.position = Vector2(
			spot.x * size.x - node.size.x * 0.5,
			spot.y * size.y - node.size.y * 0.5,
		)
