extends Control

@onready var round_label: Label = $VBoxContainer/TopBar/RoundLabel
@onready var phase_label: Label = $VBoxContainer/TopBar/PhaseLabel
@onready var timer_label: Label = $VBoxContainer/TopBar/TimerLabel
@onready var gold_label: Label = $VBoxContainer/MainHBox/LeftPanel/InfoBar/GoldLabel
@onready var debt_label: Label = $VBoxContainer/MainHBox/LeftPanel/InfoBar/DebtLabel
@onready var item_name_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/ItemNameLabel
@onready var item_rarity_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/ItemRarityLabel
@onready var starting_price_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/StartingPriceLabel
@onready var current_bid_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/CurrentBidLabel
@onready var quality_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/QualityLabel
@onready var sealed_bid_panel: PanelContainer = $VBoxContainer/MainHBox/LeftPanel/SealedBidPanel
@onready var sealed_bid_input: SpinBox = $VBoxContainer/MainHBox/LeftPanel/SealedBidPanel/VBoxContainer/SealedBidInput
@onready var sealed_bid_price_label: Label = $VBoxContainer/MainHBox/LeftPanel/SealedBidPanel/VBoxContainer/StartingPriceInfo
@onready var skill_buttons: HBoxContainer = $VBoxContainer/MainHBox/LeftPanel/SkillPanel/VBoxContainer/SkillButtons
@onready var bid_small: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/BidSmall
@onready var bid_medium: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/BidMedium
@onready var bid_large: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/BidLarge
@onready var loan_btn: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/LoanButton
@onready var ai_bid_btn: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/ProcessAIBid
@onready var players_list: VBoxContainer = $VBoxContainer/MainHBox/RightPanel/PlayersPanel/VBoxContainer/PlayersList
@onready var log_text: RichTextLabel = $VBoxContainer/MainHBox/RightPanel/LogPanel/ScrollContainer/LogText

var log_messages: Array = []
var current_item: AuctionItem

func _ready() -> void:
	_connect_buttons()
	_connect_signals()
	_update_all()

func _connect_buttons() -> void:
	bid_small.pressed.connect(_on_bid_small_pressed)
	bid_medium.pressed.connect(_on_bid_medium_pressed)
	bid_large.pressed.connect(_on_bid_large_pressed)
	loan_btn.pressed.connect(_on_loan_pressed)
	ai_bid_btn.pressed.connect(_on_process_ai_bid_pressed)
	if sealed_bid_panel:
		var confirm_btn = sealed_bid_panel.get_node_or_null("VBoxContainer/SealedBidConfirm")
		if confirm_btn:
			confirm_btn.pressed.connect(_on_sealed_bid_confirm_pressed)

func _connect_signals() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.round_started.connect(_on_round_started)
	GameManager.timer_updated.connect(_on_timer_updated)
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.log_message.connect(_on_log_message)
	AuctionSystem.auction_started.connect(_on_auction_started)
	AuctionSystem.bid_placed.connect(_on_bid_placed)
	AuctionSystem.auction_ended.connect(_on_auction_ended)
	AuctionSystem.sealed_bids_ready.connect(_on_sealed_bids_ready)
	AuctionSystem.human_sealed_bid_confirmed.connect(_on_human_sealed_bid_confirmed)

func _process(delta: float) -> void:
	if GameManager.is_timer_running:
		GameManager.tick_timer(delta)

func _update_all() -> void:
	_update_info_bar()
	_update_players()
	_update_skill_buttons()

func _update_info_bar() -> void:
	var human = GameManager.get_human_player()
	if not human:
		return
	gold_label.text = "金币: %d" % human.gold
	debt_label.text = "欠款: %d" % human.debt
	round_label.text = "第 %d/%d 轮" % [GameManager.current_round, GameManager.TOTAL_ROUNDS]
	var phase_names = ["准备中", "拍卖中", "黑市", "密封拍卖", "结束"]
	if GameManager.current_phase < phase_names.size():
		phase_label.text = phase_names[GameManager.current_phase]

func _update_players() -> void:
	for child in players_list.get_children():
		child.queue_free()

	for player in GameManager.players:
		var row = HBoxContainer.new()
		var lbl = Label.new()

		if player.id == GameManager.human_player_id:
			lbl.text = "你 [%s] 金币:%d 欠款:%d" % [player.identity, player.gold, player.debt]
		elif player.is_alive:
			lbl.text = "%s [???] 金币:?? 欠款:??" % [player.name]
		else:
			lbl.text = "%s [已淘汰]" % [player.name]

		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		players_list.add_child(row)

func _update_skill_buttons() -> void:
	for child in skill_buttons.get_children():
		child.queue_free()

	var human = GameManager.get_human_player()
	if not human or not human.is_alive:
		return

	for skill in human.skills:
		var btn = Button.new()
		var data = IdentitySkillSystem.SKILL_DATA[skill]
		btn.text = "%s (%dg)" % [skill, data.cost]
		btn.tooltip_text = data.description
		btn.pressed.connect(_on_skill_pressed.bind(skill))
		if not IdentitySkillSystem.can_use_skill(human, skill):
			btn.disabled = true
		skill_buttons.add_child(btn)

func _update_sealed_bid_panel() -> void:
	if not sealed_bid_panel:
		return
	sealed_bid_panel.visible = (
		AuctionSystem.current_auction_type == AuctionSystem.AuctionType.SEALED and
		AuctionSystem.is_auction_active and
		not AuctionSystem.human_sealed_bid_submitted
	)
	if sealed_bid_input and current_item:
		var human = GameManager.get_human_player()
		sealed_bid_input.min_value = current_item.starting_price
		sealed_bid_input.max_value = human.gold if human else 0
		sealed_bid_input.value = current_item.starting_price
	if sealed_bid_price_label and current_item:
		sealed_bid_price_label.text = "起拍价: %d 金币" % current_item.starting_price

func _on_game_started() -> void:
	_add_log("=== 游戏开始! ===")
	_update_all()

func _on_round_started(_round: int) -> void:
	_update_all()
	_update_players()
	_update_skill_buttons()

func _on_timer_updated(time: float) -> void:
	timer_label.text = "剩余: %.1f秒" % maxf(0.0, time)

func _on_phase_changed(phase: String) -> void:
	var phase_names = {"lobby": "准备中", "auction": "拍卖中", "black_market": "黑市", "sealed_bid": "密封拍卖", "end_game": "结束"}
	phase_label.text = phase_names.get(phase, phase)
	_update_all()

func _on_auction_started(item: AuctionItem) -> void:
	current_item = item
	item_name_label.text = "物品: %s" % item.name
	item_rarity_label.text = "稀有度: %s" % item.rarity
	starting_price_label.text = "起拍价: %d" % item.starting_price
	current_bid_label.text = "当前最高: %d" % item.starting_price
	quality_label.text = "品相: ???"
	quality_label.visible = false

	_update_sealed_bid_panel()

	if AuctionSystem.current_auction_type == AuctionSystem.AuctionType.SEALED:
		bid_small.disabled = true
		bid_medium.disabled = true
		bid_large.disabled = true
		loan_btn.disabled = true
		if ai_bid_btn: ai_bid_btn.visible = false
	else:
		bid_small.disabled = false
		bid_medium.disabled = false
		bid_large.disabled = false
		loan_btn.disabled = false
		if ai_bid_btn: ai_bid_btn.visible = true

func _on_bid_placed(player_id: int, amount: int) -> void:
	var player = GameManager.get_player(player_id)
	if player:
		current_bid_label.text = "当前最高: %d (%s)" % [amount, player.name]
	_update_info_bar()

func _on_auction_ended(winner_id: int, price: int, _item: Dictionary) -> void:
	if winner_id >= 0:
		var winner = GameManager.get_player(winner_id)
		if winner:
			current_bid_label.text = "成交! %s 以 %d 金币获得" % [winner.name, price]
			if current_item and current_item.quality_revealed:
				quality_label.text = "品相: %s (价值: %d)" % [current_item.get_quality_name_zh(), current_item.get_actual_value()]
				quality_label.visible = true
	else:
		current_bid_label.text = "流拍! 无人出价"
		if current_item:
			current_item.reveal_quality()
			quality_label.text = "品相: %s" % current_item.get_quality_name_zh()
			quality_label.visible = true

	bid_small.disabled = true
	bid_medium.disabled = true
	bid_large.disabled = true
	loan_btn.disabled = true
	if ai_bid_btn: ai_bid_btn.visible = false

	_update_sealed_bid_panel()
	_update_all()

func _on_sealed_bids_ready() -> void:
	_update_sealed_bid_panel()
	_update_all()

func _on_human_sealed_bid_confirmed() -> void:
	current_bid_label.text = "你已提交密封出价!"
	if sealed_bid_panel: sealed_bid_panel.visible = false
	_update_all()

func _on_game_ended() -> void:
	_add_log("=== 游戏结束! ===")
	var winner = GameManager.get_winner()
	if winner:
		_add_log("胜利者: %s (净资产: %d)" % [winner.name, winner.get_net_worth()])
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/end_game/end_game.tscn")

func _on_log_message(msg: String) -> void:
	_add_log(msg)

func _add_log(msg: String) -> void:
	log_messages.append(msg)
	if log_messages.size() > 100:
		log_messages.pop_front()
	if log_text:
		var display_text = ""
		for m in log_messages:
			display_text += m + "\n"
		log_text.text = display_text

func _on_bid_pressed(amount_offset: int) -> void:
	var new_bid = AuctionSystem.current_highest_bid + amount_offset
	AuctionSystem.human_bid(new_bid)

func _on_bid_small_pressed() -> void:
	_on_bid_pressed(10)

func _on_bid_medium_pressed() -> void:
	_on_bid_pressed(30)

func _on_bid_large_pressed() -> void:
	_on_bid_pressed(50)

func _on_skill_pressed(skill_name: String) -> void:
	var data = IdentitySkillSystem.SKILL_DATA[skill_name]
	var human = GameManager.get_human_player()
	if not human: return

	if data.needs_target:
		var candidates = GameManager.get_other_alive_players(GameManager.human_player_id)
		if candidates.is_empty():
			_add_log("没有可用目标")
			return
		IdentitySkillSystem.use_skill(human, skill_name, candidates[0].id)
	else:
		IdentitySkillSystem.use_skill(human, skill_name)

	_update_skill_buttons()
	_update_info_bar()

func _on_loan_pressed() -> void:
	var human = GameManager.get_human_player()
	if human:
		DebtSystem.take_loan(human.id)
		_update_info_bar()

func _on_sealed_bid_confirm_pressed() -> void:
	if sealed_bid_input:
		AuctionSystem.submit_human_sealed_bid(int(sealed_bid_input.value))

func _on_process_ai_bid_pressed() -> void:
	AuctionSystem.process_next_ai_bid()
	_update_info_bar()
	_update_players()
