## Ledger —— 二期经济账本：钱、杂物库存、已见计数；升级与道具扣款只走这里
## 层：phase2/core（纯逻辑）
## 依赖：只拿一个 Progress 实例（不自己读写文件）
class_name Ledger
extends RefCounted

var progress: Progress


func _init(p: Progress = null) -> void:
	progress = p


func money() -> int:
	return progress.money if progress != null else 0


func earn(amount: int) -> void:
	if progress == null or amount <= 0:
		return
	progress.add_money(amount)


## 花钱，成功返回 true。钱不够就是买不了，不搞负数。
func spend(amount: int) -> bool:
	if progress == null or amount <= 0:
		return false
	if progress.money < amount:
		return false
	progress.add_money(-amount)
	return true


func add_item(id: String, n: int = 1) -> void:
	if progress != null:
		progress.add_item(id, n)


func take_item(id: String, n: int = 1) -> bool:
	return progress.take_item(id, n) if progress != null else false


func item_count(id: String) -> int:
	return int(progress.items.get(id, 0)) if progress != null else 0


## 卖杂物：一件换钱，同时留下「见过」记号（支线用）。
func sell_trinket(id: String, price: int) -> bool:
	if progress == null:
		return false
	if progress.take_trinket(id):
		earn(price)
		progress.mark_trinket_seen(id)
		return true
	return false
