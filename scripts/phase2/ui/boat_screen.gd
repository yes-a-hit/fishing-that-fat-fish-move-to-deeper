## BoatScreen —— Claude 的船：船头界面。
##
## 层：phase2/ui（允许用一期共用件）
## 依赖：UIKit / Palette / Progress / Ledger
##
## 布局（docs/architecture-phase2.md §9.2）：
##   左下 user 背影  ·  右下 Claude 掌舵  ·  中间种子输入 + 历史坐标
## 本文件只负责「岸上」这一屏：显示、收集输入、把结果交回 DiveRoot。
##
## 注意：整屏靠自己铺满父节点，所有坐标按 size 算，
## 不要在 _ready() 里用 get_viewport_rect()——那时窗口尺寸还没定。
class_name BoatScreen
extends Control

signal dive_requested(seed_text: String)
signal shop_requested()

const USER_ART := "res://assets/art/cast/ch2/user/full.webp"
const CLAUDE_ART := "res://assets/art/cast/ch2/claude/helm.webp"
const DECK_ART := "res://assets/art/cg/ch2/boat/boat_deck.webp"

const POSTCARD_SIZE := Vector2(240, 136)

var progress: Progress = null
var ledger: Ledger = null
var scenery: Array = []
var postcard: Dictionary = {}

var _deck: TextureRect = null
var _shade: ColorRect = null
var _user: Panel = null
var _claude: Panel = null
var _col: VBoxContainer = null
var _history: VBoxContainer = null
var _history_scroll: ScrollContainer = null
var _postcard: TextureRect = null
var _postcard_caption: Label = null
var _seed_x: LineEdit = null
var _seed_y: LineEdit = null
var _money: Label = null
var _plate: Control = null
var _history_plate: Control = null


func setup(p: Progress, lg: Ledger, scenery_items: Array) -> void:
	progress = p
	ledger = lg
	scenery = scenery_items


const _SCENE_ID := "boat"

signal picked(id: String, name: String)
var _treasure_buttons: Array = []
var _treasure_progress: Progress = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_layout()
	resized.connect(_layout)


func _build() -> void:
	_deck = TextureRect.new()
	if ResourceLoader.exists(DECK_ART):
		_deck.texture = load(DECK_ART)
	_deck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_deck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deck)

	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.26)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)

	_user = _make_standing(USER_ART)
	_claude = _make_standing(CLAUDE_ART)

	_col = VBoxContainer.new()
	_col.custom_minimum_size = Vector2(300, 0)
	_col.add_theme_constant_override("separation", 10)
	add_child(_col)

	# 中列垫一层卡，免得白字压在亮甲板上看不清
	_plate = UIKit.card()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)
	move_child(_plate, _col.get_index())

	_col.add_child(UIKit.label(tr("出 海"), 30, Palette.INK))
	_col.add_child(UIKit.wrap_label(tr("克劳德掌舵。你在船头，负责把钩子放下去。"), 15, Palette.INK_SOFT))

	var coord := HBoxContainer.new()
	coord.add_theme_constant_override("separation", 8)
	coord.alignment = BoxContainer.ALIGNMENT_CENTER

	_seed_x = LineEdit.new()
	_seed_x.placeholder_text = tr("ui.coord.x")
	_seed_x.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_x.max_length = 4
	_seed_x.custom_minimum_size = Vector2(120, 0)
	coord.add_child(_seed_x)

	coord.add_child(UIKit.label("—", 16, Palette.INK_SOFT))

	_seed_y = LineEdit.new()
	_seed_y.placeholder_text = tr("ui.coord.y")
	_seed_y.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_y.max_length = 4
	_seed_y.custom_minimum_size = Vector2(120, 0)
	coord.add_child(_seed_y)

	_col.add_child(coord)
	_col.add_child(UIKit.label(tr("ui.coord.hint"), 12, Palette.INK_FAINT))

	# 操作收成一行（icon list 的骨架：图标位留给后续贴图）
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)

	var go := UIKit.button(tr("下 潜"), true)
	go.custom_minimum_size = Vector2(118, 40)
	go.pressed.connect(_on_dive)
	actions.add_child(go)

	var shop := UIKit.button(tr("商 人"), false)
	shop.custom_minimum_size = Vector2(118, 40)
	shop.pressed.connect(func(): shop_requested.emit())
	actions.add_child(shop)

	_col.add_child(actions)

	_money = UIKit.label("", 15, Palette.ACCENT_DEEP)
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(_money)

	_history_plate = UIKit.card()
	_history_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_history_plate)

	_history_scroll = ScrollContainer.new()
	_history_scroll.custom_minimum_size = Vector2(320, 128)
	_history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_history_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_history_scroll)

	_history = VBoxContainer.new()
	_history.custom_minimum_size = Vector2(300, 0)
	_history.add_theme_constant_override("separation", 4)
	_history_scroll.add_child(_history)

	_postcard = TextureRect.new()
	_postcard.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_postcard.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_postcard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_postcard)

	_postcard_caption = UIKit.label("", 13, Palette.INK_SOFT)
	add_child(_postcard_caption)

	_refresh()


func _make_standing(path: String) -> Panel:
	# 立绘是白底不透明的，套一层圆角相框，不然在甲板上像贴纸
	var frame := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.CARD
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 8
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	frame.add_theme_stylebox_override("panel", sb)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var tex := TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.offset_left = 3
	tex.offset_top = 3
	tex.offset_right = -3
	tex.offset_bottom = -3
	if ResourceLoader.exists(path):
		tex.texture = load(path)
	frame.add_child(tex)
	return frame


## 所有位置都从 size 算，窗口一变重排。
func _layout() -> void:
	if _treasure_buttons.is_empty():
		_build_treasures()
	_layout_treasures()
	var s := size
	if s.x < 8.0 or s.y < 8.0:
		return

	_deck.position = Vector2.ZERO
	_deck.size = s
	_shade.position = Vector2.ZERO
	_shade.size = s

	# 左下 user 背影、右下 Claude（身高按屏高比例）
	var uh := s.y * 0.52
	_user.size = Vector2(uh * 0.57, uh)
	_user.position = Vector2(s.x * 0.03, s.y - uh * 0.96)

	var ch := s.y * 0.50
	_claude.size = Vector2(ch * 0.57, ch)
	_claude.position = Vector2(s.x * 0.99 - ch * 0.57, s.y - ch * 0.92)

	# 中间那一列
	var col_w: float = _col.custom_minimum_size.x
	var need: Vector2 = Vector2(col_w, 336.0)
	_col.size = need
	_col.position = Vector2((s.x - col_w) * 0.5, s.y * 0.16)
	if _plate != null:
		var pad := 18.0
		_plate.position = _col.position + Vector2(-pad, -pad)
		_plate.size = Vector2(col_w + pad * 2, need.y + pad * 2)

	var hx: float = s.x * 0.03 + s.y * 0.30 + 16
	_history_scroll.position = Vector2(hx, s.y - 176)
	_history_scroll.size = Vector2(320, 128)
	if _history_plate != null:
		_history_plate.position = _history_scroll.position + Vector2(-14, -12)
		_history_plate.size = Vector2(348, 152)

	_postcard.size = POSTCARD_SIZE
	_postcard.position = Vector2(s.x - POSTCARD_SIZE.x - 28, 16)
	_postcard_caption.position = _postcard.position + Vector2(0, POSTCARD_SIZE.y + 6)


## 这一趟的「明信片」：抽到哪张摆哪张，第一次抽到算新收集。
func show_postcard(item: Dictionary, is_new: bool) -> void:
	postcard = item
	var art := String(item.get("art", ""))
	if _postcard != null and ResourceLoader.exists(art):
		_postcard.texture = load(art)
	if _postcard_caption != null:
		var title := String(item.get("name", ""))
		_postcard_caption.text = (tr("新收集 · %s") % title) if is_new else title


## 账变过（卖杂物、买东西）就刷一次钱和坐标表。
func refresh_money() -> void:
	if _money != null and ledger != null:
		_money.text = tr("token %d") % ledger.money()
	_refresh_history()


func _refresh() -> void:
	refresh_money()


func _refresh_history() -> void:
	if _history == null or progress == null:
		return
	for child in _history.get_children():
		child.queue_free()
	_history.add_child(UIKit.label(tr("去过的坐标"), 13, Palette.INK_SOFT))
	var shown := 0
	for key in progress.seeds.keys():
		if shown >= 5:
			break
		var rec: Variant = progress.seeds[key]
		if not (rec is Dictionary):
			continue
		var d: Dictionary = rec
		var line := "%s   %d/%d  %dm" % [
			String(key), int(d.get("collected", 0)), int(d.get("total", 0)), int(d.get("deepest", 0))]
		_history.add_child(UIKit.label(line, 12, Palette.INK_SOFT))
		shown += 1


func _on_dive() -> void:
	var text := _coord_text().strip_edges()
	dive_requested.emit(text)


## 把 X / Y 两段拼回八位；任意一段为空就当作随机。
func _coord_text() -> String:
	var x := _seed_x.text.strip_edges() if _seed_x != null else ""
	var y := _seed_y.text.strip_edges() if _seed_y != null else ""
	if x.length() != 4 or y.length() != 4:
		return ""
	return x + y


# ---------------- 彩蛋收藏品 ----------------

func _build_treasures() -> void:
	for it in _load_treasures().get("items", []):
		if String(it.get("scene", "")) != _SCENE_ID:
			continue
		var tid := String(it.get("id", ""))
		if tid.is_empty():
			continue
		if _treasure_progress != null and _treasure_progress.trinkets.has(tid):
			continue
		var spot: Array = it.get("spot", [0.5, 0.5])
		var sz: Array = it.get("size", [0.05, 0.05])
		var btn := Button.new()
		btn.name = "Treasure_" + tid
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = String(it.get("hint", ""))
		btn.pressed.connect(_on_treasure_pressed.bind(it))
		add_child(btn)
		_treasure_buttons.append({
			"node": btn,
			"spot": Vector2(float(spot[0]), float(spot[1])),
			"size": Vector2(float(sz[0]), float(sz[1])),
		})


func _load_treasures() -> Dictionary:
	const PATH := "res://data/phase2/treasures.json"
	if not ResourceLoader.exists(PATH):
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


func _on_treasure_pressed(it: Dictionary) -> void:
	var tid := String(it.get("id", ""))
	if _treasure_progress == null or tid.is_empty():
		return
	if _treasure_progress.trinkets.has(tid):
		return
	_treasure_progress.add_trinket(tid)
	_treasure_progress.mark_trinket_seen(tid)
	_treasure_progress.save()
	var nm := String(it.get("name", "什么"))
	picked.emit(tid, nm)


func _layout_treasures() -> void:
	for t in _treasure_buttons:
		var node: Control = t["node"]
		var spot: Vector2 = t["spot"]
		var sz: Vector2 = t["size"]
		node.size = Vector2(sz.x * size.x, sz.y * size.y)
		node.position = Vector2(
			spot.x * size.x - node.size.x * 0.5,
			spot.y * size.y - node.size.y * 0.5,
		)
