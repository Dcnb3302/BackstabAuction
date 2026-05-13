extends Control

@onready var top_bar: HBoxContainer = $VBoxContainer/TopBar
@onready var round_label: Label = $VBoxContainer/TopBar/RoundLabel
@onready var phase_label: Label = $VBoxContainer/TopBar/PhaseLabel
@onready var timer_label: Label = $VBoxContainer/TopBar/TimerLabel
@onready var gold_label: Label = $VBoxContainer/MainHBox/LeftPanel/InfoBar/GoldLabel
@onready var debt_label: Label = $VBoxContainer/MainHBox/LeftPanel/InfoBar/DebtLabel
@onready var net_worth_label: Label = $VBoxContainer/MainHBox/LeftPanel/InfoBar/NetWorthLabel
@onready var item_name_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/ItemNameLabel
@onready var item_rarity_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/ItemRarityLabel
@onready var item_desc_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/ItemDescLabel
@onready var starting_price_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/StartingPriceLabel
@onready var current_bid_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/CurrentBidLabel
@onready var quality_label: Label = $VBoxContainer/MainHBox/LeftPanel/ItemPanel/VBoxContainer/QualityLabel
@onready var sealed_bid_panel: PanelContainer = $VBoxContainer/MainHBox/LeftPanel/SealedBidPanel
@onready var sealed_bid_input: SpinBox = $VBoxContainer/MainHBox/LeftPanel/SealedBidPanel/VBoxContainer/SealedBidInput
@onready var sealed_bid_confirm: Button = $VBoxContainer/MainHBox/LeftPanel/SealedBidPanel/VBoxContainer/SealedBidConfirm
@onready var skill_buttons: HBoxContainer = $VBoxContainer/MainHBox/LeftPanel/SkillPanel/VBoxContainer/SkillButtons
@onready var bid_small: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/BidSmall
@onready var bid_medium: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/BidMedium
@onready var bid_large: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/BidLarge
@onready var loan_btn: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/LoanButton
@onready var ai_bid_btn: Button = $VBoxContainer/MainHBox/LeftPanel/ActionPanel/ProcessAIBid
@onready var players_list: VBoxContainer = $VBoxContainer/MainHBox/RightPanel/PlayersPanel/VBoxContainer/PlayersList
@onready var log_text: RichTextLabel = $VBoxContainer/MainHBox/RightPanel/LogPanel/ScrollContainer/LogText
@onready var menu_btn: Button = $VBoxContainer/TopBar/MenuButton

@onready var overlay_panel: PanelContainer = $VBoxContainer/OverlayPanel
@onready var overlay_container: VBoxContainer = $VBoxContainer/OverlayPanel/OverlayContainer
@onready var close_overlay_btn: Button = $VBoxContainer/OverlayPanel/CloseButton
@onready var tutorial_overlay: PanelContainer = $VBoxContainer/TutorialOverlay
@onready var tutorial_title: Label = $VBoxContainer/TutorialOverlay/VBoxContainer/TutorialTitle
@onready var tutorial_desc: Label = $VBoxContainer/TutorialOverlay/VBoxContainer/TutorialDesc
@onready var tutorial_next_btn: Button = $VBoxContainer/TutorialOverlay/VBoxContainer/TutorialNextButton
@onready var tutorial_skip_btn: Button = $VBoxContainer/TutorialOverlay/VBoxContainer/TutorialSkipButton
@onready var achievement_popup: PanelContainer = $VBoxContainer/AchievementPopup

var log_messages: Array = []
var current_item: AuctionItem
var pending_overlay: String = ""

func _ready() -> void:
	_connect_buttons()
	_connect_signals()
	_update_all()
	_hide_overlay()
	_hide_tutorial()
	_hide_achievement_popup()
	
	if TutorialSystem.is_tutorial_active():
		_show_tutorial()

func _connect_buttons() -> void:
	bid_small.pressed.connect(func(): _on_bid_pressed(10))
	bid_medium.pressed.connect(func(): _on_bid_pressed(30))
	bid_large.pressed.connect(func(): _on_bid_pressed(50))
	loan_btn.pressed.connect(_on_loan_pressed)
	ai_bid_btn.pressed.connect(_on_process_ai_bid_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	close_overlay_btn.pressed.connect(_hide_overlay)
	sealed_bid_confirm.pressed.connect(_on_sealed_bid_confirm_pressed)
	tutorial_next_btn.pressed.connect(_on_tutorial_next)
	tutorial_skip_btn.pressed.connect(_on_tutorial_skip)

func _connect_signals() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.round_started.connect(_on_round_started)
	GameManager.timer_updated.connect(_on_timer_updated)
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.log_message.connect(_on_log_message)
	GameManager.interest_applied.connect(_on_interest_applied)
	AuctionSystem.auction_started.connect(_on_auction_started)
	AuctionSystem.bid_placed.connect(_on_bid_placed)
	AuctionSystem.auction_ended.connect(_on_auction_ended)
	AuctionSystem.sealed_bids_ready.connect(_on_sealed_bids_ready)
	AuctionSystem.human_sealed_bid_confirmed.connect(_on_human_sealed_bid_confirmed)
	BlackMarketSystem.trade_initiated.connect(_on_trade_initiated)
	AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	TutorialSystem.tutorial_step_changed.connect(_on_tutorial_step_changed)

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
	net_worth_label.text = "净资产: %d" % human.get_net_worth()
	round_label.text = "第 %d/%d 轮" % [GameManager.current_round, GameManager.TOTAL_ROUNDS]
	var phase_names = ["准备中", "拍卖中", "黑市", "密封拍卖", "结束"]
	if GameManager.current_phase < phase_names.size():
		phase_label.text = phase_names[GameManager.current_phase]

func _update_players() -> void:
	for child in players_list.get_children():
		child.queue_free()
	
	var alive_players = GameManager.get_alive_players()
	alive_players.sort_custom(func(a, b): return a.get_net_worth() > b.get_net_worth())
	
	for player in alive_players:
		var row = HBoxContainer.new()
		var lbl = Label.new()
		
		if player.id == GameManager.human_player_id:
			lbl.text = "你 [%s]" % player.identity
			lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		else:
			lbl.text = "%s [???]" % player.name
		
		row.add_child(lbl)
		
		var gold_lbl = Label.new()
		if player.id == GameManager.human_player_id:
			gold_lbl.text = "💰 %d" % player.gold
		else:
			gold_lbl.text = "💰 ??"
		gold_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(gold_lbl)
		
		players_list.add_child(row)
	
	for player in GameManager.players:
		if not player.is_alive:
			var row = HBoxContainer.new()
			var lbl = Label.new()
			lbl.text = "%s [已淘汰]" % player.name
			lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
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
		btn.tooltip_text = data.description + "\n冷却: %d轮" % data.cooldown if data.cooldown > 0 else "冷却: 无"
		btn.pressed.connect(_on_skill_pressed.bind(skill))
		if not IdentitySkillSystem.can_use_skill(human, skill):
			btn.disabled = true
		skill_buttons.add_child(btn)

func _update_sealed_bid_panel() -> void:
	if not sealed_bid_panel:
		return
	sealed_bid_panel.visible = (
		AuctionSystem.current_auction_type == AuctionSystem.AuctionType.SEALED and
		AuctionSystem.is_auction_active
	)
	if sealed_bid_input and current_item:
		var human = GameManager.get_human_player()
		sealed_bid_input.min_value = current_item.starting_price
		sealed_bid_input.max_value = human.gold if human else 0
		sealed_bid_input.value = current_item.starting_price

func _on_game_started() -> void:
	_add_log("=== 游戏开始! ===")
	_update_all()
	_animate_panel_appearance()

func _animate_panel_appearance() -> void:
	if item_name_label:
		var tween = create_tween()
		tween.tween_property(item_name_label, "scale", Vector2(1.1, 1.1), 0.15)
		tween.tween_property(item_name_label, "scale", Vector2(1, 1), 0.15)

func _animate_item_reveal() -> void:
	if item_name_label:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(item_name_label, "modulate", Color(1, 0.9, 0.3, 0), 0.0)
		tween.tween_property(item_name_label, "modulate", Color(1, 0.9, 0.3, 1), 0.3)

func _animate_bid_update() -> void:
	if current_bid_label:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(current_bid_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(current_bid_label, "scale", Vector2(1, 1), 0.15)

func _on_round_started(_round: int) -> void:
	_update_all()
	_update_players()
	_update_skill_buttons()

func _on_timer_updated(time: float) -> void:
	timer_label.text = "⏱ %.1f秒" % maxf(0.0, time)
	if time <= 5.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		timer_label.remove_theme_color_override("font_color")

func _on_phase_changed(phase: String) -> void:
	var phase_names = {"lobby": "准备中", "auction": "拍卖中", "black_market": "黑市", "sealed_bid": "密封拍卖", "end_game": "结束"}
	phase_label.text = phase_names.get(phase, phase)
	_update_all()

func _on_auction_started(item: AuctionItem) -> void:
	current_item = item
	item_name_label.text = "📦 %s" % item.name
	item_rarity_label.text = "稀有度: %s" % item.rarity
	var desc = "这是一件神秘的拍卖品，其真实价值尚待揭晓..."
	item_desc_label.text = desc
	starting_price_label.text = "起拍价: %d 金币" % item.starting_price
	current_bid_label.text = "当前最高: %d" % item.starting_price
	quality_label.text = "品相: ???"
	quality_label.visible = false

	_update_sealed_bid_panel()

	if AuctionSystem.current_auction_type == AuctionSystem.AuctionType.SEALED:
		bid_small.disabled = true
		bid_medium.disabled = true
		bid_large.disabled = true
		loan_btn.disabled = true
		ai_bid_btn.visible = false
	else:
		bid_small.disabled = false
		bid_medium.disabled = false
		bid_large.disabled = false
		loan_btn.disabled = false
		ai_bid_btn.visible = true

	_animate_item_reveal()

func _on_bid_placed(player_id: int, amount: int) -> void:
	var player = GameManager.get_player(player_id)
	if player:
		current_bid_label.text = "当前最高: %d (%s)" % [amount, player.name]
		_animate_bid_update()
	_update_info_bar()

func _on_auction_ended(winner_id: int, price: int, _item: Dictionary) -> void:
	if winner_id >= 0:
		var winner = GameManager.get_player(winner_id)
		if winner:
			current_bid_label.text = "✅ %s 以 %d 金币获得" % [winner.name, price]
			if current_item and current_item.quality_revealed:
				var qname = current_item.get_quality_name_zh()
				var qval = current_item.get_actual_value()
				quality_label.text = "品相: %s (价值: %d)" % [qname, qval]
				quality_label.visible = true
				quality_label.add_theme_color_override("font_color", current_item.get_quality_color())
	else:
		current_bid_label.text = "❌ 流拍! 无人出价"
		if current_item:
			current_item.reveal_quality()
			quality_label.text = "品相: %s" % current_item.get_quality_name_zh()
			quality_label.visible = true

	bid_small.disabled = true
	bid_medium.disabled = true
	bid_large.disabled = true
	loan_btn.disabled = true
	ai_bid_btn.visible = false

	_update_sealed_bid_panel()
	_update_all()

func _on_sealed_bids_ready() -> void:
	_update_sealed_bid_panel()
	_update_all()

func _on_human_sealed_bid_confirmed() -> void:
	current_bid_label.text = "✅ 你已提交密封出价!"
	sealed_bid_panel.visible = false
	_update_all()

func _on_trade_initiated(_from: int, _to: int, _offer: int, _request: int) -> void:
	_update_all()

func _on_achievement_unlocked(_id: String, name: String, _desc: String) -> void:
	_show_achievement_popup(name)

func _on_tutorial_step_changed(_step: int, step_data: Dictionary) -> void:
	if TutorialSystem.is_tutorial_active():
		tutorial_title.text = step_data.get("title", "")
		tutorial_desc.text = step_data.get("description", "")

func _on_game_ended() -> void:
	_add_log("=== 游戏结束! ===")
	var winner = GameManager.get_winner()
	if winner:
		_add_log("🏆 胜利者: %s (净资产: %d)" % [winner.name, winner.get_net_worth()])
	
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/end_game/end_game.tscn")

func _on_log_message(msg: String) -> void:
	_add_log(msg)

func _add_log(msg: String) -> void:
	log_messages.append(msg)
	var max_size = SettingsSystem.get_setting("log_history_size")
	if max_size == null:
		max_size = 100
	if log_messages.size() > max_size:
		log_messages.pop_front()
	if log_text:
		var display_text = ""
		for m in log_messages:
			display_text += m + "\n"
		log_text.text = display_text

func _on_interest_applied(player_id: int, amount: int) -> void:
	if player_id == GameManager.human_player_id:
		_add_log("💰 存款利息: +%d 金币" % amount)
		_update_info_bar()

func _on_bid_pressed(amount_offset: int) -> void:
	var new_bid = AuctionSystem.current_highest_bid + amount_offset
	AuctionSystem.human_bid(new_bid)

func _on_skill_pressed(skill_name: String) -> void:
	var human = GameManager.get_human_player()
	if not human:
		return
	var data = IdentitySkillSystem.SKILL_DATA[skill_name]
	if data.needs_target:
		var candidates = GameManager.get_other_alive_players(GameManager.human_player_id)
		if candidates.is_empty():
			_add_log("⚠ 没有可用目标")
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

func _on_menu_pressed() -> void:
	_show_overlay("menu")

func _show_overlay(type: String) -> void:
	pending_overlay = type
	overlay_panel.visible = true
	
	for child in overlay_container.get_children():
		child.queue_free()
	
	match type:
		"menu": _build_menu_overlay()
		"stats": _build_stats_overlay()

func _hide_overlay() -> void:
	overlay_panel.visible = false
	pending_overlay = ""

func _build_menu_overlay() -> void:
	var title = Label.new()
	title.text = "游戏菜单"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_container.add_child(title)
	
	var sep = HSeparator.new()
	overlay_container.add_child(sep)
	
	var resume_btn = Button.new()
	resume_btn.text = "继续游戏"
	resume_btn.pressed.connect(_hide_overlay)
	overlay_container.add_child(resume_btn)
	
	var stats_btn = Button.new()
	stats_btn.text = "统计数据"
	stats_btn.pressed.connect(func(): _show_overlay("stats"))
	overlay_container.add_child(stats_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "返回主菜单"
	quit_btn.pressed.connect(func(): 
		get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
	)
	overlay_container.add_child(quit_btn)

func _build_stats_overlay() -> void:
	var title = Label.new()
	title.text = "统计数据"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_container.add_child(title)
	
	var sep = HSeparator.new()
	overlay_container.add_child(sep)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_container.add_child(scroll)
	
	var content = VBoxContainer.new()
	scroll.add_child(content)
	
	var back_btn = Button.new()
	back_btn.text = "返回菜单"
	back_btn.pressed.connect(func(): _show_overlay("menu"))
	content.add_child(back_btn)
	
	var stats_keys = [
		"games_played", "games_won", "games_lost", "current_streak", "best_streak",
		"total_gold_earned", "total_gold_spent", "total_items_bought",
		"total_skills_used", "total_auctions_won", "sealed_auctions_won",
		"total_backstabs", "total_assassinations", "highest_single_bid",
		"highest_net_worth", "best_identity", "events_triggered"
	]
	
	for key in stats_keys:
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = StatsSystem.get_stat_name_zh(key) + ":"
		name_lbl.custom_minimum_size = Vector2(140, 0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = StatsSystem.get_formatted_stat(key)
		val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(val_lbl)
		content.add_child(row)

func _show_tutorial() -> void:
	tutorial_overlay.visible = true
	var step = TutorialSystem.get_current_step_data()
	tutorial_title.text = step.get("title", "")
	tutorial_desc.text = step.get("description", "")

func _hide_tutorial() -> void:
	tutorial_overlay.visible = false

func _on_tutorial_next() -> void:
	TutorialSystem.next_step()
	if TutorialSystem.is_tutorial_active():
		_show_tutorial()
	else:
		_hide_tutorial()

func _on_tutorial_skip() -> void:
	TutorialSystem.complete_tutorial()
	_hide_tutorial()

func _show_achievement_popup(name: String) -> void:
	achievement_popup.visible = true
	var lbl = achievement_popup.get_node_or_null("VBoxContainer/Label")
	if lbl:
		lbl.text = "🏆 成就解锁: %s" % name
	
	await get_tree().create_timer(3.0).timeout
	achievement_popup.visible = false

func _hide_achievement_popup() -> void:
	achievement_popup.visible = false
