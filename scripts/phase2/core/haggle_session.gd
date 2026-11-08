"""讨价还价的纯逻辑层：指针跑、按一下就定档、三轮出倍率。

不碰任何 Node，方便单测。
"""

extends RefCounted
class_name HaggleSession

const ZONES_GREEN := 0.15
const ZONES_YELLOW := 0.05
const ZONES_RED := -0.10

const GREEN_BASE := 0.06
const GREEN_PER_AFFINITY := 0.05
const SPEED_BASE := 0.55
const SPEED_PER_DIFFICULTY := 0.25
const MULT_MIN := 0.7
const MULT_MAX := 1.45
const ROUNDS := 3

var price: int = 0
var affinity: int = 0
var difficulty: int = 1

var cursor: float = 0.0      # 0..1
var direction: float = 1.0
var speed: float = 0.55
var green_width: float = 0.06

var round_index: int = 0
var bonus: float = 0.0
var last_zone: String = ""   # "green" / "yellow" / "red"
var done: bool = false


func start(p_price: int, p_affinity: int, p_difficulty: int) -> void:
	price = maxi(1, p_price)
	affinity = clampi(p_affinity, 0, 100)
	difficulty = clampi(p_difficulty, 0, 2)
	green_width = GREEN_BASE + GREEN_PER_AFFINITY * (float(affinity) / 100.0)
	speed = SPEED_BASE + SPEED_PER_DIFFICULTY * float(difficulty)
	if affinity < 30:
		speed *= 1.15
	elif affinity >= 90:
		speed *= 0.75
	elif affinity >= 60:
		speed *= 0.88
	cursor = 0.0
	direction = 1.0
	round_index = 0
	bonus = 0.0
	last_zone = ""
	done = false


## 每帧推指针，到头折返。
func tick(delta: float) -> void:
	if done:
		return
	cursor += direction * speed * delta
	if cursor >= 1.0:
		cursor = 1.0 - (cursor - 1.0)
		direction = -1.0
	elif cursor <= 0.0:
		cursor = -cursor
		direction = 1.0


## 点一下：按指针落点判档。
func hit() -> String:
	if done:
		return ""
	var center := 0.5
	var half_green := green_width * 0.5
	var half_yellow := half_green + 0.09

	var zone := "red"
	if absf(cursor - center) <= half_green:
		zone = "green"
		bonus += ZONES_GREEN
	elif absf(cursor - center) <= half_yellow:
		zone = "yellow"
		bonus += ZONES_YELLOW
	else:
		bonus += ZONES_RED

	last_zone = zone
	round_index += 1
	if round_index >= ROUNDS:
		done = true
	return zone


## 最终倍数（含上下限）
func multiplier() -> float:
	return clampf(1.0 + bonus, MULT_MIN, MULT_MAX)


## 成交价
func final_price() -> int:
	return int(round(float(price) * multiplier()))


func is_done() -> bool:
	return done


func rounds_left() -> int:
	return maxi(0, ROUNDS - round_index)
