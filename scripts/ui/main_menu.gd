extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var player_count_label: Label = $VBoxContainer/PlayerCountLabel
@onready var player_count_spin: SpinBox = $VBoxContainer/PlayerCountSpin
@onready var start_button: Button = $VBoxContainer/StartButton

func _ready() -> void:
	title_label.text = "背刺拍卖会"
	player_count_label.text = "玩家数量 (1人为主, 其余AI)"
	start_button.text = "开始游戏"

func _on_start_pressed() -> void:
	var count = int(player_count_spin.value)
	get_tree().change_scene_to_file("res://scenes/main/auction.tscn")
	GameManager.start_game(count)
