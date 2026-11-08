extends SceneTree
## 验证训练模式：港口点训练 → 进 DIVE → 收线 → 最高分刷新。
## 用法：godot --headless --path <proj> --script res://tests/smoke_train.gd

var _frames := 0
var _node: Node = null


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/dive.tscn")
	_node = scene.instantiate()
	get_root().add_child(_node)


func _process(_delta: float) -> bool:
	_frames += 1

	if _frames == 6:
		var p = _node.get("progress")
		p.call("reset")
		p.call("save")
		_node.call("_on_train")
		print("[train] 进入训练，state = ", _node.get("state"))

	if _frames == 10:
		var s = _node.get("session")
		if s != null:
			s.set("score", 1234)
			s.set("deepest", 456)
		_node.call("_on_surface")

	if _frames == 16:
		var p = _node.get("progress")
		print("[train] 最高分 = ", p.get("best_score"))
		print("[train] state = ", _node.get("state"))
		var ok := int(p.get("best_score")) == 1234
		print("[train] ", "pass" if ok else "FAIL")
		if _node != null:
			get_root().remove_child(_node)
			_node.free()
		quit(0 if ok else 1)

	return false
