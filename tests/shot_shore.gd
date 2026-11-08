extends SceneTree
## 拍岸边。用法：godot --path <proj> --script res://tests/shot_shore.gd

var _frames := 0
var _node: Node = null


func _initialize() -> void:
	var scene: PackedScene = load("res://shore.tscn")
	_node = scene.instantiate()
	get_root().add_child(_node)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 24:
		get_root().get_texture().get_image().save_png("res://.screenshots/17_shore.png")
		print("[shot] 17_shore ok")
		if _node != null:
			get_root().remove_child(_node)
			_node.free()
		quit(0)
	return false
