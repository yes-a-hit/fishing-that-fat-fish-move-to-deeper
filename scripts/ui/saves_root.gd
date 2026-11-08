extends Control
## 存档页：三格手动槽 + 一格自动存档。
##
## 进来只做两件事：给玩家看「这格里是什么」，让他选「进哪格」或「删哪格」。
## 选完把槽号写进 SaveFile.slot，再交给 ChapterRouter 跳游戏。

const SLOT_W := 520.0
const SLOT_H := 88.0

var _list: VBoxContainer = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/art/cg/menu/keyvisual.webp"):
		bg.texture = load("res://assets/art/cg/menu/keyvisual.webp")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.06, 0.08, 0.12, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := UIKit.card()
	card.custom_minimum_size = Vector2(SLOT_W + 64, 0)
	center.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)

	col.add_child(UIKit.title(tr("存 档"), Palette.F_TITLE))
	col.add_child(UIKit.divider())

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	col.add_child(_list)

	col.add_child(UIKit.divider())
	var back := UIKit.button(tr("返 回"), false)
	back.pressed.connect(func(): ChapterRouter.to_menu(self))
	col.add_child(back)

	_migrate_if_needed()
	_refresh()


## 第一次进存档页时，把老的单文件档搬进 1 号槽，不然玩家会以为存档没了。
func _migrate_if_needed() -> void:
	if SaveFile.has_save(1) or SaveFile.has_save(SaveFile.AUTO_SLOT):
		return
	var old := SaveFile.slot
	SaveFile.slot = 1
	SaveFile.read_all()      # 内部会走 _migrate_legacy 并写出 slot_1.json
	SaveFile.slot = old


func _refresh() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()

	# 自动存档单独一行（只读，不能删）
	_list.add_child(_slot_row(SaveFile.AUTO_SLOT, true))
	for i in range(1, SaveFile.SLOT_COUNT + 1):
		_list.add_child(_slot_row(i, false))


func _slot_row(slot: int, auto: bool) -> Control:
	var info := SaveFile.summary_of(slot)
	var exists: bool = bool(info.get("exists", false))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(SLOT_W, SLOT_H)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 2)

	var title := tr("自动存档") if auto else tr("存档 %d") % slot
	text.add_child(UIKit.label(title, 16, Palette.INK))

	if exists:
		var bits := tr("结局 %d · token %d · 最深 %d") % [
			int(info.get("endings", 0)),
			int(info.get("money", 0)),
			int(info.get("deepest", 0)),
		]
		text.add_child(UIKit.label(bits, 12, Palette.INK_SOFT))
		var when := String(info.get("saved_at", ""))
		if when != "":
			text.add_child(UIKit.label(when, 11, Palette.INK_FAINT))
	else:
		text.add_child(UIKit.label(tr("空"), 12, Palette.INK_FAINT))
	row.add_child(text)

	if exists:
		if not auto:
			var enter := UIKit.button(tr("进 入"), true, true)
			enter.pressed.connect(func(): _enter(slot))
			row.add_child(enter)

			var wipe := UIKit.button(tr("删 除"), false, true)
			wipe.pressed.connect(func(): _erase(slot))
			row.add_child(wipe)
		else:
			var cont := UIKit.button(tr("继 续"), true, true)
			cont.pressed.connect(func(): _enter(slot))
			row.add_child(cont)
	else:
		var fresh := UIKit.button(tr("新 档"), false, true)
		fresh.disabled = auto
		fresh.pressed.connect(func(): _enter(slot))
		row.add_child(fresh)

	return row


func _enter(slot: int) -> void:
	SaveFile.slot = slot
	var p2 := Progress.load_or_new()
	ChapterRouter.go(self, ChapterRouter.chapter_of(p2))


func _erase(slot: int) -> void:
	SaveFile.delete_slot(slot)
	# 删完把指针挪回 1 号，免得停在已经不存在的槽上
	if SaveFile.slot == slot:
		SaveFile.slot = 1
	_refresh()
