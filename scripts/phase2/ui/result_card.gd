class_name ResultCard
extends Control
## 上岸结算卡。只负责「把这一趟的数字摆出来 + 四个按钮」，不碰流程。
##
## 用法：
##   var card := ResultCard.new()
##   card.cast_again.connect(...)   # 白饭还有，再来一竿
##   card.finish_trip.connect(...)  # 回码头
##   card.back_to_boat.connect(...) # 整趟结束，再出海
##   card.quit_to_harbor.connect(...)
##   add_child(card)
##   card.show_result(session)

signal cast_again()
signal finish_trip()
signal back_to_boat()
signal quit_to_harbor()

var _session: DiveSession = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var card := UIKit.card()
	card.position = Vector2(200, 120)
	card.custom_minimum_size = Vector2(440, 340)
	add_child(card)

	var col := VBoxContainer.new()
	col.name = "Col"
	col.position = Vector2(24, 20)
	col.custom_minimum_size = Vector2(392, 0)
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)


## 摆一次结算：标题 → 分隔 → 三个数字 → 按钮。
func show_result(dive: DiveSession) -> void:
	_session = dive
	var col := find_child("Col", true, false) as VBoxContainer
	if col == null:
		return
	for c in col.get_children():
		col.remove_child(c)
		c.queue_free()

	col.add_child(UIKit.label(tr("上 岸"), 26, Palette.INK))
	col.add_child(UIKit.divider())

	if dive != null:
		col.add_child(UIKit.label(tr("最深 %d m") % dive.deepest, 16, Palette.INK))
		col.add_child(UIKit.label(tr("得分 %d") % dive.score, 16, Palette.INK))
		col.add_child(UIKit.label(
			tr("捞到 %d 件") % (dive.holds.size() + dive.catches.size()), 16, Palette.INK))
		if dive.secret_found:
			col.add_child(UIKit.label(tr("钩子穿过了地心。"), 14, Palette.ACCENT_DEEP))

	_add_actions(col)


func _add_actions(col: VBoxContainer) -> void:
	var baits_left: int = _session.baits if _session != null else 0
	if baits_left > 0:
		col.add_child(UIKit.label(tr("ui.dive.baits_left") % baits_left, 14, Palette.ACCENT_DEEP))
		var again_bait := UIKit.button(tr("ui.dive.cast_again"), true)
		again_bait.pressed.connect(func(): cast_again.emit())
		col.add_child(again_bait)
		var to_harbor := UIKit.button(tr("ui.dive.to_harbor"), false)
		to_harbor.pressed.connect(func(): finish_trip.emit())
		col.add_child(to_harbor)
		return

	var again := UIKit.button(tr("再 来 一 趟"), true)
	again.pressed.connect(func(): back_to_boat.emit())
	col.add_child(again)

	var quit := UIKit.button(tr("回 港 口"), false)
	quit.pressed.connect(func(): quit_to_harbor.emit())
	col.add_child(quit)
