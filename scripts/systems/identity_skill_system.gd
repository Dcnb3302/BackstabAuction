extends Node

signal skill_used(skill_name: String, user_id: int)

const SKILL_DATA: Dictionary = {
	"背刺": { "cost": 0, "cooldown": 3, "needs_target": false, "description": "偷取最高出价者10%金币" },
	"护盾": { "cost": 50, "cooldown": 2, "needs_target": false, "description": "本轮免疫背刺、破坏、暗杀" },
	"冲刺": { "cost": 30, "cooldown": 3, "needs_target": false, "description": "立即结束本轮拍卖" },
	"透视": { "cost": 40, "cooldown": 2, "needs_target": false, "description": "偷看下一件拍卖物品" },
	"破坏": { "cost": 60, "cooldown": 3, "needs_target": true, "description": "让目标本轮无法出价" },
	"祝福": { "cost": 35, "cooldown": 2, "needs_target": false, "description": "本轮自己出价减少20%" },
	"巧舌如簧": { "cost": 40, "cooldown": 3, "needs_target": true, "description": "降低目标出价意愿" },
	"暗杀": { "cost": 200, "cooldown": -1, "needs_target": true, "description": "淘汰目标并清空其物品(全场仅一次)" }
}

func _ready() -> void:
	pass

func get_skills_for_identity(identity_name: String) -> Array:
	match identity_name:
		"商人": return ["背刺", "冲刺"]
		"欺诈者": return ["巧舌如簧", "破坏"]
		"贵族": return ["护盾", "祝福"]
		"刺客": return ["背刺", "暗杀"]
		"守护者": return ["护盾", "祝福"]
		"战士": return ["冲刺", "破坏"]
		"猎人": return ["透视", "背刺"]
		"法师": return ["祝福", "巧舌如簧", "透视"]
	return []

func can_use_skill(player: PlayerData, skill_name: String) -> bool:
	if not SKILL_DATA.has(skill_name):
		return false
	if not skill_name in player.skills:
		return false
	var data = SKILL_DATA[skill_name]
	if player.gold < data.cost:
		return false
	if player.skill_cooldowns.has(skill_name):
		return false
	return true

func use_skill(player: PlayerData, skill_name: String, target_id: int = -1) -> bool:
	if not can_use_skill(player, skill_name):
		return false
	var data = SKILL_DATA[skill_name]
	if data.needs_target and target_id < 0:
		return false

	player.gold -= data.cost
	if data.cooldown > 0:
		player.skill_cooldowns[skill_name] = data.cooldown

	skill_used.emit(skill_name, player.id)
	GameManager.log_message.emit("某人使用了 %s" % skill_name)

	_apply_skill_effect(player, skill_name, target_id)

	if skill_name == "暗杀":
		var idx = player.skills.find("暗杀")
		if idx >= 0:
			player.skills.remove_at(idx)

	return true

func _apply_skill_effect(user: PlayerData, skill_name: String, target_id: int) -> void:
	match skill_name:
		"背刺":
			_apply_backstab(user)
		"护盾":
			user.is_shielded = true
		"冲刺":
			AuctionSystem.on_timer_expired()
		"透视":
			_apply_peek(user)
		"破坏":
			_apply_sabotage(target_id)
		"祝福":
			user.bid_discount = 0.8
		"巧舌如簧":
			_apply_persuade(target_id)
		"暗杀":
			_apply_assassinate(user, target_id)

func _apply_backstab(user: PlayerData) -> void:
	if AuctionSystem.current_highest_bidder < 0:
		return
	var target = GameManager.get_player(AuctionSystem.current_highest_bidder)
	if not target or target.id == user.id or target.is_shielded:
		return
	var steal_amount = int(float(target.gold) * 0.1)
	target.gold -= steal_amount
	user.gold += steal_amount
	GameManager.log_message.emit("偷取了 %s 的 %d 金币" % [target.name, steal_amount])

func _apply_peek(user: PlayerData) -> void:
	if GameManager.auction_items_pool.is_empty():
		GameManager.log_message.emit("没有更多物品可看")
		return
	var next_item = GameManager.auction_items_pool[0]
	GameManager.log_message.emit("你看到了下一件物品: %s (%s, 起拍价: %d)" % [
		next_item.name, next_item.rarity, next_item.starting_price])

func _apply_sabotage(target_id: int) -> void:
	var target = GameManager.get_player(target_id)
	if not target or target.is_shielded:
		return
	target.bid_willingness = 0.0
	GameManager.log_message.emit("目标 %s 本轮无法出价" % target.name)

func _apply_persuade(target_id: int) -> void:
	var target = GameManager.get_player(target_id)
	if not target or target.is_shielded:
		return
	target.bid_willingness = 0.2
	GameManager.log_message.emit("目标 %s 的出价意愿降低" % target.name)

func _apply_assassinate(user: PlayerData, target_id: int) -> void:
	var target = GameManager.get_player(target_id)
	if not target:
		return
	if target.is_shielded:
		GameManager.log_message.emit("%s 的暗杀被护盾挡住!" % target.name)
		return
	target.items.clear()
	target.gold = 0
	target.debt = 0
	GameManager.eliminate_player(target_id)
	var alive_count = GameManager.get_alive_players().size()
	if alive_count <= 1:
		GameManager.end_game()
