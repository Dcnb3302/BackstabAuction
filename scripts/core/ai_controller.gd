extends Node

func calculate_bid(ai: PlayerData, item: AuctionItem, current_highest: int) -> int:
	if not ai.is_alive:
		return 0

	var risk = ai.ai_params.get("risk_tolerance", 0.3)
	var estimated_value = int(float(item.base_value) * (0.5 + risk))

	var reserve_ratio = ai.ai_params.get("fund_reserve", 0.4)
	var reserve_amount = int(float(ai.gold) * reserve_ratio)
	var max_can_spend = ai.gold - reserve_amount

	var max_bid = mini(estimated_value, max_can_spend)
	if max_bid <= current_highest:
		return 0

	var aggression = ai.ai_params.get("aggression", 0.3)
	var increment = 0
	if aggression > 0.5:
		increment = randi_range(20, 70)
	elif aggression > 0.3:
		increment = randi_range(10, 40)
	else:
		increment = randi_range(5, 25)

	var target_bid = current_highest + increment
	target_bid = mini(target_bid, max_bid)
	if target_bid <= current_highest:
		return 0

	return target_bid

func calculate_sealed_bid(ai: PlayerData, item: AuctionItem) -> int:
	if not ai.is_alive:
		return 0

	var risk = ai.ai_params.get("risk_tolerance", 0.3)
	var estimated_value = int(float(item.base_value) * (0.5 + risk))

	var reserve_ratio = ai.ai_params.get("fund_reserve", 0.4)
	var reserve_amount = int(float(ai.gold) * reserve_ratio)
	var available = ai.gold - reserve_amount

	var bid = int(float(available) * randf_range(0.4, 0.8))
	bid = mini(bid, estimated_value)
	bid = mini(bid, ai.gold)
	bid = maxi(bid, item.starting_price)

	return bid

func ai_should_use_skill(ai: PlayerData) -> bool:
	return randf() < 0.15

func ai_select_skill(ai: PlayerData) -> String:
	if ai.skills.is_empty():
		return ""
	var usable = []
	for skill in ai.skills:
		if IdentitySkillSystem.can_use_skill(ai, skill):
			usable.append(skill)
	if usable.is_empty():
		return ""
	return usable[randi() % usable.size()]

func ai_select_target(ai: PlayerData) -> int:
	var candidates = GameManager.get_other_alive_players(ai.id)
	if candidates.is_empty():
		return -1
	var best = candidates[0]
	for c in candidates:
		if c.get_net_worth() > best.get_net_worth():
			best = c
	return best.id

func process_ai_skill_turn(ai: PlayerData) -> void:
	if not ai.is_alive:
		return
	if ai_should_use_skill(ai):
		var skill = ai_select_skill(ai)
		if skill == "":
			return
		var data = IdentitySkillSystem.SKILL_DATA[skill]
		if data.needs_target:
			var target = ai_select_target(ai)
			if target >= 0:
				IdentitySkillSystem.use_skill(ai, skill, target)
		else:
			IdentitySkillSystem.use_skill(ai, skill)
