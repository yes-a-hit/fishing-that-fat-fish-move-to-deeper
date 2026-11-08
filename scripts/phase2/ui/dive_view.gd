## DiveView —— 只画世界：水层滚动、钩子、鱼影、明暗。
##
## 层：phase2/ui
## 依赖：DiveSession（只读状态，不许改规则）
##
## 钩子固定在屏幕中偏下，水层往下滚表示在沉。
## 鱼影按「离钩子多少米」折算成像素，越远越靠下。
class_name DiveView
extends Control

const LAYER_SHALLOW := "res://assets/art/cg/ch2/water/layer_shallow.webp"
const LAYER_MID := "res://assets/art/cg/ch2/water/layer_mid.webp"
const LAYER_DEEP := "res://assets/art/cg/ch2/water/layer_deep.webp"
const FAR_SIDE := [
	"res://assets/art/cg/ch2/scenery/seattle_skyline.webp",
	"res://assets/art/cg/ch2/seattle_statue.webp",
	"res://assets/art/cg/ch2/seattle_protest.webp",
	"res://assets/art/cg/ch2/scenery/la_bridge.webp",
]
const SCROLL_SPEED := 190.0
const PX_PER_M := 2.2          # 视野里 1 米折算多少像素

var session: DiveSession = null

var _tiles: Array = []
var _tile_h: float = 720.0
var _current: String = ""
var _flash: ColorRect = null
var _far_side: bool = false
var _far_art: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout_tiles)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.z_index = 20
	add_child(_flash)
	for i in 2:
		var tex := TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_SCALE
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex.z_index = -1
		add_child(tex)
		_tiles.append(tex)


func bind_session(s: DiveSession) -> void:
	session = s
	_current = ""
	_apply_layer("shallow")
	_layout_tiles()


func begin(_seed: int, _progress: Progress) -> void:
	_current = ""
	_apply_layer("shallow")


## 两张图首尾相接铺满屏幕，滚动时循环。窗口一变就重排。
func _layout_tiles() -> void:
	for i in _tiles.size():
		var t: TextureRect = _tiles[i]
		t.size = Vector2(size.x, size.y)
		t.position = Vector2(0, size.y * i)


func _process(delta: float) -> void:
	if not visible:
		return
	if session != null:
		var beyond := session.depth >= DiveSession.SECRET_DEPTH
		if beyond != _far_side:
			_set_far_side(beyond)
		if not _far_side:
			_apply_layer(session.layer_id())
	for i in _tiles.size():
		var t: TextureRect = _tiles[i]
		t.position.x = 0
		t.position.y -= SCROLL_SPEED * delta
		if t.position.y <= -size.y:
			t.position.y += size.y * _tiles.size()
	queue_redraw()


## 穿过地心：画面倒过来，水层换成对面的西雅图。
func _flash_once(duration: float = 0.55) -> void:
	if _flash == null:
		return
	_flash.color = Color(1, 1, 1, 0.92)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT)


func set_far_art(path: String) -> void:
	_far_art = path


func _set_far_side(on: bool) -> void:
	_far_side = on
	if on:
		if _far_art.is_empty():
			_far_art = String(FAR_SIDE[randi() % FAR_SIDE.size()])
		_current = "far"
		if ResourceLoader.exists(_far_art):
			var tex: Texture2D = load(_far_art)
			for t in _tiles:
				(t as TextureRect).texture = tex
				(t as TextureRect).flip_v = true
			_flash_once()
			# 对面的风景是一整张，不要两张叠出接缝
			_tiles[0].position.y = 0
			_tiles[0].size = Vector2(size.x, size.y)
			(_tiles[0] as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			(_tiles[1] as TextureRect).visible = false
	else:
		for t in _tiles:
			(t as TextureRect).flip_v = false
		for t2 in _tiles:
			(t2 as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE
		if _tiles.size() > 1:
			(_tiles[1] as TextureRect).visible = true
		_current = ""
		_apply_layer("shallow")


func _apply_layer(id: String) -> void:
	if id == _current:
		return
	_current = id
	var path := LAYER_SHALLOW
	match id:
		"mid":
			path = LAYER_MID
		"deep":
			path = LAYER_DEEP
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	for t in _tiles:
		(t as TextureRect).texture = tex


func _draw() -> void:
	if session == null:
		return
	var s := size

	# 明暗：600m 以下不开灯就只有一小圈
	var dark := 0.0
	if session.depth >= 600.0:
		dark = 0.55
	if dark > 0.0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, dark), true)

	# 穿透之后整张画面是倒的，钩子也从上面垂下来
	var hook_y := s.y * 0.62
	if _far_side:
		hook_y = s.y * 0.38
	var hook := Vector2(s.x * 0.5, hook_y)
	var line_top := Vector2(hook.x, 0) if not _far_side else Vector2(hook.x, s.y)
	draw_line(line_top, hook, Color(1, 1, 1, 0.45), 2.0)
	draw_circle(hook, 6.0, Color(1, 1, 1, 0.9))
	draw_polyline(PackedVector2Array([
		hook + Vector2(-7, 10), hook + Vector2(0, 20), hook + Vector2(7, 10)]),
		Color(1, 1, 1, 0.8), 2.0)

	# 鱼影：按深度差换算 y，超出视野的不画
	var font := ThemeDB.fallback_font
	for f in session.fish_list():
		var gap: float = float(f["depth"]) - session.depth
		if absf(gap) > s.y * 0.5 / PX_PER_M:
			continue
		var y := hook.y + gap * PX_PER_M * (-1.0 if _far_side else 1.0)
		var alpha := clampf(float(f["ttl"]) / 1.2, 0.0, 1.0)
		var col := Color(0.55, 0.85, 0.95, 0.55 * alpha + 0.15)
		var body := Rect2(Vector2(s.x * 0.5 - 34, y - 8), Vector2(68, 16))
		draw_rect(body, col, true)
		draw_polyline(PackedVector2Array([
			Vector2(body.position.x, y),
			Vector2(body.position.x - 12, y - 8),
			Vector2(body.position.x - 12, y + 8),
			Vector2(body.position.x, y)]), col, 2.0)
		draw_string(font, Vector2(body.position.x, y - 14), String(f["id"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.75))
