extends Resource
class_name AuctionItem

var id: int = 0
var name: String = ""
var rarity: String = ""
var base_value: int = 0
var starting_price: int = 0
var quality: String = ""
var quality_revealed: bool = false

func reveal_quality() -> void:
	if quality_revealed:
		return
	quality_revealed = true
	quality = _generate_quality()

func _generate_quality() -> String:
	if randf() < 0.002:
		return "treasure"

	var names = ["perfect", "flawed", "damaged", "fake"]
	var weights = [4, 3, 2, 1]
	var total = 0
	for w in weights:
		total += w

	var roll = randi() % total
	var cumulative = 0
	for i in range(names.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return names[i]
	return "perfect"

func get_actual_value() -> int:
	var multiplier = 1.0
	match quality:
		"treasure": multiplier = 2.0
		"perfect": multiplier = 1.0
		"flawed": multiplier = 0.8
		"damaged": multiplier = 0.5
		"fake": multiplier = 0.05
	return int(float(base_value) * multiplier)

func get_quality_color() -> Color:
	match quality:
		"treasure": return Color(1.0, 0.84, 0.0)
		"perfect": return Color(0.0, 1.0, 0.0)
		"flawed": return Color(1.0, 0.65, 0.0)
		"damaged": return Color(1.0, 0.0, 0.0)
		"fake": return Color(0.5, 0.5, 0.5)
	return Color.WHITE

func get_quality_name_zh() -> String:
	match quality:
		"treasure": return "珍品"
		"perfect": return "完美"
		"flawed": return "瑕疵"
		"damaged": return "破损"
		"fake": return "赝品"
	return "???"

func generate_starting_price() -> void:
	var ratio = randf_range(0.5, 0.7)
	starting_price = maxi(50, int(float(base_value) * ratio))

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"rarity": rarity,
		"base_value": base_value,
		"quality": quality,
		"quality_revealed": quality_revealed
	}
