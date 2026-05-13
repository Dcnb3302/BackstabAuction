extends Node

signal game_started
signal round_started(round_number: int)
signal phase_changed(phase_name: String)
signal game_ended
signal timer_updated(time_left: float)
signal log_message(msg: String)
signal interest_applied(player_id: int, amount: int)
signal player_eliminated(player_id: int)

enum GamePhase { LOBBY, AUCTION, BLACK_MARKET, SEALED_BID, END_GAME }

const INITIAL_GOLD: int = 4000
const TOTAL_ROUNDS: int = 30
const ROUND_TIME: float = 15.0
const DEPOSIT_INTEREST: float = 0.05

var current_round: int = 0
var current_phase: int = GamePhase.LOBBY
var players: Array = []
var human_player_id: int = 0
var timer_left: float = ROUND_TIME
var is_timer_running: bool = false
var auction_items_pool: Array = []
var item_id_counter: int = 0
var game_in_progress: bool = false

func _ready() -> void:
	pass

func start_game(count: int = 4) -> void:
	for p in players:
		p.free()
	players.clear()
	auction_items_pool.clear()
	item_id_counter = 0
	current_round = 0
	current_phase = GamePhase.LOBBY
	timer_left = ROUND_TIME
	is_timer_running = false
	human_player_id = 0
	game_in_progress = false

	_create_players(count)
	_generate_item_pool()
	game_in_progress = true

	game_started.emit()
	call_deferred("_start_first_round")

func _start_first_round() -> void:
	start_round()

func _create_players(count: int) -> void:
	var human = PlayerData.new()
	human.id = 0
	human.name = "你"
	human.player_type = PlayerData.PlayerType.HUMAN
	human.gold = INITIAL_GOLD
	human.is_alive = true
	players.append(human)
	human_player_id = 0

	var ai_names = ["赵", "钱", "孙", "李", "周", "吴", "郑", "王"]
	for i in range(1, count):
		var ai = PlayerData.new()
		ai.id = i
		ai.name = ai_names[(i - 1) % ai_names.size()]
		ai.player_type = PlayerData.PlayerType.AI
		ai.gold = INITIAL_GOLD
		ai.is_alive = true
		ai.ai_params = {
			"aggression": randf_range(0.2, 0.6),
			"risk_tolerance": randf_range(0.1, 0.5),
			"bid_willingness": randf_range(0.3, 0.7),
			"fund_reserve": randf_range(0.3, 0.6)
		}
		players.append(ai)

	_assign_identities()

func _assign_identities() -> void:
	var identities = ["商人", "欺诈者", "贵族", "刺客", "守护者", "战士", "猎人", "法师"]
	identities.shuffle()

	for i in range(players.size()):
		var p = players[i]
		var identity_name = identities[i % identities.size()]
		p.identity = identity_name
		p.skills = IdentitySkillSystem.get_skills_for_identity(identity_name)

		if identity_name == "商人":
			p.gold += 50
		elif identity_name == "贵族":
			p.gold += 100

func start_round() -> void:
	current_round += 1

	if current_round > TOTAL_ROUNDS:
		end_game()
		return

	var alive_count = 0
	for player in players:
		if player.is_alive:
			alive_count += 1
	if alive_count <= 1:
		end_game()
		return

	_apply_deposit_interest()
	_round_start_cleanup()

	if randf() < 0.3:
		var event_name = RandomEventSystem.trigger_event()
		log_message.emit("随机事件: %s" % event_name)

	round_started.emit(current_round)

	if current_round % 5 == 0:
		start_sealed_bid_phase()
	else:
		start_auction_phase()

func _apply_deposit_interest() -> void:
	for player in players:
		if player.is_alive and player.gold > 0:
			var interest = int(float(player.gold) * DEPOSIT_INTEREST)
			player.gold += interest
			interest_applied.emit(player.id, interest)

func _round_start_cleanup() -> void:
	for player in players:
		player.is_shielded = false
		player.bid_discount = 1.0
		player.bid_willingness = 1.0

	_update_skill_cooldowns()
	DebtSystem.apply_all_debts()

func _update_skill_cooldowns() -> void:
	for player in players:
		var to_remove = []
		for skill_name in player.skill_cooldowns:
			player.skill_cooldowns[skill_name] -= 1
			if player.skill_cooldowns[skill_name] <= 0:
				to_remove.append(skill_name)
		for skill in to_remove:
			player.skill_cooldowns.erase(skill)

func start_auction_phase() -> void:
	current_phase = GamePhase.AUCTION
	phase_changed.emit("auction")

	var item = _get_next_auction_item()
	if item:
		AuctionSystem.start_normal_auction(item)
	else:
		_generate_item_pool()
		item = _get_next_auction_item()
		if item:
			AuctionSystem.start_normal_auction(item)
		else:
			_go_to_next_phase()

func start_sealed_bid_phase() -> void:
	current_phase = GamePhase.SEALED_BID
	phase_changed.emit("sealed_bid")

	var item = _get_next_auction_item()
	if item:
		AuctionSystem.start_sealed_auction(item)
	else:
		_generate_item_pool()
		item = _get_next_auction_item()
		if item:
			AuctionSystem.start_sealed_auction(item)
		else:
			_go_to_next_phase()

func start_black_market_phase() -> void:
	current_phase = GamePhase.BLACK_MARKET
	phase_changed.emit("black_market")

	if current_round % 3 == 0:
		BlackMarketSystem.start_trade_phase(human_player_id)
	else:
		_go_to_next_phase()

func on_black_market_complete() -> void:
	_go_to_next_phase()

func _go_to_next_phase() -> void:
	if current_round >= TOTAL_ROUNDS:
		end_game()
		return

	var alive_count = 0
	for player in players:
		if player.is_alive:
			alive_count += 1
	if alive_count <= 1:
		end_game()
		return

	if current_phase == GamePhase.SEALED_BID:
		if current_round % 3 == 0:
			start_black_market_phase()
		else:
			start_round()
	elif current_phase == GamePhase.AUCTION:
		if current_round % 5 == 0:
			start_sealed_bid_phase()
		elif current_round % 3 == 0:
			start_black_market_phase()
		else:
			start_round()
	elif current_phase == GamePhase.BLACK_MARKET:
		start_round()
	else:
		start_round()

func _get_next_auction_item() -> AuctionItem:
	if auction_items_pool.is_empty():
		return null
	return auction_items_pool.pop_front()

func _generate_item_pool() -> void:
	var item_names = [
		"古老卷轴", "神秘宝石", "魔法水晶", "传说之剑",
		"龙鳞护甲", "精灵弓箭", "亡灵法杖", "矮人战锤",
		"圣骑士盾", "暗影斗篷", "凤凰羽毛", "海妖珍珠",
		"泰坦之核", "虚空碎片", "时间沙漏", "命运之轮",
		"灵魂宝钻", "星辰碎片", "月光石", "烈焰之心",
		"深渊魔典", "冰霜之冠", "雷霆战斧", "翡翠梦境",
		"混沌原石", "圣光十字架", "暗影匕首", "狂暴之怒",
		"治愈圣杯", "幻象之镜", "命运骰子", "禁忌之书",
		"远古龙蛋", "元素之心", "时空裂隙石", "死神镰刀",
		"天使之翼", "恶魔之角", "不朽王冠", "失落权杖",
		"破晓之剑", "夜幕之盾", "风暴之锤", "自然之冠",
		"冥河之水", "黄金圣衣", "紫水晶戒", "红宝石项链",
		"蓝宝石吊坠", "祖母绿胸针", "珍珠耳环", "黑曜石戒指",
		"秘银铠甲", "精金头盔", "龙骨长弓", "蛇发女妖之瞳",
		"不死鸟之灰", "独角兽之角", "美杜莎之发", "赫尔墨斯之鞋"
	]
	var rarities = ["普通", "稀有", "史诗", "传说", "神话"]

	for i in range(40):
		var item = AuctionItem.new()
		item.id = item_id_counter
		item_id_counter += 1
		item.name = item_names[i % item_names.size()]
		item.rarity = rarities[randi() % rarities.size()]
		item.base_value = randi_range(150, 1500)
		item.generate_starting_price()
		auction_items_pool.append(item)

func end_game() -> void:
	if current_phase == GamePhase.END_GAME:
		return

	current_phase = GamePhase.END_GAME
	game_in_progress = false
	stop_timer()
	phase_changed.emit("end_game")

	var alive_players = []
	var dead_players = []
	for player in players:
		if player.is_alive:
			alive_players.append(player)
		else:
			dead_players.append(player)

	alive_players.sort_custom(func(a, b): return a.get_net_worth() > b.get_net_worth())
	players = alive_players + dead_players
	game_ended.emit()

func eliminate_player(player_id: int) -> void:
	var player = get_player(player_id)
	if player and player.is_alive:
		player.is_alive = false
		player_eliminated.emit(player_id)
		log_message.emit("%s 被淘汰!" % player.name)

		var alive_count = 0
		for p in players:
			if p.is_alive:
				alive_count += 1
		if alive_count <= 1:
			call_deferred("end_game")

func get_player(player_id: int) -> PlayerData:
	for player in players:
		if player.id == player_id:
			return player
	return null

func get_human_player() -> PlayerData:
	return get_player(human_player_id)

func get_alive_players() -> Array:
	var alive = []
	for player in players:
		if player.is_alive:
			alive.append(player)
	return alive

func get_other_alive_players(exclude_id: int = -1) -> Array:
	var others = []
	for player in players:
		if player.is_alive and player.id != exclude_id:
			others.append(player)
	return others

func start_timer(duration: float = ROUND_TIME) -> void:
	timer_left = duration
	is_timer_running = true

func stop_timer() -> void:
	is_timer_running = false

func tick_timer(delta: float) -> void:
	if is_timer_running:
		timer_left -= delta
		timer_updated.emit(timer_left)
		if timer_left <= 0:
			timer_left = 0.0
			is_timer_running = false
			AuctionSystem.on_timer_expired()

func get_winner() -> PlayerData:
	var alive = get_alive_players()
	if alive.is_empty():
		return null
	alive.sort_custom(func(a, b): return a.get_net_worth() > b.get_net_worth())
	return alive[0]
