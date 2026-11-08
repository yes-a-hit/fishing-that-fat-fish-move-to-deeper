extends SceneTree
## 验证「大洋彼岸的景色」抽取机制：
## 前四次必须出四张不同的，第五次起回落随机。
## 用法：godot --headless --path <proj> --script res://tests/smoke_scenery.gd

var _frames := 0
var _node: Node = null
var _log: Array = []


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/dive.tscn")
	_node = scene.instantiate()
	get_root().add_child(_node)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames != 8:
		return false

	var p = _node.get("progress")
	p.call("reset")
	p.call("save")

	for i in 8:
		var got: Dictionary = _node.call("_roll_far_side")
		var id := String(got.get("id", ""))
		_log.append(id)
		print("[scenery] 第 %d 抽: %s" % [i + 1, id])

	var first_four := _log.slice(0, 4)
	var unique := {}
	for id in first_four:
		unique[id] = true
	print("[scenery] 前四张去重后 = %d" % unique.size())
	print("[scenery] 已收集 = %s" % str(p.get("scenery")))

	if _node != null:
		get_root().remove_child(_node)
		_node.free()
	quit(0 if unique.size() == 4 else 1)
	return false
