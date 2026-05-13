extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var results_container: VBoxContainer = $VBoxContainer/ResultsContainer
@onready var stats_container: VBoxContainer = $VBoxContainer/StatsContainer
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_display_results()
	_display_stats()

func _display_results() -> void:
	for child in results_container.get_children():
		child.queue_free()

	var sorted_players = GameManager.players.duplicate()
	sorted_players.sort_custom(func(a, b): return a.get_net_worth() > b.get_net_worth())

	var winner = GameManager.get_winner()
	if winner:
		subtitle_label.text = "🏆 胜利者: %s 🏆" % winner.name

	for i in range(sorted_players.size()):
		var player = sorted_players[i]
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 40)

		var rank = Label.new()
		var rank_color: Color
		match i:
			0:
				rank.text = "🥇 第1名"
				rank_color = Color(1, 0.85, 0.3, 1)
			1:
				rank.text = "🥈 第2名"
				rank_color = Color(0.7, 0.7, 0.7, 1)
			2:
				rank.text = "🥉 第3名"
				rank_color = Color(0.8, 0.4, 0.2, 1)
			_:
				rank.text = "第%d名" % (i + 1)
				rank_color = Color(0.6, 0.6, 0.6, 1)
		rank.add_theme_color_override("font_color", rank_color)
		rank.custom_minimum_size = Vector2(100, 0)
		rank.add_theme_font_size_override("font_size", 16)
		row.add_child(rank)

		var name_lbl = Label.new()
		if player.is_alive:
			name_lbl.text = "%s [%s]" % [player.name, player.identity]
			name_lbl.add_theme_font_size_override("font_size", 16)
		else:
			name_lbl.text = "%s [已淘汰]" % player.name
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
			name_lbl.add_theme_font_size_override("font_size", 16)
		row.add_child(name_lbl)

		var info = Label.new()
		if player.is_alive:
			info.text = "净资产: %d (金币:%d | 物品:%d | 欠款:%d)" % [
				player.get_net_worth(), player.gold,
				player.get_total_item_value(), player.debt]
		else:
			info.text = "净资产: 0"
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		info.add_theme_font_size_override("font_size", 16)
		row.add_child(info)

		if player.id == GameManager.human_player_id:
			var tag = Label.new()
			tag.text = "(你)"
			tag.add_theme_color_override("font_color", Color(1, 1, 0.3, 1))
			tag.add_theme_font_size_override("font_size", 16)
			row.add_child(tag)

		results_container.add_child(row)

func _display_stats() -> void:
	for child in stats_container.get_children():
		child.queue_free()

	var human = GameManager.get_human_player()
	if not human:
		return

	var stats_keys = [
		["回合数", str(GameManager.current_round) + "/30"],
		["拍得物品", str(human.items.size())],
		["使用技能", str(StatsSystem.stats.get("total_skills_used", 0))],
		["总花费金币", str(StatsSystem.stats.get("total_gold_spent", 0))],
		["总获得金币", str(StatsSystem.stats.get("total_gold_earned", 0))],
		["最高单次出价", str(StatsSystem.stats.get("highest_single_bid", 0))],
	]

	for pair in stats_keys:
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = pair[0] + ":"
		name_lbl.custom_minimum_size = Vector2(120, 0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1, 1))
		row.add_child(name_lbl)

		var val_lbl = Label.new()
		val_lbl.text = pair[1]
		val_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
		row.add_child(val_lbl)

		stats_container.add_child(row)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
