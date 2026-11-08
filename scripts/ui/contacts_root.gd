extends Control
## 通讯录：做成一台手机的相册/联系人。
## 钓到的显示头像与本人一句，没钓到的只有一个灰块和「别人转述的一句线索」。

const DATA := "res://data/phase2/contacts.json"
const PORTRAIT := "res://assets/art/cast/ch2/%s/full_cut.webp"
const CH1_PORTRAIT := "res://assets/art/cast/ch1/%s/default_cut.webp"

signal closed()

var _rows: VBoxContainer
var _phone: PanelContainer
var _list: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.06, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_phone = UIKit.card(Color(0.10, 0.11, 0.14, 0.98))
	add_child(_phone)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_phone.add_child(col)

	col.add_child(UIKit.label(tr("通 讯 录"), 22, Color(0.96, 0.97, 1.0)))
	col.add_child(UIKit.divider())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	_rows.custom_minimum_size = Vector2(420, 0)
	scroll.add_child(_rows)

	var back := UIKit.button(tr("关 上"), false)
	back.pressed.connect(func(): closed.emit())
	col.add_child(back)

	_load()
	_build()
	resized.connect(_layout)
	call_deferred("_layout")


func _load() -> void:
	var f := FileAccess.open(DATA, FileAccess.READ)
	if f == null:
		return
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		_list = parsed.get("characters", [])


func _is_known(id: String) -> bool:
	return SaveSchema.character_known(id)


func _portrait_of(id: String) -> String:
	# 克劳德的立绘不叫 full_cut，单独认一下
	if id == "claude":
		for cand in ["res://assets/art/cast/ch2/claude/helm_cut.webp",
				"res://assets/art/cast/ch1/claude/adult_cut.webp"]:
			if ResourceLoader.exists(cand):
				return cand
	var p := PORTRAIT % id
	if ResourceLoader.exists(p):
		return p
	var q := CH1_PORTRAIT % id
	if ResourceLoader.exists(q):
		return q
	return ""


func _build() -> void:
	for it in _list:
		var id := String(it.get("id", ""))
		var known := _is_known(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		# 一格头像位：认识的放立绘，没见过的放灰块，二者只出现一个
		if known:
			var face := TextureRect.new()
			face.custom_minimum_size = Vector2(64, 64)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var path := _portrait_of(id)
			if path != "":
				face.texture = load(path)
			row.add_child(face)
		else:
			var block_bg := ColorRect.new()
			block_bg.custom_minimum_size = Vector2(64, 64)
			block_bg.color = Color(0.16, 0.16, 0.19)
			row.add_child(block_bg)

		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := tr(String(it.get("name", "?"))) if known else tr("？ ？ ？")
		text.add_child(UIKit.label(title, 15, Color(0.96, 0.97, 1.0) if known else Color(0.55, 0.57, 0.62)))
		var line := String(it.get("line", "")) if known else String(it.get("locked", ""))
		var sub := UIKit.wrap_label(tr(line), 12, Color(0.72, 0.75, 0.82) if known else Color(0.48, 0.50, 0.56))
		text.add_child(sub)
		row.add_child(text)

		_rows.add_child(row)


func _layout() -> void:
	if _phone == null:
		return
	var s := size
	var w := 460.0
	var h := minf(s.y - 80, 640.0)
	_phone.size = Vector2(w, h)
	_phone.position = Vector2((s.x - w) * 0.5, (s.y - h) * 0.5)
