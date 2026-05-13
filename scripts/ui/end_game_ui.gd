extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var results_container: VBoxContainer = $VBoxContainer/ResultsContainer
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	title_label.text = "游戏结束"
	back_button.text = "返回主菜单"
	_display_results()

func _display_results() -> void:
	for child in results_container.get_children():
		child.queue_free()

	for i in range(GameManager.players.size()):
		var player = GameManager.players[i]
		var row = HBoxContainer.new()

		var rank = Label.new()
		rank.text = "第%d名:" % (i + 1)
		rank.custom_minimum_size = Vector2(80, 0)
		row.add_child(rank)

		var info = Label.new()
		if player.is_alive:
			info.text = "%s [%s] 净资产: %d (金币:%d 物品:%d 欠款:%d)" % [
				player.name, player.identity,
				player.get_net_worth(), player.gold,
				player.get_total_item_value(), player.debt]
		else:
			info.text = "%s [已淘汰]" % [player.name]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		if player.id == GameManager.human_player_id:
			var tag = Label.new()
			tag.text = "(你)"
			tag.add_theme_color_override("font_color", Color(1, 1, 0))
			row.add_child(tag)

		results_container.add_child(row)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
