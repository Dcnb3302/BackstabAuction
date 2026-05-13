extends Node

signal stats_updated

var stats: Dictionary = {
	"games_played": 0,
	"games_won": 0,
	"games_lost": 0,
	"total_gold_earned": 0,
	"total_gold_spent": 0,
	"total_items_bought": 0,
	"total_skills_used": 0,
	"total_auctions_won": 0,
	"total_backstabs": 0,
	"total_assassinations": 0,
	"highest_single_bid": 0,
	"highest_net_worth": 0,
	"current_streak": 0,
	"best_streak": 0,
	"events_triggered": 0,
	"players_eliminated": 0,
	"times_eliminated": 0,
	"sealed_auctions_won": 0,
	"ai_trades_betrayed": 0
}

var _is_sealed: bool = false

func _ready() -> void:
	_load_stats()
	_connect_signals()

func _connect_signals() -> void:
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.interest_applied.connect(_on_interest_applied)
	AuctionSystem.auction_ended.connect(_on_auction_ended)
	IdentitySkillSystem.skill_used.connect(_on_skill_used)
	BlackMarketSystem.trade_responded.connect(_on_trade_responded)
	DebtSystem.loan_taken.connect(_on_loan_taken)
	DebtSystem.debt_updated.connect(_on_debt_updated)
	GameManager.player_eliminated.connect(_on_player_eliminated)

func mark_sealed_auction() -> void:
	_is_sealed = true

func _load_stats() -> void:
	var save_file = "user://game_stats.dat"
	if FileAccess.file_exists(save_file):
		var file = FileAccess.open(save_file, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data:
				for key in data:
					if stats.has(key):
						stats[key] = data[key]
			file.close()

func _save_stats() -> void:
	var save_file = "user://game_stats.dat"
	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(stats))
		file.close()
	stats_updated.emit()

func _on_game_ended() -> void:
	stats["games_played"] += 1

	var winner = GameManager.get_winner()
	var human = GameManager.get_human_player()

	if winner and human:
		if winner.id == human.id:
			stats["games_won"] += 1
			stats["current_streak"] += 1
			if stats["current_streak"] > stats["best_streak"]:
				stats["best_streak"] = stats["current_streak"]
		else:
			stats["games_lost"] += 1
			stats["current_streak"] = 0
			stats["times_eliminated"] += 1

	_save_stats()

func _on_interest_applied(_player_id: int, amount: int) -> void:
	stats["total_gold_earned"] += amount

func _on_auction_ended(winner_id: int, price: int, item: Dictionary) -> void:
	var human = GameManager.get_human_player()
	if human and winner_id == human.id:
		stats["total_auctions_won"] += 1
		stats["total_items_bought"] += 1
		stats["total_gold_spent"] += price

		if _is_sealed:
			stats["sealed_auctions_won"] += 1

		if price > stats["highest_single_bid"]:
			stats["highest_single_bid"] = price

		var net_worth = human.get_net_worth()
		if net_worth > stats["highest_net_worth"]:
			stats["highest_net_worth"] = net_worth

	_is_sealed = false

func _on_skill_used(skill_name: String, user_id: int) -> void:
	var human = GameManager.get_human_player()
	if human and user_id == human.id:
		stats["total_skills_used"] += 1

		match skill_name:
			"背刺": stats["total_backstabs"] += 1
			"暗杀": stats["total_assassinations"] += 1

func _on_trade_responded(response: String, _amount: int) -> void:
	if response == "betrayed" or response == "betray":
		stats["ai_trades_betrayed"] += 1

func _on_loan_taken(_player_id: int, amount: int) -> void:
	pass

func _on_debt_updated(player_id: int, new_debt: int) -> void:
	pass

func _on_player_eliminated(player_id: int) -> void:
	if player_id != GameManager.human_player_id:
		stats["players_eliminated"] += 1

func get_stat(key: String) -> Variant:
	return stats.get(key, 0)

func get_all_stats() -> Dictionary:
	return stats.duplicate()

func get_formatted_stat(key: String) -> String:
	var value = stats.get(key, 0)
	match key:
		"total_gold_earned", "total_gold_spent", "highest_net_worth", "highest_single_bid":
			return "%d 金币" % value
		_:
			return str(value)

func get_stat_name_zh(key: String) -> String:
	match key:
		"games_played": return "总游戏场次"
		"games_won": return "获胜场次"
		"games_lost": return "失败场次"
		"total_gold_earned": return "累计赚取金币"
		"total_gold_spent": return "累计花费金币"
		"total_items_bought": return "购买物品数"
		"total_skills_used": return "技能使用次数"
		"total_auctions_won": return "拍卖获胜次数"
		"total_backstabs": return "背刺次数"
		"total_assassinations": return "暗杀次数"
		"highest_single_bid": return "最高单次出价"
		"highest_net_worth": return "最高净资产"
		"current_streak": return "当前连胜"
		"best_streak": return "最佳连胜"
		"events_triggered": return "触发事件数"
		"players_eliminated": return "淘汰玩家数"
		"times_eliminated": return "被淘汰次数"
		"sealed_auctions_won": return "密封拍卖获胜"
		"ai_trades_betrayed": return "被背叛次数"
		_: return key
