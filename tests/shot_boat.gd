extends SceneTree
## 拍两张：港口（初始态）与船上（点船之后）。
## 用法：godot --path <proj> --script res://tests/shot_boat.gd

var _frames := 0
var _node: Node = null


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/dive.tscn")
	_node = scene.instantiate()
	get_root().add_child(_node)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 20:
		get_root().get_texture().get_image().save_png("res://.screenshots/19_harbor.png")
		print("[shot] 19_harbor ok")
		_node.call("_on_board")
	if _frames == 40:
		get_root().get_texture().get_image().save_png("res://.screenshots/20_boat.png")
		print("[shot] 20_boat ok")
		if _node != null:
			get_root().remove_child(_node)
			_node.free()
		quit(0)
	return false
