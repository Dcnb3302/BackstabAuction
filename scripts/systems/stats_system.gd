extends Node

signal stats_updated

var stats: Dictionary = {
	"games_played": 0,
	"games_won": 0,
	"games_lost": 0,
	"total_gold_earned": 0,
	"total_gold_spent": 0,
	"total_items_bought": 0,
	"total_items_sold": 0,
	"total_skills_used": 0,
	"total_auctions_won": 0,
	"total_auctions_lost": 0,
	"total_backstabs": 0,
	"total_assassinations": 0,
	"total_betrayals": 0,
	"total_loans_taken": 0,
	"total_debt_paid": 0,
	"highest_single_bid": 0,
	"highest_net_worth": 0,
	"longest_game_rounds": 0,
	"shortest_game_rounds": 999,
	"treasure_items_found": 0,
	"perfect_items_found": 0,
	"flawed_items_found": 0,
	"damaged_items_found": 0,
	"fake_items_found": 0,
	"sealed_auctions_won": 0,
	"normal_auctions_won": 0,
	"ai_trades_accepted": 0,
	"ai_trades_rejected": 0,
	"ai_trades_betrayed": 0,
	"events_triggered": 0,
	"identities_unlocked": [],
	"identity_wins": {},
	"best_identity": "",
	"total_time_played": 0,
	"current_streak": 0,
	"best_streak": 0,
	"total_rounds_played": 0,
	"players_eliminated": 0,
	"times_eliminated": 0,
	"shields_used": 0,
	"shields_blocked": 0,
	"persuasions_used": 0,
	"sabotages_used": 0,
	"peeks_used": 0,
	"blessings_used": 0,
	"sprints_used": 0,
	"highest_debt_reached": 0,
	"games_no_debt_won": 0
}

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
	RandomEventSystem.event_triggered.connect(_on_event_triggered)
	GameManager.player_eliminated.connect(_on_player_eliminated)

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
	stats["total_rounds_played"] += GameManager.current_round
	
	var winner = GameManager.get_winner()
	var human = GameManager.get_human_player()
	
	if winner and human:
		if winner.id == human.id:
			stats["games_won"] += 1
			stats["current_streak"] += 1
			if stats["current_streak"] > stats["best_streak"]:
				stats["best_streak"] = stats["current_streak"]
			
			if human.debt == 0:
				stats["games_no_debt_won"] += 1
			
			if not stats["identity_wins"].has(human.identity):
				stats["identity_wins"][human.identity] = 0
			stats["identity_wins"][human.identity] += 1
			
			if not stats["identities_unlocked"].has(human.identity):
				stats["identities_unlocked"].append(human.identity)
			
			if human.net_worth > stats["highest_net_worth"]:
				stats["highest_net_worth"] = human.net_worth
		else:
			stats["games_lost"] += 1
			stats["current_streak"] = 0
			stats["times_eliminated"] += 1
	
	if GameManager.current_round > stats["longest_game_rounds"]:
		stats["longest_game_rounds"] = GameManager.current_round
	if GameManager.current_round < stats["shortest_game_rounds"] and GameManager.current_round > 0:
		stats["shortest_game_rounds"] = GameManager.current_round
	
	_update_best_identity()
	_save_stats()

func _update_best_identity() -> void:
	var max_wins = 0
	var best = ""
	for identity in stats["identity_wins"]:
		if stats["identity_wins"][identity] > max_wins:
			max_wins = stats["identity_wins"][identity]
			best = identity
	stats["best_identity"] = best

func _on_interest_applied(_player_id: int, amount: int) -> void:
	stats["total_gold_earned"] += amount

func _on_auction_ended(winner_id: int, price: int, item: Dictionary) -> void:
	var human = GameManager.get_human_player()
	if human and winner_id == human.id:
		stats["total_auctions_won"] += 1
		stats["total_items_bought"] += 1
		stats["total_gold_spent"] += price
		
		if AuctionSystem.current_auction_type == AuctionSystem.AuctionType.SEALED:
			stats["sealed_auctions_won"] += 1
		else:
			stats["normal_auctions_won"] += 1
		
		if price > stats["highest_single_bid"]:
			stats["highest_single_bid"] = price
		
		var quality = item.get("quality", "")
		match quality:
			"treasure": stats["treasure_items_found"] += 1
			"perfect": stats["perfect_items_found"] += 1
			"flawed": stats["flawed_items_found"] += 1
			"damaged": stats["damaged_items_found"] += 1
			"fake": stats["fake_items_found"] += 1
	elif human:
		stats["total_auctions_lost"] += 1

func _on_skill_used(skill_name: String, user_id: int) -> void:
	var human = GameManager.get_human_player()
	if human and user_id == human.id:
		stats["total_skills_used"] += 1
		
		match skill_name:
			"背刺": stats["total_backstabs"] += 1
			"暗杀": stats["total_assassinations"] += 1
			"护盾": stats["shields_used"] += 1
			"巧舌如簧": stats["persuasions_used"] += 1
			"破坏": stats["sabotages_used"] += 1
			"透视": stats["peeks_used"] += 1
			"祝福": stats["blessings_used"] += 1
			"冲刺": stats["sprints_used"] += 1

func _on_trade_responded(response: String, _amount: int) -> void:
	match response:
		"accepted", "ai_gave": stats["ai_trades_accepted"] += 1
		"refused", "quiet": stats["ai_trades_rejected"] += 1
		"betrayed", "betray": stats["ai_trades_betrayed"] += 1

func _on_loan_taken(_player_id: int, amount: int) -> void:
	var human = GameManager.get_human_player()
	if human:
		stats["total_loans_taken"] += amount

func _on_debt_updated(player_id: int, new_debt: int) -> void:
	if player_id == GameManager.human_player_id:
		if new_debt > stats["highest_debt_reached"]:
			stats["highest_debt_reached"] = new_debt

func _on_event_triggered(_event_type: int, _event_data: Dictionary) -> void:
	stats["events_triggered"] += 1

func _on_player_eliminated(player_id: int) -> void:
	if player_id != GameManager.human_player_id:
		stats["players_eliminated"] += 1
	else:
		stats["times_eliminated"] += 1

func get_stat(key: String) -> Variant:
	return stats.get(key, 0)

func get_all_stats() -> Dictionary:
	return stats.duplicate()

func reset_stats() -> void:
	for key in stats:
		if key == "identities_unlocked":
			stats[key] = []
		elif key == "identity_wins":
			stats[key] = {}
		elif key == "best_identity":
			stats[key] = ""
		elif key == "shortest_game_rounds":
			stats[key] = 999
		elif key == "total_time_played":
			stats[key] = 0
		else:
			stats[key] = 0
	_save_stats()

func get_formatted_stat(key: String) -> String:
	var value = stats.get(key, 0)
	match key:
		"total_gold_earned", "total_gold_spent", "highest_net_worth", "highest_single_bid", "highest_debt_reached":
			return "%d 金币" % value
		"total_loans_taken", "total_debt_paid":
			return "%d 金币" % value
		"total_time_played":
			var hours = int(value / 3600)
			var mins = int((value % 3600) / 60)
			return "%d小时 %d分钟" % [hours, mins]
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
		"longest_game_rounds": return "最长游戏轮数"
		"shortest_game_rounds": return "最短游戏轮数"
		"current_streak": return "当前连胜"
		"best_streak": return "最佳连胜"
		"best_identity": return "最擅长身份"
		"events_triggered": return "触发事件数"
		"players_eliminated": return "淘汰玩家数"
		"times_eliminated": return "被淘汰次数"
		"sealed_auctions_won": return "密封拍卖获胜"
		"ai_trades_accepted": return "接受交易数"
		"ai_trades_betrayed": return "被背叛次数"
		_: return key
