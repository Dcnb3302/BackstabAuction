extends Node

signal auction_started(item: AuctionItem)
signal bid_placed(player_id: int, amount: int)
signal auction_ended(winner_id: int, price: int, item: Dictionary)
signal sealed_bids_ready
signal human_sealed_bid_confirmed

enum AuctionType { NORMAL, SEALED }

var current_auction_type: int = AuctionType.NORMAL
var current_item: AuctionItem
var current_highest_bid: int = 0
var current_highest_bidder: int = -1
var min_bid_increment: int = 10
var is_auction_active: bool = false
var sealed_bids: Dictionary = {}
var ai_bid_queue: Array = []
var ai_bid_index: int = 0

func _ready() -> void:
	pass

func start_normal_auction(item: AuctionItem) -> void:
	current_auction_type = AuctionType.NORMAL
	current_item = item
	current_highest_bid = item.starting_price
	current_highest_bidder = -1
	is_auction_active = true
	sealed_bids.clear()
	ai_bid_queue.clear()
	ai_bid_index = 0

	var alive_players = GameManager.get_alive_players()
	for player in alive_players:
		if player.player_type == PlayerData.PlayerType.AI:
			ai_bid_queue.append(player.id)
	ai_bid_queue.shuffle()

	GameManager.start_timer(GameManager.ROUND_TIME)
	auction_started.emit(item)

func start_sealed_auction(item: AuctionItem) -> void:
	current_auction_type = AuctionType.SEALED
	current_item = item
	sealed_bids.clear()
	is_auction_active = true

	var alive_players = GameManager.get_alive_players()
	for player in alive_players:
		if player.player_type == PlayerData.PlayerType.AI:
			var bid = AIController.calculate_sealed_bid(player, item)
			if bid >= item.starting_price:
				sealed_bids[player.id] = bid
			elif item.starting_price <= player.gold:
				sealed_bids[player.id] = item.starting_price

	sealed_bids_ready.emit()

func submit_human_sealed_bid(amount: int) -> void:
	if current_auction_type != AuctionType.SEALED:
		return
	if amount < current_item.starting_price:
		return
	var human = GameManager.get_human_player()
	if not human or not human.is_alive:
		return
	if amount > human.gold:
		amount = human.gold

	sealed_bids[human.id] = amount
	GameManager.log_message.emit("你出价 %d 金币 (密封)" % amount)
	human_sealed_bid_confirmed.emit()
	call_deferred("_resolve_sealed_after_delay")

func _resolve_sealed_after_delay() -> void:
	await GameManager.get_tree().create_timer(1.5).timeout
	_resolve_sealed_auction()

func _resolve_sealed_auction() -> void:
	var highest_bid = 0
	var winner_id = -1

	for player_id in sealed_bids:
		var bid = sealed_bids[player_id]
		var player = GameManager.get_player(player_id)
		if not player or not player.is_alive:
			continue
		if bid > highest_bid:
			highest_bid = bid
			winner_id = player_id
		elif bid == highest_bid:
			if randf() > 0.5:
				winner_id = player_id

	if winner_id >= 0:
		var winner = GameManager.get_player(winner_id)
		if winner and winner.is_alive:
			winner.gold -= highest_bid
			current_item.reveal_quality()
			var item_dict = current_item.to_dict()
			winner.add_item(item_dict)
			GameManager.log_message.emit("%s 以 %d 金币拍下 %s (品相: %s, 价值: %d)" % [
				winner.name, highest_bid, current_item.name,
				current_item.get_quality_name_zh(), current_item.get_actual_value()])
	else:
		current_item.reveal_quality()
		GameManager.log_message.emit("%s 流拍" % current_item.name)

	auction_ended.emit(winner_id, highest_bid, current_item.to_dict())
	_after_auction()

func place_bid(player_id: int, amount: int) -> void:
	var player = GameManager.get_player(player_id)
	if not player or not player.is_alive:
		return
	if amount < current_highest_bid + min_bid_increment:
		return
	var adjusted_amount = int(float(amount) * player.bid_discount)
	if adjusted_amount > player.gold:
		return

	current_highest_bid = adjusted_amount
	current_highest_bidder = player_id
	bid_placed.emit(player_id, adjusted_amount)

	if player.player_type == PlayerData.PlayerType.HUMAN:
		GameManager.log_message.emit("你出价 %d 金币" % adjusted_amount)
	else:
		GameManager.log_message.emit("%s 出价 %d 金币" % [player.name, adjusted_amount])

func on_timer_expired() -> void:
	if not is_auction_active:
		return

	if current_auction_type == AuctionType.NORMAL:
		if current_highest_bidder >= 0:
			var winner = GameManager.get_player(current_highest_bidder)
			if winner and winner.is_alive:
				winner.gold -= current_highest_bid
				current_item.reveal_quality()
				winner.add_item(current_item.to_dict())
				GameManager.log_message.emit("%s 以 %d 金币拍下 %s (品相: %s, 价值: %d)" % [
					winner.name, current_highest_bid, current_item.name,
					current_item.get_quality_name_zh(), current_item.get_actual_value()])
		else:
			if current_item:
				current_item.reveal_quality()
				GameManager.log_message.emit("%s 流拍" % current_item.name)

		auction_ended.emit(current_highest_bidder, current_highest_bid, current_item.to_dict())
		_after_auction()

func process_next_ai_bid() -> void:
	if not is_auction_active:
		return
	if current_auction_type != AuctionType.NORMAL:
		return
	if ai_bid_index >= ai_bid_queue.size():
		return

	var player_id = ai_bid_queue[ai_bid_index]
	ai_bid_index += 1
	var ai = GameManager.get_player(player_id)
	if not ai or not ai.is_alive:
		return

	if randf() < ai.ai_params.get("bid_willingness", 0.5) * ai.bid_willingness:
		var ai_bid = AIController.calculate_bid(ai, current_item, current_highest_bid)
		var max_affordable = ai.gold
		if ai_bid > current_highest_bid and ai_bid <= max_affordable:
			place_bid(ai.id, ai_bid)

func _after_auction() -> void:
	is_auction_active = false
	current_highest_bidder = -1
	current_highest_bid = 0
	ai_bid_queue.clear()
	ai_bid_index = 0
	sealed_bids.clear()
	GameManager.stop_timer()
	GameManager._go_to_next_phase()

func human_bid(amount: int) -> void:
	if current_auction_type != AuctionType.NORMAL:
		return
	if not is_auction_active:
		return
	var human = GameManager.get_human_player()
	if not human or not human.is_alive:
		return
	if amount < current_highest_bid + min_bid_increment:
		return
	var adjusted_amount = int(float(amount) * human.bid_discount)
	if adjusted_amount > human.gold:
		return
	place_bid(human.id, amount)
