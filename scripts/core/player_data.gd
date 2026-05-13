extends Resource
class_name PlayerData

enum PlayerType { HUMAN, AI }

var id: int = 0
var name: String = ""
var player_type: int = PlayerType.HUMAN
var gold: int = 4000
var debt: int = 0
var items: Array = []
var identity: String = ""
var skills: Array = []
var skill_cooldowns: Dictionary = {}
var is_shielded: bool = false
var bid_discount: float = 1.0
var bid_willingness: float = 1.0
var is_alive: bool = true
var ai_params: Dictionary = {}

func get_net_worth() -> int:
	var item_value = 0
	for item in items:
		item_value += get_item_value(item)
	return gold + item_value - debt

static func get_item_value(item: Dictionary) -> int:
	if item.is_empty():
		return 0
	var base_value = item.get("base_value", 0)
	var quality = item.get("quality", "perfect")
	var multiplier = 1.0
	match quality:
		"treasure": multiplier = 2.0
		"perfect": multiplier = 1.0
		"flawed": multiplier = 0.8
		"damaged": multiplier = 0.5
		"fake": multiplier = 0.05
	return int(float(base_value) * multiplier)

func add_item(item: Dictionary) -> void:
	items.append(item)

func get_total_item_value() -> int:
	var total = 0
	for item in items:
		total += get_item_value(item)
	return total

func get_most_valuable_item_index() -> int:
	if items.is_empty():
		return -1
	var max_val = -1
	var max_idx = -1
	for i in range(items.size()):
		var val = get_item_value(items[i])
		if val > max_val:
			max_val = val
			max_idx = i
	return max_idx
