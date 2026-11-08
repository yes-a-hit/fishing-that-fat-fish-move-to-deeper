extends SceneTree
## 拍商店：港口 → 点商人 → 卡片浮出来。
## 用法：godot --path <proj> --script res://tests/shot_shop.gd

var _frames := 0
var _node: Node = null


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/dive.tscn")
	_node = scene.instantiate()
	get_root().add_child(_node)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 10:
		# 给点钱，不然按钮全是灰的，看不出布局
		var p = _node.get("progress")
		if p != null:
			p.call("add_money", 500)
		_node.call("_on_shop")
	if _frames == 26:
		get_root().get_texture().get_image().save_png("res://.screenshots/23_shop.png")
		print("[shot] 23_shop ok")
		if _node != null:
			get_root().remove_child(_node)
			_node.free()
		quit(0)
	return false
