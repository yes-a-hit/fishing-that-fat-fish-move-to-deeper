extends Control

## 主菜单。整个游戏唯一的入口。
##
## 这一页只做一件事：开始。难度和音量都收进 settings.tscn 了 ——
## 首屏摆一排难度按钮和两个滑块，玩家每次进来都得先看一遍噪音。
##
## 难度写进 user://settings.json，game_root 启动时读回来套到 GameTuning 上。

const WORLD_SCENE := "res://world.tscn"
const GAME_SCENE := "res://main.tscn"
const GALLERY_SCENE := "res://gallery.tscn"
const ABOUT_SCENE := "res://about.tscn"
const SETTINGS_SCENE := "res://settings.tscn"
const MAIN_SCENE := "res://main.tscn"
const SHORE_SCENE := "res://shore.tscn"
const DIVE_SCENE := "res://scenes/dive.tscn"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/cg/menu/keyvisual.webp")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_card()


# ---------- 卡片 ----------

var _panel: Control = null
var _col: VBoxContainer = null
var _board: TextureRect = null
var _bottom: HBoxContainer = null


func _build_card() -> void:
	var p2 := Progress.load_or_new()
	var has_save := SaveSchema.chapter1_cleared(p2)

	# 左侧信息板
	_panel = TextureRect.new()
	_panel.texture = _fade_texture()
	_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_panel.stretch_mode = TextureRect.STRETCH_SCALE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	add_child(_col)

	var logo := UIKit.picture_fit("res://assets/art/meta/logo.webp", Vector2(96, 64))
	logo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_col.add_child(logo)

	var title := UIKit.label(tr("钓肥鱼"), 36, Color(0.98, 0.97, 0.94))
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	_col.add_child(title)

	var sub := UIKit.label(tr("蓝色大肥鱼的恋爱请求"), 13, Color(0.72, 0.76, 0.82))
	sub.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_col.add_child(sub)
	_col.add_child(UIKit.spacer(6))
	_col.add_child(UIKit.divider())

	var items: Array = [
		{"text": tr("新 游 戏"), "cb": func(): _on_new_game(p2) if has_save else _start_new(p2), "on": true},
		{"text": tr("继 续 游 戏"), "cb": func(): ChapterRouter.to_saves(self), "on": true},
		{"text": tr("设 置"), "cb": _on_settings, "on": true},
		{"text": tr("画 廊"), "cb": _on_gallery, "on": true},
		{"text": tr("关 于"), "cb": _on_about, "on": true},
		{"text": tr("退 出 游 戏"), "cb": func(): get_tree().quit(), "on": true},
	]
	for it in items:
		var b := UIKit.button(String(it["text"]), bool(it.get("on", true)) and it == items[0])
		b.custom_minimum_size = Vector2(0, 44)
		b.add_theme_font_size_override("font_size", 17)
		b.disabled = not bool(it.get("on", true))
		if not b.disabled:
			b.pressed.connect(it["cb"])
		_col.add_child(b)

		
	# 右侧看板娘
	_board = TextureRect.new()
	_board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_board.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := "res://assets/art/cast/ch1/big/default_cut.webp"
	if ResourceLoader.exists(art):
		_board.texture = load(art)
	add_child(_board)

	resized.connect(_layout)
	_layout()


## 一条从左到右淡出的黑色竖条，比硬边面板舒服。
func _fade_texture() -> ImageTexture:
	var w := 64
	var img := Image.create(w, 4, false, Image.FORMAT_RGBA8)
	for x in w:
		var t := float(x) / float(w - 1)
		# 前 62% 保持住，后面淡到 0
		var a := 1.0 if t < 0.62 else maxf(0.0, 1.0 - (t - 0.62) / 0.38)
		var col := Color(0.05, 0.07, 0.11, a * 0.88)
		for y in 4:
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _layout() -> void:
	if _col == null:
		return
	var s := size
	if s.x <= 0.0:
		s = Vector2(1280, 800)

	var panel_w: float = s.x * 0.30
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(panel_w, s.y)

	var pad: float = 44.0
	_col.position = Vector2(pad, s.y * 0.10)
	_col.size = Vector2(s.x * 0.22 - pad, 0)

	if _board != null:
		_board.visible = false



## 「读取存档」：直接进最远能到的那一章，不给你选。
## 第二章的港口里自己有一条回河边的路。
func _on_continue() -> void:
	var p2 := Progress.load_or_new()
	var target := DIVE_SCENE if SaveSchema.chapter1_cleared(p2) else SHORE_SCENE
	ChapterRouter.go(self, target)


func _on_new_game(p2: Progress) -> void:
	if not SaveSchema.chapter1_cleared(p2):
		_start_new(p2)
		return
	# 已经有进度，问一句再抹
	var dlg := ConfirmationDialog.new()
	dlg.title = tr("新 游 戏")
	dlg.dialog_text = tr("现在的进度会被覆盖。真的从头开始？")
	dlg.ok_button_text = tr("从 头 开 始")
	dlg.cancel_button_text = tr("算 了")
	dlg.confirmed.connect(func():
		_start_new(p2)
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	add_child(dlg)
	dlg.popup_centered()


func _start_new(p2: Progress) -> void:
	# 网页版是最小可运行单元：跳过第一章，直接进港口
	if OS.has_feature("web"):
		ChapterRouter.to_dive(self)
		return
	SaveSchema.wipe_all(p2)
	ChapterRouter.to_shore(self)


func _save_summary(p2: Progress) -> String:
	var ends := SaveSchema.unlocked_ending_count()
	var parts: Array[String] = []
	if ends > 0:
		parts.append(tr("结局 %d") % ends)
	parts.append(tr("token %d") % p2.money)
	return " · ".join(parts)


# ---------- 交互 ----------

## 第一章算不算通关：二期存档里记了就认；没记就看一期图鉴里有没有「齐鱼之福」。
## 这样不用在 game_root / ending_overlay 里加回调，一期依旧只被动了一处。
## 【已弃用】改用 SaveSchema.chapter1_cleared()，留着只是怕别处还在调。
func _chapter_one_done(p2: Progress) -> bool:
	# 判定只留一份：SaveSchema 里看「二期记过 ch1」或「一期拿到过任意结局」
	return SaveSchema.chapter1_cleared(p2)


## 一章一行。四态就四种画法：未解锁（灰、不可点）、可入水（亮、可点）、
## 已通关（灰底但可点，随时能重打）、刚解锁（可入水 + 高亮色，当「新增」提示）。
func _add_chapter_row(parent: Node, p2: Progress, id: String, title: String,
		locked_hint: String, cb: Callable) -> void:
	var unlocked := true
	if id == "ch2":
		unlocked = _chapter_one_done(p2)
	var cleared := p2.chapter_cleared(id)
	var tag := tr("未 解 锁")
	if cleared:
		tag = tr("已 通 关")
	elif unlocked:
		tag = tr("可 入 水")

	var b := UIKit.button("%s　　%s" % [title, tag], unlocked and not cleared)
	b.disabled = not unlocked
	if not unlocked:
		b.tooltip_text = locked_hint
	else:
		b.pressed.connect(cb)
		# 刚解锁还没通关 = 「新增」，用强调色提示一次
		if not cleared:
			b.add_theme_color_override("font_color", Palette.ACCENT_DEEP)
	parent.add_child(b)


func _on_start() -> void:
	ChapterRouter.to_game(self)


func _on_dive() -> void:
	ChapterRouter.to_dive(self)


func _on_gallery() -> void:
	ChapterRouter.to_gallery(self)


func _on_settings() -> void:
	ChapterRouter.to_settings(self)


func _on_about() -> void:
	ChapterRouter.to_about(self)
