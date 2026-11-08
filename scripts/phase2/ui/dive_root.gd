## DiveRoot —— 二期根节点：串起船 → 下潜 → 结算，只做装配。
##
## 层：phase2/ui（允许用一期共用件）
## 依赖：UIKit / Palette / Progress / Ledger / SceneryDeck / DiveSession
##
## 三态机（docs/architecture-phase2.md §9）：
##   BOAT ⇄ DIVE → RESULT → BOAT
## 所有切换只走 _set_state()，其它节点不许自己换界面。
class_name DiveRoot
extends Control

enum State { HARBOR, BOAT, DIVE, RESULT }

const MENU_SCENE := "res://menu.tscn"
const DIVE_TUNING := "res://data/phase2/dive.json"

var progress: Progress = null
var ledger: Ledger = null
var scenery_table: Array = []
var tuning: Dictionary = {}
var state: int = State.BOAT
var session: DiveSession = null

var _harbor: HarborScreen = null
var _shop: ShopScreen = null
var _training: bool = false
var _boat: BoatScreen = null
var _view: DiveView = null
var _hud: DiveHud = null
var _result: ResultCard = null
var _rng := RandomNumberGenerator.new()
var _last_scenery: String = ""
var _seed_text: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_rng.randomize()
	progress = Progress.load_or_new()
	ledger = Ledger.new(progress)
	scenery_table = ConfigLoader.load_scenery().get("items", [])
	tuning = _read_tuning()
	_last_scenery = String(progress.scenery[-1]) if not progress.scenery.is_empty() else ""

	_harbor = HarborScreen.new()
	_harbor.setup(progress, ledger)
	_harbor.board_requested.connect(_on_board)
	_harbor.merchant_requested.connect(_on_shop)
	_harbor.training_requested.connect(_on_train)
	_harbor.room_requested.connect(_on_room)
	_harbor.back_requested.connect(_on_back_to_river)
	_harbor.talked.connect(_on_talk)
	add_child(_harbor)

	_boat = BoatScreen.new()
	_boat.setup(progress, ledger, scenery_table)
	_boat.dive_requested.connect(_on_dive_requested)
	_boat.shop_requested.connect(_on_shop)
	add_child(_boat)

	_view = DiveView.new()
	add_child(_view)

	_hud = DiveHud.new()
	add_child(_hud)

	_shop = ShopScreen.new()
	_shop.setup(progress, ledger)
	_shop.closed.connect(_on_shop_closed)
	add_child(_shop)

	_result = ResultCard.new()
	_result.cast_again.connect(_on_cast_again)
	_result.finish_trip.connect(_on_finish_trip)
	_result.back_to_boat.connect(_on_back_to_boat)
	_result.quit_to_harbor.connect(_on_quit)
	add_child(_result)

	_set_state(State.HARBOR)


func _read_tuning() -> Dictionary:
	if not ResourceLoader.exists(DIVE_TUNING):
		return {}
	var f := FileAccess.open(DIVE_TUNING, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


func _process(delta: float) -> void:
	if state != State.DIVE or session == null:
		return
	session.tick(delta)
	if session.depth >= session.max_depth() and not session.done:
		# 线放到底了，自动收线
		_on_surface()


# ---------- 状态 ----------

func _set_state(next: int) -> void:
	state = next
	if _harbor != null:
		_harbor.visible = next == State.HARBOR
	if _boat != null:
		_boat.visible = next == State.BOAT
	if _view != null:
		_view.visible = next == State.DIVE
	if _hud != null:
		_hud.visible = next == State.DIVE
	if _result != null:
		_result.visible = next == State.RESULT

	match next:
		State.HARBOR:
			if _harbor != null:
				_harbor.refresh()
		State.BOAT:
			if _boat != null:
				_boat.refresh_money()
		State.RESULT:
			_result.show_result(session)


## 钩子穿过地心之后，随机钩上来一处「海的那边」。
func _roll_far_side() -> Dictionary:
	if scenery_table.is_empty():
		return {}
	var seen: Array = progress.scenery
	var unseen := scenery_table.filter(
		func(it): return not seen.has(String(it.get("id", "")))
	)
	var pool: Array = unseen if not unseen.is_empty() else scenery_table
	var id := SceneryDeck.pick(pool, _rng, _last_scenery)
	if id.is_empty():
		return {}
	var item := SceneryDeck.find(scenery_table, id)
	if item.is_empty():
		return {}
	if progress.mark_scenery_seen(id):
		progress.save()
	_last_scenery = id
	return item


# ---------- 交互 ----------

func _on_dive_requested(seed_text: String) -> void:
	var text := seed_text
	if text.is_empty() or text.length() < 4:
		text = "%08x" % _rng.randi()
	_seed_text = text
	if not progress.seeds.has(text):
		progress.seeds[text] = {"collected": 0, "total": 0, "deepest": 0}
		progress.save()

	session = DiveSession.new(tuning, progress, text.hash())
	session.baits = 3 + AffinityBook.bait_bonus(AffinityBook.load_table(), progress)
	session.hooked.connect(_on_hooked)
	session.bumped.connect(_on_bumped)
	session.secret_seen.connect(_on_secret)
	session.hooked_full.connect(_on_surface)
	_view.bind_session(session)
	_hud.bind(session)
	_set_state(State.DIVE)


func _on_hooked(ai_id: String, depth: int) -> void:
	if _hud != null:
		_hud.flash(tr("钩到 %s · %d m") % [ai_id, depth])


## 1200m 以下的彩蛋：深海里的那张「自刎归天」。
func _on_secret(_id: String) -> void:
	# 钩子穿过去了。对面是倒着的西雅图。
	var item := _roll_far_side()
	if not item.is_empty():
		_view.set_far_art(String(item.get("art", "")))
	if _hud != null:
		if item.is_empty():
			_hud.flash(tr("钩子从另一头的海面冒了出来"))
		else:
			_hud.flash(tr("穿透了。%s") % String(item.get("name", "")))


func _on_bumped(penalty: int) -> void:
	if _hud != null:
		_hud.flash(tr("撞到杂物 −%d") % penalty)


## 点船上船：坐标在船上调。
func _on_board() -> void:
	_set_state(State.BOAT)


## 点其它人：只换一句话，别弹窗口 —— 沉浸感优先。
func _on_talk(who: String) -> void:
	if _harbor == null:
		return
	var lines := {
		"claude": tr("克劳德：线放多长，决定你能走多远。"),
		"big": tr("大肥鱼：……今天也去？"),
		"mid": tr("中肥鱼：我帮你看着绳子。"),
	}
	_harbor._set_line(String(lines.get(who, "")))


func _on_room() -> void:
	var form: Dictionary = _harbor.call("_room_form")
	if form.is_empty():
		return
	var art := String(form.get("art", ""))
	if art.is_empty() or not ResourceLoader.exists(art):
		return
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var tex := TextureRect.new()
	tex.texture = load(art)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(tex)
	var close := UIKit.button(tr("走 了"), false)
	close.position = Vector2(size.x * 0.5 - 90, size.y - 90)
	close.custom_minimum_size = Vector2(180, 44)
	close.pressed.connect(func(): layer.queue_free())
	layer.add_child(close)


func _on_train() -> void:
	# 训练不消耗、不进种子历史，只记分。
	_training = true
	var text := "%08x" % _rng.randi()
	_on_dive_requested(text)


func _on_shop() -> void:
	if _shop != null:
		_shop.open()


func _on_shop_closed() -> void:
	if _harbor != null:
		_harbor.refresh()


func _on_surface() -> void:
	if session != null and not session.done:
		session.surface()
		RunSettlement.settle(progress, session, _seed_text)
		_training = false
	_set_state(State.RESULT)


## 同一趟出海，再抛一竿：只重置本次下潜，鱼获留在 holds 里。
func _on_cast_again() -> void:
	if session == null or not session.cast():
		_on_finish_trip()
		return
	_view.bind_session(session)
	_hud.bind(session)
	_set_state(State.DIVE)


## 白饭喝完，回码头，下一趟重新计。
func _on_finish_trip() -> void:
	session = null
	_boat.refresh_money()
	_set_state(State.BOAT)


func _on_back_to_boat() -> void:
	session = null
	_set_state(State.BOAT)


func _on_quit() -> void:
	ChapterRouter.to_menu(self)


# ---------- 结算 ----------

func _input(event: InputEvent) -> void:
	if state != State.DIVE or session == null:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if not k.pressed or k.echo:
			return
		if k.keycode == KEY_SPACE:
			session.try_hook()
			return
		if k.keycode == KEY_ESCAPE:
			_on_surface()
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if not m.pressed:
			return
		if m.button_index == MOUSE_BUTTON_LEFT:
			session.try_hook()
		elif m.button_index == MOUSE_BUTTON_RIGHT:
			_on_surface()


## 第二章回第一章：单向，第一章没有反向的路。
func _on_back_to_river() -> void:
	ChapterRouter.to_game(self)
