## ShopScreen —— 商人的摊子。
##
## 层：phase2/ui（允许用一期共用件）
## 依赖：UIKit / Palette / Progress / Ledger / DiveTuning
##
## 玩法位置：港口点商人打开。三档升级 + 卖杂物。
## 不做独立场景，就一张浮在港口上的卡，点「走了」收起。
class_name ShopScreen
extends Control

signal closed()

const UPGRADE_LABELS := {
	"line": "鱼线",
	"hook": "鱼钩",
	"rod": "钓竿",
}
const UPGRADE_NOTES := {
	"line": "线越长，能下得越深。",
	"hook": "钩越大，一趟能多带几件。",
	"rod": "竿越好，下坠更稳、收线更快。",
}

var progress: Progress
var _affinity: Dictionary = {}
var ledger: Ledger = null
var shop_table: Dictionary = {}

var _col: VBoxContainer = null


func setup(p: Progress, lg: Ledger) -> void:
	_affinity = AffinityBook.load_table()
	progress = p
	ledger = lg
	shop_table = DiveTuning.read_json(DiveTuning.SHOP_PATH)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var card := UIKit.card()
	card.position = Vector2(300, 70)
	card.custom_minimum_size = Vector2(680, 600)
	add_child(card)

	_col = VBoxContainer.new()
	_col.position = Vector2(28, 22)
	_col.custom_minimum_size = Vector2(624, 0)
	_col.add_theme_constant_override("separation", 8)
	card.add_child(_col)


func open() -> void:
	visible = true
	rebuild()


func close() -> void:
	visible = false
	closed.emit()


func rebuild() -> void:
	if _col == null:
		return
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()

	_col.add_child(UIKit.label(tr("商 人"), 26, Palette.INK))
	_col.add_child(UIKit.label(tr("token %d") % ledger.money(), 15, Palette.ACCENT_DEEP))
	_col.add_child(UIKit.divider())

	for key in ["line", "hook", "rod"]:
		var lv := progress.upgrade_level(key)
		var price := DiveTuning.next_price(shop_table, key, lv)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var left := VBoxContainer.new()
		left.custom_minimum_size = Vector2(380, 0)
		left.add_theme_constant_override("separation", 2)
		left.add_child(UIKit.label("%s  Lv.%d" % [tr(UPGRADE_LABELS[key]), lv], 16, Palette.INK))
		left.add_child(UIKit.label(tr(UPGRADE_NOTES[key]), 12, Palette.INK_SOFT))
		row.add_child(left)

		if price < 0:
			row.add_child(UIKit.label(tr("已 满"), 14, Palette.INK_FAINT))
		else:
			var buy := UIKit.button(tr("%d token") % price, true, true)
			buy.disabled = ledger.money() < price
			buy.pressed.connect(_on_buy_upgrade.bind(key, price))
			row.add_child(buy)
		_col.add_child(row)

	_col.add_child(UIKit.divider())

	# 渔获：卖给 GPT 才换钱，价格吃的就是好感 buff
	var fish_total := 0
	var fish_worth := 0
	var bonus := AffinityBook.sell_bonus(_affinity, progress)
	for g in DiveSession.FISH_PRICE.keys():
		var n := int(progress.items.get("fish_" + String(g), 0))
		if n <= 0:
			continue
		fish_total += n
		fish_worth += AffinityBook.fish_price(int(DiveSession.FISH_PRICE[g]), bonus) * n
	_col.add_child(UIKit.label(tr("渔获 %d 条") % fish_total, 15, Palette.INK))
	if fish_total > 0:
		_col.add_child(UIKit.label(
			tr("能卖 %d token（好感 +%d%%）") % [fish_worth, int(round(bonus * 100.0))],
			13, Palette.INK_SOFT))
	var sell_fish := UIKit.button(tr("卖 给 商 人"), true, true)
	sell_fish.disabled = fish_total == 0
	sell_fish.pressed.connect(_on_sell_fish)
	_col.add_child(sell_fish)

	_col.add_child(UIKit.divider())

	var junk: int = progress.trinkets.size()
	_col.add_child(UIKit.label(tr("杂物 %d 件") % junk, 15, Palette.INK))
	var sell := UIKit.button(tr("全部卖掉"), false, true)
	sell.disabled = junk == 0
	sell.pressed.connect(_on_sell_all)
	_col.add_child(sell)

	_col.add_child(UIKit.divider())
	var back := UIKit.button(tr("走 了"), false)
	back.pressed.connect(close)
	_col.add_child(back)


func _on_buy_upgrade(key: String, price: int) -> void:
	if not ledger.spend(price):
		return
	progress.set_upgrade_level(key, progress.upgrade_level(key) + 1)
	progress.save()
	rebuild()


func _on_sell_fish() -> void:
	var bonus := AffinityBook.sell_bonus(_affinity, progress)
	var earned := 0
	for g in DiveSession.FISH_PRICE.keys():
		var key := "fish_" + String(g)
		var n := int(progress.items.get(key, 0))
		if n <= 0:
			continue
		earned += AffinityBook.fish_price(int(DiveSession.FISH_PRICE[g]), bonus) * n
		progress.take_item(key, n)
	if earned > 0:
		ledger.earn(earned)
		progress.save()
	rebuild()


func _on_sell_all() -> void:
	var raw_ids = progress.trinkets.duplicate()
	var ids: Array = raw_ids if raw_ids is Array else []
	for id in ids:
		# 杂物统一 40 一碗，M2 再按种类定价
		ledger.sell_trinket(String(id), 40)
	progress.save()
	rebuild()
