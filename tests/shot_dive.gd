extends SceneTree
## 拍一张下潜界面：看钩子、鱼影、HUD 对不对。
## 用法：godot --path <proj> --script res://tests/shot_dive.gd

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
	if _frames == 130:
		var img := get_root().get_texture().get_image()
		img.save_png("res://.screenshots/21_dive.png")
		print("[shot] 21_dive ok")
		if _node != null:
			get_root().remove_child(_node)
			_node.free()
		quit(0)
	return false
