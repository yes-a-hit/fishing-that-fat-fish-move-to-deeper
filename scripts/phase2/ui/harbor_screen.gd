## HarborScreen —— 港口：靠点人推进，不用菜单。
##
## 层：phase2/ui（允许用一期共用件）
## 依赖：UIKit / Palette / Progress / Ledger
##
## 设计（m07091）：
##   · 主菜单只留快捷功能（图鉴/设置/退出），具体互动全靠点 NPC。
##   · 港口里站着：商人、Claude、大肥鱼、中肥鱼，点谁跟谁说话。
##   · 点船 = 上船，坐标在船上调。
class_name HarborScreen
extends Control

signal contacts_requested
signal gallery_requested
signal settings_requested
signal board_requested()        # 点船
signal merchant_requested()
signal training_requested()
signal room_requested()
signal back_requested()     # 点商人
signal talked(who: String)      # 点其它 NPC

const BG_ART := "res://assets/art/cg/ch2/boat/harbor_street.webp"
const MERCHANT_ART := "res://assets/art/cast/ch2/chatgpt/full_cut.webp"
const MERCHANT_HOODED := "res://assets/art/cast/ch2/chatgpt/hooded_cut.webp"


## 好感没到就是兜帽神秘人，认识之后才露脸。
func _merchant_art() -> String:
	var p2 := Progress.load_or_new()
	if GptStage.stage_of(p2) <= 0:
		return MERCHANT_HOODED
	return MERCHANT_ART
const CLAUDE_ART := "res://assets/art/cast/ch2/claude/helm_cut.webp"
const BIG_ART := "res://assets/art/cast/ch1/big/default_cut.webp"
const MID_ART := "res://assets/art/cast/ch1/mid/default_cut.webp"
const BOAT_ART := "res://assets/art/cg/ch2/boat/boat_moored.webp"

var progress: Progress = null
var ledger: Ledger = null

var _bg: TextureRect = null
var _shade: ColorRect = null
var _line: Label
var _bar: HBoxContainer
var _show_names: bool = true
var _money: Label
var _top_bar: HBoxContainer
var _top_gallery: Button
var _top_settings: Button
var _top_contacts: Button = null
var _people: Array = []


func setup(p: Progress, lg: Ledger) -> void:
	progress = p
	ledger = lg


const _SCENE_ID := "harbor"

signal picked(id: String, name: String)
var _treasure_spots: TreasureSpots = null

func _ready() -> void:
	picked.connect(func(_id, nm): _set_line(tr("拿到：%s") % nm))
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_bg = TextureRect.new()
	if ResourceLoader.exists(BG_ART):
		_bg.texture = load(BG_ART)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_shade = ColorRect.new()
	_shade.color = Color(0.02, 0.04, 0.07, 0.45)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)

	_top_bar = HBoxContainer.new()
	_top_bar.add_theme_constant_override("separation", 10)
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top_bar)

	_top_contacts = _top_btn(tr("通 讯"))
	_top_contacts.pressed.connect(func(): contacts_requested.emit())
	_top_bar.add_child(_top_contacts)
	_top_gallery = _top_btn(tr("图 鉴"))
	_top_gallery.pressed.connect(func(): gallery_requested.emit())
	_top_bar.add_child(_top_gallery)
	_top_settings = _top_btn(tr("设 置"))
	_top_settings.pressed.connect(func(): settings_requested.emit())
	_top_bar.add_child(_top_settings)

	_money = UIKit.label("", 15, Palette.ON_DARK)
	add_child(_money)

	_line = UIKit.label(tr("港口很安静。点船上船，点人说话。"), 16, Palette.ON_DARK)
	add_child(_line)

	# 底部快捷栏：回河边 / 上船 / 训练（回房间解锁后自动多一格）
	_bar = HBoxContainer.new()
	_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_bar.add_theme_constant_override("separation", 34)
	add_child(_bar)

	# 四个 NPC + 一艘船，全部是「点一下」
	_add_person("merchant", _merchant_art(), tr("商人"), Vector2(0.875, 0.585), 0.40,
		func(): merchant_requested.emit(), tr("商人：涨价了。别问为什么。"))
	_add_person("claude", CLAUDE_ART, tr("克劳德"), Vector2(0.245, 0.615), 0.44,
		func(): board_requested.emit(), tr("克劳德：掌舵的是我。点我就走。"))
	_add_person("big", BIG_ART, tr("大肥鱼"), Vector2(0.455, 0.60), 0.40,
		func(): talked.emit("big"), tr("大肥鱼：……今天也去？"), true)
	_add_person("mid", MID_ART, tr("中肥鱼"), Vector2(0.575, 0.665), 0.359,
		func(): talked.emit("mid"), tr("中肥鱼：我帮你看着绳子。"), true)

	var back := _bar_button(tr("回 河 边"), false)
	back.pressed.connect(func(): back_requested.emit())
	_bar.add_child(back)

	var boat := _bar_button(tr("上 船"), true)
	boat.pressed.connect(func(): board_requested.emit())
	_bar.add_child(boat)

	if SaveSchema.room_unlocked():
		var room := _bar_button(tr("回 房 间"), true)
		room.pressed.connect(func(): room_requested.emit())
		_bar.add_child(room)

	var train := _bar_button(tr("训 练"), false)
	train.pressed.connect(func(): training_requested.emit())
	_bar.add_child(train)

	_show_names = GameSettings.load_settings().show_names
	_layout()
	resized.connect(_layout)


## 底部栏里的一格：统一 16 号字，主色留给「上 船」。
func _bar_button(text: String, primary: bool) -> Button:
	var b := Button.new()
	b.flat = true
	b.text = text
	b.custom_minimum_size = Vector2(96, 40)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color",
			Color(1, 0.92, 0.72) if primary else Color(0.86, 0.90, 0.94))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


func _room_form() -> Dictionary:
	var table := ConfigLoader.load_cast_forms()
	for cid in table.keys():
		var entry = table[cid]
		if not (entry is Dictionary):
			continue
		for f in entry.get("forms", []):
			if bool(f.get("private", false)):
				return f
	return {}


func _top_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.custom_minimum_size = Vector2(64, 34)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color(0.88, 0.90, 0.94))
	b.add_theme_color_override("font_hover_color", Color(1, 0.92, 0.72))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


func _add_person(id: String, art: String, display: String, anchor: Vector2, h_ratio: float,
		cb: Callable, hover_text: String, in_water: bool = false) -> void:
	var frame := Control.new()
	frame.name = id + "_frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	# 脚下一团软阴影：椭圆贴图 + 半透明
	var shadow := TextureRect.new()
	shadow.texture = SceneFx.ripple() if in_water else SceneFx.shadow()
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.modulate = (Color(0.86, 0.94, 1.0, 0.55) if in_water
			else Color(0, 0, 0, 0.62))
	frame.add_child(shadow)
	frame.resized.connect(func():
		if in_water:
			shadow.position = Vector2(frame.size.x * 0.02, frame.size.y * 0.885)
			shadow.size = Vector2(frame.size.x * 0.96, frame.size.y * 0.10)
		else:
			shadow.position = Vector2(frame.size.x * 0.18, frame.size.y * 0.90)
			shadow.size = Vector2(frame.size.x * 0.64, frame.size.y * 0.12)
	)
	shadow.position = Vector2(0, 0)
	shadow.size = Vector2(1, 1)
	if id == "shadow_marker":
		pass

	var btn := TextureButton.new()
	btn.name = id
	if ResourceLoader.exists(art):
		btn.texture_normal = load(art)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.ignore_texture_size = true
	btn.tooltip_text = hover_text
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.offset_left = 4
	btn.offset_top = 4
	btn.offset_right = -4
	btn.offset_bottom = -4
	btn.pressed.connect(cb)
	frame.add_child(btn)

	var name_label := UIKit.label(display, 13, Palette.ON_DARK)
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	# 默认不显示，鼠标移上去才出现；设置里关掉就永远不出现。
	name_label.visible = false
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.mouse_entered.connect(func():
		_set_line(hover_text)
		if _show_names:
			name_label.visible = true
	)
	btn.mouse_exited.connect(func(): name_label.visible = false)
	name_label.add_theme_color_override("font_color", Color(0.97, 0.97, 1.0))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	frame.add_child(name_label)

	_people.append({
		"node": frame,
		"btn": btn,
		"label": name_label,
		"anchor": anchor,
		"h": h_ratio,
		"ratio": 0.62,
	})


func _layout() -> void:
	if _treasure_spots == null:
		_treasure_spots = TreasureSpots.new()
		_treasure_spots.picked.connect(func(_id, nm): _set_line(tr("拿到：%s") % nm))
		add_child(_treasure_spots)
		_treasure_spots.setup(_SCENE_ID, progress)
		_treasure_spots.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_treasure_spots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := size
	if s.x < 8.0 or s.y < 8.0:
		return
	_bg.position = Vector2.ZERO
	_bg.size = s
	_shade.position = Vector2.ZERO
	_shade.size = s
	_money.position = Vector2(28, 22)
	if _top_bar != null:
		_top_bar.position = Vector2(s.x - 248, 18)
		_top_bar.custom_minimum_size = Vector2(160, 36)
	_line.position = Vector2(28, s.y - 96)
	if _bar != null:
		var bw: float = minf(560.0, s.x - 120.0)
		_bar.size = Vector2(bw, 48)
		_bar.position = Vector2((s.x - bw) * 0.5, s.y - 62)

	for p in _people:
		var n: Control = p["node"]
		var h: float = s.y * float(p["h"])
		var w: float = h * float(p["ratio"])
		n.size = Vector2(w, h)
		n.position = Vector2(s.x * float(p["anchor"].x) - w * 0.5, s.y * float(p["anchor"].y) - h * 0.5)
		if p.has("label") and p["label"] != null:
			var lb: Label = p["label"]
			lb.visible = false
			lb.position = Vector2(6, h - 26)
			lb.custom_minimum_size = Vector2(w - 12, 0)


var _line_visible := false


func _set_line(text: String) -> void:
	_line.text = text
	_line.visible = true
	_line_visible = true
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		if _line_visible:
			_line.visible = false
			_line_visible = false
	)
	return
	if _line != null:
		_line.text = text


func refresh() -> void:
	if _money != null and ledger != null:
		_money.text = tr("$ %d") % ledger.money()
