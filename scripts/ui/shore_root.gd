extends Control
## 第一章的岸边：第一人称站在水里，手里握着竿。
## 三条肥鱼钓到哪条、还差哪条，一眼看全；一开始全是影子。

const MAIN_SCENE := "res://main.tscn"
const MENU_SCENE := "res://menu.tscn"
const GALLERY_SCENE := "res://gallery.tscn"

const BG_ART := "res://assets/art/cg/ch1/opening/bank.webp"

const FISH := [
	{"id": "small", "name": "小肥鱼", "art": "res://assets/art/cast/ch1/small/default_cut.webp"},
	{"id": "mid", "name": "中肥鱼", "art": "res://assets/art/cast/ch1/mid/default_cut.webp"},
	{"id": "big", "name": "大肥鱼", "art": "res://assets/art/cast/ch1/big/default_cut.webp"},
]

var _shade: ColorRect
var _row: HBoxContainer
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	resized.connect(_layout)


func _build() -> void:
	var bg := TextureRect.new()
	bg.name = "Bg"
	if ResourceLoader.exists(BG_ART):
		bg.texture = load(BG_ART)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_shade = ColorRect.new()
	_shade.color = Color(0.05, 0.08, 0.12, 0.42)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)

	# 左下：三条鱼的收藏进度
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 14)
	add_child(_row)

	for f in FISH:
		_row.add_child(_make_slot(f))

	# 中间：开始钓鱼
	var start := UIKit.button(tr("开 始 钓 鱼"), true)
	start.name = "Start"
	start.custom_minimum_size = Vector2(260, 52)
	start.pressed.connect(func(): ChapterRouter.to_shore(self))
	add_child(start)

	# 右下：图鉴 / 主菜单
	var g := UIKit.button(tr("图 鉴"), false, true)
	g.name = "Gallery"
	g.custom_minimum_size = Vector2(120, 40)
	g.pressed.connect(func(): ChapterRouter.to_gallery(self))
	add_child(g)

	var m := UIKit.button(tr("主 菜 单"), false, true)
	m.name = "Menu"
	m.custom_minimum_size = Vector2(120, 40)
	m.pressed.connect(func(): ChapterRouter.to_menu(self))
	add_child(m)

	_hint = UIKit.label("", 15, Color(0.95, 0.95, 0.96))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(_hint)

	_refresh()


func _make_slot(f: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.custom_minimum_size = Vector2(96, 132)
	box.name = "Slot_" + String(f["id"])

	var pic := TextureRect.new()
	pic.name = "Pic"
	if ResourceLoader.exists(String(f["art"])):
		pic.texture = load(String(f["art"]))
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(96, 96)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)

	var cap := UIKit.label(String(f["name"]), 12, Color(0.92, 0.92, 0.94))
	cap.name = "Cap"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)

	return box


func _refresh() -> void:
	var got := 0
	for f in FISH:
		var id := String(f["id"])
		var unlocked := Gallery.is_unlocked(id)
		if unlocked:
			got += 1
		var box := _row.get_node_or_null("Slot_" + id) as Control
		if box == null:
			continue
		var pic := box.get_node_or_null("Pic") as TextureRect
		var cap := box.get_node_or_null("Cap") as Label
		if pic != null:
			pic.modulate = Color(1, 1, 1) if unlocked else Color(0.34, 0.36, 0.42)
		if cap != null:
			cap.text = String(f["name"]) if unlocked else tr("？")

	if got >= FISH.size():
		_hint.text = tr("三条都上岸了。")
	else:
		_hint.text = tr("还差 %d 条。") % (FISH.size() - got)
	_layout()


func _layout() -> void:
	var s := size
	if s.x <= 1.0:
		return
	_row.position = Vector2(252, s.y - 208)
	if _hint != null:
		_hint.position = Vector2(252, s.y - 242)
		_hint.custom_minimum_size = Vector2(340, 22)
		_hint.size = Vector2(340, 22)

	var start := get_node_or_null("Start") as Control
	if start != null:
		start.position = Vector2((s.x - 260) * 0.5, s.y * 0.62)

	var g := get_node_or_null("Gallery") as Control
	if g != null:
		g.position = Vector2(s.x - 276, s.y - 76)

	var m := get_node_or_null("Menu") as Control
	if m != null:
		m.position = Vector2(s.x - 144, s.y - 76)
