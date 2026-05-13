extends Node

var settings: Dictionary = {
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"ui_volume": 0.9,
	"fullscreen": false,
	"window_mode": 0,
	"language": "zh_CN",
	"tutorial_enabled": true,
	"show_damage_numbers": true,
	"auto_bid": false,
	"confirm_bids": true,
	"theme": "dark",
	"font_size": 16,
	"animations_enabled": true,
	"particle_effects": true,
	"screen_shake": true,
	"show_tooltips": true,
	"log_history_size": 100,
	"ai_difficulty": "normal",
	"ai_count": 4,
	"starting_gold": 4000,
	"total_rounds": 30,
	"round_time": 15.0
}

const WINDOW_MODES = ["窗口", "无边框窗口", "全屏"]
const THEMES = ["dark", "light", "gold"]
const DIFFICULTIES = ["简单", "普通", "困难", "地狱"]
const LANGUAGES = ["简体中文", "English"]

signal settings_changed(key: String, value: Variant)

func _ready() -> void:
	_load_settings()

func _load_settings() -> void:
	var save_file = "user://settings.dat"
	if FileAccess.file_exists(save_file):
		var file = FileAccess.open(save_file, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data:
				for key in data:
					if settings.has(key):
						settings[key] = data[key]
			file.close()
	_apply_window_settings()

func _save_settings() -> void:
	var save_file = "user://settings.dat"
	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
		file.close()

func _apply_window_settings() -> void:
	match settings.window_mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func set_setting(key: String, value: Variant) -> void:
	if settings.has(key):
		settings[key] = value
		settings_changed.emit(key, value)
		_save_settings()
		
		if key == "window_mode":
			_apply_window_settings()

func get_setting(key: String) -> Variant:
	return settings.get(key, null)

func get_all_settings() -> Dictionary:
	return settings.duplicate()

func reset_to_defaults() -> void:
	settings = {
		"music_volume": 0.7,
		"sfx_volume": 0.8,
		"ui_volume": 0.9,
		"fullscreen": false,
		"window_mode": 0,
		"language": "zh_CN",
		"tutorial_enabled": true,
		"show_damage_numbers": true,
		"auto_bid": false,
		"confirm_bids": true,
		"theme": "dark",
		"font_size": 16,
		"animations_enabled": true,
		"particle_effects": true,
		"screen_shake": true,
		"show_tooltips": true,
		"log_history_size": 100,
		"ai_difficulty": "normal",
		"ai_count": 4,
		"starting_gold": 4000,
		"total_rounds": 30,
		"round_time": 15.0
	}
	_apply_window_settings()
	_save_settings()

func get_display_name(key: String) -> String:
	match key:
		"music_volume": return "音乐音量"
		"sfx_volume": return "音效音量"
		"ui_volume": return "界面音量"
		"window_mode": return "窗口模式"
		"language": return "语言"
		"tutorial_enabled": return "启用教程"
		"show_damage_numbers": return "显示伤害数字"
		"auto_bid": return "自动出价"
		"confirm_bids": return "确认出价"
		"theme": return "主题"
		"font_size": return "字体大小"
		"animations_enabled": return "启用动画"
		"particle_effects": return "粒子效果"
		"screen_shake": return "屏幕震动"
		"show_tooltips": return "显示提示"
		"log_history_size": return "日志大小"
		"ai_difficulty": return "AI难度"
		"ai_count": return "AI数量"
		"starting_gold": return "初始金币"
		"total_rounds": return "总轮数"
		"round_time": return "每轮时间"
		_: return key
