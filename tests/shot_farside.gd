extends SceneTree
## 拍「穿透地心」那一幕：把深度硬推到 1205m，看画面是不是翻过来了。
## 用法：godot --path <proj> --script res://tests/shot_farside.gd

var _frames := 0
var _node: Node = null


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/dive.tscn")
	_node = scene.instantiate()
	get_root().add_child(_node)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 6:
		_node.call("_on_dive_requested", "abcd1234")
	if _frames == 20:
		var s: DiveSession = _node.get("session")
		if s != null:
			s.set("_max_depth", 1300.0)
			s.depth = 1205.0
			s.deepest = 1205
		print("[shot] 推到 1205m")
	if _frames == 40:
		get_root().get_texture().get_image().save_png("res://.screenshots/22_farside.png")
		print("[shot] 22_farside ok")
		if _node != null:
			get_root().remove_child(_node)
			_node.free()
		quit(0)
	return false
