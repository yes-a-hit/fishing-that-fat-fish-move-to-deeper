## DiveSession —— 一局的规则状态机：下沉、刷鱼、撞杂物、上钩、收线。
##
## 层：phase2/core（纯逻辑，不许碰 Node / SceneTree / autoload）
## 依赖：Progress（读等级）、DiveTuning（等级 → 数值）
##
## 设计（docs/plan-phase2-dive.md）：
##   · 没有氧气。深度上限 = 鱼线长度。
##   · 一次能带几件 = 钩容量。
##   · 600m 以下变暗；开灯看得远但刷怪更多。
##   · 不设专门障碍物，漂浮杂物本身就是障碍。
##   · 1200m 以下有个彩蛋，只在那时看得见。
class_name DiveSession
extends RefCounted

signal hooked(ai_id: String, depth: int)
signal hooked_full()
signal bumped(penalty: int)
signal secret_seen(id: String)
signal surfaced(items: Array, deepest: int, score: int)

const JUNK_KINDS := ["bottle", "crate", "rope", "can"]
const SECRET_DEPTH := 1200.0

var data: Dictionary = {}
var progress: Progress = null

var depth: float = 0.0
var deepest: int = 0
var score: int = 0
var catches: Array = []
var done: bool = false
var stun: float = 0.0
var secret_found: bool = false

var _max_depth: float = 420.0
var _capacity: int = 1
var baits: int = 3              # 这一趟带的白饭，抛一竿花一碗
var holds: Array = []           # 已进舱的鱼（跨多次抛竿累积）
var _sink: float = 58.0
var _hook_window: float = 0.16
var _spawn_rate: float = 1.0
var _score_scale: float = 1.0

var _rng := RandomNumberGenerator.new()
var _spawn_timer: float = 0.0
var _fish: Array = []
var _junk: Array = []


func _init(tuning: Dictionary, prog: Progress = null, seed_value: int = 0) -> void:
	data = tuning
	progress = prog
	_rng.seed = seed_value
	_apply_levels()


func _apply_levels() -> void:
	if progress == null:
		return
	var shop := DiveTuning.read_json(DiveTuning.SHOP_PATH)
	_max_depth = DiveTuning.max_depth(shop, progress.upgrade_level("line"))
	_capacity = DiveTuning.capacity(shop, progress.upgrade_level("hook"))
	_sink = 58.0 * DiveTuning.sink_scale(shop, progress.upgrade_level("rod"))
	var diff: Dictionary = data.get("difficulty", {}).get("normal", {})
	_hook_window = float(diff.get("hook_window", 0.16))
	_spawn_rate = float(diff.get("spawn_rate", 1.0))
	_score_scale = float(diff.get("score_scale", 1.0))


func max_depth() -> float:
	return _max_depth


func capacity() -> int:
	return _capacity


func layer_id() -> String:
	var layers: Array = data.get("layers", [])
	for l in layers:
		if depth >= float(l.get("depth_from", 0)) and depth < float(l.get("depth_to", 99999)):
			return String(l.get("id", "shallow"))
	return "deep"


func tick(delta: float) -> void:
	if done:
		return

	if stun > 0.0:
		stun = maxf(0.0, stun - delta)
	else:
		depth = minf(depth + _sink * delta, _max_depth)
	deepest = maxi(deepest, int(depth))
	score += int(float(data.get("score", {}).get("per_100m", 12)) * delta * 0.1 * _score_scale)

	if not secret_found and depth >= SECRET_DEPTH:
		secret_found = true
		secret_seen.emit("seafloor_light")

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = maxf(0.6, 2.2 / maxf(_spawn_rate, 0.05))
		_spawn_fish()

	for f in _fish:
		f["ttl"] = float(f["ttl"]) - delta
	_fish = _fish.filter(func(f): return float(f["ttl"]) > 0.0)

	_tick_junk(delta)


func fish_list() -> Array:
	return _fish


func junk_list() -> Array:
	return _junk


## 杂物自己往上浮，钩子往下走，撞上就是撞上。
func _tick_junk(delta: float) -> void:
	if _junk.size() < 2 and _rng.randf() < delta * 0.35:
		_junk.append({
			"kind": String(JUNK_KINDS[_rng.randi() % JUNK_KINDS.size()]),
			"depth": minf(depth + _rng.randf_range(35.0, 90.0), _max_depth),
			"x": _rng.randf_range(0.22, 0.78),
		})

	var hit := -1
	for i in _junk.size():
		var j: Dictionary = _junk[i]
		j["depth"] = float(j["depth"]) - 22.0 * delta
		if stun <= 0.0 and absf(float(j["depth"]) - depth) < 5.0:
			hit = i
	for i in range(_junk.size() - 1, -1, -1):
		if float(_junk[i]["depth"]) < depth - 120.0:
			_junk.remove_at(i)
	if hit >= 0 and hit < _junk.size():
		_junk.remove_at(hit)
		bump()


func _spawn_fish() -> void:
	if _fish.size() >= 4:
		return
	var layers: Array = data.get("layers", [])
	var pool: Array = []
	for l in layers:
		if String(l.get("id", "")) == layer_id():
			pool = l.get("ai", [])
			break
	if pool.is_empty():
		return
	var id: String = String(pool[_rng.randi() % pool.size()])
	var lead := _rng.randf_range(40.0, 220.0)
	_fish.append({
		"id": id,
		"depth": minf(depth + lead, _max_depth),
		"ttl": _rng.randf_range(4.0, 7.0),
	})


func try_hook() -> String:
	if done or catches.size() >= _capacity:
		return ""
	var best := -1
	var best_gap := INF
	for i in _fish.size():
		var gap: float = absf(float(_fish[i]["depth"]) - depth)
		if gap < best_gap:
			best_gap = gap
			best = i
	if best < 0:
		return ""
	if best_gap > maxf(20.0, _hook_window * 260.0):
		return ""
	var f: Dictionary = _fish[best]
	var got := String(f["id"])
	_fish.remove_at(best)
	var gain := int(float(data.get("score", {}).get("honest_ai_base", 120)) * _score_scale)
	score += gain
	catches.append({"id": got, "depth": int(f["depth"]), "score": gain})
	hooked.emit(got, int(f["depth"]))
	# 钩满了就自动收线：鱼进舱，等下一竿
	if catches.size() >= _capacity:
		holds.append_array(catches)
		catches.clear()
		done = true
		hooked_full.emit()
	return got


func bump() -> void:
	if done:
		return
	var penalty := int(data.get("hazard", {}).get("bump_penalty", 20))
	score = maxi(0, score - penalty)
	if bool(data.get("hazard", {}).get("drop_on_bump", true)) and not catches.is_empty():
		catches.remove_at(catches.size() - 1)
	stun = float(data.get("hazard", {}).get("bump_stun", 0.45))
	bumped.emit(penalty)


func surface() -> Dictionary:
	done = true
	var payload := {
		"items": catches.duplicate(),
		"deepest": deepest,
		"score": score,
		"layer": layer_id(),
		"secret": secret_found,
	}
	surfaced.emit(catches, deepest, score)
	return payload


## 抛下一竿：白饭够就扣一碗，重新开始这一次的下潜。
func cast() -> bool:
	if baits <= 0:
		return false
	baits -= 1
	catches.clear()
	depth = 0.0
	done = false
	secret_found = false
	_fish.clear()
	_junk.clear()
	return true


## 一条鱼值多少钱（卖价），好感 buff 在外面乘。
const FISH_PRICE := {"small": 6, "mid": 12, "big": 24, "doubao": 30, "claude": 60}


func fish_grade(c: Dictionary) -> String:
	var g := String(c.get("kind", c.get("id", "small")))
	return g if FISH_PRICE.has(g) else "small"


## 舱里所有鱼（跨竿累积的都算）。
func all_fish() -> Array:
	var out: Array = []
	out.append_array(holds)
	out.append_array(catches)
	return out


## 这一趟的预估卖价（不乘 buff，界面上自己乘）。
func haul_price() -> int:
	var total := 0
	for c in all_fish():
		total += int(FISH_PRICE.get(fish_grade(c), 6))
	return total


## 这一趟值多少碗白饭（按分数折算，留给码头结算用）。
func haul_value() -> int:
	var total := 0
	for c in holds:
		total += int(c.get("score", 0))
	for c in catches:
		total += int(c.get("score", 0))
	return int(total / 20.0)
