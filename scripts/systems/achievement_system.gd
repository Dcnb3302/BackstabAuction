extends Node

signal achievement_unlocked(achievement_id: String, name: String, description: String)
signal achievement_list_updated

const ACHIEVEMENTS: Dictionary = {
	"first_auction": {
		"name": "初次参拍",
		"description": "完成你的第一次拍卖",
		"icon": "🎯"
	},
	"first_win": {
		"name": "首战告捷",
		"description": "成功拍下一件物品",
		"icon": "🏆"
	},
	"bargain_hunter": {
		"name": "捡漏达人",
		"description": "以低于起拍价的50%拍下一件物品（AI对战中）",
		"icon": "💰"
	},
	"high_roller": {
		"name": "豪掷千金",
		"description": "单次出价超过500金币",
		"icon": "👑"
	},
	"treasure_collector": {
		"name": "珍品收藏家",
		"description": "收集到5件珍品品质的物品",
		"icon": "💎"
	},
	"perfect_collection": {
		"name": "完美主义者",
		"description": "收集到10件完美品质的物品",
		"icon": "✨"
	},
	"fortune_teller": {
		"name": "预言家",
		"description": "使用透视技能并拍下看到的物品",
		"icon": "🔮"
	},
	"backstabber": {
		"name": "背刺大师",
		"description": "成功背刺偷取金币累计超过200",
		"icon": "🗡️"
	},
	"assassin": {
		"name": "冷酷刺客",
		"description": "使用暗杀技能淘汰一名玩家",
		"icon": "☠️"
	},
	"shield_master": {
		"name": "铁壁铜墙",
		"description": "使用护盾成功抵挡5次攻击",
		"icon": "🛡️"
	},
	"merchant_king": {
		"name": "商业之王",
		"description": "以商人身份赢得游戏",
		"icon": "📈"
	},
	"noble_victory": {
		"name": "贵族胜利",
		"description": "以贵族身份赢得游戏",
		"icon": "🎩"
	},
	"assassin_win": {
		"name": "暗影之王",
		"description": "以刺客身份赢得游戏",
		"icon": "🌙"
	},
	"mage_supremacy": {
		"name": "大法师",
		"description": "以法师身份赢得游戏",
		"icon": "🧙"
	},
	"wealthy": {
		"name": "富甲一方",
		"description": "单局游戏中累计拥有超过10000金币",
		"icon": "💵"
	},
	"bankrupt": {
		"name": "倾家荡产",
		"description": "负债超过400金币",
		"icon": "📉"
	},
	"survivor": {
		"name": "幸存者",
		"description": "在其他玩家全部淘汰后获胜",
		"icon": "🏅"
	},
	"speed_run": {
		"name": "闪电战",
		"description": "在20轮内结束游戏并获胜",
		"icon": "⚡"
	},
	"marathon": {
		"name": "马拉松",
		"description": "完成全部30轮拍卖",
		"icon": "🏃"
	},
	"first_sealed": {
		"name": "密封竞拍",
		"description": "参与第一次密封拍卖",
		"icon": "📝"
	},
	"sealed_winner": {
		"name": "暗拍之王",
		"description": "赢得5次密封拍卖",
		"icon": "🎰"
	},
	"black_market_deal": {
		"name": "黑市交易",
		"description": "成功完成一次黑市交易",
		"icon": "🏪"
	},
	"black_market_betrayal": {
		"name": "背叛者",
		"description": "在黑市中背叛对方",
		"icon": "😈"
	},
	"loan_shark": {
		"name": "借贷大王",
		"description": "累计借贷超过1000金币",
		"icon": "🏦"
	},
	"debt_free": {
		"name": "无债一身轻",
		"description": "在负债超过300的情况下还清所有债务",
		"icon": "✅"
	},
	"event_lucky": {
		"name": "幸运儿",
		"description": "触发10次随机事件",
		"icon": "🍀"
	},
	"chaos_master": {
		"name": "混乱之主",
		"description": "在混乱时刻事件中获胜",
		"icon": "🌀"
	},
	"inflation_beneficiary": {
		"name": "通胀受益者",
		"description": "在通货膨胀事件中赢得拍卖",
		"icon": "📊"
	},
	"veteran": {
		"name": "老兵",
		"description": "赢得10场游戏",
		"icon": "🎖️"
	},
	"legend": {
		"name": "传奇拍卖师",
		"description": "赢得50场游戏",
		"icon": "⭐"
	},
	"all_identities": {
		"name": "千面人",
		"description": "以所有8种身份各赢得至少一场游戏",
		"icon": "🎭"
	},
	"no_debt_win": {
		"name": "清白之身",
		"description": "在不借贷的情况下赢得游戏",
		"icon": "🕊️"
	},
	"perfect_round": {
		"name": "完美回合",
		"description": "在一轮拍卖中同时使用3个技能",
		"icon": "💫"
	},
	"comeback": {
		"name": "逆风翻盘",
		"description": "从净资产排名最后逆袭获胜",
		"icon": "🔥"
	}
}

var unlocked_achievements: Array = []
var achievement_progress: Dictionary = {}
var total_wins: int = 0
var wins_by_identity: Dictionary = {}

func _ready() -> void:
	_load_achievements()
	_connect_signals()

func _connect_signals() -> void:
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.log_message.connect(_on_log_message)
	AuctionSystem.auction_ended.connect(_on_auction_ended)
	IdentitySkillSystem.skill_used.connect(_on_skill_used)
	BlackMarketSystem.trade_responded.connect(_on_trade_responded)
	DebtSystem.loan_taken.connect(_on_loan_taken)
	DebtSystem.debt_updated.connect(_on_debt_updated)
	RandomEventSystem.event_triggered.connect(_on_event_triggered)

func _load_achievements() -> void:
	var save_file = "user://achievements.dat"
	if FileAccess.file_exists(save_file):
		var file = FileAccess.open(save_file, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data:
				unlocked_achievements = data.get("unlocked", [])
				achievement_progress = data.get("progress", {})
				total_wins = data.get("total_wins", 0)
				wins_by_identity = data.get("wins_by_identity", {})
			file.close()

func _save_achievements() -> void:
	var save_file = "user://achievements.dat"
	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file:
		var data = {
			"unlocked": unlocked_achievements,
			"progress": achievement_progress,
			"total_wins": total_wins,
			"wins_by_identity": wins_by_identity
		}
		file.store_string(JSON.stringify(data))
		file.close()

func _on_game_ended() -> void:
	var winner = GameManager.get_winner()
	if winner and winner.id == GameManager.human_player_id:
		total_wins += 1
		
		var identity = winner.identity
		if not wins_by_identity.has(identity):
			wins_by_identity[identity] = 0
		wins_by_identity[identity] += 1
		
		_check_achievement("first_win")
		
		if GameManager.current_round < 20:
			_check_achievement("speed_run")
		
		_check_achievement("marathon")
		
		if total_wins >= 10:
			_check_achievement("veteran")
		if total_wins >= 50:
			_check_achievement("legend")
		
		if wins_by_identity.size() >= 8:
			_check_achievement("all_identities")
		
		match identity:
			"商人": _check_achievement("merchant_king")
			"贵族": _check_achievement("noble_victory")
			"刺客": _check_achievement("assassin_win")
			"法师": _check_achievement("mage_supremacy")
		
		var alive_players = GameManager.get_alive_players()
		if alive_players.size() == 1:
			_check_achievement("survivor")
		
		var has_debt = false
		for p in GameManager.players:
			if p.id == GameManager.human_player_id and p.debt > 0:
				has_debt = true
		if not has_debt:
			_check_achievement("no_debt_win")
		
		_check_comeback()
	
	_save_achievements()

func _check_comeback() -> void:
	if GameManager.players.size() < 2:
		return
	
	var human_idx = -1
	for i in range(GameManager.players.size()):
		if GameManager.players[i].id == GameManager.human_player_id:
			human_idx = i
			break
	
	if human_idx == 0:
		var was_last = true
		var human_net = GameManager.players[human_idx].get_net_worth()
		for i in range(1, GameManager.players.size()):
			if GameManager.players[i].get_net_worth() > human_net:
				was_last = false
				break
		if was_last:
			_check_achievement("comeback")

func _on_auction_ended(winner_id: int, price: int, item: Dictionary) -> void:
	if winner_id == GameManager.human_player_id:
		_check_achievement("first_auction")
		
		if price > 500:
			_check_achievement("high_roller")
		
		if item.get("quality") == "treasure":
			_increment_progress("treasure_collector", 5)
		
		if item.get("quality") == "perfect":
			_increment_progress("perfect_collection", 10)
		
		var starting = item.get("starting_price", 0)
		if starting > 0 and price < starting * 0.5:
			_check_achievement("bargain_hunter")

func _on_skill_used(skill_name: String, user_id: int) -> void:
	if user_id == GameManager.human_player_id:
		if skill_name == "透视":
			_check_achievement("fortune_teller")
		
		if skill_name == "暗杀":
			_check_achievement("assassin")
		
		if skill_name == "护盾":
			_increment_progress("shield_master", 5)
		
		_increment_progress("perfect_round", 3)

func _on_trade_responded(response: String, amount: int) -> void:
	if response == "accepted":
		_check_achievement("black_market_deal")
	elif response == "betrayed" or response == "betray":
		_check_achievement("black_market_betrayal")

func _on_loan_taken(player_id: int, amount: int) -> void:
	if player_id == GameManager.human_player_id:
		_increment_progress("loan_shark", 1000)

func _on_debt_updated(player_id: int, new_debt: int) -> void:
	if player_id == GameManager.human_player_id:
		if new_debt > 400:
			_check_achievement("bankrupt")
		if new_debt > 300:
			_increment_progress("debt_free", 0)

func _on_event_triggered(event_type: int, _event_data: Dictionary) -> void:
	_increment_progress("event_lucky", 10)

func _on_log_message(msg: String) -> void:
	if msg.contains("偷取了") and msg.contains("金币"):
		var parts = msg.split(" ")
		for part in parts:
			if part.is_valid_int():
				var stolen = part.to_int()
				_increment_progress("backstabber", 200)
				break

func _check_achievement(achievement_id: String) -> void:
	if unlocked_achievements.has(achievement_id):
		return
	
	if ACHIEVEMENTS.has(achievement_id):
		unlocked_achievements.append(achievement_id)
		var ach = ACHIEVEMENTS[achievement_id]
		achievement_unlocked.emit(achievement_id, ach.name, ach.description)
		achievement_list_updated.emit()
		_save_achievements()

func _increment_progress(achievement_id: String, target: int) -> void:
	if unlocked_achievements.has(achievement_id):
		return
	
	if not achievement_progress.has(achievement_id):
		achievement_progress[achievement_id] = 0
	
	achievement_progress[achievement_id] += 1
	
	if achievement_progress[achievement_id] >= target:
		_check_achievement(achievement_id)

func is_unlocked(achievement_id: String) -> bool:
	return unlocked_achievements.has(achievement_id)

func get_unlocked_count() -> int:
	return unlocked_achievements.size()

func get_total_count() -> int:
	return ACHIEVEMENTS.size()

func get_all_achievements() -> Dictionary:
	return ACHIEVEMENTS

func get_progress(achievement_id: String) -> Dictionary:
	if not achievement_progress.has(achievement_id):
		return {"current": 0, "target": 0}
	return {"current": achievement_progress[achievement_id], "target": 0}
