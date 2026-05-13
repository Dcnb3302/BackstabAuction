extends Node

enum EventType { CALM, INFLATION, DEFLATION, CHAOS, DOUBLE_VALUE, DARK_TRADE, FRENZY, CALM_PERIOD }

var event_names = {
	EventType.CALM: "平静时刻", EventType.INFLATION: "通货膨胀",
	EventType.DEFLATION: "经济萧条", EventType.CHAOS: "混乱时刻",
	EventType.DOUBLE_VALUE: "双倍收益", EventType.DARK_TRADE: "黑暗交易",
	EventType.FRENZY: "狂热竞拍", EventType.CALM_PERIOD: "冷静期"
}
var event_descs = {
	EventType.CALM: "一切正常", EventType.INFLATION: "所有出价增加20%",
	EventType.DEFLATION: "所有出价减少20%", EventType.CHAOS: "计时器随机变化",
	EventType.DOUBLE_VALUE: "本轮物品价值翻倍", EventType.DARK_TRADE: "可以偷看下一个物品",
	EventType.FRENZY: "AI更加激进", EventType.CALM_PERIOD: "AI更加保守"
}

func _ready() -> void:
	pass

func trigger_event() -> String:
	var roll = randi() % 100
	var event_type = EventType.CALM

	if roll < 15: event_type = EventType.CALM
	elif roll < 28: event_type = EventType.INFLATION
	elif roll < 41: event_type = EventType.DEFLATION
	elif roll < 54: event_type = EventType.CHAOS
	elif roll < 67: event_type = EventType.DOUBLE_VALUE
	elif roll < 78: event_type = EventType.DARK_TRADE
	elif roll < 90: event_type = EventType.FRENZY
	else: event_type = EventType.CALM_PERIOD

	_apply_event_effect(event_type)
	return "%s: %s" % [event_names[event_type], event_descs[event_type]]

func _apply_event_effect(event_type: int) -> void:
	match event_type:
		EventType.INFLATION:
			for p in GameManager.players:
				if p.is_alive: p.bid_discount = 1.2
		EventType.DEFLATION:
			for p in GameManager.players:
				if p.is_alive: p.bid_discount = 0.8
		EventType.CHAOS:
			GameManager.timer_left = randf_range(5.0, 25.0)
		EventType.DARK_TRADE:
			if GameManager.auction_items_pool.size() > 0:
				var ni = GameManager.auction_items_pool[0]
				GameManager.log_message.emit("你看到了下一件物品: %s (%s, 起拍价: %d)" % [ni.name, ni.rarity, ni.starting_price])
		EventType.FRENZY:
			for p in GameManager.players:
				if p.player_type == PlayerData.PlayerType.AI and p.is_alive:
					p.ai_params["aggression"] = clampf(p.ai_params.get("aggression", 0.3) * 1.5, 0.1, 1.0)
		EventType.CALM_PERIOD:
			for p in GameManager.players:
				if p.player_type == PlayerData.PlayerType.AI and p.is_alive:
					p.ai_params["aggression"] = clampf(p.ai_params.get("aggression", 0.3) * 0.5, 0.1, 1.0)
