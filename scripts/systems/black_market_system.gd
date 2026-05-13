extends Node

signal trade_phase_started
signal trade_initiated(from_id: int, to_id: int, offer: int, request: int)
signal trade_responded(response: String, amount: int)
signal trade_phase_ended

var pending_trades: Array = []
var trade_id_counter: int = 0

func _ready() -> void:
	pass

func start_trade_phase(human_id: int) -> void:
	pending_trades.clear()
	trade_phase_started.emit()

	if randf() < 0.5:
		_generate_ai_trade_offer(human_id)

	if pending_trades.is_empty():
		_execute_default_ai_trade(human_id)

	trade_phase_ended.emit()
	call_deferred("_on_trade_phase_end")

func _generate_ai_trade_offer(human_id: int) -> void:
	var alive_others = []
	for p in GameManager.players:
		if p.is_alive and p.id != human_id and p.player_type == PlayerData.PlayerType.AI:
			alive_others.append(p)
	if alive_others.is_empty():
		return

	var ai = alive_others[randi() % alive_others.size()]
	var offer = int(float(ai.gold) * randf_range(0.05, 0.15))
	offer = maxi(50, offer)

	var human = GameManager.get_human_player()
	var request = 0
	if human:
		request = int(float(human.gold) * randf_range(0.05, 0.15))
	request = maxi(50, request)

	pending_trades.append({
		"id": trade_id_counter,
		"from_id": ai.id,
		"to_id": human_id,
		"offer": offer,
		"request": request
	})
	trade_initiated.emit(ai.id, human_id, offer, request)
	GameManager.log_message.emit("%s 提出交易: 他给你 %d 金币, 你给他 %d 金币" % [ai.name, offer, request])

func _execute_default_ai_trade(human_id: int) -> void:
	var alive_others = []
	for p in GameManager.players:
		if p.is_alive and p.id != human_id and p.player_type == PlayerData.PlayerType.AI:
			alive_others.append(p)
	if alive_others.is_empty():
		return

	var ai = alive_others[randi() % alive_others.size()]
	var roll = randf()

	if roll < 0.6:
		var amount = int(float(ai.gold) * randf_range(0.02, 0.08))
		amount = maxi(20, amount)
		ai.gold -= amount
		var human = GameManager.get_human_player()
		if human:
			human.gold += amount
		GameManager.log_message.emit("%s 给了你 %d 金币" % [ai.name, amount])
		trade_responded.emit("ai_gave", amount)
	elif roll < 0.8:
		GameManager.log_message.emit("黑市今天很安静...")
		trade_responded.emit("quiet", 0)
	else:
		var human = GameManager.get_human_player()
		var steal = 0
		if human:
			steal = int(float(human.gold) * randf_range(0.05, 0.15))
		steal = maxi(20, steal)
		if human and human.gold >= steal:
			human.gold -= steal
			ai.gold += steal * 2
			GameManager.log_message.emit("%s 背叛了你! 偷走了 %d 金币!" % [ai.name, steal])
			trade_responded.emit("betrayed", steal * 2)
		else:
			GameManager.log_message.emit("黑市今天很安静...")
			trade_responded.emit("quiet", 0)

func respond_to_trade(trade_id: int, response: String) -> void:
	var trade = null
	for t in pending_trades:
		if t.id == trade_id:
			trade = t
			break
	if not trade:
		trade_phase_ended.emit()
		call_deferred("_on_trade_phase_end")
		return

	if response == "accept":
		var from_player = GameManager.get_player(trade.from_id)
		var to_player = GameManager.get_player(trade.to_id)
		if from_player and to_player:
			from_player.gold -= trade.offer
			to_player.gold += trade.offer
			to_player.gold -= trade.request
			from_player.gold += trade.request
			GameManager.log_message.emit("交易成功: %s 和 %s 交换金币" % [from_player.name, to_player.name])
			trade_responded.emit("accepted", trade.offer)
	elif response == "betray":
		var from_player = GameManager.get_player(trade.from_id)
		if from_player:
			var stolen = from_player.gold
			from_player.gold = 0
			var to_player = GameManager.get_player(trade.to_id)
			if to_player:
				to_player.gold += stolen * 2
			GameManager.log_message.emit("你背叛了 %s, 获得 %d 金币!" % [from_player.name, stolen * 2])
			trade_responded.emit("betrayed", stolen * 2)
	else:
		GameManager.log_message.emit("你拒绝了交易")
		trade_responded.emit("refused", 0)

	trade_phase_ended.emit()
	call_deferred("_on_trade_phase_end")

func _on_trade_phase_end() -> void:
	GameManager.on_black_market_complete()
