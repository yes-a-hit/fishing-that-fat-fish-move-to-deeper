class_name DiveHud
extends Control
## 下潜时的 HUD —— 卷轴式：所有信息压在顶部一条和右侧一竖，中间留给海。

signal surfaced()

const TOP_H := 46.0
const BAR_W := 10.0

var session: DiveSession = null

var _line1: Label = null   # 白饭 · 渔获 · 鱼线剩余
var _line2: Label = null   # 本次最深 · 历史最深 · 预计收益
var _flash_label: Label = null
var _flash_t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var top := Control.new()
	top.name = "Top"
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)

	_line1 = _mk(20, Palette.INK)
	_line2 = _mk(13, Palette.INK_SOFT)
	top.add_child(_line1)
	top.add_child(_line2)

	_flash_label = _mk(20, Palette.ACCENT_DEEP)
	_flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash_label.modulate.a = 0.0
	add_child(_flash_label)

	# 右上角两个入口（占位，先画出来）
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.name = "TopRight"
	add_child(row)
	for txt in ["渔 获", "图 鉴"]:
		var b := UIKit.button(txt, false)
		b.custom_minimum_size = Vector2(84, 34)
		b.disabled = true
		row.add_child(b)

	resized.connect(_layout)


func _mk(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func bind(s: DiveSession) -> void:
	session = s
	visible = true


func _layout() -> void:
	if _line1 == null:
		return
	_line1.position = Vector2(28, 18)
	_line2.position = Vector2(28, 46)
	_flash_label.size = Vector2(size.x, 28)
	_flash_label.position = Vector2(0, size.y * 0.42)
	var row := get_node_or_null("TopRight")
	if row is Control:
		row.position = Vector2(size.x - 200, 58)


func flash(text: String) -> void:
	if _flash_label == null:
		return
	_flash_label.text = text
	_flash_label.modulate.a = 1.0
	_flash_t = 1.8


func _process(delta: float) -> void:
	if not visible:
		return
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_flash_label.modulate.a = 0.0
		elif _flash_t < 0.6:
			_flash_label.modulate.a = _flash_t / 0.6
	if session != null:
		_refresh()
	queue_redraw()


func _refresh() -> void:
	if session == null:
		return
	var cap: int = session.capacity()
	var got: int = session.catches.size() + session.holds.size()
	var left: int = maxi(0, int(session.max_depth() - session.depth))
	_line1.text = "🍚 %d / %d    🪝 %d / %d    🎣 %d m" % [
		session.baits, 3, got, cap, left,
	]
	_line2.text = tr("本次最深 %d m · 历史最深 %d m · 预计 %d 碗") % [
		int(session.deepest), int(progress_deepest()), session.haul_value(),
	]


## 历史最深：拿不到就退回本次，避免 HUD 崩。
func progress_deepest() -> int:
	if session == null:
		return 0
	var p = session.get("progress")
	if p != null:
		var v = p.get("deepest")
		if v != null:
			return int(v)
	return int(session.deepest)


## 右侧那根竖条：从 0 米到底，600 米画一条明暗分界线。
func _draw() -> void:
	if session == null:
		return
	var h := size.y - 180.0
	if h <= 40.0:
		return
	var y0 := 96.0
	var x := size.x - 36.0
	var maxd: float = maxf(1.0, session.max_depth())

	# 轨道
	draw_rect(Rect2(x, y0, BAR_W, h), Color(1, 1, 1, 0.16))
	# 已经下到的部分（从下往上涨）
	var t := clampf(session.depth / maxd, 0.0, 1.0)
	if t > 0.0:
		draw_rect(Rect2(x, y0 + h * (1.0 - t), BAR_W, h * t), Palette.ACCENT)
	# 钩子位置
	var yh := y0 + h * (1.0 - t)
	draw_circle(Vector2(x + BAR_W * 0.5, yh), 4.0, Palette.INK)

	# 600 米明暗线
	var cut := 600.0 / maxd
	if cut < 1.0:
		var yc := y0 + h * (1.0 - cut)
		draw_line(Vector2(x - 7, yc), Vector2(x + BAR_W + 7, yc), Color(0.85, 0.62, 0.25), 1.5)

	# 刻度：0 / 600 / 底
	var font := ThemeDB.fallback_font
	var fs := 11
	for pair in [[0.0, "0"], [600.0, "600"], [maxd, "%d" % int(maxd)]]:
		var d: float = pair[0]
		if d > maxd:
			continue
		var yy := y0 + h * (1.0 - d / maxd)
		draw_line(Vector2(x + BAR_W + 2, yy), Vector2(x + BAR_W + 6, yy), Color(1, 1, 1, 0.5), 1.0)
		draw_string(font, Vector2(x + BAR_W + 9, yy + 4), String(pair[1]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.55))
