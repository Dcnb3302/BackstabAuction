extends Node

signal event_triggered(event_type: int, event_data: Dictionary)

enum EventType { CALM, INFLATION, DEFLATION, CHAOS, DOUBLE_VALUE, DARK_TRADE, FRENZY, CALM_PERIOD, GODS_BLESSING, THIEF_NIGHT, LUCKY_DRAW, MYSTERIOUS_BEGGAR }

var event_names = {
	EventType.CALM: "平静时刻", EventType.INFLATION: "通货膨胀",
	EventType.DEFLATION: "经济萧条", EventType.CHAOS: "混乱时刻",
	EventType.DOUBLE_VALUE: "双倍收益", EventType.DARK_TRADE: "黑暗交易",
	EventType.FRENZY: "狂热竞拍", EventType.CALM_PERIOD: "冷静期",
	EventType.GODS_BLESSING: "神的祝福", EventType.THIEF_NIGHT: "盗贼之夜",
	EventType.LUCKY_DRAW: "幸运抽奖", EventType.MYSTERIOUS_BEGGAR: "神秘乞丐"
}

var event_descs = {
	EventType.CALM: "一切正常，继续竞拍", EventType.INFLATION: "所有物品起拍价增加30%",
	EventType.DEFLATION: "所有物品起拍价减少20%", EventType.CHAOS: "计时器随机变化",
	EventType.DOUBLE_VALUE: "本轮物品最终价值翻倍", EventType.DARK_TRADE: "可以偷看下一个物品",
	EventType.FRENZY: "所有玩家出价更加激进", EventType.CALM_PERIOD: "所有玩家出价更加保守",
	EventType.GODS_BLESSING: "所有存活玩家获得200金币", EventType.THIEF_NIGHT: "每人随机失去100-300金币",
	EventType.LUCKY_DRAW: "随机一名玩家获得500金币奖励", EventType.MYSTERIOUS_BEGGAR: "可以选择施舍100金币获得神秘回报"
}

var _double_value_round: int = -1

func _ready() -> void:
	pass

func trigger_event() -> String:
	var roll = randi() % 100
	var event_type = EventType.CALM

	if roll < 12: event_type = EventType.CALM
	elif roll < 22: event_type = EventType.INFLATION
	elif roll < 32: event_type = EventType.DEFLATION
	elif roll < 42: event_type = EventType.CHAOS
	elif roll < 52: event_type = EventType.DOUBLE_VALUE
	elif roll < 60: event_type = EventType.DARK_TRADE
	elif roll < 70: event_type = EventType.FRENZY
	elif roll < 78: event_type = EventType.CALM_PERIOD
	elif roll < 84: event_type = EventType.GODS_BLESSING
	elif roll < 90: event_type = EventType.THIEF_NIGHT
	elif roll < 95: event_type = EventType.LUCKY_DRAW
	else: event_type = EventType.MYSTERIOUS_BEGGAR

	_apply_event_effect(event_type)
	_double_value_round = GameManager.current_round if event_type == EventType.DOUBLE_VALUE else -1
	event_triggered.emit(event_type, {"type": event_type, "round": GameManager.current_round})
	return "%s: %s" % [event_names[event_type], event_descs[event_type]]

func _apply_event_effect(event_type: int) -> void:
	match event_type:
		EventType.INFLATION:
			for item in GameManager.auction_items_pool:
				item.starting_price = int(float(item.starting_price) * 1.3)
			for p in GameManager.players:
				if p.is_alive: p.bid_discount = 1.2
		EventType.DEFLATION:
			for item in GameManager.auction_items_pool:
				item.starting_price = int(float(item.starting_price) * 0.8)
			for p in GameManager.players:
				if p.is_alive: p.bid_discount = 0.8
		EventType.CHAOS:
			GameManager.timer_left = randf_range(5.0, 25.0)
			GameManager.log_message.emit("计时器变成了 %.1f 秒!" % GameManager.timer_left)
		EventType.DOUBLE_VALUE:
			GameManager.log_message.emit("本轮拍卖的物品最终价值将翻倍!")
		EventType.DARK_TRADE:
			if GameManager.auction_items_pool.size() > 0:
				var ni = GameManager.auction_items_pool[0]
				GameManager.log_message.emit("👁 你看到了下一件物品: %s (%s, 起拍价: %d)" % [ni.name, ni.rarity, ni.starting_price])
		EventType.FRENZY:
			for p in GameManager.players:
				if p.player_type == PlayerData.PlayerType.AI and p.is_alive:
					p.ai_params["aggression"] = clampf(p.ai_params.get("aggression", 0.3) * 1.5, 0.1, 1.0)
		EventType.CALM_PERIOD:
			for p in GameManager.players:
				if p.player_type == PlayerData.PlayerType.AI and p.is_alive:
					p.ai_params["aggression"] = clampf(p.ai_params.get("aggression", 0.3) * 0.5, 0.1, 1.0)
		EventType.GODS_BLESSING:
			for p in GameManager.players:
				if p.is_alive:
					p.gold += 200
					if p.id == GameManager.human_player_id:
						GameManager.log_message.emit("✨ 你获得了200金币的神的祝福!")
		EventType.THIEF_NIGHT:
			for p in GameManager.players:
				if p.is_alive and p.gold > 300:
					var stolen = randi_range(100, 300)
					stolen = mini(stolen, p.gold - 100)
					p.gold -= stolen
					if p.id == GameManager.human_player_id:
						GameManager.log_message.emit("🗡️ 你被偷了 %d 金币!" % stolen)
		EventType.LUCKY_DRAW:
			var alive = GameManager.get_alive_players()
			if not alive.is_empty():
				var lucky = alive[randi() % alive.size()]
				lucky.gold += 500
				GameManager.log_message.emit("🎰 %s 幸运地获得了500金币!" % lucky.name)
		EventType.MYSTERIOUS_BEGGAR:
			var human = GameManager.get_human_player()
			if human and human.gold >= 100:
				human.gold -= 100
				var reward = randi_range(150, 400)
				human.gold += reward
				GameManager.log_message.emit("🧙 你施舍了100金币，神秘乞丐回报了你 %d 金币!" % reward)

func is_double_value_round() -> bool:
	return _double_value_round == GameManager.current_round
