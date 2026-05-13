extends Node

signal loan_taken(player_id: int, amount: int)
signal debt_updated(player_id: int, new_debt: int)
signal interest_applied(player_id: int, amount: int)
signal collection_triggered(player_id: int)

const LOAN_AMOUNT: int = 100
const MAX_DEBT: int = 500
const DEBT_INTEREST_RATE: float = 0.15
const FORCED_SELL_DISCOUNT: float = 0.7

func _ready() -> void:
	pass

func take_loan(player_id: int) -> bool:
	var player = GameManager.get_player(player_id)
	if not player or not player.is_alive:
		return false
	if player.debt >= MAX_DEBT:
		GameManager.log_message.emit("已达欠款上限!")
		return false

	player.debt += LOAN_AMOUNT
	player.gold += LOAN_AMOUNT
	loan_taken.emit(player_id, LOAN_AMOUNT)
	debt_updated.emit(player_id, player.debt)

	if player_id == GameManager.human_player_id:
		GameManager.log_message.emit("你借了 %d 金币, 当前欠款: %d" % [LOAN_AMOUNT, player.debt])

	_check_forced_collection(player)
	return true

func apply_debt_interest(player: PlayerData) -> void:
	if player.debt <= 0:
		return

	var interest = int(float(player.debt) * DEBT_INTEREST_RATE)
	player.debt += interest
	interest_applied.emit(player.id, interest)
	debt_updated.emit(player.id, player.debt)

	if player.id == GameManager.human_player_id and interest > 0:
		GameManager.log_message.emit("债务利息: +%d, 总欠款: %d" % [interest, player.debt])

	_check_forced_collection(player)

func _check_forced_collection(player: PlayerData) -> void:
	if player.debt > MAX_DEBT:
		collection_triggered.emit(player.id)
		_force_sell_items(player)

func _force_sell_items(player: PlayerData) -> void:
	while player.debt > MAX_DEBT and not player.items.is_empty():
		var idx = player.get_most_valuable_item_index()
		if idx < 0:
			break
		var item = player.items[idx]
		var sell_price = int(float(item.get("base_value", 0)) * FORCED_SELL_DISCOUNT)
		player.gold += sell_price
		player.debt -= sell_price
		player.items.remove_at(idx)
		if player.id == GameManager.human_player_id:
			GameManager.log_message.emit("强制拍卖: %s 以 %d 金币出售还债" % [item.get("name", "物品"), sell_price])

func apply_all_debts() -> void:
	for player in GameManager.get_alive_players():
		apply_debt_interest(player)
