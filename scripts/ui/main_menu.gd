extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var version_label: Label = $VBoxContainer/VersionLabel
@onready var play_button: Button = $VBoxContainer/CenterButtons/PlayButton
@onready var stats_button: Button = $VBoxContainer/CenterButtons/StatsButton
@onready var achievements_button: Button = $VBoxContainer/CenterButtons/AchievementsButton
@onready var settings_button: Button = $VBoxContainer/CenterButtons/SettingsButton
@onready var tutorial_button: Button = $VBoxContainer/CenterButtons/TutorialButton
@onready var quit_button: Button = $VBoxContainer/CenterButtons/QuitButton

@onready var overlay_panel: PanelContainer = $VBoxContainer/OverlayPanel
@onready var overlay_container: VBoxContainer = $VBoxContainer/OverlayPanel/OverlayContainer
@onready var close_overlay_btn: Button = $VBoxContainer/OverlayPanel/CloseButton

var overlay_type: String = ""

func _ready() -> void:
	title_label.text = "背刺拍卖会"
	subtitle_label.text = "信任是奢侈品，背叛是常态"
	version_label.text = "v1.0.0"
	
	_hide_overlay()
	
	play_button.pressed.connect(_on_play_pressed)
	stats_button.pressed.connect(func(): _show_overlay("stats"))
	achievements_button.pressed.connect(func(): _show_overlay("achievements"))
	settings_button.pressed.connect(func(): _show_overlay("settings"))
	tutorial_button.pressed.connect(func(): _show_overlay("tutorial"))
	quit_button.pressed.connect(func(): get_tree().quit())
	close_overlay_btn.pressed.connect(_hide_overlay)
	
	if SettingsSystem.get_setting("tutorial_enabled") and not AchievementSystem.is_unlocked("first_auction"):
		TutorialSystem.start_tutorial()

func _show_overlay(type: String) -> void:
	overlay_type = type
	overlay_panel.visible = true
	
	for child in overlay_container.get_children():
		child.queue_free()
	
	match type:
		"stats": _build_stats_panel()
		"achievements": _build_achievements_panel()
		"settings": _build_settings_panel()
		"tutorial": _build_tutorial_panel()

func _hide_overlay() -> void:
	overlay_panel.visible = false
	overlay_type = ""

func _build_stats_panel() -> void:
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
	
	var stats_keys = [
		"games_played", "games_won", "games_lost", "current_streak", "best_streak",
		"total_gold_earned", "total_gold_spent", "total_items_bought",
		"total_skills_used", "total_auctions_won", "sealed_auctions_won",
		"total_backstabs", "total_assassinations", "highest_single_bid",
		"highest_net_worth", "best_identity", "events_triggered",
		"players_eliminated", "times_eliminated", "ai_trades_betrayed"
	]
	
	for key in stats_keys:
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = StatsSystem.get_stat_name_zh(key) + ":"
		name_lbl.custom_minimum_size = Vector2(160, 0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = StatsSystem.get_formatted_stat(key)
		val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(val_lbl)
		content.add_child(row)

func _build_achievements_panel() -> void:
	var title = Label.new()
	title.text = "成就 (%d/%d)" % [AchievementSystem.get_unlocked_count(), AchievementSystem.get_total_count()]
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
	
	var all_achs = AchievementSystem.get_all_achievements()
	for ach_id in all_achs:
		var ach = all_achs[ach_id]
		var row = HBoxContainer.new()
		
		var icon = Label.new()
		icon.text = ach.icon
		icon.add_theme_font_size_override("font_size", 24)
		icon.custom_minimum_size = Vector2(40, 0)
		row.add_child(icon)
		
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var name_lbl = Label.new()
		name_lbl.text = ach.name
		name_lbl.add_theme_font_size_override("font_size", 16)
		if AchievementSystem.is_unlocked(ach_id):
			name_lbl.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		info.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = ach.description
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info.add_child(desc_lbl)
		
		row.add_child(info)
		content.add_child(row)

func _build_settings_panel() -> void:
	var title = Label.new()
	title.text = "设置"
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
	
	var settings_list = [
		["ai_count", "AI 数量", "option", [2, 3, 4, 5, 6, 7], ["2人", "3人", "4人", "5人", "6人", "7人"]],
		["ai_difficulty", "AI 难度", "option", [0, 1, 2, 3], ["简单", "普通", "困难", "地狱"]],
		["round_time", "每轮时间", "option", [10, 15, 20, 30], ["10秒", "15秒", "20秒", "30秒"]],
		["window_mode", "窗口模式", "option", [0, 1, 2], ["窗口", "无边框", "全屏"]],
		["show_damage_numbers", "显示伤害数字", "toggle"],
		["screen_shake", "屏幕震动", "toggle"],
		["particle_effects", "粒子效果", "toggle"],
		["animations_enabled", "启用动画", "toggle"]
	]
	
	for setting in settings_list:
		var key = setting[0]
		var name = setting[1]
		var type = setting[2]
		
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = name + ":"
		name_lbl.custom_minimum_size = Vector2(140, 0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(name_lbl)
		
		var current_val = SettingsSystem.get_setting(key)
		
		if type == "option":
			var opts = setting[3]
			var labels = setting[4]
			var opt_btn = OptionButton.new()
			for i in range(opts.size()):
				opt_btn.add_item(labels[i], i)
				if opts[i] == current_val:
					opt_btn.selected = i
			opt_btn.item_selected.connect(func(idx): SettingsSystem.set_setting(key, opts[idx]))
			row.add_child(opt_btn)
		elif type == "toggle":
			var check = CheckBox.new()
			check.button_pressed = current_val
			check.toggled.connect(func(v): SettingsSystem.set_setting(key, v))
			row.add_child(check)
		
		content.add_child(row)
	
	var reset_btn = Button.new()
	reset_btn.text = "重置默认设置"
	reset_btn.pressed.connect(func(): SettingsSystem.reset_to_defaults(); _show_overlay("settings"))
	content.add_child(reset_btn)

func _build_tutorial_panel() -> void:
	var title = Label.new()
	title.text = "教程"
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
	
	var progress = TutorialSystem.get_progress()
	var status_lbl = Label.new()
	status_lbl.text = "状态: " + ("已完成" if progress.completed else "未开始")
	status_lbl.add_theme_font_size_override("font_size", 16)
	content.add_child(status_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = "教程将引导你了解游戏的基本玩法，包括拍卖、技能、黑市交易等核心机制。"
	content.add_child(desc_lbl)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	content.add_child(spacer)
	
	var start_btn = Button.new()
	start_btn.text = "开始教程"
	start_btn.pressed.connect(func(): TutorialSystem.start_tutorial(); _hide_overlay())
	content.add_child(start_btn)
	
	var reset_btn = Button.new()
	reset_btn.text = "重置教程"
	reset_btn.pressed.connect(func(): TutorialSystem.reset_tutorial(); _show_overlay("tutorial"))
	content.add_child(reset_btn)

func _on_play_pressed() -> void:
	var ai_count = SettingsSystem.get_setting("ai_count")
	if ai_count == null:
		ai_count = 4
	var round_time = SettingsSystem.get_setting("round_time")
	if round_time == null:
		round_time = 15
	GameManager.ROUND_TIME = float(round_time)
	GameManager.start_game(ai_count + 1)
	get_tree().change_scene_to_file("res://scenes/main/auction.tscn")
