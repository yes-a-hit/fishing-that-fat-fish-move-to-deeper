extends SceneTree
## DiveRoot 冒烟：能不能实例化、三态能不能切、会不会报错。
## 用法：godot --headless --path <proj> --script res://tests/smoke_dive.gd

var _frames := 0
var _root_node: Node = null


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/dive.tscn")
	if scene == null:
		print("[smoke] dive.tscn 载不进来")
		quit(1)
		return
	_root_node = scene.instantiate()
	get_root().add_child(_root_node)
	print("[smoke] 实例化 ok")


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		var st: int = int(_root_node.get("state"))
		print("[smoke] 初始态 = %d（0=BOAT）" % st)
		if st != 0:
			print("[smoke] 初始态不对")
			quit(1)
			return true
		_root_node.call("_set_state", 1)
	if _frames == 6:
		print("[smoke] 切到 DIVE ok")
		_root_node.call("_set_state", 2)
	if _frames == 9:
		print("[smoke] 切到 RESULT ok")
		_root_node.call("_set_state", 0)
	if _frames == 12:
		var seen: Array = _root_node.get("progress").get("scenery")
		print("[smoke] 景色收集 = %s" % str(seen))
		print("[smoke] pass")
		quit(0)
	return false
